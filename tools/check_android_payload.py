"""Replay the signed APK's shipped Godot resources on the host in disposable profiles."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
RUNNERS = ("campaign_story_test", "headquarters_ui_test", "chaos_rules_test", "chaos_ui_test",
           "restoration_rules_test")


def extract_pack(apk, pack):
    with ZipFile(apk) as package, ZipFile(pack, "w") as target:
        bad = package.testzip()
        if bad:
            raise SystemExit(f"Damaged APK entry {bad}")
        entries = [k for k in package.namelist() if k.startswith("assets/") and not k.endswith("/")]
        for name in entries:
            path = name.removeprefix("assets/")
            if path.startswith(("tests/", "docs/production/w18/", "scenes/qa/")) or "c23_load" in path:
                raise SystemExit(f"QA or review resource in player APK: {path}")
            target.writestr(path, package.read(name))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--previous", type=Path, help="Earlier player APK for update-data rehearsal")
    parser.add_argument("--first-contact", action="store_true", help="Also test the illustrated C28-A mission")
    parser.add_argument("--hold-the-line", action="store_true", help="Also test the illustrated C28-B mission")
    parser.add_argument("--narrow-escape", action="store_true", help="Also test the illustrated C28-C mission")
    parser.add_argument("--campaign-visuals", action="store_true", help="Check all live Ranger and Facility rigs and W29 resources")
    parser.add_argument("--combat-balance", action="store_true", help="Verify C30 damage, live skill state and cooldowns from the exported pack")
    parser.add_argument("--skill-orbs", action="store_true", help="Check C31 orb geometry and live skill states from the exported pack")
    parser.add_argument("--logs", type=Path, default=ROOT / "build/qa/c24/payload")
    args = parser.parse_args()
    args.logs.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temporary:
        work = Path(temporary)
        pack = work / "player.zip"
        extract_pack(args.apk, pack)

        def run(name, profile, source, flags):
            env = os.environ.copy()
            for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                folder = work / profile / key
                folder.mkdir(parents=True, exist_ok=True)
                env[key] = str(folder)
            cmd = ["godot", "--headless", "--main-pack", source, *flags]
            result = subprocess.run(cmd, env=env, cwd=work, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True, timeout=180)
            (args.logs / f"{name}.log").write_text(result.stdout)
            if result.returncode or re.search(r"^(SCRIPT ERROR:|ERROR:|WARNING:|FAIL )", result.stdout, re.M):
                raise SystemExit(f"{name} failed\n{result.stdout[-1600:]}")
            if "--script" in flags:
                summary = re.search(r"^(.*: \d+ checks, 0 failures)$", result.stdout, re.M)
                checks = result.stdout.count("\nPASS ")
                if not (checks or summary):
                    raise SystemExit(f"No test result for {name}")
                print(name, summary[1] if summary else f"{checks} checks", flush=True)
            else:
                print(name, "PASS", flush=True)

        run("boot", "boot", pack, ["--quit-after", "6"])
        runners = RUNNERS + (("c28_first_contact_test",) if args.first_contact else ())
        if args.hold_the_line:
            runners += ("c28_hold_the_line_test",)
        if args.narrow_escape:
            runners += ("c28_narrow_escape_test",)
        if args.campaign_visuals:
            runners += ("campaign_visuals_test",)
        if args.combat_balance:
            runners += ("c30_combat_test",)
        if args.skill_orbs:
            runners += ("c31_skill_orb_test",)
        for name in runners:
            run(name, name, pack, ["--script", ROOT / f"tests/unit/{name}.gd"])
        seed_packs = {"fresh": pack}
        if args.previous:
            old = work / "previous.zip"
            extract_pack(args.previous, old)
            seed_packs["update"] = old
        for profile, seed in seed_packs.items():
            for phase in ("seed", "resume", "verify"):
                script = ROOT / "tests/release/player_continuity.gd"
                run(f"{profile}-{phase}", profile, seed if phase == "seed" else pack,
                    ["--script", script, "--", phase])


if __name__ == "__main__":
    main()
