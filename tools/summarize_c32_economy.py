"""Validate a full --daily C32 ledger and publish reviewable CSV and JSONL."""
import argparse
from collections import defaultdict
import csv
import json
from pathlib import Path
import re


def gather(raw, prefix):
    return [json.loads(line[len(prefix):]) for line in raw.splitlines() if line.startswith(prefix)]


def flatten(row):
    sources = row["gross"]
    return {
        "scenario": row["variant"],
        "profile": row["profile"],
        "day": row["day"],
        **{f"earned_{name}": value for name, value in sources.items()},
        "total_earned": sum(sources.values()),
        **{f"spent_{name}": value for name, value in row["spending"].items()},
        "total_spent": sum(row["spending"].values()),
        "wallet_discarded": sum(row["discarded"].values()),
        "outreach_deducted": row["outreach_deducted"],
        "finance_unstored": row["finance_unstored"],
        "wallet_balance": row["balance"],
        "active_seconds": row["active_seconds"],
        **{f"time_{name}_seconds": row["time_by_activity"].get(name, 0)
           for name in ("menu", "story", "outreach", "records", "garden", "chaos", "shopping")},
        "story_clears": row["activities"].get("story_first_clear", 0),
        "story_perfects": row["activities"].get("story_first_perfect", 0),
        "chaos_clears": row["activities"].get("chaos_clears", 0),
        "garden_harvests": row["activities"].get("garden_harvests", 0),
        "control_level": int(row["rooms"]["room.control_room"]),
        "ecology_level": int(row["rooms"]["room.ecology"]),
        "outreach_level": int(row["rooms"]["room.outreach"]),
        "rnd_buffs": row["rd_unlocked"],
        "max_units": row["max_units"],
    }


def reconcile(days, checkpoints):
    running = defaultdict(lambda: defaultdict(int))
    expected_days = defaultdict(int)
    checkpoint_by_day = {(r["variant"], r["profile"], r["day"]): flatten(r) for r in checkpoints}
    additive = ("earned_", "total_earned", "total_spent", "spent_", "time_",
                "wallet_discarded", "finance_unstored", "outreach_deducted",
                "story_clears", "story_perfects", "chaos_clears", "garden_harvests", "active_seconds")
    for row in days:
        flat = flatten(row)
        key = (flat["scenario"], flat["profile"])
        expected_days[key] += 1
        if flat["day"] != expected_days[key]:
            raise SystemExit(f"Ledger day order differs for {key} at {flat['day']}")
        totals = running[key]
        for column, amount in flat.items():
            if column.startswith(additive):
                totals[column] += amount
        balance = 10_000 + totals["total_earned"] - totals["total_spent"] - totals["wallet_discarded"] - totals["outreach_deducted"]
        if balance != flat["wallet_balance"] or flat["active_seconds"] > row["session_budget_seconds"]:
            raise SystemExit(f"Non-reconciling wallet or daily time budget for {key} on day {flat['day']}")
        checkpoint = checkpoint_by_day.get((*key, flat["day"]))
        if checkpoint and any(checkpoint[k] != v for k, v in totals.items()):
            raise SystemExit(f"Cumulative checkpoint differs from daily data for {key} on day {flat['day']}")
    groups = {(variant, profile) for variant in ("installed", "rewards", "guardrails")
              for profile in ("casual", "moderate", "chaos_regular", "rare_perfect", "hq_first", "unit_first")}
    if set(expected_days) != groups or any(day != 60 for day in expected_days.values()):
        raise SystemExit("Expected 60 consecutive days for all 18 scenario and profile pairs")
    if set(checkpoint_by_day) != {(*group, day) for group in groups for day in (7, 30, 60)}:
        raise SystemExit("Expected 7-, 30- and 60-day checkpoints for all pairs")


def write_csv(path, rows):
    material = [flatten(row) for row in rows]
    with path.open("w", newline="") as destination:
        writer = csv.DictWriter(destination, fieldnames=list(material[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(material)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    raw = args.log.read_text()
    if not re.search(r"^C32 economy simulation: \d+ checks, 0 failures$", raw, re.M):
        raise SystemExit("Expected a passing C32 simulation log")
    days = gather(raw, "DAY ")
    checks = gather(raw, "CHECKPOINT ")
    reconcile(days, checks)
    args.out.mkdir(parents=True, exist_ok=True)
    write_csv(args.out / "daily.csv", days)
    write_csv(args.out / "checkpoints.csv", checks)
    for prefix, name in [("CHECKPOINT ", "progression"), ("REFERENCE ", "gdd-reference"), ("CHAOS ", "chaos-cases")]:
        data = gather(raw, prefix)
        (args.out / f"{name}.jsonl").write_text("".join(json.dumps(row, sort_keys=True) + "\n" for row in data))
    print(f"Verified {len(days)} daily ledgers and {len(checks)} checkpoints")


if __name__ == "__main__":
    main()
