#!/usr/bin/env python3
"""Turn the AI-generated character sheets in art/generated/ into in-game sprites in art/final/.

The sheets (made with ChatGPT image generation, see docs/dev/POLISH.md) are large "pixel art"
renders on a flat magenta background, usually a front three-quarter view (our SE facing) and a back
three-quarter view (NE). For each output sprite this script:

1. keys out the magenta background (and the pink fringe around the silhouette),
2. crops the requested view and scales the whole character (both views share one scale),
3. downsizes by coverage: each target pixel is opaque if at least half of its source block is the
   character, and takes a palette colour chosen from the block (see `pick_colour`),
4. snaps every pixel to art/palette/orion.gpl (in CIE Lab, so ramps stay ramps),
5. cleans up: drops orphan pixels, closes one-pixel holes, re-draws a dark outline,
6. pastes it on the placeholder's canvas size with the feet on the bottom-centre pixel.

Usage:
    python tools/process_generated.py               # writes art/final/<name>.png
    python tools/process_generated.py --preview out.png   # also writes a 4x contact sheet

Needs Pillow and numpy. Re-run it after changing a job below or replacing a sheet.
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass, field

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEN = os.path.join(ROOT, "art", "generated")
FINAL = os.path.join(ROOT, "art", "final")
PALETTE_FILE = os.path.join(ROOT, "art", "palette", "orion.gpl")


@dataclass
class Job:
    sheet: str              # file in art/generated/
    view: int               # 0 = leftmost figure on the sheet, 1 = the next one
    canvas: tuple           # output size, the placeholder's size
    height: float           # height in output pixels of the reference view (view 0) content
    mirror: bool = False    # flip horizontally after cropping
    nudge: tuple = (0, 0)   # extra (x, y) offset on the canvas
    outline: bool = True
    exclude: list = field(default_factory=list)  # colour names never used for this sprite
    feet_rows: float = 0.05  # bottom fraction of the figure used to find the feet centre
    feet_x: float | None = None  # feet centre as a fraction of the figure's width (else found)
    dark_share: float = 0.3  # how much of a block a darker group needs to win it
    touch: list = field(default_factory=list)  # (x, y, colour name) fixes in canvas pixels


# Heights follow the placeholders and the GDD's size story: Cedalion is small, a Hoplite is big.
JOBS = {
    # His cape sweeps to the floor, so the feet are placed by hand.
    "cedalion_se": Job("Pixel Adventurer Torch Sprite Sheet.png", 0, (32, 32), 27, feet_x=0.56),
    "cedalion_ne": Job("Pixel Adventurer Torch Sprite Sheet.png", 1, (32, 32), 27, feet_x=0.74),
    "watchman_se": Job("Pixel Mercenary Sprite Views.png", 0, (40, 40), 37),
    "watchman_ne": Job("Pixel Mercenary Sprite Views.png", 1, (40, 40), 37),
    "spearman_se": Job("Crimson Spearmen Pixel Turnaround.png", 0, (56, 44), 44),
    "spearman_ne": Job("Crimson Spearmen Pixel Turnaround.png", 1, (56, 44), 44),
    # The Hoplite is armoured head to toe: without the skin ramp his bronze stays bronze.
    "hoplite_se": Job("Pixel-Art Hoplite_ Front and Back Views.png", 0, (48, 48), 47,
                      exclude=["Skin 1", "Skin 2"]),
    "hoplite_ne": Job("Pixel-Art Hoplite_ Front and Back Views.png", 1, (48, 48), 47,
                      exclude=["Skin 1", "Skin 2"]),
    "phineus_se": Job("Pixel Sage with Oil Lamp and Amphora.png", 0, (32, 32), 28, feet_rows=0.12),
    "shade_se": Job("Pixel Assassin Sprite Duo.png", 0, (32, 40), 36),
    "shade_ne": Job("Pixel Assassin Sprite Duo.png", 1, (32, 40), 36),
}

# Outline colour: the palette's darkest indigo ("never pure black in the world").
OUTLINE = "Night 0"
# Palette entries that are never used on characters.
NEVER = {"Black-figure", "Swap key 1", "Swap key 2", "Swap key 3", "Swap key 4"}


# --------------------------------------------------------------------------------------------
# Palette and colour maths

def load_palette():
    names, cols = [], []
    with open(PALETTE_FILE, encoding="utf-8") as f:
        for line in f:
            parts = line.split()
            if len(parts) < 4 or not parts[0].isdigit():
                continue
            r, g, b = int(parts[0]), int(parts[1]), int(parts[2])
            name = " ".join(parts[3:]).split(" (")[0].split(" #")[0].strip()
            if any(name.startswith(n) for n in NEVER):
                continue
            names.append(name)
            cols.append((r, g, b))
    return names, np.array(cols, dtype=np.float64)


def srgb_to_lab(rgb):
    """rgb: (..., 3) in 0..255 -> CIE Lab (D65)."""
    c = np.asarray(rgb, dtype=np.float64) / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    L = 116.0 * f[..., 1] - 16.0
    a = 500.0 * (f[..., 0] - f[..., 1])
    b = 200.0 * (f[..., 1] - f[..., 2])
    return np.stack([L, a, b], axis=-1)


def nearest_index(lab, pal_lab, allowed):
    d = ((lab[..., None, :] - pal_lab[None, ...]) ** 2).sum(-1)
    d[..., ~allowed] = 1e12
    return d.argmin(-1)


# --------------------------------------------------------------------------------------------
# Sheet handling

def foreground_mask(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    magenta = np.minimum(r, b) - g
    bg = magenta > 70
    # The anti-aliased fringe is a blend of the outline and magenta: pinkish, touching background.
    fringe = (magenta > 25) & (r > 90) & (b > 90)
    near_bg = bg.copy()
    for dy in (-2, -1, 0, 1, 2):
        for dx in (-2, -1, 0, 1, 2):
            near_bg |= np.roll(np.roll(bg, dy, 0), dx, 1)
    bg |= fringe & near_bg
    fg = ~bg
    # Open with a 3x3 to drop isolated specks of noise.
    img = Image.fromarray((fg * 255).astype(np.uint8))
    from PIL import ImageFilter
    img = img.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    return np.asarray(img) > 127


def view_ranges(fg, min_gap=30):
    cols = fg.sum(0)
    runs, start = [], None
    for x, c in enumerate(cols):
        if c > 2 and start is None:
            start = x
        elif c <= 2 and start is not None:
            runs.append([start, x])
            start = None
    if start is not None:
        runs.append([start, len(cols)])
    merged = []
    for s, e in runs:
        if merged and s - merged[-1][1] < min_gap:
            merged[-1][1] = e
        elif e - s > 40:
            merged.append([s, e])
    return merged


_sheet_cache = {}


def load_view(sheet, view):
    if sheet not in _sheet_cache:
        rgb = np.asarray(Image.open(os.path.join(GEN, sheet)).convert("RGB")).astype(np.float64)
        fg = foreground_mask(rgb)
        _sheet_cache[sheet] = (rgb, fg, view_ranges(fg))
    rgb, fg, ranges = _sheet_cache[sheet]
    x0, x1 = ranges[view]
    sub = fg[:, x0:x1]
    rows = np.where(sub.any(1))[0]
    cols = np.where(sub.any(0))[0]
    y0, y1 = rows.min(), rows.max() + 1
    cx0, cx1 = x0 + cols.min(), x0 + cols.max() + 1
    return rgb[y0:y1, cx0:cx1], fg[y0:y1, cx0:cx1]


# --------------------------------------------------------------------------------------------
# Downsizing

def pick_colour(block_lab, pal_lab, allowed, dark_share):
    """Choose one palette index for a block of source pixels (Lab values).

    Snapping every source pixel and voting gives speckle wherever a surface sits between two
    palette entries, and a plain average deletes thin dark lines (outlines, eyes, belts). So: the
    block's mean colour, snapped once, unless a clearly darker group covers a fair share of the
    block, in which case that group's mean wins; it is what carries the shapes at this size.
    """
    mean = block_lab.mean(0)
    L = block_lab[:, 0]
    dark = L < min(mean[0] - 18.0, np.percentile(L, 30) + 6.0)
    if dark.mean() >= dark_share and mean[0] - L[dark].mean() > 14.0:
        mean = block_lab[dark].mean(0)
    return int(nearest_index(mean[None, :], pal_lab, allowed)[0])


def downsize(rgb, fg, scale, pal_lab, allowed, dark_share):
    h, w = fg.shape
    th = max(1, int(round(h * scale)))
    tw = max(1, int(round(w * scale)))
    lab = srgb_to_lab(rgb)
    out = np.full((th, tw), -1, dtype=np.int64)
    sy, sx = h / th, w / tw
    for ty in range(th):
        y0, y1 = int(round(ty * sy)), max(int(round(ty * sy)) + 1, int(round((ty + 1) * sy)))
        for tx in range(tw):
            x0, x1 = int(round(tx * sx)), max(int(round(tx * sx)) + 1, int(round((tx + 1) * sx)))
            m = fg[y0:y1, x0:x1]
            if m.mean() < 0.5:
                continue
            out[ty, tx] = pick_colour(lab[y0:y1, x0:x1][m], pal_lab, allowed, dark_share)
    return out


def neighbours4(a, fill=-1):
    up = np.vstack([np.full((1, a.shape[1]), fill), a[:-1]])
    down = np.vstack([a[1:], np.full((1, a.shape[1]), fill)])
    left = np.hstack([np.full((a.shape[0], 1), fill), a[:, :-1]])
    right = np.hstack([a[:, 1:], np.full((a.shape[0], 1), fill)])
    return up, down, left, right


def cleanup(out, pal_lab, outline_idx, do_outline):
    out = out.copy()
    # Close one-pixel holes: a transparent pixel with 3+ opaque 4-neighbours.
    n = neighbours4(out)
    opaque_n = sum((x >= 0).astype(int) for x in n)
    holes = (out < 0) & (opaque_n >= 4)
    for y, x in zip(*np.where(holes)):
        vals = [v[y, x] for v in n if v[y, x] >= 0]
        out[y, x] = max(set(vals), key=vals.count)
    # Orphans: an opaque pixel whose 4 neighbours all share one other opaque colour.
    n = neighbours4(out)
    for y, x in zip(*np.where(out >= 0)):
        vals = [v[y, x] for v in n]
        if vals[0] >= 0 and all(v == vals[0] for v in vals) and out[y, x] != vals[0]:
            if abs(pal_lab[out[y, x], 0] - pal_lab[vals[0], 0]) < 30:
                out[y, x] = vals[0]
    # Strays: an opaque pixel with no opaque 4-neighbour.
    n = neighbours4(out)
    lonely = (out >= 0) & (sum((x >= 0).astype(int) for x in n) == 0)
    out[lonely] = -1
    if do_outline:
        n = neighbours4(out)
        edge = (out >= 0) & (sum((x < 0).astype(int) for x in n) > 0)
        # Only darken edge pixels that are already darkish: glowing flames and lit metal keep
        # their colour so they still read as light sources.
        for y, x in zip(*np.where(edge)):
            if pal_lab[out[y, x], 0] < 42:
                out[y, x] = outline_idx
    return out


def feet_centre(fg, frac):
    h = fg.shape[0]
    rows = fg[int(h * (1.0 - frac)):]
    ys, xs = np.where(rows)
    return xs.mean() if len(xs) else fg.shape[1] / 2


def render(job, names, pal, pal_lab, scale_for):
    allowed = np.array([n not in job.exclude for n in names])
    rgb, fg = load_view(job.sheet, job.view)
    scale = scale_for[job.sheet]
    idx = downsize(rgb, fg, scale, pal_lab, allowed, job.dark_share)
    idx = cleanup(idx, pal_lab, names.index(OUTLINE), job.outline)
    if job.mirror:
        idx = idx[:, ::-1]
    th, tw = idx.shape
    W, H = job.canvas
    fc = job.feet_x * tw if job.feet_x is not None else feet_centre(idx >= 0, job.feet_rows)
    ox = int(np.floor(W / 2)) - int(round(fc)) + job.nudge[0]
    oy = H - th + job.nudge[1]
    ox = min(max(ox, 0), max(0, W - tw)) if tw <= W else ox
    if tw > W or th > H:
        print(f"  warning: {tw}x{th} content does not fit the {W}x{H} canvas; clipping")
    img = np.zeros((H, W, 4), dtype=np.uint8)
    for y in range(th):
        for x in range(tw):
            v = idx[y, x]
            cx, cy = x + ox, y + oy
            if v >= 0 and 0 <= cx < W and 0 <= cy < H:
                img[cy, cx, :3] = pal[v]
                img[cy, cx, 3] = 255
    for x, y, cname in job.touch:
        if cname is None:
            img[y, x] = 0
        else:
            img[y, x, :3] = pal[names.index(cname)]
            img[y, x, 3] = 255
    return Image.fromarray(img, "RGBA")


def flame_offset(img, pal, names):
    """Where the hottest pixels (torch or lantern) sit relative to the feet, for the light offsets
    in player.gd and guard.gd."""
    a = np.asarray(img)
    hot = [pal[names.index(n)] for n in ("Fire 3", "Fire 2")]
    m = np.zeros(a.shape[:2], bool)
    for c in hot:
        m |= (a[..., 3] > 0) & (np.abs(a[..., :3].astype(int) - c).sum(-1) == 0)
    if not m.any():
        return None
    ys, xs = np.where(m)
    return (round(xs.mean() - img.size[0] // 2, 1), round(ys.mean() - img.size[1], 1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview", help="also write a 4x contact sheet to this PNG")
    ap.add_argument("--only", help="comma-separated output names")
    ap.add_argument("--out", default=FINAL, help="output folder (default art/final)")
    args = ap.parse_args()
    names, pal = load_palette()
    pal_lab = srgb_to_lab(pal)
    # One scale per sheet, set by view 0's height, so both facings match.
    scale_for = {}
    for name, job in JOBS.items():
        if job.sheet not in scale_for:
            _, fg0 = load_view(job.sheet, 0)
            ref = next(j for j in JOBS.values() if j.sheet == job.sheet)
            scale_for[job.sheet] = ref.height / fg0.shape[0]
    os.makedirs(args.out, exist_ok=True)
    only = set(args.only.split(",")) if args.only else None
    done = []
    for name, job in JOBS.items():
        if only and name not in only:
            continue
        img = render(job, names, pal, pal_lab, scale_for)
        img.save(os.path.join(args.out, name + ".png"))
        bb = img.getchannel("A").getbbox()
        print(f"{name}: {img.size[0]}x{img.size[1]}, content {bb}, flame {flame_offset(img, pal, names)}")
        done.append((name, img))
    if args.preview and done:
        # Two rows: on the night floor and on lit marble, to check the outline both ways.
        pad, k = 4, 5
        W = sum(i.size[0] for _, i in done) + pad * (len(done) + 1)
        rh = max(i.size[1] for _, i in done) + pad * 2
        sheet = Image.new("RGBA", (W, rh * 2), (27, 24, 52, 255))
        sheet.paste((125, 119, 109, 255), (0, rh, W, rh * 2))
        x = pad
        for _, i in done:
            for row in (0, 1):
                sheet.alpha_composite(i, (x, rh * (row + 1) - pad - i.size[1]))
            x += i.size[0] + pad
        sheet = sheet.resize((W * k, rh * 2 * k), Image.NEAREST)
        sheet.save(args.preview)
        print("preview:", args.preview)


if __name__ == "__main__":
    sys.exit(main())
