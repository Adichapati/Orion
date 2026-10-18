# ORION art

Palette, character templates and grey-box placeholders for ORION. The specs for every character (sizes, colour ramps, animation lists, silhouette rules) are in the design doc's **Characters** tab.

- `palette/orion.gpl` — the 31-colour palette plus 4 swap-key greys used only on armour layers.
- `templates/characters/*.aseprite` — one template per character: canvas, layers, animation tags per facing, guide and markers.
- `templates/iso-grid-480x270.aseprite` — the game screen with a 32×16 isometric grid.
- `placeholders/` — grey-box sprites (`*_se.png`, `*_ne.png`) and the size lineup. Not final art.
- `_scripts/make_art.lua` — regenerates everything above. Re-running overwrites `templates/` and `placeholders/`, so copy a template into a new folder (for example `characters/`) before drawing in it.

Layers starting with `_` are guides and are never exported (Aseprite Wizard exclude pattern: `^_`). Tags are named `animation_facing`, for example `walk_se`.

Regenerate:

    C:/aseprite/build/bin/aseprite.exe -b --script-param root=C:/Users/adith/Documents/Study/Coding/Orion/art --script C:/Users/adith/Documents/Study/Coding/Orion/art/_scripts/make_art.lua
