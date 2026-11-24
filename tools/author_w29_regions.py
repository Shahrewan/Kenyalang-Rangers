"""Build and verify the W29 regional art deliveries against the live map resources."""

import argparse
from collections import defaultdict
from hashlib import sha256
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source-art/environments"
IMPORT = ROOT / "assets/imported/environments"
REVIEW = ROOT / "docs/production/w29/regions"
FIRST_SOURCE = ROOT / "assets/source-art/first-contact"
FIRST_IMPORT = ROOT / "assets/imported/first_contact"
LAYOUT = json.loads((FIRST_SOURCE / "presentation.json").read_text())["battle"]
ATLAS = json.loads((FIRST_SOURCE / "atlas_regions.json").read_text())["terrain"]
SAMPLE_FOOTPRINTS = {
    "T02": ((1, 0), (2, 0)),
    "T03": ((5, 2), (6, 2)),
    "T04": ((5, 0), (6, 0)),
    "T05": ((1, 2), (2, 2)),
    "T06": ((1, 2), (2, 2)),
}
DELTAS = {(0, -1): 1, (1, 0): 2, (0, 1): 4, (-1, 0): 8}
GROUND_ART = {3: ("KRT_08", 0), 5: ("KRT_10", 0), 6: ("KRT_08", 90),
              7: ("junction_04", 0), 9: ("KRT_08", 270), 10: ("KRT_15", 0),
              12: ("KRT_17", 0)}
EDGES = {(0, -1): "KRT_25", (1, 0): "KRT_26", (0, 1): "KRT_27", (-1, 0): "KRT_28"}
CORNERS = {
    ((0, -1), (1, 0)): "KRT_29",
    ((1, 0), (0, 1)): "KRT_30",
    ((0, 1), (-1, 0)): "KRT_31",
    ((-1, 0), (0, -1)): "KRT_32",
}
MAPS = {
    "T02": ("gunung_mulu", "Gunung Mulu", ("C2-01", "C2-02"),
            "W29-B05", (17, 20, 2), 0.25, "Limestone karst and low mist"),
    "T03": ("batang_ai", "Batang Ai", ("C2-03", "C2-04"),
            "W29-B06", (14, 18, 1), 0.13, "Lake water and wooded ridges"),
    "T04": ("tanjung_datu", "Tanjung Datu", ("C2-05", "C2-06"),
            "W29-B07", (10, 12, 1), 0.13, "Coastal headland and outer roots"),
    "T05": ("imbak_canyon", "Imbak Canyon", ("C2-07", "C2-08"),
            "W29-B08", (12, 18, 1), 0.20, "Sandstone ravine and shaded rock"),
    "T06": ("sepilok_kabili", "Sepilok-Kabili", ("C2-09", "C2-10"),
            "W29-B09", (12, 16, 1), 0.08, "Lowland canopy and buttress roots"),
}

# T01-derived masks keep the exact approved occlusion shape. These small hue
# changes tie the foreground foliage to local cover without redrawing the path.
FOLIAGE_PALETTES = {
    "T02": ("#4b6040", "#7f8f59", "#a3ad74", "#80664d"),
    "T03": ("#45634b", "#748855", "#9fab70", "#79634a"),
    "T04": ("#536944", "#849750", "#a8b471", "#936d4e"),
    "T05": ("#586443", "#8c9254", "#aab06e", "#92694e"),
    "T06": ("#3c5840", "#687f49", "#9aa96b", "#786148"),
}


def relative(path):
    return path.relative_to(ROOT).as_posix()


def hash_file(path):
    return sha256(path.read_bytes()).hexdigest()


def json_file(path):
    return json.loads(path.read_text())


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def vector_list(value):
    return [tuple(map(int, pair)) for pair in re.findall(r"Vector2i\((\d+), (\d+)\)", value)]


