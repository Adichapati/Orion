# Notes for agent 2

What the first agent (Claude, on Sathvik's machine) changed on `v1-prototype`, so you can pull
and build on it without redoing or undoing it. Read `CLAUDE.md` and the "Demo day" log at the top
of `docs/dev/POLISH.md` for the full story.

## HANDOFF (2026-10-22, 15:55 IST): read this first

The first agent's usage ran out at 15:55, so you are taking over. The demo is due at **17:00 IST**.
The stable fallback is the tag `demo-checkpoint-1`.

### `v1-prototype`

Pushed to GitHub (`Adichapati/Orion`), 243 tests pass. Every change below is committed and
pushed. Sathvik wants every stable build (all tests passing) pushed, and this file kept up to date.

### Three design agents were still running, in git worktrees on Sathvik's machine

They started at about 15:40 with a hard stop at 16:25. Their full briefs, with every design
decision already made, are in `docs/dev/design-briefs-2026-10-22.js` (the TITLE, PROPS and ARMOUR
strings).

Each branch starts at `79aa53c`, so it doesn't yet have `c0b27f0` (going back) or `fd86ff1` (move
tints). The branches are local only, in `C:/Users/sathv/orion`; they are not on GitHub until
someone merges and pushes them. Screenshots are in `C:/Users/sathv/orion/.shots/design_title/`,
`design_props/` and `design_armour/` (git-ignored).

1. **Start screen.** Branch `worktree-wf_30aa9921-db2-1`, worktree `.claude/worktrees/wf_30aa9921-db2-1`.
   - The job: one main floating island close to the viewer (temple ruin, brazier, waterfall) and
     two smaller ones behind it, over a sea of clouds, at night, with Orion visible. Sathvik's
     reference 6 is the idea only. The work is in `tools/gen_title.py` (new),
     `art/greybox/title_*.png` and `scripts/ui/title_screen.gd`.
   - Committed by 15:55: `50cbfcd` Make the title a night of floating islands over the clouds;
     `f170197` Polish the title islands: clouds, olives, embers.
   - Uncommitted at 15:55: `scripts/ui/title_screen.gd`.
2. **Ruin props and materials.** Branch `worktree-wf_30aa9921-db2-2`, worktree `.claude/worktrees/wf_30aa9921-db2-2`.
   - The job: props after references 2, 3, 4 and 7 (`ruin_arch`, `nike_statue`, `amphora_plinth`,
     `column_snapped`, `fallen_drums`), moss and grass decals, and `vines_hang`.
   - They are drawn at the end of `tools/gen_greybox.py` and placed by `Room.DECOR` /
     `_place_decor()`. Looks only; the tall props fade when Cedalion is behind them.
   - No broken walls: Sathvik wants cracks.
   - Committed by 15:55: `aa7718a` Dress the rooms with mossy ruins, a winged Nike and hanging
     vines; `f2f36c0` Brighten the floor moss and clear the Nike's face; `3cd3ae5` Keep vines off
     the Brotherhood marks and test the ruins fade.
   - Uncommitted at 15:55: `scripts/world/room.gd`.
3. **Armour and weapons.** Branch `worktree-wf_30aa9921-db2-3`, worktree `.claude/worktrees/wf_30aa9921-db2-3`.
   - Sathvik's sheet, saved as `art/generated/cedalion_armour_sheet.webp`, has 3 armours x 3
     weapons. Weapons stay separate sprites, drawn on the hand point: `labrys` (axe) and `koryne`
     (mace), plus a new `data/armour/mail.tres`.
   - Looks: tunic = no armour, linothorax = leather, mail = chainmail, cuirass = plate.
   - The no-armour sheet Sathvik asked for is `art/generated/cedalion_tunic_weapons_sheet.png`
     (`tools/compose_weapon_sheet.py`).
   - The player loads `cedalion_<look>` for the equipped armour and falls back to `cedalion`.
   - Committed by 15:55: `233dcd1` Add the bronze labrys, the iron koryne and an iron mail shirt;
     `d7d5c70` Compose the no-armour sheet: Cedalion's tunic with each weapon; `8243376` Give each
     armour its own body sheet, falling back to the tunic.
   - Uncommitted at 15:55: `tools/process_sheet.py`, `tests/test_suite.gd`, `scripts/dev/autoshot.gd`,
     and new `art/final/cedalion_{leather,mail,plate}_sheet.*`: the armour bodies themselves (step 3
     of its brief), possibly half done.

