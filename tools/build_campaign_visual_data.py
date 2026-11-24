"""Copy approved W29 registrations into the player pack and audit its allowlist."""

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = "data/presentation/w29/campaign_visuals.json"
CATALOG = "data/presentation/w29/art_catalog.json"
PRESET = ROOT / "export_presets.cfg"
LAYOUT = [
    "grid_cells", "geometry_resource", "route_cells", "backdrop",
    "ground", "raised", "entries", "exit", "atlas", "planning_thumbnail",
]


def read(path):
    return json.loads((ROOT / path.removeprefix("res://")).read_text())


def registrations(catalog):
    maps = {}
    for key, path in catalog["environments"].items():
        if key == "T01":
            continue
        region = read(path)
        sha = hashlib.sha256((ROOT / region["geometry_resource"]).read_bytes()).hexdigest()
        if sha != region["geometry_sha256"]:
            raise SystemExit(f"{key} terrain receipt differs from the game board resource")
        maps[key] = {field: region[field] for field in LAYOUT}
    facilities = {}
    for key, entry in catalog["facilities"].items():
        source = read(entry["manifest"])
        scale = source["pixels_per_unit"]
        base = source["base_anchor_canvas_units"]
        ghost = {"opacity": source["states"]["Ghost"]["opacity"], "parts": []}
        layers = source["states"]["Ghost"]["visible"]
        for part in sorted(source["parts"], key=lambda item: item["draw_order"]):
            if part["id"] in layers:
                origin = [pixel / scale - anchor for pixel, anchor in zip(part["origin_png_px"], base)]
                ghost["parts"].append([part["texture"], origin, [n / scale for n in part["size_px"]]])
        facilities[key] = {"anchor": source["anchor_from_occupied_cell_top_left_units"], "ghost": ghost}
    actors = {}
    for key, entry in catalog["actors"].items():
        source = read(entry["manifest"])
        parts = {part["id"]: part["pivot_canvas_units"] for part in source["parts"]}
        actor = {}
        for name, socket in source.get("sockets", {}).items():
            pivot = parts[socket["part"]]
            actor[name] = [socket["part"], [round(x - y, 5) for x, y in zip(socket["canvas_units"], pivot)]]
        if actor:
            actors[key] = actor
    poses = read(catalog["portrait_receipts"])["portraits"]
    portraits = {
        "portrait." + key: {pose: row["texture"]["path"] for pose, row in values.items()}
        for key, values in poses.items() if key != "manager"
    }
    support = read(catalog["support_receipts"])["exports"]
    effects = {key.split(".")[-1]: row["path"] for key, row in support.items() if key.startswith("effects/w29.")}
    return {"schema_version": 1, "maps": maps, "facilities": facilities, "sockets": actors,
            "portraits": portraits, "effects": effects, "finale": support["portraits/story.finale"]["path"]}


def resources(catalog, data):
    art = {"res://" + path for path in [
        "scripts/ui/campaign_visual_assets.gd", "scripts/ui/campaign_region_art.gd", "scripts/ui/campaign_heat_display.gd",
    ]}
    data_files = {DATA}
    for entry in list(catalog["actors"].values()) + list(catalog["facilities"].values()):
        art.update(entry[key] for key in ("rig", "badge") if key in entry)
        if "animation" in entry:
            data_files.add(entry["animation"].removeprefix("res://"))
    for board in data["maps"].values():
        paths = [board["backdrop"]["texture"], board["planning_thumbnail"]["texture"],
                 board["atlas"]["junction_override"]["texture"]]
        paths.extend(entry["texture"] for entry in board["entries"])
        paths.extend(layer["texture"] for layer in board["exit"]["layers"])
        art.update("res://" + path for path in paths)
    for poses in data["portraits"].values():
        art.update(poses.values())
    art.update(data["effects"].values())
    art.update([data["finale"], catalog["heat_meter"]])
    return art, data_files


def export_config(art, data_files):
    source = PRESET.read_text()
    files = re.search(r"^export_files=PackedStringArray\((.*)\)$", source, re.MULTILINE)
    resources = list(dict.fromkeys(re.findall(r'"([^"]+)"', files[1]) + sorted(art)))
    source = source[:files.start(1)] + ", ".join(json.dumps(path) for path in resources) + source[files.end(1):]
    includes = re.search(r'^include_filter="([^"]*)"$', source, re.MULTILINE)
    paths = list(dict.fromkeys(includes[1].split(",") + sorted(data_files)))
    return source[:includes.start(1)] + ",".join(paths) + source[includes.end(1):]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    options = parser.parse_args()
    catalog = read(CATALOG)
    data = registrations(catalog)
    serialized = json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n"
    preset = export_config(*resources(catalog, data))
    target = ROOT / DATA
    if options.check:
        if target.read_text() != serialized or PRESET.read_text() != preset:
            raise SystemExit("Campaign visual registrations or Android resource selection are stale")
    else:
        target.write_text(serialized)
        PRESET.write_text(preset)
    print("PASS Campaign registrations and Android resource selection match the W29 receipts.")


if __name__ == "__main__":
    main()
