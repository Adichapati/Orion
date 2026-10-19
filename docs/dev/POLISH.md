# ORION v1 — overnight polish

Polish pass on the `v1-prototype` branch: real character sprites, game feel, atmosphere, UI,
sound and tuning. The checklist is in priority order; the dated log is at the bottom.

## Morning summary (2026-10-19, second session; stopped at about 55% of the 5-hour window)

Two sessions ran overnight. The first (8 commits) did the sprites, game feel, atmosphere, the
pixel font and new sounds. The second (about 35 commits) worked down the rest of
the list and then polished whatever looked weakest in screenshots. All 127 tests pass.

**Second session, in order of how much you'll notice:**

1. **The statue court's living statue.** The objective says "One of the stone men breathes", but
   no such guard existed. Now one Hoplite stands in stone among the statues, lantern dark, only
   breathing. Come within 2.6 tiles and he wakes (dust, colour floods back, "Ekeil!"); a noise or
   an alarm wakes him too, and a sharp-eyed player can backstab him first. He guards the
   right-hand stairs; the quiet left-hand steps stay safe.
2. **Stealth readability.** Noise now shows as spreading rings sized to each noise's real radius
   (the GDD's "noise spreads as rings"; before, rings only showed in F3). Holding G aims a
   knucklebone with an arc and its 4-tile hearing ring, and releasing throws it. The screen's
   edge reddens as guards grow aware and pulses while you're hunted. Sneaking crouches Cedalion.
   When a wall hides Cedalion or a guard, a faint outline shows through (blue for him, red for
   them); before, both could vanish behind the cistern's walls.
3. **Parry on the flash.** The glint now flares 0.32 s before the strike, so a press on the flash
   (about 0.2 s of reaction time) lands in the 120 ms window. A bot test checks it: presses 0.20 to
   0.26 s after the flash land, and presses at 0.05 s or 0.45 s miss.
4. **Screens.** The title is recomposed (menu left, Orion right, the citadel skyline with vigil
   lamps). The intro cards tell the story in a band of oil lamps that go out under Antares until
   one flame is left. The end card is a vase frieze with a stamped rank and a counting score. The
   shop has item icons, sections and coin prices. On the death card a torch gutters out.
5. **The world.** The Lion Gate has its lintel and lion relief. The art now has cracks that look
   like cracks, marble hoplite statues, shaded black-figure pithoi and amphorae, braziers with
   animated flames, an olive tree, steps with treads, masonry on both wall faces, hanging ivy,
   floor variety (worn, stained, mossy, leaves), glowing exit doors, smoking vigil lamps and red
   scorpion daubs. Taking the Belt Star is now a beat (freeze, light burst, the star flying to
   you, slow motion).
6. **Sound.** Both music loops are rewritten: 48 s instead of 16 s, with a pad, a phrased lyre, an
   aulos, an ostinato, drum fills and reverb. Room ambience is new: wind and crickets outdoors,
   drips in the cistern, a draught in the storerooms. The pause menu has a volume slider.
7. **Fixes.** The white blowout where torch, moon and lantern overlapped is gone (lights ease
   off in moonlight and near Cedalion). Throws stop at walls but clear pots.

**Look at first:** the six screenshots in `docs/dev/screens/`. Then play from the title
(`godot --path .`) through the statue court: aim a knucklebone with G held, run past a guard to
see the noise ring, and walk up the right-hand stairs.

**Open questions and not done:**

- **The hackathon rules on AI-made assets are unchecked.** The character art is AI-generated.
- **Nobody has listened to the new music or ambience.** I judged them by levels, loop seams and a
  spectrogram only. If they grate, `python tools/gen_audio.py` regenerates them, and everything is
  in the `music` and `ambience` sections.
- **Nothing was felt by hand.** Movement, buffer, hit-stop and shake are still first guesses. The
  parry timing now has a bot test, but the band is narrow (about 0.18 to 0.28 s after the flash).
  If playtesters miss, widen the weapons' `parry_window` (the GDD says 120 ms).
- **Two design calls to confirm:** the living statue is a Hoplite in the statue court, before the
  star shrine where Hoplites were first meant to appear; a toast explains his shield when he
  wakes. And G is now hold-to-aim, release-to-throw (a tap still throws at once).
- The lions on the Lion Gate are an impression at 480×270, not a readable carving. The Shade (v2)
  is still nearly invisible on dark floors.
- Worth generating for real art, as before: walk and swing frames for Cedalion, wind-up poses
  for the guards, a KO pose, Alcyone. `tools/process_generated.py` takes new sheets.

### First session (summary)

Real character sprites from the ChatGPT sheets (`tools/process_generated.py` → `art/final/`)
with procedural life (walk bob, squash, breathing, blob shadows); game feel (input buffering,
acceleration, trauma shake, hit-stop, flashes, knockback, toppling KOs, the perfect-parry beat,
camera look-ahead, magnetic obols); atmosphere (the night sky with Orion as the clock, vignette,
embers, moon motes, glinting water); an in-repo pixel font, objectives and hints; new footsteps,
a parry bell and an alert stinger.

## Checklist

- [x] Character sprites from `art/generated/` via `tools/process_generated.py` → `art/final/`
- [x] Procedural character life: walk bob, step squash, breathing idle, blob shadows
- [x] Game feel: input buffering, acceleration, trauma screen shake, hit-stop, hit flash,
      knockback, jump/land squash, dust, camera look-ahead, perfect-parry zoom and slow-mo,
      clearer stagger and KO, obol pickups
- [x] Atmosphere: night sky with Orion, dust motes, embers, animated water, vignette, light
      contrast
- [x] Star shrine inner wall corners (dark blocks); statue court portico height
- [x] UI: in-repo pixel font, first-time control hints, objective line, title constellation,
      obol counter pop (shop and end card only restyled by the font so far)
- [x] Sound: footstep variety, alert stinger, parry ring, smoother music layers
- [x] Sound: better music (both loops rewritten, 48 s) and room ambience
- [x] UI: shop, end card, intro cards, title and death card restyled; pause volume slider
- [x] Tuning: parry timing (flash cue plus a bot test); detection rates checked (no change)
- [x] Stealth readability: noise rings, knucklebone aim preview, danger vignette, sneak crouch
- [x] GDD gaps: the living statue in the statue court; the Lion Gate; story props
- [ ] Tuning by hand: movement, buffer, hit-stop, shake (needs a person playing)
- [ ] Listen to the new music and ambience

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
- 2026-10-19: Walls and the portico. The blocks' shadowed (right) face was night blue
  (#2e3a5c), which went near-black in the dark rooms, so the star shrine's stepped inner walls
  read as holes and raised floor had no visible side. It is now a blue-grey stone (#5a576b), and
  raised floor has a lighter marble top (Marble 2) than the floor below. Regenerated
  `art/greybox/` with `tools/gen_greybox.py`.
- 2026-10-19 06:10: Second session started (usage 1%). Light blowout: where a moonlight pool,
  Cedalion's torch and a guard's lantern met (colonnade), the marble clipped to white. The torch
  now eases off by up to 60% inside a moonlight pool (`Room.moon_pools`), and a guard's lantern
  and glow dim by up to 45% and 60% when Cedalion is within a few tiles. The spot reads pink-warm
  instead of white.
- 2026-10-19: End card. Still a black-figure vase, but now laid out: banded terracotta that is
  lighter where the vase swells, a black glaze band where Orion draws himself twice in reserved
  clay, the Dawn Rank stamped in gold (scale punch and a low bell) with the score counting up,
  and the night's eight numbers as a frieze (number over name) instead of two dotted lines of
  1× text. The button is black glaze too. Autoshot `screens` now waits for the stamp.
- 2026-10-19: Shop. Seven 12×12 item icons drawn pixel by pixel in `tools/gen_greybox.py`
  (`ITEM_ICONS`: dagger, kopis, xiphos, tunic, linothorax, cuirass, pomegranate) sit in framed
  slots beside each item; goods are grouped under Swords / Armour / Supplies headings; prices are
  an obol glyph and a 2× number (dull red when you can't afford it); worn or held gear has a gold
  slot and says "Worn" / "In hand"; owned items' names are gold; Phineus's portrait is 3× in a
  frame; the purse sits under his words. Also: guard lanterns ease off inside moonlight pools too
  (`Room.moonlight_at()`), which fixes the colonnade guard's white spot.
- 2026-10-19: Music. Both loops rewritten in `tools/gen_audio.py`: 16 bars at 80 BPM (48 s,
  was 16 s at 90). Explore: a dark detuned-saw chord pad (Dm, C, G, Dm / Dm, C, Am, Dm), a D drone,
  bass plucks on each bar, the lyre phrasing A A' B A'' with slight human timing and fifths under
  the B phrase, and an aulos-like reed answering in bars 9–16. Tension, on the same bars: frame
  drums with a fill every fourth bar, a low plucked D ostinato, and a tremolo drone that swells
  every four bars. Both run through a small Freeverb-style reverb that is computed over two
  passes so the tail wraps across the seam, and the drones use whole cycles per loop (checked:
  the seam's largest sample step is no bigger than any other note onset). Nobody has listened to
  it yet; it was judged by levels and a spectrogram only.
- 2026-10-19: Tuning, parry timing. The GDD says "parry on the flash" with a 120 ms window, but
  the glint appeared 0.65 s before the strike and only grew slowly, so there was nothing to time
  the press against. Now the glint flares (2×, overbright) `Guard.FLASH_LEAD` = 0.32 s before the
  strike: a reaction time of ~0.2 s plus a little input and display lag puts the press inside the
  window. A bot test parries at fixed delays after the flash: 0.20, 0.23 and 0.26 s land, 0.05 s
  (too early) and 0.45 s (too late) miss. In that harness, the effective band is roughly 0.18–0.28
  s after the flash; widen it with the weapon's `parry_window` if playtesters miss a lot. New
  autoshot timeline `flash` shoots the flare and the strike.
- 2026-10-19: Greybox art. Cracked marble read as scattered black music notes; `crack()` now
  draws one jagged crack along the floor's diagonal with branches, a dark core, a broken lit
  lower lip and a shadowed upper edge, and the third variant has a chipped-out flake. The statue
  was a flat white silhouette; it is now a marble hoplite (crested helmet, round shield with a
  lit rim and boss, spear, chiton and belt) lit from the left with a dark outline, on the same
  24×46 canvas and plinth.
- 2026-10-19: Floors and pots. Four new plain-marble variants (`floor_marble_worn`, `_stain`,
  `_moss`, `_leaves`) chosen by `Room._plain_floor()`: moss mostly beside walls, leaves only in
  the open air, and nothing crack-like so cracked slabs still read as the hazard. The pithos and
  the amphora are redrawn by one `vessel()` painter from a row profile: lit from the left with
  dithered steps between three clay tones, black-figure bands (the pithos has reserved dots), a
  lit rim, a dark outline on the shadow side, and proper loop handles on the amphora.
- 2026-10-19: Intro cards. Same vase ground as the end card (`VaseBorder.draw_ground()`, now
  shared), and a black glaze band above the words that tells the story in nine clay oil lamps:
  card 1 the vigil burning with flickering flames; card 2 the lamps snuffed one by one from the
  right with curls of smoke, then Antares rising red; card 3 every lamp dark but the middle one,
  Cedalion's, with the three Belt Stars appearing over it. Lamps are drawn in 2× pixels. New
  autoshot timeline `intro`.
- 2026-10-19: Title screen recomposed. Orion's lines ran straight through the title, buttons and
  controls text. Now the menu sits in the left half, Orion draws himself large on the right, a
  faint Milky Way band crosses the sky, and the Star Citadel stands black along the bottom
  (walls, crenellated towers, cypresses, the temple on the summit) with vigil lamps flickering on
  the parapet; the controls line sits on the dark ground.
- 2026-10-19: Death card. A torch above the words gutters and goes out over ~0.9 s, then its
  ember fades and smoke curls away (drawn in 2× pixels on a layer above the card's backdrop); the
  line is 3× and the subtitle 2× (it was 1×). New autoshot timeline `death`.
- 2026-10-19: Braziers looked like orange jellyfish: the bronze bowl turned flat orange in its
  own light. The bowl is now dark bronze with a lit rim and glowing coals, and the fire is a
  separate unshaded `AnimatedSprite2D` (`Room._flame()`) cycling three hand-drawn frames
  (`brazier_flame_0..2`) at 9 fps, each brazier starting on a random frame. Stain slabs are
  smaller and paler, so two side by side no longer make a dark blob.
- 2026-10-19: Exit doors now spill a warm, slowly breathing light (as if lamps burn in the next
  room) with a few rising motes, so the way on reads from across a dark hall. The star shrine's
  sealed door stays dark until the Belt Star is taken.
- 2026-10-19: Knucklebone aim. G now aims while held and throws on release (a tap still throws
  at once). After 0.1 s of holding, an unshaded preview shows the dotted arc marching to the
  landing spot, a cross where it lands and a dashed ring of the 4-tile noise it will make, so
  you can see which guards will hear it. Throws no longer pass through walls: the bone drops just
  short of the first wall on its line (it still clears pots and columns; `Room.wall_ray_end()`). The colonnade hint and README say so.
  New autoshot timeline `aim`.
- 2026-10-19: The Lion Gate now has its gate: `lion_gate()` in `tools/gen_greybox.py` draws a
  lintel across the two-cell exit and the relieving triangle above it (two lions rampant either
  side of a column on an altar, in a dark frame), flat in the wall's plane and then sheared onto
  the wall's lit face. `Room._make_door()` places it in the lion-gate room only. At 480×270 the
  lions are an impression rather than a readable carving.
- 2026-10-19: Ambience. `tools/gen_audio.py` writes three 24 s room-tone loops to
  `audio/ambience/`: `night` (gusting wind and two crickets with their own pitch and rhythm that
  drift in and out), `cistern` (a low hum and irregular drips from a few spots, heavily
  reverberated), `indoor` (a low draught). They loop without a seam (noise crossfaded across the
  join, modulations in whole cycles, events wrapped). `Sfx.set_ambience()` crossfades between
  them; the title and the open-air rooms use night, the storerooms indoor, the cistern its own.
  Autoshot `idle` prints the audio state. Not listened to: levels set by numbers only.
- 2026-10-19: Noise rings in play. The GDD says "noise spreads as rings" (a v1 must-have), but
  rings only showed in the F3 overlay. Now every noise the player or the world makes draws a
  dotted iso ring that spreads to its real radius in 0.6 s and fades (`Fx.noise_ring()`, hooked
  up in `Room._show_noise()`): faint for walking (2 tiles), clear for running (5), strong for
  pots, clashes and knucklebones. Sneaking and fountain-masked steps make none, so their silence
  shows. Guards' own shouts are not drawn. New autoshot timeline `noise`.
- 2026-10-19: The living statue. The statue court's objective says "One of the stone men
  breathes" and the GDD describes a Hoplite hiding among the statues, but there was none. Now a
  guard entry can say `"statue": true`: he stands stone-coloured (a desaturating shader), lantern
  and cone dark, senses off, and only his breathing gives him away. He wakes when Cedalion comes
  within 2.6 tiles (alert at once), when a noise reaches him or another guard shouts (he goes to
  look), or when struck (so a sharp-eyed player can backstab him first); stone falls off as dust
  with a low crumble and the colour floods back over 0.45 s. The statue court has one, a
  Hoplite at (11, 4) beside the statue by the main stairs: the right-hand "trick" route passes
  within reach and wakes him, the quiet left-hand steps don't. Test: a statue guard ignores
  Cedalion in plain view 4 tiles away and wakes, alert, within reach. Autoshot timeline `statue`.
- 2026-10-19: Story props: the snuffed vigil. Up to three small clay oil lamps (`vigil_lamp`)
  sit at the foot of the back walls in every room, each with a thin curl of smoke
  (`Atmosphere.smoke()`, faint and unshaded so it shows in the dark), echoing the intro card
  where the Brotherhood puts the vigil out. Decorative only (no collision), placed by the room's
  seeded RNG on plain floor away from the entrance.
- 2026-10-19: Story props: the Brotherhood's mark. Up to two tall wall faces per room carry a red
  scorpion daubed over a scratched-out star fresco (`wall_scorpion`, drawn and sheared onto the
  lit face in `tools/gen_greybox.py`; mirrored in game for right faces), as the GDD's story-prop
  list asks. `Room._paint_scorpions()` picks faces the player can see with the seeded RNG.
- 2026-10-19: Danger on screen. The vignette's dithered edge now has a red twin
  (`Atmosphere.vignette_texture(true)`) that fades in as the most aware guard nears alert (from
  30% awareness, up to 35% opacity) and pulses slowly while a guard is hunting you, then lingers
  a little as it fades (`Room.set_danger()`, driven from `main._process` with the music tension).
- 2026-10-19: Taking the Belt Star is now a beat: a 0.12 s freeze, a blue-white light burst that
  swells and fades over a second, strong sparks and a ring, a camera shake and zoom punch, then
  the star (unshaded) lifts off the altar and flies into Cedalion's hands while time runs at 40%
  for 0.6 s (`Room._star_taken_fx()`). The escape starts as before. Autoshot timeline `star`.
  (Fix-up: the star beat's freeze and slow motion delay the first collapse by ~0.5 s of real
  time, so the play-through test now waits 3.2 s for the ring to start falling; the previous
  commit went in with that one test failing.)
- 2026-10-19: Sneaking looked the same as walking. Holding sneak now eases Cedalion into a
  crouch (14% shorter, 6% wider, `Life.crouch`), so the silent gait reads at a glance. Autoshot
  timeline `sneak`.
- 2026-10-19: During the star-shrine escape the collapsing slabs no longer each draw a noise
  ring (a dozen overlapping rings cluttered the run); single cracked slabs elsewhere still do.
- 2026-10-19: The pause menu has a Volume slider (the master bus, muted at zero) under
  Brightness, with the two labels aligned, for a loud hall or a quiet projector.
- 2026-10-19: The tree was a green blob on a stick; it is now an old olive: a twisting trunk on
  flared roots, three limbs, ragged clumps of foliage lit from the upper left with a few silver
  leaves and a dark outline on the shadow side, and a soft shadow on the ground.
- 2026-10-19: Steps show two treads (a bright nose and a darker riser each) on the lit face and
  a stepped edge on the shaded face, instead of blue stripes; the star altar has a stepped base,
  a gold band of stars and an overhanging top slab instead of a plain cube.
- 2026-10-19: Walls. Tall walls now show block masonry on both faces (courses with staggered
  vertical joints; the shaded face had none), and the ivy walls have ivy hanging in strands from
  a clump along the top (a wandering stem with leaves either side) instead of scattered dots.
- 2026-10-19: Wrote the morning summary and saved six fresh screenshots (title, Lion Gate,
  colonnade duel, the living statue waking, the Belt Star beat, the end card), replacing the
  first session's set. Usage at this point: 52% of the 5-hour window, 49% of the week.
- 2026-10-19: Behind walls. In the cistern Cedalion could walk behind the tall wall by Phineus
  and vanish completely. Now, while a wall drawn in front of him covers his body
  (`Room.wall_covers()`), a faint unshaded blue outline of him is drawn over everything (the
  player's `_ghost` sprite), the usual isometric fix. Checked in four rooms for false positives.
- 2026-10-19: Guards get the same treatment: a faint red outline while a wall hides them (not
  while posing as a statue or knocked out), so a guard behind a wall is never invisible.
- 2026-10-19: Stopped at 55% of the 5-hour window (49% of the week) after the silhouettes, to
  leave weekly usage for the hackathon. Nothing is half-done; next steps are in the summary.
