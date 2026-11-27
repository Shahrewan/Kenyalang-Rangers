"""Check C37 source receipts and optionally validate the exported Android launcher bitmaps."""
import argparse
from hashlib import sha256
from io import BytesIO
import json
from math import hypot
from pathlib import Path
from xml.etree import ElementTree
from zipfile import ZipFile

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "assets/source-art/ui/w29/manifest.json"
CREAM = (246, 234, 208)
OLIVE = (53, 70, 33)
DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ICON_KEYS = {
    "icon": "main_192x192",
    "icon_background": "adaptive_background_432x432",
    "icon_foreground": "adaptive_foreground_432x432",
    "icon_monochrome": "adaptive_monochrome_432x432",
}


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def resolve(resource):
    return ROOT / resource.removeprefix("res://")


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def source_image(path):
    with Image.open(path) as source:
        return source.convert("RGBA")


def svg_emblem(path, color):
    document = ElementTree.parse(path).getroot()
    require(document.attrib["viewBox"] == "0 0 140 113", f"Emblem viewBox differs in {path}")
    visible = [node for node in document if not node.tag.endswith("title")]
    require(len(visible) == 1 and visible[0].tag.endswith("path") and visible[0].get("fill", "").lower() == color,
            f"Expected a transparent, single-color emblem in {path}")
    return {key: value for key, value in visible[0].attrib.items() if key != "fill"}


def check_source():
    menu = json.loads(MENU.read_text())
    catalog = json.loads((ROOT / "data/presentation/w29/art_catalog.json").read_text())
    require(catalog["brand"] == menu["brand"] and catalog["android_launcher"] == menu["android_launcher"],
            "Brand art catalog differs from its W29 receipt")
    for resource in [*menu["brand"].values(), *menu["android_launcher"].values()]:
        path = resolve(resource)
        require(menu["exports"][path.relative_to(ROOT).as_posix()] == digest(path),
                f"Stale brand export receipt for {path}")
    for variant in ("app_icon", "hornbill", "hornbill_dark"):
        path = resolve(menu["brand"][variant])
        require(path.read_bytes() == (MENU.parent / "brand" / path.name).read_bytes(),
                f"Source master differs for {variant}")
    cream = svg_emblem(resolve(menu["brand"]["hornbill"]), "#f6ead0")
    olive = svg_emblem(resolve(menu["brand"]["hornbill_dark"]), "#354621")
    require(cream == olive, "Cream and olive emblems must use the same geometry")
    project = (ROOT / "project.godot").read_text()
    require(f'config/icon="{menu["brand"]["app_icon"]}"' in project
            and f'boot_splash/image="{menu["brand"]["splash"]}"' in project,
            "Project icon or startup mark differs from the catalog")
    require(f'path="{menu["brand"]["hornbill"]}"' in (ROOT / "scenes/menus/main_menu.tscn").read_text(),
            "Main Menu must use the canonical cream emblem")
    hq = json.loads((ROOT / "assets/source-art/hq/manifest.json").read_text())
    for row in (hq["shell"]["lobby"], hq["overview"], hq["opening"]):
        require(digest(ROOT / row["texture"]) == row["sha256"], f"Stale HQ branding texture {row['texture']}")
    require(ROOT / hq["reception_emblem"] == MENU.parent / "brand/hornbill_dark.svg", "HQ source mark differs")

    preset = (ROOT / "export_presets.cfg").read_text()
    icons = {}
    for name, option in ICON_KEYS.items():
        resource = menu["android_launcher"][option]
        require(f'launcher_icons/{option}="{resource}"' in preset, f"Android preset is missing {option}")
        image = source_image(resolve(resource))
        size = 192 if name == "icon" else 432
        require(image.size == (size, size), f"{option} must be {size} square")
        icons[name] = image
    require(icons["icon_background"].getcolors() == [(432 * 432, (*OLIVE, 255))],
            "Adaptive background must be opaque olive")
    legacy_colors = {color for _, color in icons["icon"].getcolors(192 * 192)}
    require(icons["icon"].getchannel("A").getextrema() == (255, 255)
            and {(*CREAM, 255), (*OLIVE, 255)} <= legacy_colors,
            "Legacy icon needs both palette colors and a solid background")
    foreground = icons["icon_foreground"].getchannel("A")
    require(foreground.tobytes() == icons["icon_monochrome"].getchannel("A").tobytes(),
            "Adaptive foreground and themed mask must have the same silhouette")
    radius = max(hypot(x + 0.5 - 216, y + 0.5 - 216)
                 for y in range(432) for x in range(432) if foreground.getpixel((x, y)))
    require(radius <= 132, f"Adaptive art extends past the 264 px safe circle: {radius:.2f}px")
    print(f"PASS source and export receipts, cream/olive geometry, adaptive radius {radius:.2f}/132 px")
    return menu, icons


def verify_apk(path, menu, icons):
    with ZipFile(path) as apk:
        files = set(apk.namelist())
        for name, size in [*DENSITIES.items(), ("default", 192)]:
            directory = "res/mipmap" if name == "default" else f"res/mipmap-{name}-v4"
            for layer, original in icons.items():
                packed = Image.open(BytesIO(apk.read(f"{directory}/{layer}.webp"))).convert("RGBA")
                edge = size if layer == "icon" else size * 108 // 48
                require(packed.size == (edge, edge), f"Unexpected {name} {layer} size {packed.size}")
                if packed.size == original.size:
                    # WebP conversion may adjust RGB in semitransparent edge pixels.
                    base = Image.new("RGBA", packed.size)
                    alpha = original.getchannel("A")
                    opaque = alpha.point(lambda value: 255 if value == 255 else 0)
                    error = ImageChops.difference(original, packed)
                    require(alpha.tobytes() == packed.getchannel("A").tobytes()
                            and Image.composite(error, base, opaque).getbbox(alpha_only=False) is None,
                            f"Packaged {name} {layer} differs in silhouette or solid color")
        require("res/mipmap-anydpi-v26/icon.xml" in files, "Adaptive icon XML was not packaged")
        splash = menu["brand"]["splash"].removeprefix("res://")
        require(apk.read("assets/" + splash) == (ROOT / splash).read_bytes(), "Packaged Godot splash differs")
        require("assets/" + splash + ".import" not in files, "Only the raw Godot splash is required")
        require(not any("assets/source-art/" in path or "/brand/android/" in path
                        or path.endswith((".ico", "launcher_mask_preview.jpg")) for path in files),
                "Source/unused platform assets leaked into the game payload")
    print("PASS 24 launcher bitmaps, adaptive XML, byte-identical startup PNG and selective game payload")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path)
    options = parser.parse_args()
    menu, icons = check_source()
    if options.apk:
        verify_apk(options.apk, menu, icons)


if __name__ == "__main__":
    main()
