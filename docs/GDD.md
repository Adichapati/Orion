# ORION — Game Design Document (Persian, archived)

Oct 17, 2026 · @Adithya Raj

**Archived on 18 Oct 2026.** The team chose the Greek setting, so this doc is kept for reference only. The current design is [ORION — Game Design Document (Greek)](https://claude.ai/artifact/4Xhq62KoBu8QuQ9hXjkRGg).

ORION keeps the heart of the idea — a small prince, a dark ruined castle, a torch as the only light — and makes that torch the whole game: light lets you see, but it also lets them see you. Build a polished 10–15 minute slice in Godot 4 for the hackathon, then grow it act by act.

## What changes from the original idea

Most of the idea stays. The torch is its best part, so it becomes the centre of the design. The changes swap stat upgrades and generic beats for choices that make players think.

| Original idea | Verdict | What ORION does |
| --- | --- | --- |
| Small prince saves a princess from a castle at night | Keep, add a twist | The princess is a warrior who breaks out herself and races you to the tower. You have the light; she has the strength. |
| Prince of Persia theme | Keep as inspiration only | Borrow its measured movement, duels and traps. Build a new world from Persian architecture and the Orion myth. |
| Pixel art, isometric view | Keep | 2:1 isometric at 480×270, scaled ×4 to 1080p. Draw two facings per sprite and mirror the other two. |
| Torch is the only light inside | Keep — make it the core | Light cuts both ways: it shows you the room and shows you to the guards. You control its size, its fuel and where it sits. |
| 30–40 px light radius | Change | Too tight to see attacks coming, which feels unfair rather than hard. Use three sizes: 48 px shrouded, 96 px normal, 144 px raised. |
| Start unarmed, take a guard's sword and armour | Keep | The Gate is an unarmed stealth tutorial. Knock out a Watchman to take his scimitar and his tunic, which works as a disguise. |
| Message icon from afar, "Enter" up close | Keep, make it a system | Every interactable uses the same two-range prompt: a glyph at 5 tiles, a button prompt at 1 tile. |
| Coins in vases, chests and from guards | Keep, add risk | Smashing a vase is loud. Greed versus stealth becomes a real choice. |
| Three guard tiers, each with its own style and outfit | Keep, sharpen | Each tier asks one question with one answer: parry, sidestep, or flank and stun. You can tell them apart by silhouette and by the light they carry. |
| Cracked floor tiles | Keep, make them react | Tiles give way under weight: yours, a heavy guard's, or gold armour's. They become traps and shortcuts. |
| Vines from broken glass windows | Keep, give them a job | Vines are climbing routes that lead toward the sky. Burn them to cut a route off. |
| Merchant sells bronze, silver, gold swords and armour | Change | Good-better-best has one right answer. Make the three tiers sidegrades with weight, noise and shine costs. |
| Godot, Unity or Android Studio; prototype in a Google playground | Change | Use Godot 4 for everything, including the prototype. Android Studio is an app IDE, not a game engine. |

## Pitch and pillars

**Pitch:** A small prince carries the last flame into a dark citadel. Every light that shows him the way also gives him away. He has until Orion sets.

Four pillars decide every feature. If a feature serves none of them, cut it.

1. **Light cuts both ways.** Light lets you see, and it lets them see you. Every light in the game is both a tool and a risk.
2. **Every fight is a puzzle.** Attacks are telegraphed clearly. Each enemy type has a counter, and the room itself is a weapon.
3. **Measured movement.** This is the Prince of Persia DNA: fixed jump lengths, ledges and crumbling floors. Every move is a commitment.
4. **Small prince, sharp mind.** He wins through choices, not stats. Gear, routes and greed all cost something.

### Staying clear of Prince of Persia

Prince of Persia is a reference for feel, not a template. Never use its name, logo, characters, music, sprites or the Sands of Time. Mechanics can't be copyrighted, but each borrowed one gets a new form here.

| Prince of Persia | ORION's version |
| --- | --- |
| A princess waits in a tower | Bellatrix breaks out herself and races you to the top |
| A 60-minute real-time limit (1989) | The sky is the clock: Orion sinks past the windows as the night goes on |
| Rewinding time with the Sands of Time | The Ember: drop your flame, call it back, step to it |
| Loose floor tiles | Cracked tiles that react to weight — yours, your armour's, a heavy guard's |
| Side-view sword duels | Duels you read through light: a white glint means parry, a red glint means dodge |
| Side-scrolling platforming | Isometric measured movement: fixed jumps, ledges, vines |
| An evil vizier | Antares and the Scorpion clan — no vizier |
| Health potions | Pomegranates to heal; health shown as stars |

## Story and world

On the longest night of the year, the Scorpion clan takes the Star Citadel. Rigel, the smallest prince, must carry the last royal flame up the observatory tower before Orion sets.

### Premise

- Antares and the Scorpion clan storm the Star Citadel at dusk. They snuff every flame and drag Princess Bellatrix to the observatory tower.
- Rigel escapes with **the Ember**, the royal flame that has burned in the citadel shrine for 300 years. It is now the only fire inside the walls.
- The Scorpion army arrives at dawn. Only the Hunter's Lamp on top of the tower can call the king's riders in time, and only the royal flame can light it.
- On the longest night, Orion rules the sky until dawn. It sets in the west as Antares, the Scorpion's red heart, rises in the east. In the myth the hunter and the scorpion never share the sky. That is the game's clock: **you have until Orion sets.**

### Characters

| Character | Name meaning | Role | Look |
| --- | --- | --- | --- |
| Rigel | Arabic *rijl*, "foot" — the star at Orion's foot | Player. Youngest prince, never trained to fight. Wins with wits. | 16×24 px, oversized turban, torch in his left hand |
| Bellatrix | Latin, "female warrior" — Orion's shoulder star | The princess and the citadel's best sword. Breaks out in Act I and fights her way up. | 18×30 px, lapis and white, twin blades |
| Antares | Greek, "rival of Ares" — the red heart of Scorpius | Villain. Leads the Scorpion clan and wants the citadel dark when his army arrives. | 40×48 px, crimson armour, chain-blade "tail" |
| Kasib | Arabic, "one who earns" | The merchant. A blind oil-seller who trades with anyone. He doesn't need light to count coins. | 20×24 px, seated at a stall with no lamp |
| Scorpion clan | — | The guards: Watchmen, Lancers, Sentinels | A crimson sash on every uniform |

### The twist

Bellatrix isn't waiting to be saved. She escapes her cell in Act I and fights upward to light the Lamp herself, but she has no flame. You follow her trail of knocked-out guards and chalk star-marks; the marks also point to secrets.

In the finale Antares corners her at the Lamp. You bring the light and she brings the sword. The theme in one line: strength without light is blind, and light without strength gets snuffed out.

### Ending

Rigel lights the Hunter's Lamp as Orion touches the horizon. Dawn breaks, and for the first time the whole citadel is visible in daylight. Players see how much they crossed in the dark — a big payoff from one colour tween.

### How the story is told

- A 20-second intro: the Orion constellation draws itself while three lines of text set the stakes.
- No walls of dialogue. Kasib speaks in short lines; guards bark one or two words.
- The world tells the rest: snuffed lamps still smoking, torn star charts, toppled astrolabes, scorpion marks in red ochre, Bellatrix's chalk stars.
- Orion is visible through a window in every act, a little lower each time.

### World and culture

- A Persian-inspired desert citadel built around an observatory. Visual references: the mud-brick walls of Arg-e Bam, Isfahan tilework (eight-point star tiles, honeycomb muqarnas vaults, iwan arches) and medieval observatories such as Maragheh.
- Many star names come from Arabic and Persian astronomy, such as al-Sufi's *Book of Fixed Stars* (964 CE). That gives the world a real backbone.
- Heroes and villains come from the same world. The Scorpion clan is a faction, not a culture, so avoid "exotic villain" clichés.
- Working Persian name: *Dezh-e Setāregān*, "Fortress of the Stars". Check it with a native speaker before it goes on screen.

## The castle map

![Castle map: the castle laid out as the Orion constellation](images/castle-map.png)

You start at Rigel, Orion's foot, and finish at Meissa, his head. Act III offers two ways up — the quiet tower climb or the loud barracks — so your loadout decides the route.

## Core mechanics

Five systems carry the game, and all of them run through light: how lit you are, where your flame is, how loud you are, how you move, and what you can touch.

### Light and visibility

Your torch has three sizes. Bigger light shows more of the room and makes you visible from further away.

| Torch state | Radius | Fuel burn | Guards spot you from | Use it for |
| --- | --- | --- | --- | --- |
| Shrouded (hold Shift) | 48 px (1.5 tiles) | 0.6× | Close range only | Sneaking past |
| Normal | 96 px (3 tiles) | 1× | Medium range | Exploring |
| Raised (hold R) | 144 px (4.5 tiles) | 1.6× | Far away | Scouting a room, spotting traps |
| Out of fuel | 24 px | — | Almost never | Limping to the next oil jar |

- **Fuel.** A full torch lasts about 4 minutes at normal size. Refill from oil jars, by standing near a lit sconce, or with an oil flask. Perfect parries throw sparks that add 10%. An empty torch never kills you, but it shrinks to an ember and disables the Ember powers.
- **Sconces paint the light map.** Wall sconces start snuffed. Light one and the area is lit and your progress is saved, but guards can now see you there too. Snuff sconces to make dark paths. Guards notice a sconce changing and come to look, so a sconce is also a lure.
- **Moonlight.** Broken windows throw cool pools of patterned light. Guards see you in them, and they're where vines grow.
- **Alarm braziers.** An alerted guard runs to the nearest alarm brazier. If he lights it, the whole room lights up. Stop him on the way, or snuff it afterwards.

### The Ember

The Ember is ORION's signature mechanic and its answer to rewinding time. Your flame can leave your hand.

- **Plant (tap F).** Set the flame down. It keeps burning and lights its spot, and you stand in the dark.
- **Recall (tap F again).** The flame flies back to your hand in a straight line. It lights or ignites what it passes: vines, oil puddles, sconces.
- **Ember Step (hold F; first Belt Star).** Warp to the planted flame. Plant before a risky move and step back if it goes wrong.
- **Why it makes players think.** A planted flame is a lure, a lamp for a puzzle and an escape point. While it's planted, you're blind.
- **Later powers.** Alnilam's star gives *Focus*: a narrow beam that reaches far sconces and dazzles one guard. Mintaka's star gives *Flare*: spend 30% fuel to light the whole room for 2 seconds and stun everyone in it.

### Stealth and noise

- Every guard has an awareness meter from 0 to 100, shown as a **?** that fills and turns into a **!**. The guard awareness section below shows each state.
- **Sight.** A guard sees you when you're inside his lantern's cone, nothing blocks the line, and you're lit enough for the distance. Your exposure adds up your torch state, every other light reaching you and your armour's shine.
- **Noise** spreads as rings. Guards inside a ring turn toward it and investigate.

| Action | Noise radius |
| --- | --- |
| Sneaking | 0 tiles |
| Walking | 2 tiles |
| Opening a chest | 3 tiles |
| Thrown pebble landing | 4 tiles |
| Running | 5 tiles |
| Smashing a vase | 6 tiles |
| Sword clash | 8 tiles |
| Armour while moving | +1 bronze, +2 silver, +3 gold |

- **Pebbles** are free and unlimited. Throw one to turn a guard's head or walk him onto cracked tiles.
- **Disguise.** The stolen Watchman tunic fools Watchmen beyond 2 tiles, unless your torch is raised or you attack. Lancers see through it up close; Sentinels always do.

### Movement and traversal

- Eight-direction, screen-relative movement. Running is fast but loud.
- **Fixed jumps:** 2 tiles across, 1 tile up. Every gap is built to those numbers, so a skilled player reads a room and knows what's reachable.
- **Ledges:** walk off an edge to hang, then climb up or drop. Edges are always drawn clearly.
- **Cracked tiles** show a hairline crack and creak. Stand still for 0.6 s and they shake and drop dust; at 1.2 s they collapse. In gold armour, or under a Sentinel, they collapse at once.
- A collapsed tile drops you to the floor below — a shortcut or a trap. Running across a chain of them without stopping is safe, and a skill test.
- **Vines** grow under broken windows, so they always lead toward the sky. Climb them, or burn them with the torch to cut a route and light the room briefly. Gold armour is too heavy to climb.

### Interaction prompts

Your friend's door idea becomes one reusable component for every door, chest, sconce, lever and the merchant.

- **Notice range (about 5 tiles):** a small glyph floats over the object — a diamond for doors, a coin for chests, a flame for sconces.
- **Interact range (1 tile):** the glyph becomes a button prompt with a verb, such as "E — Enter" or "E — Light".
- Glyphs show in the dark, but only for objects you've already seen once. That keeps exploring meaningful.

## Combat

Combat is a short duel you win by reading. Every attack is telegraphed, every enemy has a counter, and the torch in your left hand is a second weapon.

### The basics

- **Moves:** a 3-hit sword combo; parry (tap, 120 ms window); dodge (a sidestep with a brief invulnerability window); torch thrust (stuns and ignites, costs 5% fuel); shove (pushes a guard back one tile).
- **Health:** 4 stars to start, plus 1–3 from armour. Most hits cost 1 star; heavy hits cost 2.
- **Knock-outs, not kills.** It fits a small prince and keeps the game family-friendly. Knocked-out guards stay down; on hard mode they wake after 2 minutes.
- **Duel rule:** only one guard attacks at a time while the others circle. Keep encounters to 2–3 guards so isometric fights stay readable.
- **Clever pays.** A guard dropped by the floor, a ledge or fire gives 50% more coins than a sword knock-out.

### Telegraph language

| Signal | Meaning | Answer |
| --- | --- | --- |
| White star glint on the blade, bright "ting" | Parryable | Parry on the flash |
| Red ring glint, low drum hit | Unparryable | Dodge sideways |
| Guard lowers his lantern and steps back | Charge or lunge coming | Get off his line |
| Shield raised with a pale outline | Blocking from the front | Flank, stun, or use the floor |

The glints differ in shape and sound as well as colour, so they work for colourblind players. On every clash, sparks act as tiny lights for 0.1 s, so each parry lights the room for a moment. Add 60 ms of hit-stop on hits and 100 ms on perfect parries.

### Enemy roster

| Enemy | Acts | Outfit and light | Attack style | Counter | HP | Drops |
| --- | --- | --- | --- | --- | --- | --- |
| Watchman | Prologue, I | Patched brown tunic, cloth turban, hand lantern with a short 60° cone | Slow overhead chop (white) | Parry and riposte, or take him from behind | 3 | 2–5 coins, oil |
| Lancer | I, II | Bronze scale vest, pointed helmet, red sash, torch on a pole lighting a wide circle | Long thrust (red), wide sweep (white); keeps his distance | Stay outside his circle, sidestep the thrust, then close in | 5 | 5–10 coins |
| Sentinel | II, III | Black iron armour, full helm with a scorpion crest, tower shield with a lantern on its face | Shield bash (red), heavy overhead (white); blocks everything from the front | Flank him; thrust the torch at his visor for a 2 s stun; lure him onto cracked tiles; shove him off a ledge | 8 | 10–20 coins, pomegranate |
| Shade (stretch) | III | Dark cloth, carries no light | Snuffs sconces and your planted Ember, strikes from the dark | Visible only in light: raise the torch, fight under sconces, use Flare | 4 | 5 coins |
| Antares (boss) | Finale | Crimson armour, red-glass lantern, chain-blade tail | Long tail strikes (red) and sweeps (white); snuffs every sconce in phase 2 | Relight sconces between attacks to see him; in phase 3, Bellatrix attacks whatever your light touches | 30 | — |

Each guard's light is its silhouette in the dark: a small cone, a wide circle on a pole, a square of light on a shield. Players know the threat before they see the sprite. The Sentinel's light points forward, so his back is always dark and flanking feels natural.

### The torch as an off-hand

- Thrust it at a Sentinel's visor to stun him.
- Set fire to oil puddles and vines in the middle of a fight.
- Light a nearby sconce mid-fight to see attacks earlier, at the cost of being seen by everyone else.
- In the Prologue you have no sword, so shove and torch are your only tools: guards go off ledges, into the well or onto cracked tiles.

## Guard awareness

![Guard awareness: four states while awake, plus knocked out](images/guard-awareness.png)

Every step shows over the guard's head, and hiding walks him back down, so a mistake costs time and tension rather than a reload.

## Economy and the merchant

Coins buy choices, not power. Each sword and armour set is best at one thing and costs you something else, so gold is a playstyle, not an upgrade.

### Where coins come from

| Source | Coins | The catch |
| --- | --- | --- |
| Vase | 1–3 | Smashing it makes a 6-tile noise |
| Chest | 10–25 | Takes 1.5 s to open and makes a 3-tile noise |
| Watchman / Lancer / Sentinel | 2–5 / 5–10 / 10–20 | +50% when the floor, a ledge or fire did it |
| Secret behind Bellatrix's chalk marks | 30+ | Off the main path |

The Prologue holds about 25 coins and Act I about 150 for a thorough player. That buys two items, not everything, which forces a choice.

### Kasib's stall

- Kasib sits in safe rooms with a lit sconce and no guards. These are also save points and the place to swap gear.
- You keep everything you buy and can swap at any of his stalls. The question is never "which is best?" but "which fits the next area?"
- He gives one short tip about the next area per visit. Sample line: "I don't need light to count coins, little prince."

### Swords

| Sword | Price | Damage | Swing time | Reach | Strength | Weakness |
| --- | --- | --- | --- | --- | --- | --- |
| Watchman's scimitar | Free (Prologue) | 1 | 0.40 s | 1 tile | — | Plain |
| Bronze khanjar (dagger) | 30 | 1 | 0.25 s | 0.75 tile | Silent; instant knock-out from behind | Useless against shields |
| Silver shamshir | 75 | 2 | 0.40 s | 1.1 tiles | 180 ms parry window; ripostes do double damage | None — the all-rounder |
| Gold sunblade | 150 | 3 | 0.60 s | 1.3 tiles | Breaks shields; perfect parries add 20% fuel | Slow; the blade glints in light (+15% exposure) |

### Armour

| Armour | Price | Extra health | Noise when moving | Strength | Weakness |
| --- | --- | --- | --- | --- | --- |
| Stolen tunic | Free (Prologue) | +0 | +0 | Disguise against Watchmen | Paper-thin |
| Bronze scale | 40 | +1 | +1 tile | Light; climbs normally | Little protection |
| Silver mail | 90 | +2 | +2 tiles | Less stagger | Medium noise |
| Gold lamellar | 160 | +3 | +3 tiles | Can't be staggered | Breaks cracked tiles at once, can't climb vines, shines (+30% exposure) |

Khanjar plus tunic makes a ghost who avoids fights. Sunblade plus gold makes a tank who has to take the loud, direct route.

### Consumables

| Item | Price | Use | Carry limit |
| --- | --- | --- | --- |
| Oil flask | 10 | Refill 50% fuel, or throw it to make a fire pool that lights an area for 20 s | 3 |
| Pomegranate | 15 | Restores 2 stars | 2 |
| Pebbles | Free | Throw for a 4-tile noise | Unlimited |

## Depth for skilled players

Skilled players get depth from freedom, not bigger health bars. Every encounter has at least three solutions, and the game scores how you solved it.

- **Three ways through every room:** ghost past unseen, trick the guards with lures, floors or fire, or duel. When you build a room, write down all three before placing anything.
- **Dawn Rank** at the end of each act scores time, times spotted, knock-outs versus guards ghosted, coins and damage taken. Ranks run C to S, plus *Orion* for a perfect ghost run under par time.
- **Challenge seals** are optional and shown on the star map: *Moth* — never let the torch burn out; *Shadow* — never raise the torch; *Hunter* — drop every guard with the environment; *Pilgrim* — buy nothing.
- **No minimap.** The star map only marks rooms where you've lit a sconce, so mapping costs you exposure.
- **Systems that talk to each other.** Guards react to sconces changing, alarm braziers light rooms, sparks feed fuel, armour weight breaks tiles. The best "thinking" moments are solutions players find themselves.
- **Hard mode, "Hunter's Night":** a real-time clock (Orion sets in 15 minutes for the slice, 45 for the full game), half the oil, guards wake after 2 minutes, and awareness never fully resets.
- **Speedrun support:** an on-screen timer and an instant room restart.

## Art direction

Night-blue pixel art at 480×270 where colour is information: warm light is yours, cool light is the sky, red is the enemy.

### Canvas and grid

| Setting | Value |
| --- | --- |
| Native resolution | 480×270, integer-scaled ×4 to 1920×1080 |
| Projection | 2:1 pixel isometric (lines step 2 px across, 1 px down) |
| Floor tile | 32×16 px diamond |
| Wall block | 32×32 px plus a 16 px cap; south-facing walls cut away to half height so they never hide the player |
| Height step | 16 px per floor level |
| Facings | Draw two (front-right, back-right) and mirror for the other two. Movement is 8-way; the sprite snaps to the nearest diagonal |

One gotcha: mirroring swaps hands, so the torch jumps to the right hand. At 16 px nobody notices; if it bothers you, draw all four facings for Rigel only.

### Colour rules

- **Colour is information.** Warm amber is your fire, cool blue is moonlight and the sky, crimson is the Scorpion clan and danger, a gold glint is loot.
- **Hue-shift every ramp.** Shadows lean blue-violet and highlights lean yellow. Never darken by adding black.
- **Never pure black.** The darkest value is deep indigo so the game still reads on a projector.
- Keep the palette to about 32 colours. Start from a Lospec palette such as Resurrect 64 and trim it, or start from this one:

| Role | Colours |
| --- | --- |
| Night and shadow | #0d0b1a, #1b1834, #2e3a5c |
| Moonlight | #7fa6d8, #cfe3ff |
| Torch fire | #7a2a1a, #e0782c, #ffc857, #fff1c1 |
| Stone and sand | #3a3330, #6b5d52, #a8957f, #d9c49a |
| Persian tile | #2a4a8c lapis, #3fa7a3 turquoise, #a5502d terracotta |
| Scorpion clan | #8e1b2a, #c23b3b |
| Metals | #a8693a bronze, #b7c1c9 silver, #d9a43a gold |
| Vines | #3d6b3a, #6fa35a |

### Sprite sizes

| Sprite | Size (px) |
| --- | --- |
| Rigel | 16×24 |
| Watchman | 20×32 |
| Lancer | 20×34, plus spear |
| Sentinel | 28×36 |
| Bellatrix | 18×30 |
| Kasib (seated) | 20×24 |
| Antares | 40×48 |

Size tells the story: Rigel is two-thirds of a Watchman's height and half a Sentinel's. Run a silhouette test too: fill every sprite solid black, and if you can't tell the enemies apart, redesign them.

### Rigel's animations

| Animation | Frames |
| --- | --- |
| Idle | 4 |
| Walk, run, sneak | 6 each |
| Jump | 5 |
| Ledge hang, climb up | 2, 6 |
| Vine climb | 4 |
| Sword combo | 3 × 4 |
| Parry, dodge | 3, 5 |
| Torch thrust, torch raise | 4, 2 |
| Plant Ember, recall Ember | 4, 3 |
| Shove, interact | 4, 3 |
| Hurt, knocked down | 2, 6 |

That is about 87 frames per facing, so about 170 for Rigel. Budget about 80 per guard type.

### Asset savers

- **Armour tiers by palette swap.** Draw armour once in a grey ramp; a shader maps it to bronze, silver or gold.
- **One sword animation.** The blade is a separate sprite on a hand anchor, in three lengths.
- **One guard body.** Watchmen, Lancers and Sentinels share a rig; outfit, headgear and weapon differ.
- **Normal maps only on walls, floors and big props.** Generate them with Laigter (free) so torchlight rakes across the brickwork. Characters stay flat for readability.

### Environment kit

- **Architecture:** iwan arches, muqarnas vaults, eight-point star tiles, jali lattice windows, wind-catcher towers on the skyline, brick cisterns.
- **Ruin layer:** cracked plaster showing brick, fallen tiles, cracked floor tiles (three variants plus broken), vines, rubble.
- **Story props:** snuffed lamps still smoking, toppled astrolabes, torn star charts, red-ochre scorpion marks, Bellatrix's chalk stars.
- **Interactables:** vases in three sizes, chests, sconces (lit and unlit), oil jars, alarm braziers, mirrors (Act II), Kasib's stall.

### Tools

- Aseprite (about $20, or free if you compile it yourself), or the free Pixelorama or LibreSprite.
- Laigter for normal maps, Lospec for palettes, and Godot's built-in tile editor for levels.
- A pixel font with a clear licence, such as Daniel Linssen's free m5x7, credited.
- The judges score "it's yours". Draw the core art yourselves, and credit anything external.

## Lighting design

Lighting is Godot 2D lights over a dark base, drawn as banded pixel shapes so the light itself looks hand-made. Exposure is computed in script, never read back from pixels.

### The light rig

| Layer | Godot node | Colour | Notes |
| --- | --- | --- | --- |
| Ambient base | CanvasModulate | Interior #1b1834 (about 10% brightness); courtyard #4a5a8a | Tween to dawn (#f0c8a0) for the ending |
| Player torch | PointLight2D + flicker script | #ffb45a | 48 / 96 / 144 px by torch state; casts shadows; light height set for normal maps |
| Wall sconces | PointLight2D | #ff9d4a | 64 px; lit and unlit states; one shared texture |
| Moonlight | PointLight2D with a jali lattice texture, an additive shaft sprite and dust particles | #7fa6d8 | No shadows |
| Guard lanterns | PointLight2D with a shaped texture | #ffcf7a | The texture is the vision area: cone (Watchman), circle (Lancer), square (Sentinel) |
| Scorpion braziers | PointLight2D | #e04a3a | Red always means enemy |
| Sparks | PointLight2D that lives 0.1 s | #fff1c1 | Spawned on clashes and parries |

### Making light look like pixel art

- **Draw the light textures yourselves:** a radial gradient cut into 4 hard bands, with a 1-pixel dither between bands. Light then falls off in visible steps, like the rest of the art.
- **Render at 480×270 and scale up,** so light edges stay pixel-sharp.
- **Flicker with noise, not a sine wave.** Vary energy ±8% and scale ±4% with FastNoiseLite at about 10 Hz, plus a 1-pixel jitter.
- **Loot glints only when lit.** A canvas shader's `light()` function makes coins and gold sparkle when your torch touches them, which rewards exploring.

### Shadows

- Put LightOccluder2D only on pillar bases and low walls, using footprint polygons. Isometric shadows are cast in screen space, so tall occluders look wrong.
- Cast shadows only from the player torch and a few set pieces. Shadows are the expensive part, especially in a web build.
- A pillar's shadow hides you from a guard's lantern. That's a free stealth mechanic once occluders exist.

### Exposure maths

Godot can't cheaply read the light at a point, so the player script computes it every 0.1 s. Starting values, to tune in playtests:

```gdscript
var e: float = TORCH_EXPOSURE[torch_state]  # shrouded 0.2, normal 0.5, raised 1.0, ember 0.05
for light in LightRegistry.lights_near(global_position):
    if has_line_of_sight(light.global_position, global_position):
        var t := 1.0 - global_position.distance_to(light.global_position) / light.range
        e += light.energy * t * t
if in_moonlight:
    e += 0.6
e *= armour.shine  # 1.3 for gold, 1.0 otherwise
```

A guard sees you when you're inside his cone, the line is clear, and distance < cone\_range × (0.4 + exposure). His awareness then rises by 60 × exposure × (1 − distance / range) per second.

### The projector problem

- Judges will probably watch on a projector or a bright laptop, and both wash out dark scenes. Plan for it now.
- Add a brightness slider and a "Demo" preset that raises ambient light by 15%.
- Give characters a 1-pixel rim in the light's colour on their lit side, so they read against dark floors.
- Test on the real demo screen at least once before judging.
- For the web build, keep about 8–12 lights on screen and test it early.

## Sound and music

Sound is the player's sight in the dark. Guards are heard before they're seen, silence is a mechanic, and the music rises with the guards' awareness.

### Adaptive music

Four stems of the same length and tempo play in lockstep, and the mix follows the highest awareness among nearby guards. Godot 4.3+ has AudioStreamSynchronized for this; fade each stem in or out over about 1 s.

| Stem | Instruments | Plays when |
| --- | --- | --- |
| Drone | Low ney flute and a bowed-string drone on D | Always, very quiet |
| Theme | Santur or setar melody | Exploring |
| Tension | Daf and tombak frame drums | Any guard is suspicious |
| Combat | Fast tombak and low strings | Any guard is alerted |

Keep exploration sparse. Long stretches of drone and room tone make the stingers land.

### Scales and motifs

- **Danger:** D Phrygian dominant (D E♭ F♯ G A B♭ C), close to the Arabic maqam Hijaz and the Persian dastgah Homayoun.
- **Home and loss:** D harmonic minor, close to maqam Nahawand.
- **Three leitmotifs:** Rigel (four rising notes, hopeful), Bellatrix (bold and rhythmic, plays near her chalk marks), Antares (a falling chromatic line).
- **No musician?** Compose in BeepBox or JummBox using Phrygian dominant. An "8-bit maqam" sound is unusual and matches the pixel art.
- **Want real instruments?** Use LMMS (free) with free sampled instruments in Decent Sampler.

### Sound effects

| Group | Sounds | What it tells the player |
| --- | --- | --- |
| Footsteps | Stone, sand, carpet, cracked tile, plus an armour clink layer per armour type | How loud you are; where guards are in the dark |
| Torch | Ignite whoosh, crackle loop, sputter when low, snuff hiss, Ember flight | Fuel left, without looking at the HUD |
| Sword | Three swing variants, clash, parry "ting", riposte hit, shield thud | Timing; the parry "ting" must be the brightest sound in the game |
| Telegraphs | High chime for a white glint, low drum for a red glint | Parry or dodge, by ear |
| World | Vase smash, coin jingle that rises in pitch along a chain, chest creak, tile groan and collapse, vines burning | Risk and reward |
| Guard barks | "Hm?" (suspicious), "There!" (alert), "…rats." (gives up) | Each guard's awareness state |
| Ambience | Wind through broken windows, cistern drips, a distant owl, room tone | Space and isolation |
| Kasib | Pitched gibberish syllables | Character without voice acting |

### Mix tricks

- Shrouding the torch puts a low-pass filter on the music and ambience buses, like holding your breath.
- A short santur-and-drum stinger plays the moment a guard goes to alert.
- A heartbeat layer plays at 1 star.
- Guard footsteps are positional and audible beyond the light, so players learn to listen.
- Use AudioStreamRandomizer for pitch and volume variation on every repeated sound.

### Tools

- jsfxr or ChipTone (free, in the browser) for retro effects; Audacity for editing.
- Freesound, filtered to CC0, for ambience. Credit sources and check the hackathon's rules on outside assets.
- Phone foley works well: keys for armour, celery for hits, rice on cardboard for footsteps, a struck match for the torch.

## Controls

Keyboard and mouse is the main scheme for the demo; gamepad support comes almost free in Godot's input map. Teach each control in the world, one at a time, through the prompt glyphs.

| Action | Keyboard and mouse | Gamepad |
| --- | --- | --- |
| Move | WASD | Left stick |
| Run | Hold Ctrl | Click left stick (toggle) |
| Jump, climb, drop | Space | A |
| Dodge | C | B |
| Sword attack | Left click | X |
| Parry | Right click | RB |
| Interact | E | Y |
| Shroud torch and sneak | Hold Shift | Hold LT |
| Raise torch | Hold R | Hold LB |
| Torch thrust | Q | LB + X |
| Plant or recall the Ember (hold: Ember Step) | F | RT |
| Throw a pebble | G, toward the cursor | Flick the right stick |
| Star map, pause | Tab, Esc | Back, Start |
| Debug overlay (dev builds) | F3 | — |

## Tech plan

Use Godot 4.3 or newer with GDScript. It has the strongest 2D lighting and isometric tiles of the free engines, it's light enough for two people, and it exports a web build judges can play in a browser.

### Engine choice

| Option | Verdict | Why |
| --- | --- | --- |
| Godot 4.3+ | Use this | Built-in 2D lights, shadows and normal maps; isometric tile layers with Y-sorting; fast GDScript iteration; free; web, Windows and Android exports |
| Unity 6 | Fine if one of you already knows it well | Its 2D lights are excellent, but the editor is heavier and setup takes longer |
| Unreal Engine | Skip | Built for 3D; its 2D tools are thin |
| Android Studio | Skip | An app IDE, not a game engine. Godot exports to Android if you want mobile later |
| A separate prototyping tool | Skip | Prototype in Godot with grey boxes, so nothing is thrown away |

### Project settings

- Viewport 480×270, window 1920×1080, stretch mode "viewport", scale mode "integer".
- Default texture filter set to Nearest; snap 2D transforms and vertices to pixels.
- Pick the renderer on day one. Compatibility runs in browsers; Forward+ is desktop-only. Choose Compatibility if you want a playable web link.
- Use the single-threaded web export (Godot 4.3+), which runs on itch.io without special server headers.

### Project structure

```text
orion/
├─ project.godot
├─ autoload/     game_state.gd, noise_bus.gd, light_registry.gd, audio_director.gd
├─ components/   health.gd, hitbox.gd, hurtbox.gd, interactable.tscn, light_source.gd
├─ actors/
│  ├─ player/    player.tscn, player.gd, states/ (idle, move, sneak, jump, climb, attack, parry, dodge, hurt)
│  └─ guards/    guard.tscn, guard.gd, perception.gd, states/ (patrol, suspicious, alert, search)
├─ data/         weapons/*.tres, armour/*.tres, enemies/*.tres
├─ levels/       gate.tscn, undercroft.tscn, rooms/
├─ props/        vase, chest, sconce, cracked_tile, vine, oil_jar, alarm_brazier, door
├─ ui/           hud, star_map, merchant, prompts, title
├─ art/          sprites, tiles, light textures, normal maps
├─ audio/        music stems, sfx, ambience
└─ debug/        overlay.tscn (F3)
```

### Core systems

| System | Built from | Job |
| --- | --- | --- |
| Player | CharacterBody2D + state machine | Movement, combat, torch states, the Ember |
| Guard AI | CharacterBody2D + NavigationAgent2D + state machine | Patrol, react, fight; a shared "attack token" lets only one guard attack at a time |
| Perception | Script on each guard | Sight from cone + raycast + exposure; hearing from the NoiseBus |
| LightRegistry | Autoload | Tracks every light for the exposure maths, and tells guards when a sconce changes |
| NoiseBus | Autoload with one signal, `noise(position, radius, source)` | Every loud action calls it; guards in range react |
| Interactable | Area2D component with two radii | The notice glyph and button prompt, reused everywhere |
| Gear and enemy data | Custom Resources (.tres files) | Tune numbers without touching code |
| AudioDirector | Autoload | Mixes music stems from the highest awareness; plays stingers |
| Saving | JSON in `user://`, written at lit sconces | Checkpoints |
| Debug overlay | A scene toggled with F3 | Draws vision cones, noise rings, exposure and AI states — also a demo tool for the technical score |

### Isometric gotchas

- Use a TileMapLayer with tile shape Isometric, layout Diamond Down, size 32×16, and Y-sort enabled on the parent. Put each wall tile's Y-sort origin at its base.
- For walls in front of the player, cut south walls away permanently, or fade a wall with a dither shader while the player is behind it.
- Use one TileMapLayer per floor, offset 16 px up. Stairs and ladders switch the player's collision layer.
- Movement input is screen-relative. Halve vertical speed if diagonal movement feels too fast on the 2:1 grid.
- For pathfinding, bake a NavigationRegion2D from the tiles, or use AStarGrid2D, which supports isometric cells.

### Working as two

- Use Git and GitHub from the first hour, with Godot's .gitignore (it ignores the `.godot/` folder).
- Godot scene files merge badly. Split the game into many small scenes, and let only one person edit a scene at a time.
- Commit small and often, and tag every build you might demo.

## Hackathon scope

Ship one polished 10–15 minute slice — the Gate and the Undercroft, ending on the first Belt Star — not three rough acts. Judges reward "fun to pick up and play" far more than content they'll never reach.

### What's in the slice

| Priority | Features |
| --- | --- |
| Must | Isometric movement with fixed jumps and ledges; torch with three sizes; darkness inside; Watchman and Lancer with lantern vision and awareness meters; attack, parry, dodge, shove; telegraph glints; cracked tiles; vases, chests and coins; Kasib selling 2 swords and 2 armour sets; the Ember (plant and recall); interaction prompts; decorative vines; the Gate and 5 Undercroft rooms; title screen and end card; core sound effects and one music loop; brightness slider |
| Should | Sentinel; torch-thrust stun; fuel, with sconces as checkpoints; noise rings and pebbles; Ember Step as the end reward; adaptive music stems; normal-mapped walls; Dawn Rank screen; debug overlay |
| Could | Third sword and armour; disguise; alarm braziers; climbable vines; Bellatrix's chalk-mark secrets; star map; constellation intro; hard mode |
| Won't, this hackathon | Acts II and III, mirror puzzles, Shades, Antares, Focus and Flare, mobile controls, a full save system |

### The slice, room by room

1. **The Gate** (moonlit courtyard): sneak with the torch shrouded, shove a Watchman into the well, take his scimitar and tunic, see the door's glyph from afar, then "Enter".
2. **Entrance hall:** the screen goes dark and only your torch is left. Learn the torch sizes, sconces and vases, and parry your first Watchman.
3. **Storerooms:** plant the Ember to light a dark room from a distance, then recall it. Lure a guard across cracked tiles.
4. **Kasib's cistern:** a safe room — save, shop, choose a loadout.
5. **Lancer gallery:** the exam. Two guards and a Lancer; ghost, trick or duel.
6. **Alnitak shrine:** take the first Belt Star and gain Ember Step, then use it to escape as the floor collapses behind you. End card with your Dawn Rank: "Orion is sinking."

### Who builds what

| Area | Person A: gameplay code | Person B: art, audio, levels, UI |
| --- | --- | --- |
| Player | Controller, states, combat, the Ember | Sprites and animations |
| Guards | AI, perception, attack token | Sprites, silhouettes, barks |
| World | Cracked tiles, sconces, noise, exposure maths | Tilesets, light textures, normal maps, props |
| Levels | Scripted events, triggers | Room layouts built in the editor |
| UI and audio | Merchant logic, saving, debug overlay | HUD, merchant screen, music, sound effects |

Both of you: design decisions, room layouts drawn on paper first, and a 15-minute playtest every day. If you both code, split by systems instead: one takes player, combat and guards; the other takes lights, props, interactables, UI and audio.

Art is the bottleneck in isometric pixel art. Start every system with coloured grey-box diamonds and swap in final art once the mechanic is fun.

## Build roadmap

![Build roadmap: five phases, four gates, two lanes](images/build-roadmap.png)

If a gate fails, fix that phase before starting the next one: a fun greybox matters more than finished art. With 48 hours the phases run in hours; with two weeks, in days.

## Demo to the panel

Win the panel in three minutes: show the moment the lights go out, one clever solution and the debug overlay, then hand a judge the controls.

### Judging criteria, mapped

| Criterion | What the judges should see | When in the demo |
| --- | --- | --- |
| 01 Creativity | Light that cuts both ways; the Ember; the castle laid out as Orion; the sky as the clock; a princess who saves herself | 0:00–0:20 and 1:20–1:40 |
| 02 Gameplay experience | A tight loop of read, choose, act; three solutions per room; telegraphs a stranger can read | 0:40–1:40 and the hands-on |
| 03 Design quality | A palette with meaning (warm, cool, red), readable silhouettes, Persian architecture, torchlight on normal-mapped walls, music that reacts | Throughout; point out the music shift |
| 04 Technical implementation | Light exposure, noise propagation, guard state machines, isometric Y-sorting, data-driven gear, a web build | 2:00–2:30 with the F3 overlay |

### Three-minute script

1. **0:00** Title: the constellation draws itself. One line: "Light lets you see. It also lets them see you."
2. **0:20** The Gate: sneak with the torch shrouded, shove a Watchman into the well, take his sword.
3. **0:40** "Enter" — the screen goes dark. Raise and shroud the torch to show the trade-off.
4. **1:00** Smash a vase and a guard turns. Parry him, and the sparks light the room.
5. **1:20** Plant the Ember as a lure, recall it, and walk a Lancer onto cracked tiles.
6. **1:40** At Kasib's stall, explain gold armour's trade-offs in one sentence.
7. **2:00** Press F3: vision cones, noise rings, the exposure value. Explain the system in two sentences.
8. **2:30** Hand a judge the controls in the Lancer gallery.

### Demo risks

| Risk | Fix |
| --- | --- |
| The projector washes out the dark | Demo brightness preset; test on the real screen beforehand |
| A bug or crash on stage | Demo from a tagged build; a debug room select (F1–F6) to jump to any room |
| The laptop or browser runs slowly | Desktop build as the main copy, web link as backup; cap lights on screen |
| The live demo fails completely | A 90-second recorded video as a fallback |
| Judges don't know the controls | Prompts in the world, plus a one-card control sheet on the table |

## Open questions

- [ ] How long is the hackathon, and can you build anything before it opens? That sets the roadmap's real dates.
- [ ] Are outside assets (fonts, CC0 sounds) or AI-generated assets allowed? "It's yours" suggests making the core art yourselves.
- [ ] Who draws and who codes? Has either of you used Godot, Aseprite or a music tool before?
- [ ] Is Bellatrix Rigel's sister or his betrothed? A sister reads better with a small prince.
- [ ] Desktop and web only, or does Android matter? Touch controls would need their own design.
- [ ] Are the names (Rigel, Bellatrix, Antares, Kasib) final, or does your friend have others in mind?
