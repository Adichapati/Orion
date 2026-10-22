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


def render(w, angle_deg):
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
                    m = material(u, v, w)
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
    if preview:
        sheet = Image.new("RGBA", (CELL * ANGLES, CELL * len(rows)), (40, 38, 64, 255))
        for i, r in enumerate(rows):
            sheet.alpha_composite(r, (0, i * CELL))
        sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(preview / "swords_x2.png")


if __name__ == "__main__":
    main()
