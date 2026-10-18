"""Generates ORION's placeholder sounds with nothing but the Python standard library.

    python tools/gen_audio.py

Writes short effects to audio/sfx/<name>.wav and two 16-second loops to audio/music/:
explore.wav (a plucked lyre in D Dorian over a drone) and tension.wav (a frame-drum pattern).
Both loops share length and sample rate, so the game can start them together and cross-fade
them by the guards' awareness. Replace any file with a real recording of the same name.
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
ROOT = Path(__file__).resolve().parent.parent
SFX = ROOT / "audio" / "sfx"
MUSIC = ROOT / "audio" / "music"
rng = random.Random(1987)


# ---------------------------------------------------------------- building blocks

def silence(sec):
    return [0.0] * int(sec * RATE)


def env(n, attack=0.005, release=None, curve=3.0):
    """Attack then exponential decay over n samples."""
    a = max(1, int(attack * RATE))
    out = []
    for i in range(n):
        if i < a:
            out.append(i / a)
        else:
            t = (i - a) / max(1, n - a)
            out.append(math.exp(-curve * t) * (1 - t) if release is None else max(0.0, 1 - t))
    return out


def tone(freq, sec, wave_="sine", vol=0.5, slide=0.0, attack=0.005, curve=3.0):
    """A pitched tone; `slide` bends the pitch by that many Hz over its length."""
    n = int(sec * RATE)
    e = env(n, attack, curve=curve)
    out, ph = [], 0.0
    for i in range(n):
        f = freq + slide * i / n
        ph += f / RATE
        x = ph % 1.0
        if wave_ == "sine":
            s = math.sin(2 * math.pi * x)
        elif wave_ == "square":
            s = 1.0 if x < 0.5 else -1.0
        elif wave_ == "tri":
            s = 4 * abs(x - 0.5) - 1
        else:
            s = 2 * x - 1
        out.append(s * e[i] * vol)
    return out


def noise(sec, vol=0.5, lp=0.5, attack=0.002, curve=4.0):
    """Filtered white noise; lp near 0 is dull, near 1 is bright."""
    n = int(sec * RATE)
    e = env(n, attack, curve=curve)
    out, y = [], 0.0
    for i in range(n):
        y += lp * (rng.uniform(-1, 1) - y)
        out.append(y * e[i] * vol)
    return out


def mix(*parts, offsets=None):
    offsets = offsets or [0.0] * len(parts)
    n = max(int(o * RATE) + len(p) for p, o in zip(parts, offsets))
    out = [0.0] * n
    for p, o in zip(parts, offsets):
        s = int(o * RATE)
        for i, v in enumerate(p):
            out[s + i] += v
    return out


def seq(*parts):
    out = []
    for p in parts:
        out += p
    return out


def pluck(freq, sec, vol=0.5, damp=0.996):
    """Karplus-Strong plucked string: a burst of noise in a delay line that loses its highs."""
    n = int(sec * RATE)
    period = max(2, int(RATE / freq))
    buf = [rng.uniform(-1, 1) for _ in range(period)]
    out = []
    for i in range(n):
        j = i % period
        v = buf[j]
        nxt = buf[(j + 1) % period]
        buf[j] = damp * 0.5 * (v + nxt)
        out.append(v * vol)
    return out


def drum(freq, sec, vol=0.7, skin=0.25):
    """A frame drum: a pitch-dropping body plus a slap of noise."""
    body = tone(freq, sec, "sine", vol, slide=-freq * 0.45, curve=6.0)
    slap = noise(min(sec, 0.06), vol * skin, lp=0.6, curve=8.0)
    return mix(body, slap)


def write(path, samples, peak=0.85):
    path.parent.mkdir(parents=True, exist_ok=True)
    m = max(0.0001, max(abs(s) for s in samples))
    k = peak / m if m > peak else 1.0
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * k)) * 32767)) for s in samples))


# ---------------------------------------------------------------- effects

def effects():
    fx = {
        "step": noise(0.07, 0.5, lp=0.25, curve=7),
        # Footstep variants (Sfx picks step, step_1 ... at random): grit plus a soft heel thump.
        "step_1": mix(noise(0.06, 0.5, lp=0.22, curve=7), tone(95, 0.05, "sine", 0.35, slide=-20, curve=6)),
        "step_2": mix(noise(0.07, 0.45, lp=0.28, curve=8), tone(110, 0.05, "sine", 0.3, slide=-25, curve=6)),
        "step_3": mix(noise(0.05, 0.5, lp=0.18, curve=6), tone(85, 0.06, "sine", 0.35, slide=-15, curve=6)),
        "step_4": mix(noise(0.08, 0.4, lp=0.32, curve=9), tone(120, 0.04, "sine", 0.25, slide=-30, curve=6)),
        "swing": noise(0.18, 0.5, lp=0.85, attack=0.04, curve=3),
        "hit": mix(noise(0.12, 0.7, lp=0.4, curve=6), tone(140, 0.12, "sine", 0.5, slide=-60, curve=6)),
        "shield": mix(tone(380, 0.35, "square", 0.25, curve=5), tone(571, 0.3, "tri", 0.25, curve=5), noise(0.05, 0.5, lp=0.9)),
        # A bronze bell ring: inharmonic partials (1, 2.76, 5.4) with a long tail, over a bright click.
        "parry": mix(tone(1480, 1.1, "sine", 0.3, curve=2.2), tone(1480 * 2.76, 0.6, "sine", 0.14, curve=3),
                     tone(1480 * 5.4, 0.3, "sine", 0.08, curve=4), tone(740, 0.9, "tri", 0.15, curve=2.5),
                     noise(0.03, 0.7, lp=0.98)),
        "dodge": noise(0.16, 0.35, lp=0.55, attack=0.03, curve=2.5),
        "jump": tone(220, 0.14, "tri", 0.35, slide=180, curve=3),
        "land": noise(0.09, 0.55, lp=0.2, curve=6),
        "hurt": mix(tone(300, 0.25, "square", 0.25, slide=-160, curve=4), noise(0.1, 0.4, lp=0.5)),
        "fall": tone(500, 0.7, "tri", 0.35, slide=-420, attack=0.01, curve=1.5),
        "death": seq(tone(330, 0.3, "tri", 0.35, curve=2), tone(262, 0.3, "tri", 0.35, curve=2), tone(196, 0.8, "tri", 0.35, curve=2)),
        "ko": mix(noise(0.25, 0.6, lp=0.2, curve=4), tone(90, 0.25, "sine", 0.5, slide=-30, curve=5)),
        "coin": seq(tone(1568, 0.06, "square", 0.18, curve=2), tone(2093, 0.18, "square", 0.18, curve=4)),
        "pickup": seq(tone(784, 0.07, "tri", 0.3), tone(1047, 0.07, "tri", 0.3), tone(1319, 0.16, "tri", 0.3)),
        "buy": seq(tone(1047, 0.06, "square", 0.15), tone(1319, 0.06, "square", 0.15), tone(1568, 0.2, "square", 0.15, curve=4)),
        "deny": seq(tone(196, 0.1, "square", 0.2, curve=1), tone(147, 0.18, "square", 0.2, curve=2)),
        "heal": seq(tone(523, 0.1, "sine", 0.35), tone(659, 0.1, "sine", 0.35), tone(784, 0.3, "sine", 0.35, curve=3)),
        "pot_crack": mix(noise(0.08, 0.6, lp=0.7, curve=8), tone(900, 0.06, "tri", 0.2, curve=8)),
        "pot_smash": mix(noise(0.45, 0.7, lp=0.75, curve=4), *[tone(rng.uniform(1200, 2600), 0.15, "tri", 0.12, curve=6) for _ in range(4)],
                         offsets=[0, 0.0, 0.05, 0.11, 0.18]),
        "chest": mix(tone(110, 0.6, "saw", 0.12, slide=40, attack=0.1, curve=1), noise(0.6, 0.15, lp=0.1, attack=0.1, curve=1)),
        "creak": tone(180, 0.5, "saw", 0.2, slide=-50, attack=0.08, curve=1.5),
        "crumble": mix(noise(0.8, 0.7, lp=0.15, curve=2.5), noise(0.3, 0.3, lp=0.6, curve=5), offsets=[0, 0.1]),
        "clack": seq(tone(1700, 0.03, "square", 0.25, curve=8), silence(0.05), tone(1500, 0.03, "square", 0.18, curve=8)),
        "toss": noise(0.12, 0.25, lp=0.7, attack=0.03, curve=3),
        "shove": mix(noise(0.14, 0.5, lp=0.3, curve=5), tone(120, 0.12, "sine", 0.35, curve=5)),
        "torch": mix(noise(0.35, 0.5, lp=0.45, attack=0.01, curve=3), tone(80, 0.3, "sine", 0.3, curve=4)),
        "glint_white": mix(tone(2637, 0.35, "sine", 0.3, curve=4), tone(3951, 0.25, "sine", 0.15, curve=5)),
        "glint_red": mix(tone(220, 0.4, "square", 0.22, curve=3), tone(233, 0.4, "square", 0.22, curve=3)),
        # The stinger when a guard spots you: a frame-drum hit under a rising, sour two-note call.
        "alert": mix(drum(70, 0.5, 0.8), seq(silence(0.02), tone(587, 0.12, "square", 0.2, curve=1),
                                              tone(831, 0.5, "square", 0.22, slide=-30, curve=2))),
        "suspicious": tone(660, 0.25, "tri", 0.25, slide=120, curve=3),
        "mark": mix(*[tone(f, 0.9, "sine", 0.18, curve=3) for f in (587, 740, 880, 1175)], offsets=[0, 0.08, 0.16, 0.24]),
        "star": mix(*[tone(f, 1.6, "sine", 0.2, curve=2) for f in (294, 440, 587, 880, 1175)], offsets=[0, 0.1, 0.2, 0.3, 0.45]),
        "ui_move": tone(1200, 0.04, "square", 0.12, curve=6),
        "ui_select": seq(tone(900, 0.04, "square", 0.15), tone(1350, 0.08, "square", 0.15, curve=4)),
    }
    for name, s in fx.items():
        write(SFX / f"{name}.wav", s)
    return sorted(fx)


# ---------------------------------------------------------------- music

LOOP = 16.0
BPM = 90
BEAT = 60.0 / BPM


def hz(semitones_from_d3):
    return 146.83 * 2 ** (semitones_from_d3 / 12)


def explore():
    """Lyre phrases in D Dorian (D E F G A B C) over a soft D-A drone."""
    n = int(LOOP * RATE)
    out = [0.0] * n
    # Drone: D2 and A2, slowly breathing so the loop seam is smooth.
    for i in range(n):
        t = i / RATE
        breath = 0.75 + 0.25 * math.sin(2 * math.pi * t / LOOP)
        out[i] += breath * (0.07 * math.sin(2 * math.pi * 73.42 * t) + 0.045 * math.sin(2 * math.pi * 110.0 * t)
                            + 0.02 * math.sin(2 * math.pi * 146.83 * t))
    dorian = [0, 2, 3, 5, 7, 9, 10, 12, 14, 15, 17]
    phrase = [  # (beat, scale degree, length in beats)
        (0, 7, 1), (1, 9, 0.5), (1.5, 8, 0.5), (2, 7, 1), (3, 4, 1),
        (4, 5, 1.5), (5.5, 4, 0.5), (6, 3, 1), (7, 4, 1),
        (8, 7, 1), (9, 10, 1), (10, 9, 0.5), (10.5, 8, 0.5), (11, 7, 1),
        (12, 5, 1), (13, 6, 0.5), (13.5, 5, 0.5), (14, 4, 2),
        (16, 0, 1), (17, 2, 1), (18, 4, 1), (19, 3, 0.5), (19.5, 2, 0.5),
        (20, 4, 2), (22, 5, 1), (23, 6, 1),
    ]
    for beat, deg, length in phrase:
        start = int(beat * BEAT * RATE)
        if start >= n:
            continue
        note = pluck(hz(dorian[deg]), min(length * BEAT + 1.2, LOOP - beat * BEAT), 0.32)
        for i, v in enumerate(note):
            out[(start + i) % n] += v
    # Bass plucks on the bar.
    for bar in range(int(LOOP / (BEAT * 4))):
        start = int(bar * 4 * BEAT * RATE)
        root = [0, 0, -2, 3][bar % 4]
        note = pluck(hz(root - 12), 2.5, 0.25, damp=0.993)
        for i, v in enumerate(note):
            out[(start + i) % n] += v
    return out


def tension():
    """A frame-drum pattern in the same tempo: doum and tek, with a rattle on the off-beats."""
    n = int(LOOP * RATE)
    out = [0.0] * n
    pattern = [("D", 0), ("t", 0.75), ("t", 1.5), ("D", 2), ("t", 2.5), ("t", 3.25), ("r", 3.5)]
    bars = int(LOOP / (BEAT * 4))
    for bar in range(bars):
        for kind, beat in pattern:
            start = int((bar * 4 + beat) * BEAT * RATE)
            if kind == "D":
                hit = drum(78, 0.5, 0.75, skin=0.2)
            elif kind == "t":
                hit = drum(240, 0.12, 0.35, skin=0.9)
            else:
                hit = noise(0.18, 0.18, lp=0.8, curve=3)
            for i, v in enumerate(hit):
                out[(start + i) % n] += v
    # A low pulse under it all.
    for i in range(n):
        t = i / RATE
        out[i] += 0.05 * math.sin(2 * math.pi * 55.0 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * t / (BEAT * 2)))
    return out


if __name__ == "__main__":
    random.seed(7)  # the same files every run, so regenerating doesn't churn git
    names = effects()
    print("sfx:", len(names), "files in", SFX)
    write(MUSIC / "explore.wav", explore(), peak=0.7)
    write(MUSIC / "tension.wav", tension(), peak=0.7)
    print("music: explore.wav, tension.wav in", MUSIC)
