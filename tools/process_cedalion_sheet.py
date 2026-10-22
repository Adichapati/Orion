"""Turn the hand-made Cedalion sheet (art/generated/cedalion_friend_sheet.webp) into game frames.

Writes art/final/cedalion_sheet.png + cedalion_sheet.json in Aseprite's json-array format, so a
real Aseprite export (File > Export Sprite Sheet, JSON data, tags) can replace it later with no
code changes, plus art/final/cedalion_se.png / cedalion_ne.png stills.

For every frame it removes the paper, grid and drop shadow, cuts the sword out (the game draws
the sword as its own sprite: hidden while Cedalion is unarmed, swung in an arc, one per weapon),
mirrors it so all front frames face south-east and all back frames face north-east, scales it
down to the in-game size, maps every frame to one shared palette (so colours never flicker
between frames), lines the feet up on one pivot and records where the torch flame and the sword
hand are, so the torch light and the sword follow the hands.

    python tools/process_cedalion_sheet.py
"""
from collections import deque
from pathlib import Path
import json
import math
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art" / "generated" / "cedalion_friend_sheet.webp"
OUT = ROOT / "art" / "final"
PREVIEW = Path(sys.argv[1]) if len(sys.argv) > 1 else None

SCALE = 0.19          # sheet pixels -> game pixels (figure ~26 px tall, like the doc's 16x24 hero plus hair and sword)
PALETTE_SIZE = 22
COLS = 8

