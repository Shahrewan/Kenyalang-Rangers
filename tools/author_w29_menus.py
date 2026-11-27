"""Build the original W29 shell graphics, Godot Theme, and source receipt."""

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source-art/ui/w29"
ACTIVE = ROOT / "assets/imported/ui/w29"
DESIGN = ROOT / "resources/presentation/w29_ui_theme.tres"

PALETTE = {
    "shadow": "#222b22",
    "forest": "#343d32",
    "ink": "#283226",
    "olive": "#69734a",
    "sage": "#87916b",
    "muted": "#d6c8ad",
    "paper": "#f3ebdd",
    "warm": "#e8dbbe",
    "sand": "#bb9d73",
    "amber": "#e8b957",
    "rust": "#bc6550",
}

# The fill, inset edge, lower rim and shade represent the same reed-paper,
# stained timber and brass palette as the illustrated First Contact controls.
FRAME_COLORS = {
    "forest": ("#354337", "#657050", "#232c23"),
    "deep_forest": ("#263328", "#4d5c42", "#202720"),
    "paper": ("#f3ebdd", "#dac8a2", "#b79b73"),
    "parchment": ("#e7d9bd", "#f4e9d2", "#9b8465"),
    "button": ("#e9dfc9", "#fff3dc", "#ad9472"),
    "button_hover": ("#fff0ce", "#fff8e8", "#af8d5d"),
    "button_down": ("#cdbc9e", "#e4d2ae", "#9e825e"),
    "primary": ("#e8b957", "#f9d98b", "#ac7834"),
    "primary_hover": ("#f4cd75", "#ffe8a4", "#ba873d"),
    "primary_down": ("#d9a547", "#edc370", "#91672b"),
    "disabled": ("#5a6152", "#7e8271", "#3b4136"),
    "danger": ("#713d34", "#a55f4d", "#482e27"),
    "danger_hover": ("#8b483d", "#bc6550", "#583129"),
    "danger_down": ("#60382d", "#915343", "#38241d"),
    "selected": ("#52613f", "#99a371", "#344230"),
    "input": ("#efe5cb", "#fff3db", "#af906a"),
    "track": ("#29342a", "#59634b", "#202820"),
    "fill": ("#94a174", "#c4cd9d", "#566842"),
    "warning": ("#ad6348", "#e0a365", "#733a2f"),
}

