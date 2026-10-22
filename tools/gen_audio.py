"""Generates ORION's placeholder sounds with nothing but the Python standard library.

    python tools/gen_audio.py

Writes short effects to audio/sfx/<name>.wav and two 48-second loops to audio/music/:
explore.wav (a lyre, pad and aulos in D Dorian) and tension.wav (frame drums and an ostinato),
and three 24-second room-tone loops to audio/ambience/ (night, cistern, indoor).
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
#
# Both loops are 16 bars of 4/4 at 80 BPM (48 s), so the game starts them together and fades the
# tension layer in and out. Explore is a night piece in D Dorian: a soft chord pad, a lyre that
# phrases A A' B A'', an aulos answering in the B section, bass plucks. Tension keeps the same
# bars: frame drums with fills, a low plucked ostinato on D and a tremolo drone that swells every
# four bars. Everything goes through a small reverb that wraps around the loop seam.

BPM = 80
BEAT = 60.0 / BPM
BARS = 16
LOOP = BARS * 4 * BEAT


def hz(semitones_from_d3):
    return 146.83 * 2 ** (semitones_from_d3 / 12)


def seamless(freq):
    """The nearest frequency that fits a whole number of cycles into the loop."""
    return round(freq * LOOP) / LOOP


def place(out, part, at_sec, gain=1.0):
    """Adds part into out at at_sec, wrapping around the end of the loop."""
    n = len(out)
    s = int(at_sec * RATE)
    for i, v in enumerate(part):
        out[(s + i) % n] += v * gain


def reverb(samples, mix_=0.3, room=0.84, damp=0.35):
    """A Schroeder/Freeverb-style reverb: parallel damped combs into series all-passes. Runs the
    loop twice and keeps the second pass, so the tail wraps around the seam."""
    n = len(samples)
    src = samples + samples
    wet = [0.0] * len(src)
    for d in (1116, 1188, 1277, 1356, 1422, 1491):
        d = int(d * RATE / 44100)
        buf, j, f = [0.0] * d, 0, 0.0
        for i, x in enumerate(src):
            y = buf[j]
            f = y * (1 - damp) + f * damp
            buf[j] = x + f * room
            wet[i] += y
            j = (j + 1) % d
    for d in (556, 441, 341, 225):
        d = int(d * RATE / 44100)
        buf, j = [0.0] * d, 0
        for i, x in enumerate(wet):
            b = buf[j]
            buf[j] = x + b * 0.5
            wet[i] = b - x
            j = (j + 1) % d
    return [samples[i] * (1 - mix_) + wet[n + i] * mix_ * 0.18 for i in range(n)]


def pad_note(freq, sec, vol):
    """Two detuned saws, darkened, with a slow swell in and out (a bowed or breathed chord)."""
    n = int(sec * RATE)
    out, p1, p2, y = [], 0.0, 0.0, 0.0
    for i in range(n):
        p1 += freq * 0.997 / RATE
        p2 += freq * 1.003 / RATE
        v = (p1 % 1.0) + (p2 % 1.0) - 1.0
        y += 0.06 * (v - y)
        t = i / n
        e = min(1.0, t / 0.3) * min(1.0, (1 - t) / 0.35)
        out.append(y * vol * e * e)
    return out


def reed(freq, sec, vol):
    """An aulos-like reed: a few odd-heavy harmonics, a breathy attack, vibrato that grows."""
    n = int(sec * RATE)
    out, ph = [], 0.0
    for i in range(n):
        t = i / RATE
        vib = 1 + 0.006 * min(1.0, t / 0.6) * math.sin(2 * math.pi * 5.2 * t)
        ph += freq * vib / RATE
        x = 2 * math.pi * ph
        v = math.sin(x) + 0.45 * math.sin(3 * x) + 0.22 * math.sin(2 * x) + 0.12 * math.sin(5 * x)
        e = min(1.0, t / 0.12) * min(1.0, (sec - t) / 0.4)
        out.append((v + rng.uniform(-0.15, 0.15) * (1 - min(1.0, t / 0.2))) * vol * max(0.0, e))
    return out


# D Dorian as semitones above D3; degree 7 is D4, negative degrees reach below D3.
DORIAN = [0, 2, 3, 5, 7, 9, 10]


def deg(d):
    return DORIAN[d % 7] + 12 * (d // 7)


# Two bars per chord: i, VII, IV, i, i, VII, v, i (D minor, C, G, D minor, D minor, C, A minor, D minor).
CHORDS = [[0, 2, 4], [-1, 1, 3], [3, 5, 7], [0, 2, 4], [0, 2, 4], [-1, 1, 3], [4, 6, 8], [0, 2, 4]]

# Lyre phrases as (beat, degree, beats), four bars (16 beats) each.
PHRASE_A = [(0, 7, 1), (1, 9, 0.5), (1.5, 8, 0.5), (2, 7, 1.5), (4, 6, 1), (5, 5, 1), (6, 4, 2),
            (8, 5, 1), (9, 6, 0.5), (9.5, 5, 0.5), (10, 4, 1), (11, 3, 1), (12, 4, 3)]
PHRASE_A2 = [(0, 7, 1), (1, 9, 0.5), (1.5, 8, 0.5), (2, 7, 1.5), (4, 9, 1), (5, 10, 1), (6, 9, 2),
             (8, 8, 1), (9, 7, 0.5), (9.5, 6, 0.5), (10, 5, 1), (11, 6, 1), (12, 7, 3)]
PHRASE_B = [(0, 11, 2), (2, 10, 1), (3, 9, 1), (4, 8, 2), (6, 9, 2),
            (8, 11, 1), (9, 12, 1), (10, 11, 1), (11, 9, 1), (12, 8, 3)]
PHRASE_A3 = [(0, 7, 1), (1, 9, 0.5), (1.5, 8, 0.5), (2, 7, 1.5), (4, 6, 1), (5, 5, 1), (6, 4, 2),
             (8, 3, 1), (9, 2, 1), (10, 1, 1), (11, -1, 1), (12, 0, 4)]
# The aulos answers the lyre's B phrase (from bar 9) and holds under the return.
AULOS = [(2, 4, 2), (6, 5, 2), (10, 6, 1.5), (12, 4, 4), (18, 2, 2), (22, 3, 2), (26, 4, 1.5), (28, 1, 4)]


def explore():
    n = int(LOOP * RATE)
    out = [0.0] * n
    bar = 4 * BEAT
    # Pad: each chord swells over its two bars and overlaps the next a little.
    for i, chord in enumerate(CHORDS):
        for d in chord:
            place(out, pad_note(hz(deg(d) - 12), bar * 2 + 1.0, 0.045), i * bar * 2 - 0.5)
    # A low drone on D under everything, breathing once per loop (whole cycles, so no seam click).
    f = seamless(73.42)
    for i in range(n):
        t = i / RATE
        out[i] += (0.05 + 0.02 * math.sin(2 * math.pi * t / LOOP)) * math.sin(2 * math.pi * f * t)
    # Bass pluck on each bar (the chord's root), and its fifth late in every second bar.
    for b in range(BARS):
        root = CHORDS[b // 2][0]
        place(out, pluck(hz(deg(root) - 12), 2.8, 0.22, damp=0.993), b * bar)
        if b % 2 == 1:
            place(out, pluck(hz(deg(root + 4) - 12), 1.5, 0.12, damp=0.99), b * bar + 2.5 * BEAT)
    # Lyre: A A' B A'', with a little human timing.
    for k, phrase in enumerate([PHRASE_A, PHRASE_A2, PHRASE_B, PHRASE_A3]):
        for beat, d, length in phrase:
            at = (k * 16 + beat) * BEAT + rng.uniform(-0.012, 0.012)
            vol = 0.3 if beat % 2 == 0 else 0.24
            place(out, pluck(hz(deg(d)), length * BEAT + 1.4, vol), at)
            if k == 2 and length >= 2:  # the B phrase's long notes get a fifth below
                place(out, pluck(hz(deg(d - 4)), length * BEAT + 1.0, 0.12), at + 0.03)
    for beat, d, length in AULOS:
        place(out, reed(hz(deg(d)), length * BEAT, 0.05), (32 + beat) * BEAT)
    return reverb(out, mix_=0.35)


def tension():
    n = int(LOOP * RATE)
    out = [0.0] * n
    bar = 4 * BEAT
    main = [("D", 0), ("t", 0.75), ("t", 1.5), ("D", 2), ("t", 2.5), ("t", 3.25), ("r", 3.5)]
    fill = [("D", 0), ("t", 0.5), ("t", 0.75), ("D", 1.5), ("D", 2), ("t", 2.5), ("t", 3), ("t", 3.25),
            ("t", 3.5), ("t", 3.75)]
    for b in range(BARS):
        for kind, beat in (fill if b % 4 == 3 else main):
            at = (b * 4 + beat) * BEAT
            if kind == "D":
                hit = drum(72, 0.6, 0.7, skin=0.2)
            elif kind == "t":
                hit = drum(250 + rng.uniform(-15, 15), 0.12, 0.3 + rng.uniform(0, 0.08), skin=0.6)
            else:
                hit = noise(0.2, 0.1, lp=0.7, curve=3)
            place(out, hit, at)
    # Ostinato: low plucked eighths on D, lifting to A and C at the end of each bar.
    figure = [0, 0, 0, 0, 0, 0, 4, 6]
    for b in range(BARS):
        for e, d in enumerate(figure):
            place(out, pluck(hz(deg(d) - 24), 0.5, 0.2 if e % 2 == 0 else 0.13, damp=0.985), (b * 4 + e * 0.5) * BEAT)
    # A tremolo drone on D, A and D, swelling across each four bars.
    four = 4 * bar
    for d, vol in ((0, 0.05), (4, 0.035), (7, 0.02)):
        f = seamless(hz(deg(d) - 12))
        ph1 = ph2 = y = 0.0
        for i in range(n):
            t = i / RATE
            ph1 += (f - 12 / LOOP) / RATE
            ph2 += (f + 12 / LOOP) / RATE
            y += 0.05 * ((ph1 % 1.0) + (ph2 % 1.0) - 1.0 - y)
            swell = 0.35 + 0.65 * ((t % four) / four) ** 2
            trem = 0.6 + 0.4 * math.sin(2 * math.pi * t * 2 / BEAT)
            out[i] += y * vol * swell * trem
    return reverb(out, mix_=0.15, room=0.75)


# ---------------------------------------------------------------- ambience
#
# Room tone under the music, one loop per kind of room (audio/ambience/<name>.wav): "night" for the
# open-air rooms and the title (wind and crickets), "cistern" (drips in a stone tank), "indoor"
# (a low draught through the storerooms). Each is 24 s and seamless: wrapped events, slow
# modulations with whole cycles per loop, and noise crossfaded across the seam.

AMBIENCE = ROOT / "audio" / "ambience"
AMB_LOOP = 24.0


def loopify(samples, fade_sec=1.5):
    """Crossfades the tail into the head so filtered noise loops without a seam. The input must be
    AMB_LOOP + fade_sec long; the result is AMB_LOOP long."""
    n = int(AMB_LOOP * RATE)
    f = int(fade_sec * RATE)
    out = samples[:n]
    for i in range(f):
        k = i / f
        out[i] = samples[n + i] * (1 - k) + samples[i] * k
    return out


def wind(sec, vol, lp, gusts):
    """Lowpassed noise whose loudness swells with a few slow sines (whole cycles per loop)."""
    n = int(sec * RATE)
    out, y, y2 = [], 0.0, 0.0
    for i in range(n):
        t = i / RATE
        y += lp * (rng.uniform(-1, 1) - y)
        y2 += lp * (y - y2)
        g = 0.55 + sum(a * math.sin(2 * math.pi * c * t / AMB_LOOP + ph) for c, a, ph in gusts)
        out.append(y2 * vol * max(0.1, g))
    return out


def chirp(freq, pulses, vol):
    """One cricket chirp: a few 14 ms pulses of a high tone."""
    out = []
    for _ in range(pulses):
        m = int(0.014 * RATE)
        for i in range(m):
            e = math.sin(math.pi * i / m)
            out.append(math.sin(2 * math.pi * freq * i / RATE) * e * vol)
        out += [0.0] * int(0.012 * RATE)
    return out


def drip(freq, vol):
    """A drop into still water: a short sine that leaps up in pitch, then a faint ring."""
    n = int(0.25 * RATE)
    out, ph = [], 0.0
    for i in range(n):
        t = i / RATE
        f = freq * (1 + 1.4 * min(1.0, t / 0.02))
        ph += f / RATE
        out.append(math.sin(2 * math.pi * ph) * math.exp(-t * 26) * vol)
    return out


def amb_night():
    n = int(AMB_LOOP * RATE)
    total = AMB_LOOP + 1.5
    out = wind(total, 0.5, 0.05, [(1, 0.25, 0.0), (3, 0.15, 1.3), (5, 0.08, 2.1)])
    out = loopify(out)
    # Two crickets, each with its own pitch and rhythm, fading in and out of hearing.
    for freq, period, pulses, vol, cyc in ((4300, 0.62, 3, 0.05, 2), (3800, 0.9, 4, 0.035, 3)):
        t = rng.uniform(0, period)
        while t < AMB_LOOP:
            presence = 0.5 + 0.5 * math.sin(2 * math.pi * cyc * t / AMB_LOOP)
            if presence > 0.25:
                place(out, chirp(freq + rng.uniform(-40, 40), pulses, vol * presence), t)
            t += period * rng.uniform(0.9, 1.1)
    return out


def amb_cistern():
    total = AMB_LOOP + 1.5
    out = loopify(wind(total, 0.22, 0.02, [(1, 0.15, 0.4), (2, 0.1, 2.0)]))
    # Drips at irregular intervals, from two or three spots in the tank.
    t = 0.3
    while t < AMB_LOOP:
        place(out, drip(rng.choice([900, 1150, 1400]) * rng.uniform(0.95, 1.05), rng.uniform(0.06, 0.12)), t)
        t += rng.uniform(0.7, 2.6)
    return reverb(out, mix_=0.5, room=0.88)


def amb_indoor():
    total = AMB_LOOP + 1.5
    return loopify(wind(total, 0.3, 0.025, [(1, 0.3, 0.0), (2, 0.2, 1.0), (4, 0.1, 2.5)]))


def rise():
    """The climb between islands: a rush of air that swells and fades, an airy tone rising under
    it, and a soft lyre chord as the next island settles."""
    air = noise(1.1, 0.5, lp=0.12, attack=0.45, curve=2.0)
    lift = tone(196, 1.0, "sine", 0.12, slide=196, attack=0.3, curve=2.0)
    chord = mix(pluck(hz(12), 1.0, 0.22), pluck(hz(19), 0.9, 0.16), pluck(hz(24), 0.8, 0.12), offsets=[0.0, 0.07, 0.14])
    return mix(air, lift, chord, offsets=[0.0, 0.05, 0.62])


if __name__ == "__main__":
    random.seed(7)  # the same files every run, so regenerating doesn't churn git
    names = effects()
    print("sfx:", len(names), "files in", SFX)
    write(MUSIC / "explore.wav", explore(), peak=0.7)
    write(MUSIC / "tension.wav", tension(), peak=0.7)
    print("music: explore.wav, tension.wav in", MUSIC)
    write(AMBIENCE / "night.wav", amb_night(), peak=0.5)
    write(AMBIENCE / "cistern.wav", amb_cistern(), peak=0.5)
    write(AMBIENCE / "indoor.wav", amb_indoor(), peak=0.5)
    print("ambience: night.wav, cistern.wav, indoor.wav in", AMBIENCE)
    # Added last, so every file above keeps its random stream and stays byte-identical.
    write(SFX / "rise.wav", rise(), peak=0.6)
