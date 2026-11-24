"""Copy the approved Headquarters registrations into the player resource area."""

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source-art/hq/manifest.json"
RUNTIME = ROOT / "data/presentation/w29/headquarters.json"


def build(source):
    rooms = source["rooms"]
    first, second = (row["overview_hit_rect"] for row in rooms[:2])
    last_x, last_y, width, height = rooms[-1]["overview_hit_rect"]
    return {
        "schema_version": source["schema_version"],
        "canvas_units": source["canvas_units"],
        "shell": {layer: entry["texture"] for layer, entry in source["shell"].items()},
        "unbuilt": source["unbuilt"]["texture"],
        "vacant_bay": [last_x + second[0] - first[0], last_y, width, height],
        "trophy_anchor": source["trophy_anchor"],
        "trophy_max_size": source["trophy_max_size"],
        "rooms": [
            {
                "id": row["id"],
                "rect": row["overview_hit_rect"],
                "back": row["assets"]["back"]["texture"],
                "front": row["assets"]["front"]["texture"],
                "detail": row["detail"]["texture"],
                "staff": {key: row["staff"][key] for key in ("rig", "clip", "anchor_in_room", "scale")},
            }
            for row in rooms
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    options = parser.parse_args()
    expected = json.dumps(build(json.loads(SOURCE.read_text())), indent=2) + "\n"
    if options.check:
        if RUNTIME.read_text() != expected:
            raise SystemExit("HQ runtime registrations differ from the approved W29 manifest.")
    else:
        RUNTIME.write_text(expected)
    print("PASS HQ runtime registrations match the approved W29 manifest.")


if __name__ == "__main__":
    main()