# User-facing text is authored by the view and stays outside the glyphs.
# Keep compact controls legible by shape as well as color.
GLYPHS = {
    "back": '<path d="M23 7l-9 9 9 9M15 16H5"/>',
    "forward": '<path d="M9 7l9 9-9 9M17 16h10"/>',
    "close": '<path d="m8 8 16 16M24 8 8 24"/>',
    "headquarters": '<path d="M4 27h24M7 27V9h9V5h9v22M11 14h2m-2 5h2m5-9h3m-3 5h3m-3 5h3m-3 7v-4h3v4"/>',
    "campaign": '<path d="M6 6v20M6 7c4-4 8 2 13 0l6-2v15l-6 2c-5 2-9-4-13 0"/>',
    "chaos": '<path d="M5 25c9-14 8-19 20-20-2 13-7 19-20 20Zm9-15 3 6 6 1m-8 1-5 1M20 27l5-5m-1 5h5"/>',
    "restoration": '<path d="M16 27V15m0 5C6 20 5 11 5 7c8 0 11 6 11 13Zm0-5c0-7 6-10 11-10-1 6-5 10-11 10ZM7 27h18"/>',
    "settings": '<path d="M7 5v8m0 6v8m9-22v15m0 5v2m9-22v3m0 5v14M4 13h6v6H4zm9 7h6v5h-6zm9-12h6v5h-6z"/>',
    "guide": '<path d="M5 5h10a3 3 0 0 1 3 3v19a4 4 0 0 0-4-4H5zm13 3 2-3h7v18h-5a4 4 0 0 0-4 4M8 10h6m-6 4h6m7-4h3m-3 4h3"/>',
    "control": '<path d="M5 6h22v16H5zM11 27h10m-5-5v5M9 15l5-2 4 3 5-6"/><circle cx="23" cy="10" r="1"/>',
    "human_resources": '<path d="M5 9h22v17H5zM13 9V5h6v4m0 7h5m-5 4h5M8 22c0-5 7-5 7 0"/><circle cx="11.5" cy="14.5" r="2.5"/>',
    "finance": '<path d="M6 6h20v20H6zM6 13h20M13 6v20m4-9h5m-5 5h5M9 9h1m8 0h5"/>',
    "mechanical": '<path d="M22 4a6 6 0 0 0-7 8L5 22a3 3 0 0 0 4 4l10-10a6 6 0 0 0 8-7l-4 3-3-3z"/>',
    "ecology": '<path d="M13 5h6m-5 0v7L6 25q-1 3 2 3h16q3 0 2-3l-8-13V5M10 21h13m-7 0c-.5-4-2.5-5-5-6 0 4 2 6 5 6Z"/>',
    "outreach": '<path d="M5 7h22v15H16l-7 5v-5H5zM10 12h12m-12 5h8"/>',
    "records": '<path d="M5 10h22v16H5zM7 5h18v5H7zM12 15h8v5h-8z"/>',
    "research": '<path d="M12 5h8m-6 0v7L6 25a2 2 0 0 0 2 3h16a2 2 0 0 0 2-3l-8-13V5M10 21h12"/><circle cx="16" cy="17" r="1"/>',
    "ranger": '<path d="M6 19c1-8 6-13 13-13 5 1 6 6 7 10l3 2h-8L4 22zM11 22c4 6 10 6 14 1"/>',
    "facility": '<path d="M5 27h22m-19 0V16h16v11M6 16l10-8 10 8zM14 27v-7h4v7m2-13V6h4"/>',
    "map": '<path d="m4 8 8-3 8 3 8-3v19l-8 3-8-3-8 3zM12 5v19m8-16v19"/>',
    "intel": '<path d="M3 16c5-7 10-9 13-9s8 2 13 9c-5 7-10 9-13 9S8 23 3 16Z"/><circle cx="16" cy="16" r="4"/>',
    "lock": '<path d="M10 14V9a6 6 0 1 1 12 0v5M7 14h18v13H7zm9 5v4"/>',
    "check": '<path d="m6 16 6 7L27 8"/>',
    "perfect": '<path d="m16 4 3.5 7.1 7.8 1.1-5.7 5.5 1.4 7.8-7-3.7-7 3.7 1.4-7.8-5.7-5.5 7.8-1.1z"/>',
    "warning": '<path d="M16 5 29 27H3Zm0 7v7m0 4v1"/>',
    "retry": '<path d="M6 13A11 11 0 1 1 6 21M5 5v9h9"/>',
    "clock": '<circle cx="16" cy="17" r="11"/><path d="M16 10v7l5 3M13 3h6"/>',
    "heal": '<path d="M13 5h6v8h8v6h-8v8h-6v-8H5v-6h8z"/>',
    "repair": '<path d="M6 8h12l5 4-5 5h-4v10H8V17H6zm3 9h5m10-8v10m-4 4h8"/>',
    "attack": '<path d="m8 24 10-9 2 2-7 11zm7-9L25 4l2 2-8 13m-7-5 10 9"/>',
    "defense": '<path d="M16 4c3 3 6 4 11 5v7c0 5-4 9-11 12C9 25 5 21 5 16V9c5-1 8-2 11-5Z"/>',
    "support": '<path d="M5 23h22M7 15h18M16 5v22m-7-8 7-7 7 7"/>',
    "specialist": '<path d="M16 4l5 7 7 5-7 5-5 7-5-7-7-5 7-5z"/><circle cx="16" cy="16" r="4"/>',
    "technology": '<rect x="8" y="8" width="16" height="16" rx="3"/><rect x="13" y="13" width="6" height="6" rx="1"/><path d="M12 4v4m8-4v4m-8 16v4m8-4v4M4 12h4m-4 8h4m16-8h4m-4 8h4"/>',
    "siege": '<path d="M5 24h22M7 24v-7h17v7M8 15 22 6l3 4-13 9M14 22h3"/>',
    "aerial": '<path d="M5 14h22m-20-3v6m18-6v6M11 14l2 8h6l2-8m-7 11h4"/>',
    "heavy": '<path d="M7 24h18L22 9H10zm6-15V5h6v4m-8 15v3m10-3v3"/>',
    "fog": '<path d="M4 10h21M7 16h21M4 22h20m-2-12 2-4m-7 16 3 5"/>',
    "sound": '<path d="M5 13h5l6-6v18l-6-6H5zm14-2q8 5 0 10m4-13q12 8 0 16"/>',
    "mute": '<path d="M5 13h5l6-6v18l-6-6H5zm14-1 8 8m0-8-8 8"/>',
    "water": '<path d="M16 4C12 11 7 15 7 21a9 9 0 0 0 18 0c0-6-5-10-9-17Zm-4 17c0 2 1 4 3 5"/>',
    "add": '<path d="M16 6v20M6 16h20"/>',
    "minus": '<path d="M6 16h20"/>',
    "play": '<path d="M10 6v20l16-10z"/>',
    "pause": '<path d="M10 7h4v18h-4zm8 0h4v18h-4z"/>',
    "toggle_on": '<rect x="3" y="7" width="26" height="18" rx="9"/><path fill="currentColor" d="M26 16a6 6 0 1 1-12 0 6 6 0 0 1 12 0Z"/>',
    "toggle_off": '<rect x="3" y="7" width="26" height="18" rx="9"/><path fill="currentColor" d="M18 16a6 6 0 1 1-12 0 6 6 0 0 1 12 0Z"/>',
    "caret": '<path d="m8 12 8 8 8-8"/>',
    "list": '<path d="M11 8h16M11 16h16M11 24h16M5 8h1m-1 8h1m-1 8h1"/>',
    "quiz": '<path d="M7 5h18v22H7zm5 7a4 4 0 0 1 8 0c0 3-4 3-4 6m0 3v1"/>',
    "heat": '<path d="M16 4c4 5 5 8 3 11 3-1 4-3 4-4 3 5 4 11 0 14-4 4-12 3-15-1-3-4 0-9 3-12 0 3 1 4 2 4 2-3 3-7 3-12Z"/>',
    "construct": '<path d="M4 25h24M6 20h20M9 20l3-12h8l3 12M12 13h8m-10 4h12"/>',
}

