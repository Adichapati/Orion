"""Procedural animation sheets from single stills, until hand-made sheets exist.

For each character with only a front (SE) and a back (NE) still, this cuts the figure at the
hips and builds frames by moving the parts a pixel or two: a walk cycle (each leg lifts and steps
in turn, the body bobs, the arms swing), an attack (lean back in the wind-up, lunge forward on the
strike with the front foot out, settle), and a hurt flinch. It writes art/final/<name>_sheet.png +
<name>_sheet.json in the same Aseprite format as Cedalion's sheet, so the game's SheetAnim reads
them, and a real sheet exported under the same name simply replaces them (re-running this tool
skips any character whose sheet wasn't made by it).

The game adds what pixels can't: the lunge's travel, the glint, hit flashes, the stagger shake
and the KO topple.

    python tools/animate_stills.py [preview dir]
"""
from pathlib import Path
import json
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
FINAL = ROOT / "art" / "final"
APP = "tools/animate_stills.py"

# name: options. legs = fraction of the figure's height below the hips; arms = swing the arms
# (off for figures whose long weapon runs past their hands); seated = no legs to move.
CHARACTERS = {
    "watchman": dict(legs=0.36, arms=True),
    "spearman": dict(legs=0.34, arms=False),
    "hoplite": dict(legs=0.34, arms=False),
    "phineus": dict(legs=0.0, arms=False, seated=True),
}
WALK_MS = 150
COLS = 8


def load(name):
    for d in (FINAL, ROOT / "art" / "placeholders"):
        p = d / f"{name}.png"
        if p.exists():
            return Image.open(p).convert("RGBA")
    return None


class Figure:
    """A still with its hip line, leg columns and arm columns found from its pixels."""

    def __init__(self, img, legs_frac, arms):
        self.img = img
        self.w, self.h = img.size
        bb = img.getbbox()
        self.top, self.bottom = bb[1], bb[3] - 1
        px = img.load()
        self.px = px
        height = self.bottom - self.top + 1
        self.hip = self.bottom - round(height * legs_frac) if legs_frac > 0 else self.bottom + 1
        # The feet: runs of solid columns in the bottom three rows; the widest two are feet (a
        # spear butt is a thin run).
        cols = [x for x in range(self.w) if any(px[x, y][3] for y in range(self.bottom - 2, self.bottom + 1))]
        runs = []
        for x in cols:
            if runs and x == runs[-1][1] + 1:
                runs[-1][1] = x
            else:
                runs.append([x, x])
        runs.sort(key=lambda r: r[1] - r[0], reverse=True)
        feet = sorted(runs[:2]) if len(runs) >= 2 and runs[1][1] - runs[1][0] >= 1 else sorted(runs[:1])
        if len(feet) == 2:
            self.leg_l = (feet[0][0] - 1, (feet[0][1] + feet[1][0]) // 2)
            self.leg_r = (self.leg_l[1] + 1, feet[1][1] + 1)
        elif feet:
            mid = (feet[0][0] + feet[0][1]) // 2
            self.leg_l = (feet[0][0] - 2, mid)
            self.leg_r = (mid + 1, feet[0][1] + 2)
        else:
            c = self.w // 2
            self.leg_l, self.leg_r = (c - 4, c), (c + 1, c + 5)
        # The arms: the outermost three solid columns of each torso row, between shoulders and hips.
        self.arms = arms
        self.shoulder = self.top + round(height * 0.3)

    def blank(self):
        return Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))

    def frame(self, lean=0, bob=0, left=(0, 0), right=(0, 0), arm=0):
        """Builds one frame. lean: pixels the head moves sideways (+ = forward, toward screen
        right), sheared down to nothing at the hips. bob: pixels the body above the hips rises
        (+) or sinks. left / right: (dx, lift) for each leg. arm: +1 swings the left arm down and
        the right arm up, -1 the reverse."""
        out = self.blank()
        o = out.load()
        px = self.px
        span = max(1, self.hip - self.top)
        # legs first, then the body over them
        for (x0, x1), (dx, lift) in ((self.leg_l, left), (self.leg_r, right)):
            for y in range(self.hip, self.bottom + 1):
                for x in range(max(0, x0), min(self.w, x1 + 1)):
                    c = px[x, y]
                    if c[3]:
                        nx, ny = x + dx, y - lift
                        if 0 <= nx < self.w and 0 <= ny < self.h:
                            o[nx, ny] = c
            # a lifted leg leaves its hip pixels in place, so the thigh stays joined
            if lift:
                for y in range(self.hip, self.hip + lift):
                    for x in range(max(0, x0), min(self.w, x1 + 1)):
                        if px[x, y][3] and not o[x, y][3]:
                            o[x, y] = px[x, y]
        # everything outside the leg columns below the hips (cloaks, spear butts) stays put
        for y in range(self.hip, self.bottom + 1):
            for x in range(self.w):
                in_leg = self.leg_l[0] <= x <= self.leg_l[1] or self.leg_r[0] <= x <= self.leg_r[1]
                if not in_leg and px[x, y][3]:
                    o[x, y] = px[x, y]
        # the body above the hips: bob, lean (shear) and arm swing
        rows = {}
        for y in range(self.top, self.hip):
            solid = [x for x in range(self.w) if px[x, y][3]]
            rows[y] = solid
        for y in range(self.top, self.hip):
            shift = round(lean * (self.hip - y) / span)
            solid = rows[y]
            for x in solid:
                dy = -bob
                if self.arms and arm and self.shoulder <= y and solid:
                    if x <= solid[0] + 2:
                        dy += arm
                    elif x >= solid[-1] - 2:
                        dy -= arm
                nx, ny = x + shift, y + dy
                if 0 <= nx < self.w and 0 <= ny < self.h:
                    o[nx, ny] = px[x, y]
        # if the body rose, close the gap above the hips with the hip row
        if bob > 0:
            for k in range(bob):
                y = self.hip - 1 - k
                for x in range(self.w):
                    if not o[x, y][3] and px[x, self.hip - 1][3]:
                        o[x, y] = px[x, self.hip - 1]
        return out


