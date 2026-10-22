"""Generate the title screen's floating islands, at the game's pixel size (480x270, shown at 2x).

- title_island_main.png: the near island, a grassy top seen slightly from above with a ruined
  temple, a fallen drum, amphorae and a bronze brazier, strata cliffs lit warm on the left and
  moonlit blue-grey on the right, a jagged underside with roots and ivy, and a thin waterfall
  pouring off the front edge (the title animates the flame and the falling streaks).
- title_island_back_0.png, title_island_back_1.png: two far islands, a third of the size, with
  column silhouettes, tinted toward the night haze.
- title_cloud_0..2.png: three tileable moonlit cloud bands (480 wide) for the parallax sea.
- title_moon.png: the moon.

Spots the title needs (brazier, waterfall) are constants in scripts/ui/title_screen.gd.

    python tools/gen_title.py
"""
from pathlib import Path
import math
import random

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "greybox"


def palette():
    cols = {}
    for line in (ROOT / "art" / "palette" / "orion.gpl").read_text().splitlines():
        parts = line.split()
        if len(parts) >= 4 and parts[0].isdigit():
            cols[" ".join(parts[3:]).split(" (")[0].split(" #")[0].strip()] = tuple(int(p) for p in parts[:3])
    return cols


P = palette()
N0, N1, N2 = P["Night 0"], P["Night 1"], P["Night 2"]
M0, M1 = P["Moon 0"], P["Moon 1"]
F0, F1, F2, F3 = P["Fire 0"], P["Fire 1"], P["Fire 2"], P["Fire 3"]
S0, S1, S2 = P["Marble 0"], P["Marble 1"], P["Marble 2"]
C0, C1, C2 = P["Clay 0"], P["Clay 1"], P["Clay 2"]
A0, A1, POOL = P["Aegean 0"], P["Aegean 1"], P["Pool"]
O0, O1, O2 = P["Olive 0"], P["Olive 1"], P["Olive 2"]
BRONZE, LEATHER = P["Bronze"], P["Leather"]
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dith(x, y, t):
    """True on a 4x4 ordered-dither pattern covering fraction t."""
    return BAYER[y % 4][x % 4] < t * 16


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def set(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return None

    def rect(self, x, y, w, h, c):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.set(xx, yy, c)

    def save(self, name):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c is not None:
                    img.putpixel((x, y), c + (255,))
        img.save(OUT / name)


FAR = {}


def haze(c, k):
    """A colour as seen through the night haze: one step (k < 0.5) or two toward Night 2/1."""
    if not FAR:
        FAR.update({O2: O1, O1: O0, O0: N2, S2: M0, S1: M0, S0: N2, M1: M0, M0: N2, C2: N2, C1: N2,
                    C0: N1, LEATHER: N1, N2: N1, N1: N1, N0: N1, BRONZE: C0, A1: A0})
    c = FAR.get(c, c)
    if k >= 0.5:
        c = FAR.get(c, c) if c not in (S2, S1, M0) else (M0 if c != M0 else N2)
    return c


def island(cv, rng, cx, cy, rx, ry, cliff, spike, warm=True, grass=True):
    """Draw an island top (irregular ellipse), strata cliffs and a jagged underside.
    Returns (top, front): per-column top and front-edge y of the grass."""
    w = cv.w
    ph = [rng.uniform(0, math.tau) for _ in range(4)]
    top, front = {}, {}
    for x in range(w):
        dx = (x - cx) / rx
        wob = 0.05 * math.sin(dx * 7 + ph[0]) + 0.04 * math.sin(dx * 13 + ph[1])
        r = 1.0 + wob
        if abs(dx) >= r:
            continue
        hh = ry * math.sqrt(max(0.0, 1 - (dx / r) ** 2))
        top[x] = int(round(cy - hh * (1 + 0.06 * math.sin(dx * 9 + ph[2]))))
        front[x] = int(round(cy + hh))
    xs = sorted(top)
    # Cliff depth and the underside: deeper toward a point a little right of centre.
    tipx = cx + rx * 0.12
    jag = {}
    for x in xs:
        if x % 3 == 0 or x not in jag:
            j = rng.randint(-4, 6)
        jag[x] = j
    for x in xs:
        d = cliff + int(3 * math.sin(x * 0.21 + ph[3]))
        u = max(0.0, 1 - abs(x - tipx) / (rx * 1.05))
        under = int(spike * u ** 1.6) + (jag[x] if u > 0.1 else 0)
        y0, y1, y2 = front[x], front[x] + d, front[x] + d + max(0, under)
        side = (x - cx) / rx  # -1 left .. 1 right
        for y in range(top[x], y2 + 1):
            if y <= front[x]:
                continue
            if y < y1:  # strata
                band = ((y - y0) + (x // 9) % 2) // 4
                lightband = band % 2 == 0
                if side < -0.25 and warm:
                    c = (C1 if lightband else C0) if y - y0 < 8 else (C0 if lightband else LEATHER)
                    if side < -0.6 and lightband and y - y0 < 5:
                        c = C2
                elif side > 0.25:
                    c = (M0 if lightband and y - y0 < 6 else N2) if lightband else N1
                else:
                    c = (S0 if lightband else N2) if y - y0 < 12 else (N2 if lightband else N1)
                    if warm and side < 0 and lightband and dith(x, y, -side * 2):
                        c = C0
                # The top of each band catches light.
                if (y - y0) % 4 == 0 and lightband and side < 0.6:
                    c = S1 if side > -0.25 else (C2 if warm else S1)
                cv.set(x, y, c)
            else:  # underside rock, darker going down
                k = (y - y1) / max(1, spike)
                c = N2 if k < 0.25 or (k < 0.55 and dith(x, y, 1.6 - k * 2.6)) else N1
                if k > 0.8 and dith(x, y, 0.5):
                    c = N0
                if side > 0.25 and k < 0.3 and dith(x, y, 0.22 - k * 0.5):
                    c = M0
                if side < -0.3 and k < 0.2 and warm and dith(x, y, 0.4):
                    c = C0
                cv.set(x, y, c)
        # Vertical cracks.
        if rng.random() < 0.08:
            for y in range(y0 + 2, y1 + rng.randint(0, 10)):
                if cv.get(x, y) is not None:
                    cv.set(x, y, N1 if y < y1 else N0)
    # Outline the underside silhouette darker.
    for x in xs:
        for y in range(cv.h - 1, 0, -1):
            if cv.get(x, y) is not None:
                cv.set(x, y, N0)
                break
    # The grass top.
    if grass:
        for x in xs:
            for y in range(top[x], front[x] + 1):
                u = (x - (cx - rx)) / (2 * rx)
                v = (y - top[x]) / max(1, front[x] - top[x])
                lit = (1 - u) * 0.6 + (1 - v) * 0.5
                c = O2 if lit > 0.88 else (O1 if lit > 0.45 else O0)
                if 0.4 < lit < 0.48 and dith(x, y, 0.5):
                    c = O0
                if 0.84 < lit < 0.9 and dith(x, y, 0.5):
                    c = O1
                cv.set(x, y, c)
            cv.set(x, top[x], O2 if x < cx + rx * 0.3 else O1)
        # Tufts and moss along the back and the front lip.
        for x in xs:
            if rng.random() < 0.35:
                cv.set(x, top[x] - 1, O1 if x > cx else O2)
            if rng.random() < 0.5:
                y = front[x] + 1
                cv.set(x, y, O1 if x < cx else O0)
                if rng.random() < 0.4:
                    cv.set(x, y + 1, O0)
        for _ in range(int(rx * ry / 30)):
            x = rng.choice(xs)
            y = rng.randint(top[x] + 2, max(top[x] + 2, front[x] - 2))
            cv.set(x, y, O2)
            cv.set(x + 1, y, O1)
            cv.set(x, y + 1, O0)
    return top, front


def column(cv, x, base, h, w=6, capital=True, k=0.0):
    """A fluted marble column, lit from the left."""
    for yy in range(base - h, base):
        for xx in range(w):
            c = S2 if xx == 0 else (S1 if xx < w - 2 else S0)
            if xx == 2 and (yy % 3) != 0:
                c = S1 if c == S2 else S0
            cv.set(x + xx, yy, haze(c, k) if k else c)
    if capital:
        cv.rect(x - 1, base - h - 2, w + 2, 2, haze(S2, k) if k else S2)
        cv.set(x + w, base - h - 1, haze(S0, k) if k else S0)
    cv.rect(x - 1, base, w + 2, 1, haze(S0, k) if k else S0)


def main_island():
    rng = random.Random(4011)
    W, H = 240, 200
    cv = Canvas(W, H)
    cx, cy, rx, ry = 120, 66, 110, 36
    top, front = island(cv, rng, cx, cy, rx, ry, 24, 70)
    # Hanging roots and ivy from the cliff foot and the front lip.
    for _ in range(40):
        x = rng.randint(cx - rx + 10, cx + rx - 10)
        if x not in front:
            continue
        y = front[x] + rng.randint(18, 30)
        n = rng.randint(4, 16)
        c = LEATHER if rng.random() < 0.6 else O0
        for i in range(n):
            if cv.get(x, y + i) is None and i > 2 and rng.random() < 0.5:
                break
            cv.set(x + (1 if i > n // 2 and rng.random() < 0.2 else 0), y + i, c)
    for _ in range(14):  # ivy curtains from the grass lip
        x = rng.randint(cx - rx + 6, cx + rx - 6)
        if x not in front:
            continue
        n = rng.randint(5, 14)
        for i in range(n):
            xx = x + int(1.5 * math.sin(i * 0.8))
            cv.set(xx, front[x] + 2 + i, O1 if i < 3 else O0)
            if i % 3 == 1:
                cv.set(xx + 1, front[x] + 2 + i, O0)
    # A marble paving under the temple at the back left.
    for y in range(44, 62):
        for x in range(40, 128):
            if x in top and y > top[x] + 3 and abs((x - 84) / 46) + abs((y - 53) / 10) < 1.0:
                c = S1 if (x + y // 3) % 7 else S0
                if dith(x, y, 0.15):
                    c = S0
                cv.set(x, y, c)
    for x in range(42, 126):  # stylobate edge
        y = 53 + int(10 * (1 - abs((x - 84) / 46)))
        if abs((x - 84) / 46) < 1:
            cv.set(x, y, S0)
            cv.set(x, y + 1, N2)
    # Columns: two whole, one broken, one whole; a lintel across the first pair with a broken
    # pediment corner.
    base = [(52, 54), (68, 51), (88, 50), (106, 53)]
    heights = [34, 34, 18, 32]
    for (x, b), h in zip(base, heights):
        column(cv, x, b, h, capital=h > 20)
    for xx in range(50, 78):  # lintel
        for yy in range(16, 20):
            c = S2 if yy == 16 else (S1 if yy < 19 else S0)
            if xx > 74 and yy > 17 and (xx + yy) % 2:
                continue
            cv.set(xx, yy, c)
    for i in range(10):  # pediment rake, broken off
        for xx in range(50 + i * 2, 66 - i):
            cv.set(xx, 15 - i, S1 if xx < 58 else S0)
        cv.set(50 + i * 2, 15 - i, S2)
    cv.rect(91, 30, 3, 2, S2)  # broken column's jagged top
    cv.set(89, 31, S2)
    cv.set(93, 29, S1)
    # A fallen drum on the grass, and bits of rubble.
    dx, dy = 70, 80
    for yy in range(-4, 5):
        for xx in range(-9, 10):
            if abs(yy) <= 4:
                c = S1 if yy < 0 else S0
                if yy == -4:
                    c = S2
                cv.set(dx + xx, dy + yy, c)
    for yy in range(-4, 5):  # its end face
        for xx in range(-2, 3):
            if (xx / 2.5) ** 2 + (yy / 4.5) ** 2 <= 1:
                cv.set(dx + 10 + xx, dy + yy, S2 if xx < 0 else S1)
    cv.set(dx + 10, dy, S0)
    cv.rect(dx - 9, dy + 5, 22, 1, O0)
    for (rx2, ry2) in [(98, 70), (102, 72), (60, 68), (125, 66)]:
        cv.rect(rx2, ry2, 2, 2, S1)
        cv.set(rx2 + 1, ry2 + 1, S0)
    # Amphorae by the temple steps.
    for ax, ay in [(124, 58), (131, 61)]:
        shape = [1, 2, 3, 3, 3, 2, 2, 1]
        for i, hw in enumerate(shape):
            for xx in range(-hw, hw + 1):
                c = C2 if xx < 0 else (C1 if xx < hw else C0)
                if i == 3:
                    c = F0 if xx > -hw else C1
                cv.set(ax + xx, ay - 8 + i, c)
        cv.set(ax - 2, ay - 7, C0)
        cv.set(ax + 2, ay - 7, C0)
        cv.rect(ax - 1, ay - 9, 3, 1, C1)
        cv.rect(ax - 2, ay, 5, 1, O0)
    # The brazier glow on the grass (warm dither around it), then the bronze tripod.
    bx, by = BRAZIER
    for y in range(by - 20, by + 14):
        for x in range(bx - 30, bx + 30):
            d = math.hypot((x - bx) / 2.0, (y - by - 4))
            c = cv.get(x, y)
            if c in (O0, O1, O2) and d < 11:
                t = (1 - d / 11) * 0.8
                if dith(x, y, t):
                    cv.set(x, y, O2 if t > 0.5 else (O1 if c == O0 else O2))
    for i in range(4):  # bowl
        for xx in range(-5 + i, 6 - i):
            c = BRONZE if xx < 2 else C0
            if i == 0:
                c = F2 if abs(xx) < 4 else BRONZE
            cv.set(bx + xx, by - 8 + i, c)
    for leg in (-4, 0, 4):
        for i in range(8):
            cv.set(bx + leg + (leg // 4) * (i // 4), by - 4 + i, BRONZE if leg < 0 else C0)
    cv.rect(bx - 2, by - 9, 5, 1, F1)
    # Two olive trees: gnarled trunks, round silver-green crowns lit from the upper left.
    for tx, ty, r in [(150, 52, 11), (28, 72, 8)]:
        for i in range(r + 2):
            cv.set(tx + (1 if i > r // 2 else 0), ty - i, LEATHER)
            cv.set(tx + 1 + (1 if i > r // 2 else 0), ty - i, N1)
        cy2 = ty - r - 4
        for yy in range(-r, r // 2 + 2):
            for xx in range(-r - 2, r + 3):
                d = (xx / (r + 2)) ** 2 + (yy / r) ** 2
                if d <= 1 and not (d > 0.8 and dith(tx + xx, cy2 + yy, 0.5)):
                    l = -0.6 * xx / r - 0.8 * yy / r
                    c = P["Silver"] if l > 0.88 else (O2 if l > 0.35 else (O1 if l > -0.3 else N2))
                    if c == O2 and dith(tx + xx + (yy // 3) * 2, cy2 + yy, 0.3):
                        c = O1
                    if c == N2 and dith(tx + xx, cy2 + yy + xx // 3, 0.3):
                        c = O0
                    if d > 0.7 and l < 0.2:
                        c = N1
                    if c == O1 and dith(tx + xx, cy2 + yy, 0.25):
                        c = O0
                    cv.set(tx + xx, cy2 + yy, c)
        cv.rect(tx - r, ty + 1, r * 2 + 2, 1, O0)  # shadow on the grass
    # A spring and a little stream to the waterfall's lip.
    fx0 = FALLS_X
    sx, sy = 140, 80
    for i in range(60):
        t = i / 59
        x = int(round(sx + (fx0 + 2 - sx) * t + 2 * math.sin(t * 5)))
        y = int(round(sy + (front[fx0] - sy) * t))
        cv.set(x, y, A1)
        cv.set(x + 1, y, POOL if i % 4 else M1)
        cv.set(x + 2, y, A0)
    cv.rect(sx - 3, sy - 2, 7, 3, A1)
    cv.rect(sx - 2, sy - 2, 4, 1, POOL)
    cv.set(sx - 1, sy - 1, M1)
    # The waterfall itself, down the front of the cliff to the bottom of the image.
    for y in range(front[fx0] - 1, H):
        spread = (y - front[fx0]) // 30
        for xx in range(-spread, FALLS_W + spread):
            x = fx0 + xx
            band = (xx + spread) % 4
            c = A1 if band in (1, 2) else A0
            if band == 1 and (y // 2) % 3 == 0:
                c = POOL
            if xx < 0 or xx >= FALLS_W:
                if not dith(x, y, 0.5):
                    continue
                c = A0
            cv.set(x, y, c)
        cv.set(fx0 - spread - 1, y, N1 if cv.get(fx0 - spread - 1, y) else None)
    for xx in range(-1, FALLS_W + 1):  # white lip where it pours over
        cv.set(fx0 + xx, front[fx0], M1)
        cv.set(fx0 + xx, front[fx0] + 1, M0)
    cv.save("title_island_main.png")


# Spots shared with scripts/ui/title_screen.gd (island pixels).
BRAZIER = (178, 74)
FALLS_X, FALLS_W = 150, 6


def back_island(name, seed, brazier):
    rng = random.Random(seed)
    W, H = 84, 64
    cv = Canvas(W, H)
    cx, cy, rx, ry = 42, 22, 38, 12
    top, front = island(cv, rng, cx, cy, rx, ry, 9, 30, warm=False)
    # Column silhouettes.
    for x, h in ([(26, 15), (33, 15), (44, 8)] if brazier else [(30, 17), (50, 11)]):
        column(cv, x, cy - 2, h, w=3, capital=h > 12)
    if brazier:
        cv.rect(25, cy - 19, 12, 2, S1)
        bx, by = 56, cy + 1
        cv.rect(bx - 2, by - 3, 5, 1, BRONZE)
        cv.rect(bx - 1, by - 2, 3, 1, C0)
        cv.set(bx - 1, by - 1, C0)
        cv.set(bx + 1, by - 1, C0)
    # Tint everything toward the night haze for distance.
    for y in range(H):
        for x in range(W):
            c = cv.get(x, y)
            if c is not None:
                cv.set(x, y, haze(c, 0.3))
    cv.save(name)


def cloud_band(name, seed, h, rows, cols):
    """A horizontally tileable cloud band, 480 wide: rows of puffs (back to front), each lit from
    the upper left by the moon, over a body that darkens downward and is opaque at the bottom.
    rows: [(centre y, min r, max r)]; cols: (rim, lit, body, shadow, deep)."""
    rng = random.Random(seed)
    W = 480
    cv = Canvas(W, h)
    rim, lit, body, shadow, deep = cols
    for ry, r0, r1 in rows:
        x = rng.randint(0, r1)
        while x < W + r1:
            r = rng.randint(r0, r1)
            by = ry + rng.randint(-5, 4)
            for yy in range(by - r, h):
                for xx in range(x - r - 1, x + r + 2):
                    dx = (xx - x) / r
                    dy = (yy - by) / (r * 0.72)
                    if yy > by:
                        dy = 0.0 if abs(dx) <= 1 else 2.0  # puffs run down into the body
                    if dx * dx + dy * dy > 1:
                        continue
                    l = -0.5 * dx - 0.86 * dy
                    if yy > by:
                        k = (yy - by) / max(1, h - by)
                        c = shadow if k < 0.35 or (k < 0.6 and dith(xx, yy, 0.5)) else deep
                    elif l > 0.84:
                        c = rim
                    elif l > 0.45:
                        c = lit
                    elif l > -0.1:
                        c = body
                    else:
                        c = shadow if not (l > -0.2 and dith(xx, yy, 0.5)) else body
                    cv.set(xx % W, yy, c)
            x += rng.randint(int(r * 1.3), int(r * 2.1))
    cv.save(name)


def moon():
    cv = Canvas(22, 22)
    c = 10.5
    for y in range(22):
        for x in range(22):
            d = math.hypot(x - c, y - c)
            if d <= 9.5:
                lit = (x - c) * -0.5 + (y - c) * -0.5
                col = M1 if lit > -2 else (M0 if lit > -5.5 or dith(x, y, 0.5) else M0)
                if lit < -5.5:
                    col = M0
                cv.set(x, y, col)
    for (x, y, r) in [(7, 8, 2), (13, 13, 2), (12, 6, 1), (6, 14, 1)]:
        for yy in range(-r, r + 1):
            for xx in range(-r, r + 1):
                if xx * xx + yy * yy <= r * r:
                    cv.set(x + xx, y + yy, M0)
        cv.set(x - r // 2, y - r // 2, P["Silver"])
    cv.save("title_moon.png")


if __name__ == "__main__":
    main_island()
    back_island("title_island_back_0.png", 721, False)
    back_island("title_island_back_1.png", 733, True)
    cloud_band("title_cloud_0.png", 801, 70, [(18, 7, 11), (26, 6, 9)], (N2, N2, N2, N1, N1))
    cloud_band("title_cloud_1.png", 802, 52, [(22, 11, 17), (32, 8, 12)], (M1, M0, N2, N1, N1))
    cloud_band("title_cloud_2.png", 803, 44, [(24, 14, 22), (34, 9, 14)], (M0, N2, N1, N0, N0))
    moon()
    print("wrote title art to", OUT)
