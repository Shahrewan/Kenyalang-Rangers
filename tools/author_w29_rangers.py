"""Rebuild the editable W29 Ranger variant masters and their rig contracts.

The existing W27 cutout exporter bakes each SVG layer at 4x. Keep the checked-in
masters editable and the inherited pieces linked to the approved PNGs.
"""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path
from xml.etree import ElementTree as ET

from export_w27_cutouts import ROOT, sha256

SVG = "http://www.w3.org/2000/svg"
INKSCAPE = "http://www.inkscape.org/namespaces/inkscape"
XLINK = "http://www.w3.org/1999/xlink"
ET.register_namespace("", SVG)
ET.register_namespace("inkscape", INKSCAPE)
ET.register_namespace("xlink", XLINK)

INK = "#2B2622"
CREAM = "#F0DEC2"
MOSS = "#85875E"
LEAF = "#637352"
DARK = "#46453C"
BRASS = "#C4A06B"
SAGE = "#8C9A83"


def svg_path(d, fill, width=2.35, stroke=INK):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke if width else "none"}" stroke-width="{width}"/>'


def rect(x, y, w, h, r, fill, width=2.0):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" '
            f'stroke="{INK if width else "none"}" stroke-width="{width}"/>')


def ellipse(x, y, rx, ry, fill, width=2.0):
    return (f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" '
            f'stroke="{INK if width else "none"}" stroke-width="{width}"/>')


def line(d, color=INK, width=1.4):
    return svg_path(d, "none", width, color)


def append_svg(element, markup):
    group = ET.fromstring(f'<g xmlns="{SVG}">{markup}</g>')
    for child in group:
        element.append(child)


def layer(id_, label, art):
    result = ET.Element(f"{{{SVG}}}g", {
        "id": f"part_{id_}", f"{{{INKSCAPE}}}groupmode": "layer",
        f"{{{INKSCAPE}}}label": label, "stroke-linecap": "round", "stroke-linejoin": "round",
    })
    append_svg(result, art)
    return result


def piece(id_, label, parent, pivot, art):
    return {
        "id": id_, "label": label, "parent": parent, "pivot_canvas_units": list(pivot),
        "svg_layer_id": f"part_{id_}", "layer": layer(id_, label, art),
    }


def scarf(x, y, fill):
    return svg_path(f"M{x-7} {y-1} Q{x} {y+2} {x+7} {y-1} L{x+1} {y+9} Z", fill, 1.65)


def tag(x, y, color, fill=CREAM):
    return rect(x, y, 5, 3.3, .7, color, 1.0) + rect(x+1, y+1, 2.4, .8, .3, fill, 0)


def cap(crown, shade, band, button=None):
    art = svg_path("M27 34 Q26 24 33 20 Q40 16 49 16 Q61 16 65 24 L68 33 Q58 37 46 37 L30 40 Z", shade)
    art += svg_path("M30 32 Q30 25 36 22 Q44 18 51 18 Q59 18 62 23 L64 28 L50 29 Z", crown, 0)
    art += svg_path("M25 39 Q31 32 49 29 Q65 25 74 32 Q77 34 72 36 L59 34 Q42 34 29 41 Z", crown)
    art += svg_path("M29 36 Q44 30 57 30 Q66 28 73 32 Q67 33 61 32 Q44 32 31 39 Z", band, 0)
    if button:
        art += rect(47, 22, 7, 3.8, .8, button, 1)
    return art


def short_brim(crown, shade, panel):
    return (
        svg_path("M26 33 Q27 23 37 20 Q46 16 55 19 Q63 19 67 29 L67 34 L30 40 Z", shade)
        + svg_path("M30 30 Q31 23 41 21 Q51 19 58 22 L63 27 Q50 27 30 34 Z", crown, 0)
        + svg_path("M24 37 Q37 30 51 29 Q65 26 74 31 Q76 34 71 35 Q61 33 52 33 L28 40 Z", crown)
        + svg_path("M38 30 L45 21 Q52 20 55 23 L54 28 Z", panel, 0)
    )


def strap(x, y, color):
    return svg_path(f"M{x} {y} L{x+3} {y+1} L{x-8} {y+14} L{x-12} {y+14} Z", color, 1.4)


def broad_shield():
    return (
        svg_path("M54 53 Q54 48 60 47 L79 45 Q84 46 84 51 L85 70 Q84 77 80 80 L60 83 Q55 83 54 78 Z", "#705A4D", 2.85)
        + svg_path("M58 54 L60 51 L79 49 L81 51 L81 69 Q81 74 77 77 L59 79 Z", "#9E816C", 1.65)
        + svg_path("M59 62 L81 58 L81 63 L59 67 Z", "#D5AF7E", 0)
        + line("M60 70 L77 67", "#745C4D", 1.6)
        + ellipse(62, 56, 1, 1, INK, 0) + ellipse(76, 53, 1, 1, INK, 0)
        + ellipse(62, 74, 1, 1, INK, 0) + ellipse(77, 71, 1, 1, INK, 0)
    )


def arm_guards(x, y, width, fill):
    return svg_path(f"M{x-3} {y+1} Q{x-1} {y-5} {x+3} {y-4} L{x+width} {y-1} L{x+width-2} {y+5} L{x-4} {y+4} Z", fill, 2.0)


def hair_recolor(head, pairs):
    for node in head.iter():
        for key in ("fill", "stroke", "stop-color"):
            color = node.get(key)
            if color in pairs:
                node.set(key, pairs[color])


