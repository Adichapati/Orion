"""Turn a hand-made character sheet into game frames: art/final/<name>_sheet.png + .json.

The output is Aseprite's json-array sprite-sheet format, so a real Aseprite export (File > Export
Sprite Sheet, JSON data, tags) can replace it with no code changes; it also writes the stills
art/final/<name>_se.png and <name>_ne.png at the sheet's cell size.

For every frame it removes the background (and drop shadows), optionally cuts the sword out (the
game draws Cedalion's sword as its own sprite: hidden while he's unarmed, swung in an arc, one
per weapon), mirrors frames so front views face south-east and back views north-east, scales
them to the in-game size, maps every frame to one shared palette (so colours never flicker),
lines the feet up on one pivot and records where the torch flame and the sword hand are.

Cedalion's sheet (art/generated/cedalion_friend_sheet.webp) has hand-measured frame boxes and
blade lines below. Any other character drops straight in: save its sheet as
art/generated/<name>_sheet.png (or .webp) in the same layout, on a flat plain background with no
ground tile or shadow:

    row 1: idle  - front view, then back view (extra poses are ignored)
    row 2: walk  - the front-view frames, then the back-view frames (4 + 4)
    row 3: attack - the front-view frames, then the back-view frames
    (row 4, if any, is ignored: lying poses are animated in code)

Front views should face screen-right (pass --mirror if they face left; --paper for a sheet drawn
on gridded paper like Cedalion's). The frames are found
automatically (labels are skipped), scaled to the height of the character's current still, and
the stills are rewritten to match.

    python tools/process_sheet.py cedalion [preview dir]
    python tools/process_sheet.py cedalion_leather   # also cedalion_mail, cedalion_plate: his armour bodies
    python tools/process_sheet.py watchman [--mirror] [--paper] [--attack-front=N] [preview dir]
"""
from collections import deque
from pathlib import Path
import json
import math
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GENERATED = ROOT / "art" / "generated"
OUT = ROOT / "art" / "final"
APP = "tools/process_sheet.py"
COLS = 8

# ---------------------------------------------------------------- Cedalion's hand-made sheet

# (box in the sheet, mirror?, kind) - boxes found by scanning the sheet; mirror normalises facing:
# front views must look toward screen-right (SE) and back views away up-right (NE). The artist was
# not consistent: of the front poses, the second idle and the last three walk frames look right
# (ear on the left of the face, eyes right of centre) but the first idle and the first walk frame
# look left. Mirroring those two would swap the torch to the other hand mid-step, so the walk
# leaves the first frame out and the left-looking idle is only his glance back ("look"). FACES
# records which way each pose looks as drawn; the sheet's JSON carries it (after mirroring) so a
# test can check that every clip faces the way he moves.
BOXES = {
    "idle_f": ((60, 50, 280, 222), False, "stand"),
    "idle_f2": ((380, 50, 590, 222), False, "stand"),
    "idle_b": ((640, 50, 880, 222), False, "stand"),
    "idle_b2": ((950, 50, 1190, 222), False, "stand"),
    "walk_f0": ((15, 275, 182, 429), False, "stand"),
    "walk_f1": ((191, 274, 320, 430), False, "stand"),
    "walk_f2": ((327, 274, 458, 430), False, "stand"),
    "walk_f3": ((462, 274, 596, 430), False, "stand"),
    "walk_b0": ((638, 276, 780, 429), True, "stand"),
    "walk_b1": ((775, 276, 912, 429), True, "stand"),
    "walk_b2": ((912, 276, 1051, 430), True, "stand"),
    "walk_b3": ((1054, 276, 1199, 429), True, "stand"),
    "atk_f0": ((68, 489, 266, 640), False, "stand"),
    "atk_f1": ((387, 493, 536, 641), False, "stand"),
    "atk_f2": ((684, 492, 870, 640), False, "stand"),
    "atk_b": ((978, 487, 1163, 640), False, "stand"),
}

# Which way each pose looks as drawn (before mirroring), seen from the front or the back.
FACES = {
    "idle_f": "left", "idle_f2": "right", "idle_b": "right", "idle_b2": "right",
    "walk_f0": "left", "walk_f1": "right", "walk_f2": "right", "walk_f3": "right",
    "walk_b0": "left", "walk_b1": "left", "walk_b2": "left", "walk_b3": "left",
    "atk_f0": "right", "atk_f1": "right", "atk_f2": "right", "atk_b": "right",
    "roll0": "right", "roll1": "right", "roll2": "right",
    "block_f": "left", "block_b": "left", "hurt_f": "left", "hurt_b": "right",
}

