"""Build editable W29 hostile variants from the approved E02 artwork and pivots.

Run with --write to synthesize the master SVGs and contracts, then rasterize each
named cutout using the standard W27 tool. The original E01/E02 assets stay intact.
"""
from __future__ import annotations

import argparse
import copy
import json
import os
import re
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

from export_w27_cutouts import ROOT, export_unit, sha256

SVG = "http://www.w3.org/2000/svg"
XLINK = "http://www.w3.org/1999/xlink"
INKSCAPE = "http://www.inkscape.org/namespaces/inkscape"
ET.register_namespace("", SVG)
ET.register_namespace("xlink", XLINK)
ET.register_namespace("inkscape", INKSCAPE)
E02 = ROOT / "assets/source-art/enemies/e02"
INK = "#32251f"
STEEL = "#6f6659"
SAND = "#bda275"
AMBER = "#e0ac60"
CREAM = "#dbc19a"
RED = "#9e4e3b"
PLUM = "#5e3c36"
TOR = [49.125, 66.125]
LEFT_HIP = [35.875, 70.375]
FAR_PALM = [60.875, 67.375]
NEAR_PALM = [37.125, 67.125]


def tag(label):
    return f"{{{SVG}}}{label}"


def xml(content):
    return ET.fromstring(f'<g xmlns="{SVG}" xmlns:xlink="{XLINK}">{content}</g>')


def path(d, fill, width=2.1, stroke=INK):
    return (f'<path d="{d}" fill="{fill}" stroke="{stroke if width else "none"}" '
            f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')


def circle(x, y, r, fill, width=1.5):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{INK}" stroke-width="{width}"/>'


def ring(d, stroke, width):
    return path(d, "none", width, stroke)


def rect(x, y, w, h, rx, fill, width=2):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" '
            f'stroke="{INK}" stroke-width="{width}"/>')