**How to finish them** (on Sathvik's machine, in `C:/Users/sathv/orion`):
1. For each worktree, check whether its agent finished: `git -C .claude/worktrees/<name> log --oneline -5`
   and `git -C .claude/worktrees/<name> status`.
2. Look at any uncommitted diff, run `--import` twice in that worktree, then run the tests. Commit
   if they pass; `git restore` and clean it if not. The armour bodies may be half done: if their
   tests fail, keep commits `233dcd1` and `d7d5c70` (weapons plus the no-armour sheet) and drop
   the rest.
3. Merge into `v1-prototype` one at a time: props, then title, then armour (`git merge <branch>`).
4. After each merge:
   - Run `--import` twice, then the full test suite.
   - Take screenshots: `--script=title`; `idle`, `walk` and `vista` in every room; `moves` in
     `lion-gate`.
   - Add a dated entry to `docs/dev/POLISH.md`, update this file, commit and push.
5. Remove the worktrees: `git worktree unlock <path>`, then `git worktree remove --force <path>`.
6. Show Sathvik the screenshots and ask for feedback; he asked for feedback from time to time.

Expected merge conflicts, easy to resolve:
- `tests/test_suite.gd`: each agent added one registration line just before
  `await test_playthrough()` in `run()`, and its test functions at the end of the file. Keep them all.
- `scripts/world/room.gd`: props adds `DECOR` / `_place_decor()` next to `CLUTTER`; main changed
  the door code.
- `autoload/game.gd`: armour adds to the item lists; main added `room_state`.
- `scripts/actors/player.gd`: armour adds the sheet per armour; main changed the tints in
  `_update_visuals` and `take_hit`.

### Still open after that

- **Item 2 of `CLAUDE.md`, chest art and Alcyone:** waiting on Adithya's images as
  `art/generated/chest_sheet.png` and `art/generated/alcyone_sheet.png`, and on where Alcyone
  appears (suggested: chained by the star shrine's altar). Asked, no answer yet.
- **Nits from a screenshot tour:**
  - In the cistern's `walk_walked2` shot the hero shows as a faint ghost behind a column and a
    wall corner.
  - In the statue court's vista a tree and the front corner hide the hero.
  - The Hoplite's name and HP label is tiny on a projector.
- **Mock-ups:** the Aseprite mock-ups in `art/maps/*` are not rebuilt, because there's no
  Aseprite on this machine. `rooms.json` changed: the cistern dais is now `H`.

### Rules Sathvik set for this work

- Keep every test passing, and add a test for each bug you fix.
- Commit after each working piece, adding files by path.
- Never commit `art/characters/`, `docs/proposal/` or `.shots/`.
- Push stable builds, and keep this file updated.
- Ask before anything that risks the build near the deadline.
- Use cheaper subagents (Sonnet or Haiku) for mechanical work like screenshot tours, and keep
  design decisions with the main model. Ultracode workflows are fine for design work.

## How this machine runs things

- Godot 4.7.2 (winget, no `godot` alias):
  `C:\Users\sathv\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`
- Tests: `timeout 300 "$G" --headless --path . --script res://tests/run_tests.gd`. A GDScript
  parse error makes the suite hang instead of fail: find it with `tests/check_scripts.gd`. In
  GDScript, `var t := <untyped expr>` is a parse error; type it.
- Python 3.14 with Pillow 13, NumPy and SciPy. `tools/gen_greybox.py` redraws seven older files a
  pixel off on this Python and Pillow: `floor_coping_e/s`, `floor_key_e`, `jar`, `mark_question`,
  `shards`, `water_shade_e`. They are never committed from here (`git checkout --` them). New art
  goes at the end of a generator, with its own `random.Random`, so older output stays byte-identical.

## Changes so far (2026-10-22), all on `v1-prototype`

1. `0c914e1` Cedalion's dodge roll, block and get-hit, from `art/generated/cedalion_sheet_v2.jpg`.
   - `tools/process_sheet.py`: a config can take extra sheets (`more`), each with its own boxes,
     sword lines, painted arcs (removed), scale and background test (`is_paper_jpg` for the JPEG).
     The palette still comes from the first sheet only.
   - Tags: `dodge_*` are three tucked roll frames with no sword hand; `parry_*` is the braced
     block; `hurt_*` is the flinch.
   - `scripts/actors/player.gd`: the dodge plays its clip by progress over `DODGE_TIME`; `S.HURT`
     shows `hurt`. A frame without a sword hand, on a sheet that has hands, hides the sword
     (`_frame_hides_sword`, `SheetAnim.has_hands()`).
   - `scripts/dev/autoshot.gd`: `--script=moves`.
2. `7a6719a` and `5ee0ed4` Environment.
   - `Room.MEDALLIONS` takes `[cell, texture]`: a Vergina sun in the statue court at (7, 11) and a
     star mosaic (`floor_medallion_star`) in the star shrine at (6, 10).
   - Cracked back walls: `wall_tall_cracked`, `Room.CRACKED_WALLS`. Sathvik asked for cracks, not
     broken walls; the broken variant was removed.
   - Storeroom clutter, looks only: `Room.CLUTTER` (sacks, crates, rope, `floor_grain`).
3. `283d824` and `6cf5dbc` Facing and the sky.
   - Facing: the artist drew the front poses facing different ways. `idle_f` and `walk_f0` look
     left; `idle_f2` and `walk_f1` to `walk_f3` look right. Nothing is mirrored.
     - The walk is `walk_f2, walk_f1, walk_f3, walk_f1`.
     - `idle_se` is `idle_f2`, and `look_se` (the glance back) is `idle_f`.
     - `FACES` in `tools/process_sheet.py` records each pose's facing; the JSON carries it per
       frame (`"faces"`) and a test checks it.
   - Sky: `Atmosphere.skyline()`, `skyline_span()` and `unpeek()`.
     - Far islands that would rest on the back walls lift clear or sink behind them.
     - Orion moves to the nearest open sky, and shrinks to 80% when it's tight.
     - `NightSky.room` and `FarSky.room` are set in `dress()`.
4. `79aa53c` Phineus's dais: new tile `H` in `art/maps/rooms.json`, raised floor that is solid. The
   cistern's raised floor is `H` except the landing (2, 3) at the top of the step.
5. `c0b27f0` Going back.
   - From the second room on, the entrance `E` offers "Go back" (hold 0.45 s).
   - Code: `Room.back_reached`, `Room.exit_cell()`, `main._on_back_reached()`, and
     `load_room(index, arrive, back)`.
   - `Game.room_state` (with `remember()` / `remembered()`, saved in the snapshot) keeps smashed
     pots and opened chests used up for the run.
6. `fd86ff1` Readable moves: dodge alpha 0.85, parry glint (1.15, 1.15, 1.3), hurt tint
   (1, 0.75, 0.72) after the red flash.
7. `scripts/dev/autoshot.gd` timelines: `moves`, `turns` (walk four ways, traced), `ledge` (cistern
   dais probe), `ruins`. The `info` call prints the cell, its tile and the elevation.

## Tests

243 pass. New today:
- `test_cedalion_faces_where_he_walks`
- `test_cedalion_moves`
- `test_medallions_on_plain_floor` (also covers the cracked walls and the clutter)
- `test_phineus_dais`
- `test_go_back`
- `test_sky_clears_walls`