# The sword, in sheet pixels before mirroring: the blade's tip and the centre of its crossguard
# (None where the frame shows no blade), and the sword hand's grip. Measured by eye from the sheet.
# The blade and crossguard are cut out of the frame; the grip becomes the frame's "hand" point.
SWORDS = {
    "idle_f": ((70, 113), (132, 153), (143, 160)),
    "idle_f2": ((398, 125), (442, 168), (452, 176)),
    "idle_b": ((870, 93), (815, 146), (803, 157)),
    "idle_b2": ((1168, 103), (1112, 150), (1098, 160)),
    "walk_f0": ((17, 325), (58, 364), (72, 367)),
    "walk_f1": (None, None, (199, 372)),
    "walk_f2": (None, None, (337, 375)),
    "walk_f3": (None, None, (471, 373)),
    "walk_b0": ((640, 329), (684, 368), (695, 378)),
    "walk_b1": ((778, 333), (818, 372), (829, 378)),
    "walk_b2": ((914, 329), (955, 370), (963, 379)),
    "walk_b3": ((1056, 328), (1098, 369), (1110, 378)),
    "atk_f0": ((263, 542), (216, 580), (205, 588)),
    "atk_f1": (None, None, (517, 590)),
    "atk_f2": ((866, 539), (820, 580), (810, 590)),
    "atk_b": ((1160, 542), (1115, 582), (1100, 592)),
}
BLADE_R = 10      # half-width of the cut along the blade, in sheet pixels (blade plus outline)
GUARD_R = 6       # half-width of the cut along the crossguard
GUARD_HALF = 14   # half-length of the crossguard
# Frames whose blade isn't drawn: the resting angle is borrowed from another frame.
ANGLE_FROM = {"walk_f1": "walk_f0", "walk_f2": "walk_f0", "walk_f3": "walk_f0", "atk_f1": "atk_f2"}
# The pale swing arc painted into one frame (the game draws its own): only light pixels inside
# these capsules (x0, y0, x1, y1, radius) are removed, so the tunic and legs stay.
ARCS = {
    "atk_f1": [(512, 488, 548, 528, 8), (548, 528, 545, 570, 8), (545, 570, 512, 604, 8), (512, 604, 478, 616, 7)],
}

# Adithya's fuller sheet (art/generated/cedalion_sheet_v2.jpg) adds the moves the first one lacks:
# the dodge roll, the block and the get-hit. Only those are taken: its walk and idle rows are
# labelled with directions that don't match them, and the first sheet's work. Its lower rows are
# drawn smaller (about 72 px standing against 160), hence their own scale. The roll's first and
# last poses are just standing, so only the three tucked frames are used; they show no sword, so
# they get no sword hand and the game hides the blade while he's curled up.
BOXES_V2 = {
    "roll0": ((161, 641, 229, 707), False, "stand"),
    "roll1": ((266, 638, 338, 705), False, "stand"),
    "roll2": ((383, 635, 454, 705), False, "stand"),
    # the front block looks left, so it is mirrored to face the way he moves
    "block_f": ((698, 626, 771, 704), True, "stand"),
    # the back views hold the sword on the left: mirrored to match the first sheet's back views
    "block_b": ((962, 628, 1042, 704), True, "stand"),
    # the flinch looks a little left, with the sword on our right: mirrored like the block
    "hurt_f": ((537, 779, 608, 862), True, "stand"),
    "hurt_b": ((609, 778, 694, 854), False, "stand"),
}
SWORDS_V2 = {
    "block_f": (None, None, (708, 683)),
    "block_b": (None, None, (979, 668)),
    "hurt_f": ((603, 790), (586, 813), (582, 821)),
    "hurt_b": ((690, 803), (664, 828), (659, 833)),
}
# The painted block effects: a crescent round the front block and a pale shield on the back one.
ARCS_V2 = {
    "block_f": [(746, 629, 764, 641, 6), (764, 641, 772, 662, 6), (772, 662, 767, 685, 6), (767, 685, 750, 702, 6)],
    "block_b": [(963, 645, 963, 691, 5), (963, 645, 990, 645, 5), (963, 691, 986, 691, 5)],
}
# Frames without a drawn blade borrow a resting angle (the game poses the parry blade itself).
ANGLE_FROM_V2 = {"block_f": "idle_f", "block_b": "idle_b"}
SHEET_V2 = dict(
    source=GENERATED / "cedalion_sheet_v2.jpg",
    boxes=BOXES_V2, swords=SWORDS_V2, arcs=ARCS_V2,
    scale=0.40, is_bg=lambda c: is_paper_jpg(c), enhance=(1.45, 1.35, 2.5),
)

# Cedalion's lying poses sit on a grass tile that can't be separated cleanly at this scale, so the
# game animates the fall in code instead.
# Animation tags: name -> (frame keys, ms per frame). Facing suffix: _se front, _ne back; the game
# mirrors them for _sw / _nw.
TAGS = [
    # the right-looking idle; now and then he glances back over his shoulder (the left-looking one)
    ("idle_se", ["idle_f2"], 400), ("idle_ne", ["idle_b"], 400),
    ("look_se", ["idle_f"], 400), ("look_ne", ["idle_b2"], 400),
    # stride, pass, stride, pass: two footfalls per cycle, in step with the footstep sounds (the
    # first walk frame looks the other way, so the other pass frame is used twice)
    ("walk_se", ["walk_f2", "walk_f1", "walk_f3", "walk_f1"], 150),
    ("walk_ne", ["walk_b1", "walk_b0", "walk_b3", "walk_b2"], 150),
    ("attack_se", ["atk_f0", "atk_f1", "atk_f2"], 100),
    ("attack_ne", ["atk_b"], 300),
    ("parry_se", ["block_f"], 300), ("parry_ne", ["block_b"], 300),
    ("lunge_se", ["atk_f2"], 300), ("lunge_ne", ["atk_b"], 300),
    ("jump_se", ["walk_f1"], 300), ("jump_ne", ["walk_b1"], 300),
    # the roll is the same tucked ball from either side; the game plays it over the dodge's length
    ("dodge_se", ["roll0", "roll1", "roll2"], 90), ("dodge_ne", ["roll0", "roll1", "roll2"], 90),
    ("hurt_se", ["hurt_f"], 300), ("hurt_ne", ["hurt_b"], 300),
]