def read_geometry(id):
    slug, _, _, _, counts, *_ = MAPS[id]
    path = ROOT / f"data/stages/campaign/{id.lower()}_{slug}.tres"
    text = path.read_text()
    assert f'map_id = &"{id}"' in text and f'stage_id = &"{id}"' in text

    def read_property(key):
        return vector_list(re.search(rf"^{key} = (.+)$", text, re.MULTILINE)[1])

    width, height = read_property("size")[0]
    ground, raised, entries = (read_property(name) for name in ("ground", "elevated", "spawns"))
    terminal = read_property("tunnel")[0]
    routes = [vector_list(value) for value in re.findall(r"^cells = (.+)$", text, re.MULTILINE)]
    assert (width, height) == (12, 5)
    assert (len(ground), len(raised), len(routes)) == counts
    assert set(ground) == {cell for route in routes for cell in route[1:-1]}
    assert entries == [route[0] for route in routes]
    assert all(route[-1] == terminal for route in routes)
    fields = ground + raised + entries + [terminal]
    assert len(fields) == len(set(fields))
    assert all(0 <= x < width and 0 <= y < height for x, y in fields)
    assert terminal[0] == width - 1 and all(entry[0] == 0 for entry in entries)
    return path, (width, height), ground, raised, entries, terminal, routes


def directed_edges(routes):
    masks, outgoing = defaultdict(int), {}
    for route in routes:
        for (x0, y0), (x1, y1) in zip(route, route[1:]):
            delta = (x1 - x0, y1 - y0)
            masks[(x0, y0)] |= DELTAS[delta]
            masks[(x1, y1)] |= DELTAS[(-delta[0], -delta[1])]
            old = outgoing.get((x0, y0))
            assert old in (None, delta), "Unexpected fork in regional layout"
            outgoing[(x0, y0)] = delta
    return masks, outgoing


def item(path, **extra):
    with Image.open(path) as image:
        return {"texture": relative(path), "size_px": list(image.size),
                "sha256": hash_file(path), **extra}


def map_registration(id):
    path, size, ground, raised, entries, terminal, routes = read_geometry(id)
    _, region, missions, batch, _, cover_y, landmark = MAPS[id]
    dst = IMPORT / id.lower()
    source = SOURCE / id.lower()
    masks, outgoing = directed_edges(routes)
    top = set(raised)
    registrations = []
    for x, y in raised:
        exposed = {offset for offset in EDGES if (x + offset[0], y + offset[1]) not in top}
        registrations.append({
            "cell": [x, y], "region": "KRT_21",
            "exposed_edge_art": [value for offset, value in EDGES.items() if offset in exposed]
            + [value for offsets, value in CORNERS.items() if set(offsets) <= exposed],
        })
    gate_art = ("entry_a", "entry_b") if len(entries) == 2 else ("entry",)
    gates = [{
        "cell": list(cell), "route_index": index,
        "label": chr(65 + index) if len(entries) == 2 else "",
        "outgoing": list(outgoing[cell]),
        **item(IMPORT / "shared" / f"{gate_art[index]}.png",
               source_svg=relative(SOURCE / "shared" / f"{gate_art[index]}.svg")),
    } for index, cell in enumerate(entries)]
    pieces = []
    for layer in LAYOUT["tunnel"]["layers"]:
        piece = {key: layer[key] for key in ("id", "display_size_units",
                                             "offset_units_from_terminal_top_left", "draw_phase")}
        if layer["id"] == "woodland_runout":
            texture, svg = ROOT / layer["texture"], ROOT / layer["source_svg"]
        else:
            texture = dst / f'{layer["id"]}.png'
            svg = source / f'{layer["id"]}.svg'
        pieces.append({**piece, **item(texture, source_svg=relative(svg))})
    return {
        "schema_version": 1, "id": id, "region": region, "missions": list(missions),
        "batch": batch, "landmark": landmark, "approval_status": "visual_review_pending",
        "binding_status": "verified_art_unbound",
        "geometry_resource": relative(path), "geometry_sha256": hash_file(path),
        "grid_cells": list(size), "tile_artist_units": 80,
        "geometry_note": "Use BattleBoard origin and current tile_size(). No texture defines geometry.",
        "source_references": ["GDD pp. 7–8, 21–22, 32", "UI pp. 4–5, 8, 117–119 (T02) and 31 (T05)",
                              "C28-A First Contact terrain and exit art"],
        "route_cells": [[list(cell) for cell in route] for route in routes],
        "ground": [{
            "cell": list(cell), "connection_mask": masks[cell], "region": GROUND_ART[masks[cell]][0],
            "clockwise_degrees": GROUND_ART[masks[cell]][1], "arrow_direction": list(outgoing[cell]),
        } for cell in ground],
        "raised": registrations,
        "opening_post_pairs": [[[x, y], [x + 1, y]] for x, y in raised if (x + 1, y) in top],
        "entries": gates,
        "exit": {
            "cell": list(terminal), "region": "KRT_48", "escape_world_cell": list(terminal),
            "approach": ["west"], "display": "woodland_edge",
            "layers": pieces,
            "anchor": "Terminal tile top-left with independent uniform tile_size()/80 scaling.",
            "occlusion": "Foreground renders after enemies, HP and world effects; remove visible Exit pose at the existing escape event.",
        },
        "atlas": {"texture": ATLAS["texture"], "regions": relative(FIRST_SOURCE / "atlas_regions.json"),
                  "junction_override": item(IMPORT / "shared/junction_04.png",
                                            source_svg=relative(SOURCE / "shared/junction_04.svg"))},
        "backdrop": {
            **item(dst / "backdrop.jpg"), "source_master": relative(source / "backdrop_master.png"),
            "source_sha256": hash_file(source / "backdrop_master.png"),
            "fit": "cover", "cover_anchor": [0.5, cover_y], "decorative": True,
            "render_before": "terrain",
            "provenance": "Original project-specific ImageGen scenic master, W29 2026-11-24. "
                          "C28-A T01 is the style input. W08 T02 concept is a motif input only.",
        },
        "planning_thumbnail": item(dst / "card_wide.jpg"),
    }


