"""Cedalion with no armour, holding each weapon: a sheet laid out like one row of Sathvik's armour
sheet (art/generated/cedalion_armour_sheet.webp), "No Armour + Mace / Axe / Sword".

In the game this set needs no art of its own: the tunic body (art/final/cedalion_sheet.*) is
weapon-free and the weapon is its own sprite (art/final/sword_<id>.png, tools/gen_swords.py),
drawn at each frame's "hand" point. This tool composes the same two layers the way
Player._update_sword does, so the sheet shows what the game draws:

  - walk: the front walk (walk_se) and the back walk (walk_ne), the weapon resting at the frame's
    hand angle, behind the body;
  - attack: the forehand cut sampled through the swing (the body frame the game picks at that
    point, the weapon posed by Player._swing_pose), in front of the body.

Writes art/generated/cedalion_tunic_weapons_sheet.png, 4x with nearest filtering, on a plain dark
background with labels.

    python tools/compose_weapon_sheet.py
"""
from pathlib import Path
import json
import math

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FINAL = ROOT / "art" / "final"
OUT = ROOT / "art" / "generated" / "cedalion_tunic_weapons_sheet.png"
ZOOM = 4
WEAPONS = [("koryne", "Mace"), ("labrys", "Axe"), ("xiphos", "Sword")]
# Player's swing phases (fractions of the swing time) and where the attack samples fall.
SWING_STRIKE, SWING_FOLLOW, SWING_RECOVER = 0.26, 0.44, 0.7
SAMPLES = [0.12, 0.3, 0.38, 0.55, 0.85]
BG = (13, 11, 26)      # Night 0
PANEL = (27, 24, 52)   # Night 1
RULE = (46, 58, 92)    # Night 2
GOLD = (217, 164, 58)
TEXT = (207, 227, 255)  # Moon 1


def ease(x, curve):
    """Godot's ease() for a positive curve below 1 (ease out)."""
    x = max(0.0, min(1.0, x))
    return 1.0 - (1.0 - x) ** (1.0 / curve)


def smoothstep(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def swing_pose(k, face, rest):
    """Player._swing_pose for the first swing of the combo (the forehand cut)."""
    wind, end, settle, reach = face - 95.0, face + 55.0, 12.0, 3.0
    if k < SWING_STRIKE:
        t = ease(k / SWING_STRIKE, 0.5)
        return 2.0 * t, -4.0 * t, rest + (wind - rest) * t
    if k < SWING_FOLLOW:
        t = 1.0 - (1.0 - (k - SWING_STRIKE) / (SWING_FOLLOW - SWING_STRIKE)) ** 2
        return 2.0 + (reach - 2.0) * t, -4.0 + 5.0 * t, wind + (end - wind) * t
    if k < SWING_RECOVER:
        t = (k - SWING_FOLLOW) / (SWING_RECOVER - SWING_FOLLOW)
        return reach * (1.0 - 0.3 * t), 1.0, end + settle * t
    t = smoothstep((k - SWING_RECOVER) / (1.0 - SWING_RECOVER))
    return reach * 0.7 * (1.0 - t), 1.0 - t, end + settle + (rest - end - settle) * t


def load_sheet():
    meta = json.loads((FINAL / "cedalion_sheet.json").read_text())
    img = Image.open(FINAL / "cedalion_sheet.png").convert("RGBA")
    frames = meta["frames"]
    tags = {t["name"]: [frames[i] for i in range(t["from"], t["to"] + 1)] for t in meta["meta"]["frameTags"]}
    pv = meta["meta"]["pivot"]
    return img, tags, (pv["x"], pv["y"])


def compose(img, frame, pivot, sword, hand, angle, front, pad):
    """One figure: the body cell plus the weapon cell whose grip pixel (16, 16) sits on the hand,
    as the game places it (the body's pivot pixel is drawn one pixel above the node's origin)."""
    r = frame["frame"]
    body = img.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"]))
    cell = Image.new("RGBA", (r["w"] + pad * 2, r["h"] + pad * 2), (0, 0, 0, 0))
    i = round(angle / 11.25) % 32
    blade = sword.crop((i * 32, 0, i * 32 + 32, 32))
    at = (round(pad + pivot[0] + hand[0]) - 16, round(pad + pivot[1] + hand[1] + 1) - 16)
    if not front:
        cell.alpha_composite(blade, at)
    cell.alpha_composite(body, (pad, pad))
    if front:
        cell.alpha_composite(blade, at)
    return cell


def figures(img, tags, pivot, sword, pad):
    walk, attack = [], []
    for d, face in (("se", math.degrees(math.atan2(0.5, 1.0))), ("ne", math.degrees(math.atan2(-0.5, 1.0)))):
        for f in tags["walk_" + d]:
            h = f["hand"]
            walk.append(compose(img, f, pivot, sword, (h["x"], h["y"]), h["angle"], False, pad))
        clip = tags["attack_" + d]
        fx, fy = math.cos(math.radians(face)), math.sin(math.radians(face))
        for k in (SAMPLES if d == "se" else SAMPLES[1:4]):
            # the body frame Player._animate shows at this point of the swing
            n = len(clip)
            i = (0 if k < SWING_STRIKE else (1 if k < 0.56 else 2)) if n == 3 else min(n - 1, int(k * n))
            f = clip[i]
            h = f["hand"]
            px, py, ang = swing_pose(k, face, h["angle"])
            hand = (h["x"] + fx * px, h["y"] + fy * px + py)
            attack.append(compose(img, f, pivot, sword, hand, ang, k < SWING_RECOVER + 0.1, pad))
    return walk, attack


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def main():
    img, tags, pivot = load_sheet()
    pad = 12
    rows = []
    for wid, label in WEAPONS:
        sword = Image.open(FINAL / f"sword_{wid}.png").convert("RGBA")
        rows.append((wid, label) + figures(img, tags, pivot, sword, pad))
    fw, fh = rows[0][2][0].width * ZOOM, rows[0][2][0].height * ZOOM
    per_row = max(len(rows[0][2]), len(rows[0][3]))
    gap, head, sub = 8, 44, 26
    block_w = per_row * (fw + gap) + gap + 150
    block_h = head + 2 * (sub + fh + gap)
    sheet = Image.new("RGB", (block_w + 2 * gap, len(rows) * (block_h + gap) + gap + 40), BG)
    d = ImageDraw.Draw(sheet)
    d.text((gap + 4, 8), "Cedalion - No Armour (Prince's tunic) + each weapon, as the game draws them", fill=GOLD, font=font(22))
    y = 40
    for wid, label, walk, attack in rows:
        d.rectangle([gap, y, gap + block_w, y + block_h], fill=PANEL, outline=RULE)
        d.text((gap + 12, y + 8), f"No Armour + {label}  ({wid})", fill=GOLD, font=font(24))
        yy = y + head
        for title, figs in (("Walk Cycle (front, then back)", walk), ("Attack (forehand cut, front then back)", attack)):
            d.text((gap + 12, yy + 2), title, fill=TEXT, font=font(16))
            yy += sub
            x = gap + 150
            for f in figs:
                sheet.paste(f.resize((fw, fh), Image.NEAREST), (x, yy), f.resize((fw, fh), Image.NEAREST))
                x += fw + gap
            yy += fh + gap
        y += block_h + gap
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"{OUT.relative_to(ROOT)}: {sheet.width}x{sheet.height}")


if __name__ == "__main__":
    main()