def palette_filter(defs, name, gains):
    item = ET.SubElement(defs, f"{{{SVG}}}filter", {
        "id": name, "filterUnits": "userSpaceOnUse", "x": "0", "y": "0", "width": "96",
        "height": "96", "color-interpolation-filters": "sRGB",
    })
    red, green, blue = gains
    ET.SubElement(item, f"{{{SVG}}}feColorMatrix", {
        "type": "matrix",
        "values": f"{red} 0 0 0 0  0 {green} 0 0 0  0 0 {blue} 0 0  0 0 0 1 0",
    })


def recolor_scout(defs, layers, colors, changed):
    for item in defs:
        if item.get("id") == "hair_chestnut":
            hair_recolor(item, colors)
            changed.add("head")
    for id_ in ("torso", "upper_arm_near", "forearm_near", "upper_arm_far", "forearm_far", "head"):
        original = ET.tostring(layers[id_])
        hair_recolor(layers[id_], colors)
        if original != ET.tostring(layers[id_]):
            changed.add(id_)


def recolor_patrol(defs, layers, gains, changed):
    palette_filter(defs, "jacket_tone", gains)
    for id_ in ("torso", "upper_arm_near", "forearm_near", "upper_arm_far", "forearm_far"):
        layers[id_].set("filter", "url(#jacket_tone)")
        changed.add(id_)


