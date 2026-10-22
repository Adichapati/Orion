"""Generate the floating-island look: each room's island, distant ruined islands and cloud banks.

Every room is the flat top of an island hanging in the night sky. For each room in
art/maps/rooms.json this draws, around and below its grid:

- a grassy rim one to two tiles wide around the walls, its outer edge ragged;
- cliff faces under the two front edges in layered strata (grass lip, soil, banded stone),
  the left face lit by the moon and the right in shadow, as the walls are;
- a jagged underside narrowing to stalactite points below the front corner;
- hanging roots, ivy strands and moss drips.

It writes art/greybox/island_<room>.png and island_<room>.json ({"origin": the image's top-left
in room screen pixels, relative to cell (0, 0)'s centre; "grid": the grid size it was made for;
"falls": waterfalls the game animates}). It also draws four far islands carrying temple ruins
(far_island_<n>.png, with brazier spots in far_islands.json) and three moonlit cloud banks
(cloud_<n>.png) for the parallax layers. Re-run it after changing a room's size.

    python tools/gen_islands.py [preview dir]
"""
from pathlib import Path
import json
import math
import random
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "greybox"
ROOMS = ROOT / "art" / "maps" / "rooms.json"

# How moonlight tints the unshaded cliffs (a little brighter than the rooms' night ambience).
MOON_TINT = (0.56, 0.57, 0.76)
RIM = 1.35         # tiles of ground outside the grid, before the ragged edge
MAX_DEPTH = 96     # pixels from the front edge to the underside's lowest point
ROOT_SPACE = 30    # room below the underside for hanging roots
# Rooms with a waterfall pouring off the island: fraction along the left face.
FALLS = {"cistern": 0.42, "statue-court": 0.7}