CONFIGS = {
    "cedalion": dict(
        source=GENERATED / "cedalion_friend_sheet.webp",
        boxes=BOXES, tags=TAGS, swords=SWORDS, arcs=ARCS, angle_from={**ANGLE_FROM, **ANGLE_FROM_V2},
        scale=0.19,  # sheet pixels -> game pixels (~26 px tall, the doc's 16x24 hero plus hair)
        palette=22, background="paper", torch=True, stills=("idle_f2", "idle_b"), faces=FACES,
        more=[SHEET_V2],
    ),
}

# ---------------------------------------------------------------- Cedalion's armour bodies
# Sathvik's armour sheet (art/generated/cedalion_armour_sheet.webp) is a 3x3 grid: rows Leather,
# Chainmail, Plate; columns Mace, Axe, Sword. Only each armour's "+ Sword" block is used, and in
# it only the poses that hold no weapon (the game draws the weapon itself): of the five walk-row
# figures, the two front views without a sword (w2, w4) and the two back views (w1, whose club is
# cut away, and w5). The front views look left as drawn (eyes left of the face's middle), so both
# are mirrored to face screen-right; the back views look away up-right. The sheet's figures stand
# square to the viewer and barely change pose, so every move is built from these four frames.
# They hold no torch: one is drawn into the off hand (draw_torch) and its flame recorded.
ARMOUR_FACES = {"w1": "right", "w2": "left", "w4": "left", "w5": "right", "a3": "right", "a4": "right"}
# Leather's boxes and points, in sheet pixels; the other blocks sit lower by their own offsets.
ARMOUR_BOXES = {
    "w1": (1122, 71, 1162, 147), "w2": (1198, 71, 1237, 146),
    "w4": (1349, 70, 1390, 146), "w5": (1418, 71, 1456, 146),
    "a3": (1266, 171, 1312, 236), "a4": (1349, 171, 1392, 236),
}
# (club tip, club neck, sword hand) - only w1 holds anything (a club, cut out)
ARMOUR_SWORDS = {
    "w1": ((1178, 115), (1165, 125), (1158, 124)),
    "w2": (None, None, (1229, 124)),
    "w4": (None, None, (1384, 127)),
    "w5": (None, None, (1450, 124)),
    "a3": ((1320, 197), (1302, 215), (1299, 219)),
    "a4": ((1405, 196), (1385, 216), (1381, 219)),
}
ARMOUR_TORCH_HANDS = {"w1": (1129, 124), "w2": (1205, 124), "w4": (1355, 124), "w5": (1417, 124),
                      "a3": (1270, 222), "a4": (1352, 217)}
# Where each block's figures sit, per frame (found by detect_rows): leather's boxes moved by these.
ARMOUR_BLOCKS = {
    "leather": {"w1": (1122, 71), "w2": (1198, 71), "w4": (1349, 70), "w5": (1418, 71), "a3": (1266, 171), "a4": (1349, 171)},
    "mail": {"w1": (1118, 408), "w2": (1195, 408), "w4": (1351, 408), "w5": (1420, 408), "a3": (1265, 516), "a4": (1350, 517)},
    "plate": {"w1": (1121, 756), "w2": (1197, 756), "w4": (1349, 755), "w5": (1418, 755), "a3": (1263, 855), "a4": (1351, 855)},
}
ARMOUR_TAGS = [
    ("idle_se", ["w2"], 400), ("idle_ne", ["w5"], 400),
    ("look_se", ["w4"], 400), ("look_ne", ["w1"], 400),
    ("walk_se", ["w4", "w2"], 150), ("walk_ne", ["w5", "w1"], 150),
    ("attack_se", ["a3"], 300), ("attack_ne", ["a4"], 300),
    ("parry_se", ["a3"], 300), ("parry_ne", ["a4"], 300),
    ("lunge_se", ["a3"], 300), ("lunge_ne", ["a4"], 300),
    ("jump_se", ["w4"], 300), ("jump_ne", ["w1"], 300),
    ("dodge_se", ["w4"], 300), ("dodge_ne", ["w1"], 300),
    ("hurt_se", ["w2"], 300), ("hurt_ne", ["w1"], 300),
]
TORCH_PAD = 3