# Back hair, cropped top/fringe, and one tone of painted highlight. The screen-
# right face, eyes and neck connect to the original art at the approved pivots.
HAIR = {
    "trail_crest": ("#4a342b", "#654438", "#8b6150",
        "M31 48 Q25 50 26 43 L30 33 Q27 30 31 26 L35 23 L37 19 L41 21 Q45 15 49 19 Q55 15 59 20 Q66 20 68 29 L67 42 Q69 49 63 51 L61 47 L42 49 L38 51 L33 49Z",
        "M27 41 Q26 36 30 31 L30 27 L37 23 L38 19 L43 21 Q46 16 50 20 Q57 17 61 22 Q67 23 68 28 L65 34 Q63 29 59 29 Q52 34 46 35 L41 39 L37 37 L34 41 L32 47 L29 44Z",
        "M35 28 Q39 23 45 23 L48 21 Q52 20 55 22 Q51 24 49 24 Q43 25 40 29 L36 30Z"),
    "block_crop": ("#3e302b", "#54433b", "#6b574b",
        "M28 42 L27 32 Q27 25 34 21 Q41 17 49 18 L61 20 Q67 22 68 30 L67 44 Q68 49 63 51 L59 47 L41 49 Q37 52 33 50 L29 49Z",
        "M28 35 L28 29 Q28 23 34 21 Q43 17 51 19 L62 21 Q67 22 68 29 L65 36 L62 33 L59 29 L50 28 L44 30 L41 34 L37 36 L36 41 L31 44 L29 40Z",
        "M32 26 Q40 21 49 22 L61 24 L61 26 L47 25 L39 27 L34 29Z"),
    "slick_back": ("#47332d", "#67463a", "#986851",
        "M28 40 L27 34 Q25 30 29 25 Q39 16 51 18 Q57 17 62 21 L67 24 Q70 29 67 35 L68 44 Q68 48 64 50 L61 46 L42 50 L34 50 Q28 49 28 40Z",
        "M28 37 Q25 33 28 28 Q34 20 44 19 Q51 17 57 19 L62 21 Q66 23 67 29 L65 37 L63 32 L60 28 Q51 22 44 31 Q41 34 36 35 L34 43 L31 44Z",
        "M32 28 Q42 19 50 22 Q44 24 41 26 Q38 30 32 31Z"),
    "ash_part": ("#494039", "#65554a", "#a08470",
        "M29 42 Q25 37 28 31 Q26 26 33 23 Q35 17 45 19 L50 17 Q54 18 56 21 Q63 19 67 25 Q71 32 67 38 L68 44 Q67 50 63 51 L60 46 L39 50 Q31 51 29 42Z",
        "M28 37 Q25 33 29 29 Q25 24 33 22 Q36 17 44 19 Q48 16 50 18 L50 25 L46 29 Q43 35 37 37 L34 43 L30 44Z M51 25 L52 18 Q57 20 59 22 Q62 20 66 24 Q70 29 67 35 L64 37 Q64 31 60 30 L55 29Z",
        "M32 25 Q36 20 43 21 L47 21 Q44 23 42 25 L34 28Z M54 21 Q59 23 62 23 L65 27 L59 26Z"),
    "tight_curls": ("#3d2c27", "#563b32", "#775745",
        "M29 40 Q24 40 27 33 Q24 27 30 25 Q29 20 36 21 Q38 15 44 19 Q49 14 54 19 Q61 16 64 22 Q69 24 67 29 Q71 33 67 40 L68 45 Q67 50 63 51 L59 46 L43 49 L37 52 Q29 51 29 40Z",
        "M28 36 Q24 32 28 29 Q26 24 31 24 Q31 19 36 21 Q39 16 45 19 Q49 15 54 19 Q59 17 63 22 Q67 22 66 28 Q70 31 65 36 L63 31 Q59 29 56 30 Q53 27 49 31 Q46 30 44 34 Q39 33 36 38 L34 42 L30 44Z",
        "M30 28 Q31 25 34 25 L37 24 L40 20 Q43 21 44 23 Q46 20 50 20 L52 21 L48 24 L42 25 Q39 27 34 28Z"),
    "tied_tail": ("#47322c", "#634338", "#8b6652",
        "M30 39 Q24 40 25 34 L23 31 Q26 28 31 27 Q33 19 45 18 Q53 17 59 20 Q65 20 68 27 Q70 32 67 39 L68 44 Q67 50 63 51 L60 47 L42 49 L36 51 Q28 51 29 43Z",
        "M28 38 L29 32 L25 33 L24 30 Q26 27 32 27 Q35 20 44 19 Q50 17 58 20 L64 23 Q68 28 67 31 L64 36 L61 30 L58 28 Q50 27 44 34 L38 37 L35 44 L31 43Z",
        "M32 28 Q37 21 45 21 L52 21 Q47 23 43 25 L39 29 L34 30Z"),
    "high_crop": ("#47312a", "#674638", "#925f49",
        "M28 42 Q26 39 28 33 L27 28 Q29 25 33 24 L35 20 L41 20 L45 17 L49 19 L53 17 L58 20 L64 21 Q68 24 68 31 L66 42 Q69 48 63 51 L59 46 L41 50 Q34 52 30 48Z",
        "M27 36 L27 29 L33 25 L34 21 L40 21 L45 17 L49 20 L53 18 L59 21 L63 21 Q67 24 68 28 L65 35 L62 30 L58 27 Q54 28 50 28 Q44 31 37 33 L34 42 L31 43Z",
        "M34 25 L39 23 L45 20 L49 22 L54 20 L59 23 L53 24 L48 24 L45 23 L40 26 L35 27Z"),
    "brushed_fringe": ("#463a32", "#5a4b41", "#816e60",
        "M27 42 L26 35 Q23 29 29 26 Q32 19 45 18 Q57 16 64 21 Q69 25 68 33 L67 42 Q69 48 63 51 L60 46 L39 51 Q30 53 27 42Z",
        "M26 37 Q23 32 27 28 Q28 26 31 24 Q34 19 45 18 Q56 17 62 21 Q68 23 68 30 L66 36 L63 31 L59 29 L51 31 L48 34 L44 34 Q39 39 35 37 L32 44 L29 44Z",
        "M29 32 Q31 24 42 22 L54 21 Q50 23 45 25 Q36 25 32 31Z"),
    "short_crest": ("#3e2c29", "#573934", "#7b5145",
        "M26 42 Q24 38 27 32 Q25 26 31 23 L36 22 Q40 15 46 18 L52 17 L55 19 Q63 18 66 23 Q71 28 67 36 L67 44 Q67 49 63 52 L59 46 L43 49 L35 52 Q27 51 26 42Z",
        "M27 37 L26 32 Q24 26 31 24 L37 22 Q39 16 46 18 L52 17 L57 20 Q64 20 67 25 L66 33 L64 36 L61 31 L57 28 L52 29 L48 31 L42 33 L38 38 L35 40 L34 43 L29 45Z",
        "M34 27 Q37 23 42 23 L46 20 L50 21 L54 20 L60 23 L54 24 L49 24 L45 23 Q42 26 37 28Z"),
    "operator_crop": ("#4f3027", "#704633", "#956248",
        "M27 43 Q25 37 28 31 Q25 25 32 22 Q36 18 47 18 Q52 16 58 20 Q63 19 68 25 L67 34 L67 44 Q67 49 63 51 L59 47 L41 49 L35 51 Q28 50 27 43Z",
        "M28 36 Q25 31 28 27 Q33 18 47 18 Q53 17 58 20 L63 21 Q69 26 67 32 L65 36 L63 31 L57 27 L52 27 Q47 28 43 34 L38 36 L35 42 L32 44 L29 41Z",
        "M34 27 Q41 21 48 21 L56 22 L54 24 L47 24 Q40 25 36 29Z"),
    "oiled_wave": ("#362825", "#4c3932", "#785745",
        "M27 42 Q24 40 25 34 Q27 30 28 29 Q25 24 32 22 Q38 16 45 19 Q53 15 58 19 L62 21 Q70 24 68 35 L67 43 Q68 49 63 51 L60 47 L39 51 Q29 52 27 42Z",
        "M26 38 Q23 35 27 31 Q24 27 29 24 Q34 17 45 19 Q52 16 58 20 Q65 20 67 26 L68 30 L65 36 Q63 31 59 28 Q56 26 52 28 Q49 33 44 34 L40 33 L36 38 L33 44 L29 45Z",
        "M31 29 Q34 22 40 22 L46 23 Q49 21 53 21 L58 23 Q52 22 49 25 L45 27 Q39 23 34 29Z"),
    "captain": ("#493129", "#694737", "#9a6d54",
        "M26 43 L26 36 Q24 29 29 24 Q31 18 39 17 Q44 12 52 15 L58 13 L61 17 Q66 16 69 22 L69 26 Q73 31 69 39 L70 44 Q69 50 64 53 L60 47 L40 50 L35 54 Q26 51 26 43Z",
        "M27 38 Q24 34 27 28 Q28 20 38 17 Q45 13 52 16 L58 13 L61 17 Q66 16 69 23 Q72 30 67 35 L64 30 L59 27 L54 27 Q49 32 43 33 L40 37 L37 37 L34 43 L29 45Z",
        "M31 27 Q33 20 43 18 L51 19 L57 16 L59 20 L64 20 L66 24 L61 23 L58 21 L53 23 L49 23 L45 21 Q38 22 34 28Z"),
    "foreman": ("#43403a", "#625b50", "#9c8d7a",
        "M26 43 L25 34 Q22 28 27 22 Q28 15 35 17 L37 12 L44 15 L50 12 L55 14 L61 13 L65 17 Q71 19 71 27 L70 38 L71 44 Q70 51 65 53 L60 47 L42 51 L35 54 Q27 54 26 43Z",
        "M26 38 L24 31 Q23 23 29 21 Q28 16 35 17 L38 13 L44 16 L50 12 L55 15 L62 14 L65 17 Q70 20 70 28 L67 37 L64 31 L61 29 L51 28 L46 31 L43 33 L38 36 L35 43 L30 46Z",
        "M29 24 L33 19 L37 19 L40 16 L45 19 L50 15 L55 18 L61 17 L65 21 L57 21 L53 20 L48 21 L44 21 L40 20 L36 22 L31 26Z"),
    "leader": ("#3a2929", "#5a3935", "#92594d",
        "M26 40 Q22 37 25 29 Q24 23 29 21 Q31 14 41 15 Q45 12 52 15 L57 12 L60 16 Q69 16 70 23 Q73 27 70 36 L71 43 L69 54 Q68 58 63 56 L60 48 L43 52 L34 60 Q25 60 27 51Z",
        "M26 39 L24 34 Q23 28 27 24 Q28 18 36 16 Q42 13 48 16 L56 13 L60 16 Q66 15 69 21 Q73 26 69 34 L66 36 L64 29 L59 26 Q55 25 51 27 Q47 32 43 33 L40 39 L36 40 L34 47 L32 54 L29 51 L30 42Z",
        "M31 25 Q34 18 40 18 Q45 18 48 20 L53 18 L57 16 L59 20 L63 19 L67 22 L64 23 L60 21 L56 21 L51 23 L47 24 Q41 20 35 25Z"),
}


