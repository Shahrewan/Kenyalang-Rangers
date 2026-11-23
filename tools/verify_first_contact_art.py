"""Check C1-01 art registrations and load their imported Godot textures."""

import ast
import json
from pathlib import Path
import re
import subprocess
import tempfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source-art/first-contact"
IMPORT = ROOT / "assets/imported/first_contact"


def load_json(path):
    return json.loads(path.read_text())


def cells(path, key):
    row = re.search(fr"^{key} = (.+)$", (ROOT / path).read_text(), re.MULTILINE)[1]
    return [list(ast.literal_eval(pair)) for pair in re.findall(r"Vector2i(\([0-9, ]+\))", row)]


def verify_authoring_data():
    data = load_json(SOURCE / "presentation.json")
    board = data["battle"]
    map_path, route_path = board["geometry_resources"]
    route = cells(route_path, "cells")
    ground = cells(map_path, "ground")
    raised = cells(map_path, "elevated")
    assert board["grid_cells"] == cells(map_path, "size")[0] == [12, 5]
    assert board["route_cells"] == route and len(route) == 14
    assert [item["cell"] for item in board["ground"]] == ground == route[1:-1] and len(ground) == 12
    assert [item["cell"] for item in board["raised"]] == raised and len(raised) == 19
    assert board["entry"]["cell"] == cells(map_path, "spawns")[0] == route[0]
    assert board["tunnel"]["cell"] == cells(map_path, "tunnel")[0] == route[-1]
    assert [item["next_cell"] for item in board["ground"]] == route[2:]
    assert board["opening_post_pairs"] == [
        [[x, y], [x + 1, y]] for x, y in raised if [x + 1, y] in raised
    ]
    assert all(abs(a[0] - b[0]) + abs(a[1] - b[1]) == 1 for a, b in zip(route, route[1:]))
    campaign = ROOT / "docs/production/w13"
    nodes = data["story"]["nodes"]
    assert [n["id"] for n in nodes] == load_json(campaign / "campaign.json")["mission_ids"]
    assert len(nodes) == 15 and len({tuple(n["ui_center_units"]) for n in nodes}) == 15
    for n in nodes:
        stage = load_json(campaign / "stages" / (n["id"].lower() + ".json"))
        assert n["title"] == stage["title"]
        for key in ("min_control_level", "requires_previous_clear", "region"):
            assert n[key] == stage["operation"][key]
    revealed = data["story"]["revealed_by_control"]
    for lv in range(1, 6):
        assert revealed[str(lv)] == [n["id"] for n in nodes if n["min_control_level"] <= lv]
    assert [len(ids) for ids in revealed.values()] == [3, 5, 9, 13, 15]
    return data


def verify_atlases(data):
    expected = {}
    atlases = load_json(SOURCE / "atlas_regions.json")
    for atlas in atlases.values():
        assert (ROOT / atlas["source_svg"]).is_file()
        image = Image.open(ROOT / atlas["texture"]).convert("RGBA")
        assert list(image.size) == atlas["dimensions_px"]
        expected[atlas["texture"]] = list(image.size)
        regions = atlas["regions"]
        padding = atlas["gutter_px"]
        for item in regions.values():
            x, y, w, h = item["region_px"]
            ax, ay = item["anchor_px"]
            assert 0 <= ax < w and 0 <= ay < h
            assert x >= padding and y >= padding
            assert x + w + padding <= image.width and y + h + padding <= image.height
            assert image.crop((x, y, x + w, y + h)).getchannel("A").getbbox()
            # The inner border texel comes from the matching art edge.
            for j in range(h):
                assert image.getpixel((x, y+j)) == image.getpixel((x-1, y+j))
                assert image.getpixel((x+w-1, y+j)) == image.getpixel((x+w, y+j))
            for i in range(w):
                assert image.getpixel((x+i, y)) == image.getpixel((x+i, y-1))
                assert image.getpixel((x+i, y+h-1)) == image.getpixel((x+i, y+h))

    board = data["battle"]
    terrain = atlases["terrain"]["regions"]
    assert all(item["region"] in terrain for item in board["ground"] + board["raised"] + [board["entry"], board["tunnel"]])
    assert all(id in terrain for item in board["raised"] for id in item["exposed_edge_art"])
    assert all(id in atlases["effects"]["regions"] for id in data["scout_shot"]["regions"])
    assert all(id in atlases["interface"]["regions"] for id in data["story"]["states"])
    assert data["scout_shot"]["visual_only"] is True
    expected[board["background"]["file"]] = board["background"]["size"]
    expected[data["story"]["backplate"]] = data["reference_viewport"]
    expected[data["thumbnails"]["texture"]] = data["thumbnails"]["size_px"]
    for binding in data["portraits"]["bindings"].values():
        for file in binding.values():
            expected[file] = data["portraits"]["size_px"]
    assert set(expected) == {str(p.relative_to(ROOT)) for p in IMPORT.iterdir()
                             if p.suffix in {".png", ".jpg", ".svg"}}
    print(f"{sum(len(atlas['regions']) for atlas in atlases.values())} atlas regions and their gutters passed")
    return expected


def verify_engine(expected):
    checks = []
    for path, (width, height) in expected.items():
        checks.append(f'\t_check("{path}", Vector2({width}, {height}))')
    code = """extends SceneTree

func _initialize() -> void:
%s
    if failures:
        quit(1)
    else:
        print("Godot loaded %d First Contact textures at their registered dimensions")
        quit()

var failures := 0

func _check(path: String, expected: Vector2) -> void:
    var texture := load("res://" + path) as Texture2D
    if texture == null or texture.get_size() != expected:
        failures += 1
        push_error("Unexpected First Contact texture: " + path)
""" % ("\n".join(checks).expandtabs(4), len(expected))
    with tempfile.TemporaryDirectory(prefix="first-contact-art-") as scratch:
        path = Path(scratch) / "probe.gd"
        path.write_text(code)
        subprocess.run(["godot", "--headless", "--path", str(ROOT), "--script", str(path)], check=True, timeout=30)


if __name__ == "__main__":
    layout = verify_authoring_data()
    textures = verify_atlases(layout)
    print("T01 route, platform mask, 15 mission registrations and Control reveal counts passed", flush=True)
    verify_engine(textures)
