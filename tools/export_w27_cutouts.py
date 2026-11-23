"""Export or check the independently drawn W27 SVG layers (Inkscape and Pillow)."""

import argparse
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
UNITS = ("rangers/patrolman", "enemies/e01")
PADDING = 4
DENSITY = 4


def sha256(file):
    return hashlib.sha256(file.read_bytes()).hexdigest()


def render(source, raster, layer=None):
    command = ["inkscape", str(source), "--export-area-page", "--export-width=384",
               f"--export-filename={raster}"]
    if layer:
        command += [f"--export-id={layer}", "--export-id-only"]
    subprocess.run(command, check=True, capture_output=True)
    with Image.open(raster) as image:
        return image.convert("RGBA")


def opaque_joint(alpha, pivot):
    """A two-unit disk in each neighboring part survives rotation about that joint."""
    radius = 2 * DENSITY
    x, y = (v * DENSITY for v in pivot)
    return all(
        alpha.getpixel((px, py)) >= 240
        for px in range(int(x) - radius, int(x) + radius + 1)
        for py in range(int(y) - radius, int(y) + radius + 1)
        if (px + 0.5 - x) ** 2 + (py + 0.5 - y) ** 2 <= radius ** 2
    )


def export_unit(unit, scratch, write):
    path = ROOT / "assets/source-art" / unit / "manifest.json"
    original = json.loads(path.read_text())
    result = copy.deepcopy(original)
    source = ROOT / result["source_svg"]
    layers = [node.attrib["id"] for node in ET.parse(source).getroot()
              if node.tag == "{http://www.w3.org/2000/svg}g"]
    parts = sorted(result["parts"], key=lambda part: part["draw_order"])
    assert layers == [part["svg_layer_id"] for part in parts], unit

    merged = Image.new("RGBA", (384, 384))
    masks = {}
    generated = {}
    raster = scratch / "full.png"
    for part in parts:
        key = part["id"]
        image = render(source, raster, part["svg_layer_id"])
        alpha = image.getchannel("A")
        support = alpha.point(lambda value: 255 if value >= 16 else 0)
        support_left, support_top, support_right, _ = support.getbbox()
        first_x = next(x for x in range(support_left, support_right)
                       if support.getpixel((x, support_top)) == 255)
        ImageDraw.floodfill(support, (first_x, support_top), 128)
        assert support.getextrema()[1] == 128, f"Detached alpha in {unit}/{key}"
        masks[key] = alpha
        left, top, right, bottom = alpha.getbbox()
        assert min(left, top, 384 - right, 384 - bottom) >= PADDING, key
        box = (left - PADDING, top - PADDING, right + PADDING, bottom + PADDING)
        cropped = image.crop(box)
        assert cropped.getchannel("A").getbbox() == (
            PADDING, PADDING, cropped.width - PADDING, cropped.height - PADDING), key
        preview = scratch / f"{key}.png"
        cropped.save(preview, optimize=True)
        generated[ROOT / part["png"]] = preview
        pivot = part["pivot_canvas_units"]
        part.update(
            canvas_rect_px=[box[0], box[1], cropped.width, cropped.height],
            pivot_canvas_normalized=[round(v / 96, 8) for v in pivot],
            pivot_local_px=[round(v * DENSITY - start, 6) for v, start in zip(pivot, box)],
            sha256=sha256(preview),
        )
        merged.alpha_composite(cropped, box[:2])

    for part in parts:
        for key in (part["id"], part["parent"]):
            if key is not None:
                assert opaque_joint(masks[key], part["pivot_canvas_units"]), (
                    unit, part["id"], key, part["pivot_canvas_units"])
    master = render(source, raster)
    difference = ImageChops.difference(merged.convert("RGBa"), master.convert("RGBa"))
    greatest_error = max(high for _, high in difference.getextrema())
    assert greatest_error <= 3, (unit, greatest_error)
    reference_path = ROOT / result["study_reference"]
    assert sha256(reference_path) == result["study_reference_sha256"], unit
    with Image.open(reference_path) as reference:
        comparison = ImageChops.difference(merged.convert("RGBa"), reference.convert("RGBa"))
    study_error = max(high for _, high in comparison.getextrema())
    assert study_error <= 2, (unit, study_error)
    result["study_reassembly_max_delta"] = study_error
    left, top, right, bottom = master.getchannel("A").getbbox()
    result.update(
        source_sha256=sha256(source),
        art_bounds_units=[v / DENSITY for v in (left, top, right - left, bottom - top)],
        measured_visible_height_units=(bottom - top) / DENSITY,
        neutral_rgba_reassembly_max_delta=greatest_error,
    )
    if write:
        for file, preview in generated.items():
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(preview.read_bytes())
        path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    else:
        assert original == result, f"Manifest does not match raster export for {unit}"
        for file, preview in generated.items():
            assert file.read_bytes() == preview.read_bytes(), file

    print(f"{result['display_name']}: {len(parts)} transparent parts, "
          f"{len(parts) - 1} joined pivots, {result['measured_visible_height_units']} units, "
          f"maximum premultiplied delta: master {greatest_error}/255, study {study_error}/255")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="Refresh parts and measured metadata")
    options = parser.parse_args()
    for unit in UNITS:
        with tempfile.TemporaryDirectory(prefix="w27-cutout-") as scratch:
            export_unit(unit, Path(scratch), options.write)


if __name__ == "__main__":
    main()
