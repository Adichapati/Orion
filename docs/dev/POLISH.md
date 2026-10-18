# ORION v1 — overnight polish

Polish pass on the `v1-prototype` branch: real character sprites, game feel, atmosphere, UI,
sound and tuning. The checklist is in priority order; the dated log is at the bottom.

## Checklist

- [x] Character sprites from `art/generated/` via `tools/process_generated.py` → `art/final/`
- [ ] Procedural character life: walk bob, squash and stretch, lean, blob shadows
- [ ] Game feel: input buffering, acceleration, trauma screen shake, hit-stop, hit flash,
      knockback, jump/land squash, dust, camera look-ahead, perfect-parry zoom and slow-mo,
      clearer stagger and KO, obol pickups
- [ ] Atmosphere: night sky with Orion, dust motes, embers, animated water, vignette, light
      contrast; star shrine inner corners; statue court portico height
- [ ] UI: in-repo pixel font, first-time control hints, objective line, title constellation,
      HUD, shop and end card polish
- [ ] Sound: better effects and music, footstep variety, alert stinger, parry ring, smoother
      music layers
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