def svg_content(s):
    return s[s.index(">") + 1:s.rindex("</svg>")]


def tile_source(id):
    master = (FIRST_SOURCE / "t01_terrain_atlas.svg").read_text()
    return svg_content(re.search(rf'<svg id="{id}"[^\n]+</svg>', master)[0])


def svg_document(title, artwork):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">\n'
            f'<title>{title}</title>\n{artwork}\n</svg>\n')


def render_svg(source, target):
    subprocess.run(["inkscape", str(source), "--export-filename", str(target)], check=True,
                   capture_output=True, timeout=30)


def build_shared():
    source = SOURCE / "shared"
    dst = IMPORT / "shared"
    source.mkdir(parents=True, exist_ok=True)
    dst.mkdir(parents=True, exist_ok=True)
    labels = {
        "entry": '<path d="M43 54h43m-15-11 15 11-15 11"/>',
        "entry_a": '<path d="M33 67l9-24 9 24m-15-8h12M69 54h23m-9-8 9 8-9 8"/>',
        "entry_b": '<path d="M34 67V43h7c11 0 12 11 2 12 12-1 13 12 1 12H34m0-12h7M69 54h23m-9-8 9 8-9 8"/>',
    }
    paint = tile_source("KRT_46")
    for id, label in labels.items():
        artwork = (f'<g id="sign">{paint}</g>\n<g id="direction_mark" fill="none" stroke="#FAEDCC" '
                   f'stroke-width="4.8" stroke-linejoin="round" stroke-linecap="round">{label}</g>')
        source_file = source / f"{id}.svg"
        source_file.write_text(svg_document(f"W29 {id.replace('_', ' ')}", artwork))
        render_svg(source_file, dst / f"{id}.png")

    # N|E|S connector differs from KRT_10 solely by the open eastern edge.
    artwork = re.sub(r'<path d="M126 2V126"[^>]*/>', "", tile_source("KRT_10"), count=1)
    source_file = source / "junction_04.svg"
    source_file.write_text(svg_document("W29 north east south sand junction", artwork))
    render_svg(source_file, dst / "junction_04.png")


