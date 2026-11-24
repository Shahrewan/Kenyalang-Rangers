"""Assemble the reusable W29 Godot artwork without modifying the game's live routes."""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

from build_cutout_scene import generate

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source-art"
IMPORT = ROOT / "assets/imported"
RUNTIME = ROOT / "data/presentation/w29"
AUDIT = ROOT / "docs/production/w29/asset_audit.csv"
PILOTS = {
    "ranger.scout_sniper": ("scenes/units/scout_rig.tscn", "ranger_scout_sniper"),
    "ranger.patrolman": ("scenes/units/patrolman_rig.tscn", "ranger_patrolman"),
    "E01": ("scenes/units/e01_rig.tscn", "E01"),
}


def ref(path):
    return "res://" + path.relative_to(ROOT).as_posix()


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write(path, text, check):
    if check:
        assert path.is_file() and path.read_text(encoding="utf-8") == text, f"Stale W29 artifact {path}"
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def json_text(record):
    return json.dumps(record, indent=2, ensure_ascii=False) + "\n"


def actor(id_, family, folder, check):
    path = SOURCE / family / folder / "manifest.json"
    data = read(path)
    info = {
        "manifest": ref(path),
        "label": data["display_name"],
        "part_count": len(data["parts"]),
        "foot_anchor": data["ground_anchor_units"],
    }
    if id_ in PILOTS:
        scene, badge = PILOTS[id_]
        info["rig"] = "res://" + scene
        info["badge"] = f"res://assets/imported/first_contact/parts/badges/{badge}.png"
        info["live_in_first_contact"] = True
        return info

    # The runtime clip copy belongs with presentation data. Originals stay
    # addressable at the source paths and can be edited outside the game import.
    source = ROOT / data["animation_contract"]
    contract = read(source)
    key = "__".join((family, *folder.split("/")))
    exported = RUNTIME / "animation" / f"{key}.json"
    write(exported, json_text(contract), check)
    scene = IMPORT / family / folder / "rig.tscn"
    node = "".join(noun.title() for noun in key.replace("__", "_").split("_")) + "Rig"
    text = generate(data, "res://scripts/animation/first_contact_cutout.gd", node, ref(exported))
    write(scene, text, check)
    info.update(rig=ref(scene), animation=ref(exported), state_count=len(contract["states"]))
    if "derived_badge" in data:
        info["badge"] = "res://" + data["derived_badge"]["path"]
    if "companion" in data:
        info["companion"] = data["companion"]["asset_id"]
        info["companion_attachment"] = data["companion"]
    return info


def bundle(check):
    with AUDIT.open(encoding="utf-8") as file:
        rows = list(csv.DictReader(file))
    actors, facilities, boards = {}, {}, {}
    for row in rows:
        id_, family = row["asset_id"], row["family"]
        folder = id_.rsplit(".", 1)[-1]
        match family:
            case "ranger":
                actors[id_] = actor(id_, "rangers", folder, check)
            case "enemy":
                actors[id_] = actor(id_, "enemies", folder.lower(), check)
            case "boss":
                actors[id_] = actor(id_, "bosses", folder, check)
            case "facility":
                path = SOURCE / "facilities" / folder / "manifest.json"
                data = read(path)
                assert data["asset_id"] == id_
                facilities[id_] = {
                    "manifest": ref(path), "label": data["display_name"],
                    "badge": data["badge"]["texture"], "rig": data["rig"],
                    "footprint": data["footprint_cells"], "reserved": data["reserved_cells"],
                    "states": list(data["states"]),
                }
            case "environment":
                boards[folder] = (ref(SOURCE / "first-contact/presentation.json") if folder == "T01"
                                  else ref(SOURCE / "environments" / folder.lower() / "manifest.json"))
    actors["companion.k9_ranger.dog"] = actor("companion.k9_ranger.dog", "rangers", "k9_ranger/companion", check)
    assert len(actors) == 12 + 15 + 3 + 1 and len(facilities) == 13 and len(boards) == 6
    return {
        "schema_version": 1,
        "engine": "4.7.2",
        "scope": "Art packages and preview metadata. Integration uses the existing campaign and save state.",
        "actors": actors,
        "facilities": facilities,
        "environments": boards,
        "headquarters": ref(SOURCE / "hq/manifest.json"),
        "portrait_receipts": ref(SOURCE / "portraits/manifest.json"),
        "support_receipts": ref(SOURCE / "support-w29/manifest.json"),
        "menu_receipts": ref(SOURCE / "ui/w29/manifest.json"),
        "heat_meter": ref(IMPORT / "effects/w29/heat_meter.tscn"),
        "menu_theme": ref(ROOT / "resources/presentation/w29_ui_theme.tres"),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Compare the generated catalog, rig scenes and clip copies")
    args = parser.parse_args()
    result = bundle(args.check)
    write(RUNTIME / "art_catalog.json", json_text(result), args.check)
    print("W29 catalog covers 12 Rangers, the K9 companion, 15 standard enemies, 3 bosses, 13 Facilities and all 6 boards.")


if __name__ == "__main__":
    main()
