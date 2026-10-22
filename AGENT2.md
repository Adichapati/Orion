# Notes for agent 2

What the other agent (Claude, on Sathvik's machine) changed on `v1-prototype`, so you can pull
and build on it without redoing or undoing it. Newest last. Read `CLAUDE.md` and the
"Demo day" log at the top of `docs/dev/POLISH.md` for the full story. Every push here is a
stable build: all tests pass.

## How this machine runs things

- Godot 4.7.2 (winget, no `godot` alias):
  `C:\Users\sathv\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`
- Python 3.14 with Pillow 13, NumPy, SciPy. `tools/gen_greybox.py` redraws seven older files a
  pixel off on this Python/Pillow (`floor_coping_e/s`, `floor_key_e`, `jar`, `mark_question`,
  `shards`, `water_shade_e`); they are never committed from here. New art goes at the end of a
  generator with its own `random.Random`, so older output stays byte-identical.

## Changes so far (2026-10-22)

1. `0c914e1` Cedalion's dodge roll, block and get-hit from `art/generated/cedalion_sheet_v2.jpg`.
   - `tools/process_sheet.py`: a config can take extra sheets (`more`), each with its own boxes,
     sword lines, painted arcs (removed), scale and background test (`is_paper_jpg` for the JPEG).
     The palette still comes from the first sheet only.
   - Tags: `dodge_*` = three tucked roll frames with no sword hand; `parry_*` = the braced block;
     `hurt_*` = the flinch.
   - `scripts/actors/player.gd`: the dodge plays its clip by progress over `DODGE_TIME`; `S.HURT`
     shows `hurt`; a frame without a sword hand (on a sheet that has hands) hides the sword
     (`_frame_hides_sword`, `SheetAnim.has_hands()`).
   - `scripts/dev/autoshot.gd`: `--script=moves` shoots the roll, block and get-hit.
2. `7a6719a` + `5ee0ed4` Environment.
   - `Room.MEDALLIONS` now takes `[cell, texture]`: a Vergina sun in the statue court at (7, 11)
     and a new star mosaic (`floor_medallion_star`) in the star shrine at (6, 10).
   - Cracked back walls (`wall_tall_cracked`, `Room.CRACKED_WALLS`). Sathvik asked for cracks,
     not broken walls; the broken variant was removed.
   - Storeroom clutter, looks only, no collision (`Room.CLUTTER`: sacks, crates, rope,
     `floor_grain`).
3. This push: two fixes.
   - Facing bug: the artist drew the front poses facing different ways. `idle_f` and `walk_f0`
     look left; `idle_f2` and `walk_f1`-`walk_f3` look right. Nothing is mirrored now. The walk is
     `walk_f2, walk_f1, walk_f3, walk_f1`; `idle_se` is `idle_f2` and `look_se` (the glance back)
     is `idle_f`. `FACES` in `tools/process_sheet.py` records each pose's facing and the JSON
     carries it per frame ("faces"), so the test catches a left-facing frame in any clip but `look`.
   - Sky: `Atmosphere.skyline()` / `skyline_span()` / `unpeek()`. Far islands that would rest on
     the back walls lift clear or sink behind them; Orion moves to the nearest open sky and
     shrinks to 80% when it's tight. `NightSky.room` / `FarSky.room` are set in `dress()`.
   - Tests: `test_cedalion_faces_where_he_walks`, `test_sky_clears_walls`.

4. `Phineus's dais`: new tile `H` in `art/maps/rooms.json` = raised dais, drawn like `h` but
   solid (`Room._build_floor`, `_build_solid`, `_prop_elevated`, `elevation_px`). The cistern's
   raised floor is `H` except the landing (2, 3) at the top of the step. Test `test_phineus_dais`.
5. `scripts/dev/autoshot.gd`: `--script=turns` (walk four ways, traced) and `--script=ledge`
   (cistern dais probe); the `info` call prints the cell, its tile and the elevation.

## Tests

234 pass (`tests/run_tests.gd`). New tests: `test_cedalion_moves`,
`test_cedalion_faces_where_he_walks`, `test_medallions_on_plain_floor` (also covers cracked walls
and clutter), `test_sky_clears_walls`.

## In progress here next (avoid these files for now, or tell Sathvik)

- Going back through a room's entrance door with E (`scripts/main.gd`, `scripts/world/room.gd`,
  `autoload/game.gd`).
- Title screen as floating platforms (`scripts/ui/title_screen.gd`, a new generator in `tools/`).
- Ruin props from Sathvik's references: arches, fallen columns, a winged statue, moss and vines.
- Armour and weapon sets from Sathvik's sheet (leather, chainmail, plate × mace, axe, sword), plus a
  no-armour set.
