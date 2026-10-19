# ORION

A small prince carries the last flame through a dark temple-citadel. Every light that shows him the way also gives him away. He has until Orion sets.

ORION is an isometric pixel-art game of stealth and sword duels set in mythic Greece, inspired by the feel of Prince of Persia and planned for a hackathon. It's built in Godot 4.7. A playable v1 prototype with grey-box art is on the `v1-prototype` branch. v1, the hackathon demo, leaves the light system, the Ember and a fighting princess for v2.

## Design

- [Game Design Document](docs/GDD.md) — **Greek setting**, chosen on 2026-10-18. A Markdown snapshot of the live Claude Doc, exported on 2026-10-18. The live doc is the one to edit: <https://claude.ai/artifact/4Xhq62KoBu8QuQ9hXjkRGg> (ask Adithya for access).
- [Tools and assets](docs/TOOLS.md) — the free tool pipeline, AI-tool prices and free asset sources, from the live doc's second tab.
- The earlier Persian-setting version is archived on the `persian-setting` branch. Compare the two with `git diff persian-setting main -- docs/GDD.md`.

## Diagrams

| Castle map | Guard awareness | Build roadmap |
| --- | --- | --- |
| [![Castle map](docs/images/castle-map.png)](docs/images/castle-map.png) | [![Guard awareness](docs/images/guard-awareness.png)](docs/images/guard-awareness.png) | [![Build roadmap](docs/images/build-roadmap.png)](docs/images/build-roadmap.png) |

## Running the prototype

You need Godot 4.7 (standard build, not .NET). Open `project.godot` in the editor and press F5, or run from a terminal:

    godot --path .

The game starts on the title screen. To jump straight into a room, pass its id or index after `--`:

    godot --path . -- --room=statue-court

### Controls

| Action | Keyboard and mouse | Gamepad |
| --- | --- | --- |
| Move | WASD or arrow keys | Left stick |
| Run / sneak | Hold Ctrl / hold Shift | Click left stick / hold LT |
| Jump (2 tiles along a grid axis) | Space | A |
| Dodge | C | B |
| Attack / parry | J or left click / K or right click | X / RB |
| Shove | F | LB |
| Torch thrust (stun) | Q | RT |
| Toss a knucklebone: hold to aim (arc and hearing ring), release to throw (toward the mouse if it moved) | G | — |
| Interact (hold for chests) | E | Y |
| Eat a pomegranate | H | D-pad up |
| Pause (controls, brightness, restart) | Esc | Start |
| Fullscreen / debug overlay | F11 / F3 | — |

A white glint means an attack can be parried; a red glint means dodge it.

### Swapping in real art

All textures load by name through `scripts/core/art.gd`, which looks in three folders in order:

1. `art/final/` — drop finished art here
2. `art/placeholders/` — the character placeholders
3. `art/greybox/` — generated tiles and props (`python tools/gen_greybox.py` rebuilds them)

To replace something, save a PNG with the same file name into `art/final/` (for example `art/final/column.png` or `art/final/cedalion_se.png`) and keep the same size and pivot: characters and props stand on their bottom-centre pixel, blocks have their 32×16 ground diamond at the bottom, and flat tiles are 32×16. No code changes needed.

### Animations

Cedalion animates from `art/final/cedalion_sheet.png` and `cedalion_sheet.json`, in Aseprite's sprite-sheet export format (File > Export Sprite Sheet, with JSON data and tags). Tags are named `<animation>_<facing>`: `idle`, `look`, `walk`, `attack`, `parry`, `lunge`, `jump` and `dodge`, each as `_se` (front) and `_ne` (back); the game mirrors them for the other two facings, and plays `walk` faster when he runs and slower when he sneaks. An optional per-frame `"torch": {"x", "y"}` (relative to the feet) moves the torch light with the flame. Export a new sheet with the same name and tags to replace the animations; if there is no sheet, the stills are used. The current sheet is built from the hand-made sheet in `art/generated/cedalion_friend_sheet.webp` by `python tools/process_cedalion_sheet.py`. Re-running it overwrites the sheet, so don't run it once a real Aseprite export is in place.

Sounds work the same way: `audio/sfx/<name>.wav` and `audio/music/explore.wav` / `tension.wav`. `python tools/gen_audio.py` regenerates the placeholders; overwrite any file with a real recording of the same name.

### How rooms.json drives the levels

Every room is built at run time from `art/maps/rooms.json`, so editing that file changes the game and the mock-ups together. Each room has:

- `grid` — one character per tile; x grows to the right (east), y downwards (south). The legend is in the file's `tiles` section: `#` wall, `L` wall lamp, `.` floor, `x` cracked marble, `h` raised floor, `^` steps, `_` pit, `W` deep water, `p` stepping stone, `o` column, `S` statue, `J` jar, `a` amphora, `C` chest, `F` fountain, `P` Phineus, `A` the Belt Star altar, `*` Alcyone's mark, `E` entrance, `D` exit door, and so on.
- `player` — the entrance cell; Cedalion starts one tile inside it.
- `guards` — `{id, type, at, face, path}`: type is `watchman`, `spearman` or `hoplite` (stats in `data/guards/*.tres`), `path` is the list of patrol cells (one cell means he stands and looks around).

The room order in the file is the play order. After editing, run the tests (below): they check that every room builds, guards can reach their waypoints and the exit is reachable.

### Tests and checks

    godot --headless --path . --import
    godot --headless --path . --script res://tests/run_tests.gd

The suite builds every room, checks reachability, guard sight, hearing, cracked marble, shoves, a parry duel, the shop, and a full play-through of the main scene. For screenshots without playing, see `scripts/dev/autoshot.gd`. The code layout is described in [docs/dev/ARCHITECTURE.md](docs/dev/ARCHITECTURE.md), and the build log is [docs/dev/PROGRESS.md](docs/dev/PROGRESS.md).

## Status

v1 prototype playable end to end, with AI-generated character sprites over grey-box rooms, generated sounds and an overnight polish pass (game feel, night sky, pixel font, hints); see [docs/dev/POLISH.md](docs/dev/POLISH.md). Next: play-testing and tuning.
