"""Draw Cedalion's swords as pixel-art sprite strips, one per weapon, pre-rotated to 32 angles.

The game draws the sword as its own sprite on Cedalion's sword hand (the body frames are cut
sword-free by tools/process_sheet.py), so it can be hidden while he's unarmed, swung
in an arc and changed per weapon. Pre-rotating here keeps every angle crisp: each angle is
rendered from the sword's shape with 8x8 supersampling, then outlined in the sheet's dark ink.

Writes art/final/sword_<weapon>.png: 32 cells of 32x32 in a row. Cell i points the blade at
i * 11.25 degrees (0 = screen right, clockwise, since screen y grows down); the grip is at the
cell's centre pixel (16, 16).

    python tools/gen_swords.py [preview dir]
"""
from pathlib import Path
import math
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "final"
CELL = 32
ANGLES = 32
SS = 8

INK = (36, 22, 18)
GRIP = (92, 54, 32)
BRONZE = ((240, 186, 132), (198, 126, 84))
STEEL = ((226, 232, 240), (146, 156, 176))
GOLD = (222, 168, 52)
SILVER = (200, 206, 216)

# id: blade length (px from the guard), half-width, blade colours (light edge, body), hilt colour,
# curve (px the tip bends forward, for the kopis), guard half-length
WEAPONS = {
    "xiphos": dict(length=11.0, half=1.1, blade=BRONZE, hilt=GOLD, curve=0.0, guard=2.6),
    "dagger": dict(length=6.5, half=1.0, blade=BRONZE, hilt=GOLD, curve=0.0, guard=2.0),
    "kopis": dict(length=11.0, half=1.25, blade=STEEL, hilt=SILVER, curve=1.6, guard=2.2),
    "longsword": dict(length=14.5, half=1.1, blade=STEEL, hilt=GOLD, curve=0.0, guard=3.2),
}


def material(u, v, w):
    """What lies at (u, v): u along the blade from the guard, v across it (positive = the blade's
    back). Returns a colour or None."""
    L, half, curve = w["length"], w["half"], w["curve"]
    # pommel and grip behind the guard
    if -4.2 <= u < -3.0 and abs(v) <= 0.9:
        return w["hilt"]
    if -3.0 <= u < 0.0 and abs(v) <= 0.65:
        return GRIP
    if 0.0 <= u < 1.0 and abs(v) <= w["guard"]:
        return w["hilt"]
    if 1.0 <= u <= L:
        k = (u - 1.0) / (L - 1.0)
        bend = curve * k * k
        vv = v + bend
        # straight edges, tapering to a point over the last 2.5 px; the kopis widens toward the tip
        hw = half * (1.0 + 0.35 * curve * k)
        if u > L - 2.5:
            hw *= (L - u) / 2.5
        if abs(vv) <= hw:
            return w["blade"][0] if vv < 0 else w["blade"][1]
    return None


