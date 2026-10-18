# ORION v1 — code architecture

A short map of the prototype's code. Everything is built in code: the only scene is
`scenes/main.tscn`, and rooms come from `art/maps/rooms.json`.

## Spaces and rendering

- The world renders into a **480×270 SubViewport** (`Main/WorldContainer/WorldViewport`), shown at
  2× with nearest filtering. All UI lives on the `UI` CanvasLayer in **960×540** space.
  `main.world_to_ui(p)` maps a room point to the UI (`canvas_transform * p * 2`).
- `scripts/core/iso.gd` converts between **grid** space (float tiles; every range, angle and
  speed in the game is in tiles) and **screen** space (pixels; cell (x, y) is centred at
  `((x − y)·16, (x + y)·8)`).
- Depth: floors sit on a layer at z −100, vision cones at z −60, and everything that stands
  (walls, props, actors, pickups) is in the y-sorted `Room.world` node, with each sprite's origin
  at its feet. Raised floor lifts actors by `Room.elevation_px(cell)`.
- Darkness is a `CanvasModulate` per room (scaled by `Game.brightness`); light comes from
  `PointLight2D`s: Cedalion's torch, wall lamps, braziers, moonlight pools, guard lanterns
  (a cone texture in a pivot squashed to (1, 0.5)) and sparks.

## Autoloads

| Autoload | Job |
| --- | --- |
| `Controls` | Registers every input action in code (keyboard, mouse, gamepad); F11 fullscreen |
| `Game` | Run state: rooms and data, obols, health, gear and the shop, checkpoint snapshots, the one-attacker-at-a-time token, stats and Dawn Rank, debug and brightness settings |
| `NoiseBus` | `emit_noise(pos, radius_tiles, source)`; guards listen to its `noise` signal |
| `Sfx` | Plays `audio/sfx/<name>.wav` with distance falloff; runs the two music layers and mixes them by tension |

## Main flow (`scripts/main.gd`)

Title → intro cards → `load_room(i)` → exit → snapshot → next room … → end card.
`load_room` builds a `Room`, calls `spawn_guards()`, adds the `Player`, sets camera limits, wires
`exit_reached`, `message("shop")` and `player.died`, and adds the F3 `DebugOverlay`. Death shows a
`MessageCard`, restores the entry snapshot and rebuilds the room. Esc opens `PauseMenu` (the tree
pauses; UI nodes run with `PROCESS_MODE_ALWAYS`). User args after `--`: `--room=`, `--debug`,
`--shots=` + `--script=` (see `scripts/dev/autoshot.gd`).

## World (`scripts/world/`)

- `room.gd` builds tiles, walls, props, collisions (layer 1 solid, 2 hazard, 3 ledge, 4 actor),
  lights, doors, marks, Phineus and the altar from the grid; owns the AStar2D graph, line of sight,
  cracked marble timing and collapse, fountain noise masking, column fading, checkpoints and the
  star-shrine escape (taking the star unseals the door and drops the cracked ring in a wave).
- `interactable.gd` is the two-range prompt (glyph at 5 tiles, "E — verb" within reach, optional
  hold time). `breakable.gd` (pots), `chest.gd` and `pickup.gd` (obols, the dropped sword) use it.

## Actors (`scripts/actors/`)

- `player.gd` — a state machine (normal, attack, parry, dodge, jump, hurt, shove, thrust, fall,
  dead, locked). Footsteps emit noise by gait and armour. Attacks hit the nearest guard in an arc;
  backstabs, ripostes and shields are resolved here.
- `guard.gd` — patrol, suspicious, alert, search, return, stunned, shoved, falling, KO. Sight is a
  cone plus a raycast; awareness rises with closeness and decays; noises and other guards' shouts
  make him investigate. In a fight he takes the attack token, winds up behind a glint, strikes,
  recovers; the others circle. All numbers come from a `GuardType` resource.
- `knucklebone.gd` — a thrown lure that makes a 4-tile noise where it lands.

## Data (`scripts/data/`, `data/`)

`WeaponData`, `ArmourData`, `AttackData` and `GuardType` resources. Balance changes go in the
`.tres` files, not the code.

## UI (`scripts/ui/`)

`UiKit` holds the shared style. `Hud`, `ShopPanel`, `TitleScreen`, `IntroCards`, `PauseMenu`,
`MessageCard`, `EndCard`, `DebugOverlay` and `VaseBorder` are plain scripts that build their own
controls.

## Tests and tools

- `tests/run_tests.gd` loads `tests/test_suite.gd` (the entry script of `--script` can't see the
  autoloads when it compiles). `tests/check_scripts.gd` just loads every script.
- `tools/gen_greybox.py` and `tools/gen_audio.py` regenerate the placeholder art and sounds.
- `tools/process_generated.py` turns the AI-generated sheets in `art/generated/` into
  `art/final/` sprites; `tools/gen_font.py` writes the pixel font in `art/fonts/`.

## Polish layer (see docs/dev/POLISH.md)

- `scripts/core/shake_camera.gd` — the player's camera: `ShakeCamera.add_trauma()`,
  `ShakeCamera.punch()`, look-ahead.
- `scripts/core/juice.gd` — `Juice.freeze()` (hit-stop), `Juice.slowmo()`, `Juice.flash()`.
- `scripts/core/life.gd` — procedural walk bob, squash and stretch and blob shadow for actors.
- `scripts/world/atmosphere.gd` — sky with Orion, vignette, embers, moon motes, water shader;
  `Room.build()` calls `Atmosphere.dress()`.
- `Hud.ROOMS` holds each room's objective line and first-visit hints.