def swatches(color, light, kind):
    """Closed role garments preserve the neutral torso and join under the arms."""
    front = path("M45 54 Q51 57 55 53 L59 56 L58 63 L60 68 Q55 71 42 70 L43 64 Q46 58 45 54Z", color)
    if kind in ("vest", "field"):
        return (front
                + path("M46 57 L50 58 L49 64 L45 66 L46 62Z", light, 0)
                + path("M51 65 L56 64 L56 67 L51 68Z", PLUM, 1.3)
                + ring("M55 57 L54 61", CREAM, 1.05))
    if kind == "padded":
        return (path("M39 57 Q43 52 47 54 L52 57 L56 53 Q62 53 63 59 L59 63 L61 71 L43 72 L41 65 L37 62Z", color)
                + path("M43 57 Q44 54 48 56 L50 60 L44 61Z", light, 0)
                + ring("M45 65 Q51 63 58 63 M44 68 Q51 66 58 66", PLUM, 1.1)
                + rect(52, 57, 5, 3, 0.8, SAND, 1))
    if kind == "poncho":
        return (path("M44 50 L47 51 Q51 54 55 51 L61 55 L61 61 L57 60 L60 69 Q55 71 44 71 L42 62 L38 63Z", color)
                + path("M45 52 Q50 55 56 53 L58 56 L52 60 L43 56Z", light, 1.2)
                + ring("M50 62 L53 68", CREAM, 0.95))
    if kind == "sash":
        return (front
                + path("M57 55 L60 57 Q52 64 43 69 L42 66 Q50 62 57 55Z", light, 1.15)
                + rect(47, 63, 5, 3.5, 0.8, AMBER, 1.15))
    if kind == "apron":
        return (path("M44 55 L48 54 Q51 57 55 54 L58 55 L58 62 L61 72 L41 73 L43 65Z", color)
                + path("M48 57 Q51 59 56 57 L55 64 L46 65Z", light, 0)
                + rect(47, 65, 9, 4, 0.9, PLUM, 1.3)
                + ring("M49 67 H53", AMBER, 1.05))
    if kind == "coat":
        return (path("M42 54 Q47 50 51 56 L56 51 Q61 53 62 58 L58 61 L62 75 L41 77 L42 65 L39 61Z", color)
                + path("M43 55 Q48 56 51 59 L48 62 L45 59 L42 58Z", light, 0)
                + path("M57 53 L59 57 L55 61 L53 59Z", light, 0)
                + ring("M51 60 L51 73", PLUM, 1.6)
                + circle(53.5, 63, 1.2, AMBER, 0.6))
    return front


def pack_shell(color, light, motif):
    outer = (path("M35 58 Q30 55 26 58 L25 65 L26 75 Q29 78 36 76 L40 71 L39 62Z", color)
             + path("M27 61 L32 59 L36 60 L35 64 L27 65Z", light, 0))
    if motif == "can":
        return (rect(26, 59, 11, 19, 3.5, color)
                + rect(27, 57, 9, 5, 1.5, STEEL)
                + path("M29 67 L35 66 L35 71 L29 72Z", light, 1)
                + ring("M30 74 H34", CREAM, 1.1))
    return outer + rect(28, 66, 7, 5, 0.8, light, 1) + ring("M30 68 H33", INK, 0.8)


def shield():
    return (path("M63 47 Q73 45 81 51 L81 71 Q78 80 69 84 Q60 81 57 73 L57 54 Q58 50 63 47Z", "#736558", 2.65)
            + path("M63 51 Q71 48 77 52 L77 70 Q75 75 70 78 Q64 76 61 71 L61 56Z", "#a29175", 0)
            + path("M66 51 Q69 50 72 50 L72 77 L69 79 L66 77Z", "#77634d", 0)
            + ring("M61 53 L63 51 M78 67 V71 Q76 76 73 78", CREAM, 1.05)
            + circle(70, 54, 1.28, AMBER) + circle(69, 74, 1.25, AMBER)
            + path("M58 62 L63 62 L64 72 L59 75Z", "#5b4a3e", 1.3))


def rifle():
    return (path("M45 65 L54 60 L67 60 L77 53 L85 53 L86 57 L76 61 L66 66 L60 66 L57 71 L52 71 L53 66 L46 69Z", "#50443c", 2.35)
            + path("M59 63L64 63L64 68L62 71L58 71L58 67Z", "#5d4a3d", 1.7)
            + path("M47 65 L54 61 L63 61 L64 64 L55 65 L48 67Z", "#946c50", 0)
            + rect(62, 57, 7, 3, 1, "#957f66", 1.35)
            + ring("M69 61 L76 56 H82", CREAM, 0.9))


def jammer():
    return (path("M18 47 Q20 43 26 44 L38 47 L39 53 L38 69 L33 76 L18 74 L16 70 L16 52Z", "#5b5142", 2.5)
            + path("M20 48 Q24 46 32 48 L32 59 L20 58Z", "#a78e66", 0)
            + rect(20, 61, 13, 9, 1.5, "#985541", 1.65)
            + circle(23.5, 65, 1.55, AMBER)
            + ring("M28 65 H31 M28 67 H31", CREAM, 1.0))


def antenna():
    return path("M21 49 L21 34 Q21 32 23 32 Q25 32 25 34 L25 49Z", STEEL, 1.7) + circle(23, 33, 2.25, RED)


def net():
    return (path("M58 66 Q64 62 70 59 L74 61 L65 68 L60 72 L56 71Z", "#745643", 1.9)
            + path("M69 56 Q71 50 77 51 Q82 51 86 56 L85 64 Q81 70 74 66 L68 62Z", "#9c8660", 2.15)
            + ring("M71 57 L82 64 M73 53 L85 59 M69 60 L79 67 M75 52 L71 63 M79 52 L75 66 M84 55 L79 67", CREAM, 1.0)
            + ring("M70 54 Q76 50 82 53 Q88 57 85 63 Q82 68 76 67 L70 63Z", "#5b4430", 1.6))