def build_region(id):
    source = SOURCE / id.lower()
    dst = IMPORT / id.lower()
    dst.mkdir(parents=True, exist_ok=True)
    with Image.open(source / "backdrop_master.png") as full:
        landscape = ImageOps.fit(full.convert("RGB"), (1280, 720), Image.Resampling.LANCZOS)
        landscape.save(dst / "backdrop.jpg", quality=94, optimize=True, progressive=True, subsampling=0)
        wide = ImageOps.fit(landscape, (440, 200), Image.Resampling.LANCZOS, centering=(0.5, 0.12))
        wide.save(dst / "card_wide.jpg", quality=93, optimize=True, progressive=True, subsampling=0)

    dark, green, sun, wood = FOLIAGE_PALETTES[id]
    for layer in ("woodland_trees_back", "woodland_trees_front"):
        original = FIRST_SOURCE / "woodland_exit" / f"{layer}.svg"
        revised = original.read_text()
        substitutions = {
            "#556643": dark, "#566642": dark, "#637449": dark, "#5E7144": dark,
            "#849252": green, "#829047": green, "#8F9B55": green, "#849551": green,
            "#A8AF67": sun, "#A2AA5C": sun, "#AFB567": sun, "#AFB567": sun,
            "#846749": wood, "#755F45": wood,
        }
        revised = re.sub(r"#[0-9A-Fa-f]{6}", lambda match: substitutions.get(match[0], match[0]), revised)
        revised = revised.replace("xmlns:inkscape=", "xmlns:inkscape=")  # Preserve editable named groups.
        (source / f"{layer}.svg").write_text(revised)
        render_svg(source / f"{layer}.svg", dst / f"{layer}.png")

    registration = map_registration(id)
    # Persist board and source provenance separate from the gameplay resource.
    write_json(source / "manifest.json", registration)


def terrain(id):
    if id == "junction_04":
        return Image.open(IMPORT / "shared/junction_04.png").convert("RGBA")
    rec = ATLAS["regions"][id]
    return Image.open(ROOT / rec["standalone_texture"]).convert("RGBA")


def regional_layer(layer, scale):
    image = Image.open(ROOT / layer["texture"]).convert("RGBA")
    size = [round(v * scale) for v in layer["display_size_units"]]
    return image.resize(tuple(size), Image.Resampling.LANCZOS)


def actor_art(path, scale):
    manifest = json_file(ROOT / path)
    image = Image.new("RGBA", (384, 384))
    for part in sorted(manifest["parts"], key=lambda p: p["draw_order"]):
        sprite = Image.open(ROOT / part["png"]).convert("RGBA")
        image.alpha_composite(sprite, tuple(part["canvas_rect_px"][:2]))
    return image.resize((round(96 * scale), round(96 * scale)), Image.Resampling.LANCZOS)


def verify_occlusion(registration, expected):
    # Sample the real approved E01 pose and its route-held silhouette as it goes
    # from still visible before the terminal cell to hidden at the escape center.
    actor = Image.open(ROOT / "assets/source-art/enemies/e01/rust_reference.png").getchannel("A")
    front = registration["exit"]["layers"][-1]
    for cell_size in (80, 60):
        scale = cell_size / 80
        canvas = Image.new("L", (4 * cell_size, 3 * cell_size))
        ox, oy = [round(v * scale) for v in front["offset_units_from_terminal_top_left"]]
        canvas.paste(regional_layer(front, scale).getchannel("A"), (cell_size + ox, cell_size + oy))
        sprite = actor.resize((round(96 * scale), round(96 * scale)), Image.Resampling.LANCZOS)
        for x, minimum, maximum in expected:
            body = Image.new("L", canvas.size)
            body.paste(sprite, (cell_size + round((x - 48) * scale),
                                cell_size + round((40 + 22 - 84) * scale)))
            covered = [alpha for value, alpha in zip(body.tobytes(), canvas.tobytes()) if value >= 128]
            assert covered and minimum <= sum(a < 242 for a in covered) / len(covered) <= maximum
        # Decorative alpha is allowed beyond the grid, never on a raised pad.
        terminal = registration["exit"]["cell"]
        for row in registration["raised"]:
            cx, cy = row["cell"]
            x = cell_size * (cx - terminal[0] + 1)
            y = cell_size * (cy - terminal[1] + 1)
            assert canvas.crop((x, y, x + cell_size, y + cell_size)).getbbox() is None