def inventory():
    cap_med = short_brim("#E4D7B8", "#A99F84", "#F1E5CC")
    cap_med += rect(46, 23, 10, 6, 2, "#73876D", 1.3)
    cap_med += svg_path("M47 27 Q50 23 54 24 Q55 27 51 28 Z", "#F4E4BE", 0)
    cap_crowd = (
        svg_path("M27 34 L28 25 Q29 20 38 19 L55 18 Q66 19 69 25 L70 34 L59 37 L34 38 Z", "#777E68")
        + svg_path("M30 27 Q34 21 48 21 L57 21 Q61 22 63 25 L44 25 Z", "#A1AA8A", 0)
        + svg_path("M27 33 Q43 30 61 28 Q72 27 74 34 L67 38 L54 35 L28 39 Z", DARK)
        + rect(26, 31, 10, 14, 3.5, "#4F5249", 2.55)
        + rect(28.5, 34, 4.7, 7.7, 2, "#8DA387", 0)
        + line("M30 30 Q32 23 36 21", DARK, 2)
    )
    cap_seer = (
        svg_path("M26 35 Q26 26 36 20 Q46 14 57 16 Q64 18 69 30 L66 34 L33 40 Z", "#778157")
        + svg_path("M28 30 Q35 22 44 20 Q49 17 54 18 L52 25 L42 32 L31 35 Z", CREAM, 0)
        + svg_path("M38 25 Q43 22 47 21 L46 29 L38 34 Z", "#C39951", 0)
        + svg_path("M22 38 Q34 31 48 29 Q59 25 68 27 Q74 29 76 34 Q76 37 71 38 L62 34 Q42 36 26 43 Q22 43 22 38 Z", "#868759")
        + line("M26 40 Q38 34 51 32", "#AA9F6B", 1.1)
    )
    cap_mech = cap("#8D7957", "#6F5A44", "#A99064")
    cap_mech += rect(39, 22, 23, 8.3, 3.0, "#514E42", 2)
    cap_mech += rect(42, 24, 6, 4.4, 1.3, "#BD955C", 1)
    cap_mech += rect(51, 23.8, 8, 4.2, 1.3, "#BD955C", 1)
    cap_guard = cap("#817E56", "#6D684D", "#A58E5E", "#D3B17E")
    cap_barricade = (
        svg_path("M25 35 L27 27 Q28 21 37 20 L58 20 Q65 20 69 29 L71 37 L66 42 L29 42 Z", "#656954")
        + svg_path("M30 27 Q32 22 39 22 L57 22 Q62 23 65 27 L50 28 Z", "#899078", 0)
        + svg_path("M23 39 Q36 33 55 33 Q72 31 74 36 L70 40 L63 38 L25 44 Z", "#545344")
        + rect(44, 25, 11, 5, 1, "#A07760", 1.2)
    )
    cap_k9 = cap("#89895B", "#6B704C", "#AD9C6B")
    cap_k9 += (
        svg_path("M36 25 Q47 20 61 22 Q67 24 68 30 Q58 29 47 34 Q39 34 36 30 Z", DARK, 2.25)
        + svg_path("M40 26 Q49 22 60 24 Q64 25 64 28 Q56 28 48 31 Q43 32 40 29 Z", "#DDB367", 1.3)
        + svg_path("M41 26 L47 24 L49 24 L45 30 L42 30 Z", "#F1D597", 0)
    )
    cap_woods = (
        svg_path("M27 36 Q29 23 37 21 Q46 17 55 21 Q63 22 67 35 L64 40 L34 44 Z", "#AF9A6D")
        + svg_path("M31 30 Q34 22 44 21 Q51 19 56 23 L59 27 Z", "#CEBB8E", 0)
        + svg_path("M20 43 Q30 33 49 31 Q69 28 77 37 L75 42 L62 39 Q41 41 23 47 Z", "#BCA879")
        + svg_path("M23 42 Q32 35 44 34 Q62 29 75 37 Q64 36 54 37 Q36 40 24 45 Z", "#D8C49B", 0)
        + svg_path("M35 28 Q27 29 25 23 Q31 21 36 25 Q34 16 39 17 Q42 23 38 29 Z", LEAF, 1.7)
    )
    cap_saboteur = (
        svg_path("M24 42 Q23 27 34 22 Q44 16 57 21 Q66 23 71 34 L74 48 Q69 56 60 57 L55 52 L65 46 L65 38 Q63 30 55 28 Q41 28 32 41 L35 50 L39 55 L31 55 Q24 53 24 42 Z", "#666E63", 2.65)
        + svg_path("M27 38 Q30 27 43 23 Q52 21 57 24 Q43 25 32 37 L31 45 Z", "#929789", 0)
        + svg_path("M28 47 L34 48 L38 54 L33 55 Z", "#4E6351", 0)
    )
    cap_strike = (
        svg_path("M29 32 Q29 24 38 21 Q49 18 57 21 Q63 21 68 29 L67 34 L31 40 Z", "#65674B")
        + svg_path("M30 31 L37 25 L51 22 L56 23 L51 31 Z", "#8E8B63", 0)
        + svg_path("M24 40 Q38 33 53 30 Q69 26 76 31 Q78 34 74 36 L66 34 Q46 37 28 44 Z", "#5E6149")
        + svg_path("M43 28 L52 25 L57 25 L53 30 L43 33 Z", "#A97459", 0)
    )
    return {
        "crowd_controller": {
            "name": "Crowd Controller", "base": "scout_sniper", "cap": cap_crowd, "grade": 69,
            "palette": {"#8E895E": "#87927B", "#6F6C4A": "#647062", "#848055": "#9CA78F",
                        "#493B35": "#48443D", "#645148": "#5B4B41", "#514039": "#4B3F39"},
            "torso": strap(59, 53, "#515A50") + tag(51, 58, SAGE),
            "gear": [
                ("battery", "Back-mounted power pack", "torso", (39, 61), -1,
                 rect(25, 50, 17, 23, 3, "#595F50") + rect(28, 49, 8, 22, 2, "#7C826D")
                 + rect(28, 58, 3, 6, .7, "#AFB794", 0)),
                ("projector", "Padded EMP projector", "hand_near", (48, 63), 45,
                 svg_path("M44 60 Q44 57 48 56 L69 55 L77 57 L78 63 L75 67 L52 68 L45 66 Z", "#55574E")
                 + rect(68, 54.5, 9, 14, 2.6, "#79887B") + rect(72, 57, 4.2, 8, 1.3, "#BDD2AF", 0)
                 + rect(49, 58, 13, 4, 1, "#8A9276", 1.3) + tag(62, 62, "#C1C495")),
            ],
            "prop": "projector", "socket": "emp_emitter", "tip": [76, 61],
            "skill": "Empowered EMP and slowing-field presentation", "pose": "aim",
        },
        "combat_medic": {
            "name": "Combat Medic", "base": "scout_sniper", "cap": cap_med, "grade": 68,
            "palette": {"#8E895E": "#A4A182", "#6F6C4A": "#747D63", "#848055": "#9D9F7E",
                        "#F0DEC2": "#EFE3C9", "#645148": "#7B5545", "#514039": "#5E4238"},
            "torso": scarf(50, 50, "#D4C5A3") + strap(58, 54, "#D9CDB2") + tag(52, 58, "#72816C"),
            "gear": [
                ("treatment_case", "Treatment case", "hand_near", (48, 63), 45,
                 svg_path("M46 64 Q46 60 50 59 L67 61 Q72 62 72 66 L71 76 Q70 78 66 77 L48 74 Q45 74 45 70 Z", "#A39B7C")
                 + svg_path("M46 64 Q47 60 51 60 L67 62 Q70 63 70 66 L67 70 L48 67 Z", "#E4D8B9", 1.7)
                 + svg_path("M54 66 Q58 62 63 64 Q62 68 58 69 L56 67 Z", "#64785F", 0)
                 + rect(58, 69, 4, 3.1, .7, BRASS, 1.0)),
            ],
            "prop": "treatment_case", "socket": "treatment_fx", "tip": [66, 64],
            "skill": "Emergency Treatment kit and cleanse presentation", "pose": "assist",
        },
        "kenyalang_seer": {
            "name": "Kenyalang Seer", "base": "scout_sniper", "cap": cap_seer, "grade": 69,
            "palette": {"#8E895E": "#8B8D60", "#6F6C4A": "#6A7453", "#848055": "#999C72",
                        "#645148": "#584640", "#514039": "#453A37"},
            "torso": scarf(50, 50, "#CFA354"),
            "gear": [
                ("braid", "Tied braid", "head", (31, 43), -2,
                 svg_path("M30 39 Q35 37 35 43 L32 52 L28 61 Q24 64 22 61 Q22 58 25 55 L25 51 Z", "#54413B")
                 + line("M29 46 L33 47 M27 52 L30 54 M24 57 L27 59", "#775751", 1.5)
                 + line("M23 61 L26 62", "#B08A5D", 1.5)),
                ("mantle", "Hornbill cream-and-gold half mantle", "upper_arm_near", (42.75, 53.25), 25,
                 svg_path("M43 49 Q47 50 47 55 L42 66 Q38 71 34 73 L26 67 Q28 63 36 56 Z", "#888D60")
                 + svg_path("M28 66 Q36 66 38 60 L43 60 L39 67 L34 72 Z", "#E0D2B0", 0)
                 + svg_path("M28 67 L34 70 L37 67 L37 70 L34 72 Z", "#C4974B", 0)
                 + svg_path("M35 64 Q38 60 42 60 L41 63 L37 66 Z", "#E8DFC0", 0)),
                ("boomerang", "Open hornbill boomerang", "hand_near", (48, 63), 45,
                 svg_path("M44 59 Q58 59 69 49 L76 43 Q79 43 80 47 L77 52 Q68 62 57 66 L48 68 Q44 66 44 59 Z", "#B68C49")
                 + svg_path("M48 61 Q61 59 70 51 L76 46 L76 49 Q67 60 55 64 Z", "#E1BD70", 0)
                 + svg_path("M71 49 L76 45 L78 47 L76 50 L73 53 Z", "#6B7153", 0)),
            ],
            "prop": "boomerang", "socket": "boomerang_release", "tip": [73, 50],
            "skill": "Danger scan and reveal presentation", "pose": "throw",
        },
        "outpost_mechanic": {
            "name": "Outpost Mechanic", "base": "scout_sniper", "cap": cap_mech, "grade": 69,
            "palette": {"#8E895E": "#8B775A", "#6F6C4A": "#6C644E", "#848055": "#A28B68",
                        "#645148": "#59473E", "#514039": "#483C35"},
            "torso": strap(58, 54, "#BB9866") + tag(52, 57, "#A98255"),
            "gear": [
                ("toolbox", "Toolbox with folding handle", "torso", (39, 66), -1,
                 rect(21, 62, 21, 15, 3, "#9F8358") + line("M25 62 V58 Q25 57 27 57 H35 Q37 57 37 62", DARK, 2)
                 + line("M22 66 H40", INK, 1.3) + rect(28, 65, 5, 4, .7, "#D3B47A", 1.2)),
                ("wrench", "Open-ended repair wrench", "hand_near", (48.375, 63.375), 45,
                 svg_path("M44 64 L61 58 L65 54 Q63 51 64 47 Q65 44 67 44 L69 49 L73 49 L75 44 Q78 46 78 50 Q78 55 72 58 L67 58 L49 68 Q46 68 44 64 Z", "#77746A")
                 + svg_path("M48 64 L66 56 L70 54 L70 56 L51 66 Z", "#A29F87", 0)),
            ],
            "prop": "wrench", "socket": "repair_contact", "tip": [72, 53],
            "skill": "Facility and eligible Barricade Ops repair presentation", "pose": "assist",
        },
        "guard_veteran": {
            "name": "Guard Veteran", "base": "patrolman", "cap": cap_guard, "grade": 70,
            "tone": (1.05, 1.0, .91),
            "torso": scarf(50, 56, "#A68252") + tag(53, 65, "#AA895D"),
            "arms": {"upper_arm_near": arm_guards(36, 59, 9, "#A18B60")},
            "gear": [
                ("stun_prod", "Long tapered stun prod", "hand_near", (34.5, 69), 46,
                 svg_path("M31 68 Q33 66 36 67 L64 67 L79 65 Q83 64 85 66 L84 69 L65 72 L35 73 Q31 72 31 68 Z", "#564D41")
                 + svg_path("M48 68 L64 68 L79 66 L80 68 L64 70 L48 71 Z", "#968471", 0)
                 + rect(61, 66.5, 5.4, 5.1, 1, "#AA895D", 1.3)
                 + line("M82 66 L86 64 M83 68 L87 68", "#5A6351", 1.8)),
            ],
            "prop": "stun_prod", "socket": "prod_contact", "tip": [85, 67],
            "skill": "Charged forward stun-prod strike presentation", "pose": "swing",
            "frame": "locked", "block": True,
        },
        "barricade_ops": {
            "name": "Barricade Ops", "base": "patrolman", "cap": cap_barricade, "grade": 70,
            "tone": (.9, .9, .93),
            "torso": strap(56, 56, "#A87458") + tag(52, 65, "#AA7D61"),
            "arms": {
                "upper_arm_far": arm_guards(58, 58, 8, "#8E735E"),
                "upper_arm_near": arm_guards(37, 58, 11, "#A67C62"),
            },
            "gear": [("wide_shield", "Wide clay-trimmed push shield", "hand_far", (63.5, 62.25), 42, broad_shield())],
            "prop": "wide_shield", "socket": "shield_edge", "tip": [82, 64],
            "skill": "Shield shove presentation", "pose": "shield",
            "frame": "locked", "block": True, "footprint": [[0, 0], [1, 0]],
        },
        "k9_ranger": {
            "name": "K9 Ranger", "base": "patrolman", "cap": cap_k9, "grade": 70,
            "tone": (1.03, 1.06, .98), "torso": strap(58, 55, "#B29E69") + tag(50, 64, "#B6A368"),
            "gear": [
                ("dog_pack", "Compact handler pack", "torso", (40, 61), -1,
                 rect(21, 52, 20, 23, 5, "#8B8A5B") + rect(22, 54, 16, 8, 2.5, "#A59C6F")
                 + rect(27, 62, 6, 9, 1.3, "#716D52", 1.5)),
                ("tranq_carbine", "Compact tranquilizer carbine", "hand_near", (36.375, 69.125), 46,
                 svg_path("M31 67 L40 63 L53 61 L69 58 L73 59 L73 63 L68 65 L54 68 L38 71 L32 72 Z", "#70574A")
                 + svg_path("M49 62 L59 60 L69 57 L75 57 L77 60 L74 63 L59 65 L51 66 Z", "#57564C", 1.9)
                 + rect(53, 58.8, 8, 3, 1, "#879170", 1.2)),
            ],
            "prop": "tranq_carbine", "socket": "tranq_muzzle", "tip": [75.75, 60.5],
            "skill": "Signal companion howl for the existing reveal/slow presentation", "pose": "aim",
            "block": True,
        },
        "woods_tracker": {
            "name": "Woods Tracker", "base": "patrolman", "cap": cap_woods, "grade": 69,
            "tone": (1.0, 1.06, 1.02), "torso": scarf(51, 56, "#B99955") + tag(52, 65, "#84905D"),
            "gear": [
                ("net_pouch", "Rear roll and net pouch", "torso", (44, 64), 0,
                 svg_path("M22 59 Q24 55 32 56 L39 59 L41 72 L32 76 L23 73 Z", "#817C55")
                 + svg_path("M36 60 Q41 58 46 61L48 65L44 68L37 67Z", "#817C55", 1.2)
                 + rect(22, 55, 13, 6, 3, "#B4A581") + line("M25 66 L37 68", DARK, 1.6)),
                ("field_net", "Open rim field net", "hand_near", (34.5, 69), 46,
                 svg_path("M32 70 L35 67 L64 57 Q67 57 67 60 L64 62 L35 73 Q32 73 32 70 Z", "#7C6547")
                 + svg_path("M61 59 Q61 53 66 49 Q73 46 80 50 Q86 54 83 60 Q81 66 74 67 Q65 67 61 59 Z", "#AEAB83")
                 + svg_path("M64 57 Q64 52 72 51 Q81 51 81 56 Q82 61 75 64 Q68 65 64 57 Z", "#D8CCAB", 1.2)
                 + line("M66 53 L74 64 M71 52 L79 60 M64 57 L75 52 M68 62 L81 56", "#6C6F55", 1)),
            ],
            "prop": "field_net", "socket": "net_release", "tip": [78, 57],
            "skill": "Existing deploy-net presentation and visual follow-through", "pose": "throw",
            "frame": "locked",
        },
        "saboteurist": {
            "name": "Saboteurist", "base": "patrolman", "cap": cap_saboteur, "grade": 68,
            "hat_pivot": [31.625, 42.125],
            "tone": (.88, .94, 1.08),
            "torso": scarf(51, 56, "#668371") + tag(51, 65, "#789486"),
            "arms": {"forearm_near": rect(31.8, 61.8, 9.8, 5, 1.3, "#4B5F56", 1.8)
                     + rect(33.6, 63.0, 4.8, 1.4, .45, "#ACC0AA", 0)},
            "gear": [
                ("interference_fork", "Interference fork and insulated grip", "hand_near", (35, 69), 46,
                 svg_path("M31 67 Q34 64 37 65 L56 66 L62 62 L70 61 L73 63 L71 66 L65 67 L65 69 L72 69 L73 72 L70 74 L61 73 L56 71 L35 73 Q31 72 31 67 Z", "#59685F")
                 + rect(40, 66.3, 12, 4.1, 1, "#839F91", 1.2)
                 + line("M62 64 L67 64 M62 71 L68 71", "#B8C4A5", 1.5)),
            ],
            "prop": "interference_fork", "socket": "pulse_origin", "tip": [72, 67.5],
            "skill": "Existing temporal interference field and retreat pulse cues", "pose": "pulse",
            "frame": "locked",
        },
        "strike_team": {
            "name": "Strike Team", "base": "patrolman", "cap": cap_strike, "grade": 68,
            "tone": (1.07, 1.03, .93), "torso": strap(56, 57, "#A47C5D") + tag(50, 65, "#AD795C"),
            "arms": {"upper_arm_near": arm_guards(37, 57, 10, "#AD815F")
                     + line("M34 59 L43 60", "#E1C6A0", 1.35),
                     "upper_arm_far": arm_guards(58, 58, 7, "#8D7057")},
            "gear": [
                ("compact_baton", "Split-grip compact baton", "hand_near", (34.25, 69.75), 46,
                 svg_path("M30 68 Q32 65 37 68 L62 70 Q65 71 64 74 Q64 76 60 76 L35 74 Q30 73 30 68 Z", "#5F4A3D")
                 + rect(53, 71, 9, 3.6, 1, "#AA8866", 1.1)
                 + line("M37 70 L39 73 M41 70 L43 73", "#9D795F", 1.4)),
            ],
            "prop": "compact_baton", "socket": "baton_contact", "tip": [62, 73],
            "skill": "Delayed arrival and charge-level presentation", "pose": "swing",
            "frame": "locked", "footprint": [[0, 0], [1, 0]],
        },
    }