def draw_torch(img, x, y):
    """A small torch held in the fist at (x, y): a leather-bound haft and a flame in the ORION
    fire colours, outlined in ink. Returns the flame's centre."""
    px = img.load()
    leather, bronze = (74, 51, 38), (168, 105, 58)
    f1, f2, f3 = (224, 120, 44), (255, 200, 87), (255, 241, 193)
    pts = {}
    for yy in (y + 1, y + 2):
        pts[(x, yy)] = leather
    for yy in range(y - 6, y):
        pts[(x, yy)] = bronze if yy <= y - 5 else leather
    pts.update({(x - 1, y - 7): f1, (x, y - 7): f2, (x + 1, y - 7): f1,
                (x - 1, y - 8): f2, (x, y - 8): f3, (x + 1, y - 8): f2,
                (x - 1, y - 9): f1, (x, y - 9): f3, (x + 1, y - 9): f1,
                (x, y - 10): f2, (x, y - 11): f1})
    for (a, b), c in pts.items():
        if 0 <= a < img.width and 0 <= b < img.height:
            px[a, b] = c + (255,)
    for (a, b) in list(pts):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (a + dx, b + dy)
            if n not in pts and 0 <= n[0] < img.width and 0 <= n[1] < img.height and px[n][3] == 0:
                px[n] = (26, 20, 18, 255)
    return (x, y - 8)


def armour_config(look):
    def moved(key, p):
        if p is None:
            return None
        bx, by = ARMOUR_BLOCKS[look][key]
        lx, ly = ARMOUR_BLOCKS["leather"][key]
        return (p[0] + bx - lx, p[1] + by - ly)
    boxes, swords, torches = {}, {}, {}
    for key, box in ARMOUR_BOXES.items():
        a, b = moved(key, box[:2]), moved(key, box[2:])
        boxes[key] = ((a[0], a[1], b[0], b[1]), ARMOUR_FACES[key] == "left", "stand")
        swords[key] = tuple(moved(key, p) for p in ARMOUR_SWORDS[key])
        torches[key] = moved(key, ARMOUR_TORCH_HANDS[key])
    return dict(
        source=GENERATED / "cedalion_armour_sheet.webp",
        boxes=boxes, tags=ARMOUR_TAGS, swords=swords, torch_hands=torches,
        # front views rest the blade up and back over the shoulder, back views up and forward,
        # like the tunic sheet's walk
        angles={"w2": -136, "w4": -136, "w1": -44, "w5": -44},
        blade_r=4, guard_r=3, guard_half=4,
        scale=0.40, palette=22, background="paper", is_bg=lambda c: is_paper(c) or is_paper_jpg(c),
        # the leather is the colour of his skin: firmer contrast keeps his face apart from it
        enhance=(1.3, 1.2, 1.5) if look == "leather" else None,
        torch=True, stills=None, faces=ARMOUR_FACES,
    )


for _look in ("leather", "mail", "plate"):
    CONFIGS["cedalion_" + _look] = armour_config(_look)


def is_paper(c):
    """The sheet's blue-grey paper, grid and drop shadow. Cream tunics and the pale swing arc lean
    warm (red >= blue), so they stay."""
    r, g, b = c[:3]
    return (max(r, g, b) - min(r, g, b)) < 42 and max(r, g, b) > 112 and b >= r - 6


def is_paper_jpg(c):
    """The v2 sheet's paper is a JPEG: its edges round each figure blur into light greys that lean
    a little warm, and its drop shadows are a darker slate blue. Skin, hair, tunic and flame lean
    much warmer, and the outline is dark and warm, so they stay. The sheet also ends in a black
    strip along its bottom edge."""
    r, g, b = c[:3]
    hi, lo = max(r, g, b), min(r, g, b)
    if hi < 14:
        return True
    if hi - lo < 48 and hi > 150 and b >= r - 28:
        return True
    return b >= r + 4 and hi - lo < 70 and hi >= 60


