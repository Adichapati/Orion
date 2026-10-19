"""Generate ORION's grey-box art: floor tiles, blocks, props, UI icons and light textures.

Everything is drawn in the ORION palette (art/palette/orion.gpl) so the prototype reads like the
mock-ups in art/maps. These are placeholders: replace any PNG in art/greybox/ with real art of the
same size and pivot, or point scripts/core/art.gd at a new file.

    python tools/gen_greybox.py
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math
import random

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "greybox"
OUT.mkdir(parents=True, exist_ok=True)


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


P = {k: hexc(v) for k, v in {
    "night0": "0d0b1a", "night1": "1b1834", "night2": "2e3a5c", "moon0": "7fa6d8", "moon1": "cfe3ff",
    "fire0": "7a2a1a", "fire1": "e0782c", "fire2": "ffc857", "fire3": "fff1c1",
    "marble0": "7d776d", "marble1": "b9b2a3", "marble2": "e8e2d4",
    "clay0": "8a3b22", "clay1": "c0603a", "clay2": "d9935f", "black": "1a1412",
    "aegean0": "2b5d8a", "aegean1": "4f8fbf", "pool": "5fb3b0",
    "olive0": "3a4a2a", "olive1": "5d6b3a", "olive2": "8c9a5b",
    "scorp0": "8e1b2a", "scorp1": "c23b3b", "bronze": "a8693a", "silver": "b7c1c9", "gold": "d9a43a",
    "skin1": "9c6a4c", "leather": "4a3326",
}.items()}
CLEAR = (0, 0, 0, 0)
random.seed(7)


def save(img, name):
    img.save(OUT / f"{name}.png")


def diamond(draw, ox, oy, fill, w=32, h=16, outline=None):
    """2:1 pixel diamond whose bounding box top-left is (ox, oy)."""
    hw, hh = w // 2, h // 2
    pts = [(ox + hw - 1, oy), (ox + hw, oy), (ox + w - 1, oy + hh - 1), (ox + w - 1, oy + hh),
           (ox + hw, oy + h - 1), (ox + hw - 1, oy + h - 1), (ox, oy + hh), (ox, oy + hh - 1)]
    draw.polygon(pts, fill=fill, outline=outline)


def floor_tile(base, seam, name, extra=None):
    img = Image.new("RGBA", (32, 16), CLEAR)
    d = ImageDraw.Draw(img)
    diamond(d, 0, 0, base)
    # seam on the two lower edges gives the grid a gentle read
    for i in range(16):
        img.putpixel((16 + i, 15 - i // 2), seam)
        img.putpixel((15 - i, 15 - i // 2), seam)
    if extra:
        extra(img, d)
    save(img, name)


def block(name, h, top, left, right, edge=None, top_extra=None, side_extra=None):
    """A block standing on a 32x16 footprint. Texture is 32 x (16 + h); ground diamond centre at (16, h + 8)."""
    img = Image.new("RGBA", (32, 16 + h), CLEAR)
    d = ImageDraw.Draw(img)
    # left face, right face, then top
    d.polygon([(0, 8), (16, 16), (16, 16 + h), (0, 8 + h)], fill=left)
    d.polygon([(16, 16), (31, 8), (31, 8 + h), (16, 16 + h)], fill=right)
    diamond(d, 0, 0, top)
    if edge:
        for i in range(16):
            img.putpixel((i, 8 + i // 2), edge)
            img.putpixel((16 + i, 15 - i // 2), edge)
    if side_extra:
        side_extra(img, d, h)
    if top_extra:
        top_extra(img, d)
    save(img, name)


def crack(img, seed, n=2):
    """A jagged crack across the slab: a dark core with a lit lower lip and a shadowed upper one,
    a branch or two, and on the worst slabs a chipped-out flake."""
    rnd = random.Random(seed)
    core, lip, shade = hexc("4a4540"), P["marble2"], P["marble0"]

    def inside(x, y):
        return 1 < x < 30 and 1 < y < 14 and img.getpixel((x, y))[3] > 0 and img.getpixel((x, y))[:3] != shade[:3]

    def walk(x, y, dx, steps, slope):
        """Steps along x, drifting on the floor's diagonal (slope ±0.5) with a little jitter."""
        pts, fy, j = [], float(y), 0
        for _ in range(steps):
            pts.append((x, int(round(fy)) + j))
            x += dx
            fy += slope * dx
            if rnd.random() < 0.3:
                j = max(-1, min(1, j + rnd.choice([-1, 1])))
        return pts

    slope = rnd.choice([-0.5, 0.5])
    x0 = rnd.randint(7, 10)
    y0 = 10 if slope < 0 else 4
    main = walk(x0, y0 + rnd.randint(-1, 1), 1, rnd.randint(12, 15), slope)
    lines = [main]
    for _ in range(n - 1):
        bx, by = main[rnd.randint(3, len(main) - 3)]
        lines.append(walk(bx, by, rnd.choice([-1, 1]), rnd.randint(3, 5), -slope))
    for pts in lines:
        for x, y in pts:
            if inside(x, y + 1) and rnd.random() < 0.45:
                img.putpixel((x, y + 1), lip)
            if inside(x, y - 1) and rnd.random() < 0.3:
                img.putpixel((x, y - 1), shade)
        for x, y in pts:
            if inside(x, y):
                img.putpixel((x, y), core)
    if n >= 4:  # a flake has come away
        fx, fy = main[len(main) // 2]
        for x, y in [(fx - 1, fy), (fx, fy), (fx + 1, fy), (fx, fy + 1), (fx + 1, fy + 1)]:
            if inside(x, y):
                img.putpixel((x, y), P["night1"])
        for x, y in [(fx - 1, fy + 1), (fx + 2, fy + 1), (fx, fy + 2), (fx + 1, fy + 2)]:
            if inside(x, y):
                img.putpixel((x, y), lip)


# ---------------------------------------------------------------- floors
floor_tile(P["marble1"], P["marble0"], "floor_marble")
floor_tile(P["marble2"], P["marble1"], "floor_moon")
floor_tile(hexc("a8a093"), P["marble0"], "floor_marble_dark")
for i in range(3):
    floor_tile(P["marble1"], P["marble0"], f"floor_cracked_{i}", lambda img, d, s=i: crack(img, 21 + s, 2 + s))
floor_tile(P["clay2"], P["clay1"], "floor_door")

# Plain-floor variants so a hall isn't one stamp repeated. None of them may look like a crack:
# cracked slabs are a hazard and have to stand out.
def _in_slab(img, x, y):
    return 1 < x < 30 and 1 < y < 14 and img.getpixel((x, y))[3] > 0 and img.getpixel((x, y))[:3] != P["marble0"][:3]


def worn(img, d):
    """A smoothed, paler patch where feet have polished the slab (checker dither)."""
    rnd = random.Random(31)
    cx, cy = rnd.randint(12, 19), rnd.randint(6, 9)
    for y in range(16):
        for x in range(32):
            if ((x - cx) / 7.0) ** 2 + ((y - cy) / 3.2) ** 2 < 1 and (x + y) % 2 == 0 and _in_slab(img, x, y):
                img.putpixel((x, y), hexc("cbc4b5"))


def stained(img, d):
    """A darker water stain, dithered at its edge."""
    cx, cy = 18, 7
    for y in range(16):
        for x in range(32):
            r = ((x - cx) / 5.0) ** 2 + ((y - cy) / 2.4) ** 2
            if (r < 0.45 or (r < 1 and (x + y) % 2 == 0)) and _in_slab(img, x, y):
                img.putpixel((x, y), hexc("aea697"))


def moss(img, d):
    """Moss creeping out of the lower seams."""
    rnd = random.Random(41)
    for i in range(16):
        for (x, y) in ((16 + i, 14 - i // 2), (15 - i, 14 - i // 2)):
            if rnd.random() < 0.45 and _in_slab(img, x, y):
                img.putpixel((x, y), P["olive1"] if rnd.random() < 0.7 else P["olive2"])
                if rnd.random() < 0.3 and _in_slab(img, x, y - 1):
                    img.putpixel((x, y - 1), P["olive0"])


def leaves(img, d):
    """Two fallen olive leaves."""
    for (x, y, flip) in ((11, 6, False), (20, 9, True)):
        pts = [(x, y), (x + 1, y), (x + 2, y + 1), (x + 3, y + 1)] if not flip else [(x, y + 1), (x + 1, y + 1), (x + 2, y), (x + 3, y)]
        for i, (px, py) in enumerate(pts):
            if _in_slab(img, px, py):
                img.putpixel((px, py), P["olive2"] if i < 2 else P["olive1"])


floor_tile(P["marble1"], P["marble0"], "floor_marble_worn", worn)
floor_tile(P["marble1"], P["marble0"], "floor_marble_stain", stained)
floor_tile(P["marble1"], P["marble0"], "floor_marble_moss", moss)
floor_tile(P["marble1"], P["marble0"], "floor_marble_leaves", leaves)
floor_tile(P["aegean0"], P["night2"], "water_deep",
           lambda img, d: [img.putpixel((x, y), P["aegean1"]) for x, y in [(8, 7), (9, 7), (20, 5), (21, 5), (14, 10), (15, 10)]])
floor_tile(P["aegean1"], P["aegean0"], "water_shallow",
           lambda img, d: [img.putpixel((x, y), P["moon1"]) for x, y in [(10, 6), (11, 6), (22, 8), (23, 8)]])


def pit_extra(img, d):
    diamond(d, 4, 2, P["night0"], 24, 12)


floor_tile(P["night2"], P["night1"], "pit", pit_extra)


def seven_dots(img, d):
    for x, y in [(10, 6), (13, 5), (16, 6), (19, 5), (22, 6), (15, 9), (18, 9)]:
        img.putpixel((x, y), P["moon1"])


floor_tile(P["marble1"], P["marble0"], "floor_mark", seven_dots)

# ---------------------------------------------------------------- blocks
# The shadowed (right) face is a blue-grey stone rather than night blue: in the dark rooms night
# blue went near-black and made cut-away walls and raised floors read as holes.
WALL_TOP, WALL_L, WALL_R, EDGE = hexc("a39b8c"), hexc("8a8478"), hexc("5a576b"), hexc("6f695f")


def wall_joints(img, d, h):
    for yy in range(16, 8 + h, 8):
        for i in range(16):
            y = yy + i // 2 - 8 + 8
            if 0 <= y < img.height and img.getpixel((i, min(y, img.height - 1)))[3] > 0:
                pass
    # horizontal courses on the left face
    for k in range(1, h // 8 + 1):
        for i in range(16):
            y = 8 + i // 2 + k * 8
            if y < 8 + h + i // 2 and y < img.height:
                img.putpixel((i, y), hexc("7a7468"))


block("wall_tall", 32, WALL_TOP, WALL_L, WALL_R, EDGE, side_extra=wall_joints)
block("wall_low", 8, WALL_TOP, WALL_L, WALL_R, EDGE)


def ivy(img, d, h):
    rnd = random.Random(5)
    for _ in range(40):
        x, y = rnd.randint(1, 30), rnd.randint(10, 8 + h)
        if img.getpixel((x, y))[3] > 0:
            img.putpixel((x, y), rnd.choice([P["olive1"], P["olive2"], P["olive0"]]))


block("wall_tall_ivy", 32, WALL_TOP, WALL_L, WALL_R, EDGE, side_extra=lambda img, d, h: (wall_joints(img, d, h), ivy(img, d, h)))


def lion_gate():
    """The Lion Gate over a two-cell doorway in a wall that runs down-right (along grid x): a
    lintel across the opening and the relieving triangle above it, two lions rampant on either
    side of a column. Drawn flat in the wall's plane, then sheared half a pixel down per pixel
    right to lie on the wall's lit face. The pixel at (PAD, H + PAD // 2) sits on the doorway's
    west ground corner."""
    pad, open_w, wall_h = 4, 32, 32
    W, H = open_w + 2 * pad, wall_h + 26
    flat = Image.new("RGBA", (W, H), CLEAR)
    f = ImageDraw.Draw(flat)
    stone, stone_l, carve, deep = hexc("a8a093"), P["marble1"], P["marble0"], hexc("5f5a52")

    def v(y):  # height above the ground -> row
        return H - 1 - y
    # lintel: a heavy block across the top of the opening, resting on the jambs
    f.rectangle([0, v(wall_h + 1), W - 1, v(wall_h - 6)], fill=stone_l)
    f.line([(0, v(wall_h + 1)), (W - 1, v(wall_h + 1))], fill=P["marble2"])
    f.line([(0, v(wall_h - 5)), (W - 1, v(wall_h - 5))], fill=carve)
    f.line([(0, v(wall_h - 6)), (W - 1, v(wall_h - 6))], fill=deep)
    f.line([(pad, v(wall_h - 7)), (pad + open_w - 1, v(wall_h - 7))], fill=deep)
    # jamb edges inside the opening
    for x in (pad - 1, pad + open_w):
        f.line([(x, v(wall_h - 7)), (x, v(0))], fill=EDGE)
    # relieving triangle
    base, top = wall_h + 2, wall_h + 24
    cx = W // 2
    # a dark frame (the relieving gap) around the relief slab
    f.polygon([(cx - 17, v(base)), (cx + 16, v(base)), (cx, v(top + 2))], fill=deep)
    f.polygon([(cx - 15, v(base)), (cx + 14, v(base)), (cx, v(top))], fill=stone)
    f.line([(cx - 15, v(base)), (cx, v(top))], fill=stone_l)
    f.line([(cx + 14, v(base)), (cx, v(top))], fill=carve)
    # the column between the lions, on a two-step altar
    f.rectangle([cx - 4, v(base + 2), cx + 3, v(base)], fill=carve)
    f.rectangle([cx - 1, v(base + 14), cx + 1, v(base + 3)], fill=stone_l)
    f.point((cx + 1, v(base + 8)), fill=carve)
    f.rectangle([cx - 3, v(base + 16), cx + 2, v(base + 15)], fill=carve)
    # two lions rampant, forepaws on the altar, facing the column: carved silhouettes
    for side in (-1, 1):
        def px(dx, dy, c=deep):
            x = cx + side * dx - (1 if side > 0 else 0)
            flat.putpixel((x, v(base + dy)), c)
        body = [(5, 3), (6, 3), (7, 4), (6, 4), (7, 5), (8, 5), (6, 5), (7, 6), (8, 6), (6, 6), (7, 7), (8, 7),
                (6, 7), (6, 8), (7, 8), (5, 8), (5, 9), (6, 9), (4, 9), (4, 10), (5, 10)]
        legs = [(9, 1), (9, 2), (8, 3), (10, 1), (8, 4), (4, 3), (3, 3), (3, 4)]
        head = [(3, 10), (3, 11), (4, 11), (2, 11), (3, 12), (4, 12)]
        tail = [(9, 6), (10, 7), (10, 8), (9, 9)]
        for dx, dy in body + legs + head + tail:
            px(dx, dy)
        for dx, dy in [(5, 4), (5, 5), (5, 6), (5, 7), (4, 8)]:
            px(dx, dy, carve)
    # shear onto the face
    out = Image.new("RGBA", (W, H + W // 2 + 1), CLEAR)
    for y in range(H):
        for x in range(W):
            c = flat.getpixel((x, y))
            if c[3]:
                out.putpixel((x, y + x // 2), c)
    save(out, "lion_gate")


lion_gate()


# The Brotherhood's mark: a red scorpion daubed over a scratched-out star fresco, sheared onto a
# wall's lit (left) face like the gate. The game mirrors it for right faces.
SCORPION = [
    "r..r....r..r",
    ".rr..s...rr.",
    "..r.rrrr.r..",
    ".s..rrrr..s.",
    "...rrrrrr...",
    "..s.rrrr.s..",
    ".....rr.....",
    "....s.rr....",
    ".......r.r..",
    "....d...rr..",
    "........d...",
]


def wall_scorpion():
    W, H = len(SCORPION[0]), len(SCORPION)
    out = Image.new("RGBA", (W, H + W // 2 + 1), CLEAR)
    cols = {"r": P["scorp1"], "d": P["scorp0"], "s": hexc("c9c2b2")}
    for y, row in enumerate(SCORPION):
        for x, ch in enumerate(row):
            if ch != ".":
                out.putpixel((x, y + x // 2), cols[ch])
    save(out, "wall_scorpion")


wall_scorpion()
# Raised floor (the portico): a lighter top than the floor below, so the level change reads.
block("raised", 16, P["marble2"], WALL_L, WALL_R, EDGE)


def stair_lines(img, d, h):
    for k in (2, 5):
        for i in range(16):
            img.putpixel((i, 8 + i // 2 + k), hexc("8a8478"))
            img.putpixel((16 + i, 15 - i // 2 + k), hexc("3b4870"))


block("steps", 8, P["marble1"], WALL_L, WALL_R, EDGE, side_extra=stair_lines)
block("stepping_stone", 4, P["marble1"], WALL_L, WALL_R)

# ---------------------------------------------------------------- props (pivot = bottom-centre unless noted)


def prop(name, w, h, painter):
    img = Image.new("RGBA", (w, h), CLEAR)
    d = ImageDraw.Draw(img)
    painter(img, d, w, h)
    save(img, name)


def column(img, d, w, h):
    cx = w // 2
    diamond(d, cx - 8, h - 9, P["marble0"], 16, 8)
    d.rectangle([cx - 4, 8, cx + 3, h - 5], fill=P["marble1"])
    d.rectangle([cx + 1, 8, cx + 3, h - 5], fill=hexc("9a9384"))
    for x in (cx - 3, cx - 1):
        d.line([(x, 9), (x, h - 6)], fill=P["marble2"])
    d.rectangle([cx - 6, 4, cx + 5, 7], fill=P["marble1"])
    diamond(d, cx - 7, 0, P["marble2"], 14, 7)


prop("column", 16, 60, column)


def statue(img, d, w, h):
    """A marble hoplite on a plinth: helmet and crest, round shield on his left arm, spear upright
    in his right. Lit from the left like everything else, with a dark outline so he reads on
    marble floors."""
    cx = w // 2
    # plinth
    d.rectangle([cx - 8, h - 12, cx + 7, h - 3], fill=WALL_L)
    d.rectangle([cx, h - 12, cx + 7, h - 3], fill=WALL_R)
    diamond(d, cx - 8, h - 16, P["marble1"], 16, 8)
    fig = Image.new("RGBA", (w, h), CLEAR)
    f = ImageDraw.Draw(fig)
    L, M, D = P["marble2"], P["marble1"], P["marble0"]
    base = h - 13  # feet on the plinth top
    # spear behind everything, in his right hand (screen right)
    f.line([(cx + 6, base - 33), (cx + 6, base)], fill=D)
    f.point((cx + 6, base - 34), fill=M)
    # legs
    f.rectangle([cx - 3, base - 9, cx - 2, base - 1], fill=L)
    f.rectangle([cx + 1, base - 9, cx + 2, base - 1], fill=M)
    f.point((cx + 2, base - 1), fill=D)
    # skirt of the chiton
    f.polygon([(cx - 4, base - 9), (cx + 3, base - 9), (cx + 4, base - 12), (cx - 4, base - 12)], fill=L)
    f.line([(cx + 2, base - 9), (cx + 3, base - 12)], fill=D)
    # torso
    f.rectangle([cx - 4, base - 21, cx + 3, base - 12], fill=L)
    f.rectangle([cx + 1, base - 21, cx + 3, base - 12], fill=M)
    f.line([(cx + 3, base - 21), (cx + 3, base - 12)], fill=D)
    f.line([(cx - 3, base - 15), (cx + 2, base - 15)], fill=M)  # belt
    # right arm up to the spear
    f.line([(cx + 4, base - 20), (cx + 5, base - 16)], fill=M)
    f.point((cx + 5, base - 17), fill=L)
    # head and helmet with a crest
    f.rectangle([cx - 2, base - 26, cx + 2, base - 22], fill=L)
    f.rectangle([cx + 1, base - 26, cx + 2, base - 22], fill=M)
    f.point((cx - 1, base - 24), fill=D)  # eye slit
    f.line([(cx - 2, base - 27), (cx + 2, base - 27)], fill=L)
    f.line([(cx - 3, base - 29), (cx + 1, base - 30)], fill=M)
    f.line([(cx - 2, base - 28), (cx + 2, base - 29)], fill=L)
    # round shield on his left arm (screen left), a lit rim and a boss
    f.ellipse([cx - 10, base - 22, cx - 1, base - 12], fill=M)
    f.arc([cx - 10, base - 22, cx - 1, base - 12], 150, 300, fill=L)
    f.arc([cx - 10, base - 22, cx - 1, base - 12], 330, 120, fill=D)
    f.point((cx - 6, base - 17), fill=L)
    f.point((cx - 5, base - 17), fill=D)
    # outline
    ink = hexc("3b3742")
    src = fig.copy()
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3] == 0:
                for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + ox, y + oy
                    if 0 <= nx < w and 0 <= ny < h and src.getpixel((nx, ny))[3] > 0 and y < base:
                        fig.putpixel((x, y), ink)
                        break
    img.alpha_composite(fig)


prop("statue", 24, 46, statue)


def vessel(img, profile, top, bands=(), dots=(), handles=False):
    """A turned clay pot from a list of half-widths per row (top row first, starting at row
    `top`): lit from the left with dithered steps between three clay tones, black-figure bands,
    reserved dots in a band, a lit rim and a dark inner outline so it reads on the floor."""
    w = img.width
    cx = w / 2 - 0.5
    rows = {top + i: hw for i, hw in enumerate(profile)}
    for y, hw in rows.items():
        for x in range(w):
            u = (x - cx) / max(0.5, hw)
            if abs(u) > 1.0:
                continue
            light = -0.35 + (0.12 if (x + y) % 2 else -0.12)
            dark = 0.45 + (0.12 if (x + y) % 2 else -0.12)
            c = P["clay2"] if u < light else P["clay1"] if u < dark else P["clay0"]
            if y - top in bands:
                c = P["black"]
                if y - top in dots and x % 3 == 1 and abs(u) < 0.8:
                    c = P["clay1"]
            img.putpixel((x, y), c)
    # the rim: a lit lip on the top row
    for x in range(w):
        if img.getpixel((x, top))[3] and x < cx + rows[top] * 0.4:
            img.putpixel((x, top), P["clay2"])
    if handles:
        # Loops from the neck out to the shoulder: lit on the left, black on the right.
        for side, col in ((-1, P["clay0"]), (1, P["black"])):
            for dx, dy in ((2, 1), (3, 2), (4, 3), (4, 4), (4, 5), (3, 6)):
                x = (w // 2 - 1 - dx) if side < 0 else (w // 2 + dx)
                if 0 <= x < w:
                    img.putpixel((x, top + dy), col)
    src = img.copy()
    for y in range(img.height):
        for x in range(w):
            if src.getpixel((x, y))[3] == 0:
                continue
            edge = any(not (0 <= x + ox < w and 0 <= y + oy < img.height) or src.getpixel((x + ox, y + oy))[3] == 0
                       for ox, oy in ((1, 0), (0, 1), (-1, 0)))
            if edge and y > top:
                img.putpixel((x, y), P["black"] if x >= cx or y > top + len(profile) - 3 else P["clay0"])


def jar(img, d, w, h):
    # A storage pithos: a narrow neck, a broad shoulder and a long taper to a small foot.
    profile = [5, 5, 4, 4, 5, 6, 7, 7, 8, 8, 8, 8, 8, 8, 8, 7, 7, 7, 7, 6, 6, 6, 5, 5, 4, 4, 3]
    vessel(img, profile, h - len(profile), bands=(6, 7, 8, 14), dots=(7,))


prop("jar", 18, 28, jar)


def amphora(img, d, w, h):
    # A neck amphora with two handles, a wide body and a pointed foot.
    profile = [2, 2, 1, 1, 1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 4, 3, 3, 2, 1, 1]
    vessel(img, profile, h - len(profile) - 1, bands=(9, 10), dots=(), handles=True)


prop("amphora", 12, 21, amphora)


def vigil_lamp(img, d, w, h):
    """A snuffed clay oil lamp from the vigil: body, spout and handle, a dark wick hole."""
    body, light, dark = P["clay1"], P["clay2"], P["clay0"]
    d.rectangle([1, h - 3, w - 3, h - 1], fill=body)
    d.rectangle([2, h - 4, w - 4, h - 4], fill=light)
    d.rectangle([w - 3, h - 3, w - 1, h - 2], fill=body)
    d.point((w - 1, h - 3), fill=P["black"])
    d.point((0, h - 4), fill=dark)
    d.point((0, h - 3), fill=dark)
    d.point((4, h - 4), fill=P["black"])
    d.line([(1, h - 1), (w - 3, h - 1)], fill=dark)


prop("vigil_lamp", 9, 5, vigil_lamp)


def shards(img, d, w, h):
    for x, y, c in [(2, 6, "clay1"), (5, 7, "clay0"), (9, 5, "clay2"), (11, 7, "clay1"), (7, 4, "clay1"), (13, 6, "clay0")]:
        d.rectangle([x, y, x + 1, y + 1], fill=P[c])


prop("shards", 16, 9, shards)


def chest(img, d, w, h, opened=False):
    cx = w // 2
    d.polygon([(cx - 10, h - 8), (cx, h - 3), (cx + 9, h - 8), (cx + 9, h - 14), (cx, h - 9), (cx - 10, h - 14)], fill=P["leather"])
    d.polygon([(cx, h - 3), (cx + 9, h - 8), (cx + 9, h - 14), (cx, h - 9)], fill=hexc("3a2a20"))
    if opened:
        d.polygon([(cx - 10, h - 14), (cx, h - 9), (cx + 9, h - 14), (cx + 6, h - 21), (cx - 4, h - 22)], fill=hexc("2a1e17"))
        d.rectangle([cx - 4, h - 15, cx + 3, h - 12], fill=P["gold"])
    else:
        d.polygon([(cx - 10, h - 14), (cx, h - 9), (cx + 9, h - 14), (cx, h - 19)], fill=hexc("6a4a36"))
        d.line([(cx - 10, h - 14), (cx, h - 9), (cx + 9, h - 14)], fill=P["bronze"])
        d.rectangle([cx - 1, h - 11, cx, h - 9], fill=P["gold"])


prop("chest", 22, 24, chest)
prop("chest_open", 22, 24, lambda img, d, w, h: chest(img, d, w, h, True))


def rubble(img, d, w, h):
    for x, y, r, c in [(4, 7, 4, "marble0"), (11, 6, 5, "marble1"), (18, 7, 4, "marble0"), (8, 3, 3, "marble1"), (15, 3, 3, "marble0")]:
        d.ellipse([x - r, y - r // 2, x + r, y + r // 2 + 1], fill=P[c])


prop("rubble", 24, 12, rubble)


def tree(img, d, w, h):
    """An old olive tree: a gnarled, twisting trunk on flared roots, three limbs, and clumps of
    silvery foliage lit from the upper left, ragged at the edges, with a dark outline below."""
    rnd = random.Random(53)
    cx = w // 2
    bark, bark_l, bark_d = hexc("5a4030"), hexc("7a5a40"), hexc("33241b")
    # roots and trunk: two strands that wind around each other
    for x in range(cx - 4, cx + 4):
        img.putpixel((x, h - 1), bark_d)
    for i in range(20):
        y = h - 2 - i
        sway = int(round(1.5 * math.sin(i / 4.0)))
        for dx in range(-2, 2):
            x = cx + sway + dx
            c = bark_l if dx == -2 else bark_d if dx == 1 else bark
            img.putpixel((x, y), c)
        if i % 5 == 2:  # a knot
            img.putpixel((cx + sway, y), bark_d)
    # limbs
    top = h - 22
    for (dx, dy) in ((-7, -6), (6, -8), (1, -10)):
        d.line([(cx, top), (cx + dx, top + dy)], fill=bark, width=2)
        d.point((cx + dx, top + dy), fill=bark_l)
    # foliage clumps: (x, y, radius)
    clumps = [(cx - 8, h - 31, 7), (cx + 7, h - 33, 7), (cx, h - 38, 8), (cx - 3, h - 30, 6), (cx + 4, h - 27, 5),
              (cx - 10, h - 26, 4), (cx + 11, h - 28, 4)]
    leaf = Image.new("RGBA", (w, h), CLEAR)
    for (x0, y0, r) in clumps:
        for y in range(y0 - r, y0 + r + 1):
            for x in range(x0 - r - 1, x0 + r + 2):
                if not (0 <= x < w and 0 <= y < h):
                    continue
                dd = ((x - x0) / (r + 0.5)) ** 2 + ((y - y0) / (r * 0.8 + 0.5)) ** 2
                if dd > 1.0 or (dd > 0.7 and rnd.random() < 0.45):
                    continue
                light = -((x - x0) + (y - y0)) / (r * 1.4) + rnd.uniform(-0.35, 0.35)
                c = P["olive2"] if light > 0.45 else P["olive1"] if light > -0.25 else P["olive0"]
                if light > 1.0 and rnd.random() < 0.18:
                    c = P["silver"]
                leaf.putpixel((x, y), c)
    # outline the foliage on its shadow side so it reads on pale marble
    src = leaf.copy()
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3]:
                continue
            for ox, oy in ((-1, 0), (0, -1)):
                nx, ny = x + ox, y + oy
                if 0 <= nx < w and 0 <= ny < h and src.getpixel((nx, ny))[3]:
                    leaf.putpixel((x, y), hexc("232b18"))
                    break
    img.alpha_composite(leaf)


prop("tree", 32, 50, tree)


def well(img, d, w, h):
    cx = w // 2
    d.ellipse([cx - 13, h - 16, cx + 12, h - 1], fill=WALL_L)
    d.ellipse([cx - 13, h - 18, cx + 12, h - 5], fill=P["marble1"])
    d.ellipse([cx - 9, h - 15, cx + 8, h - 8], fill=P["night0"])
    d.line([(cx - 11, h - 20), (cx - 11, h - 30)], fill=P["leather"])
    d.line([(cx + 10, h - 20), (cx + 10, h - 30)], fill=P["leather"])
    d.line([(cx - 11, h - 30), (cx + 10, h - 30)], fill=P["leather"])


prop("well", 28, 32, well)


def brazier(img, d, w, h):
    """A dark bronze bowl on three legs with glowing coals; the flame is a separate, unshaded
    sprite (brazier_flame_0..2) so the bowl doesn't turn orange in its own light."""
    cx = w // 2
    dark, rim = hexc("3a2a22"), P["bronze"]
    for x0, x1 in [(cx - 5, cx - 3), (cx + 4, cx + 2), (cx, cx)]:
        d.line([(x0, h - 1), (x1, h - 9)], fill=dark)
    d.point((cx - 4, h - 5), fill=rim)
    d.point((cx + 3, h - 5), fill=rim)
    d.ellipse([cx - 6, h - 13, cx + 5, h - 8], fill=dark)
    d.line([(cx - 5, h - 12), (cx + 4, h - 12)], fill=rim)
    d.line([(cx - 4, h - 13), (cx + 3, h - 13)], fill=P["fire0"])
    for x in (cx - 3, cx, cx + 2):
        d.point((x, h - 13), fill=P["fire1"])
    d.point((cx - 5, h - 10), fill=rim)


prop("brazier", 14, 20, brazier)


# Three flame frames for the brazier: tongues of fire, outer orange to a pale core.
FLAMES = [
    ["....3.....", "...32.....", "...221.3..", "..2221.2..", "..12221...", ".112221...", ".1122211..", "..11111..."],
    [".....3....", "....23....", "..3.122...", "..2.1222..", "...12221..", "..1122221.", "..1122211.", "...11111.."],
    ["...3......", "...2..3...", "..12..2...", "..122122..", ".1122221..", ".11222211.", "..1222211.", "...1111..."],
]
for _i, _rows in enumerate(FLAMES):
    _img = Image.new("RGBA", (10, 8), CLEAR)
    for _y, _row in enumerate(_rows):
        for _x, _ch in enumerate(_row):
            if _ch != ".":
                _img.putpixel((_x, _y), {"1": P["fire1"], "2": P["fire2"], "3": P["fire3"]}[_ch])
    save(_img, f"brazier_flame_{_i}")


def rack(img, d, w, h):
    d.rectangle([2, h - 22, 3, h - 1], fill=P["leather"])
    d.rectangle([w - 4, h - 22, w - 3, h - 1], fill=P["leather"])
    d.rectangle([2, h - 20, w - 3, h - 19], fill=P["leather"])
    d.rectangle([2, h - 9, w - 3, h - 8], fill=P["leather"])
    d.line([(7, h - 23), (13, h - 3)], fill=P["silver"], width=2)
    d.line([(6, h - 17), (11, h - 19)], fill=P["bronze"])


prop("weapon_rack", 20, 26, rack)
prop("weapon_rack_empty", 20, 26, lambda img, d, w, h: (d.rectangle([2, h - 22, 3, h - 1], fill=P["leather"]),
                                                       d.rectangle([w - 4, h - 22, w - 3, h - 1], fill=P["leather"]),
                                                       d.rectangle([2, h - 20, w - 3, h - 19], fill=P["leather"]),
                                                       d.rectangle([2, h - 9, w - 3, h - 8], fill=P["leather"])))


def fountain(img, d, w, h):
    # one cell of the basin: low marble block with water on top
    block_img = Image.new("RGBA", (32, 24), CLEAR)
    bd = ImageDraw.Draw(block_img)
    bd.polygon([(0, 8), (16, 16), (16, 23), (0, 15)], fill=WALL_L)
    bd.polygon([(16, 16), (31, 8), (31, 15), (16, 23)], fill=WALL_R)
    diamond(bd, 0, 0, P["marble1"])
    diamond(bd, 3, 1, P["pool"], 26, 13)
    img.alpha_composite(block_img, (0, h - 24))


prop("fountain", 32, 24, fountain)


def fountain_spout(img, d, w, h):
    fountain(img, d, w, h)
    cx = w // 2
    d.rectangle([cx - 2, h - 34, cx + 1, h - 14], fill=P["marble2"])
    d.ellipse([cx - 4, h - 38, cx + 3, h - 33], fill=P["marble1"])
    for y in range(h - 36, h - 18, 3):
        d.point((cx + 4, y), fill=P["moon1"])
        d.point((cx - 5, y + 1), fill=P["moon1"])


prop("fountain_spout", 32, 40, fountain_spout)


def altar(img, d, w, h):
    cx = w // 2
    d.rectangle([cx - 10, h - 12, cx - 1, h - 2], fill=WALL_L)
    d.rectangle([cx, h - 12, cx + 9, h - 2], fill=WALL_R)
    diamond(d, cx - 11, h - 18, P["marble2"], 22, 11)


prop("altar", 24, 22, altar)


def belt_star(img, d, w, h):
    cx, cy = w // 2, h // 2
    for r, c in [(5, "moon0"), (3, "moon1"), (1, "fire3")]:
        d.polygon([(cx, cy - r - 2), (cx + r // 2 + 1, cy - 1), (cx + r + 2, cy), (cx + r // 2 + 1, cy + 1),
                   (cx, cy + r + 2), (cx - r // 2 - 1, cy + 1), (cx - r - 2, cy), (cx - r // 2 - 1, cy - 1)], fill=P[c])


prop("belt_star", 16, 16, belt_star)


def wall_lamp(img, d, w, h):
    d.ellipse([1, 3, 8, 7], fill=P["clay1"])
    d.rectangle([7, 4, 9, 5], fill=P["clay0"])
    d.ellipse([7, 0, 10, 4], fill=P["fire2"])


prop("wall_lamp", 11, 8, wall_lamp)


def knucklebone(img, d, w, h):
    d.rectangle([0, 1, 3, 2], fill=P["marble2"])
    d.point((0, 0), fill=P["marble2"])
    d.point((3, 3), fill=P["marble2"])


prop("knucklebone", 4, 4, knucklebone)


def obol(img, d, w, h):
    d.ellipse([0, 0, w - 1, h - 1], fill=P["gold"])
    d.ellipse([1, 1, w - 3, h - 3], fill=hexc("f0c45a"))
    d.point((w // 2, h // 2), fill=P["bronze"])


prop("obol", 6, 5, obol)
prop("sword_drop", 14, 6, lambda img, d, w, h: (d.line([(1, 4), (11, 1)], fill=P["silver"], width=2),
                                                d.line([(2, 2), (4, 6)], fill=P["bronze"])))

# ---------------------------------------------------------------- UI icons (drawn at 1x; the UI shows them at 2x)


def icon(name, w, h, painter):
    prop(name, w, h, painter)


def star_shape(d, cx, cy, r, fill):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=fill)


icon("hud_star", 11, 11, lambda img, d, w, h: star_shape(d, 5, 5.5, 5.4, P["fire2"]))
icon("hud_star_empty", 11, 11, lambda img, d, w, h: star_shape(d, 5, 5.5, 5.4, P["night2"]))
icon("hud_obol", 9, 9, lambda img, d, w, h: (d.ellipse([0, 0, 8, 8], fill=P["gold"]), d.ellipse([2, 2, 6, 6], fill=hexc("f0c45a"))))
icon("glyph_door", 7, 7, lambda img, d, w, h: d.polygon([(3, 0), (6, 3), (3, 6), (0, 3)], outline=P["fire2"]))
icon("glyph_coin", 7, 7, lambda img, d, w, h: d.ellipse([0, 0, 6, 6], outline=P["gold"]))
icon("glyph_hand", 7, 7, lambda img, d, w, h: (d.rectangle([1, 2, 5, 6], outline=P["moon1"]), d.line([(3, 0), (3, 2)], fill=P["moon1"])))
icon("glyph_star", 9, 9, lambda img, d, w, h: star_shape(d, 4, 4.5, 4.4, P["moon1"]))


# Shop item icons, 12x12, drawn pixel by pixel.
GRID_COLOURS = {"k": "black", "s": "silver", "S": "moon1", "b": "bronze", "g": "gold", "l": "leather",
                "w": "marble2", "m": "marble1", "r": "scorp1", "R": "scorp0", "o": "olive1"}
ITEM_ICONS = {
    "item_dagger": [
        "..........kk", ".........ksk", "........kSk.", ".......kSk..", "......kSk...", ".....kSk....",
        "..g.kSk.....", "...gbk......", "...kbg......", "..klk.g.....", ".klk........", ".kk.........",
    ],
    "item_kopis": [
        ".......kkk..", ".....kkSsk..", "....kSssk...", "...kSssk....", "..kSssk.....", "..kSsk......",
        ".gkSk.......", "..gbk.......", "..kbgg......", ".klk........", "klk.........", "kk..........",
    ],
    "item_xiphos": [
        "..........kk", ".........kSk", "........kSsk", ".......kSsk.", "......kSsk..", ".....kSsk...",
        "..g.kSsk....", "...gbsk.....", "...kbg......", "..klk.g.....", ".klk........", ".kk.........",
    ],
    "item_tunic": [
        "............", "..kkk..kkk..", ".kwwwkkwwwk.", "kwwwwwwwwwwk", "kmkwwwwwwkmk", ".k.kwwwwk.k.",
        "...kwwwwk...", "...kwwwwk...", "...kbbbbk...", "...kwwwwk...", "...kmmmmk...", "...kkkkkk...",
    ],
    "item_linothorax": [
        "............", "..kkk..kkk..", ".kwwwkkwwwk.", "kwbwbwwbwbwk", "kmkbwbbwbkmk", ".k.kbwbwk.k.",
        "...kwbwbk...", "...kbwbwk...", "...kllllk...", "...kwmwmk...", "...kmwmwk...", "...kkkkkk...",
    ],
    "item_cuirass": [
        "............", "..kk....kk..", ".kSsk..ksSk.", "kSSsskksSSsk", "kSsSsSSsSsSk", ".kSsssssSsk.",
        ".ksSsSSsSsk.", ".kssSssSssk.", "..kssssssk..", "..ksSssSsk..", "..kbbbbbbk..", "..kkkkkkkk..",
    ],
    "item_pomegranate": [
        "....k.k.k...", "....kgkgk...", "...kkrrkk...", "..krrSrrrk..", ".krrSrrrrrk.", ".krrrrrrrrk.",
        ".krrrrrrrRk.", ".krrrrrrRRk.", "..krrrrRRk..", "...kRRRRk...", "....kkkk....", "............",
    ],
}
for _name, _rows in ITEM_ICONS.items():
    _img = Image.new("RGBA", (12, 12), CLEAR)
    for _y, _row in enumerate(_rows):
        assert len(_row) == 12, (_name, _y)
        for _x, _ch in enumerate(_row):
            if _ch != ".":
                _img.putpixel((_x, _y), P[GRID_COLOURS[_ch]])
    save(_img, _name)


def qmark(img, d, w, h, col):
    for x, y in [(1, 0), (2, 0), (3, 0), (0, 1), (4, 1), (4, 2), (3, 3), (2, 4), (2, 5), (2, 7)]:
        img.putpixel((x, y), col)


icon("mark_question", 5, 8, lambda img, d, w, h: qmark(img, d, w, h, P["fire2"]))
icon("mark_alert", 3, 8, lambda img, d, w, h: [img.putpixel((x, y), P["scorp1"]) for x in range(3) for y in (0, 1, 2, 3, 4, 6, 7) if not (y >= 3 and x != 1) or y in (6, 7) and x == 1])
icon("glint_white", 9, 9, lambda img, d, w, h: star_shape(d, 4, 4.5, 4.6, (255, 255, 255, 255)))
icon("glint_red", 11, 11, lambda img, d, w, h: (d.ellipse([0, 0, 10, 10], outline=P["scorp1"]), d.ellipse([1, 1, 9, 9], outline=P["scorp0"])))
icon("spark", 3, 3, lambda img, d, w, h: (d.point((1, 1), fill=P["fire3"]), d.point((1, 0), fill=P["fire2"]), d.point((0, 1), fill=P["fire2"]),
                                          d.point((2, 1), fill=P["fire2"]), d.point((1, 2), fill=P["fire2"])))

# ---------------------------------------------------------------- light textures


def radial_banded(name, size, bands=4):
    img = Image.new("RGBA", (size, size), CLEAR)
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            r = math.hypot(x - c, y - c) / c
            if r >= 1:
                continue
            v = (1 - r) ** 1.4
            # quantise into hard bands with a checker dither on band edges
            q = v * bands
            lo = math.floor(q)
            frac = q - lo
            level = lo + (1 if frac > 0.5 + (0.25 if (x + y) % 2 else -0.25) else 0)
            a = min(1.0, level / bands)
            img.putpixel((x, y), (255, 255, 255, int(255 * a)))
    save(img, name)


radial_banded("light_radial", 128)


def cone(name, size, half_deg):
    img = Image.new("RGBA", (size, size), CLEAR)
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            dx, dy = x - c, y - c
            r = math.hypot(dx, dy) / c
            if r >= 1 or r < 0.02:
                continue
            ang = abs(math.degrees(math.atan2(dy, dx)))
            if ang > half_deg:
                continue
            edge = 1 - max(0, (ang - half_deg * 0.7) / (half_deg * 0.3))
            v = (1 - r) ** 1.2 * edge
            level = round(v * 4 + (0.2 if (x + y) % 2 else -0.2))
            img.putpixel((x, y), (255, 255, 255, int(255 * max(0, min(4, level)) / 4)))
    save(img, name)


cone("light_cone", 128, 50)

print("greybox art written to", OUT)
print(sorted(p.name for p in OUT.glob("*.png")))