def render(w, angle_deg, mat=material):
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    px = img.load()
    c = CELL // 2
    for y in range(CELL):
        for x in range(CELL):
            votes = {}
            n = 0
            for sy in range(SS):
                for sx in range(SS):
                    dx = x + (sx + 0.5) / SS - (c + 0.5)
                    dy = y + (sy + 0.5) / SS - (c + 0.5)
                    # rotate into the blade's frame
                    u = dx * ca + dy * sa
                    v = -dx * sa + dy * ca
                    m = mat(u, v, w)
                    if m:
                        votes[m] = votes.get(m, 0) + 1
                        n += 1
            if n >= SS * SS * 0.38:
                px[x, y] = max(votes, key=votes.get) + (255,)
    # outline in ink
    edge = []
    for y in range(CELL):
        for x in range(CELL):
            if px[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < CELL and 0 <= ny < CELL and px[nx, ny][3] and px[nx, ny][:3] != INK:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = INK + (255,)
    return img


def main():
    preview = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for wid, w in WEAPONS.items():
        strip = Image.new("RGBA", (CELL * ANGLES, CELL), (0, 0, 0, 0))
        for i in range(ANGLES):
            strip.alpha_composite(render(w, i * 360.0 / ANGLES), (i * CELL, 0))
        strip.save(OUT / f"sword_{wid}.png")
        rows.append(strip)
        print(f"sword_{wid}.png")
    rows += hafted_weapons()
    item_icons()
    if preview:
        sheet = Image.new("RGBA", (CELL * ANGLES, CELL * len(rows)), (40, 38, 64, 255))
        for i, r in enumerate(rows):
            sheet.alpha_composite(r, (0, i * CELL))
        sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(preview / "swords_x2.png")


# ---------------------------------------------------------------- hafted weapons (appended)
# The bronze labrys (a Greek double axe) and the iron koryne (a flanged mace), after Sathvik's
# armour sheet and weapons reference: a grey metal head with a dark rim and a pale highlight, a
# brown haft with red wraps and gold bands, and a gold pommel. Same strip format as the swords:
# the hand is the cell's centre and the haft runs out along the angle, head last. ORION colours.

NIGHT2 = (46, 58, 92)
MARBLE0 = (125, 119, 109)
MARBLE1 = (185, 178, 163)
MOON1 = (207, 227, 255)
SILVER_P = (183, 193, 201)
HAFT = (92, 59, 46)        # Skin 0, the darker wood
HAFT_LIT = (156, 106, 76)  # Skin 1, the lit side of the haft
WRAP = (194, 59, 59)       # Scorpion 1
GOLD_P = (217, 164, 58)
BRONZE_P = (168, 105, 58)


def haft(u, v, top, wraps, bands):
    """The shared grip: a gold pommel, a wooden haft up to `top`, red wraps and gold bands as
    (from, to) spans along it."""
    if -4.4 <= u < -3.0 and abs(v) <= 1.05:
        return GOLD_P
    if -3.0 <= u < top and abs(v) <= 0.7:
        for a, b in bands:
            if a <= u < b:
                return GOLD_P
        for a, b in wraps:
            if a <= u < b:
                return WRAP
        return HAFT_LIT if v < 0 else HAFT
    return None


def labrys(u, v, w):
    """A double-bitted axe: two crescent bits either side of a socket near the haft's end, and a
    short spike past them."""
    c = 9.6  # the head's centre along the haft
    av = abs(v)
    # the spike beyond the head
    if c + 1.6 <= u <= c + 4.0 and av <= 0.75 * (c + 4.0 - u) / 2.4 + 0.15:
        return SILVER_P
    # the socket that grips the haft
    if c - 1.8 <= u <= c + 1.6 and av <= 1.15:
        return MARBLE1 if v > 0 else SILVER_P
    # the bits: narrow at the socket, flaring out to a curved edge
    if 1.0 < av <= 5.6:
        k = (av - 1.0) / 4.6
        hw = 1.1 + 2.6 * k * k
        edge = 5.6 - 0.88 * ((u - c) / max(hw, 0.1)) ** 2
        if abs(u - c) <= hw and av <= edge:
            if av > edge - 0.9:
                return NIGHT2 if v > 0 else MARBLE0
            if v < 0 and 2.2 <= av <= 3.0 and u < c + 0.4:
                return MOON1
            return SILVER_P if v < 0 else MARBLE1
    return haft(u, v, c - 1.8, wraps=((-2.4, -0.6), (2.4, 4.2)), bands=((-0.6, 0.2), (4.2, 5.0)))


def koryne(u, v, w):
    """A flanged mace: a heavy round head with studs, on a shorter haft."""
    c = 9.2
    du = u - c
    r = math.hypot(du, v)
    # studs round the head: forward, both sides and the two forward diagonals
    for sa in (0.0, 1.0, -1.0, 0.55, -0.55):
        ang = sa * math.pi / 2.0
        sx, sy = math.cos(ang), math.sin(ang)
        along = du * sx + v * sy
        across = abs(-du * sy + v * sx)
        if 2.4 <= along <= 4.0 and across <= 0.9 * (4.0 - along) / 1.6 + 0.1:
            return SILVER_P if along < 3.4 else MARBLE0
    if r <= 2.9:
        if r > 2.15:
            return NIGHT2 if v > 0 or du > 1.6 else MARBLE0
        if v < -0.4 and du < 0.6 and r < 1.7:
            return MOON1
        return SILVER_P if v <= 0.5 else MARBLE1
    # the collar under the head
    if c - 3.6 <= u < c - 2.5 and abs(v) <= 1.2:
        return GOLD_P
    return haft(u, v, c - 2.5, wraps=((-2.4, -0.6), (2.0, 3.6)), bands=((-0.6, 0.2), (3.6, 4.3)))


HAFTED = {
    "labrys": labrys,
    "koryne": koryne,
}


def hafted_weapons():
    rows = []
    for wid, mat in HAFTED.items():
        strip = Image.new("RGBA", (CELL * ANGLES, CELL), (0, 0, 0, 0))
        for i in range(ANGLES):
            strip.alpha_composite(render({}, i * 360.0 / ANGLES, mat), (i * CELL, 0))
        strip.save(OUT / f"sword_{wid}.png")
        rows.append(strip)
        print(f"sword_{wid}.png")
    return rows


# Shop icons for the new goods, 12x12 like the grey-box ones (tools/gen_greybox.py), written to
# art/final (nothing there has these names yet).
ICON_COLOURS = {"k": INK, "s": SILVER_P, "S": MOON1, "m": MARBLE1, "d": MARBLE0, "n": NIGHT2,
                "h": HAFT, "H": HAFT_LIT, "r": WRAP, "g": GOLD_P, "b": BRONZE_P}
ICONS = {
    "item_labrys": [
        "..kk...kk...", ".kSsk.kssk..", "kSssskkssmk.", "kSsskssksmk.", ".kskskksmk..", "..kkHgkkk...",
        ".kk.kHk.....", "....krk.....", "....kHk.....", "....kgk.....", "....kHk.....", "....kgk.....",
    ],
    "item_koryne": [
        "....kk......", "..kkSskk....", ".kSSsssmk...", "kSSssssmdk..", ".kssssmmk...", "..kkmmkk....",
        "....kgk.....", "....kHk.....", "....krk.....", "....kHk.....", "....kgk.....", "....kgk.....",
    ],
    "item_mail": [
        "............", "..kkk..kkk..", ".kssskkssk..", "ksmsmsmsmsk.", "kdksmsmsmkdk", ".k.kmsmsk.k.",
        "...ksmsmk...", "...kmsmsk...", "...khhhhk...", "...ksmsmk...", "...kmsmsk...", "...kkkkkk...",
    ],
}


def item_icons():
    for name, grid in ICONS.items():
        img = Image.new("RGBA", (12, 12), (0, 0, 0, 0))
        for y, row in enumerate(grid):
            assert len(row) == 12, (name, y)
            for x, ch in enumerate(row):
                if ch != ".":
                    img.putpixel((x, y), ICON_COLOURS[ch] + (255,))
        img.save(OUT / f"{name}.png")
        print(f"{name}.png")


if __name__ == "__main__":
    main()