MODIFIER_GLYPHS = {
    "benefit_eco": "ecology",
    "benefit_combat": "attack",
    "benefit_guard": "defense",
    "benefit_crisis": "warning",
    "challenge_environment": "heat",
    "challenge_enemy": "intel",
    "challenge_loadout": "lock",
    "challenge_logistics": "construct",
    "configuration": "settings",
}

MODIFIER_ID_GROUPS = {
    **{f"B{number:02}": "benefit_eco" for number in range(1, 5)},
    **{f"B{number:02}": "benefit_combat" for number in range(5, 9)},
    **{f"B{number:02}": "benefit_guard" for number in range(9, 13)},
    **{f"B{number:02}": "benefit_crisis" for number in range(13, 16)},
    **{number: "challenge_logistics" for number in ("D01", "D04", "D05", "D07", "D10", "D12")},
    **{number: "challenge_enemy" for number in ("D02", "D06", "D08", "D09", "D11", "D13", "D15")},
    "D03": "challenge_loadout",
    "D14": "challenge_environment",
}

REUSE = {
    "funds": "res://assets/imported/first_contact/parts/interface/funds.png",
    "tokens": "res://assets/imported/first_contact/parts/interface/token.png",
    "integrity": "res://assets/imported/first_contact/parts/interface/integrity.png",
    "wave": "res://assets/imported/first_contact/parts/interface/wave.png",
    "story_map": "res://assets/imported/first_contact/story_node_backplate.svg",
    "perfect_receipt": "res://assets/imported/first_contact/parts/interface/result_perfect.png",
    "clear_receipt": "res://assets/imported/first_contact/parts/interface/result_clear.png",
    "defeat_receipt": "res://assets/imported/first_contact/parts/interface/result_defeat.png",
    "first_contact": "res://assets/imported/first_contact/t01_forest_backdrop.jpg",
    "garden": "res://assets/imported/restoration/garden_clearing.jpg",
}

