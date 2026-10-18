# ORION v1 — overnight polish

Polish pass on the `v1-prototype` branch: real character sprites, game feel, atmosphere, UI,
sound and tuning. The checklist is in priority order; the dated log is at the bottom.

## Checklist

- [x] Character sprites from `art/generated/` via `tools/process_generated.py` → `art/final/`
- [x] Procedural character life: walk bob, step squash, breathing idle, blob shadows
- [x] Game feel: input buffering, acceleration, trauma screen shake, hit-stop, hit flash,
      knockback, jump/land squash, dust, camera look-ahead, perfect-parry zoom and slow-mo,
      clearer stagger and KO, obol pickups
- [x] Atmosphere: night sky with Orion, dust motes, embers, animated water, vignette, light
      contrast
- [ ] Star shrine inner wall corners (dark blocks); statue court portico height (not started)
- [x] UI: in-repo pixel font, first-time control hints, objective line, title constellation,
      obol counter pop (shop and end card only restyled by the font so far)
- [x] Sound: footstep variety, alert stinger, parry ring, smoother music layers
- [ ] Sound: better music (the two loops are unchanged)
- [ ] Tuning with timelines and bots

## Notes

- **The character art is AI-generated** (ChatGPT image generation; the source sheets are in
  `art/generated/`). The hackathon's rules on AI-made assets are **still unchecked**: check them
  before the demo, and be ready to say which art is AI-made.
- `tools/process_generated.py` is repeatable: keys out the magenta, crops each view, scales both
  facings of a character by one factor, picks one palette colour per block (the block mean,
  unless a clearly darker group would be lost: outlines, eyes, belts), snaps to
  `art/palette/orion.gpl` in Lab, cleans orphans and holes, re-draws a dark outline, and pastes
  onto the placeholder canvas with the feet on the bottom-centre pixel. Per-sprite settings
  (height, feet position, excluded colours, pixel touch-ups) are in its `JOBS` table.
- The sheets have only a front (SE) and a back (NE) view, no animation frames, so movement is
  procedural (see the log).

## Log

- 2026-10-19 01:38: Started. Usage at 57% of the 5-hour window when the session began.
- 2026-10-19: Sprites: `tools/process_generated.py` writes 11 sprites into `art/final/`
  (Cedalion, Watchman, Spearman, Hoplite SE/NE; Phineus SE; Shade SE/NE). Heights: Cedalion
  27 px, Watchman 37, Spearman 44 with the torch, Hoplite 47 with the spear, Phineus 28, Shade 36.
  The Hoplite excludes the skin ramp so his bronze stays bronze. Cedalion's torch is in his right
  hand, so the torch light now sits on the screen-left side when he faces SE. New test: every
  final sprite has its placeholder's size.
- 2026-10-19: Game feel. Researched the usual sources first (Celeste's forgiveness article on
  buffering; the trauma model of screen shake: trauma 0..1, offset ∝ trauma², linear decay).
  New `scripts/core/`: `ShakeCamera` (trauma shake rounded to whole pixels, zoom punch,
  look-ahead toward Cedalion's velocity), `Juice` (hit-stop and slow-motion holds where the
  slowest active hold wins; an unshaded flash material), `Life` (walk bob, step squash, breathing
  idle, spring-back squash and stretch, two-tone blob shadow that shrinks in the air). Player:
  0.15 s input buffer for attack, parry, dodge, jump, shove, thrust; attacks chain from the
  follow-through and a dodge cancels the recovery; acceleration 26 and deceleration 20 tiles/s²
  with a faster turnaround; squash on jump, land, dodge, swing and hurt; dust on runs, dodges and
  landings; hits freeze 65 ms (100 ms for ripostes, backstabs and the third combo swing, which
  also knock back 1.8×); a successful parry flashes, rings, punches the zoom, freezes 90 ms and
  then plays 300 ms at 35% speed. Guards: white hit flash, knockback 0.45 tiles, a stagger
  shudder, dazed stars on long stuns, and a KO that topples with dust and a thud. Obols are drawn
  to Cedalion within 1.8 tiles once landed, glitter, and ring higher in a quick streak. Pause menu
  has a "Screen shake" toggle (`Game.screen_shake`). Tests: 118 pass.
- 2026-10-19: Atmosphere (`scripts/world/atmosphere.gd`, added by `Room.build`): a night sky
  on a canvas layer behind each open-air room (dithered bands, 150 twinkling stars with slight
  parallax, a haloed moon, and Orion drawn from his eight main stars with dotted lines; he moves
  from high in the east to low in the west with `Atmosphere.orion_progress()`, so the sky is the
  clock); the storerooms and cistern are roofed and stay dark. A 480×270 vignette with Bayer
  dithered alpha. Embers rise from Cedalion's torch (they follow the flame pixel per facing),
  wall lamps and braziers. Dust motes drift in every moonlight pool. Water tiles share a shader
  that runs glints and crests across them in screen pixels. Moonlight is a little stronger (0.9)
  and guard lanterns are redder (and turn red when a guard is alert), so warm torch, cool moon
  and red enemy light read apart.
- 2026-10-19: UI. `tools/gen_font.py` draws "Orion 5x7", an original 109-glyph pixel font
  (caps and digits 5×7, lowercase with ascenders and descenders, plus · — – … “ ” ’ é × and
  arrows), and writes it as a BMFont (`art/fonts/orion_pixel.fnt` + `.png`); it is the project's
  default font (`gui/theme/custom_font`) and imports with integer-only scaling. `UiKit.px()`
  maps nominal sizes to whole multiples of its 10 px design size (under 16 → 1×, body and buttons
  2×, titles 3–5×), and labels use a 1-pixel drop shadow instead of an outline. The HUD shows each
  room's objective line at the top and, the first time a room is entered, one or two control
  hints as toasts (`Hud.ROOMS`); the interaction prompt and toasts are 2×; the obol counter pops
  when it changes. The title screen draws Orion star by star and line by line over ~3 s.
- 2026-10-19: Sound. `Sfx` now picks a random take of an effect from `<name>.wav` and
  `<name>_1..8.wav`; `tools/gen_audio.py` adds four footstep takes (grit plus a heel thump), a
  bronze-bell parry ring (inharmonic partials, long tail), and an alert stinger (frame drum under
  a rising sour call). The tension layer eases in fast (rate 2.2/s) and lingers on the way down
  (0.45/s) with a smoothstep volume curve. The generator is seeded, so re-running it no longer
  changes every file.