def clips_for(fig, seated):
    """name -> (frames, ms per frame) for one facing."""
    if seated:
        return {
            "idle": ([fig.img, fig.frame(bob=-1)], 700),
            "talk": ([fig.frame(lean=1), fig.frame(lean=1, bob=-1), fig.frame(lean=2), fig.frame(lean=1, bob=-1)], 160),
        }
    return {
        "idle": ([fig.img], 400),
        # lift and step: each leg rises and comes forward while the body rides up, then plants
        "walk": ([
            fig.frame(bob=1, left=(1, 2), arm=1),
            fig.frame(left=(1, 0), right=(-1, 0)),
            fig.frame(bob=1, right=(1, 2), arm=-1),
            fig.frame(left=(-1, 0), right=(1, 0)),
        ], WALK_MS),
        # wind-up (rear back), strike (lunge low with the front foot out), settle
        "attack": ([
            fig.frame(lean=-2, bob=1, left=(-1, 0)),
            fig.frame(lean=3, bob=-1, right=(2, 0), left=(-1, 0)),
            fig.frame(lean=1, right=(1, 0)),
        ], 120),
        "hurt": ([fig.frame(lean=-2, bob=-1)], 200),
    }


def build(name, opts, preview):
    se, ne = load(f"{name}_se"), load(f"{name}_ne")
    if se is None:
        print(f"{name}: no still, skipped")
        return
    sheet_json = FINAL / f"{name}_sheet.json"
    if sheet_json.exists():
        app = json.loads(sheet_json.read_text()).get("meta", {}).get("app", "")
        if app != APP:
            print(f"{name}: has a hand-made sheet ({app or 'unknown app'}), left alone")
            return
    seated = opts.get("seated", False)
    order, tags = [], []
    for facing, img in (("se", se), ("ne", ne)):
        if img is None:
            continue
        fig = Figure(img, opts["legs"], opts["arms"])
        for clip, (frames, ms) in clips_for(fig, seated).items():
            start = len(order)
            order.extend((f, ms) for f in frames)
            tags.append({"name": f"{clip}_{facing}", "from": start, "to": len(order) - 1, "direction": "forward"})
    cw, ch = se.size
    rows = (len(order) + COLS - 1) // COLS
    out = Image.new("RGBA", (cw * COLS, ch * rows), (0, 0, 0, 0))
    frames = []
    for i, (f, ms) in enumerate(order):
        x, y = (i % COLS) * cw, (i // COLS) * ch
        out.alpha_composite(f, (x, y))
        frames.append({"filename": f"{name} {i}", "frame": {"x": x, "y": y, "w": cw, "h": ch}, "duration": ms})
    out.save(FINAL / f"{name}_sheet.png")
    meta = {"frames": frames, "meta": {"app": APP, "image": f"{name}_sheet.png",
            "size": {"w": out.width, "h": out.height}, "frameTags": tags}}
    sheet_json.write_text(json.dumps(meta, indent=1), newline="\n")
    print(f"{name}: {len(order)} frames, cell {cw}x{ch}")
    if preview:
        big = Image.new("RGBA", out.size, (60, 58, 88, 255))
        big.alpha_composite(out)
        big.resize((out.width * 4, out.height * 4), Image.NEAREST).save(preview / f"{name}_sheet_x4.png")


def main():
    preview = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    for name, opts in CHARACTERS.items():
        build(name, opts, preview)


if __name__ == "__main__":
    main()