def tile_colours(img: Image.Image):
    """The grass-and-earth tile under a lying pose: sample the tile's bare corners."""
    w, h = img.size
    px = img.load()
    pts = []
    for (x0, x1) in ((0, w // 4), (3 * w // 4, w)):
        for y in range(h // 2, h):
            for x in range(x0, x1):
                c = px[x, y][:3]
                if not is_paper(c) and max(c) > 70:
                    pts.append(c)
    if not pts:
        return []
    sample = Image.new("RGB", (len(pts), 1))
    sample.putdata(pts)
    q = sample.quantize(colors=8, method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette()[:24]
    return [tuple(pal[i:i + 3]) for i in range(0, 24, 3)]


def near_any(c, cols, d):
    r, g, b = c[:3]
    return any((r - p[0]) ** 2 + (g - p[1]) ** 2 + (b - p[2]) ** 2 < d * d for p in cols)


def flat_background(sheet: Image.Image):
    """A test for a flat plain background: the commonest colour in the sheet's corners, give or
    take a little (and soft dark drop shadows on it)."""
    px = sheet.load()
    counts = {}
    for cx, cy in ((0, 0), (sheet.width - 8, 0), (0, sheet.height - 8), (sheet.width - 8, sheet.height - 8)):
        for y in range(cy, cy + 8):
            for x in range(cx, cx + 8):
                c = px[x, y][:3]
                counts[c] = counts.get(c, 0) + 1
    bg = max(counts, key=counts.get)
    return lambda c: sum((c[i] - bg[i]) ** 2 for i in range(3)) < 48 * 48


def cut_out(img: Image.Image, lying: bool, is_bg=is_paper) -> Image.Image:
    """Flood the background in from the crop's border; the dark outline protects the figure."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    if lying:
        tile = tile_colours(img)
        # tight match, and nothing bright: hair and skin highlights are never tile
        passable = lambda c: is_bg(c) or (max(c[:3]) < 190 and near_any(c, tile, 28))
    else:
        passable = is_bg
    bg = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if bg[i] or not passable(px[x, y]):
            continue
        bg[i] = 1
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not bg[ny * w + nx]:
                q.append((nx, ny))
    for y in range(h):
        for x in range(w):
            if bg[y * w + x]:
                px[x, y] = (0, 0, 0, 0)
    return keep_main_parts(img)


def keep_main_parts(img: Image.Image) -> Image.Image:
    """Drop stray specks and bits of neighbouring frames: keep components >= 6% of the largest."""
    w, h = img.size
    px = img.load()
    label = [-1] * (w * h)
    sizes = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 or label[y * w + x] >= 0:
                continue
            k = len(sizes)
            n = 0
            q = deque([(x, y)])
            label[y * w + x] = k
            while q:
                cx, cy = q.popleft()
                n += 1
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and label[ny * w + nx] < 0 and px[nx, ny][3] > 0:
                        label[ny * w + nx] = k
                        q.append((nx, ny))
            sizes.append(n)
    if not sizes:
        return img
    big = max(sizes)
    keep = {k for k, n in enumerate(sizes) if n >= big * 0.06}
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0 and label[y * w + x] not in keep:
                px[x, y] = (0, 0, 0, 0)
    return img


def seg_dist(p, a, b):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    L = dx * dx + dy * dy
    t = 0.0 if L == 0 else max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - ay) * dy) / L))
    return ((p[0] - ax - t * dx) ** 2 + (p[1] - ay - t * dy) ** 2) ** 0.5


def cut_sword(img: Image.Image, key, origin, cfg):
    """Clears the blade and crossguard (and any painted swing arc) out of a cut-out frame. Points
    are in sheet pixels; `origin` is the crop's top-left in the sheet."""
    tip, guard, _hand = cfg.get("swords", {}).get(key, (None, None, None))
    caps = []
    if tip:
        br, gr, gh = cfg.get("blade_r", BLADE_R), cfg.get("guard_r", GUARD_R), cfg.get("guard_half", GUARD_HALF)
        dx, dy = guard[0] - tip[0], guard[1] - tip[1]
        n = (dx * dx + dy * dy) ** 0.5
        ux, uy = dx / n, dy / n
        caps.append((tip, (guard[0] + ux * 3, guard[1] + uy * 3), br, False))
        caps.append(((guard[0] - uy * gh, guard[1] + ux * gh),
                     (guard[0] + uy * gh, guard[1] - ux * gh), gr, False))
    for x0, y0, x1, y1, r in cfg.get("arcs", {}).get(key, []):
        caps.append(((x0, y0), (x1, y1), r, True))
    if not caps:
        return img
    px = img.load()
    ox, oy = origin
    for y in range(img.height):
        for x in range(img.width):
            c = px[x, y]
            if c[3] == 0:
                continue
            p = (x + ox, y + oy)
            for a, b, r, light_only in caps:
                if seg_dist(p, a, b) <= r and (not light_only or min(c[:3]) > 150):
                    px[x, y] = (0, 0, 0, 0)
                    break
    return keep_main_parts(img)


def enhance(img: Image.Image, contrast: float, colour: float, sharpness: float) -> Image.Image:
    """Firms up a soft, washed-out drawing (the v2 JPEG) to match the first sheet's tones before it
    is shrunk: more contrast and colour, sharper edges. The alpha is kept as it is."""
    from PIL import ImageEnhance
    alpha = img.getchannel("A")
    rgb = img.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    rgb = ImageEnhance.Color(rgb).enhance(colour)
    rgb = ImageEnhance.Sharpness(rgb).enhance(sharpness)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def shrink(img: Image.Image, scale: float) -> Image.Image:
    bb = img.getbbox()
    img = img.crop(bb)
    w, h = img.size
    tw, th = max(1, round(w * scale)), max(1, round(h * scale))
    small = img.convert("RGBa").resize((tw, th), Image.BOX).convert("RGBA")
    px = small.load()
    for y in range(th):
        for x in range(tw):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    return small


def build_palette(frames, size):
    strip_w = sum(f.width for f in frames)
    strip = Image.new("RGB", (strip_w, max(f.height for f in frames)), (0, 0, 0))
    x = 0
    pts = []
    for f in frames:
        for yy in range(f.height):
            for xx in range(f.width):
                p = f.getpixel((xx, yy))
                if p[3] > 0:
                    pts.append(p[:3])
        x += f.width
    sample = Image.new("RGB", (len(pts), 1))
    sample.putdata(pts)
    q = sample.quantize(colors=size, method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette()[: size * 3]
    return [tuple(pal[i:i + 3]) for i in range(0, len(pal), 3)]


def nearest(c, pal):
    r, g, b = c
    best, bd = pal[0], 1e18
    for p in pal:
        # weighted RGB distance, close enough to perceptual for small palettes
        d = 2 * (r - p[0]) ** 2 + 4 * (g - p[1]) ** 2 + 3 * (b - p[2]) ** 2
        if d < bd:
            bd, best = d, p
    return best


def is_flame(c):
    r, g, b = c[:3]
    return r > 190 and b < 130 and r > g and g > 70


def finish(f: Image.Image, pal, ink):
    px = f.load()
    w, h = f.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = nearest((r, g, b), pal) + (255,)
    # crisp silhouette: light pixels on the edge become outline ink (flames stay bright)
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or px[nx, ny][3] == 0:
                    c = px[x, y]
                    lum = 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
                    if lum > 70 and not is_flame(c):
                        edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = ink + (255,)
    return f


def anchor_of(f: Image.Image, lying: bool):
    w, h = f.size
    px = f.load()
    rows = [y for y in range(h) if any(px[x, y][3] for x in range(w))]
    yb = rows[-1]
    if lying:
        bb = f.getbbox()
        return ((bb[0] + bb[2]) / 2.0, yb)
    xs = [x for y in range(max(0, yb - 2), yb + 1) for x in range(w) if px[x, y][3]]
    return (sum(xs) / len(xs), yb)


def flame_of(f: Image.Image, side=0):
    """Where the torch flame is. The golden hair sits in the middle and is flame-coloured too, so
    only orange pixels in the outer thirds count: on `side` (-1 left, 1 right) if given (the torch
    is in the hand that doesn't hold the sword), else on whichever side has more of them."""
    bb = f.getbbox()
    left = bb[0] + (bb[2] - bb[0]) * 0.36
    right = bb[2] - (bb[2] - bb[0]) * 0.36
    sides = ([], [])
    for y in range(f.height):
        for x in range(f.width):
            c = f.getpixel((x, y))
            if c[3] and is_flame(c) and (x < left or x > right):
                sides[0 if x < left else 1].append((x, y))
    pts = sides[0] if side < 0 else (sides[1] if side > 0 else max(sides, key=len))
    if len(pts) < 3:
        return None
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))


def process(name, cfg, preview=None):
    raw = {}
    hands = {}
    torch_hands = {}
    mirrors = {}
    first = None
    # The main sheet, then any extra sheets ("more": their own source, boxes, swords, arcs and
    # scale) that add frames to the same set.
    for part in [cfg] + cfg.get("more", []):
        sheet = Image.open(part["source"]).convert("RGB")
        is_bg = part.get("is_bg") or (is_paper if cfg.get("background") == "paper" else flat_background(sheet))
        swords = part.get("swords", {})
        for key, (box, mirror, kind) in part["boxes"].items():
            x0, y0, x1, y1 = box
            origin = (max(0, x0 - 4), max(0, y0 - 4))
            crop = sheet.crop((origin[0], origin[1], min(sheet.width, x1 + 5), min(sheet.height, y1 + 5)))
            cut = cut_sword(cut_out(crop, kind == "lying", is_bg), key, origin, part)
            if part.get("enhance"):
                cut = enhance(cut, *part["enhance"])
            tip, guard, hand = swords.get(key, (None, None, None))
            mirrors[key] = mirror
            if mirror:
                cut = cut.transpose(Image.FLIP_LEFT_RIGHT)
            bb = cut.getbbox()
            small = shrink(cut, part["scale"])
            if hand:
                hx, hy = hand[0] - origin[0], hand[1] - origin[1]
                if mirror:
                    hx = crop.width - 1 - hx
                sx, sy = small.width / (bb[2] - bb[0]), small.height / (bb[3] - bb[1])
                angle = None
                if tip:
                    dx, dy = tip[0] - guard[0], tip[1] - guard[1]
                    if mirror:
                        dx = -dx
                    angle = math.degrees(math.atan2(dy, dx))
                hands[key] = [(hx - bb[0]) * sx, (hy - bb[1]) * sy, angle]
            th = part.get("torch_hands", {}).get(key)
            if th:
                # the off hand, where a torch is drawn in (armour sheets show no torch)
                tx, ty = th[0] - origin[0], th[1] - origin[1]
                if mirror:
                    tx = crop.width - 1 - tx
                sx, sy = small.width / (bb[2] - bb[0]), small.height / (bb[3] - bb[1])
                torch_hands[key] = ((tx - bb[0]) * sx, (ty - bb[1]) * sy)
            raw[key] = (small, kind)
        if first is None:
            first = list(raw)
    for key, src in cfg.get("angle_from", {}).items():
        if key in hands and src in hands:
            hands[key][2] = hands[src][2]
    for key, a in cfg.get("angles", {}).items():
        if key in hands:
            hands[key][2] = a
    # The palette comes from the main sheet alone, so extra frames never shift its colours.
    pal = build_palette([raw[k][0] for k in first], cfg.get("palette", 22))
    ink = min(pal, key=lambda p: p[0] + p[1] + p[2])
    frames = {}
    for key, (f, kind) in raw.items():
        frames[key] = (finish(f, pal, ink), kind)
    # Armour sheets show no torch, but Cedalion always carries the last flame: draw one into the
    # off hand, after the palette so its fire stays bright, and remember where its flame is.
    flames = {}
    for key, at in torch_hands.items():
        f, kind = frames[key]
        padded = Image.new("RGBA", (f.width + 2 * TORCH_PAD, f.height), (0, 0, 0, 0))
        padded.alpha_composite(f, (TORCH_PAD, 0))
        flames[key] = draw_torch(padded, round(at[0]) + TORCH_PAD, round(at[1]))
        if key in hands:
            hands[key][0] += TORCH_PAD
        frames[key] = (padded, kind)

    # one canvas for every frame, feet on a shared pivot
    ext = [0, 0, 0]  # left, right, up (from the anchor)
    anchors = {}
    for key, (f, kind) in frames.items():
        ax, ay = anchor_of(f, kind == "lying")
        anchors[key] = (ax, ay)
        ext[0] = max(ext[0], ax)
        ext[1] = max(ext[1], f.width - ax)
        ext[2] = max(ext[2], ay + 1)
    half = int(max(ext[0], ext[1])) + 2
    cw, ch = half * 2, int(ext[2]) + 2
    pivot = (half, ch - 1)

    order = []
    tag_meta = []
    for tag, keys, ms in cfg["tags"]:
        start = len(order)
        for k in keys:
            order.append((k, ms))
        tag_meta.append({"name": tag, "from": start, "to": len(order) - 1, "direction": "forward"})

    rows = (len(order) + COLS - 1) // COLS
    out = Image.new("RGBA", (cw * COLS, ch * rows), (0, 0, 0, 0))
    frame_meta = []
    for i, (k, ms) in enumerate(order):
        f, kind = frames[k]
        ax, ay = anchors[k]
        cx, cy = (i % COLS) * cw, (i // COLS) * ch
        ox, oy = round(cx + pivot[0] - ax), round(cy + pivot[1] - ay)
        out.alpha_composite(f, (ox, oy))
        entry = {"filename": f"{name} {i}", "frame": {"x": cx, "y": cy, "w": cw, "h": ch}, "duration": ms}
        side = 0
        if k in hands:
            side = 1 if hands[k][0] < f.width / 2 else -1
        fl = flame_of(f, side) if cfg.get("torch") else None
        if k in flames:
            fl = flames[k]
        if fl:
            entry["torch"] = {"x": round(fl[0] - ax), "y": round(fl[1] - ay)}
        if k in hands:
            hx, hy, angle = hands[k]
            entry["hand"] = {"x": round(hx - ax), "y": round(hy - ay), "angle": round(angle or 0.0)}
        drawn = cfg.get("faces", {}).get(k)
        if drawn:
            mirrored = mirrors.get(k, False)
            entry["faces"] = ("left" if drawn == "right" else "right") if mirrored else drawn
        frame_meta.append(entry)

    OUT.mkdir(parents=True, exist_ok=True)
    out.save(OUT / f"{name}_sheet.png")
    meta = {
        "frames": frame_meta,
        "meta": {
            "app": APP,
            "image": f"{name}_sheet.png",
            "size": {"w": out.width, "h": out.height},
            "pivot": {"x": pivot[0], "y": pivot[1]},
            "frameTags": tag_meta,
        },
    }
    (OUT / f"{name}_sheet.json").write_text(json.dumps(meta, indent=1), newline="\n")

    # stills for anything that still asks for <name>_se / <name>_ne
    for still, key in ((f"{name}_se", cfg["stills"][0]), (f"{name}_ne", cfg["stills"][1])) if cfg.get("stills") else ():
        f, _ = frames[key]
        ax, ay = anchors[key]
        img = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        img.alpha_composite(f, (round(pivot[0] - ax), round(pivot[1] - ay)))
        img.save(OUT / f"{still}.png")

    print(f"{len(order)} frames, cell {cw}x{ch}, pivot {pivot}, palette {len(pal)} colours")
    if preview:
        big = Image.new("RGBA", out.size, (40, 38, 64, 255))
        big.alpha_composite(out)
        big = big.resize((out.width * 4, out.height * 4), Image.NEAREST)
        # the sword hand (red) and the resting blade direction (yellow)
        from PIL import ImageDraw
        d = ImageDraw.Draw(big)
        for i, e in enumerate(frame_meta):
            if "hand" not in e:
                continue
            cx, cy = (i % COLS) * cw + pivot[0] + e["hand"]["x"], (i // COLS) * ch + pivot[1] + e["hand"]["y"]
            a = math.radians(e["hand"]["angle"])
            d.line([(cx * 4 + 2, cy * 4 + 2), (cx * 4 + 2 + math.cos(a) * 44, cy * 4 + 2 + math.sin(a) * 44)], fill=(255, 220, 0), width=2)
            d.rectangle([cx * 4, cy * 4, cx * 4 + 3, cy * 4 + 3], fill=(255, 0, 0))
        big.save(preview / f"{name}_sheet_x4.png")


# ---------------------------------------------------------------- any other character

def detect_rows(sheet: Image.Image, is_bg):
    """Finds the figures on a sheet and groups them into rows, top to bottom, left to right.
    Returns a list of rows of boxes (x0, y0, x1, y1) in sheet pixels. Labels and specks are
    skipped: anything much shorter than the tallest figure."""
    import numpy as np
    from scipy import ndimage
    arr = np.asarray(sheet.convert("RGB")).astype(int)
    h, w, _ = arr.shape
    fg = np.zeros((h, w), dtype=bool)
    for y in range(h):
        row = arr[y]
        fg[y] = [not is_bg(tuple(c)) for c in row]
    # merge a figure's loose parts (flames, weapons) within a few pixels
    grown = ndimage.binary_dilation(fg, iterations=4)
    labels, n = ndimage.label(grown)
    boxes = []
    for sl in ndimage.find_objects(labels):
        ys, xs = sl
        boxes.append((xs.start, ys.start, xs.stop, ys.stop))
    if not boxes:
        return []
    tallest = max(b[3] - b[1] for b in boxes)
    figs = [b for b in boxes if (b[3] - b[1]) >= tallest * 0.45 and (b[2] - b[0]) >= tallest * 0.2]
    figs.sort(key=lambda b: (b[1] + b[3]) / 2)
    rows = []
    for b in figs:
        cy = (b[1] + b[3]) / 2
        if rows and abs(cy - rows[-1][0]) < tallest * 0.5:
            rows[-1][1].append(b)
            rows[-1][0] = sum((r[1] + r[3]) / 2 for r in rows[-1][1]) / len(rows[-1][1])
        else:
            rows.append([cy, [b]])
    # Figures that touch (a sword over the next frame) come out as one wide box: split any box
    # much wider than its row's median into that many equal parts.
    out = []
    for _, row in rows:
        widths = sorted(b[2] - b[0] for b in row)
        med = widths[len(widths) // 2]
        split = []
        for b in sorted(row):
            k = round((b[2] - b[0]) / med)
            if k >= 2 and (b[2] - b[0]) > med * 1.6:
                step = (b[2] - b[0]) / k
                split += [(round(b[0] + i * step), b[1], round(b[0] + (i + 1) * step), b[3]) for i in range(k)]
            else:
                split.append(b)
        out.append(split)
    return out


def auto_config(name, source, mirror=False, attack_front=None, paper=False):
    """A config for a sheet in the standard layout (see the top of this file). `paper`: the sheet
    is drawn on gridded paper like Cedalion's, not a flat background."""
    sheet = Image.open(source).convert("RGB")
    flat = flat_background(sheet)
    is_bg = (lambda c: flat(c) or is_paper(c)) if paper else flat
    rows = detect_rows(sheet, is_bg)
    if len(rows) < 3:
        raise SystemExit(f"{source.name}: found {len(rows)} rows of figures, need idle, walk and attack rows")
    boxes = {}

    def add(key, b):
        boxes[key] = ((b[0] + 3, b[1] + 3, b[2] - 4, b[3] - 4), mirror, "stand")
        return key

    idle, walk, attack = rows[0], rows[1], rows[2]
    half_i = max(1, len(idle) // 2)
    idle_f, idle_b = add("idle_f", idle[0]), add("idle_b", idle[half_i] if len(idle) > 1 else idle[0])
    half_w = max(1, len(walk) // 2)
    walk_f = [add(f"walk_f{i}", b) for i, b in enumerate(walk[:half_w])]
    walk_b = [add(f"walk_b{i}", b) for i, b in enumerate(walk[half_w:])] or walk_f
    n = len(attack)
    front = attack_front if attack_front else (n // 2 if n % 2 == 0 and n >= 4 else max(1, n - 1))
    atk_f = [add(f"atk_f{i}", b) for i, b in enumerate(attack[:front])]
    atk_b = [add(f"atk_b{i}", b) for i, b in enumerate(attack[front:])] or atk_f
    tags = [
        ("idle_se", [idle_f], 400), ("idle_ne", [idle_b], 400),
        ("walk_se", walk_f, 150), ("walk_ne", walk_b, 150),
        ("attack_se", atk_f, 120), ("attack_ne", atk_b, 120),
        ("hurt_se", [atk_f[0]], 200), ("hurt_ne", [atk_b[0]], 200),
    ]
    # scale to the height of the character's current still (or 32 px)
    target = 32
    still = OUT / f"{name}_se.png"
    if still.exists():
        bb = Image.open(still).getbbox()
        target = bb[3] - bb[1]
    heights = []
    for b in idle[:1] + walk[:1]:
        crop = cut_out(sheet.crop(b), False, is_bg)
        bb = crop.getbbox()
        heights.append(bb[3] - bb[1])
    scale = target / max(heights)
    print(f"{name}: rows of {[len(r) for r in rows]} figures; scale {scale:.3f} to {target} px")
    return dict(source=source, boxes=boxes, tags=tags, scale=scale, palette=20,
                background="paper" if paper else "auto", torch=False, stills=(idle_f, idle_b))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    if not args:
        raise SystemExit(__doc__)
    name = args[0]
    preview = Path(args[1]) if len(args) > 1 else None
    if name in CONFIGS:
        cfg = CONFIGS[name]
    else:
        source = next((p for p in (GENERATED / f"{name}_sheet.png", GENERATED / f"{name}_sheet.webp") if p.exists()), None)
        if source is None:
            raise SystemExit(f"No sheet for {name}: save it as art/generated/{name}_sheet.png")
        attack_front = next((int(f.split("=")[1]) for f in flags if f.startswith("--attack-front=")), None)
        cfg = auto_config(name, source, "--mirror" in flags, attack_front, "--paper" in flags)
    process(name, cfg, preview)


if __name__ == "__main__":
    main()