def verify_registry():
    paths = {}
    for id in MAPS:
        manifest = json_file(SOURCE / id.lower() / "manifest.json")
        assert manifest == map_registration(id), id
        _, _, ground, raised, entries, exit_cell, _ = read_geometry(id)
        assert set(map(tuple, [row["cell"] for row in manifest["ground"]])) == set(ground)
        assert [tuple(row["cell"]) for row in manifest["raised"]] == raised
        assert [tuple(gate["cell"]) for gate in manifest["entries"]] == entries
        assert tuple(manifest["exit"]["escape_world_cell"]) == exit_cell
        verify_occlusion(manifest, [(-20, .95, 1.0), (20, .05, .35), (40, 0, .01)])
        assets = [manifest["backdrop"], manifest["planning_thumbnail"], *manifest["entries"],
                  *manifest["exit"]["layers"], manifest["atlas"]["junction_override"]]
        for art in assets:
            path = ROOT / art["texture"]
            with Image.open(path) as image:
                if path.suffix == ".png":
                    assert image.mode == "RGBA", path
                    alpha = image.getchannel("A")
                    assert alpha.getextrema() == (0, 255) or "junction" in path.name, path
                else:
                    assert image.mode == "RGB", path
                paths[art["texture"]] = art["size_px"]
            assert hash_file(path) == art["sha256"], path

    # All layouts share the same sand texel into and out of the terminal tile.
    final = terrain("KRT_48")
    sand = terrain("KRT_15")
    runout = Image.open(ROOT / LAYOUT["tunnel"]["layers"][0]["texture"]).convert("RGBA")
    for y in range(16, 112):
        assert sand.getpixel((127, y)) == final.getpixel((0, y))
        assert final.getpixel((127, y)) == runout.getpixel((0, y))
    assert [r["cell"] for r in json_file(SOURCE / "t02/manifest.json")["ground"]
            if r["region"] == "junction_04"] == [[5, 2]]
    print("T02–T06: exact 65 ground and 84 elevated cells, 6 entries and 5 exits; "
          "actor and pad occlusion passed at 80/60. All 24 exported textures validated.")
    return paths