def charge():
    return (rect(53, 56, 22, 24, 3.3, "#98544a", 2.5)
            + path("M55 61 L72 57 L73 61 L56 66Z", AMBER, 1.0)
            + rect(56, 69, 16, 7, 0.8, "#67453a", 1.1)
            + circle(59, 73, 1.4, "#d6bb91")
            + circle(68.5, 73, 1.4, "#d6bb91"))


def mortar_base():
    return (path("M52 70 L65 68 L71 69 L80 81 L76 84 L70 76 L66 76 L61 84 L56 82 L61 74 L53 76Z", "#796954", 2.45)
            + path("M46 63L53 63L62 69L60 73L54 72L49 69L46 69Z", "#73614e", 1.6)
            + path("M63 68 L71 67 L74 71 L70 75 L63 74Z", "#9a7955", 1.8))


def mortar_tube():
    return (path("M63 73 L64 65 L77 45 L84 46 L87 51 L73 72 L68 75Z", "#696455", 2.65)
            + path("M67 65 L80 47 L84 49 L73 66Z", "#ad9777", 0)
            + path("M77 45 L81 43 L87 46 L89 50 L86 53 L80 51Z", "#71614d", 1.9)
            + ring("M81 46 L85 48", INK, 1.2)
            + path("M68 62 L75 63 L74 67 L65 66Z", "#964d3f", 1.6))


def ram():
    return (path("M34 65 Q45 63 58 63 L69 59 L82 61 L84 65 L81 71 L70 73 L58 70 L41 72 L35 70Z", "#70594a", 2.3)
            + path("M34 65 L46 64 L48 69 L40 72 L34 70 L32 68Z", "#9a7b5b", 1.7)
            + path("M70 60 L81 62 L83 65 L80 70 L70 72 L68 69 L68 63Z", "#b29b7d", 1.8)
            + ring("M73 63 L80 64 M72 69 L78 68", CREAM, 1.05))


def heat_pack():
    return (path("M24 49 Q27 46 32 48 L38 52 L39 74 Q36 78 29 76 L23 73 L21 56Z", "#9d4f38", 2.25)
            + path("M24 53 Q26 51 30 52 L33 55 L32 69 L25 70Z", "#c67a50", 0)
            + rect(26, 44, 9, 6, 1.4, "#947250", 1.7)
            + path("M26 63 L30 56 L35 63 L32 68 L27 67Z", AMBER, 1.1)
            + ring("M29 62 L31 62 L29 65", PLUM, 0.95))


def heat_wand():
    return (path("M54 65 L60 61 L72 58 L77 59 L77 63 L67 64 L61 68 L60 72 L56 72Z", "#5d5144", 2.1)
            + path("M59 64L64 63L64 69L62 72L58 71L58 67Z", "#655345", 1.6)
            + path("M69 58 L75 57 L79 57 L80 63 L74 64 L70 63Z", "#b99662", 1.5)
            + ring("M58 65 L68 61", "#824b37", 1.6))


def trade_case():
    return (path("M66 56 L72 55 L83 59 L85 63 L85 79 L76 83 L57 80 L55 76 L56 62Z", "#857055", 2.5)
            + path("M59 63 L74 63 L74 79 L58 78Z", "#af9068", 0)
            + path("M76 64 L82 61 L82 77 L77 79Z", "#614a3b", 0)
            + ring("M62 66 H72 M62 69 H72 M62 72 H72", INK, 1.15)
            + rect(62, 75, 8, 4, 0.8, "#b76048", 1.0)
            + ring("M63 57 L64 53 Q69 52 72 54 L72 57", "#614a3b", 2.0))


def cape():
    return (path("M48 50 Q56 48 59 55 L53 66 L50 77 Q43 86 33 84 L19 78 Q25 76 30 65 Q35 59 40 54Z", "#8a4539", 2.75)
            + path("M27 78 Q30 68 38 62 L48 55 Q40 70 37 78 L35 81Z", "#b86d53", 0)
            + ring("M24 78 Q36 83 46 79", SAND, 1.25))


def captain_radio():
    return (rect(56, 57, 12, 16, 2.2, "#5a5145", 2.05)
            + rect(58, 60, 7.5, 5, 0.75, AMBER, 1.15)
            + ring("M65 58 L67 50", INK, 2.1)
            + ring("M59 68 H64 M59 70 H63", CREAM, 0.9))


def foreman_pack():
    return (path("M24 44 L37 43 Q42 45 43 52 L43 75 L35 82 L21 78 L18 71 L18 54Q18 48 24 44Z", "#845846", 2.7)
            + path("M24 49 L32 47 L36 49 L35 68 L22 70 L22 55Z", "#b97850", 0)
            + rect(23, 62, 15, 10, 1.6, "#594b42", 1.6)
            + path("M27 70 L31 63 L34 69Z", AMBER, 0.8)
            + ring("M27 78 L25 74 M36 75 L39 70", CREAM, 1.1))


def foreman_hinge():
    return (rect(23, 39, 10, 15, 2.5, "#6b5750", 2.2)
            + rect(24, 40, 8, 4, 1.1, AMBER, 1.25)
            + ring("M27 47 V52", CREAM, 1.0))


def leader_coat():
    return (path("M45 53L56 49L63 56 L62 67 L67 83 Q59 88 51 83 L47 74 L42 83 Q37 86 28 84 L34 67 L34 59Z", "#68362f", 2.55)
            + path("M42 56 L51 55 L47 72 L38 82 L34 82 L41 65Z", "#9f5040", 0)
            + ring("M31 83 L40 82 L46 76 M54 82 Q60 84 64 82", AMBER, 1.35))


def leader_buckle():
    return (path("M58 59 L65 59 L71 64 L71 70 L65 74 L57 72 L55 67Z", "#613b34", 2.25)
            + path("M61 62 L66 62 L68 66 L65 70 L60 69 L59 65Z", AMBER, 1.45)
            + ring("M61 66 L64 67 L66 64", INK, 1.1))


def part(name, label, parent, pivot, data, before=None):
    return {"id": name, "label": label, "parent": parent, "pivot_canvas_units": list(pivot),
            "svg": data, "before": before}


def mounted(name, label, data, socket=FAR_PALM, parent="hand_far"):
    return part(name, label, parent, socket, data, "hand_far" if parent == "hand_far" else "hand_near")


