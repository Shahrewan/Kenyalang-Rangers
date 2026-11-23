"""Build the runtime JSON from the approved, editor-ignored art sources."""

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source-art"
RUNTIME = ROOT / "data/presentation/first_contact"


def read(path):
    return json.loads((SOURCE / path).read_text())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    options = parser.parse_args()
    patrolman = read("rangers/patrolman/manifest.json")
    pivots = {part["id"]: part["pivot_canvas_units"] for part in patrolman["parts"]}
    sockets = {}
    for name, socket in sorted(patrolman["sockets"].items()):
        bone = socket["part"]
        offset = [round(at - pivot, 4) for at, pivot in zip(socket["canvas_units"], pivots[bone])]
        sockets[name] = [bone, offset]
    files = {
        "field.json": {
            "layout": read("first-contact/presentation.json"),
            "atlas": read("first-contact/atlas_regions.json"),
            "patrolman_sockets": sockets,
        },
        "patrolman_animation.json": read("rangers/patrolman/animation_contract.json"),
        "e01_animation.json": read("enemies/e01/animation_contract.json"),
    }
    if not options.check:
        RUNTIME.mkdir(parents=True, exist_ok=True)
    for name, data in files.items():
        target = RUNTIME / name
        output = json.dumps(data, separators=(",", ":")) + "\n"
        if options.check:
            if not target.is_file() or target.read_text() != output:
                raise SystemExit(f"Regenerate {target.relative_to(ROOT)} with {Path(__file__).name}")
        else:
            target.write_text(output)
    print(f"PASS {len(files)} First Contact runtime registrations match the art sources")


if __name__ == "__main__":
    main()