FERN = """<g fill="#88916b" stroke="#657254" stroke-width="1.25" stroke-linecap="round">
  <path d="M11 72Q40 35 72 9M22 66q9-21 25-28-2 17-22 29ZM31 52q3-17 12-26 4 15-8 25Z"/>
  <path d="M40 42q5-18 18-26-4 17-16 27Zm13-14q7-14 20-17-6 13-18 18ZM22 64Q15 49 20 38q11 7 5 23Zm12-13q-5-14 3-23 6 10 0 22Z"/>
  <path d="M26 66q13-6 24-1-10 7-24 3Zm13-13q16-9 25-3-11 7-25 3Zm11-12q15-10 22-4-12 6-22 4Z"/>
</g>"""

FONT_FILES = ["NotoSans-Regular.ttf", "NotoSans-Bold.ttf", "NotoSerif-Bold.ttf"]


def svg(width, height, body, title):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
        f"<title>{title}</title>\n{body}\n</svg>\n"
    )


def frame(fill, inset, rim):
    return (
        '<rect x="3" y="3" width="90" height="61" rx="12" fill="#263025"/>\n'
        f'<rect x="4" y="3" width="88" height="58" rx="11" fill="{rim}"/>\n'
        f'<rect x="4" y="3" width="88" height="55" rx="11" fill="{fill}" '
        'stroke="#283226" stroke-width="2.4"/>\n'
        '<path d="M16 7.5H80a7 7 0 0 1 7.5 7M8.5 15a7.5 7.5 0 0 1 7.5-7.5" '
        f'fill="none" stroke="{inset}" stroke-width="1.7" stroke-linecap="round"/>'
    )


def focus_frame():
    return (
        '<rect x="2" y="2" width="92" height="63" rx="12" '
        'fill="none" stroke="#f3ca72" stroke-width="3"/>'
        '<rect x="5" y="5" width="86" height="57" rx="10" '
        'fill="none" stroke="#2e392b" stroke-width="1"/>'
    )


def texture_path(relative):
    return f"res://{(ACTIVE / relative).relative_to(ROOT).as_posix()}"


def save_art(relative, content):
    for directory in (SOURCE, ACTIVE):
        path = directory / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def color(hex_value):
    values = [int(hex_value[index:index+2], 16) / 255 for index in (1, 3, 5)]
    return f"Color({', '.join(f'{part:.6f}' for part in values)}, 1)"


def but_styles(variant, keys, ink):
    normal, hover, pressed, disabled = keys
    values = {
        "normal": normal,
        "hover": hover,
        "pressed": pressed,
        "hover_pressed": pressed,
        "disabled": disabled,
        "focus": "focus",
    }
    lines = {
        f"{variant}/styles/{name}": f'SubResource("{key}")'
        for name, key in values.items()
    }
    for term in ("font", "font_hover", "font_pressed", "font_hover_pressed", "font_focus"):
        lines[f"{variant}/colors/{term}_color"] = color(ink)
    lines[f"{variant}/colors/font_disabled_color"] = color("#eee4cd")
    lines[f"{variant}/constants/h_separation"] = "11"
    lines[f"{variant}/constants/icon_max_width"] = "24"
    lines[f"{variant}/font_sizes/font_size"] = "20"
    return lines


def stylebox(name):
    content = 15 if name in {"forest", "deep_forest", "paper", "parchment"} else 10
    texture_margin = 16
    result = [
        f'[sub_resource type="StyleBoxTexture" id="{name}"]',
        f'texture = ExtResource("frame_{name}")',
    ]
    for axis in ("left", "top", "right", "bottom"):
        result.append(f"texture_margin_{axis} = {texture_margin}.0")
        result.append(f"content_margin_{axis} = {content}.0")
    if name == "focus":
        result.append("draw_center = false")
    return "\n".join(result)


def flat_stylebox(name, fill, border):
    output = [
        f'[sub_resource type="StyleBoxFlat" id="{name}"]',
        f"bg_color = {color(fill)}",
        f"border_color = {color(border)}",
    ]
    for axis in ("left", "top", "right", "bottom"):
        output.extend((f"border_width_{axis} = 2", f"content_margin_{axis} = 3.0"))
    for corner in ("top_left", "top_right", "bottom_left", "bottom_right"):
        output.append(f"corner_radius_{corner} = 6")
    return "\n".join(output)