def sling(mode):
    if mode == "runner":
        return part("runner_wrap", "Folded runner neck wrap", "torso", [49.125, 54.625],
                    path("M43 52 Q49 54 54 52 L57 55 L53 59 L47 57 L41 59 L35 60 L33 56 L39 55Z", "#9b483c", 1.9)
                    + ring("M44 55 L48 55 L52 56", "#bd7a55", 1.1),
                    "upper_arm_near")
    return part("smoke_collar", "Smoke scarf", "torso", [49.5, 54.5],
                path("M42 50 Q49 53 56 50 L61 53 L58 58 Q53 60 49 58 L42 56Z", "#807465", 1.9)
                + ring("M46 54 Q52 56 56 53", "#c0a384", 1.0), "head")


def hip(name, label, data):
    return part(name, label, "torso", LEFT_HIP, data, "forearm_near")


def back(name, label, data):
    return part(name, label, "torso", LEFT_HIP, data, "torso")


# Wardrobe choices and props are all at the same W27 size except the intentionally
# larger boss silhouette pieces. Weapon shapes are illustrative game cues.
HUMANOIDS = {
    "enemies/e03": ("Contraband Runner", "trail_crest", ("#984c3a", "#bc7956", "vest"),
        "#9a7754", [hip("runner_sling", "Slim field sling", pack_shell("#9a7650", SAND, "bag")), sling("runner")],
        "Sprint", "Existing Sprint ability is active.", "runner_wrap", (-14, 8)),
    "enemies/e04": ("Shield Carrier", "block_crop", ("#825549", "#ba8f6f", "padded"),
        "#8c6b58", [mounted("shield", "Wood-and-metal carry shield", shield())],
        None, None, None, None),
    "enemies/e05": ("Rifle Spotter", "slick_back", ("#845342", "#b98e65", "sash"),
        "#9f785c", [mounted("rifle", "Illustrated spotting rifle", rifle())],
        None, None, None, None),
    "enemies/e06": ("Smoke Infiltrator", "ash_part", ("#625750", "#90574b", "poncho"),
        "#77675c", [hip("canister", "Smoke canister", pack_shell("#815049", SAND, "can")), sling("smoke")],
        "Conceal", "Existing smoke concealment starts.", "canister", (-8, 0)),
    "enemies/e07": ("Signal Jammer", "tight_curls", ("#7e4b3c", "#ba8665", "vest"),
        "#948059", [back("jammer_pack", "Jammer pack housing", jammer()),
                    part("mast", "Articulated jammer antenna", "jammer_pack", [22.875, 47.625], antenna(), "torso")],
        "Jam", "Existing jammer warning or pulse.", "mast", (-14, 0)),
    "enemies/e10": ("Net Trapper", "tied_tail", ("#73594b", "#aa5d47", "sash"),
        "#ac8a5a", [mounted("net_frame", "Laced throwing net", net())],
        "Cast", "Existing entanglement cast or warning.", "net_frame", (-26, 10)),
    "enemies/e11": ("Demolitionist", "high_crop", ("#6f5043", "#b6664c", "apron"),
        "#9d725a", [mounted("charge_case", "Siege charge case", charge())],
        "Windup", "Existing Siege warning begins.", "charge_case", (-10, 0)),
    "enemies/e12": ("Portable Mortar Crew", "brushed_fringe", ("#695b49", "#ab7053", "vest"),
        "#8c805c", [part("mortar_mount", "Folded mortar support", "torso", TOR, mortar_base()),
                     part("mortar_tube", "Articulated mortar tube", "mortar_mount", [68, 71], mortar_tube())],
        "Windup", "Existing delayed Siege warning begins.", "mortar_tube", (-18, 8)),
    "enemies/e13": ("Heavy Breacher", "short_crest", ("#724237", "#aa6e54", "padded"),
        "#8f6a54", [mounted("breach_ram", "Reinforced breaching ram", ram(), NEAR_PALM, "hand_near")],
        "Breach", "Existing knockdown windup or hit.", "breach_ram", (-19, 12)),
    "enemies/e14": ("Ignition Operator", "operator_crop", ("#7e4738", "#bb7a4e", "apron"),
        "#a67857", [back("heat_pack", "Heat equipment cylinder", heat_pack()),
                    mounted("heat_wand", "Handheld heat-source silhouette", heat_wand())],
        "Heat", "Existing eligible Heat presentation cue.", "heat_wand", (-15, 6)),
    "enemies/e15": ("Wildlife Trafficker", "oiled_wave", ("#753b36", "#a86650", "coat"),
        "#8b695a", [mounted("trade_case", "Vented transport case", trade_case())],
        None, None, None, None),
    "bosses/diversion_captain": ("Diversion Captain", "captain", ("#9b4a37", "#c47c58", "coat"),
        "#ae7557", [back("captain_cape", "Broad command cape", cape()),
                    mounted("captain_radio", "Command radio", captain_radio())],
        "Rally", "Existing reinforcement call or aura presentation.", "captain_cape", (-12, 4)),
    "bosses/illegal_logging_foreman": ("Illegal Logging Foreman", "foreman", ("#7a4d37", "#be8554", "apron"),
        "#a88b58", [back("heat_rig", "Industrial Heat rig", foreman_pack()),
                    part("relief_stack", "Heat rig relief stack", "heat_rig", [28, 51], foreman_hinge(), "torso")],
        "Overheat", "Existing temporary protection and Heat phase presentation.", "relief_stack", (-9, 7)),
    "bosses/poacher_leader": ("Poacher Leader", "leader", ("#9a4e3d", "#b77f59", "coat"),
        "#886358", [back("leader_coat", "Long red operations coat", leader_coat()),
                    mounted("guard_cuff", "Brass command cuff", leader_buckle())],
        "Surge", "Existing late-phase speed surge.", "leader_coat", (-11, 10)),
}


