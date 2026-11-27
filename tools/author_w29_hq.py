#!/usr/bin/env python3
"""Author and export Headquarters layers, stationary work loops, and review plates."""
from __future__ import annotations

from base64 import b64encode
from dataclasses import dataclass
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import random
import re
from subprocess import run
from tempfile import TemporaryDirectory
from xml.sax.saxutils import escape

from PIL import Image, ImageDraw, ImageFont
from build_cutout_scene import generate as build_cutout

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source-art/hq"
RECEPTION_EMBLEM = SOURCE.parent / "ui/w29/brand/hornbill_dark.svg"
IMPORT = ROOT / "assets/imported/hq"
REVIEW = ROOT / "docs/production/w29/hq"
ROOM_W, ROOM_H = 314, 105
BOARD_W, BOARD_H = 1280, 720
ORIGIN = (150, 151)
STEP = (326, 116)
ART_UNIT_SCALE = 0.96

INK = "#34332a"
ACTOR_INK = "#30261f"
LIGHT_INK = "#69624f"
GOLD = "#daad5b"
CREAM = "#f5e6c8"
TAN = "#c4a37a"
WOOD = "#a37b55"
FOLIAGE = "#6f844e"
TEAL = "#568883"
DEEP_TEAL = "#395c59"
METAL = "#8d9b8e"
PAPER = "#eae0c7"


@dataclass(frozen=True)
class Staff:
    job: str
    hair: str
    outfit: str
    cuff: str
    skin: str
    feature: str
    action: str
    period: float
    head_primary: float
    arm_primary: float


@dataclass(frozen=True)
class Room:
    key: str
    label: str
    page: str
    accent: str
    person: Staff
    anchor: tuple[int, int]


ROOMS = (
    Room("control_room", "Control Room", "H01", "#829889",
         Staff("Operations officer", "bob", "#697959", "#a8af77", "#f3c49e", "radio headset", "Checks the console", 3.4, -5, -11), (220, 98)),
    Room("human_resources", "Human Resources", "H02", "#a1938f",
         Staff("Personnel clerk", "bun", "#8e726f", "#c5a799", "#dda77f", "glasses", "Reviews a form", 3.9, 6, -8), (212, 98)),
    Room("finance_room", "Finance Room", "H03", "#8e9c81",
         Staff("Finance officer", "part", "#677a69", "#c1c8ab", "#f2c198", "glasses", "Taps the calculator", 2.8, 3, 13), (200, 98)),
    Room("mechanical", "Mechanical", "H04", "#a58f6d",
         Staff("Workshop mechanic", "part", "#6f837c", "#8f9f83", "#dba578", "work goggles", "Turns a wrench", 2.9, -4, 17), (91, 101)),
    Room("ecology", "Ecology", "H05", "#a1a778",
         Staff("Nursery technician", "part", "#9b8960", "#c1a779", "#e6b588", "field hat", "Tends a seedling", 4.4, 5, -18), (84, 97)),
    Room("outreach", "Outreach", "H06", "#b1937a",
         Staff("Outreach producer", "bob", "#a37465", "#c39b7d", "#f0c19a", "radio headset", "Adjusts the microphone", 3.8, -5, -14), (169, 100)),
    Room("records", "Records", "H07", "#a4967c",
         Staff("Archivist", "bun", "#8f8668", "#c4ab86", "#d9a179", "glasses", "Moves a reference page", 4.6, 7, 11), (178, 99)),
    Room("r_d_eco", "R&D Eco", "H08", "#91a284",
         Staff("Seed researcher", "bob", "#92a28c", "#c0cead", "#f0bd94", "safety glasses", "Adjusts the microscope", 3.9, 6, -9), (104, 100)),
    Room("r_d_combat", "R&D Combat", "H09", "#afa27b",
         Staff("Equipment engineer", "part", "#767c5c", "#a9a779", "#d9a47b", "work goggles", "Checks the line reel", 3.1, -4, 16), (182, 101)),
    Room("r_d_guard", "R&D Guard", "H10", "#84988c",
         Staff("Equipment tester", "part", "#718471", "#a7b792", "#f0be92", "patrol cap", "Inspects a shield fitting", 3.5, 4, -10), (195, 100)),
    Room("r_d_crisis", "R&D Crisis", "H11", "#80969a",
         Staff("Response coordinator", "bob", "#667d7f", "#99aea4", "#dfae86", "radio headset", "Checks the radio", 3.2, -5, -15), (163, 100)),
)


def fmt(value: float) -> str:
    return f"{value:.3f}".rstrip("0").rstrip(".")


def rect(x, y, width, height, fill, stroke=None, sw=1.45, radius=0) -> str:
    edge = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return f'<rect x="{x}" y="{y}" width="{width}" height="{height}" rx="{radius}" fill="{fill}"{edge}/>'


def ellipse(x, y, rx, ry, fill, stroke=None, sw=1.45) -> str:
    edge = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}"{edge}/>'


def path(d, fill, stroke=None, sw=1.45) -> str:
    edge = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return f'<path d="{d}" fill="{fill}"{edge}/>'


def polygon(points, fill, stroke=None, sw=1.45) -> str:
    points_text = " ".join(f"{x},{y}" for x, y in points)
    edge = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return f'<polygon points="{points_text}" fill="{fill}"{edge}/>'


def line(x1, y1, x2, y2, stroke=INK, sw=1.45) -> str:
    return path(f"M{x1} {y1}L{x2} {y2}", "none", stroke, sw)


def stack(*items: str) -> str:
    return "\n".join(items)


def place(x: float, y: float, art: str, scale: float = 1) -> str:
    return f'<g transform="translate({x} {y}) scale({scale})">\n{art}\n</g>'


def heading(width, height, layers: dict[str, str]) -> str:
    records = [f'<g id="{name}" inkscape:groupmode="layer" inkscape:label="{escape(name.replace("_", " ").title())}">\n{art}\n</g>'
               for name, art in layers.items()]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" width="{width}" height="{height}" '
            f'viewBox="0 0 {width} {height}" stroke-linejoin="round" stroke-linecap="round">\n'
            + "\n".join(records) + "\n</svg>\n")


def save_svg(target: Path, dimensions, layers) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(heading(*dimensions, layers), encoding="utf-8")


def render(source: Path, destination: Path, width: int, layer: str | None = None) -> Image.Image:
    destination.parent.mkdir(parents=True, exist_ok=True)
    command = ["inkscape", str(source), "--export-area-page", f"--export-width={width}",
               f"--export-filename={destination}"]
    if layer is not None:
        command.extend([f"--export-id={layer}", "--export-id-only"])
    run(command, check=True, capture_output=True)
    with Image.open(destination) as image:
        return image.convert("RGBA")


def receipt(file_path: Path) -> dict:
    with Image.open(file_path) as image:
        return {"texture": file_path.relative_to(ROOT).as_posix(), "dimensions": list(image.size),
                "sha256": sha256(file_path.read_bytes()).hexdigest(), "alpha_bounds_px": image.convert("RGBA").getbbox()}