def theme(frame_names):
    external = [
        f'[ext_resource type="Texture2D" path="{texture_path(f"frames/{name}.svg")}" id="frame_{name}"]'
        for name in frame_names
    ]
    for font in FONT_FILES:
        external.append(
            f'[ext_resource type="FontFile" path="{texture_path(f"fonts/{font}")}" id="{Path(font).stem}"]'
        )
    for icon in ("lock", "check", "toggle_on", "toggle_off", "caret", "close"):
        external.append(
            f'[ext_resource type="Texture2D" path="{texture_path(f"icons/light/{icon}.svg")}" id="glyph_{icon}"]'
        )
    panels = [stylebox(name) for name in frame_names]
    panels.extend((
        flat_stylebox("meter_track", "#283528", "#788266"),
        flat_stylebox("meter_fill", "#839664", "#a5b382"),
        flat_stylebox("meter_alert", "#a85843", "#d99263"),
    ))
    plain = ("button", "button_hover", "button_down", "disabled")
    primary = ("primary", "primary_hover", "primary_down", "disabled")
    danger = ("danger", "danger_hover", "danger_down", "disabled")
    selected = ("selected", "forest", "deep_forest", "disabled")
    output = {
        "default_font": 'ExtResource("NotoSans-Regular")',
        "default_font_size": "20",
    }
    output.update(but_styles("Button", plain, PALETTE["ink"]))
    for name, keys, foreground in (
        ("PrimaryButton", primary, PALETTE["ink"]),
        ("DangerButton", danger, PALETTE["paper"]),
        ("NavButton", selected, PALETTE["paper"]),
    ):
        output[f"{name}/base_type"] = '&"Button"'
        output.update(but_styles(name, keys, foreground))
    for type_name, base, style in (
        ("PanelContainer", None, "forest"), ("Panel", None, "forest"),
        ("LightPanel", "PanelContainer", "paper"), ("FieldPanel", "PanelContainer", "deep_forest"),
        ("BrassPanel", "PanelContainer", "parchment"), ("DialogPanel", "PanelContainer", "paper"),
    ):
        if base is not None:
            output[f"{type_name}/base_type"] = f'&"{base}"'
        output[f"{type_name}/styles/panel"] = f'SubResource("{style}")'
    for type_name, font, size, fill in (
        ("Label", "NotoSans-Regular", 20, PALETTE["paper"]),
        ("FieldTitle", "NotoSerif-Bold", 35, PALETTE["paper"]),
        ("PaperTitle", "NotoSerif-Bold", 32, PALETTE["ink"]),
        ("FieldStrong", "NotoSans-Bold", 22, PALETTE["paper"]),
        ("FieldMeta", "NotoSans-Regular", 17, PALETTE["muted"]),
        ("PaperText", "NotoSans-Regular", 20, PALETTE["ink"]),
        ("PaperStrong", "NotoSans-Bold", 23, PALETTE["ink"]),
        ("PaperMeta", "NotoSans-Regular", 17, "#5a5d46"),
    ):
        if type_name != "Label":
            output[f"{type_name}/base_type"] = '&"Label"'
        output[f"{type_name}/fonts/font"] = f'ExtResource("{font}")'
        output[f"{type_name}/font_sizes/font_size"] = str(size)
        output[f"{type_name}/colors/font_color"] = color(fill)
    for box in ("HBoxContainer", "VBoxContainer"):
        output[f"{box}/constants/separation"] = "12"
    for axis in ("h", "v"):
        output[f"GridContainer/constants/{axis}_separation"] = "12"
    for type_name in ("LineEdit", "TextEdit"):
        for style, frame_name in (("normal", "input"), ("read_only", "parchment"), ("focus", "focus")):
            output[f"{type_name}/styles/{style}"] = f'SubResource("{frame_name}")'
        for name in ("font_color", "font_uneditable_color", "caret_color", "font_placeholder_color"):
            output[f"{type_name}/colors/{name}"] = color(PALETTE["ink"])
        output[f"{type_name}/colors/selection_color"] = color("#d7ad52")
    output.update(but_styles("OptionButton", plain, PALETTE["ink"]))
    output.update(but_styles("CheckButton", selected, PALETTE["paper"]))
    output["CheckButton/icons/checked"] = 'ExtResource("glyph_toggle_on")'
    output["CheckButton/icons/unchecked"] = 'ExtResource("glyph_toggle_off")'
    output["CheckButton/icons/checked_disabled"] = 'ExtResource("glyph_toggle_on")'
    output["CheckButton/icons/unchecked_disabled"] = 'ExtResource("glyph_toggle_off")'
    output["OptionButton/icons/arrow"] = 'ExtResource("glyph_caret")'
    output["OptionButton/colors/arrow_color"] = color(PALETTE["ink"])
    for type_name in ("VScrollBar", "HScrollBar"):
        for style, box in (("scroll", "meter_track"), ("scroll_focus", "meter_track"), ("grabber", "meter_fill"),
                           ("grabber_highlight", "meter_fill"), ("grabber_pressed", "meter_alert")):
            output[f"{type_name}/styles/{style}"] = f'SubResource("{box}")'
    for type_name in ("HSlider", "VSlider"):
        output[f"{type_name}/styles/slider"] = 'SubResource("meter_track")'
        output[f"{type_name}/styles/grabber_area"] = 'SubResource("meter_fill")'
        output[f"{type_name}/styles/grabber_area_highlight"] = 'SubResource("meter_fill")'
    for type_name in ("ProgressBar", "DangerMeter"):
        if type_name == "DangerMeter":
            output[f"{type_name}/base_type"] = '&"ProgressBar"'
        output[f"{type_name}/styles/background"] = 'SubResource("meter_track")'
        field = "meter_alert" if type_name == "DangerMeter" else "meter_fill"
        output[f"{type_name}/styles/fill"] = f'SubResource("{field}")'
        output[f"{type_name}/colors/font_color"] = color(PALETTE["paper"])
    output["AcceptDialog/styles/panel"] = 'SubResource("forest")'
    output["PopupMenu/styles/panel"] = 'SubResource("forest")'
    output["PopupMenu/styles/hover"] = 'SubResource("selected")'
    output["PopupMenu/constants/v_separation"] = "16"
    output["PopupMenu/colors/font_color"] = color(PALETTE["paper"])
    output["PopupMenu/colors/font_hover_color"] = color(PALETTE["paper"])
    output["PopupMenu/colors/font_disabled_color"] = color(PALETTE["muted"])
    output["PopupMenu/icons/checked"] = 'ExtResource("glyph_check")'
    output["Window/styles/embedded_border"] = 'SubResource("forest")'
    output["Window/styles/embedded_unfocused_border"] = 'SubResource("deep_forest")'
    output["Window/icons/close"] = 'ExtResource("glyph_close")'
    output["Window/icons/close_pressed"] = 'ExtResource("glyph_close")'
    output["Window/fonts/title_font"] = 'ExtResource("NotoSans-Bold")'
    output["Window/colors/title_color"] = color(PALETTE["paper"])
    output["Window/constants/title_height"] = "36"
    for type_name in ("TabBar", "TabContainer"):
        for state, frame_name in (("tab_selected", "selected"), ("tab_unselected", "deep_forest"),
                                  ("tab_hovered", "forest"), ("tab_disabled", "disabled")):
            output[f"{type_name}/styles/{state}"] = f'SubResource("{frame_name}")'
        for key in ("font_selected_color", "font_unselected_color", "font_hovered_color"):
            output[f"{type_name}/colors/{key}"] = color(PALETTE["paper"])
        output[f"{type_name}/colors/font_disabled_color"] = color(PALETTE["muted"])
    output["TabContainer/styles/panel"] = 'SubResource("forest")'
    output["ItemList/styles/panel"] = 'SubResource("forest")'
    output["ItemList/styles/selected"] = 'SubResource("selected")'
    output["ItemList/styles/selected_focus"] = 'SubResource("selected")'
    output["ItemList/colors/font_color"] = color(PALETTE["paper"])
    entries = "\n".join(f"{key} = {value}" for key, value in output.items())
    opening = f'[gd_resource type="Theme" load_steps={1 + len(external) + len(panels)} format=3]'
    DESIGN.write_text("\n\n".join([opening, "\n".join(external), *panels, "[resource]\n" + entries])+"\n",
                      encoding="utf-8")