def placement_settings(config):
    if config["base"] == "scout_sniper":
        return {"tile": "elevated", "footprint_0_based": [[0, 0]], "anchor": "Foot at addressed cell center"}
    footprint = config.get("footprint", [[0, 0]])
    return {
        "tile": "ground", "footprint_0_based": footprint,
        "anchor": "Foot at occupied pair center; leave gameplay anchor at leading cell" if len(footprint) > 1
        else "Foot at addressed cell center",
    }


def variant_source(id_, config, template):
    base_path = ROOT / template["source_svg"]
    root = ET.parse(base_path).getroot()
    title = root.find(f"{{{SVG}}}title")
    title.text = f"{config['name']} · W29 editable production cutout"
    defs = root.find(f"{{{SVG}}}defs")
    layers = {child.get("id").removeprefix("part_"): child
              for child in root if child.tag == f"{{{SVG}}}g"}
    changed = {"hat", "torso"}
    if config["base"] == "scout_sniper":
        recolor_scout(defs, layers, config["palette"], changed)
        # W06 preview allowed a tighter pad here. Match the two-unit W27 pivot overlap
        # behind the approved visible knee edge for production variants.
        padding = ET.fromstring(f'<g xmlns="{SVG}">{ellipse(40.6, 76.5, 2.2, 2.2, "#5E584A", 0)}</g>')
        layers["thigh_near"].insert(0, padding[0])
        changed.add("thigh_near")
    else:
        recolor_patrol(defs, layers, config["tone"], changed)
        # The shield obscured most of the far glove in W27. Complete that pad for
        # scouts who carry the new field tools below the shoulder.
        carried = ellipse(63.7, 62.1, 3.75, 3.1, "#C9926E", 1.8)
        append_svg(layers["hand_far"], carried)
        changed.add("hand_far")
    append_svg(layers["torso"], config["torso"])
    layers["torso"].set("stroke-linecap", "round")
    layers["torso"].set("stroke-linejoin", "round")
    for id_arm, art in config.get("arms", {}).items():
        append_svg(layers[id_arm], art)
        changed.add(id_arm)
    layers["hat"] = layer("hat", "Ranger headgear", config["cap"])
    source_parts = []
    for source_part in template["parts"]:
        id_part = source_part["id"]
        if id_part in ("shield", "baton", "tranq_tool", "mantle", "pack", "ponytail"):
            continue
        part = copy.deepcopy(source_part)
        if id_part in changed:
            part["png"] = f"assets/imported/rangers/{id_}/{id_part}.png"
        elif config["base"] == "scout_sniper":
            # The legacy W06 package uses its own crop padding; share the
            # normalized W29 baking of those same unchanged vector shapes.
            part["png"] = f"assets/imported/rangers/crowd_controller/{id_part}.png"
        part["layer"] = layers[id_part]
        if id_part == "hat":
            part["label"] = "Ranger headgear"
            part["pivot_canvas_units"] = config.get("hat_pivot", part["pivot_canvas_units"])
        # Keep inherited legs and feet below the jacket and active parts above
        # it. Prime each modified variant with its true rest transform.
        part["_order"] = part["draw_order"] * 3
        source_parts.append(part)
    for id_prop, label, parent, pivot, order, art in config["gear"]:
        prop = piece(id_prop, label, parent, pivot, art)
        prop["_order"] = order
        prop["png"] = f"assets/imported/rangers/{id_}/{id_prop}.png"
        source_parts.append(prop)

    # Plot carrying gear behind the fists and jaw. At equal order inherit the
    # approved bone hierarchy, then draw the additional tool.
    for child in list(root):
        if child.tag == f"{{{SVG}}}g":
            root.remove(child)
    sorted_parts = sorted(source_parts, key=lambda p: p["_order"])
    for order, part in enumerate(sorted_parts, 1):
        part["draw_order"] = order
        root.append(part.pop("layer"))
        part.pop("_order")

    if config["base"] == "patrolman":
        # Reuse the approved underlying study by relative link instead of
        # duplicating the embedded PNG into six variant masters.
        study = defs.find(f"{{{SVG}}}image")
        study.set(f"{{{XLINK}}}href", "../patrolman/study_reference.png")
    return root, sorted_parts