# (box in the sheet, mirror?, kind) - boxes found by scanning the sheet; mirror normalises facing
BOXES = {
    "idle_f": ((60, 50, 280, 222), True, "stand"),
    "idle_f2": ((380, 50, 590, 222), True, "stand"),
    "idle_b": ((640, 50, 880, 222), False, "stand"),
    "idle_b2": ((950, 50, 1190, 222), False, "stand"),
    "walk_f0": ((15, 275, 182, 429), True, "stand"),
    "walk_f1": ((191, 274, 320, 430), True, "stand"),
    "walk_f2": ((327, 274, 458, 430), True, "stand"),
    "walk_f3": ((462, 274, 596, 430), True, "stand"),
    "walk_b0": ((638, 276, 780, 429), True, "stand"),
    "walk_b1": ((775, 276, 912, 429), True, "stand"),
    "walk_b2": ((912, 276, 1051, 430), True, "stand"),
    "walk_b3": ((1054, 276, 1199, 429), True, "stand"),
    "atk_f0": ((68, 489, 266, 640), False, "stand"),
    "atk_f1": ((387, 493, 536, 641), False, "stand"),
    "atk_f2": ((684, 492, 870, 640), False, "stand"),
    "atk_b": ((978, 487, 1163, 640), False, "stand"),
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

# The sheet's lying poses sit on a grass tile that can't be separated cleanly at this scale, so the
# game animates the fall in code instead.
# Animation tags: name -> (frame keys, ms per frame). Facing suffix: _se front, _ne back; the game
# mirrors them for _sw / _nw.
TAGS = [
    ("idle_se", ["idle_f"], 400), ("idle_ne", ["idle_b"], 400),
    ("look_se", ["idle_f2"], 400), ("look_ne", ["idle_b2"], 400),
    # stride, pass, stride, pass: two footfalls per cycle, in step with the footstep sounds
    ("walk_se", ["walk_f2", "walk_f0", "walk_f3", "walk_f1"], 150),
    ("walk_ne", ["walk_b1", "walk_b0", "walk_b3", "walk_b2"], 150),
    ("attack_se", ["atk_f0", "atk_f1", "atk_f2"], 100),
    ("attack_ne", ["atk_b"], 300),
    ("parry_se", ["atk_f0"], 300), ("parry_ne", ["atk_b"], 300),
    ("lunge_se", ["atk_f2"], 300), ("lunge_ne", ["atk_b"], 300),
    ("jump_se", ["walk_f1"], 300), ("jump_ne", ["walk_b1"], 300),
    ("dodge_se", ["walk_f3"], 300), ("dodge_ne", ["walk_b3"], 300),
]


def is_paper(c):
    """The sheet's blue-grey paper, grid and drop shadow. Cream tunics and the pale swing arc lean
    warm (red >= blue), so they stay."""
    r, g, b = c[:3]
    return (max(r, g, b) - min(r, g, b)) < 42 and max(r, g, b) > 112 and b >= r - 6


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


def cut_out(img: Image.Image, lying: bool) -> Image.Image:
    """Flood the background in from the crop's border; the dark outline protects the figure."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    if lying:
        tile = tile_colours(img)
        # tight match, and nothing bright: hair and skin highlights are never tile
        passable = lambda c: is_paper(c) or (max(c[:3]) < 190 and near_any(c, tile, 28))
    else:
        passable = is_paper
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


def cut_sword(img: Image.Image, key, origin):
    """Clears the blade and crossguard (and any painted swing arc) out of a cut-out frame. Points
    are in sheet pixels; `origin` is the crop's top-left in the sheet."""
    tip, guard, _hand = SWORDS.get(key, (None, None, None))
    caps = []
    if tip:
        dx, dy = guard[0] - tip[0], guard[1] - tip[1]
        n = (dx * dx + dy * dy) ** 0.5
        ux, uy = dx / n, dy / n
        caps.append((tip, (guard[0] + ux * 3, guard[1] + uy * 3), BLADE_R, False))
        caps.append(((guard[0] - uy * GUARD_HALF, guard[1] + ux * GUARD_HALF),
                     (guard[0] + uy * GUARD_HALF, guard[1] - ux * GUARD_HALF), GUARD_R, False))
    for x0, y0, x1, y1, r in ARCS.get(key, []):
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


def shrink(img: Image.Image) -> Image.Image:
    bb = img.getbbox()
    img = img.crop(bb)
    w, h = img.size
    tw, th = max(1, round(w * SCALE)), max(1, round(h * SCALE))
    small = img.convert("RGBa").resize((tw, th), Image.BOX).convert("RGBA")
    px = small.load()
    for y in range(th):
        for x in range(tw):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    return small


def build_palette(frames):
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
    q = sample.quantize(colors=PALETTE_SIZE, method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette()[: PALETTE_SIZE * 3]
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


def flame_of(f: Image.Image):
    """Where the torch flame is. After mirroring the torch is always on the figure's left, and the
    golden hair sits in the middle, so only orange pixels in the left third count."""
    bb = f.getbbox()
    limit = bb[0] + (bb[2] - bb[0]) * 0.36
    pts = []
    for y in range(f.height):
        for x in range(f.width):
            c = f.getpixel((x, y))
            if c[3] and x < limit and is_flame(c):
                pts.append((x, y))
    if len(pts) < 3:
        return None
    return (sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts))


def main():
    sheet = Image.open(SRC).convert("RGB")
    raw = {}
    hands = {}
    for key, (box, mirror, kind) in BOXES.items():
        x0, y0, x1, y1 = box
        origin = (max(0, x0 - 4), max(0, y0 - 4))
        crop = sheet.crop((origin[0], origin[1], min(sheet.width, x1 + 5), min(sheet.height, y1 + 5)))
        cut = cut_sword(cut_out(crop, kind == "lying"), key, origin)
        tip, guard, hand = SWORDS.get(key, (None, None, None))
        if mirror:
            cut = cut.transpose(Image.FLIP_LEFT_RIGHT)
        bb = cut.getbbox()
        small = shrink(cut)
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
        raw[key] = (small, kind)
    for key, src in ANGLE_FROM.items():
        if key in hands and src in hands:
            hands[key][2] = hands[src][2]
    pal = build_palette([f for f, _ in raw.values()])
    ink = min(pal, key=lambda p: p[0] + p[1] + p[2])
    frames = {}
    for key, (f, kind) in raw.items():
        frames[key] = (finish(f, pal, ink), kind)

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
    for name, keys, ms in TAGS:
        start = len(order)
        for k in keys:
            order.append((k, ms))
        tag_meta.append({"name": name, "from": start, "to": len(order) - 1, "direction": "forward"})

    rows = (len(order) + COLS - 1) // COLS
    out = Image.new("RGBA", (cw * COLS, ch * rows), (0, 0, 0, 0))
    frame_meta = []
    for i, (k, ms) in enumerate(order):
        f, kind = frames[k]
        ax, ay = anchors[k]
        cx, cy = (i % COLS) * cw, (i // COLS) * ch
        ox, oy = round(cx + pivot[0] - ax), round(cy + pivot[1] - ay)
        out.alpha_composite(f, (ox, oy))
        entry = {"filename": f"cedalion {i}", "frame": {"x": cx, "y": cy, "w": cw, "h": ch}, "duration": ms}
        fl = flame_of(f)
        if fl:
            entry["torch"] = {"x": round(fl[0] - ax), "y": round(fl[1] - ay)}
        if k in hands:
            hx, hy, angle = hands[k]
            entry["hand"] = {"x": round(hx - ax), "y": round(hy - ay), "angle": round(angle or 0.0)}
        frame_meta.append(entry)

    OUT.mkdir(parents=True, exist_ok=True)
    out.save(OUT / "cedalion_sheet.png")
    meta = {
        "frames": frame_meta,
        "meta": {
            "app": "tools/process_cedalion_sheet.py",
            "image": "cedalion_sheet.png",
            "size": {"w": out.width, "h": out.height},
            "pivot": {"x": pivot[0], "y": pivot[1]},
            "frameTags": tag_meta,
        },
    }
    (OUT / "cedalion_sheet.json").write_text(json.dumps(meta, indent=1))

    # stills for anything that still asks for cedalion_se / cedalion_ne
    for still, key in (("cedalion_se", "idle_f"), ("cedalion_ne", "idle_b")):
        f, _ = frames[key]
        ax, ay = anchors[key]
        img = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        img.alpha_composite(f, (round(pivot[0] - ax), round(pivot[1] - ay)))
        img.save(OUT / f"{still}.png")

    print(f"{len(order)} frames, cell {cw}x{ch}, pivot {pivot}, palette {len(pal)} colours")
    if PREVIEW:
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
        big.save(PREVIEW / "cedalion_sheet_x4.png")
        w = Image.open(ROOT / "art" / "final" / "watchman_se.png").convert("RGBA")
        line = Image.new("RGBA", (cw * 3 + w.width + 8, max(ch, w.height) + 4), (60, 58, 80, 255))
        line.alpha_composite(Image.open(OUT / "cedalion_se.png"), (2, line.height - ch - 2))
        line.alpha_composite(Image.open(OUT / "cedalion_ne.png"), (cw + 2, line.height - ch - 2))
        line.alpha_composite(w, (cw * 2 + 6, line.height - w.height - 2))
        line.resize((line.width * 5, line.height * 5), Image.NEAREST).save(PREVIEW / "cedalion_scale_x5.png")


if __name__ == "__main__":
    main()