def hexc(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


NIGHT0, NIGHT1, NIGHT2 = hexc("0d0b1a"), hexc("1b1834"), hexc("2e3a5c")
MOON0, MOON1 = hexc("7fa6d8"), hexc("cfe3ff")
OLIVE0, OLIVE1, OLIVE2 = hexc("3a4a2a"), hexc("5d6b3a"), hexc("8c9a5b")
LEATHER, SKIN0, CLAY0 = hexc("4a3326"), hexc("5c3b2e"), hexc("8a3b22")
MARBLE0, MARBLE1, MARBLE2 = hexc("7d776d"), hexc("b9b2a3"), hexc("e8e2d4")
FIRE1, FIRE2 = hexc("e0782c"), hexc("ffc857")

# Cliff tones, lit (left) face and shaded (right) face, from the top stratum down.
STONE_L = [(125, 119, 109), (110, 103, 98), (96, 90, 92), (80, 76, 86), (62, 59, 76), (44, 42, 62)]
STONE_R = [(88, 85, 104), (76, 73, 94), (66, 63, 86), (55, 52, 76), (44, 42, 66), (33, 31, 54)]
BAYER = [[0.0, 0.5], [0.75, 0.25]]


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def h2(x, y, seed):
    h = (x * 374761393 + y * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0


def vnoise(x, y, s, seed):
    gx, gy = x / s, y / s
    ix, iy = math.floor(gx), math.floor(gy)
    fx, fy = gx - ix, gy - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = h2(ix, iy, seed), h2(ix + 1, iy, seed)
    c, d = h2(ix, iy + 1, seed), h2(ix + 1, iy + 1, seed)
    return (a + (b - a) * fx) * (1 - fy) + (c + (d - c) * fx) * fy


class Noise1D:
    def __init__(self, rng, scale):
        self.scale = scale
        self.k = [rng.uniform(-1, 1) for _ in range(256)]

    def __call__(self, t):
        t = t / self.scale + 64
        i = math.floor(t)
        f = t - i
        f = f * f * (3 - 2 * f)
        return self.k[i % 256] * (1 - f) + self.k[(i + 1) % 256] * f


def to_screen(gx, gy):
    return ((gx - gy) * 16.0, (gx + gy) * 8.0)


def to_grid(sx, sy):
    return (sx / 32.0 + sy / 16.0, sy / 16.0 - sx / 32.0)


def room_island(room, seed):
    grid = room["grid"]
    W, H = len(grid[0]), len(grid)
    rng = random.Random(seed)
    edges = {k: Noise1D(rng, 2.2) for k in ("l", "r", "t", "b")}
    m = lambda k, t: RIM + 0.55 * edges[k](t) + 0.25 * edges[k](t * 3.1)
    x0, x1, y0, y1 = -0.5, W - 0.5, -0.5, H - 0.5
    ext = RIM + 1.0
    corners = [to_screen(x0 - ext, y0 - ext), to_screen(x1 + ext, y0 - ext),
               to_screen(x1 + ext, y1 + ext), to_screen(x0 - ext, y1 + ext)]
    minx = math.floor(min(c[0] for c in corners)) - 2
    maxx = math.ceil(max(c[0] for c in corners)) + 2
    miny = math.floor(min(c[1] for c in corners)) - 2
    maxy = math.ceil(max(c[1] for c in corners)) + 2
    w, h = maxx - minx, maxy - miny + MAX_DEPTH + ROOT_SPACE
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()

    top = [[False] * h for _ in range(w)]
    in_grid = [[False] * h for _ in range(w)]
    for x in range(w):
        for y in range(maxy - miny):
            gx, gy = to_grid(x + minx + 0.5, y + miny + 0.5)
            ins = (gx >= x0 - m("l", gy) and gx <= x1 + m("r", gy)
                   and gy >= y0 - m("t", gx) and gy <= y1 + m("b", gx))
            top[x][y] = ins
            in_grid[x][y] = x0 <= gx <= x1 and y0 <= gy <= y1
    # The front edge: the lowest top pixel in each column.
    e = [-1] * w
    for x in range(w):
        for y in range(maxy - miny - 1, -1, -1):
            if top[x][y]:
                e[x] = y
                break
    cols = [x for x in range(w) if e[x] >= 0]
    lx, rx = cols[0], cols[-1]
    bx = max(cols, key=lambda x: e[x])

    # The underside's depth below the front edge: thin at the side tips, deepest under the front
    # corner, with stalactite spikes.
    dn = Noise1D(rng, 9.0)
    spikes = []
    for _ in range(max(4, (rx - lx) // 9)):
        c = rng.uniform(lx + 10, rx - 10)
        u = abs(c - bx) / max(1, (bx - lx) if c < bx else (rx - bx))
        spikes.append((c, rng.uniform(2.5, 6.5), rng.uniform(6, 24) * (1.0 - 0.55 * u)))

    def depth(x):
        u = (x - bx) / max(1, (bx - lx) if x < bx else (rx - bx))
        d = 9 + (MAX_DEPTH - 30) * (1 - min(1.0, abs(u))) ** 1.35 + 5 * dn(x)
        for c, hw, ln in spikes:
            if abs(x - c) < hw:
                d = max(d, d + ln * (1 - abs(x - c) / hw))
        return int(d)

    depths = {x: depth(x) for x in cols}
    cliff = [[False] * h for _ in range(w)]
    for x in cols:
        for y in range(e[x] + 1, min(h, e[x] + 1 + depths[x])):
            cliff[x][y] = True

    # --- the cliff faces and underside
    band_noise = Noise1D(rng, 14.0)
    for x in cols:
        left = x < bx
        tones = STONE_L if left else STONE_R
        drip = rng.randint(0, 4) if rng.random() < 0.35 else 0
        for y in range(e[x] + 1, e[x] + 1 + depths[x]):
            if y >= h:
                break
            d = y - e[x]
            k = d / depths[x]
            th = BAYER[y % 2][x % 2]
            n = vnoise(x, y, 3.0, seed) * 0.65 + vnoise(x, y, 1.3, seed + 1) * 0.35
            if d <= 2 + drip:
                c = OLIVE1 if left else OLIVE0
                if d > 2 or n < 0.3:
                    c = OLIVE0 if left else mix(OLIVE0, NIGHT1, 0.4)
            elif d <= 6:
                c = SKIN0 if left else LEATHER
                if n > 0.72:
                    c = CLAY0 if left else SKIN0
                elif n < 0.25:
                    c = LEATHER if left else mix(LEATHER, NIGHT1, 0.35)
            else:
                # strata parallel to the top edge, of uneven thickness; deeper is darker
                s = (d - 7) + 3.0 * band_noise(x)
                band = int(s // 7)
                depth_k = min(1.0, k * 1.15)
                base = depth_k * (len(tones) - 1.6) + (0.5 if band % 2 else 0.0)
                i = min(len(tones) - 1, max(0, int(base + (n - 0.5) * 1.2 + th * 0.9 - 0.45)))
                c = tones[i]
                if int(s) % 7 == 0 and n < 0.55:
                    c = mix(c, NIGHT1, 0.45)  # a seam between strata
                # cracks
                if vnoise(x * 0.7, y * 1.8, 2.0, seed + 7) > 0.86:
                    c = mix(c, NIGHT0, 0.5)
            # the corner ridge where the two faces meet catches a little light
            if x == bx and 6 < d < depths[x] * 0.5:
                c = mix(c, MARBLE1, 0.25)
            px[x, y] = c + (255,)
    # dark outline under the silhouette
    for x in cols:
        for y in range(h - 1):
            if cliff[x][y] and not cliff[x][y + 1]:
                px[x, y] = NIGHT1 + (255,)
        for y in range(h):
            if cliff[x][y] and ((x == 0 or not cliff[x - 1][y]) or (x == w - 1 or not cliff[x + 1][y])):
                if y - e[x] > 2:
                    px[x, y] = mix(px[x, y][:3], NIGHT1, 0.6) + (255,)

    # --- the grassy rim on top (the grid itself is covered by the floor tiles)
    for x in range(w):
        for y in range(maxy - miny):
            if not top[x][y] or in_grid[x][y]:
                continue
            n = vnoise(x, y, 4.0, seed + 3) * 0.7 + vnoise(x, y, 1.5, seed + 4) * 0.3
            th = BAYER[y % 2][x % 2]
            if n < 0.3:
                c = LEATHER if n + th * 0.1 < 0.25 else OLIVE0
            elif n + (th - 0.5) * 0.25 < 0.55:
                c = OLIVE0
            elif n < 0.8:
                c = OLIVE1
            else:
                c = OLIVE2
            if h2(x, y, seed + 9) > 0.985:
                c = MARBLE0  # pebbles
            # edges: a bright grass lip at the front, a dark line at the back
            if y == e[x]:
                c = OLIVE2 if n > 0.35 else OLIVE1
            elif y == 0 or not top[x][y - 1]:
                c = mix(OLIVE0, NIGHT1, 0.5)
            px[x, y] = c + (255,)
    # grass tufts poking over the front edge
    for x in cols:
        if rng.random() < 0.18 and e[x] > 0:
            px[x, e[x] - 1] = OLIVE2 + (255,)

    # --- ruins on the rim: broken column stumps, a loose drum and a fallen column, on the
    # grass in front of the walls (kept low, so they never reach up into the wall above)
    def put(x, y, c):
        if 0 <= x < w and 0 <= y < maxy - miny and top[x][y] and not in_grid[x][y]:
            px[x, y] = c + (255,)

    def stump(x, y, hgt):
        for dx in range(-3, 4):
            put(x + dx, y, MARBLE0)
            put(x + dx, y + 1, NIGHT1)
        for yy in range(y - hgt, y):
            for dx in range(-2, 3):
                c = MARBLE2 if dx == -2 else (MARBLE1 if dx in (-1, 1) else (MARBLE0 if dx == 2 else MARBLE1))
                if dx == 0 and yy % 2 == 0:
                    c = mix(MARBLE1, MARBLE0, 0.5)  # fluting
                put(x + dx, yy, c)
        for dx in range(-2, 3):  # broken top
            put(x + dx, y - hgt - rng.randint(0, 2) + (1 if dx == 2 else 0), MARBLE2 if dx < 1 else MARBLE0)
        for yy in range(y - hgt - 1, y + 1):
            put(x - 3, yy, NIGHT1)
            put(x + 3, yy, NIGHT1)

    def fallen(x, y, length, slope):
        for i in range(length):
            cx, cy = x + i, y + round(i * slope)
            for t in range(-2, 2):
                c = MARBLE2 if t == -2 else (MARBLE1 if t < 1 else MARBLE0)
                if i % 6 == 5:
                    c = mix(c, NIGHT1, 0.45)  # joint between drums
                put(cx, cy + t, c)
            put(cx, cy - 3, NIGHT1)
            put(cx, cy + 2, NIGHT1)

    spots = []
    for _ in range(400):
        x = rng.randint(lx + 8, rx - 8)
        y = e[x] - rng.randint(3, 6)
        gx, gy = to_grid(x + minx + 0.5, y + miny + 0.5)
        outside = gx - x1 if gx > x1 else (gy - y1 if gy > y1 else -1)
        if 0.45 < outside < 1.1 and abs(x - bx) > 16 and all(abs(x - sx) > 26 for sx, _ in spots):
            spots.append((x, y))
        if len(spots) >= 4:
            break
    for i, (x, y) in enumerate(spots):
        if i == 2:
            fallen(x - 8, y, rng.randint(13, 17), 0.5 if x < bx else -0.5)
        elif i == 3:
            for dx in range(-3, 3):  # a loose drum on its side
                for t in range(-2, 2):
                    put(x + dx, y + t, MARBLE1 if t < 0 else MARBLE0)
            for t in range(-2, 2):
                put(x - 4, y + t, NIGHT1)
                put(x + 3, y + t, mix(MARBLE0, NIGHT1, 0.4))
        else:
            stump(x, y, rng.randint(4, 7))

    # --- hanging roots and ivy
    for _ in range((rx - lx) // 5):
        x = rng.randint(lx + 3, rx - 3)
        from_bottom = rng.random() < 0.55
        y = e[x] + (depths[x] - 1 if from_bottom else rng.randint(3, 6))
        length = rng.randint(8, 24) if from_bottom else rng.randint(5, 14)
        col = LEATHER
        for i in range(length):
            if 0 <= x < w and 0 <= y < h and (not cliff[x][y] or not from_bottom):
                px[x, y] = (col if i % 5 else SKIN0) + (255,)
            y += 1
            if i % rng.randint(3, 5) == 0:
                x += rng.choice((-1, 0, 1))
    for _ in range((rx - lx) // 12):
        x = rng.randint(lx + 4, rx - 4)
        y = e[x] + 1
        for i in range(rng.randint(6, 18)):
            if 0 <= x < w and 0 <= y < h:
                px[x, y] = (OLIVE0 if i % 3 else OLIVE1) + (255,)
                if i % 3 == 1:
                    lf = x + (1 if i % 2 else -1)
                    if 0 <= lf < w:
                        px[lf, y] = OLIVE1 + (255,)
            y += 1
            if i % 4 == 3:
                x += rng.choice((-1, 1))

    falls = []
    if room["id"] in FALLS:
        fx = int(lx + FALLS[room["id"]] * (bx - lx)) if FALLS[room["id"]] < 1 else bx
        if FALLS[room["id"]] > 0.5:
            fx = int(bx + (FALLS[room["id"]] - 0.5) * 2 * (rx - bx))
        falls.append({"x": fx + minx, "y": e[fx] + miny + 1, "length": depths[fx] + 70})
    # Split the rim (drawn in the room's own light, so torches reach it) from the cliffs and
    # underside, which the game draws unshaded: pre-darkened here to moonlight so they read
    # against the night sky instead of sinking into the room's darkness.
    cliff_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cp = cliff_img.load()
    for x in range(w):
        for y in range(h):
            c = px[x, y]
            if c[3] == 0:
                continue
            if y < maxy - miny and top[x][y]:
                continue
            cp[x, y] = (round(c[0] * MOON_TINT[0]), round(c[1] * MOON_TINT[1]), round(c[2] * MOON_TINT[2]), c[3])
            px[x, y] = (0, 0, 0, 0)
    meta = {"origin": [minx, miny], "grid": [W, H], "falls": falls}
    return img, cliff_img, meta


def far_island(rng, seed, w, kind):
    """A small island far off, hazed toward the sky, with temple ruins on top."""
    h = w + 40
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    haze = lambda c, t=0.55: mix(c, (40, 44, 78), t) + (255,)
    cx = w / 2
    top_y = 34
    half = w / 2 - 2
    dn = Noise1D(rng, 6.0)
    fires = []
    # the top: a flat iso lozenge
    for x in range(w):
        dx = abs(x - cx) / half
        if dx > 1:
            continue
        ht = (1 - dx) * half * 0.32
        for y in range(int(top_y - ht), int(top_y + ht) + 1):
            px[x, y] = haze(OLIVE0 if (x + y) % 3 else OLIVE1)
        # underside
        depth = 5 + (w * 0.55) * (1 - dx) ** 1.6 + 3 * dn(x)
        if rng.random() < 0.08:
            depth += rng.uniform(4, 12) * (1 - dx)
        y0 = int(top_y + ht) + 1
        for y in range(y0, min(h, y0 + int(depth))):
            k = (y - y0) / max(1, depth)
            c = STONE_L[min(5, int(k * 5 + 0.5))] if x < cx else STONE_R[min(5, int(k * 5 + 0.5))]
            px[x, y] = haze(c, 0.5 + 0.2 * k)
        if y0 + int(depth) < h:
            px[x, y0 + int(depth) - 1] = haze(NIGHT1, 0.3)
    # ruins on top
    base = top_y
    lit, shade = haze(MARBLE1, 0.45), haze(MARBLE0, 0.5)
    if kind in ("temple", "colonnade"):
        n = 4 if kind == "temple" else 5
        span = w * 0.5
        xs = [int(cx - span / 2 + i * span / (n - 1)) for i in range(n)]
        col_h = int(w * 0.24)
        for i, x in enumerate(xs):
            hh = col_h if (kind == "temple" or i % 2 == 0) else int(col_h * rng.uniform(0.4, 0.8))
            for y in range(base - hh, base + 1):
                px[x, y] = lit
                px[x + 1, y] = shade
            px[x - 1, base - hh] = lit
            px[x + 2, base - hh] = shade
        if kind == "temple":
            # architrave and pediment
            yb = base - col_h - 1
            for x in range(xs[0] - 2, xs[-1] + 4):
                px[x, yb] = lit
                px[x, yb - 1] = shade
            peak = (xs[0] + xs[-1] + 1) / 2
            ph = int((xs[-1] - xs[0]) * 0.22)
            for x in range(xs[0] - 2, xs[-1] + 4):
                t = 1 - abs(x - peak) / ((xs[-1] - xs[0]) / 2 + 3)
                for y in range(yb - 1 - int(ph * t), yb - 1):
                    px[x, y] = lit if x < peak else shade
            fires.append([xs[0] - 4, base - 3])
        else:
            fires.append([xs[-1] + 4, base - 3])
    elif kind == "tholos":
        r = int(w * 0.16)
        for x in range(int(cx - r), int(cx + r) + 1):
            for y in range(base - int(w * 0.2), base + 1):
                if (x - cx) % 3 == 0:
                    px[x, y] = lit if x < cx else shade
        for x in range(int(cx - r - 1), int(cx + r) + 2):
            t = 1 - ((x - cx) / (r + 1)) ** 2
            for y in range(base - int(w * 0.2) - int(4 * t) - 1, base - int(w * 0.2)):
                px[x, y] = lit if x < cx else shade
        fires.append([int(cx + r + 4), base - 2])
    else:  # broken wall and a lone column with an olive tree
        for x in range(int(cx - w * 0.25), int(cx)):
            top = base - int(6 + 4 * dn(x * 3))
            for y in range(top, base + 1):
                px[x, y] = shade if (y + x // 4) % 4 else lit
        for y in range(base - int(w * 0.25), base + 1):
            px[int(cx + 6), y] = lit
            px[int(cx + 7), y] = shade
        for dx in range(-4, 5):
            for dy in range(-3, 3):
                if dx * dx / 16 + dy * dy / 9 <= 1:
                    px[int(cx + w * 0.22) + dx, base - 8 + dy] = haze(OLIVE1 if dy < 0 else OLIVE0, 0.5)
        for y in range(base - 6, base + 1):
            px[int(cx + w * 0.22), y] = haze(LEATHER, 0.5)
    # hanging roots
    for _ in range(w // 8):
        x = rng.randint(int(cx - half * 0.6), int(cx + half * 0.6))
        y = h - 1
        while y > 0 and px[x, y][3] == 0:
            y -= 1
        for i in range(rng.randint(3, 9)):
            if y + i < h:
                px[x, y + i] = haze(LEATHER, 0.45)
    bb = img.getbbox()
    img = img.crop((0, bb[1], w, bb[3]))
    fires = [[f[0], f[1] - bb[1]] for f in fires]
    return img, fires


def cloud_bank(rng, w, h):
    """A long low bank of cloud, moonlit along its top, thinning to dithered wisps below. It
    wraps at its left and right ends, so it can scroll forever."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    puffs = []
    x = 0.0
    while x < w:
        r = rng.uniform(8, 17)
        puffs.append((x, h * 0.62 - rng.uniform(0, h * 0.3), r))
        x += r * rng.uniform(1.0, 1.6)
    mask = [[False] * h for _ in range(w)]
    for y in range(h):
        for x in range(w):
            for cx, cy, r in puffs:
                dx = (x - cx + w / 2) % w - w / 2
                if dx * dx + ((y - cy) * 1.7) ** 2 <= r * r:
                    mask[x][y] = True
                    break
    for y in range(h):
        for x in range(w):
            if not mask[x][y]:
                continue
            fade = (y - h * 0.6) / (h * 0.4)
            th = BAYER[y % 2][x % 2]
            if fade > 0 and fade > th * 0.85 + 0.12:
                continue
            up = 0
            while up < 3 and y - up - 1 >= 0 and mask[x][y - up - 1]:
                up += 1
            if up == 0:
                c, a = MOON0, 210
            elif up == 1:
                c, a = mix(NIGHT2, MOON0, 0.45), 220
            elif up == 2 and th > 0.4:
                c, a = mix(NIGHT2, MOON0, 0.2), 220
            else:
                c, a = (NIGHT2 if vnoise(x, y, 5.0, 3) > 0.4 else mix(NIGHT2, NIGHT1, 0.45)), 215
            px[x, y] = c + (a,)
    return img


def main():
    preview = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    data = json.loads(ROOMS.read_text(encoding="utf-8"))
    for i, room in enumerate(data["rooms"]):
        img, cliff, meta = room_island(room, 1000 + i * 17)
        img.save(OUT / f"island_{room['id']}.png")
        cliff.save(OUT / f"island_{room['id']}_cliff.png")
        (OUT / f"island_{room['id']}.json").write_text(json.dumps(meta), newline="\n")
        print(f"island_{room['id']}.png {img.size} origin {meta['origin']}")
        if preview:
            big = Image.new("RGBA", img.size, NIGHT0 + (255,))
            big.alpha_composite(img)
            big.alpha_composite(cliff)
            big.resize((img.width * 2, img.height * 2), Image.NEAREST).save(preview / f"island_{room['id']}_x2.png")
    rng = random.Random(5)
    far = []
    for n, (w, kind) in enumerate([(64, "temple"), (44, "tholos"), (54, "colonnade"), (36, "ruin")]):
        img, fires = far_island(rng, 50 + n, w, kind)
        img.save(OUT / f"far_island_{n}.png")
        far.append({"name": f"far_island_{n}", "fires": fires})
    (OUT / "far_islands.json").write_text(json.dumps(far), newline="\n")
    for n, (w, h) in enumerate([(480, 36), (480, 30), (480, 44)]):
        cloud_bank(random.Random(90 + n), w, h).save(OUT / f"cloud_{n}.png")
    print("far islands and clouds written")
    if preview:
        sheet = Image.new("RGBA", (480, 300), NIGHT0 + (255,))
        x = 4
        for n in range(4):
            im = Image.open(OUT / f"far_island_{n}.png")
            sheet.alpha_composite(im, (x, 10))
            x += im.width + 10
        for n in range(3):
            sheet.alpha_composite(Image.open(OUT / f"cloud_{n}.png"), (0, 140 + n * 50))
        sheet.resize((960, 600), Image.NEAREST).save(preview / "distance_x2.png")


if __name__ == "__main__":
    main()