def write_variant(id_, config):
    base_rel = f"assets/source-art/rangers/{config['base']}/manifest.json"
    base = json.loads((ROOT / base_rel).read_text())
    root, parts = variant_source(id_, config, base)
    rel = f"assets/source-art/rangers/{id_}"
    src = ROOT / rel
    src.mkdir(parents=True, exist_ok=True)
    (src / ".gdignore").touch()
    ET.indent(root, space="  ")
    ET.ElementTree(root).write(src / f"{id_}.svg", encoding="unicode")
    prop = config["prop"]
    prop_part = next(item for item in parts if item["id"] == prop)
    sockets = {
        "tool_grip": {"part": prop_part["parent"], "canvas_units": prop_part["pivot_canvas_units"]},
        "attack_fx": {"part": prop, "canvas_units": config["tip"]},
        config["socket"]: {"part": prop, "canvas_units": config["tip"]},
    }
    manifest = {
        "schema_version": 1, "asset_version": "1.0.0",
        "ranger_id": f"ranger.{id_}", "display_name": config["name"],
        "status": "W29 production cutout and isolated pose proof; runtime binding separate",
        "source_svg": f"{rel}/{id_}.svg",
        "coordinate_system": "Top-left origin, +x right, +y down", "canvas_units": [96, 96],
        "normalized_raster_canvas_px": [384, 384], "pixels_per_unit": 4,
        "godot_units_per_png_pixel": .25, "tile_units": 80, "ground_anchor_units": [48, 84],
        "target_visible_height_units": config["grade"], "neutral_facing": "right",
        "horizontal_mirror_origin": "Facing node at foot anchor",
        "underfoot_hp_offset_units": [0, 5],
        "deployment": placement_settings(config),
        "animation_contract": f"{rel}/animation_contract.json",
        "export": {
            "format": "PNG RGBA", "minimum_padding_px": 4, "filter": "linear",
            "rasterizer": "Inkscape 1.4", "crop_offset_origin": "top-left of normalized raster canvas",
        },
        "derived_badge": {
            "path": f"assets/imported/rangers/{id_}/field_badge.png", "dimensions_px": [96, 96],
            "max_content_px": [82, 78], "baseline_px": 86,
        },
        "provenance": {
            "creator": "Kenyalang Rangers production art",
            "revision": "2026-11-24",
            "base_manifest": base_rel,
            "base_source": base["source_svg"],
            "base_source_sha256": sha256(ROOT / base["source_svg"]),
            "source": "Approved body proportions, established base cutouts and original role-specific SVG art.",
            "reference": "W06 Ranger art spec, W27 approved enemy and Patrolman proportions, UI storyboard pp. 2–3 and 11, GDD pp. 9–11",
            "release_review": "D-014",
        },
        "sockets": sockets,
        "parts": parts,
    }
    if id_ == "k9_ranger":
        manifest["companion"] = {
            "asset_id": "companion.k9_ranger.dog", "manifest": f"{rel}/companion/manifest.json",
            "attach_offset_units_right": [26, 0], "parent": "Facing",
            "placement": "Presentation attached to existing K9 Ranger. The dog does not occupy a separate tile.",
            "states": {"Idle": "Idle", "Deploy": "Move", "Attack": "Idle", "Skill": "Howl",
                       "Hit": "Idle", "Retreat": "Move", "Defeat": "Down", "Block": "Idle"},
        }
    write_json(src / "manifest.json", manifest)
    write_json(src / "animation_contract.json", ranger_motion(id_, config))
    return rel


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def ranger_motion(id_, config):
    pose = config["pose"]
    prop = config["prop"]
    initial = {
        "aim": {"head": 1, "forearm_near": -11, "forearm_far": -7},
        "assist": {"head": 3, "upper_arm_near": 9, "forearm_near": -7},
        "throw": {"head": 7, "upper_arm_near": 19, "forearm_near": 22, prop: 11},
        "swing": {"head": 4, "upper_arm_near": 26, "forearm_near": 12, prop: 8},
        "shield": {"head": 1, "upper_arm_far": 11, "forearm_far": 7, prop: -8},
        "pulse": {"head": 4, "upper_arm_near": 11, "forearm_near": 7},
    }[pose]
    strike = {
        "aim": {"head": -3, "upper_arm_near": -9, "forearm_near": -16, "hand_near": 11, prop: -3},
        "assist": {"head": -4, "upper_arm_near": -13, "forearm_near": -19, "hand_near": 8, prop: -5},
        "throw": {"head": -6, "upper_arm_near": -23, "forearm_near": -19, "hand_near": 13, prop: -12},
        "swing": {"head": -5, "upper_arm_near": -27, "forearm_near": -17, "hand_near": 38, prop: -7},
        "shield": {"head": -6, "upper_arm_far": -19, "forearm_far": -9, "hand_far": 17, prop: 5},
        "pulse": {"head": -4, "upper_arm_near": -14, "forearm_near": -13, "hand_near": 19, prop: 4},
    }[pose]

    def once(event, keys, **more):
        clip = {"playback": "return", "next": "Idle", "event": event, "keys": keys}
        if config.get("block"):
            clip["return_if_blocking"] = "Block"
        return clip | more

    idle = {"playback": "loop", "event": "Placed, alive and no transient pose",
            "keys": [[0, 0, {}], [.62, 0, {"head": -2.6, "forearm_near": 2.5}], [1.24, 0, {}]]}
    states = {
        "Idle": idle,
        "Deploy": once("Successful placement", [[0, -4, {"head": 4, "thigh_near": 7}],
                                                [.18, 0, {"head": -3, "forearm_far": -6}], [.39, 0, {}]]),
        "Attack": once("Existing action and attack presentation cue",
                       [[0, 0, {}], [.12, 0, initial], [.25, -.5, strike], [.46, 0, {}]],
                       accent={"socket": "attack_fx", "preview_seconds": .25}),
        "Skill": once(config["skill"], [[0, 0, {}], [.16, -1, initial], [.32, -1.8, strike],
                                        [.47, 0, strike | {"head": -2}], [.66, 0, {}]],
                      accent={"socket": config["socket"], "preview_seconds": .32}),
        "Hit": once("Nonterminal damage presentation cue", [[0, 0, {}],
                    [.095, 0, {"head": 9, "upper_arm_near": 12, "upper_arm_far": 8}], [.29, 0, {}]]),
        "Retreat": {"playback": "hold", "event": "Voluntary removal cue",
                    "keys": [[0, 0, {}], [.16, -1.3, {"head": 11, "thigh_near": 9, "shin_far": -7}],
                             [.36, -2.6, {"head": 13, "thigh_near": 12, "shin_far": -8,
                                          "upper_arm_near": 10}]]},
        "Defeat": {"playback": "hold", "event": "Forced loss cue",
                   "keys": [[0, 0, {}], [.16, 0, {"head": 11, "upper_arm_near": 11}],
                            [.43, 2.3, {"head": 22, "upper_arm_near": 24, "thigh_near": 13,
                                         "thigh_far": -12}]]},
    }
    if config.get("block"):
        braced = {"head": -3, "upper_arm_far": -11, "forearm_far": -9, "hand_far": 4}
        states["Block"] = {
            "playback": "loop", "event": "Existing snapshot contains blocked actors",
            "keys": [[0, 0, braced], [.32, 0, braced | {"head": -2, "forearm_far": -7}], [.64, 0, braced]],
        }
    if id_ == "woods_tracker":
        states["Deploy"]["keys"] = [
            [0, -3, initial], [.16, -.5, strike], [.32, 0, {"head": -3}], [.46, 0, {}],
        ]
        states["Deploy"]["accent"] = {"socket": "net_release", "preview_seconds": .16}
    if id_ == "saboteurist":
        states["Retreat"]["accent"] = {"socket": "pulse_origin", "preview_seconds": .18}

    return {
        "schema_version": 1, "asset_id": f"ranger.{id_}",
        "status": "W29 verified character motion, isolated from gameplay",
        "sampling_fps": 60, "default": "Idle",
        "facing": "Lock art facing at placement." if config.get("frame") == "locked"
        else "Mirror about the facing root. Keep overlays outside that node.",
        "anchor": "Same ground anchor in every state; motion is presentation only.",
        "clock": "Use the existing combat-clock delta. Pause passes zero.",
        "key_format": "[seconds, torso_y_offset_units, {bone_id: local_rotation_degrees}]. Missing bone rotation is neutral.",
        "states": states,
    }