def main():
    frame_names = [*FRAME_COLORS, "focus"]
    for name, fills in FRAME_COLORS.items():
        save_art(f"frames/{name}.svg", svg(96, 67, frame(*fills), name.replace("_", " ").title()))
    save_art("frames/focus.svg", svg(96, 67, focus_frame(), "Keyboard and controller focus outline"))
    for glyph, body in GLYPHS.items():
        for family, ink in (("dark", PALETTE["ink"]), ("light", PALETTE["paper"])):
            icon = body.replace("currentColor", ink)
            group = (
                f'<g fill="none" stroke="{ink}" stroke-width="2.25" stroke-linecap="round" '
                f'stroke-linejoin="round">{icon}</g>'
            )
            save_art(f"icons/{family}/{glyph}.svg", svg(32, 32, group, glyph.replace("_", " ").title()))
    # These approved C37 masters are owner-supplied art, shared with the HQ authoring tool.
    for name in ("hornbill", "hornbill_dark", "app_icon"):
        relative = Path("brand") / f"{name}.svg"
        (ACTIVE / relative).write_bytes((SOURCE / relative).read_bytes())
    save_art("brand/fern.svg", svg(80, 80, FERN, "Forest fern trim"))
    theme(frame_names)
    manifest = {
        "revision": "W29-B11",
        "theme": f"res://{DESIGN.relative_to(ROOT).as_posix()}",
        "logical_reference": [1280, 720],
        "review_windows": [[1280, 720], [960, 540]],
        "touch_min_logical": [64, 64],
        "safe_inset_logical": 24,
        "content_font": texture_path("fonts/NotoSans-Regular.ttf"),
        "emphasis_font": texture_path("fonts/NotoSans-Bold.ttf"),
        "title_font": texture_path("fonts/NotoSerif-Bold.ttf"),
        "font_license": texture_path("fonts/OFL.txt"),
        "palette": PALETTE,
        "frames": {
            key: {"texture": texture_path(f"frames/{key}.svg"), "texture_margins_px": [16] * 4}
            for key in frame_names
        },
        "glyphs": {
            key: {family: texture_path(f"icons/{family}/{key}.svg") for family in ("dark", "light")}
            for key in GLYPHS
        },
        "modifier_glyphs": MODIFIER_GLYPHS,
        "modifier_id_glyphs": {id_: MODIFIER_GLYPHS[group] for id_, group in MODIFIER_ID_GROUPS.items()},
        "reuse": REUSE,
        "brand": {
            **{key: texture_path(f"brand/{key}.svg") for key in ("hornbill", "hornbill_dark", "fern", "app_icon")},
            "splash": texture_path("brand/splash.png"),
        },
        "android_launcher": {
            field: texture_path(f"brand/android/{name}.png")
            for field, name in (
                ("main_192x192", "launcher"), ("adaptive_foreground_432x432", "adaptive_foreground"),
                ("adaptive_background_432x432", "adaptive_background"), ("adaptive_monochrome_432x432", "adaptive_monochrome"),
            )
        },
        "provenance": {
            "frames_glyphs": "Original vector assets authored for Kenyalang Rangers W29. Owner release review pending.",
            "brand": "C37 owner-supplied Kenyalang Rangers Brand Pack, a vector trace inspired by the GDD insignia.",
            "fonts": "Noto Sans and Noto Serif by Google. Included unmodified under SIL OFL 1.1.",
            "reused": "Existing W28/C28-A field/interface assets and C20 restoration clearing.",
        },
        "exports": {
            path.relative_to(ROOT).as_posix(): digest(path)
            for path in sorted(ACTIVE.rglob("*"))
            if path.suffix in {".svg", ".ttf", ".txt", ".png"}
        },
    }
    (SOURCE / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
    print(f"W29 UI · {len(frame_names)} frames, {len(GLYPHS)} semantic glyphs, {len(FONT_FILES)} fonts")


if __name__ == "__main__":
    main()