MACHINES = {
    "enemies/e08": ("Recon Drone", [48, 84], [
        part("arm_far", "Far rotor arm", "torso", [55, 40],
             path("M52 37 L74 29 L77 33 L77 38 L55 44 L51 41Z", "#9a8063", 2.3)),
        part("rotor_far", "Far rotor and hub", "arm_far", [75, 34],
             path("M71 29 L75 27 L80 28 L82 32 L78 38 L73 39 L70 34Z", "#78594b", 2.1)
             + path("M75 31 Q84 27 93 28 L93 32 L78 34 L62 36 L60 34Z", "#bfaa8a", 1.4)
             + circle(75, 33, 2.5, RED)),
        part("arm_near", "Near rotor arm", "torso", [42, 40],
             path("M42 37 L23 31 L21 34 L24 40 L43 45 L46 42Z", "#ac8967", 2.4)),
        part("rotor_near", "Near rotor and hub", "arm_near", [24, 36],
             path("M22 31 L26 31 L29 35 L27 39 L23 41 L19 38 L19 34Z", "#78594b", 2.1)
             + path("M23 33 Q29 30 42 31 L43 34 L27 37 L9 39 L7 36Z", "#bfaa8a", 1.4)
             + circle(24, 35, 2.6, RED)),
        part("torso", "Brick-red drone casing", None, [48, 45],
             path("M38 32 Q45 29 53 33 L61 36 Q65 40 62 50 L57 57 Q48 62 39 57 L34 51 L34 42Z", "#a55541", 2.65)
             + path("M38 35 Q46 32 54 35 L57 38 Q48 37 39 41Z", "#ca8061", 0)
             + path("M42 53 L50 53 L55 57 L49 60 L42 57Z", "#6a5143", 1.85)),
        part("gimbal", "Attached camera gimbal", "torso", [53, 47],
             path("M51 41 Q57 38 62 42 Q67 45 65 51 L62 56 L55 56 L50 52 L49 46Z", "#ac9577", 2.15)
             + circle(60, 48, 4.4, "#594a40", 1.6)
             + circle(61, 47, 1.85, AMBER, 0.5)),
    ]),
    "enemies/e09": ("Tracking Bot", [48, 84], [
        part("tread_far", "Far tread", "torso", [56, 72],
             path("M55 65 L71 65 L76 72 L74 81 L68 83 L55 82 L51 79 L51 71Z", "#574a40", 2.5)
             + ring("M57 70 L69 70 L72 73 L71 78 L57 78", "#957e62", 1.4)),
        part("torso", "Low brick-red crawler chassis", None, [48, 69],
             path("M24 65 L31 57 Q43 53 56 55 L67 61 L70 70 L63 76 L28 75Z", "#9d5241", 2.65)
             + path("M34 59 Q44 56 54 58 L58 61 L31 65Z", "#c78561", 0)
             + path("M57 62 L64 63 L65 68 L59 71 L55 68Z", SAND, 1.35)),
        part("tread_near", "Near tread", "torso", [37, 72],
             path("M26 68 L47 68 Q52 69 55 74 L54 80 L50 83 L26 83 L21 79 L21 74Z", "#4d4038", 2.5)
             + path("M27 72 L47 72 L51 75 L49 79 L27 79 L24 76Z", "#776450", 1.3)
             + "".join(circle(x, 76, 2.1, "#ae906d", 1.0) for x in [29, 37, 45])),
        part("sensor_arm", "Rotating sensor arm", "torso", [48, 61],
             path("M44 62 L44 50 L45 45 L52 45 L53 60 L50 64Z", "#ab8b64", 2.1)
             + rect(46, 53, 4.5, 4.5, 0.8, RED, 0.9)),
        part("sensor", "Tracking sensor housing", "sensor_arm", [48, 49],
             path("M40 40 Q41 34 46 34 L59 35 Q66 37 66 43 L63 50 L56 53 L42 52 L39 47Z", "#815344", 2.6)
             + rect(48, 39, 15, 8, 2.0, "#512f29", 1.6)
             + circle(57, 43, 2.0, AMBER, 0.5)
             + ring("M43 39 L45 38", CREAM, 1.0)),
    ]),
}


def set_attr(root, name, **attributes):
    node = root.find(f".//*[@id='{name}']")
    node.attrib.update(attributes)


def author_head(layer, style, boss):
    shade, color, light, back_path, fringe, shine = HAIR[style]
    face = copy.deepcopy(layer.find(f"*[@id='face_underpaint']"))
    eyes = copy.deepcopy(layer.find(tag("use")))
    layer[:] = []
    layer.set(f"{{{INKSCAPE}}}label", "Bare head, original mouthless face")
    artwork = xml(path(back_path, shade, 2.8))
    layer.extend(artwork)
    layer.append(face)
    layer.append(eyes)
    layer.extend(xml(path(fringe, color, 2.5) + path(shine, light, 0)))
    if style == "operator_crop":
        layer.extend(xml(path("M38 38 Q45 36 50 38 L50 43 L46 45 L42 44Z", "#957452", 1.1)
                         + path("M52 38 Q57 35 62 38 L62 43 L57 44 L53 43Z", "#a78554", 1.1)
                         + ring("M50 39 H53", INK, 1.25)
                         + ring("M43 39 L46 39 M56 38.5 L59 38.5", CREAM, 0.9)))
    if style == "foreman":
        layer.extend(xml(path("M37 31 Q46 29 52 30 L53 35 L49 37 L43 37 L38 36Z", "#a67c50", 1.65)
                         + path("M54 31 Q61 29 65 31 L66 35 L60 37 L55 36Z", "#957046", 1.6)
                         + ring("M45 33 L48 32 M59 33 L62 32", CREAM, 1.1)))
    if boss:
        # Widen only the visual around the existing neck joint. It does not
        # alter a pose key, HP marker, movement anchor or game footprint.
        eye_line = 48.125
        scale = 1.1 if style == "leader" else 1.15
        layer.set("transform", f"translate({eye_line} 0) scale({scale} 1) translate({-eye_line} 0)")


def author_body(layer, outfit):
    equip = layer.find(f"*[@id='wardrobe_vest']")
    layer.remove(equip)
    changed = xml(swatches(*outfit))
    changed.set("id", "wardrobe")
    layer.append(changed)
    layer.set(f"{{{INKSCAPE}}}label", "Layered role garment")


def full_input(unit, file):
    return ROOT / "assets/source-art" / unit / file


def base_id(unit):
    if unit.startswith("enemies/"):
        return unit.split("/")[-1].upper()
    return "boss." + unit.split("/")[-1]


def dump(path, record):
    path.write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n")


