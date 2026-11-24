"""Build the illustrated W29 Facility cutouts, Godot rigs, and scale proofs."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from tempfile import TemporaryDirectory
from xml.sax.saxutils import escape

from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source-art/facilities"
OUTPUT = ROOT / "assets/imported/facilities"
REVIEW = ROOT / "docs/production/w29/facilities"
DENSITY = 4
TILE = 80

INK = "#2d2922"
OLIVE = "#888b61"
MOSS = "#a1a077"
LIGHT = "#b8b584"
DEEP = "#62654a"
BROWN = "#79674f"
TAUPE = "#b39c7e"
WOOD = "#a7865c"
CREAM = "#e5d6b8"
PAPER = "#f0e4c9"
SHADOW = "#8d7d6b"
AMBER = "#e9b454"
GOLD = "#f5d17a"
RUST = "#935a44"
RUST_LIGHT = "#cb855e"
TEAL = "#83cbb1"
TEAL_LIGHT = "#b5e0c6"
DARK_TEAL = "#527d70"
GLASS = "#49504a"


def group(*parts, attrs=""):
    return f"<g {attrs}>" + "".join(parts) + "</g>"


def path(d, fill, stroke=INK, width=3.4, attrs=""):
    return (
        f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" '
        f'stroke-linecap="round" stroke-linejoin="round" {attrs}/>'
    )


def line(d, color=INK, width=3.4):
    return path(d, "none", color, width)


def rounded(x, y, w, h, rx, fill, stroke=INK, width=3.4):
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" '
        f'fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'
    )


def ellipse(x, y, rx, ry, fill, stroke=INK, width=3.4):
    return (
        f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" '
        f'stroke="{stroke}" stroke-width="{width}"/>'
    )


def face(d, fill):
    return path(d, fill, "none")


def bolt(x, y, color=TAUPE):
    return ellipse(x, y, 2, 2, color, INK, 1.4)


def bolts(*positions):
    return "".join(bolt(*position) for position in positions)


def slot(x, y, w):
    return rounded(x, y, w, 3, 1, INK, "none")


def sled(wide=True):
    """Low shared drawing language for frame steel, skid feet, and deck."""
    if not wide:
        return (
            path("M12 135 H66 L70 143 Q70 149 64 150 H14 Q8 149 9 144Z", DEEP)
            + path("M13 138 H67 L66 143 H12Z", OLIVE, "none")
            + rounded(10, 144, 19, 7, 2, TAUPE, INK, 2.5)
            + rounded(50, 144, 20, 7, 2, TAUPE, INK, 2.5)
        )
    return (
        path("M20 54 H139 L149 63 Q149 69 145 70 H15 Q10 69 11 64Z", DEEP)
        + face("M23 56 H136 L142 62 H17Z", LIGHT)
        + rounded(13, 64, 23, 6.5, 1.8, TAUPE, INK, 2.3)
        + rounded(123, 64, 24, 6.5, 1.8, TAUPE, INK, 2.3)
    )


def antenna(x, y, lean=0, color=TAUPE):
    return line(f"M{x} {y} l{lean} -16", INK, 6) + line(
        f"M{x} {y - 1} l{lean} -15", color, 2.1
    ) + ellipse(x + lean, y - 16, 3.8, 3.8, color, INK, 2.4)


def lamp(x, y, color):
    return ellipse(x, y, 3.5, 3.5, color, INK, 1.6)


def console(x, y, w, h, tint=OLIVE):
    return (
        rounded(x, y, w, h, 6, tint)
        + face(f"M{x+4} {y+7} q1 -3 6 -3 h{w-18} l2 3Z", LIGHT)
        + face(f"M{x+4} {y+h-8} h{w-8} v4 H{x+6}Z", DEEP)
    )


def display(x, y, width, color=AMBER):
    return (
        rounded(x, y, width, 12, 2.1, color, INK, 2.7)
        + rounded(x + 3.4, y + 3, width / 2.5, 1.9, 0.7, PAPER, "none")
    )


def logistics_post():
    body = (
        path("M18 34 L31 20 H83 L97 33 V62 H18Z", OLIVE)
        + face("M31 22 H81 L91 32 H23Z", LIGHT)
        + face("M20 52 H94 V59 H20Z", DEEP)
        + line("M19 34 H95")
        + path("M34 20 H43 L33 34 L32 61 H24 V34Z", WOOD, INK, 2.3)
        + path("M61 20 H72 L65 34 V62 H55 V34Z", WOOD, INK, 2.3)
        + rounded(24, 37, 9, 9, 1.6, CREAM, INK, 2)
        + rounded(55, 37, 10, 9, 1.6, CREAM, INK, 2)
        + slot(38, 47, 13)
        + path("M84 24 L95 34 V61 H84 L79 55 V33Z", BROWN, INK, 2.5)
    )
    active = (
        antenna(124, 31)
        + console(89, 32, 51, 30)
        + rounded(97, 38, 35, 11, 2.2, GLASS, INK, 2)
        + slot(99, 53, 10)
        + slot(119, 53, 10)
        + bolt(95, 54)
    )
    return body, active, display(97, 38, 35), (115, 57), None


def medic_cabin():
    body = (
        path("M26 31 L41 15 H111 L134 31 V63 H26Z", CREAM)
        + face("M41 18 H110 L129 30 H30Z", PAPER)
        + path("M26 34 H134", "none")
        + face("M29 52 H131 V61 H29Z", TAUPE)
        + path("M24 58 L30 50 H40 V64 H24Z", DEEP)
        + path("M120 49 H129 L137 58 V64 H120Z", DEEP)
        + rounded(39, 27, 10, 17, 2, BROWN, INK, 2.3)
        + rounded(110, 27, 10, 17, 2, BROWN, INK, 2.3)
        + path("M76 38 H86 V45 H93 V54 H86 V61 H76 V54 H69 V45 H76Z", DEEP, "none")
    )
    active = (
        path("M49 58 V48 Q52 43 56 48 V58", "none", INK, 3)
        + rounded(43, 52, 19, 12, 3, OLIVE, INK, 2.1)
        + line("M48 58 H57 M52.5 55 V61", PAPER, 1.65)
        + line("M99 41 V49", INK, 3)
    )
    return body, active, lamp(99, 41, TEAL), (53, 57), None


def skill_relay_station():
    body = (
        path("M22 40 L32 31 H122 L139 40 V63 H22Z", BROWN)
        + console(32, 25, 99, 38)
        + path("M48 25 V17 H79 V25", TAUPE)
        + slot(44, 51, 10)
        + slot(60, 51, 9)
        + slot(76, 51, 10)
        + bolts((27, 55), (135, 55))
    )
    active = (
        antenna(107, 25, 3)
        + ellipse(110, 45, 15, 15, BROWN)
        + ellipse(110, 45, 11, 11, CREAM, INK, 2.4)
        + line("M110 38 V45 L115 48", INK, 2.85)
    )
    return body, active, display(42, 34, 42), (110, 45), None


def dish(x, y, tilt):
    return group(
        line(f"M{x} {y+16} V{y+29}", INK, 6),
        path(
            f"M{x-22} {y-2} Q{x-14} {y-21} {x+9} {y-19} "
            f"Q{x+26} {y-15} {x+22} {y-1} Q{x+15} {y+12} {x} {y+15} "
            f"Q{x-12} {y+12} {x-22} {y-2}Z",
            CREAM,
        ),
        face(
            f"M{x-19} {y-3} Q{x-3} {y+8} {x+19} {y-6} "
            f"Q{x+17} {y+9} {x} {y+12} Q{x-11} {y+8} {x-19} {y-3}Z",
            TAUPE,
        ),
        line(f"M{x} {y+2} l6 -15", INK, 3.6),
        ellipse(x+6, y-13, 3.5, 3.5, DEEP, INK, 2),
        attrs=f'transform="rotate({tilt} {x} {y+15})"',
    )


def dispatch_relay():
    body = (
        path("M19 52 L29 40 H130 L142 52 V63 H19Z", CREAM)
        + path("M20 53 H142 V63 H20Z", OLIVE, INK, 2.5)
        + slot(30, 55, 15)
        + slot(115, 55, 15)
        + console(60, 40, 40, 23)
    )
    active = dish(44, 29, 21) + dish(115, 29, -21)
    return body, active, display(68, 48, 24), (80, 47), None


def tripod(x, y, color=OLIVE):
    return (
        path(f"M{x-11} {y-10} H{x+10} L{x+32} {y+11} H{x+16} L{x} {y-1} "
             f"L{x-14} {y+11} H{x-31}Z", color)
        + line(f"M{x} {y} v10", INK, 4)
        + rounded(x-32, y+8, 20, 7, 2, TAUPE, INK, 2.3)
        + rounded(x+13, y+8, 20, 7, 2, TAUPE, INK, 2.3)
    )


def sonic_turret():
    body = tripod(69, 50) + rounded(61, 39, 20, 11, 3, DEEP)
    active = (
        path("M31 33 L40 25 H62 L102 13 L115 19 V45 L103 51 L62 40 H40Z", OLIVE)
        + face("M41 27 H62 L62 33 H40Z", LIGHT)
        + path("M61 26 L102 14 V48 L61 39Z", CREAM)
        + face("M63 33 L102 33 V45 L63 38Z", TAUPE)
        + ellipse(105, 32, 12, 20, TAUPE)
        + ellipse(106, 32, 7.8, 15.7, GLASS, INK, 2.6)
        + ellipse(105, 32, 4, 8, CREAM)
        + slot(45, 30, 6)
    )
    indicator = line("M125 23 q6 8 0 17", AMBER, 2.5) + line("M132 18 q11 13 0 26", AMBER, 2.7)
    return body, active, indicator, (71, 41), (108, 31)


def coil(x, y):
    return (
        path(f"M{x-7} 55 L{x-10} {y+14} Q{x-11} {y+4} {x-5} {y+3} V{y-6} "
             f"Q{x} {y-14} {x+6} {y-6} V{y+2} Q{x+12} {y+4} {x+11} {y+12} "
             f"L{x+7} 55Z", DEEP)
        + rounded(x-4, y-7, 9, 11, 3, CREAM, INK, 2.1)
        + rounded(x-14, y+3, 28, 9, 3, OLIVE, INK, 2.8)
        + rounded(x-12, y+13, 24, 11, 4, BROWN, INK, 2.7)
    )


def electric_pulse_turret():
    body = (
        path("M20 60 L31 46 H125 L141 61 L137 66 H21Z", OLIVE)
        + path("M52 65 V55 L61 46 H103 L114 55 V65Z", DEEP)
        + rounded(67, 52, 29, 12, 2, CREAM, INK, 2.5)
        + bolts((38, 57), (123, 56))
    )
    active = coil(49, 27) + coil(110, 25)
    indicator = "".join(
        rounded(x - 9, y, 18, 3, 1, TEAL, "none")
        for x, y in [(49, 41), (49, 47), (110, 39), (110, 45)]
    ) + path("M76 21 L90 11 L84 22 H93 L77 34 L83 23Z", TEAL, DARK_TEAL, 1.4)
    return body, active, indicator, (80, 51), (85, 23)


def tube(x, y):
    return (
        rounded(x, y, 21, 49, 8, OLIVE)
        + rounded(x+3, y+9, 15, 7, 2, AMBER, "none")
        + face(f"M{x+4} {y+21} h4 v22 h-4Z", LIGHT)
        + ellipse(x+10.5, y+7, 8.5, 6.1, TAUPE, INK, 2.5)
        + ellipse(x+10.5, y+7, 5.1, 3.7, GLASS, INK, 1.8)
    )


def canopy_defense_launcher():
    body = (
        path("M26 64 L36 48 H114 L132 63 V65 H26Z", OLIVE)
        + path("M55 59 L58 44 L69 38 H84 L96 46 L102 63Z", DEEP)
        + ellipse(77, 50, 12, 12, BROWN)
        + bolt(77, 50)
        + bolts((40, 56), (118, 57))
    )
    active = group(
        tube(60, 12), tube(83, 7),
        path("M65 48 H98 L102 57 H61Z", BROWN, INK, 2.3),
        attrs='transform="rotate(35 80 49)"',
    )
    indicator = lamp(108, 57, AMBER) + lamp(119, 57, GOLD)
    return body, active, indicator, (80, 49), (101, 15)


def sentry_tower():
    body = (
        path("M20 138 L26 76 H34 L29 139Z", WOOD)
        + path("M49 139 L45 76 H54 L60 138Z", WOOD)
        + path("M31 84 L56 121 L53 128 L27 95Z", BROWN, INK, 2.6)
        + path("M50 85 L22 121 L25 130 L54 95Z", TAUPE, INK, 2.6)
        + line("M33 80 V127 M33 85 h13 M33 96 h14 M33 106 h14 M33 117 h15", INK, 2.4)
        + path("M17 59 H64 V81 H17Z", WOOD)
        + path("M16 70 H65 V81 L60 85 H20 L16 80Z", OLIVE)
        + rounded(16, 67, 49, 7, 1.7, WOOD, INK, 2.5)
        + line("M24 70 V81 M40 70 V81 M56 70 V81", INK, 2.2)
        + path("M22 61 V38 H27 V61Z M53 61 V38 H58 V61Z", BROWN, INK, 2.7)
        + path("M25 61 H57 V66 H25Z", DEEP, INK, 2.1)
    )
    active = (
        path("M12 41 Q11 38 16 35 L34 18 Q40 13 45 17 L66 34 Q72 39 67 43 H13Z", OLIVE)
        + face("M19 36 L37 20 Q40 18 43 20 L62 36Z", LIGHT)
        + line("M27 34 L39 23 L51 33", MOSS, 1.6)
        + path("M12 40 H68 L65 45 H16Z", DEEP, INK, 2.8)
    )
    indicator = path("M33 54 H46 L49 58 L45 62 H33Z", CREAM, INK, 2.2)
    return body, active, indicator, (40, 38), None


def firebreak_beacon():
    body = (
        console(54, 26, 86, 37)
        + rounded(69, 30, 37, 26, 4, BROWN, INK, 2.5)
        + slot(113, 32, 17)
        + slot(113, 41, 17)
        + slot(113, 50, 17)
        + bolts((61, 59), (134, 56))
    )
    active = (
        path("M24 28 V22 Q24 17 30 17 H53 Q58 17 60 22 L61 28Z", DEEP)
        + path("M19 38 Q19 26 30 26 H45 Q55 26 55 38 V61 H19Z", RUST_LIGHT)
        + face("M23 39 H51 V46 H23Z", AMBER)
        + face("M23 49 H51 V58 H23Z", RUST)
        + antenna(114, 27, 0, TAUPE)
        + slot(31, 31, 10)
    )
    indicator = (
        path("M85 36 Q85 42 88 42 Q91 39 90 34 Q98 39 99 45 "
             "Q98 52 90 52 H82 Q75 52 76 46 Q78 43 79 40 Q81 45 83 45 Q84 42 85 36Z", GOLD, "none")
        + path("M87 44 Q91 47 91 49 Q90 52 85 51 Q80 49 84 46Z", RUST, "none")
    )
    return body, active, indicator, (37, 41), (88, 44)


def specialist_calltower():
    body = (
        path("M22 62 L28 41 L46 33 H113 L132 43 L140 62Z", OLIVE)
        + face("M33 41 L48 36 H109 L121 42 H32Z", LIGHT)
        + path("M28 43 L38 39 H51 V61 H30Z", DEEP)
        + slot(59, 45, 36)
        + slot(59, 53, 29)
        + bolt(126, 54)
    )
    active = (
        antenna(43, 40, -4)
        + path("M86 34 V22 Q86 12 97 11 Q111 10 114 22 V35Z", BROWN)
        + path("M82 29 H118 V39 H82Z", DEEP)
        + rounded(86, 31, 29, 3, 1, TAUPE, "none")
    )
    indicator = path("M89 27 V22 Q90 15 98 15 Q108 14 110 22 V27Z", AMBER, INK, 2)
    indicator += ellipse(98, 20, 3.2, 2.5, GOLD, "none")
    return body, active, indicator, (99, 39), (99, 19)


def ranger_coordination_hub():
    body = (
        path("M22 58 L37 30 H112 L137 58 V64 H22Z", OLIVE)
        + path("M37 33 H112 L128 55 H33Z", CREAM)
        + path("M43 37 H108 L118 51 H40Z", DEEP, INK, 2)
        + line("M53 39 L47 49 M71 38 L67 50 M92 38 L93 50 M47 44 H111", MOSS, 1.45)
        + slot(68, 57, 23)
        + bolts((27, 59), (131, 59))
    )
    active = (
        line("M115 36 V15", INK, 6)
        + line("M115 35 V15", TAUPE, 2)
        + path("M115 15 Q125 11 131 14 Q137 17 145 12 V27 Q139 32 131 29 Q124 26 115 30Z", DEEP)
        + face("M124 23 Q128 18 133 21 L138 17 Q139 23 133 25 L132 28 L128 25Z", CREAM)
    )
    indicator = path("M75 39 Q80 36 83 41 Q85 44 78 48 Q71 44 75 39Z", AMBER, INK, 1.8)
    indicator += ellipse(78.7, 41.5, 1.1, 1.1, INK, "none")
    return body, active, indicator, (115, 36), None


def cover_wing(x, flip=False):
    drawing = (
        path("M16 56 L25 36 H45 L51 58 V65 H16Z", OLIVE)
        + face("M27 38 H43 L47 42 H25Z", LIGHT)
        + face("M22 52 H30 L24 62 H18Z M34 52 H41 L35 62 H28Z", AMBER)
        + bolt(44, 50)
    )
    return group(drawing, attrs=f'transform="translate({x} 0) scale({"-1" if flip else "1"} 1)"')


def reinforced_cover_station():
    body = (
        path("M37 58 L48 22 Q50 16 55 16 H108 Q113 18 115 26 L124 60 L118 66 H42Z", DEEP)
        + face("M53 20 H107 L111 27 H50Z", OLIVE)
        + face("M45 54 H116 L120 62 H41Z", BROWN)
        + line("M48 33 L43 51 M113 33 L118 50", MOSS, 2.2)
    )
    active = cover_wing(0) + cover_wing(160, True)
    indicator = (
        path("M80 31 Q87 35 94 35 V44 Q91 53 80 57 Q69 52 66 44 V35 Q74 35 80 31Z", CREAM, "none")
        + path("M80 36 L89 39 V44 Q87 49 80 52 Q73 48 71 44 V39Z", DEEP, "none")
    )
    return body, active, indicator, (80, 62), None


def disruption_beacon():
    body = (
        path("M26 64 L34 52 L53 49 H106 L126 54 L136 64Z", OLIVE)
        + path("M51 51 Q59 35 67 34 H94 Q103 34 109 51Z", DEEP)
        + path("M65 49 L70 36 H91 L95 49Z", TAUPE, INK, 2.5)
        + bolts((44, 57), (115, 57))
    )
    active = (
        path("M69 36 L72 22 H89 L93 36Z", WOOD)
        + path("M62 20 Q62 12 80 11 Q97 12 100 19 V25 Q96 33 80 33 Q65 32 62 25Z", DEEP)
        + ellipse(80.5, 20, 19, 9, OLIVE)
        + ellipse(80.5, 20, 13, 5.5, TEAL)
    )
    indicator = (
        line("M49 15 q-10 9 -3 20 M41 11 Q27 23 36 38", DARK_TEAL, 4)
        + line("M111 14 q10 8 4 20 M120 10 q13 12 6 26", DARK_TEAL, 4)
        + line("M49 14 q-10 9 -3 20 M41 11 Q27 23 36 38", TEAL, 2.1)
        + line("M111 14 q10 8 4 20 M120 10 q13 12 6 26", TEAL, 2.1)
        + display(66, 53, 26, AMBER)
    )
    return body, active, indicator, (80, 33), (80, 20)


DESIGNS = {
    "logistics_post": logistics_post,
    "medic_cabin": medic_cabin,
    "skill_relay_station": skill_relay_station,
    "dispatch_relay": dispatch_relay,
    "sonic_turret": sonic_turret,
    "electric_pulse_turret": electric_pulse_turret,
    "canopy_defense_launcher": canopy_defense_launcher,
    "sentry_tower": sentry_tower,
    "firebreak_beacon": firebreak_beacon,
    "specialist_calltower": specialist_calltower,
    "ranger_coordination_hub": ranger_coordination_hub,
    "reinforced_cover_station": reinforced_cover_station,
    "disruption_beacon": disruption_beacon,
}

CUES = {
    "logistics_post": ("Ready › Active on existing Token payout cue", "crate straps and field radio"),
    "medic_cabin": ("Active on confirmed kit use", "cream cross and medic-kit locker"),
    "skill_relay_station": ("Active on existing Ranger-skill cooldown pulse", "clock and amber status screen"),
    "dispatch_relay": ("Active on existing Ranger and Facility cooldown pulse", "twin opposing dishes"),
    "sonic_turret": ("Active on existing sonic hit", "cup horn and ochre sound arcs"),
    "electric_pulse_turret": ("Active on existing electrical burst hit", "paired teal coils"),
    "canopy_defense_launcher": ("Active on existing launcher hit", "twin upward tube rims"),
    "sentry_tower": ("Active for an existing detection cue if exposed", "tall lookout and reserved upper cell"),
    "firebreak_beacon": ("Active while an existing Heat suppression cue is present", "amber tank and flame monitor"),
    "specialist_calltower": ("Active on existing discount claim", "high domed amber light"),
    "ranger_coordination_hub": ("Active for an existing allied buff cue if exposed", "sloped map and Ranger pennant"),
    "reinforced_cover_station": ("Active for an existing mitigation cue if exposed", "shield plate and cover wings"),
    "disruption_beacon": ("Active for an existing disruption cue if exposed", "low aerial and teal arcs"),
}


def common_states(wide):
    """Separate visual-only states aligned to each footprint canvas."""
    dx, dy = (0, 0) if wide else (-40, 80)
    construction = (
        path("M25 58 L34 30 H125 L137 58 L136 64 H25Z", BROWN)
        + path("M27 57 L38 39 L70 37 L120 31 L131 57Z", OLIVE, INK, 2.9)
        + path("M28 62 L32 53 L112 34 L124 35 L119 42 L53 60Z", WOOD, INK, 2.4)
        + path("M66 45 L69 48 L100 43 L101 39Z", TAUPE, "none")
        + line("M41 50 V59 M123 47 V57", INK, 2.5)
    )
    siege = (
        path("M22 51 L28 44 L31 49 L36 44 L37 52 L44 54 L35 57 L32 63 L29 57 L22 59Z", AMBER, INK, 2)
        + line("M123 49 l8 -7 M129 53 l9 -2", RUST_LIGHT, 2.4)
        + path("M53 60 L57 57 L62 61 L59 63Z M111 61 L115 57 L118 59 L117 62Z", RUST, "none")
    )
    ruin = (
        path("M25 65 L37 54 L46 56 L53 43 L74 45 L86 54 L109 50 L123 55 L137 63 L128 65Z", SHADOW)
        + path("M46 56 L55 47 L74 50 L79 58 L68 62 L50 62Z", BROWN, INK, 2)
        + face("M94 55 L111 53 L126 61 H104Z", DEEP)
        + line("M55 49 l13 4 M105 58 l9 2", RUST, 2)
    )
    if wide:
        return {"construction": construction, "siege": siege, "ruin": ruin}

    # This mini kit is redrawn for the tower's one-cell plinth instead of
    # rescaling the wider frame. Every piece remains below the mount.
    construction = (
        path("M15 59 L21 33 H57 L65 60 V65 H15Z", BROWN)
        + path("M20 56 L25 39 L56 36 L60 57Z", OLIVE, INK, 2.6)
        + line("M25 55 L54 43 M23 51 V60 M56 48 V59", WOOD, 5)
    )
    siege = (
        path("M19 48 L26 43 L28 48 L34 46 L33 52 L38 55 L31 56 L27 62 L24 57 L18 56Z", AMBER, INK, 2)
        + line("M51 49 l6 -5 M55 54 l8 -2", RUST_LIGHT, 2.4)
    )
    ruin = (
        path("M17 65 L24 58 L29 59 L38 43 L49 50 L54 55 L60 58 L65 65Z", SHADOW)
        + path("M25 60 L38 46 L46 50 L36 63Z", WOOD, INK, 2.4)
        + line("M43 60 L54 57 L60 62", DEEP, 3)
    )
    return {
        key: group(art, attrs=f'transform="translate({dx+40} {dy})"')
        for key, art in {"construction": construction, "siege": siege, "ruin": ruin}.items()
    }


def safe_mount_label(slug):
    return "".join(p.capitalize() for p in slug.split("_"))


def write_svg(pathname, title, size, layers):
    w, h = size
    body = "\n".join(
        f'  <g id="{key}" inkscape:groupmode="layer" inkscape:label="{key}">{value}</g>'
        for key, value in layers.items()
    )
    pathname.parent.mkdir(parents=True, exist_ok=True)
    pathname.write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" '
        f'width="{w*DENSITY}" height="{h*DENSITY}" viewBox="0 0 {w} {h}">\n'
        f"  <title>{escape(title)}</title>\n{body}\n</svg>\n"
    )


def render(svg, output, layer=None):
    command = ["inkscape", str(svg), "--export-area-page", f"--export-filename={output}"]
    if layer:
        command.extend([f"--export-id={layer}", "--export-id-only"])
    subprocess.run(command, check=True, capture_output=True)
    with Image.open(output) as png:
        return png.convert("RGBA")


def sha(pathname):
    return hashlib.sha256(pathname.read_bytes()).hexdigest()


def ref(pathname):
    return "res://" + pathname.relative_to(ROOT).as_posix()


def cutout(image, path_out, pivot, name, parent, z):
    bounds = image.getbbox()
    assert bounds is not None, f"{name} has no pixels"
    assert bounds[0] >= 4 and bounds[1] >= 4
    assert bounds[2] <= image.width - 4 and bounds[3] <= image.height - 4
    x0, y0, x1, y1 = [coord + inset for coord, inset in zip(bounds, [-4, -4, 4, 4])]
    cropped = image.crop((x0, y0, x1, y1))
    path_out.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(path_out, optimize=True)
    return {
        "id": name,
        "parent": parent,
        "draw_order": z,
        "texture": ref(path_out),
        "sha256": sha(path_out),
        "origin_png_px": [x0, y0],
        "size_px": list(cropped.size),
        "alpha_bounds_canvas_px_xyxy": list(bounds),
        "pivot_units": list(pivot),
        "pivot_local_png_px": [pivot[0]*DENSITY-x0, pivot[1]*DENSITY-y0],
    }


def file_entry(image, path_out):
    image.save(path_out, optimize=True)
    return {"texture": ref(path_out), "size_px": list(image.size), "sha256": sha(path_out)}


def badge(image):
    full = image.crop(image.getbbox())
    full.thumbnail((96, 96), Image.Resampling.LANCZOS)
    thumb = Image.new("RGBA", (112, 112))
    thumb.alpha_composite(full, ((112-full.width)//2, (112-full.height)//2))
    return thumb


def layer_frames(name, position, boot_angle):
    """Visual numbers only. No timers, range, costs, output or damage here."""
    ready_parts = ["base", "body", "active", "indicator"]
    return {
        "Ready": {"length": 2.0, "loop": True, "visible": ready_parts,
                  "indicator_alpha": [[0.0, 0.83], [1.0, 1.0], [2.0, 0.83]]},
        "Active": {"length": 0.45, "loop": False, "visible": ready_parts,
                   "indicator_alpha": [[0.0, 0.68], [0.11, 1.0], [0.45, 0.84]],
                   "part_rotation_degrees": [[0.0, 0.0], [0.11, boot_angle], [0.45, 0.0]],
                   "socket": position, "cue": CUES[name][0]},
        "Ghost": {"length": 0.1, "loop": False, "visible": ready_parts, "opacity": 0.52},
        "Construction": {"length": 0.1, "loop": False, "visible": ["base", "construction"]},
        "UnderSiege": {"length": 0.5, "loop": False, "visible": ready_parts + ["siege"],
                       "siege_alpha": [[0.0, 0.3], [0.12, 1.0], [0.5, 0.0]]},
        "ConstructionUnderSiege": {"length": 0.5, "loop": False, "visible": ["base", "construction", "siege"],
                                   "siege_alpha": [[0.0, 0.3], [0.12, 1.0], [0.5, 0.0]]},
        "Destroyed": {"length": 0.3, "loop": False, "visible": ["base", "ruin"]},
    }


def read_specs():
    catalog = (ROOT / "data/facilities/catalog.tres").read_text()
    listed = re.findall(r'res://data/facilities/([a-z_]+)\.tres"', catalog)
    assert set(listed) == set(DESIGNS), (listed, list(DESIGNS))
    record = {}
    for slug in listed:
        spec = (ROOT / f"data/facilities/{slug}.tres").read_text()
        resource = dict(re.findall(r"^(id|label|kind) = (.+)$", spec, re.M))
        aid = resource["id"].removeprefix('&"').removesuffix('"')
        label = resource["label"].strip('"')
        kind = resource["kind"]
        assert kind == ("4" if slug == "sentry_tower" else "3")
        record[slug] = (aid, label, kind == "3")
    return record


def assemble_common(temp):
    result = {}
    for wide in (True, False):
        size = (160, 80) if wide else (80, 160)
        anchor = (80, 67) if wide else (40, 147)
        key = "pair" if wide else "sentry"
        svg = SOURCE / "shared" / f"{key}_states.svg"
        layers = common_states(wide)
        write_svg(svg, f"{key.title()} Facility visual states", size, layers)
        path = OUTPUT / "shared" / key
        path.mkdir(parents=True, exist_ok=True)
        result[wide] = [
            cutout(render(svg, temp / "full.png", part), path / f"{part}.png", anchor, part, "base", z)
            for part, z in [("construction", 5), ("siege", 7), ("ruin", 6)]
        ]
    return result


def assemble(slug, spec, common, temp):
    aid, label, wide = spec
    canvas = (160, 80) if wide else (80, 160)
    anchor = (80, 67) if wide else (40, 147)
    out = OUTPUT / slug
    src = SOURCE / slug
    src.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)
    body, active, indicator, active_pivot, socket = DESIGNS[slug]()
    layers = {"base": sled(wide), "body": body, "active": active, "indicator": indicator}
    svg = src / "master.svg"
    write_svg(svg, f"{label} · W29", canvas, layers)
    composite = Image.new("RGBA", tuple(value * DENSITY for value in canvas))
    descriptors = []
    for z, (layer, pivot, parent) in enumerate([
        ("base", anchor, None), ("body", anchor, "base"),
        ("active", active_pivot, "body"), ("indicator", active_pivot, "active"),
    ]):
        image = render(svg, temp / "full.png", layer)
        composite = Image.alpha_composite(composite, image)
        descriptors.append(cutout(image, out / f"{layer}.png", pivot, layer, parent, z))
    flattened = render(svg, temp / "full.png")
    max_difference = max(high for low, high in ImageChops.difference(
        composite.convert("RGBa"), flattened.convert("RGBa")
    ).getextrema())
    assert max_difference <= 3, (slug, max_difference)

    active_rot = -4.0 if slug in {"sonic_turret", "canopy_defense_launcher"} else 0.0
    clips = layer_frames(slug, socket, active_rot)
    md = {
        "schema_version": 1,
        "asset_version": "0.1.0",
        "asset_id": aid,
        "display_name": label,
        "status": "unbound_presentation_asset",
        "source": ref(svg),
        "source_sha256": sha(svg),
        "provenance": "Original vector redraw for Kenyalang Rangers, W29, based on W08 facilities.png and the C28-A crate/radio, sage terrain and ink palette.",
        "permission_review": "D-014 pending final shipping sign-off.",
        "canon_refs": ["SimSimi pp. 15–17 § J", "Storyboard pp. 17, 28–29, 66, 69, 127"],
        "readability_cue": CUES[slug][1],
        "canvas_units": list(canvas),
        "pixels_per_unit": DENSITY,
        "tile_units": TILE,
        "footprint_cells": [[0, 0], [1, 0]] if wide else [[0, 0]],
        "reserved_cells": [] if wide else [[0, -1]],
        "canvas_origin_from_occupied_cell_top_left_units": [0, 0 if wide else -TILE],
        "base_anchor_canvas_units": list(anchor),
        "anchor_from_occupied_cell_top_left_units": [anchor[0], 67],
        "ready_alpha_bounds_canvas_px_xyxy": list(composite.getbbox()),
        "world_scale": "One scalar tile_size()/80 for both axes. Place root at tile origin plus anchor_from_occupied_cell_top_left_units times scalar.",
        "portrait_scale": "Fit uniformly inside card art area. The badge already has transparent square padding.",
        "mount_socket_canvas_units": None if wide else [40, 59],
        "parts": descriptors + common,
        "states": clips,
        "badge": file_entry(badge(composite), out / "badge.png"),
        "rig": ref(out / "rig.tscn"),
        "master_reassembly_max_premultiplied_channel_delta": max_difference,
    }
    (src / "manifest.json").write_text(json.dumps(md, indent=2, ensure_ascii=False) + "\n")
    (out / "rig.tscn").write_text(scene_text(slug, md))
    return md, composite


def godot_color(alpha):
    return f"Color(1, 1, 1, {alpha:g})"


def values_track(index, path_to_property, times, values, discrete=False):
    def packed(values):
        return "PackedFloat32Array(" + ", ".join(f"{value:g}" for value in values) + ")"

    track = f"tracks/{index}"
    return [
        f'{track}/type = "value"',
        f"{track}/imported = false",
        f"{track}/enabled = true",
        f'{track}/path = NodePath("{path_to_property}")',
        f"{track}/interp = 1",
        f"{track}/loop_wrap = true",
        f"{track}/keys = {{",
        f'"times": {packed(times)},',
        f'"transitions": {packed([1] * len(times))},',
        f'"update": {1 if discrete else 0},',
        '"values": [' + ", ".join(values) + "]",
        "}",
    ]


def scene_text(slug, md):
    parts = md["parts"]
    states = md["states"]
    title = safe_mount_label(slug)
    paths = {}
    lines = [f"[gd_scene load_steps={len(parts)+len(states)+2} format=3]", ""]
    for part in parts:
        key = part["id"]
        lines.append(f'[ext_resource type="Texture2D" path="{part["texture"]}" id="{key}"]')
        parent = paths.get(part["parent"], ".")
        paths[key] = f"{parent}/{key}" if parent != "." else key

    for state, clip in states.items():
        lines.extend([
            "", f'[sub_resource type="Animation" id="Animation_{state}"]',
            f'resource_name = "{state}"',
            f'length = {clip["length"]:g}',
            f'loop_mode = {1 if clip["loop"] else 0}',
        ])
        for index, part in enumerate(parts):
            key = part["id"]
            lines.extend(values_track(index, f"{paths[key]}/Art:visible", [0], [
                "true" if key in clip["visible"] else "false"
            ], discrete=True))
        tracks = [
            (f'{paths["active"]}:rotation_degrees', clip.get("part_rotation_degrees", [[0, 0]]), False),
            (f'{paths["indicator"]}/Art:self_modulate', clip.get("indicator_alpha", [[0, 1]]), True),
            (f'{paths["siege"]}/Art:self_modulate', clip.get("siege_alpha", [[0, 1]]), True),
            (f'{paths["base"]}:modulate', [[0, clip.get("opacity", 1)]], True),
        ]
        for index, (property_path, track, color) in enumerate(tracks, len(parts)):
            lines.extend(values_track(index, property_path, [time for time, _ in track], [
                godot_color(value) if color else f"{value:g}" for _, value in track
            ]))

    lines.extend(["", '[sub_resource type="AnimationLibrary" id="VisualStates"]', "_data = {"])
    lines.extend(
        f'&"{state}": SubResource("Animation_{state}")' + ("," if index < len(states) - 1 else "")
        for index, state in enumerate(states)
    )
    lines.extend(["}", "", f'[node name="{title}" type="Node2D"]', 'texture_filter = 2',
                  f'metadata/asset_id = &"{md["asset_id"]}"'])
    pivots = {part["id"]: part["pivot_units"] for part in parts}
    for part in parts:
        key = part["id"]
        parent = part["parent"]
        parent_path = paths.get(parent, ".")
        position = [
            part["pivot_units"][axis] - pivots.get(parent, md["base_anchor_canvas_units"])[axis]
            for axis in range(2)
        ]
        local = [value / -DENSITY for value in part["pivot_local_png_px"]]
        lines.extend([
            "", f'[node name="{key}" type="Node2D" parent="{parent_path}"]',
            f"position = Vector2({position[0]:g}, {position[1]:g})",
            "", f'[node name="Art" type="Sprite2D" parent="{paths[key]}"]',
            f'visible = {"true" if key in states["Ready"]["visible"] else "false"}',
            f'z_index = {part["draw_order"]}',
            "z_as_relative = false",
            "centered = false",
            'scale = Vector2(0.25, 0.25)',
            f'position = Vector2({local[0]:g}, {local[1]:g})',
            f'texture = ExtResource("{key}")',
        ])
    if md["mount_socket_canvas_units"]:
        x, y = (
            value - origin
            for value, origin in zip(md["mount_socket_canvas_units"], md["base_anchor_canvas_units"])
        )
        lines.extend(["", '[node name="MountSocket" type="Marker2D" parent="."]',
                      f"position = Vector2({x:g}, {y:g})"])
    lines.extend(["", '[node name="AnimationPlayer" type="AnimationPlayer" parent="."]',
                  'libraries = {&"": SubResource("VisualStates")}', 'autoplay = "Ready"', ""])
    return "\n".join(lines)


def scaled(image, units, scale):
    target = tuple(round(value * scale) for value in units)
    return image.resize(target, Image.Resampling.LANCZOS)


def tiles_proof(panel, pos, art, descriptor, cell, tile, reserved):
    cells = descriptor["footprint_cells"]
    tower = bool(descriptor["reserved_cells"])
    for dx, dy in cells:
        panel.alpha_composite(tile[cell], (pos[0]+dx*cell, pos[1]+(dy+tower)*cell))
    if tower:
        panel.alpha_composite(reserved[cell], pos)
    panel.alpha_composite(scaled(art, descriptor["canvas_units"], cell/TILE), pos)


def story_fonts():
    paths = Path("/usr/share/fonts/truetype/dejavu")
    return tuple(
        ImageFont.truetype(str(paths / face), size)
        for face, size in [("DejaVuSans-Bold.ttf", 45), ("DejaVuSans.ttf", 20),
                           ("DejaVuSans-Bold.ttf", 17), ("DejaVuSans.ttf", 14)]
    )


def make_review(records):
    bg = "#f1e7d3"
    text = "#2b2f22"
    quiet = "#685e4b"
    card = "#e6dabb"
    dark = "#313b2b"
    header, label, name, small = story_fonts()
    artwork = Image.open(ROOT / "assets/imported/first_contact/parts/terrain/KRT_21.png").convert("RGBA")
    tile = {cell: scaled(artwork, (TILE,TILE), cell/TILE) for cell in (80,60)}
    reserve_sprite = Image.open(ROOT / "assets/imported/first_contact/parts/terrain/KRT_55.png").convert("RGBA")
    reserved = {
        cell: Image.alpha_composite(tile[cell], scaled(reserve_sprite, (TILE,TILE), cell/TILE))
        for cell in (80,60)
    }

    sheet = Image.new("RGBA", (1308, 1130), bg)
    draw = ImageDraw.Draw(sheet)
    draw.rectangle((0,0,1308,144), fill=dark)
    draw.text((40, 28), "Facility field kits", font=header, fill="#f5ecd7")
    draw.text((42, 94), "Kenyalang Rangers  /  W29  /  Ready artwork on matching raised pads", font=label, fill="#d7c8a8")
    for index, (slug, (md, rg)) in enumerate(records.items()):
        col, row = index % 4, index // 4
        x, y = 28+col*316, 164+row*234
        draw.rounded_rectangle((x,y,x+302,y+222), 12, fill=card, outline="#cdbd9b", width=1)
        draw.text((x+14,y+13), md["display_name"], font=name, fill=text)
        draw.text((x+14,y+40), md["readability_cue"], font=small, fill=quiet)
        if slug == "sentry_tower":
            tiles_proof(sheet, (x+44,y+59), rg, md, 80, tile, reserved)
            tiles_proof(sheet, (x+174,y+99), rg, md, 60, tile, reserved)
            draw.text((x+59,y+201), "80 px", font=small, fill="#f7efda", stroke_width=2, stroke_fill=dark)
            draw.text((x+180,y+201), "60 px", font=small, fill="#f7efda", stroke_width=2, stroke_fill=dark)
        else:
            tiles_proof(sheet, (x+12,y+89), rg, md, 80, tile, reserved)
            tiles_proof(sheet, (x+180,y+109), rg, md, 60, tile, reserved)
            draw.text((x+14,y+180), "80 px tile", font=small, fill=quiet)
            draw.text((x+181,y+180), "60 px tile", font=small, fill=quiet)
    draw.text((1000, 1099), "Shared scale  /  distinct role silhouettes", font=small, fill=quiet)
    sheet.convert("RGB").save(REVIEW / "facility_review.png", optimize=True)

    # Plot the actual status textures with the Ready PNGs on the same pads.
    states = Image.new("RGBA", (1290,620), bg)
    pen = ImageDraw.Draw(states)
    pen.rectangle((0, 0, 1290, 142), fill=dark)
    pen.text((34, 28), "Footprints and lifecycle", font=header, fill="#f5ecd7")
    pen.text((37, 94), "Registered layers at 80 px per tile", font=label, fill="#d7c8a8")
    demonstration = [("Ready", "Ready"), ("Ghost", "Placement ghost"),
                     ("Construction", "Construction"), ("UnderSiege", "Under Siege"),
                     ("ConstructionUnderSiege", "Building under Siege"), ("Destroyed", "Destroyed")]

    for row, slug in enumerate(["logistics_post", "sentry_tower"]):
        md, _ = records[slug]
        top = 153 + row*207
        pen.text((36,top+9), md["display_name"], font=name, fill=text)
        for column, (clip, display_name) in enumerate(demonstration):
            example = compose_state(md, clip)
            x = 31 + column*208
            y = top + 40
            tiles_proof(states, (x,y), example, md, 80, tile, reserved)
            pen.text((x,y+80*(1+row)+10), display_name, font=small, fill=quiet)
    states.convert("RGB").save(REVIEW / "facility_states.png", optimize=True)


def compose_state(md, clip):
    state = md["states"][clip]
    art = Image.new("RGBA", tuple(value * DENSITY for value in md["canvas_units"]))
    for part in md["parts"]:
        if part["id"] not in state["visible"]:
            continue
        with Image.open(ROOT / part["texture"].removeprefix("res://")) as texture:
            art.alpha_composite(texture, tuple(part["origin_png_px"]))
    if state.get("opacity"):
        art.putalpha(art.getchannel("A").point(lambda value: round(value*state["opacity"])))
    return art


RIG_CHECK = '''extends SceneTree

var checks := 0
var fails := 0

func _initialize() -> void:
	call_deferred("_verify")

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		push_error(label)

func _verify() -> void:
	var records: Array = JSON.parse_string(FileAccess.get_file_as_string("res://records.json"))
	var samples := 0
	var textures := {}
	for record: Dictionary in records:
		var rig := (load(record.rig) as PackedScene).instantiate() as Node2D
		var id: String = record.asset_id
		root.add_child(rig)
		var anim := rig.get_node("AnimationPlayer") as AnimationPlayer
		var art: Dictionary = {}
		var masks: Dictionary = {}
		for sprite: Node in rig.find_children("Art", "Sprite2D", true, false):
			var image := (sprite as Sprite2D).texture.get_image()
			var box := image.get_used_rect()
			art[sprite.get_parent().name] = sprite
			masks[sprite.get_parent().name] = Rect2(box)
			textures[(sprite as Sprite2D).texture.resource_path] = true
		for part: Dictionary in record.parts:
			var sprite: Sprite2D = art[part.id]
			var expected := Vector2(float(part.size_px[0]), float(part.size_px[1]))
			expect(sprite.texture.get_size() == expected, id + " texture size")
			expect(sprite.texture.resource_path == part.texture, id + " texture path")
			var used: Rect2 = masks[part.id]
			expect(used.position == Vector2(4, 4) and used.end == expected - Vector2(4,4), id + " alpha padding")
			expect(sprite.z_index == int(part.draw_order), id + " draw order")
		var badge := (load(record.badge.texture) as Texture2D).get_image()
		textures[record.badge.texture] = true
		expect(badge.get_width() == 112 and badge.get_height() == 112 and badge.detect_alpha() != Image.ALPHA_NONE, id + " badge")
		for cell: int in [80, 60]:
			var scalar := float(cell) / 80.0
			rig.scale = Vector2.ONE * scalar
			var anchor := Vector2(float(record.base_anchor_canvas_units[0]), float(record.base_anchor_canvas_units[1]))
			rig.position = anchor * scalar
			var limits := Rect2(Vector2.ZERO, Vector2(float(record.canvas_units[0]), float(record.canvas_units[1])) * scalar)
			for state: String in record.states:
				var definition: Dictionary = record.states[state]
				var clip := anim.get_animation(state)
				expect(clip != null and is_equal_approx(clip.length, float(definition.length)), id + " clip " + state)
				anim.play(state)
				for frame: int in range(21):
					anim.seek(clip.length * float(frame) / 20.0, true)
					samples += 1
					for part: Dictionary in record.parts:
						var sprite: Sprite2D = art[part.id]
						expect(sprite.is_visible_in_tree() == (part.id in definition.visible), id + " " + state + " visibility " + part.id)
						if not sprite.is_visible_in_tree():
							continue
						var rect := sprite.get_global_transform() * (masks[part.id] as Rect2)
						expect(limits.encloses(rect), id + " " + state + " alpha outside footprint")
			if not record.reserved_cells.is_empty():
				var mount := rig.get_node("MountSocket") as Marker2D
				expect(mount.position.y < -67.0 and mount.position.y > -147.0, id + " mount in reservation")
		rig.free()
	print("W29 facilities: %d rigs, %d unique textures, %d animated scale samples, %d checks, %d failures" %
			[records.size(), textures.size(), samples, checks, fails])
	quit(0 if fails == 0 else 1)
'''


def godot_check(records):
    import shutil

    version = subprocess.check_output(["godot", "--version"], text=True).strip()
    assert version.startswith((ROOT / ".godot-version").read_text().strip() + ".stable"), version
    with TemporaryDirectory(prefix="w29-facilities-import-") as tmp:
        project = Path(tmp)
        (project / "project.godot").write_text(
            'config_version=5\n[application]\nconfig/name="W29 Facility artwork proof"\n'
            '[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
        )
        descriptors = [item[0] for item in records.values()]
        (project / "records.json").write_text(json.dumps(descriptors))
        (project / "verify.gd").write_text(RIG_CHECK)
        shutil.copytree(OUTPUT, project / OUTPUT.relative_to(ROOT), ignore=shutil.ignore_patterns("*.import"))
        command = ["godot", "--headless", "--path", str(project)]
        stage = subprocess.run(command + ["--editor", "--import", "--quit"], capture_output=True, text=True)
        assert stage.returncode == 0 and "ERROR:" not in stage.stderr, stage.stdout + stage.stderr
        result = subprocess.run(command + ["--script", "res://verify.gd"], capture_output=True, text=True)
        assert result.returncode == 0 and "ERROR:" not in result.stderr, result.stdout + result.stderr[-6000:]
        print(result.stdout.strip())
        print("All Facility visuals verified on the pinned engine in an isolated project.")


def existing_records():
    records = {}
    for slug in read_specs():
        descriptor = json.loads((SOURCE / slug / "manifest.json").read_text())
        assert sha(ROOT / descriptor["source"].removeprefix("res://")) == descriptor["source_sha256"]
        assert (ROOT / descriptor["rig"].removeprefix("res://")).is_file()
        for art in [*descriptor["parts"], descriptor["badge"]]:
            pathname = ROOT / art["texture"].removeprefix("res://")
            assert sha(pathname) == art["sha256"], pathname
        records[slug] = (descriptor, compose_state(descriptor, "Ready"))
    return records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="re-export originals, textures, manifests, and review sheets")
    parser.add_argument("--godot", action="store_true", help="verify scene and texture imports and state transforms")
    args = parser.parse_args()
    if args.write:
        SOURCE.mkdir(parents=True, exist_ok=True)
        (SOURCE / ".gdignore").touch()
        REVIEW.mkdir(parents=True, exist_ok=True)
        (REVIEW / ".gdignore").touch()
        with TemporaryDirectory(prefix="w29-facilities-render-") as tmp:
            temp = Path(tmp)
            common = assemble_common(temp)
            records = {
                slug: assemble(slug, spec, common[spec[2]], temp)
                for slug, spec in read_specs().items()
            }
        make_review(records)
    else:
        records = existing_records()
    print(f"{len(records)} Facility roles match the canonical catalog.")
    if args.godot:
        godot_check(records)


if __name__ == "__main__":
    main()