def store(path: Path, record: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def foliage(x, y, size=1, shade=FOLIAGE) -> str:
    blades = stack(
        path("M0 1C-1-7-7-19-17-24C-20-17-14-9-5-5L0 1Z", shade, INK, 1.4),
        path("M0 0C0-12-5-28 0-32C7-29 9-15 3-7L0 0Z", "#9aa35d", INK, 1.4),
        path("M1 1C5-12 11-22 21-22C24-15 18-10 12-6Z", "#899754", INK, 1.4),
        path("M0 0C-2-6-14-8-23-9C-24-4-21 1-14 2L0 4Z", "#75884f", INK, 1.4),
        path("M1 1C7-4 13-8 22-7C23-3 20 2 13 4L1 4Z", "#758249", INK, 1.4),
        path("M-1-2Q-4-13-10-18M1-4L1-24M2-2Q8-11 16-16", "none", "#4e613d", .8),
    )
    return place(x, y, blades, size)


def pot(x, bottom, scale=1, tone="#aa7655") -> str:
    base = stack(foliage(0, -10, .78), path("M-10-13L10-13L7-1Q0 1-7-1Z", tone, INK, 1.5),
                 rect(-12, -15, 24, 4, "#c5966d", INK, 1.25, 1.25), line(-5,-9,-4,-3,"#dbb18b",1))
    return place(x,bottom,base,scale)


def cloud(x, y, scale) -> str:
    return place(x,y,path("M0 13Q5 5 16 7Q17-2 29 1Q36-8 48 4Q62 1 67 10Q79 7 84 15H0Z",
                          "#dcdfc9"),scale)


def canopy_shape(x, y, width, height, color, seed, count=14) -> str:
    rng = random.Random(seed)
    width_step = width / count
    points = [(x, y + height * .65)]
    for index in range(count):
        cx = x + index * width_step
        top = y + rng.uniform(-.24, .33) * height
        points.append((round(cx, 1), round(top, 1)))
    points.append((x + width, y + height * .2))
    shape = f"M{x} {y + height * .65} "
    for (prevx, prevy), (nextx, nexty) in zip(points, points[1:]):
        dx = nextx - prevx
        shape += f"C{fmt(prevx + dx*.21)} {fmt(min(prevy,nexty)-height*.58)} {fmt(prevx + dx*.62)} {fmt(min(prevy,nexty)-height*.48)} {nextx} {nexty} "
    shape += f"L{x + width} {y + height}H{x}Z"
    return path(shape,color)


def jungle_trunk(x, y, direction, scale) -> str:
    tree = stack(
        path("M17 487Q28 411 28 338Q25 248 11 172L-31 81L-19 64L17 118Q26 71 21 10L42 6Q47 65 38 108L81 62L98 64Q74 108 49 133L43 158Q48 234 54 296Q51 393 64 487Z",
             "#565346","#434737",4),
        path("M34 472Q43 393 39 325Q36 241 31 209L26 147L43 151Q42 230 48 289Q49 401 54 476Z","#6b604d"),
        path("M39 227L90 147L108 150L71 208L45 262Z","#5f5846","#434737",2),
        path("M34 289Q34 200 23 161M45 386L43 449","none","#827258",3),
    )
    return f'<g transform="translate({x} {y}) scale({direction * scale} {scale})">{tree}</g>'


def leaf_silhouette(x, y, s, color) -> str:
    return place(x, y, path("M0 0C-9-17 -22-20 -31-17C-29-9 -19-1 -5 3C-16 2 -21 5 -25 8C-20 15 -9 13 0 7C10 16 19 13 23 8C22 4 15 1 4 1C14-8 21-13 21-23C13-26 5-17 0 0Z",color),s)


def jungle_background() -> str:
    layers = [
        rect(0,0,1280,720,"#9abfc1"),
        cloud(174,51,1.5),cloud(752,56,1.75),cloud(961,31,1.2),cloud(480,47,.68),
        canopy_shape(0,111,1280,392,"#849e78",921,34),
        canopy_shape(0,151,1280,463,"#718963",340,29),
        canopy_shape(0,211,1280,469,"#557759",776,33),
        canopy_shape(-30,397,1330,318,"#496747",619,24),
        jungle_trunk(-2,81,1,1.19), jungle_trunk(1259,85,-1,1.21),
        jungle_trunk(96,153,1,.62), jungle_trunk(1164,187,-1,.67),
    ]
    for sign, offset in [(1, 0), (-1,1280)]:
        rng = random.Random(64+sign)
        for idx in range(50):
            x = round(rng.uniform(-16,235 if idx < 26 else 104) * sign + offset)
            y = round(rng.uniform(-16,89 if idx < 26 else 500))
            size = round(rng.uniform(.56,1.4),2)
            colors = ["#486842","#58774a","#688348","#82944f","#a0a55a"]
            layers.append(leaf_silhouette(x,y,size,rng.choice(colors)))
    layers.extend([
        path("M0 622Q262 592 640 615Q1006 591 1280 622V720H0Z","#7e8b5c"),
        path("M0 667Q293 636 640 663Q962 640 1280 663V720H0Z","#89956a"),
        path("M0 705Q238 679 449 694Q759 664 1280 698V720H0Z","#a19874"),
    ])
    return stack(*layers)


def glass_panel(x,y,w,h,division=True) -> str:
    body = [
        rect(x,y,w,h,"#76a7a0",DEEP_TEAL,1.6),
        polygon([(x+2,y+8),(x+int(w*.38),y+2),(x+int(w*.54),y+2),(x+1,y+int(h*.65))],"#a9c9b7"),
        polygon([(x+int(w*.4),y+h-2),(x+w-2,y+int(h*.32)),(x+w-2,y+int(h*.62)),(x+int(w*.68),y+h-2)],"#8cb7a8"),
        line(x+2,y+h-3,x+w-2,y+h-3, "#55817b",1.6),
    ]
    if division:
        body.append(line(x+w/2,y+1,x+w/2,y+h-1,DEEP_TEAL,2))
    return stack(*body)


def lamp(x: int, y: int, width: int) -> str:
    return stack(rect(x-2,y-2,width+4,6,"#e6c079",None,1,2),rect(x,y,width,2,"#fff1ba",None,1,1))


def roof_art() -> str:
    solar = stack(
        polygon([(351,53),(544,28),(610,72),(411,94)],"#47535d",INK,3.4),
        polygon([(356,53),(543,34),(600,71),(410,87)],"#6d8789",INK,1.7),
        *[line(359+i*43,53-i*4.1,413+i*42,86-i*3.2,"#a8b7aa",1.7) for i in range(5)],
        line(374,63,563,43,"#a8b7aa",1.5),line(387,74,579,56,"#a8b7aa",1.5),
        path("M410 89V121M593 75V112M494 77V116","none",INK,4),
    )
    rooftop = stack(
        polygon([(350,87),(787,57),(918,92),(917,121),(351,121)],"#dcd4b9",INK,3),
        *[glass_panel(x,90+(i%2)*2,51,41,False) for i,x in enumerate(range(375,888,52))],
        polygon([(349,80),(794,52),(923,84),(909,93),(785,65),(351,94)],"#e7ddc9",INK,2.7),
        path("M348 82L791 54L920 86","none","#faf0d6",2.6),
        solar, lamp(432,99,68),lamp(623,91,64),lamp(780,91,68),
        rect(125,116,1032,27,"#a79e85",INK,2.5),
        rect(138,111,1010,9,"#d4c7ae",INK,2.2),
        path("M169 110V90H307V110M972 110V91H1129V110","none",DEEP_TEAL,3),
        *[line(x,92,x,110,DEEP_TEAL,2) for x in [195,221,247,273,998,1026,1055,1082,1108]],
        *[foliage(x,116,scale) for x,scale in [(160,.78),(205,.88),(246,.65),(283,.88),(325,.7),(977,.66),(1008,.85),(1045,.68),(1081,.78),(1126,.8)]],
        path("M892 110L910 74L923 110Z","#756d60",INK,2),
        '<g transform="translate(913 68) rotate(-28)">'
        + stack(ellipse(0,0,26,12,"#cfcabd",INK,2.8),ellipse(0,-2,21,7,"#ede6cc",LIGHT_INK,1.4),
                line(0,-16,4,1,INK,2.2),ellipse(0,-16,3.8,3.3,GOLD,INK,1.3)) + '</g>',
        path("M952 109V70M941 77H962M945 86H959","none",INK,2.6),
    )
    return rooftop


def lobby_art() -> str:
    emblem = re.search(r"<path\b[^>]+/>", RECEPTION_EMBLEM.read_text(encoding="utf-8"))[0]
    lobby = [rect(124,615,1032,60,"#8e8a76",INK,3)]
    for x in [128,199,270,341,412,483,718,790,862,934,1006,1078]:
        lobby.append(glass_panel(x,617,69,51))
    lobby.extend([
        rect(486,610,305,66,"#b1a388",INK,3),
        rect(501,616,272,56,"#e2caa4",INK,1.7),
        lamp(555,620,69),lamp(663,620,63),
        place(587,623,emblem,.22),
        rect(547,645,185,24,"#ad895f",INK,1.5,3),
        rect(540,644,199,7,"#d1ae7c",INK,1.4,1.5),
        rect(622,630,45,14,"#59655a",INK,1.5,1.7),
        rect(627,633,35,7,"#9caa92",None,1,1),
        pot(526,667,.98),pot(757,667,1.1),
        rect(500,618,7,53,"#7f8e86",INK,1.3),rect(769,617,7,54,"#7f8e86",INK,1.3),
        line(581,620,581,671,DEEP_TEAL,2.2),line(696,620,696,671,DEEP_TEAL,2.2),
        polygon([(487,672),(792,672),(818,693),(464,693)],"#d0c5a9",INK,2.3),
        line(480,679,800,679,"#7e755f",2.8),line(471,686,808,686,"#8e816a",2.4),
        rect(887,641,64,29,"#7b7562",INK,2,2),
        rect(882,636,74,7,"#bbb090",INK,1.6,1.7),
        rect(898,649,43,14,"#9e9075",None,1,1),
    ])
    return stack(*lobby)


def exterior_layers() -> dict[str,str]:
    under = [rect(111,137,1058,482,"#aaa58f",INK,4),rect(121,150,1038,455,"#d1c7ab",INK,2)]
    over = []
    for row in range(4):
        y = ORIGIN[1] + row * STEP[1]
        for x in [119,1135]:
            under.append(glass_panel(x,y,29,105))
            under.append(line(x+2,y+45,x+27,y+45,DEEP_TEAL,2))
        for column in range(3):
            x = ORIGIN[0] + column * STEP[0]
            under.append(rect(x,y,ROOM_W,ROOM_H,"#c2b398",LIGHT_INK,2))
        beam_y = y+ROOM_H-1
        over.extend([
            rect(103,beam_y,1074,12,"#ddd2b8",INK,2.6,2),
            rect(111,beam_y+8,1058,4,"#a49a81",None,1,1),
            line(104,beam_y+1,1176,beam_y+1,"#f6e9cb",1.7),
            *[line(x,beam_y+3,x,beam_y+10,"#a79b83",1) for x in [234,370,505,640,775,910,1045]],
        ])
    for x in [144,470,796,1122]:
        over.extend([
            rect(x,146,8,465,"#aca18b","#5e5747",1.45),
            line(x+1,147,x+1,610,"#e2d6bb",1.35),
        ])
    over.extend([
        rect(101,133,1078,17,"#dbd1b8",INK,3,2),
        rect(106,144,1068,5,"#a09783",None,1,1),
        rect(106,132,1068,4,"#f0e5cb",None,1,1),
        *[line(x,137,x,148,"#a49a84",1.2) for x in range(221,1151,131)],
    ])
    edge = [polygon([(0,696),(155,686),(358,697),(505,713),(0,720)],"#b3a584"),
            polygon([(820,711),(966,698),(1081,695),(1280,682),(1280,720)],"#b7a68a")]
    for x,y,scale in [(11,683,2.7),(76,711,2.4),(131,693,1.8),(195,708,1.53),(344,705,1.4),
                      (970,706,1.43),(1099,697,1.65),(1166,711,2.12),(1243,683,2.8),(1276,712,2.4)]:
        edge.append(foliage(x,y,scale,"#607b4b"))
    for x, y, scale in [(152,685,1.24),(297,689,.8),(1012,691,.9),(1140,685,1.31)]:
        edge.append(place(x,y,stack(path("M-22 0L-17-13L-4-19L12-17L20-7L23 0Z","#8c8572",INK,2.4),
                                    path("M-17-8L-4-16L9-14L14-10L-4-10Z","#aea68b")),scale))
    return {"jungle": jungle_background(), "roof": roof_art(), "frame_back": stack(*under),
            "lobby": lobby_art(), "frame_front": stack(*over), "foreground": stack(*edge)}


def dossier(x,y,w=14,h=30, color="#be9f5e") -> str:
    return stack(rect(x,y,w,h,color,INK,1.2,1),rect(x+3,y+3,w-6,6,"#eee3bf"),
                 ellipse(x+w*.5,y+h-4,1.7,1.7,"#6b5d45"))


def shelving(x,y,w,h,books="#938c67") -> str:
    out = [rect(x,y,w,h,"#8c775b",INK,1.8,1), rect(x+4,y+4,w-8,h-8,"#ad8e65",INK,1.2)]
    row_height = int((h-10)/2)
    for row in range(2):
        baseline = y + 5 + row_height * (row+1)
        for col in range(int((w-8)/11)):
            book_height=row_height-5-((row+col)%3)*2
            tone = [books,"#bda16d","#7e8a69","#b38358"][(row+col)%4]
            out.append(dossier(x+5+col*11,baseline-book_height,10,book_height,tone))
        out.append(rect(x+3,baseline,w-6,2.3,"#d4ad7e",INK,1.05))
    return stack(*out)


def drawer(x,y,w=45,h=35, fill="#ac9981") -> str:
    out = [rect(x,y,w,h,fill,INK,1.65,2)]
    for row in range(3):
        yy = y+(row+.5)*h/3
        out.append(line(x+2,yy+h/6,x+w-2,yy+h/6,"#796d59",1.1))
        out.append(line(x+w*.36,yy,x+w*.62,yy,INK,1.6))
    return stack(*out)


def carton(x,y,w,h, fill="#b69667") -> str:
    return stack(rect(x,y,w,h,fill,INK,1.65,1.4),rect(x-1,y,w+2,4,"#d0af7a",INK,1.1,1),
                 rect(x+w*.37,y+7,w*.28,3.1,"#6f6047",None,1,1))


def laptop(x,y,scale=1) -> str:
    case = stack(path("M0 1L25 1L21 20L-5 20Z","#58665b",INK,1.6),
                 path("M3 4L21 4L19 16L0 16Z","#9cb9a2"), rect(-7,19,34,3,"#a7a28c",INK,1.05,1.3),
                 line(4,7,17,7,"#c2d1ac",.9),line(4,10,13,10,"#c2d1ac",.9))
    return place(x,y,case,scale)


def monitor(x,y,w,h,content="signal") -> str:
    inside=[rect(0,0,w,h,"#645f50",INK,1.7,2),rect(3,3,w-6,h-6,"#436c70",INK,1.05),
            polygon([(3,3),(w*.77,3),(w*.18,h-3),(3,h-3)],"#608c8b")]
    if content=="map":
        inside.extend([polygon([(8,h*.88),(w*.26,h*.23),(w*.55,h*.44),(w*.87,h*.19),(w*.90,h*.75),
                                 (w*.61,h*.72),(w*.54,h*.87)],"#829751"),
                       path(f"M10 {h*.77}L{w*.37} {h*.66}L{w*.55} {h*.45}L{w*.78} {h*.47}","none","#e8dc96",1.15)])
        for mx,my in [(10,h*.77),(w*.37,h*.66),(w*.55,h*.45),(w*.78,h*.47)]:
            inside.append(ellipse(mx,my,1.9,1.9,GOLD,"#f5df9b",.7))
    elif content=="signal":
        inside.append(path(f"M6 {h*.64}H{w*.27}L{w*.36} {h*.42}L{w*.49} {h*.74}L{w*.60} {h*.34}L{w*.73} {h*.62}H{w-5}","none","#c6c78e",1.5))
    elif content=="radar":
        for rad in [.19,.32]:
            inside.append(ellipse(w*.52,h*.51,h*rad,h*rad,"none","#a3bfa1",1))
        inside.append(line(w*.52,h*.51,w*.69,h*.28,"#edcc69",1.6))
        inside.append(ellipse(w*.59,h*.6,2.2,2.2,GOLD))
    else:
        for i in range(5):
            inside.append(rect(9+i*(w-17)/5,h-(i+2)*h/9-4,(w-23)/6,(i+2)*h/9,"#a6b684"))
    return place(x,y,stack(*inside))


def wall_chart(x,y,w,h, leaf=False) -> str:
    paper=stack(rect(0,0,w,h,"#e4d1a9",INK,1.6,1.3),rect(4,4,w-8,h-8,"#f5e8cb",None,1,1))
    if leaf:
        art=path(f"M{w*.26} {h*.77}Q{w*.22} {h*.37} {w*.74} {h*.22}Q{w*.85} {h*.61} {w*.26} {h*.77}Z","#829765")
        art+=line(w*.23,h*.82,w*.7,h*.29,"#5d7752",1.45)
    else:
        art=line(7,h-8,w-6,h-8,"#a49a78",1)
        for idx in range(6):
            length=(idx%3+idx+2)*1.55
            art+=rect(8+idx*(w-15)/6,h-9-length,3.5,length,"#7e906c")
    return place(x,y,paper+art)


def desk(x, y, width, tone=WOOD, height=22) -> str:
    return stack(rect(x+4,y+1,width-8,height,tone,INK,1.7,2),
                 path(f"M{x+5} {y+height-3}H{x+width-5}","none","#7f644b",1.35),
                 rect(x-1,y-3,width+2,5.5,"#cfad82",INK,1.6,1.3),
                 line(x+5,y+6,x+width-5,y+6,"#c1a477",1))


def pot_tray(x,y,count,scale=1) -> str:
    out = []
    for idx in range(count):
        off=idx*23
        out.append(rect(off+1,4,20,18,"#b9c0a4",INK,1.15,2))
        out.append(rect(off+4,11,14,8,"#9d805a",None,1,1))
        out.append(foliage(off+11,15,.45,"#728d56"))
        out.append(line(off+4,6,off+4,17,"#e0dab6",1.2))
    return place(x,y,stack(rect(-3,18,count*23+3,6,"#a99c75",INK,1.3,2),*out),scale)


def room_backdrop(accent: str) -> str:
    return stack(
        rect(0,0,ROOM_W,ROOM_H,"#d8c6a5"),
        polygon([(0,0),(314,0),(297,15),(18,15)],"#bcae91"),
        rect(16,14,282,72,"#edf0d7" if accent=="#a1a778" else "#e4d5b8"),
        polygon([(0,0),(16,15),(16,86),(0,101)],"#c0af90"),
        polygon([(315,0),(297,15),(297,86),(314,100)],"#b2a48b"),
        polygon([(0,105),(314,105),(298,86),(16,86)],"#9d8d72"),
        polygon([(15,105),(314,105),(298,90),(16,90)],"#ad9978"),
        rect(16,83,281,5,accent, None,1,1.2),
        *[line(x,90,x-11,105,"#8e7f66",.66) for x in range(45,299,29)],
        line(0,101,314,101,"#c5b095",1.1),
        lamp(34,7,77),lamp(124,7,74),lamp(211,7,69),
        rect(265,28,26,57,"#8e866e",INK,1.8,1),
        rect(269,34,17,26,accent,INK,1.1,1),
        rect(273,38,10,16,"#b5c4aa",None,1,1),ellipse(271,70,1.1,2.2,INK),
        rect(262,83,32,3,"#a2977c",INK,1),
    )


def tool_rack(x,y) -> str:
    shapes = [rect(0,0,128,52,"#aa9b81",INK,1.8,3)]
    for row in range(5):
        for col in range(15):
            shapes.append(ellipse(7+col*8,6+row*10,.7,.7,"#766b55"))
    for col,x1 in enumerate(range(11,82,16)):
        item=stack(path("M-4-10L-2-14L1-11L4-14L6-10L3-5L3 10L-2 10L-2-5Z","#c6c2a3",INK,1.05),
                   ellipse(.5,7.5,1.15,1.15,"#a2916e"))
        shapes.append(place(x1,27+(col%2)*4,item,.81))
    shapes.extend([
        path("M91 13L116 13L119 21L105 23L105 33L98 33L97 23L91 23Z","#d4aa55",INK,1.6),
        line(87,18,92,18,INK,2),
        path("M94 40H115","none","#586e62",2.6),
    ])
    return place(x,y,stack(*shapes))


def radio(x,y,scale=1) -> str:
    return place(x,y,stack(rect(-13,2,26,17,"#5f6658",INK,1.7,2),
                          rect(-9,5,15,7,"#b5c394",INK,1,1),rect(-8,14,27,1,"#3f4d43"),
                          ellipse(8,8,2,2,GOLD,INK,.9),line(-8,2,-9,-11,INK,1.7)),scale)


def microscope(x,y,scale=1) -> str:
    return place(x,y,stack(path("M10 4Q21 11 17 23L12 28L5 28L9 24Q17 21 14 15L9 11Z",
                               "#9fae9e",INK,1.3),
                          path("M6 2L13 6L8 17L3 14Z","#c1c8ad",INK,1.4),
                          path("M1 1L7 2L7 6L0 4Z","#5d685c",INK,1.3),
                          rect(-4,19,14,3,"#657a6e",INK,1.2,1),
                          rect(-6,28,27,5,"#afbc9c",INK,1.25,2),ellipse(16,18,3,3,GOLD,INK,1.2)),scale)


def camera(x,y,scale=1) -> str:
    return place(x,y,stack(path("M0 15L-11 44M0 15L10 44M0 15L2 44","none","#545d50",2.9),
                          rect(-13,2,28,16,"#5e685d",INK,1.65,3),rect(10,4,9,10,"#aaa58a",INK,1.15,1.4),
                          rect(-10,-5,17,6,"#93988c",INK,1.3,2),rect(-18,4,8,9,"#899c8d",INK,1.25,1.4),
                          ellipse(-17,8,2.2,2.6,"#bcc6a3"),ellipse(7,4,1.4,1.4,"#ae6552")),scale)


def protective_shield(x,y,scale=1) -> str:
    return place(x,y,stack(path("M0 2Q13-3 27 3L26 34Q22 45 14 48Q6 44 1 32Z","#75807a",INK,1.8),
                          path("M6 4Q12 2 21 4L20 30Q17 39 13 40L7 34Z","#a5b3a2"),
                          path("M8 24L14 14L20 23L16 22L14 27L11 23Z","#dddfbc"),
                          line(3,9,4,31,"#bbc2a9",1.1)),scale)


def book(x,y,scale=1) -> str:
    return place(x,y,stack(path("M-2 5L11 0L19 5L32 1L27 13L15 17L9 13L-4 16Z","#7d775d",INK,1.45),
                          path("M-1 4L11 0L19 4L30 0L25 11L15 14L9 11L-3 14Z","#e9dfb9",INK,1.16),
                          line(19,4,15,14,"#8e7c60",1.15),
                          path("M1 7L9 5M1 10L9 8M18 8L26 5M17 11L25 8","none","#a39374",.75)),scale)


def lamp_desk(x,y) -> str:
    return place(x,y,stack(rect(-10,22,25,3,"#7d7965",INK,1,1.5),
                           path("M0 20L11 5L-1-6","none","#596758",2.4),
                           path("M-4-9Q-14-7-17 1L-2 3L3-6Z","#7f946f",INK,1.45),
                           path("M-15 1L-3 2","none","#ead79d",1.45)))


def calculator(x,y,scale=1) -> str:
    items = [path("M1 1H22L21 24H-3Z","#c2bca3",INK,1.55),
             rect(3,4,14,5,"#87967f",INK,.65,1)]
    for row in range(3):
        for col in range(3):
            items.append(rect(col*5+1,row*3.6+12,3.4,2.1,"#656856",None,1,.5))
    return place(x,y,stack(*items),scale)


def room_contents(key: str) -> tuple[str,str]:
    match key:
        case "control_room":
            return (stack(monitor(37,22,97,49,"map"),monitor(139,22,57,25,"radar"),monitor(139,50,57,22),
                          monitor(201,23,44,27),rect(37,67,208,11,"#80765d",INK,1.4),pot(26,89,.76),
                          drawer(226,56,27,31),radio(241,69,.62)),
                    stack(desk(94,88,149,height=15),laptop(134,67,1),radio(181,72,.69),
                          rect(210,85,20,4,"#a4b997",INK,1,1.1)))
        case "human_resources":
            return (stack(shelving(29,22,107,59,"#b2a482"),drawer(141,55,38,30),
                          wall_chart(151,19,41,28),wall_chart(197,19,43,28,True),pot(249,88,.67)),
                    stack(desk(94,88,157,"#a88666",15),laptop(148,66,.98),
                          rect(184,84,20,4,"#d8d0af",INK,.9,1),rect(192,86,16,3,"#bdad8e",INK,.8,1)))
        case "finance_room":
            return (stack(carton(26,66,34,18),carton(29,48,29,18),shelving(62,21,79,53,"#7e866a"),
                          wall_chart(153,23,64,45),drawer(227,53,28,33,"#a9a285")),
                    stack(desk(87,89,161,"#a48660",15),laptop(108,69),calculator(223,68,.87),
                          dossier(149,75,12,13,"#969573"),dossier(160,74,12,14,"#b09f71"),pot(247,98,.54)))
        case "mechanical":
            return (stack(tool_rack(83,21),drawer(26,49,44,37,"#c49f54"),rect(47,26,24,21,"#899181",INK,1.45,2),
                          *[line(50,30+k*4,68,30+k*4,"#ccd0ac",1) for k in range(4)],carton(232,49,24,37,"#a9906d")),
                    stack(desk(45,93,182,"#907a60",12),rect(122,81,40,10,"#7f8c7c",INK,1.4,2),
                          ellipse(145,81,8,6,"#a3a899",INK,1.4),line(134,86,156,86,INK,.95),
                          rect(181,80,30,11,"#d5a749",INK,1.45,2),line(188,80,188,89,"#866f46",1)))
        case "ecology":
            return (stack(glass_panel(109,19,131,55),pot_tray(113,49,5),pot(44,55,.91),pot(74,56,.76),
                          drawer(24,58,55,25,"#bca981"),pot(246,86,.77),lamp(147,23,65),path("M40 53V44M53 53V44M60 53V45","none","#a98d67",1.1)),
                    stack(desk(51,93,193,"#9a875e",11),pot_tray(121,68,4,.98),pot(71,92,.67)))
        case "outreach":
            mountain=stack(rect(122,23,110,48,"#a7babc",INK,1.55,2),
                           polygon([(128,66),(154,38),(178,56),(190,32),(227,66)],"#738f82"),
                           polygon([(154,38),(165,49),(156,47),(150,51),(144,49)],"#e7e4c7"),
                           polygon([(190,32),(206,48),(197,46),(193,51),(185,45),(181,46)],"#dddcc0"))
            return (stack(mountain,pot(36,91,1),pot(246,89,.85),camera(90,43,.94),carton(225,76,27,13)),
                    stack(desk(126,88,108,"#b19270",16),laptop(194,65,.96),rect(150,85,29,4,"#e2d3af",INK,1,1)))
        case "records":
            return (stack(shelving(25,20,128,68,"#b5956b"),shelving(152,20,76,69,"#9e9a73"),
                          drawer(226,59,24,28),pot(254,89,.74)),
                    stack(desk(91,91,155,"#9e7e5c",13),lamp_desk(219,67),book(158,74,1),
                          rect(116,81,33,5,"#b68a5d",INK,1.1,1),rect(122,77,29,5,"#839171",INK,1.1,1)))
        case "r_d_eco":
            return (stack(wall_chart(40,22,48,42,True),wall_chart(92,22,48,42,True),wall_chart(144,22,48,42,True),
                          drawer(218,49,33,35,"#a6a78b"),pot(248,55,.63),pot(25,88,.63),
                          rect(31,76,164,10,"#a0a084",INK,1.45,1),pot_tray(125,52,3,.88)),
                    stack(desk(60,92,187,"#9c9979",12),microscope(128,59,.98),
                          rect(181,71,47,19,"#8d9f87",INK,1.3,2),
                          *[rect(i,65,4.3,23,"#c1c7a5",INK,.82,1) for i in [188,201,214]]))
        case "r_d_combat":
            net=stack(path("M0 0Q22-10 40 1Q20 35 1 20Z","#b9ac86",INK,1.5),
                      path("M4 5L25 18M12 1L31 12M5 12L16 23M11 0L6 19M20-1L14 24M28 0L24 21M35 1L31 13","none","#80775c",.85),
                      line(6,19,-13,41,INK,2.2))
            return (stack(shelving(27,21,57,61,"#b69764"),place(133,31,net,1.04),
                          rect(197,25,37,25,"#bd9c50",INK,1.7,2),rect(213,25,6,25,"#7a8066",INK,1.1),
                          drawer(213,61,39,26,"#9c9a86")),
                    stack(desk(85,92,163,"#9c8766",12),ellipse(119,82,21,8,"#ab9052",INK,1.55),
                          ellipse(119,82,15,4.7,"none","#5d694e",1.05),rect(193,78,35,12,"#cbab58",INK,1.5,2),
                          line(199,79,199,88,INK,1)))
        case "r_d_guard":
            return (stack(protective_shield(37,25,1.07),protective_shield(67,25,.99),protective_shield(95,25,.88),
                          rect(32,78,93,7,"#8a826a",INK,1.4,2),
                          wall_chart(151,25,48,38),drawer(224,55,29,32),pot(246,57,.59)),
                    stack(desk(103,93,148,"#8f8b73",11),laptop(138,72,.9),
                          protective_shield(217,67,.53),
                          rect(184,87,29,5,"#a49b8a",INK,.95,1.1)))
        case "r_d_crisis":
            return (stack(monitor(29,22,76,42,"signal"),monitor(109,22,86,42,"map"),monitor(200,24,51,40),
                          rect(29,70,223,13,"#9a8e75",INK,1.6,2),radio(49,60,.81),
                          drawer(224,69,28,19,"#a39f86")),
                    stack(desk(77,93,172,"#8d8774",11),laptop(93,69,1.05),radio(183,80,.85),radio(210,79,.63),
                          rect(151,87,18,3,"#b0b5a0",INK,.85,1)))
        case _:
            raise ValueError(f"No configured Headquarters art for {key}")


def room_unbuilt() -> str:
    rivets = []
    for y in [26,58,80]:
        for x in range(20,254,36):
            rivets.append(ellipse(x,y,.9,.9,"#a19a84"))
    return stack(room_backdrop("#b5a58b"),rect(24,20,220,62,"#d3c6a9",LIGHT_INK,1.35,1),
                 line(97,21,97,80,"#b1a58c",1),line(170,21,170,80,"#b1a58c",1),line(23,52,242,52,"#b1a58c",1),
                 *rivets, carton(32,62,35,25,"#b39a72"),carton(60,76,46,19,"#af9571"),
                 path("M169 88L184 47H194L203 88M179 88L189 52M175 77H201M178 68H199M181 58H197","none","#756950",2.2),
                 path("M223 86L227 58M227 86L235 65M230 85L240 69","none","#d3c5a3",3.4),
                 rect(219,78,25,13,"#a59c7f",INK,1.35,1),
                 rect(103,89,55,8,"#c0a77f",LIGHT_INK,1.1,1))


def badge_graphic(feature: str) -> str:
    hair = ACTOR_INK
    match feature:
        case "radio headset":
            return stack(path("M22 46Q21 23 42 20Q59 17 67 31","none","#4d574f",3.6),
                         ellipse(29,46,6.7,7.3,"#5a6256",hair,2.5),ellipse(29,46,3.2,4.6,"#89927a"),
                         path("M34 51Q40 55 48 52","none",hair,1.4),ellipse(47.7,51.4,2.3,1.6,"#626e5f",hair,1.1))
        case "glasses" | "safety glasses":
            tone = "#65584a" if feature == "glasses" else "#626f61"
            return stack(rect(43,40,9,9,"none",tone,1.75,2),rect(56,40,8.6,8.8,"none",tone,1.75,2),
                         line(52,43,56,43,tone,1.45),line(43,43,39,42,tone,1.4),
                         line(45,41,47,41,"#f5dcb7",.68),line(58,41,60,41,"#f5dcb7",.68))
        case "work goggles":
            return stack(path("M25 35Q27 20 43 18Q58 16 68 34L62 37L25 36Z","#a89057",hair,2.7),
                         path("M39 23Q55 18 61 30L49 31L38 29Z","#bcab76"),
                         path("M36 29Q51 24 60 28L62 34L57 36L47 34L39 36Z","#a87744",hair,2.4),
                         path("M40 29Q51 26 57 28L58 32L50 32L42 33Z","#e3c47a",None),
                         line(45,29,50,27,"#fae3a2",.95))
        case "field hat":
            return stack(path("M28 33Q26 20 40 16Q55 13 60 25L64 32Z","#b9a371",hair,2.55),
                         path("M30 31Q44 27 61 27L64 32Z","#8a8055"),
                         path("M24 35Q40 29 65 30L73 33Q70 38 60 38L30 39Z","#b7a477",hair,2.6),
                         line(36,34,60,33,"#d5bf8c",1.45))
        case "patrol cap":
            return stack(path("M26 32Q26 20 45 19Q58 18 65 33","#899563",hair,2.7),
                         path("M26 33Q43 27 68 30L73 35Q70 37 64 36L28 38Z","#8a975f",hair,2.3),
                         path("M39 27L42 24L48 25L46 27Z","#e3d4a1"))
        case _:
            raise ValueError(f"Unknown staff accessory {feature}")


def npc_head(person: Staff, approved: str) -> str:
    tone, shade = {
        "bob": ("#554035", "#6d5140"),
        "bun": ("#4c3932", "#6b4b3a"),
        "part": ("#574239", "#70513f"),
    }[person.hair]
    # The eye marks come from the approved E02 head crop. The ears, chin,
    # spacing and scale stay registered in the same 96-unit chibi canvas.
    shapes = []
    if person.hair == "bun":
        shapes.append(ellipse(30,29,12,10,tone,ACTOR_INK,3.2))
        shapes.append(path("M24 27Q27 22 35 23","none",shade,1.7))
    if person.hair == "bob":
        shapes.append(path("M27 34Q18 49 26 57Q34 57 46 53L61 55Q68 55 71 47L65 30Z",tone,ACTOR_INK,3.0))
    shapes.extend([
        path("M24 43Q21 20 44 18Q62 16 69 32Q74 46 65 51L56 52H39L26 48Z",tone,ACTOR_INK,3.1),
        path("M43 33Q56 32 63 35L66 41V51Q64 55 58 56L43 55Q37 54 36 50Q28 53 28 47Q27 43 33 42Z",
             person.skin,ACTOR_INK,2.7),
        path("M39 51Q49 55 61 53Q58 56 50 56Q43 55 39 51Z","#c89571"),
        # Preserve the reference eye proportions and shape while grading the
        # adjacent skin into the staff member's own palette.
        approved,
    ])
    if person.hair == "bun":
        shapes.append(path("M24 40Q24 27 34 22Q48 18 60 26Q68 30 67 39Q59 36 54 30Q49 37 42 38L35 45Z",tone,ACTOR_INK,2.7))
        shapes.append(path("M31 28Q43 21 54 25Q39 25 31 31Z",shade))
    elif person.hair == "bob":
        shapes.append(path("M25 43Q21 24 40 20Q54 16 66 29Q70 34 68 41Q61 39 55 30Q52 38 46 39Q43 38 42 33Q38 41 34 43L31 50Z",tone,ACTOR_INK,2.7))
        shapes.append(path("M29 31Q35 23 46 23Q39 26 34 32Z",shade))
    else:
        shapes.append(path("M25 42Q21 28 37 21Q50 16 59 25Q68 26 68 40Q64 36 58 35Q54 29 52 29Q45 36 35 39L32 48Z",tone,ACTOR_INK,2.5))
        shapes.append(path("M34 28Q45 21 52 24Q45 24 36 31Z",shade))
    return stack(*shapes)


def npc_prop(role: str) -> str:
    stroke = ACTOR_INK
    match role:
        case "control_room":
            return radio(70,68,.60)
        case "human_resources":
            return stack(path("M63 64L77 60L83 70L69 76Z","#b59668",stroke,1.8),
                         path("M65 65L76 62L80 69L70 74Z","#e8d9b4",stroke,1.15),
                         path("M70 67L77 64M71 70L78 67","none","#929b76",.95))
        case "finance_room":
            return stack(path("M62 68L80 65L82 73L64 76Z","#8d9678",stroke,1.7),
                         path("M65 69L78 67L79 71L66 74Z","#c5c6a0",stroke,.9))
        case "mechanical":
            return stack(path("M60 72L66 71L75 60L73 56L76 54L78 57L81 54L83 57L80 63L77 63L69 76L64 78Z",
                              "#b6b8a5",stroke,1.65),line(68,73,76,62,"#d7cfb2",1.1))
        case "ecology":
            return stack(path("M63 65L74 65L76 74L67 77L63 73Z","#809474",stroke,1.5),
                         path("M72 67L81 63L82 66L75 72Z","#9da88b",stroke,1.1),
                         path("M64 66Q58 60 60 69L65 71","none",stroke,1.35))
        case "outreach":
            item=stack(rect(-1,1,5,13,"#707565",stroke,1.3,1.4),ellipse(1.4,0,4.8,4.5,"#696a5c",stroke,1.3),
                       ellipse(2,-1,3.4,2.4,"#b1a88d"))
            return '<g transform="translate(73 61) rotate(35)">' + item + '</g>'
        case "records":
            return book(68,66,.65)
        case "r_d_eco":
            return stack(rect(69,58,5,15,"#cad4b5",stroke,1.2,1.1),
                         rect(69.9,65,3.2,7,"#82a080",None,1,.5),rect(68,57,7,3,"#b39770",stroke,1.25,1))
        case "r_d_combat":
            return stack(ellipse(73,68,8,7,"#c5a35c",stroke,1.6),
                         ellipse(73,68,5,4,"none","#8b6948",1.3),
                         ellipse(73,68,2.3,1.8,"#a27b51",stroke,1.05),line(79,70,84,72,stroke,1.1))
        case "r_d_guard":
            return stack(path("M67 70L74 62L79 62L81 67L74 72L72 76Z","#9a9a85",stroke,1.45),
                         path("M74 64L78 64L79 66L75 68Z","#c3c2a9"))
        case "r_d_crisis":
            return radio(72,69,.64)
        case _:
            raise ValueError(f"Unknown staff job {role}")


def npc_art(room: Room, approved_eyes: str) -> tuple[dict[str,str], dict[str,tuple]]:
    staff = room.person
    shadow = ellipse(47,84,25,3.1,"#625347")
    boots = stack(path("M31 69Q36 68 46 70L53 69L61 73L63 80Q62 83 53 83L45 80L43 75L42 83L32 84L28 82Z",
                       "#54483a",ACTOR_INK,3),
                  path("M33 74H43L42 79L33 80ZM49 74H58L60 79L51 79Z","#6b5848"))
    torso = stack(path("M35 48Q43 45 55 48Q66 51 64 65L64 75Q61 78 50 77L31 75Q26 73 29 63Z",
                        staff.outfit,ACTOR_INK,3.05),
                  path("M33 60L40 52L51 54L61 52L61 68Q53 72 31 70Z",staff.cuff),
                  path("M41 50L49 54L55 51L51 60Z",staff.skin,ACTOR_INK,1.5),
                  path("M30 70H62L62 75H33Z","#5d5544",ACTOR_INK,1.55),
                  rect(49,71,6,4,"#cfb786",ACTOR_INK,1,1),
                  path("M43 60L45 68M54 60L55 68","none",staff.outfit,1.5))
    left = stack(path("M34 55Q27 55 25 64Q24 69 29 72Q34 73 36 67L38 59Z",
                      staff.outfit,ACTOR_INK,2.6),
                 path("M25 65L33 67L32 72Q28 75 24 71Z",staff.skin,ACTOR_INK,2.25),
                 path("M27 64L33 66","none",staff.cuff,1.5))
    active = stack(path("M52 57Q53 52 59 53Q63 56 64 62L68 64L68 70L61 73L56 67Z",
                        staff.outfit,ACTOR_INK,2.75),
                   path("M55 60L61 61L65 66L61 70L56 66Z",staff.cuff,ACTOR_INK,1.4),
                   path("M64 64Q70 63 71 69Q71 73 66 73Q61 72 62 67Z",staff.skin,ACTOR_INK,2.05))
    art = {"shadow":shadow,"legs":boots,"torso":torso,"passive_arm":left,
           "hand":active,"work_prop":npc_prop(room.key),"head":npc_head(staff,approved_eyes),"gear":badge_graphic(staff.feature)}
    pivots = {
        "shadow": ((48,84), None), "legs": ((48,74), None), "torso": ((48,67),None),
        "passive_arm": ((34,58),"torso"), "hand": ((58,57),"torso"), "work_prop": ((67,69),"hand"),
        "head": ((48,52),"torso"), "gear": ((48,52),"head")
    }
    return art,pivots


def approved_eyes() -> str:
    """Preserve the registered dark eye marks from the accepted E02 face."""
    manifest = json.loads((ROOT / "assets/source-art/enemies/e02/manifest.json").read_text())
    head = next(part for part in manifest["parts"] if part["id"] == "head")
    left, top = head["canvas_rect_px"][:2]
    with Image.open(ROOT / head["png"]) as source:
        face = source.convert("RGBA")
    strips = []
    for x, y, width, height in [(47, 39.5, 3.25, 8.1), (58.4, 39.7, 3, 8.1)]:
        crop = face.crop((round(x * 4) - left, round(y * 4) - top,
                          round((x + width) * 4) - left, round((y + height) * 4) - top))
        alpha = Image.new("L", crop.size)
        alpha.putdata([round(a * max(0, min(1, (164 - r) / 108))) for r, _, _, a in crop.getdata()])
        tint = Image.new("RGBA", crop.size, ACTOR_INK)
        tint.putalpha(alpha)
        data = BytesIO()
        tint.save(data, format="PNG", optimize=True)
        uri = "data:image/png;base64," + b64encode(data.getvalue()).decode("ascii")
        strips.append(f'<image x="{x}" y="{y+1.5}" width="{width}" height="{height}" xlink:href="{uri}"/>')
    return stack(*strips)


def cutout(source: Path, name, path, temp) -> tuple[dict, Image.Image]:
    raw = render(source, temp / "npc.png", 384, name)
    bounds = raw.getbbox()
    assert bounds is not None, name
    crop = (bounds[0] - 4, bounds[1] - 4, bounds[2] + 4, bounds[3] + 4)
    assert 0 <= crop[0] < crop[2] <= 384 and 0 <= crop[1] < crop[3] <= 384, (name, crop)
    out = raw.crop(crop)
    path.parent.mkdir(parents=True, exist_ok=True)
    out.save(path, optimize=True)
    return dict(receipt(path), canvas_rect_px=[*crop[:2], *out.size]), raw


def animation_track(i, path, length, values):
    times = ', '.join(fmt(length * normalized) for normalized in (0, .24, .43, .64, 1))
    degrees = ', '.join(fmt(value) for value in values)
    return stack(f'tracks/{i}/type = "value"', f'tracks/{i}/path = NodePath("{path}:rotation_degrees")',
                 f'tracks/{i}/keys = {{',
                 f'"times": PackedFloat32Array({times}),',
                 '"transitions": PackedFloat32Array(1, 1, 1, 1, 1),',
                 f'"update": 0,\n"values": [{degrees}]\n}}')


def rig_text(id, records, staff) -> str:
    rig = build_cutout(dict(parts=records, godot_units_per_png_pixel=.25, ground_anchor_units=[48,84]),
                       "res://unused.gd", id)
    rig = rig.replace(f"load_steps={len(records)+2}", f"load_steps={len(records)+3}")
    rig = '\n'.join(line for line in rig.splitlines()
                    if 'path="res://unused.gd"' not in line and 'script = ExtResource("rig")' not in line)
    length = staff.period
    anim = stack('[sub_resource type="Animation" id="Work"]', 'resource_name = "Work"',
                 f'length = {fmt(length)}', 'loop_mode = 1',
                 animation_track(0, 'Facing/Skeleton/torso/head', length, (0,staff.head_primary,staff.head_primary*.6,-1,0)),
                 animation_track(1, 'Facing/Skeleton/torso/hand', length, (0,staff.arm_primary,staff.arm_primary*.7,1,0)),
                 '[sub_resource type="AnimationLibrary" id="StaffLoops"]\n_data = { &"Work": SubResource("Work") }', '')
    first_node = rig.index('[node ')
    rig = rig[:first_node] + anim + '\n' + rig[first_node:]
    return rig + '\nlibraries = {&"": SubResource("StaffLoops")}\nautoplay = "Work"\n'


def room_asset(room, eyes, temp):
    source = SOURCE / "rooms" / room.key
    imported = IMPORT / "rooms" / room.key
    imported.mkdir(parents=True, exist_ok=True)
    back, front = room_contents(room.key)
    layers = {"back": room_backdrop(room.accent) + back, "front": front}
    save_svg(source / "interior.svg", (ROOM_W, ROOM_H), layers)
    plates = {}
    rasters = {}
    for layer in layers:
        path_out = imported / f"{layer}.png"
        rasters[layer] = render(source / "interior.svg", path_out, ROOM_W * 2, layer)
        plates[layer] = receipt(path_out)

    art, pivots = npc_art(room, eyes)
    save_svg(source / "staff.svg", (96,96), art)
    parts = []
    assembled = Image.new("RGBA", (384,384))
    for order, name in enumerate(art, 1):
        texture = imported / "staff" / f"{name}.png"
        record, rgba = cutout(source / "staff.svg", name, texture, temp)
        assembled.alpha_composite(rgba)
        pivot, parent = pivots[name]
        parts.append(dict(record, id=name, parent=parent, pivot_canvas_units=list(pivot), draw_order=order,
                          png=record["texture"], pivot_local_px=[4*axis-start for axis,start in zip(pivot,record["canvas_rect_px"][:2])]))
    rig = imported / "staff.tscn"
    rig.write_text(rig_text('Staff_' + room.key, parts, room.person))
    staff = dict(role=room.person.job, uniform=room.person.feature, action=room.person.action,
                 anchor_in_room=list(room.anchor), scale=ART_UNIT_SCALE,
                 duration=room.person.period, clip="Work", rig=rig.relative_to(ROOT).as_posix(),
                 ground_anchor_units=[48,84], layers=parts,
                 source=(source / "staff.svg").relative_to(ROOT).as_posix())

    sheet = rasters["back"].copy()
    staff_size = round(96 * ART_UNIT_SCALE * 2)
    staff_image = assembled.resize((staff_size, staff_size), Image.Resampling.LANCZOS)
    left = round(room.anchor[0]*2 - staff_size * .5)
    top = round(room.anchor[1]*2 - staff_size * 84 / 96)
    sheet.alpha_composite(staff_image, (left,top))
    sheet.alpha_composite(rasters["front"])
    output = imported / "interior.png"
    sheet.save(output, optimize=True)
    return dict(id=f"room.{room.key}", name=room.label, storyboard=room.page, assets=plates, staff=staff,
                detail=receipt(output), source=(source / "interior.svg").relative_to(ROOT).as_posix()), sheet


def position(index):
    return (ORIGIN[0]+index%3*STEP[0], ORIGIN[1]+index//3*STEP[1])


def render_exterior():
    layers = exterior_layers()
    save_svg(SOURCE / "shell.svg", (BOARD_W,BOARD_H), layers)
    plates = {}
    rasters = {}
    for layer in layers:
        destination = IMPORT / "shell" / (layer + ".png")
        rasters[layer] = render(SOURCE / "shell.svg", destination, BOARD_W, layer)
        plates[layer] = receipt(destination)
    return plates, rasters


def overview(shell, rooms, unbuilt, built_count, target):
    result = shell["jungle"].copy()
    for name in ("roof","frame_back","lobby"):
        result.alpha_composite(shell[name])
    for index, layer in enumerate([*rooms,unbuilt]):
        use = layer if index < built_count else unbuilt
        result.alpha_composite(use.resize((ROOM_W,ROOM_H), Image.Resampling.LANCZOS), position(index))
    result.alpha_composite(shell["frame_front"])
    result.alpha_composite(shell["foreground"])
    result.save(target, optimize=True)


def detail_review(details):
    fill = "#f1e5cc"
    sheet = Image.new("RGB", (1280,810),fill)
    draw = ImageDraw.Draw(sheet)
    font = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    bold = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
    draw.text((35,18),"Headquarters room art and work loops",font=ImageFont.truetype(bold,29),fill=INK)
    for index,(room,art) in enumerate(zip(ROOMS,details,strict=True)):
        x,y=35+index%3*415,72+index//3*176
        crop=art.resize((382,128),Image.Resampling.LANCZOS)
        sheet.paste(crop,(x,y),crop.getchannel("A"))
        draw.text((x+1,y+130),room.label,font=ImageFont.truetype(bold,16),fill=INK)
        draw.text((x+1,y+150),room.person.action,font=ImageFont.truetype(font,13),fill="#544938")
    sheet.save(REVIEW/"room_review.png", optimize=True)


def build():
    for directory in (SOURCE, IMPORT, REVIEW):
        directory.mkdir(parents=True,exist_ok=True)
    (SOURCE / ".gdignore").touch()
    (REVIEW / ".gdignore").touch()
    spec = (ROOT / "data/headquarters/rooms.tres").read_text()
    assert re.findall(r'^id = &"room\.(.*?)"',spec,re.M) == [room.key for room in ROOMS]
    plates, shell = render_exterior()
    save_svg(SOURCE/"unbuilt.svg",(ROOM_W,ROOM_H),{"unbuilt":room_unbuilt()})
    unbuilt_path=IMPORT/"unbuilt.png"
    unbuilt=render(SOURCE/"unbuilt.svg",unbuilt_path,ROOM_W*2)
    with TemporaryDirectory(prefix="w29-hq-") as temp:
        eyes = approved_eyes()
        rendered = [room_asset(room, eyes, Path(temp)) for room in ROOMS]
    rooms, details = zip(*rendered)
    for index, record in enumerate(rooms):
        record["overview_hit_rect"] = [*position(index), ROOM_W, ROOM_H]
    overview(shell,details,unbuilt,len(ROOMS),IMPORT/"overview.png")
    overview(shell,details,unbuilt,3,IMPORT/"opening.png")
    detail_review(details)
    manifest = {
        "schema_version":1,"canvas_units":[BOARD_W,BOARD_H],"created":"2026-11-24",
        "origin":"Original W29 Kenyalang Rangers art. Eyes reference the approved E02 sheet. D-014 release review pending.",
        "references":["UI pp. 12, 38–68, 109–110","GDD §§ M.1–3","data/headquarters/rooms.tres"],
        "shell":plates,"unbuilt":receipt(unbuilt_path),
        "reception_emblem": RECEPTION_EMBLEM.relative_to(ROOT).as_posix(),
        "overview":receipt(IMPORT/"overview.png"),"opening":receipt(IMPORT/"opening.png"),
        "trophy_anchor":[918,636],"trophy_max_size":[57,48],
        "draw_order":["jungle","roof","frame_back","lobby","room_back","staff","room_front","frame_front","foreground","controls"],
        "staff_rule":"Stationary, shape-matched work loops. Keep root at its authored post; separate playback from purchases, Funds and stock state.",
        "rooms":list(rooms)
    }
    store(SOURCE/"manifest.json",manifest)
    print(f"{len(ROOMS)} room sets including eight registered staff parts and one Work loop per room.")


if __name__ == "__main__":
    build()