def view_frame(manifest, cell):
    size = (1232, 430) if cell == 80 else (924, 322)
    scale = cell / 80
    result = ImageOps.fit(Image.open(ROOT / manifest["backdrop"]["texture"]).convert("RGB"),
                          size, Image.Resampling.LANCZOS,
                          centering=tuple(manifest["backdrop"]["cover_anchor"])).convert("RGBA")
    origin = ((size[0] - 12 * cell) // 2, (size[1] - 5 * cell) // 2)

    def top_left(point):
        return tuple(base + index * cell for base, index in zip(origin, point))

    def put_tile(id, point, degrees=0):
        art = terrain(id)
        if degrees:
            art = art.rotate(-degrees)
        result.alpha_composite(art.resize((cell, cell), Image.Resampling.LANCZOS), top_left(point))

    for row in manifest["ground"]:
        put_tile(row["region"], row["cell"], row["clockwise_degrees"])
    for row in manifest["raised"]:
        put_tile(row["region"], row["cell"])
        for edge in row["exposed_edge_art"]:
            put_tile(edge, row["cell"])

    for row in manifest["ground"]:
        deg = {(1, 0): 0, (0, 1): 90, (-1, 0): 180, (0, -1): 270}[tuple(row["arrow_direction"])]
        arrow = terrain("route_arrow").rotate(-deg)
        alpha = round(cell * .32)
        x, y = top_left(row["cell"])
        a = (cell - alpha) // 2
        result.alpha_composite(arrow.resize((alpha, alpha), Image.Resampling.LANCZOS), (x + a, y + a))

    terminal = manifest["exit"]["cell"]
    put_tile(manifest["exit"]["region"], terminal)
    for gate in manifest["entries"]:
        texture = Image.open(ROOT / gate["texture"]).convert("RGBA")
        result.alpha_composite(texture.resize((cell, cell), Image.Resampling.LANCZOS), top_left(gate["cell"]))

    def layer_at(layer):
        x, y = top_left(terminal)
        dx, dy = [round(v * scale) for v in layer["offset_units_from_terminal_top_left"]]
        result.alpha_composite(regional_layer(layer, scale), (x + dx, y + dy))

    layers = manifest["exit"]["layers"]
    layer_at(layers[0])
    layer_at(layers[1])
    # Approved neutral study and cutouts provide readable scale witnesses for
    # the paths. This is a static projection review, not a new gameplay scene.
    e02 = actor_art("assets/source-art/enemies/e02/manifest.json", scale)
    e01 = Image.open(ROOT / "assets/source-art/enemies/e01/rust_reference.png").convert("RGBA").resize(e02.size)
    for lane in manifest["route_cells"]:
        for index, art in ((2, e01), (4, e02)):
            x, y = top_left(lane[index])
            result.alpha_composite(art, (x + cell // 2 - round(48 * scale), y + round((62 - 84) * scale)))
    layer_at(layers[2])
    return result.convert("RGB")


def make_previews():
    for cell, viewport in ((80, (1280, 720)), (60, (960, 540))):
        scale = cell / 80
        boards = []
        font = ImageFont.truetype("DejaVuSans.ttf", round(21 * scale))
        for id in MAPS:
            manifest = json_file(SOURCE / id.lower() / "manifest.json")
            board = view_frame(manifest, cell)
            canvas = Image.new("RGB", viewport, "#243127")
            canvas.paste(board, (round(24 * scale), round(85 * scale)))
            draw = ImageDraw.Draw(canvas)
            draw.text((round(24 * scale), round(35 * scale)), f'{id}  {manifest["region"]}',
                      fill="#f4ead7", font=font)
            draw.text((round(24 * scale), round(545 * scale)), manifest["landmark"],
                      fill="#f4ead7", font=font)
            canvas.save(REVIEW / f"{id.lower()}_{cell}.jpg", quality=88, optimize=True)
            boards.append((board, manifest))
        thumb = 600 if cell == 80 else 450
        font = ImageFont.truetype("DejaVuSans.ttf", 19 if cell == 80 else 16)
        small = ImageFont.truetype("DejaVuSans.ttf", 14 if cell == 80 else 12)
        row_height = round(thumb * 430 / 1232) + 62
        sheet = Image.new("RGB", (2 * thumb + 48, 3 * row_height + 60), "#243127")
        draw = ImageDraw.Draw(sheet)
        draw.text((16, 16), f"Kenyalang Rangers  ·  Chapter 2 terrain  ·  {cell} px tiles",
                  fill="#f5ead3", font=font)
        for index, (board, manifest) in enumerate(boards):
            x, y = (16 + (index % 2) * (thumb + 16), 52 + (index // 2) * row_height)
            fitted = board.resize((thumb, round(thumb * 430 / 1232)), Image.Resampling.LANCZOS)
            sheet.paste(fitted, (x, y))
            draw.text((x, y + fitted.height + 9), f'{manifest["id"]}  {manifest["region"]}',
                      fill="#f5ead3", font=font)
            draw.text((x, y + fitted.height + 32), manifest["landmark"], fill="#cfd3b2", font=small)
        sheet.save(REVIEW / f"regional_boards_{cell}.jpg", quality=90, optimize=True)


def godot_check(textures):
    expected = "4.7.2.stable.official.ed1daf0bf"
    assert subprocess.check_output(["godot", "--version"], text=True).strip() == expected
    with tempfile.TemporaryDirectory(prefix="w29-regional-import-") as dir_name:
        path = Path(dir_name)
        (path / "project.godot").write_text('[application]\nconfig/name="W29 regional import"\n'
                                          '[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        for texture in textures:
            file = path / texture
            file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / texture, file)
        (path / "data.json").write_text(json.dumps(textures))
        (path / "probe.gd").write_text('''extends SceneTree

func _initialize() -> void:
	var textures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data.json"))
	for path: String in textures:
		var art := load("res://" + path) as Texture2D
		var size: Array = textures[path]
		if art == null or art.get_width() != int(size[0]) or art.get_height() != int(size[1]):
			printerr("Texture import mismatch: " + path)
			quit(1)
			return
	print("Godot: " + str(textures.size()) + " regional and shared textures loaded at expected dimensions.")
	quit()
''')
        subprocess.run(["godot", "--headless", "--editor", "--path", dir_name, "--import", "--quit"],
                       check=True, capture_output=True, timeout=120)
        results = subprocess.run(["godot", "--headless", "--path", dir_name, "--script", "probe.gd"],
                                 check=True, capture_output=True, text=True, timeout=60)
        print(results.stdout.strip())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true", help="Regenerate outputs from the registered masters")
    parser.add_argument("--previews", action="store_true", help="Write visual projections of the five actual boards")
    parser.add_argument("--godot", action="store_true", help="Verify actual engine imports in an isolated project")
    args = parser.parse_args()
    if args.build:
        build_shared()
        for id in MAPS:
            build_region(id)
    textures = verify_registry()
    if args.previews:
        make_previews()
    if args.godot:
        godot_check(textures)


if __name__ == "__main__":
    main()