def kit_manifest(unit, label):
    base = json.loads((E02 / "manifest.json").read_text())
    for key in ("art_bounds_units", "measured_visible_height_units", "neutral_rgba_reassembly_max_delta", "source_sha256"):
        base.pop(key, None)
    base.update(
        asset_version="0.1.0", enemy_id=base_id(unit), display_name=label,
        status="W29 production cutout candidate; isolated import verified separately",
        source_svg=f"assets/source-art/{unit}/{unit.split('/')[-1]}.svg",
        animation_contract=f"assets/source-art/{unit}/animation_contract.json",
        sockets={}, parts=[],
        provenance={
            "creator": "Kenyalang Rangers W29 production art",
            "source": "Original role-specific clothing, hair and equipment registered to the approved Forest Trespasser and Poacher art. Machines use new equivalent ink and palette.",
            "base_manifest": "assets/source-art/enemies/e02/manifest.json",
            "base_source_sha256": sha256(E02 / "e02.svg"),
            "review": "Owner directed this body style. These new role designs await live visual acceptance and D-014 release clearance.",
            "visual_references": [
                "W27 approved E01/E02 actual art pivots and alpha sheets",
                "GDD §§ H.2–3, M.4, M.7 and retained data definitions",
                "UI storyboard pp. 19, 30–31; enemy card and field scale",
            ],
        },
        derived_badge={
            "path": f"assets/imported/{unit}/field_badge.png", "dimensions_px": [96, 96],
            "baseline_px": 90, "max_content_px": [82, 82],
            "source": "Reassembled neutral pose in declared draw order. Alpha trim then fit, centre x, ground baseline.",
        },
    )
    return base


def new_layer(props):
    group = xml(props["svg"])
    group.set("id", "part_" + props["id"])
    group.set(f"{{{INKSCAPE}}}groupmode", "layer")
    group.set(f"{{{INKSCAPE}}}label", props["label"])
    return group


def record_part(unit, props, order):
    id = props["id"]
    return {
        "id": id, "label": props["label"], "svg_layer_id": "part_" + id,
        "parent": props["parent"], "draw_order": order,
        "pivot_canvas_units": props["pivot_canvas_units"],
        "png": props.get("png", f"assets/imported/{unit}/{id}.png"),
    }


def accessory_points(manifest, unit):
    for part_data in manifest["parts"]:
        parent = part_data["parent"]
        id = part_data["id"]
        if parent is not None and id not in BASE_PARTS:
            manifest["sockets"][f"{id}_mount"] = {
                "part": parent, "canvas_units": part_data["pivot_canvas_units"],
            }

    accents = {
        "enemies/e05": ("rifle", [85, 55]), "enemies/e06": ("canister", [32, 57]),
        "enemies/e07": ("mast", [23, 33]), "enemies/e08": ("gimbal", [60, 48]),
        "enemies/e09": ("sensor", [58, 43]), "enemies/e10": ("net_frame", [78, 59]),
        "enemies/e11": ("charge_case", [66, 65]), "enemies/e12": ("mortar_tube", [85, 48]),
        "enemies/e13": ("breach_ram", [81, 65]), "enemies/e14": ("heat_wand", [79, 60]),
        "bosses/diversion_captain": ("captain_radio", [67, 50]),
        "bosses/illegal_logging_foreman": ("relief_stack", [28, 41]),
        "bosses/poacher_leader": ("guard_cuff", [65, 66]),
    }
    target, xy = accents.get(unit, ("hand_near", [36.807, 69.804]))
    manifest["sockets"]["attack_fx"] = {"part": target, "canvas_units": xy}


BASE_PARTS = {p["id"]: p for p in json.loads((E02 / "manifest.json").read_text())["parts"]}


def author_human(unit):
    name, hair, outfit, sleeve, additions, _, _, _, _ = HUMANOIDS[unit]
    root = ET.parse(E02 / "e02.svg").getroot()
    root.find(tag("title")).text = name
    root.find(tag("desc")).text = "Editable cutout art derived from the approved E02 anatomy and W27 pivots."
    image = root.find(".//*[@id='study_base']")
    image.set(f"{{{XLINK}}}href", os.path.relpath(ROOT / "assets/source-art/enemies/e01/study_reference.png",
                                                full_input(unit, "manifest.json").parent))
    parts = list(BASE_PARTS)
    parts.remove("satchel")
    root.remove(root.find("./*[@id='part_satchel']"))
    data = dict(BASE_PARTS)
    for addition in additions:
        pos = parts.index(addition["before"]) if addition["before"] else len(parts)
        parts.insert(pos, addition["id"])
        root.insert(pos + 3, new_layer(addition))
        data[addition["id"]] = addition
    # Protect the exact approved legs, fists, forearms and boots. Clothing
    # underpaint uses the same masks and controlled colour changes.
    author_head(root.find("./*[@id='part_head']"), hair, unit.startswith("bosses/"))
    author_body(root.find("./*[@id='part_torso']"), outfit)
    for side in ("near", "far"):
        node = root.find(f"./*[@id='part_upper_arm_{side}']")
        hidden = node.find(f"*[@id='hidden_upper_arm_{side}']")
        hidden.set("fill", sleeve)
        node.find(tag("use")).set("filter", "url(#sleeve_palette)")
    old_rgb = [178, 136, 90]
    new_rgb = [int(sleeve[x:x+2], 16) for x in (1, 3, 5)]
    factors = [round(wanted/present, 3) for wanted, present in zip(new_rgb, old_rgb)]
    matrix = f"{factors[0]} 0 0 0 0 0 {factors[1]} 0 0 0 0 0 {factors[2]} 0 0 0 0 0 1 0"
    filt = xml(f'<filter id="sleeve_palette" filterUnits="userSpaceOnUse" x="0" y="0" width="96" height="96" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="{matrix}"/></filter>')[0]
    root.find(tag("defs")).append(filt)
    record = kit_manifest(unit, name)
    for index, name in enumerate(parts, 1):
        props = data[name].copy()
        if name in ("head", "torso", "upper_arm_near", "upper_arm_far"):
            props.pop("png", None)
            props["label"] = root.find(f"./*[@id='part_{name}']").get(f"{{{INKSCAPE}}}label")
        record["parts"].append(record_part(unit, props, index))
    accessory_points(record, unit)
    record["provenance"]["linked_study"] = "assets/source-art/enemies/e01/study_reference.png"
    record["provenance"]["linked_study_sha256"] = sha256(ROOT / record["provenance"]["linked_study"])
    record["target_visible_height_units"] = 76 if unit.startswith("bosses/") else 67.25
    return root, record