def companion():
    rel = "assets/source-art/rangers/k9_ranger/companion"
    src = ROOT / rel
    src.mkdir(parents=True, exist_ok=True)
    (src / ".gdignore").touch()

    tan, shade, charcoal = "#C4A077", "#A17C58", "#524743"
    hip_support = ellipse(33, 73, 2.3, 2.3, tan, 0)
    parts = [
        piece("leg_far_rear", "Far hind leg", "torso", (33.375, 72.375),
              svg_path("M31 70 Q34 69 36 72 L36 79 L38 80 Q39 82 37 83 L31 83 L30 79 Z", shade, 2.0)),
        piece("leg_far_front", "Far foreleg", "torso", (54, 72),
              svg_path("M52 69 Q55 67 57 70 L57 79 L60 80 Q61 82 58 83 L53 82 L51 77 Z", shade, 2.0)),
        piece("tail", "Tipped shepherd tail", "torso", (33, 69),
              svg_path("M35 68 Q29 65 26 61 Q24 58 20 60 L22 65 Q26 72 33 73 Z", shade, 2.0)
              + svg_path("M22 61 L25 61 L27 65 L24 67 Z", charcoal, 0)),
        piece("torso", "Shepherd body with olive field harness", None, (44, 71),
              hip_support
              + svg_path("M31 65 Q37 59 48 61 Q55 59 60 63 Q62 69 59 74 Q51 78 39 76 Q30 75 31 65 Z", tan)
              + svg_path("M37 62 Q45 60 50 62 L57 62 L56 70 L47 72 L37 70 Z", "#747C57", 2.0)
              + rect(42, 65, 6.5, 4.8, 1.2, "#A89C68", 1.3)),
        piece("leg_near_rear", "Near hind leg", "torso", (38, 73),
              svg_path("M34 71 Q37 69 41 71 L40 77 L42 80 Q43 83 40 83 L35 83 L33 79 Z", tan, 2.0)),
        piece("leg_near_front", "Near foreleg", "torso", (54, 73),
              svg_path("M51 70 Q54 68 57 70 L57 78 L60 81 Q60 83 58 83 L53 83 L51 79 Z", tan, 2.0)),
        piece("head", "Pointed ears and dark muzzle", "torso", (55, 65),
              svg_path("M48 57 L49 48 Q50 46 52 48 L56 54 L60 47 Q62 46 62 50 L62 55 Q67 56 68 60 L72 61 Q74 62 71 66 L66 68 Q60 72 54 69 L49 65 Z", tan)
              + svg_path("M50 50 L54 55 L51 56 Z M60 50 L61 55 L58 56 Z", "#8D624D", 0)
              + svg_path("M64 58 Q66 61 72 61 Q73 64 69 66 Q64 67 61 64 Z", charcoal, 0)
              + rect(61, 57, 2, 4, .9, INK, 0)
              + line("M53 66 Q57 67 60 67", "#697652", 1.65)),
    ]
    root = ET.Element(f"{{{SVG}}}svg", {"width": "96", "height": "96", "viewBox": "0 0 96 96"})
    for order, part in enumerate(parts, 1):
        root.append(part.pop("layer"))
        part["draw_order"] = order
        part["png"] = f"assets/imported/rangers/k9_ranger/companion/{part['id']}.png"
    ET.indent(root, space="  ")
    ET.ElementTree(root).write(src / "dog.svg", encoding="unicode")
    write_json(src / "manifest.json", {
        "schema_version": 1, "asset_version": "1.0.0", "asset_id": "companion.k9_ranger.dog",
        "display_name": "K9 Ranger companion", "status": "W29 subordinate skeletal cutout",
        "source_svg": f"{rel}/dog.svg", "ground_anchor_units": [48, 84], "tile_units": 80,
        "canvas_units": [96, 96], "normalized_raster_canvas_px": [384, 384],
        "godot_units_per_png_pixel": .25, "neutral_facing": "right",
        "animation_contract": f"{rel}/animation_contract.json",
        "provenance": {"creator": "Kenyalang Rangers production art", "revision": "2026-11-24",
                       "reference": "Approved Ranger lineup, W06 and GDD H.1",
                       "release_review": "D-014"},
        "sockets": {"howl_fx": {"part": "head", "canvas_units": [71, 63]}}, "parts": parts,
    })
    write_json(src / "animation_contract.json", {
        "schema_version": 1, "asset_id": "companion.k9_ranger.dog", "sampling_fps": 60,
        "default": "Idle", "clock": "Advance with the handler's combat clock delta.",
        "states": {
            "Idle": {"playback": "loop", "event": "Stationary beside the handler",
                     "keys": [[0, 0, {"tail": -8}], [.5, 0, {"tail": 8, "head": 1.7}], [1.0, 0, {"tail": -8}]]},
            "Move": {"playback": "loop", "event": "Visual arrival or exit trot",
                     "keys": [[0, 0, {"leg_near_rear": -16, "leg_near_front": 14, "tail": 5}],
                              [.2, -1, {"leg_far_rear": 14, "leg_far_front": -13, "tail": -4}],
                              [.4, 0, {"leg_near_rear": -16, "leg_near_front": 14, "tail": 5}]]},
            "Howl": {"playback": "return", "next": "Idle", "event": "Handler reveal and slow cue",
                     "keys": [[0, 0, {}], [.14, 0, {"head": -12, "tail": -10}],
                              [.38, 0, {"head": -22, "tail": -16}], [.62, 0, {}]],
                     "accent": {"socket": "howl_fx", "preview_seconds": .38}},
            "Down": {"playback": "hold", "event": "Handler forced loss",
                     "keys": [[0, 0, {}], [.4, 1.5, {"head": 16, "tail": 36, "leg_far_rear": 10,
                                                     "leg_near_front": -11}]]},
        },
    })


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--unit", action="append", choices=inventory())
    args = parser.parse_args()
    roster = inventory()
    for id_ in args.unit or roster:
        print(write_variant(id_, roster[id_]))
        if id_ == "k9_ranger":
            companion()


if __name__ == "__main__":
    main()