def author_machine(unit):
    name, anchor, parts = MACHINES[unit]
    root = ET.Element(tag("svg"), {"viewBox": "0 0 96 96", "width": "384", "height": "384"})
    ET.SubElement(root, tag("title")).text = name
    for item in parts:
        root.append(new_layer(item))
    record = kit_manifest(unit, name)
    record["ground_anchor_units"] = anchor
    record["parts"] = [record_part(unit, props, index) for index, props in enumerate(parts, 1)]
    record["target_visible_height_units"] = 35 if unit.endswith("e08") else 50
    if unit.endswith("e08"):
        record["presentation_anchor"] = "The rig floats above the combat anchor. Add a separate shadow at ground contact if used."
    accessory_points(record, unit)
    return root, record


def keys(*frames):
    return [[t, dy, pose] for t, dy, pose in frames]


def clip(event, frames, playback="return", follow="Move", blocked="Blocked"):
    result = {"event": event, "playback": playback, "keys": frames}
    if playback == "return":
        result.update(next=follow, return_if_blocking=blocked)
    return result


def machine_animation(unit, contract):
    if unit.endswith("e08"):
        parts = ["arm_far", "rotor_far", "arm_near", "rotor_near", "gimbal"]
        lean = dict(zip(parts, [-4, 8, 3, -7, 6]))
        opposite = {k: -v for k, v in lean.items()}
        peak = {"gimbal": 14, "arm_far": -6, "arm_near": 7}
    else:
        lean = {"sensor_arm": -6, "sensor": 10, "tread_near": -2, "tread_far": 2}
        opposite = {k: -v for k, v in lean.items()}
        peak = {"sensor_arm": 9, "sensor": -16}
    return {
        "Move": clip("Existing route motion; the art stays on its anchor.",
                     keys((0, 0, lean), (0.28, -2, opposite), (0.56, 0, lean)), "loop"),
        "Blocked": clip("Optional actor pause; Recon Drone never uses a grounded blocker.",
                        keys((0, 0, {}), (0.28, -1, lean), (0.56, 0, {})), "loop"),
        "Attack": clip("Existing ranged attack cue.", keys((0, 0, {}), (0.16, 0, peak), (0.40, 0, {}))),
        "Hit": clip("Existing nonterminal damage cue.", keys((0, 0, {}), (0.09, 1, opposite), (0.24, 0, {}))),
        "Defeat": clip("Existing removal cue.", keys((0, 0, {}), (0.28, 4, peak)), "hold"),
        "Exit": clip("Existing tunnel escape cue.", keys((0, 0, {}), (0.24, 0, lean)), "hold"),
    }


def author_animation(unit):
    contract = json.loads((E02 / "animation_contract.json").read_text())
    contract["asset_id"] = base_id(unit)
    contract["status"] = "W29 art-only keys mapped to existing combat cues."
    if unit in MACHINES:
        contract["states"] = machine_animation(unit, contract)
        if unit.endswith("e09"):
            contract["states"]["Mark"] = clip("Existing tracking debuff pulse.",
                keys((0, 0, {}), (0.18, 0, {"sensor": -14, "sensor_arm": 10}), (0.42, 0, {})))
        return contract
    _, _, _, _, additions, state, event, prop, angles = HUMANOIDS[unit]
    ranged_id = {"enemies/e05": "rifle", "enemies/e07": "mast", "enemies/e10": "net_frame",
                 "enemies/e11": "charge_case", "enemies/e12": "mortar_tube", "enemies/e14": "heat_wand"}
    if unit in ranged_id:
        role_prop = ranged_id[unit]
        contract["states"]["Attack"] = clip("Existing ranged, Heat or Siege presentation cue for this actor.",
            keys((0, 0, {}), (0.13, 0, {"head": -4, "upper_arm_far": -12, role_prop: -16}),
                 (0.21, 1, {"head": 5, "upper_arm_far": -5, role_prop: 5}), (0.44, 0, {})))
        contract["states"]["Attack"]["accent"] = {"socket": "attack_fx", "preview_seconds": 0.13}
    if state is not None:
        posture = {prop: angles[0], "head": -7}
        recoil = {prop: angles[1], "head": 3}
        if state in ("Sprint", "Surge"):
            posture.update(thigh_near=-25, shin_near=13, thigh_far=21, upper_arm_near=15)
            recoil.update(thigh_near=18, thigh_far=-25, shin_far=13, upper_arm_near=-15)
            contract["states"][state] = clip(event, keys((0, 0, posture), (0.19, -1, recoil), (0.38, 0, posture)), "loop")
        else:
            contract["states"][state] = clip(event,
                keys((0, 0, {}), (0.2, -1, posture), (0.34, 0, recoil), (0.6, 0, {})))
    if unit == "bosses/diversion_captain":
        contract["states"]["Captured"] = clip("Existing nonlethal capture presentation after defeat.",
            keys((0, 0, {}), (0.36, 1, {"head": 12, "captain_cape": 8, "upper_arm_far": 18})), "hold")
    return contract


def definitions(unit):
    family, slug = unit.split("/")
    files = sorted((ROOT / "data" / family).glob(f"{slug}*.tres"))
    assert len(files) == 1, files
    return files[0]


def author(unit):
    root, record = author_machine(unit) if unit in MACHINES else author_human(unit)
    source_dir = full_input(unit, "manifest.json").parent
    source_dir.mkdir(parents=True, exist_ok=True)
    (source_dir / ".gdignore").touch()
    path = ROOT / record["source_svg"]
    ET.indent(root, "  ")
    ET.ElementTree(root).write(path, encoding="utf-8", xml_declaration=False)
    with path.open("a") as out:
        out.write("\n")
    data = definitions(unit)
    assert re.search(r'display_name = "' + re.escape(record["display_name"]) + r'"', data.read_text()), unit
    record["provenance"]["definition"] = str(data.relative_to(ROOT))
    dump(source_dir / "manifest.json", record)
    dump(source_dir / "animation_contract.json", author_animation(unit))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--unit", action="append")
    args = parser.parse_args()
    for unit in args.unit or sorted(set(HUMANOIDS) | set(MACHINES)):
        if args.write:
            author(unit)
        with tempfile.TemporaryDirectory(prefix="w29-foes-") as scratch:
            export_unit(unit, Path(scratch), args.write)


if __name__ == "__main__":
    main()
