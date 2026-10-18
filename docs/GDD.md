# ORION — Game Design Document (Greek)

Oct 17, 2026 · @Adithya Raj

ORION keeps the heart of the idea — a small prince, a dark ruined citadel, a torch as the only light — and makes that torch the whole game: light lets you see, but it also lets them see you. This version sets it in mythic Greece, where Orion's own myth becomes the plot. The [Persian version](https://claude.ai/artifact/DkETn7xHUMDvHV2gPv3CLH) is kept only as an archive: Greek is the confirmed direction, decided on 18 Oct 2026.

## Greek versus Persian

The game underneath is the same; the Greek setting mainly upgrades the story. Orion's own myth — a blind hunter guided to the sunrise by a small boy — is a story about light and sight, so it becomes the plot instead of a backdrop.

| Area | Persian version | Greek version | Why |
| --- | --- | --- | --- |
| Myth | Orion through Arabic star names | Orion's own myth: blinded, guided east by the boy Cedalion, healed by the sunrise, killed by the scorpion | The myth is already about light, sight and a small guide |
| Hero | Rigel | Cedalion | In the myth, Cedalion is the small one who sees for a blind giant |
| Princess | Bellatrix | Alcyone, the brightest of the Pleiades | A Greek star name; the Pleiades rise just ahead of Orion, like a princess who stays one room ahead |
| Villain | Antares | Antares (kept) | The name is already Greek, and the scorpion is what killed Orion |
| Merchant | Kasib, a blind oil-seller | Phineus, a blind seer | His one prophecy per visit is the tip mechanic |
| Goal | Light the Hunter's Lamp | Light the Hunter's Beacon to warn the allied islands | Greek beacon-fire chains are a famous real practice |
| Framing | The longest night | The Long Night Vigil, kept for the blind hunter | The darkness now means something: the enemy breaks a sacred vigil |
| Finale | Bellatrix fights what you light | Alcyone fights blind and you are her eyes | It acts out the Cedalion myth |
| Architecture | Mud-brick citadel, Isfahan tilework, iwans | Classical temples from your reference board, built on older cyclopean walls | Your references; the Athenian Acropolis really sits on Mycenaean walls |
| Moonlight | Lattice windows | Collapsed roofs, open courtyards and gaps between columns | Glass windows don't fit; columns give natural stripes of light and shadow |
| Enemies | Watchman, Lancer, Sentinel | Watchman, Spearman, Hoplite | Greek soldier types; the counters are unchanged |
| Gear | Khanjar, shamshir, sunblade; scale, mail, lamellar | Inlaid dagger, kopis, gold-hilted longsword; linothorax, muscle cuirass, Dendra plate | Real Greek weapons and armour |
| Props | Astrolabes, star charts | A broken bronze "Star Engine" (Antikythera-style), star frescoes, amphorae, statues, fountains | Greek objects with the same jobs |
| Music | Santur, ney, daf; Hijaz | Lyre, aulos, frame drums; Dorian and Phrygian modes | Greek instruments and modes |
| Cutscenes and UI | A constellation that draws itself | Black-figure vase paintings and meander borders | Cheap two-colour silhouettes that read as Greek at once |
| Unchanged | — | Pillars, light and visibility, the Ember, stealth and noise, movement, telegraphs, economy numbers, controls, tech, scope, roadmap, demo plan | The design works in either world |

## What changes from the original idea

Most of the idea stays. The torch is its best part, so it becomes the centre of the design. The changes swap stat upgrades and generic beats for choices that make players think.

| Original idea | Verdict | What ORION does |
| --- | --- | --- |
| Small prince saves a princess from a castle at night | Keep, add a twist | The princess is a warrior who breaks out herself and races you to the summit. You have the light; she has the strength. |
| Prince of Persia theme | Keep as inspiration only | Borrow its measured movement, duels and traps. Build a new world from Greek myth and the Orion story. |
| Pixel art, isometric view | Keep | 2:1 isometric at 480×270, scaled ×4 to 1080p. Draw two facings per sprite and mirror the other two. |
| Torch is the only light inside | Keep — make it the core | Light cuts both ways: it shows you the room and shows you to the guards. You control its size, its fuel and where it sits. |
| 30–40 px light radius | Change | Too tight to see attacks coming, which feels unfair rather than hard. Use three sizes: 48 px shrouded, 96 px normal, 144 px raised. |
| Start unarmed, take a guard's sword and armour | Keep | The Lion Gate is an unarmed stealth tutorial. Knock out a Watchman to take his short sword and his tunic, which works as a disguise. |
| Message icon from afar, "Enter" up close | Keep, make it a system | Every interactable uses the same two-range prompt: a glyph at 5 tiles, a button prompt at 1 tile. |
| Coins in vases, chests and from guards | Keep, add risk | Obols hide in amphorae and giant storage jars. Smashing pottery is loud, so greed versus stealth becomes a real choice. |
| Three guard tiers, each with its own style and outfit | Keep, sharpen | Each tier asks one question with one answer: parry, sidestep, or flank and stun. You can tell them apart by silhouette and by the light they carry. |
| Cracked floor tiles | Keep, make them react | Cracked marble and mosaic give way under weight: yours, a heavy guard's, or heavy armour's. They become traps and shortcuts. |
| Vines from broken glass windows | Keep, give them a job | Ivy and grapevines grow where moonlight gets in, through collapsed roofs and courtyards. Climb them, or burn them to cut a route off. |
| Merchant sells bronze, silver, gold swords and armour | Change | Good-better-best has one right answer. Make the three tiers sidegrades with weight, noise and shine costs. |
| Godot, Unity or Android Studio; prototype in a Google playground | Change | Use Godot 4 for everything, including the prototype. Android Studio is an app IDE, not a game engine. |

## Pitch and pillars

**Pitch:** A small prince carries the last flame through a dark temple-citadel. Every light that shows him the way also gives him away. He has until Orion sets.

**Tagline:** Be the eyes of the hunter.

Four pillars decide every feature. If a feature serves none of them, cut it.

1. **Light cuts both ways.** Light lets you see, and it lets them see you. Every light in the game is both a tool and a risk.
2. **Every fight is a puzzle.** Attacks are telegraphed clearly. Each enemy type has a counter, and the room itself is a weapon.
3. **Measured movement.** This is the Prince of Persia DNA: fixed jump lengths, ledges and crumbling floors. Every move is a commitment.
4. **Small prince, sharp mind.** He wins through choices, not stats. Gear, routes and greed all cost something.

### Staying clear of Prince of Persia

Prince of Persia is a reference for feel, not a template. Never use its name, logo, characters, music, sprites or the Sands of Time. Mechanics can't be copyrighted, but each borrowed one gets a new form here.

| Prince of Persia | ORION's version |
| --- | --- |
| A princess waits in a tower | Alcyone breaks out herself and races you to the summit |
| A 60-minute real-time limit (1989) | The sky is the clock: Orion sinks past the columns as the night goes on |
| Rewinding time with the Sands of Time | The Ember: drop your flame, call it back, step to it |
| Loose floor tiles | Cracked marble that reacts to weight — yours, your armour's, a heavy guard's |
| Side-view sword duels | Duels you read through light: a white glint means parry, a red glint means dodge |
| Side-scrolling platforming | Isometric measured movement: fixed jumps, ledges, vines |
| An evil vizier | Antares and the Scorpion Brotherhood — no vizier |
| Health potions | Pomegranates, Persephone's fruit, to heal; health shown as stars |

## Story and world

On the longest night of the year, the Scorpion Brotherhood storms the Star Citadel and snuffs every flame of the sacred vigil. Cedalion, the smallest prince, must carry the last one to the summit beacon before Orion sets.

### The myth we build on

- Orion, the giant hunter, was blinded by King Oenopion.
- The smith-god Hephaestus gave him a boy, Cedalion, who rode on Orion's shoulders and guided him east.
- When Orion faced the rising sun, his sight came back.
- Later a giant scorpion killed him. The hunter and the scorpion were set on opposite sides of the sky so they never meet: Orion sets as the Scorpion rises.

The game acts this out. You are Cedalion, the small one who sees for the strong. The whole night is a blind walk toward the dawn, and the ending is the sunrise that gives the hunter back his sight.

### Premise

- The Star Citadel is a temple-citadel on a rocky island: marble temples built on top of far older cyclopean walls.
- Every year on the longest night its people keep the **Long Night Vigil**. Every lamp burns until dawn, for the blind hunter who walked toward the sun.
- At midnight Antares and the Scorpion Brotherhood climb the walls. They snuff every lamp and drag Princess Alcyone to the summit.
- Cedalion escapes with **the Ember**, the vigil flame from the shrine hearth. It is now the only fire inside the walls.
- The Scorpion fleet lands at dawn. Only the Hunter's Beacon on the summit can warn the allied islands in time, and by custom only the vigil flame may light it.
- On the longest night Orion rules the sky until dawn, then sets in the west as Antares, the Scorpion's red heart, rises in the east. That is the game's clock: **you have until Orion sets.**

### Characters

| Character | Name meaning | Role | Look |
| --- | --- | --- | --- |
| Cedalion | The boy who guided blind Orion to the sunrise | Player. Youngest prince, never trained to fight. Wins with wits. | 16×24 px, short tunic, a cloak too big for him, torch in his left hand |
| Alcyone | The brightest of the Pleiades, the stars that rise just ahead of Orion | The princess and the citadel's best spear. Breaks out in Act I and stays one room ahead of you. | 18×30 px, Aegean blue and white, spear and small round shield |
| Antares | Greek, "rival of Ares" — the red heart of the Scorpion | Villain. Leads the Scorpion Brotherhood and wants the citadel dark when his fleet lands. | 40×48 px, red-lacquered bronze, scorpion crest, a hooked glaive shaped like a scorpion's tail |
| Phineus | The blind seer who guided the Argonauts | The merchant. Sells olive oil and gear to anyone and gives one prophecy per visit. | 20×24 px, seated, clouded eyes, a lamp he never lights |
| Scorpion Brotherhood | — | The guards: Watchmen, Spearmen, Hoplites | A red scorpion painted on every shield and cloak |

### Why these names

- **Cedalion replaces Rigel.** The myth's Cedalion is a small guide who sees for a blind giant: the game's theme in one name. Rigel stays as the Lion Gate's star on the map.
- **Alcyone replaces Bellatrix.** She's a Greek star, and the Pleiades lead Orion across the sky. Avoid Merope: in the myth, Orion's assault on Merope is why he was blinded. Bellatrix (Latin, "female warrior") is the fallback.
- **Antares stays.** The name is Greek already, and the scorpion is what killed Orion.
- **Phineus replaces Kasib.** A blind seer who gave directions suits a merchant who sells tips. Not Charon: Hades already made the ferryman a shopkeeper.
- **Oenopion stays in the legend** as the king who blinded the hunter. He's a ready-made villain for a later chapter.

### The twist

Alcyone isn't waiting to be saved. She escapes her guards in Act I and fights upward to light the beacon herself, but she has no flame. You follow her trail of knocked-out guards and her mark, seven scratched dots for the Pleiades; the marks also point to secrets.

In the finale Antares snuffs the summit and Alcyone is fighting blind. You become her eyes: she strikes whatever your light touches, like Cedalion on the hunter's shoulders. Strength without light is blind, and light without strength gets snuffed out.

### Ending

Cedalion lights the beacon as Orion touches the western sea. The sun rises in the east, as it did for the blind hunter, and for the first time the whole citadel is visible in daylight — the sunlit temples of your reference board. Players see how much they crossed in the dark.

### How the story is told

- A 20-second intro in black-figure vase style: the myth of Orion and Cedalion painted on a turning vase, then the attack.
- No walls of dialogue. Phineus speaks in short prophecies; guards bark one or two words.
- The world tells the rest: vigil lamps still smoking, star frescoes scratched out, red scorpions painted over them, the broken Star Engine, Alcyone's seven-dot marks.
- Orion is visible between the columns in every act, a little lower each time.

### World and culture

- A mythic island citadel. Classical temples, colonnades, mosaics, statues and fountains (your reference board) stand on rough cyclopean walls with a lion gate from an older age. The Athenian Acropolis is a real example: its temples sit on Mycenaean walls.
- It's a blend, not a reconstruction. Mixing eras is fine if the look stays consistent.
- Heroes and villains share one culture. The Scorpion Brotherhood is a faction; a red scorpion was a real shield emblem on Greek vases.
- Greek myth is public domain, but some takes on it are not. Steer clear of Hades (its painterly style, Charon as shopkeeper, gods handing out boons), God of War (Kratos, gore, chained blades) and Apotheon (a whole game drawn in black-figure style; we use it only for cutscenes).
- No fake Greek lettering, such as Σ for E. Check any Greek words with a Greek speaker.

## The castle map

![Citadel map: the citadel laid out as the Orion constellation](images/castle-map.png)

You start at Rigel, Orion's foot, and finish at Meissa, his head, where the beacon stands in a round *tholos* temple. The layout and routes match the Persian version; only the area names change. Act III still offers two ways up, so your loadout decides the route.

## Core mechanics

Five systems carry the game, and all of them run through light: how lit you are, where your flame is, how loud you are, how you move, and what you can touch. They're unchanged from the Persian version; the Greek setting adds columns, statues and fountains that feed them.

### Light and visibility

Your torch has three sizes. Bigger light shows more of the room and makes you visible from further away.

| Torch state | Radius | Fuel burn | Guards spot you from | Use it for |
| --- | --- | --- | --- | --- |
| Shrouded (hold Shift) | 48 px (1.5 tiles) | 0.6× | Close range only | Sneaking past |
| Normal | 96 px (3 tiles) | 1× | Medium range | Exploring |
| Raised (hold R) | 144 px (4.5 tiles) | 1.6× | Far away | Scouting a room, spotting traps |
| Out of fuel | 24 px | — | Almost never | Limping to the next oil jar |

- **Fuel** is olive oil. A full torch lasts about 4 minutes at normal size. Refill from oil jars, by standing near a lit wall lamp, or with an oil flask. Perfect parries throw sparks that add 10%. An empty torch never kills you, but it shrinks to an ember and disables the Ember powers.
- **Vigil lamps paint the light map.** Terracotta lamps in wall niches start snuffed. Relight one and the area is lit and your progress is saved, but guards can now see you there too. Snuff lamps to make dark paths. Guards notice a lamp changing and come to look, so a lamp is also a lure.
- **Moonlight** falls through collapsed roofs and open courtyards. Colonnades cut it into stripes: cross a portico in the column shadows and you're hidden; step into a stripe and you're lit.
- **Alarm tripods.** An alerted guard runs to the nearest bronze tripod brazier. If he lights it, the whole room lights up. Stop him on the way, or snuff it afterwards.

### The Ember

The Ember is ORION's signature mechanic and its answer to rewinding time. Your flame can leave your hand.

- **Plant (tap F).** Set the flame down. It keeps burning and lights its spot, and you stand in the dark.
- **Recall (tap F again).** The flame flies back to your hand in a straight line. It lights or ignites what it passes: vines, oil puddles, lamps.
- **Ember Step (hold F; first Belt Star).** Warp to the planted flame. Plant before a risky move and step back if it goes wrong.
- **Why it makes players think.** A planted flame is a lure, a lamp for a puzzle and an escape point. While it's planted, you're blind.
- **Later powers.** Alnilam's star gives *Focus*: a narrow beam that reaches far lamps and dazzles one guard. Mintaka's star gives *Flare*: spend 30% fuel to light the whole room for 2 seconds and stun everyone in it.

### Stealth and noise

- Every guard has an awareness meter from 0 to 100, shown as a **?** that fills and turns into a **!**. The guard awareness section below shows each state.
- **Sight.** A guard sees you when you're inside his lantern's cone, nothing blocks the line, and you're lit enough for the distance. Your exposure adds up your torch state, every other light reaching you and your armour's shine.
- **Noise** spreads as rings. Guards inside a ring turn toward it and investigate.

| Action | Noise radius |
| --- | --- |
| Sneaking | 0 tiles |
| Walking | 2 tiles |
| Opening a chest | 3 tiles |
| Wading through a pool | 3 tiles |
| Thrown knucklebones landing | 4 tiles |
| Running | 5 tiles |
| Smashing an amphora or storage jar | 6 tiles |
| Sword clash | 8 tiles |
| Armour while moving | +1 light, +2 medium, +3 heavy |

- **Fountains mask sound.** Within 3 tiles of running water, your footsteps make no noise. Courtyards become safe crossings, if you can stay out of the moonlight.
- **Knucklebones** are free and unlimited. Toss them to turn a guard's head or walk him onto cracked marble.
- **Statue or guard?** Courtyards are full of statues. In the dark, a Hoplite standing still looks exactly like one until light touches him. Statues also block sight lines, so they double as hiding spots.
- **Disguise.** The stolen Watchman tunic and cap fool Watchmen beyond 2 tiles, unless your torch is raised or you attack. Spearmen see through it up close; Hoplites always do.

### Movement and traversal

- Eight-direction, screen-relative movement. Running is fast but loud.
- **Fixed jumps:** 2 tiles across, 1 tile up. Every gap is built to those numbers, so a skilled player reads a room and knows what's reachable.
- **Ledges:** walk off an edge to hang, then climb up or drop. Temple steps and broken platforms make natural ledges.
- **Cracked marble and mosaic** show a hairline crack and creak. Stand still for 0.6 s and they shake and drop dust; at 1.2 s they collapse. In heavy armour, or under a Hoplite, they collapse at once.
- A collapsed floor drops you to the level below — a shortcut or a trap. Running across a chain of cracks without stopping is safe, and a skill test.
- **Ivy and grapevines** grow where moonlight gets in, so they always lead toward the sky. Climb them, or burn them with the torch to cut a route and light the room briefly. Heavy armour is too heavy to climb.

### Interaction prompts

Your friend's door idea becomes one reusable component for every door, chest, lamp, lever and the merchant.

- **Notice range (about 5 tiles):** a small glyph floats over the object — a diamond for doors, a coin for chests, a flame for lamps.
- **Interact range (1 tile):** the glyph becomes a button prompt with a verb, such as "E — Enter" or "E — Light".
- Glyphs show in the dark, but only for objects you've already seen once. That keeps exploring meaningful.

## Combat

Combat is a short duel you win by reading. Every attack is telegraphed, every enemy has a counter, and the torch in your left hand is a second weapon. Only the enemy roster changes from the Persian version.

### The basics

- **Moves:** a 3-hit sword combo; parry (tap, 120 ms window); dodge (a sidestep with a brief invulnerability window); torch thrust (stuns and ignites, costs 5% fuel); shove (pushes a guard back one tile).
- **Health:** 4 stars to start, plus 1–3 from armour. Most hits cost 1 star; heavy hits cost 2.
- **Knock-outs, not kills.** It fits a small prince and keeps the game family-friendly. Knocked-out guards stay down; on hard mode they wake after 2 minutes.
- **Duel rule:** only one guard attacks at a time while the others circle. Keep encounters to 2–3 guards so isometric fights stay readable.
- **Clever pays.** A guard dropped by the floor, a ledge or fire gives 50% more obols than a sword knock-out.

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
| Watchman (*phylax*) | Prologue, I | Undyed wool tunic, felt cap, terracotta hand lantern with a short 60° cone | Slow overhead chop (white) | Parry and riposte, or take him from behind | 3 | 2–5 obols, oil |
| Spearman (*doryphoros*) | I, II | Linen corslet, crested leather helmet, red cloak, torch on a tall pole lighting a wide circle | Long thrust (red), wide sweep (white); keeps his distance | Stay outside his circle, sidestep the thrust, then close in | 5 | 5–10 obols |
| Hoplite | II, III | Bronze cuirass, Corinthian helmet with eye slits, big round shield painted with a red scorpion and a lantern hung from its rim | Shield bash (red), heavy overhead (white); blocks everything from the front | Flank him; thrust the torch into his eye slits for a 2 s stun; lure him onto cracked marble; shove him off a ledge | 8 | 10–20 obols, pomegranate |
| Shade (stretch) | III | Black wool, carries no light | Snuffs lamps and your planted Ember, strikes from the dark | Visible only in light: raise the torch, fight under lamps, use Flare | 4 | 5 obols |
| Antares (boss) | Finale | Red-lacquered bronze, scorpion crest, red lantern, a hooked glaive shaped like a scorpion's tail | Long glaive strikes (red) and sweeps (white); snuffs every lamp in phase 2 | Relight lamps between attacks to see him; in phase 3, Alcyone strikes whatever your light touches | 30 | — |

Each guard's light is its silhouette in the dark: a small cone, a wide circle on a pole, a square of light on a shield. Players know the threat before they see the sprite. The Hoplite's light points forward, so his back is always dark and flanking feels natural.

Antares carries a glaive rather than the Persian version's chain-blade, because chained blades read as God of War.

### The torch as an off-hand

- Thrust it into a Hoplite's eye slits to stun him.
- Set fire to oil puddles and vines in the middle of a fight.
- Relight a nearby lamp mid-fight to see attacks earlier, at the cost of being seen by everyone else.
- In the Prologue you have no sword, so shove and torch are your only tools: guards go off ledges, into the well or onto cracked marble.

## Guard awareness

![Guard awareness: four states while awake, plus knocked out](images/guard-awareness.png)

Every step shows over the guard's head, and hiding walks him back down, so a mistake costs time and tension rather than a reload. Only the barks change from the Persian version: short Greek words, to be checked with a speaker.

## Economy and the merchant

Obols buy choices, not power. Each sword and armour set is best at one thing and costs you something else, so gold is a playstyle, not an upgrade. The numbers match the Persian version; only names and flavour change.

### Where obols come from

| Source | Obols | The catch |
| --- | --- | --- |
| Amphora | 1–3 | Smashing it makes a 6-tile noise |
| Giant storage jar (*pithos*) | 5–8 | Same noise, and it takes two hits |
| Cedar chest | 10–25 | Takes 1.5 s to open and makes a 3-tile noise |
| Watchman / Spearman / Hoplite | 2–5 / 5–10 / 10–20 | +50% when the floor, a ledge or fire did it |
| Secret behind Alcyone's seven-dot marks | 30+ | Off the main path |

The Prologue holds about 25 obols and Act I about 150 for a thorough player. That buys two items, not everything, which forces a choice.

### Phineus's stall

- Phineus sits in safe rooms with a lit lamp and no guards. These are also save points and the place to swap gear.
- You keep everything you buy and can swap at any of his stalls. The question is never "which is best?" but "which fits the next area?"
- He gives one short prophecy about the next area per visit, which is the hint system. Sample line: "I lost my eyes long ago, little prince. I can still count obols."

### Swords

| Sword | Price | Damage | Swing time | Reach | Strength | Weakness |
| --- | --- | --- | --- | --- | --- | --- |
| Watchman's short sword (*xiphos*) | Free (Prologue) | 1 | 0.40 s | 1 tile | — | Plain |
| Bronze inlaid dagger | 30 | 1 | 0.25 s | 0.75 tile | Silent; instant knock-out from behind | Useless against shields |
| Silver-hilted *kopis* | 75 | 2 | 0.40 s | 1.1 tiles | 180 ms parry window; ripostes do double damage | None — the all-rounder |
| Gold-hilted longsword | 150 | 3 | 0.60 s | 1.3 tiles | Breaks shields; perfect parries add 20% fuel | Slow; the blade glints in light (+15% exposure) |

The dagger and the longsword are heirlooms from the age of the old walls: Mycenaean graves held inlaid bronze daggers and gold-hilted long swords. The xiphos and kopis are the soldiers' blades of the temple age.

### Armour

| Armour | Price | Extra health | Noise when moving | Strength | Weakness |
| --- | --- | --- | --- | --- | --- |
| Watchman's tunic and cap | Free (Prologue) | +0 | +0 | Disguise against Watchmen | Paper-thin |
| Bronze-scaled *linothorax* (layered linen) | 40 | +1 | +1 tile | Light; climbs normally | Little protection |
| Silvered muscle cuirass | 90 | +2 | +2 tiles | Less stagger | Medium noise |
| Gilded Dendra plate | 160 | +3 | +3 tiles | Can't be staggered | Breaks cracked marble at once, can't climb vines, shines (+30% exposure) |

The Dendra armour is a real Mycenaean suit of bronze plates from about 1400 BCE, with a collar up to the ears. It makes the perfect heavy tier.

Dagger plus tunic makes a ghost who avoids fights. Longsword plus Dendra plate makes a tank who has to take the loud, direct route.

### Consumables

| Item | Price | Use | Carry limit |
| --- | --- | --- | --- |
| Olive-oil flask | 10 | Refill 50% fuel, or throw it to make a fire pool that lights an area for 20 s | 3 |
| Pomegranate | 15 | Restores 2 stars | 2 |
| Knucklebones | Free | Toss for a 4-tile noise | Unlimited |

## Depth for skilled players

Skilled players get depth from freedom, not bigger health bars. Every encounter has at least three solutions, and the game scores how you solved it. This is unchanged from the Persian version.

- **Three ways through every room:** ghost past unseen, trick the guards with lures, floors or fire, or duel. When you build a room, write down all three before placing anything.
- **Dawn Rank** at the end of each act scores time, times spotted, knock-outs versus guards ghosted, obols and damage taken. Ranks run C to S, plus *Orion* for a perfect ghost run under par time.
- **Challenge seals** are optional and shown on the star map: *Moth* — never let the torch burn out; *Shadow* — never raise the torch; *Hunter* — drop every guard with the environment; *Pilgrim* — buy nothing.
- **No minimap.** The star map only marks rooms where you've relit a lamp, so mapping costs you exposure.
- **Systems that talk to each other.** Guards react to lamps changing, alarm tripods light rooms, fountains hide footsteps, sparks feed fuel, armour weight breaks floors. The best "thinking" moments are solutions players find themselves.
- **Hard mode, "Hunter's Night":** a real-time clock (Orion sets in 15 minutes for the slice, 45 for the full game), half the oil, guards wake after 2 minutes, and awareness never fully resets.
- **Speedrun support:** an on-screen timer and an instant room restart.

## Art direction

Isometric pixel temples in the style of your reference board, played mostly by moonlight: marble and terracotta turn night-blue, your torch is the only warm colour, and red is always the enemy.

### Reference board

| Reference | What to take | What to leave |
| --- | --- | --- |
| Overgrown temple island with a pool and trees (pixel art) | The target look: chunky marble blocks, ivy taking over, water, a ruin that feels rugged rather than royal | Its daylight; ours is night |
| Temple card with a blue-and-gold meander frame (pixel art) | Marble with terracotta trim, pots on the steps, and the frame itself as the UI border style | — |
| Temple porch with statues, a fountain and a mosaic floor (painted) | Props and layout: statues, fountains, mosaic floors, broad steps | The painterly rendering |
| Acropolis landscape (painted) | The skyline and how temples stack on a hill, for the map and the dawn ending | The painterly rendering |

- The references are daytime scenes. At night the same buildings read in moonlight blues; the dawn ending is the moment the game finally looks like them.
- They look like watermarked stock images. Use them for mood only: don't trace them or ship them. The judges score "it's yours".

### Canvas and grid

| Setting | Value |
| --- | --- |
| Native resolution | 480×270, integer-scaled ×4 to 1920×1080 |
| Projection | 2:1 pixel isometric (lines step 2 px across, 1 px down) |
| Floor tile | 32×16 px diamond |
| Wall block | 32×32 px plus a 16 px cap; south-facing walls cut away to half height so they never hide the player |
| Column | 16 px wide, 48–64 px tall; fades to a dither while the player is behind it |
| Height step | 16 px per floor level; temple steps are 8 px |
| Facings | Draw two (front-right, back-right) and mirror for the other two. Movement is 8-way; the sprite snaps to the nearest diagonal |

One gotcha: mirroring swaps hands, so the torch jumps to the right hand. At 16 px nobody notices; if it bothers you, draw all four facings for Cedalion only.

### Colour rules

- **Colour is information.** Warm amber is your fire, cool blue is moonlight and the sky, red is the Scorpion Brotherhood and danger, a gold glint is loot.
- **Hue-shift every ramp.** Shadows lean blue-violet and highlights lean yellow. Never darken by adding black. Marble is the best canvas for this: it takes on whatever light hits it.
- **Never pure black in the world.** The darkest value is deep indigo so the game still reads on a projector. Black-figure black is for cutscenes and UI only.
- Keep the palette to about 32 colours:

| Role | Colours |
| --- | --- |
| Night and shadow | #0d0b1a, #1b1834, #2e3a5c |
| Moonlight | #7fa6d8, #cfe3ff |
| Torch fire | #7a2a1a, #e0782c, #ffc857, #fff1c1 |
| Marble and limestone | #7d776d, #b9b2a3, #e8e2d4 |
| Terracotta and clay | #8a3b22, #c0603a, #d9935f |
| Black-figure black (cutscenes, UI) | #1a1412 |
| Aegean blue and pool water | #2b5d8a, #4f8fbf, #5fb3b0 |
| Olive, cypress and ivy | #3a4a2a, #5d6b3a, #8c9a5b |
| Scorpion red | #8e1b2a, #c23b3b |
| Metals | #a8693a bronze, #b7c1c9 silver, #d9a43a gold |

### Sprite sizes

| Sprite | Size (px) |
| --- | --- |
| Cedalion | 16×24 |
| Watchman | 20×32 |
| Spearman | 20×34, plus spear |
| Hoplite | 28×36, plus shield |
| Alcyone | 18×30 |
| Phineus (seated) | 20×24 |
| Antares | 40×48 |
| Statue (on a plinth) | 20×40 |

Size tells the story: Cedalion is two-thirds of a Watchman's height and half a Hoplite's. Statues are drawn close to Hoplite size on purpose, so a still guard can hide among them. Run a silhouette test on the enemies too: fill each sprite solid black, and if you can't tell them apart, redesign.

### Cedalion's animations

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

That is about 87 frames per facing, so about 170 for Cedalion. Budget about 80 per guard type.

### Asset savers

- **Armour tiers by palette swap.** Draw armour once in a grey ramp; a shader maps it to bronze, silver or gold.
- **One sword animation.** The blade is a separate sprite on a hand anchor, in three lengths.
- **One guard body.** Watchmen, Spearmen and Hoplites share a rig; helmet, shield and weapon differ.
- **A modular temple kit.** Column, column drum (fallen), capital, architrave block, pediment, step, wall block. Temples are assembled from these, not drawn whole.
- **Normal maps only on marble, walls and big props.** Generate them with Laigter (free) so torchlight rakes across fluted columns and block joints. Characters stay flat for readability.

### Environment kit

- **Architecture:** Doric and Ionic colonnades, temple steps and porches, pediments with simple friezes, terracotta roof tiles, open courtyards, a round *tholos* temple on the summit; outside, rough cyclopean walls and a lion gate from the older age, plus a stepped tunnel down to an underground cistern.
- **Floors:** marble slabs, pebble and tile mosaics with meander borders, cracked variants of each (three plus broken).
- **Ruin layer:** fallen column drums, cracked plaster, broken roofs open to the sky, rubble, ivy and grapevines, olive and cypress trees in the courtyards.
- **Water:** pools and fountains in turquoise; running fountains hide footsteps.
- **Story props:** vigil lamps still smoking, star frescoes scratched out and painted over with red scorpions, the broken bronze Star Engine, toppled statues, Alcyone's seven-dot marks.
- **Interactables:** amphorae and giant storage jars, cedar chests, wall lamps (lit and unlit), olive-oil jars, alarm tripods, bronze mirrors (Act II), Phineus's stall.

### Cutscenes and UI

- **Black-figure vase style** for the intro and act cards: black silhouettes on terracotta, framed by a meander border, animated as if the vase turns. Two colours and silhouettes only, so it's cheap to draw.
- **HUD:** health as stars, fuel as the flame of a small terracotta oil lamp, obols as a coin count.
- **Frames and menus** borrow the blue-and-gold meander border from your second reference.
- **Star map** drawn as the bronze dial of the Star Engine.
- **Font:** a readable pixel font; no fake Greek letters.

### Tools

- Aseprite (about $20, or free if you compile it yourself), or the free Pixelorama or LibreSprite.
- Laigter for normal maps, Lospec for palettes, and Godot's built-in tile editor for levels.
- A pixel font with a clear licence, such as Daniel Linssen's free m5x7, credited.

Every tool, price and free asset source, with the cheapest pipeline: [Tools and assets](TOOLS.md)

## Lighting design

Lighting is Godot 2D lights over a dark base, drawn as banded pixel shapes so the light itself looks hand-made. Exposure is computed in script, never read back from pixels. The rig matches the Persian version; colonnades and marble give it more to work with.

### The light rig

| Layer | Godot node | Colour | Notes |
| --- | --- | --- | --- |
| Ambient base | CanvasModulate | Interior #1b1834 (about 10% brightness); courtyards #4a5a8a | Tween to dawn (#f0c8a0) for the ending |
| Player torch | PointLight2D + flicker script | #ffb45a | 48 / 96 / 144 px by torch state; casts shadows; light height set for normal maps |
| Wall lamps | PointLight2D | #ff9d4a | 64 px; lit and unlit states; one shared texture |
| Moonlight | PointLight2D through roof gaps and courtyards, an additive shaft sprite and dust particles | #7fa6d8 | Column occluders cut it into stripes |
| Guard lanterns | PointLight2D with a shaped texture | #ffcf7a | The texture is the vision area: cone (Watchman), circle (Spearman), square (Hoplite) |
| Scorpion tripods | PointLight2D | #e04a3a | Red always means enemy |
| Pool reflections | A shader on water tiles | Takes the colour of nearby lights | Water ripples whatever light is near it; cheap and very pretty |
| Sparks | PointLight2D that lives 0.1 s | #fff1c1 | Spawned on clashes and parries |

### Making light look like pixel art

- **Draw the light textures yourselves:** a radial gradient cut into 4 hard bands, with a 1-pixel dither between bands. Light then falls off in visible steps, like the rest of the art.
- **Render at 480×270 and scale up,** so light edges stay pixel-sharp.
- **Flicker with noise, not a sine wave.** Vary energy ±8% and scale ±4% with FastNoiseLite at about 10 Hz, plus a 1-pixel jitter.
- **Loot glints only when lit.** A canvas shader's `light()` function makes obols, gold and bronze sparkle when your torch touches them, which rewards exploring.
- **Marble takes the light's colour.** With normal maps on fluted columns, a torch passing a colonnade sweeps warm highlights down each flute. This is the single best-looking effect for its cost.

### Shadows

- Put LightOccluder2D on column bases, statue plinths and low walls, using footprint polygons. Isometric shadows are cast in screen space, so tall occluders look wrong.
- Cast shadows only from the player torch, the moonlight in key courtyards and a few set pieces. Shadows are the expensive part, especially in a web build.
- A column's or statue's shadow hides you from a guard's lantern. That's a free stealth mechanic once occluders exist.

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
e *= armour.shine  # 1.3 for Dendra plate, 1.0 otherwise
```

A guard sees you when you're inside his cone, the line is clear, and distance < cone\_range × (0.4 + exposure). His awareness then rises by 60 × exposure × (1 − distance / range) per second.

### The projector problem

- Judges will probably watch on a projector or a bright laptop, and both wash out dark scenes. Plan for it now.
- Add a brightness slider and a "Demo" preset that raises ambient light by 15%.
- Give characters a 1-pixel rim in the light's colour on their lit side, so they read against dark floors. Pale marble helps here: lit floors read well even on weak screens.
- Test on the real demo screen at least once before judging.
- For the web build, keep about 8–12 lights on screen and test it early.

## Sound and music

Sound is the player's sight in the dark. Guards are heard before they're seen, silence is a mechanic, and the music rises with the guards' awareness. The system is unchanged; the instruments, modes and sounds become Greek.

### Adaptive music

Four stems of the same length and tempo play in lockstep, and the mix follows the highest awareness among nearby guards. Godot 4.3+ has AudioStreamSynchronized for this; fade each stem in or out over about 1 s.

| Stem | Instruments | Plays when |
| --- | --- | --- |
| Drone | Aulos drone pipe and low bowed strings on D | Always, very quiet |
| Theme | Lyre or kithara melody | Exploring |
| Tension | Frame drum (*tympanon*) and wooden clappers (*krotala*) | Any guard is suspicious |
| Combat | Fast frame drum, a piercing aulos line, low strings | Any guard is alerted |

Keep exploration sparse and acoustic. Long stretches of drone, sea and room tone make the stingers land, and keep the sound away from the rock-heavy Greek style Hades is known for.

### Modes and motifs

- **Home and hope:** D Dorian (D E F G A B C), a minor scale with a brighter sixth.
- **Danger:** D Phrygian (D E♭ F G A B♭ C), dark because of the flat second.
- **Antares:** D Phrygian dominant (D E♭ F♯ G A B♭ C), known in Greek folk music as the *Hitzaz* mode.
- The ancient Greek scales with these names were different; these are the modern modes, used for flavour.
- **Three leitmotifs:** Cedalion (four rising lyre notes), Alcyone (seven notes, one per Pleiad, bold and rhythmic, plays near her marks), Antares (a falling chromatic line).
- **No musician?** Compose in BeepBox or JummBox in D Dorian and D Phrygian. An "8-bit lyre" sound is unusual and matches the pixel art.
- **Want real instruments?** Use LMMS (free) with free sampled harps and reeds in Decent Sampler.

### Sound effects

| Group | Sounds | What it tells the player |
| --- | --- | --- |
| Footsteps | Marble, mosaic, sand, packed earth, plus an armour layer (linen rustle, cuirass clank, Dendra plate clatter) | How loud you are; where guards are in the dark |
| Torch | Ignite whoosh, crackle loop, sputter when low, snuff hiss, Ember flight | Fuel left, without looking at the HUD |
| Sword | Three swing variants, bronze-on-bronze clash, parry "ting", riposte hit, shield thud | Timing; the parry "ting" must be the brightest sound in the game |
| Telegraphs | High chime for a white glint, low drum for a red glint | Parry or dodge, by ear |
| World | Amphora crack, storage-jar boom, obol jingle that rises in pitch along a chain, chest creak, marble groan and collapse, vines burning, fountain splash | Risk and reward |
| Guard barks | "Ti?" ("What?", suspicious), "Ekei!" ("There!", alert), "Pou?" ("Where?", searching) | Each guard's awareness state |
| Ambience | Sea surf at the foot of the walls, wind through broken roofs, cistern drips, a little owl (Athena's bird), room tone | Space, height and isolation |
| Phineus | Slow, pitched gibberish syllables | Character without voice acting |

The barks are simple Greek words, but ancient and modern Greek differ; check them with a Greek speaker or use gibberish.

### Mix tricks

- Shrouding the torch puts a low-pass filter on the music and ambience buses, like holding your breath.
- A short lyre-and-drum stinger plays the moment a guard goes to alert.
- A heartbeat layer plays at 1 star.
- Guard footsteps are positional and audible beyond the light, so players learn to listen.
- Fountains play a looping splash that visibly and audibly marks the safe, noise-masked zone.
- Use AudioStreamRandomizer for pitch and volume variation on every repeated sound.

### Tools

- jsfxr or ChipTone (free, in the browser) for retro effects; Audacity for editing.
- Freesound, filtered to CC0, for sea and wind ambience. Credit sources and check the hackathon's rules on outside assets.
- Phone foley works well: keys for armour, a flowerpot tapped or dropped for pottery, celery for hits, rice on cardboard for footsteps, a struck match for the torch.

## Controls

Keyboard and mouse is the main scheme for the demo; gamepad support comes almost free in Godot's input map. Teach each control in the world, one at a time, through the prompt glyphs. Only the thrown item's name changes from the Persian version.

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
| Toss knucklebones | G, toward the cursor | Flick the right stick |
| Star map, pause | Tab, Esc | Back, Start |
| Debug overlay (dev builds) | F3 | — |

## Tech plan

Use Godot 4.3 or newer with GDScript. It has the strongest 2D lighting and isometric tiles of the free engines, it's light enough for two people, and it exports a web build judges can play in a browser. This is unchanged except for prop names, plus two small systems the Greek setting adds: fountains and statues.

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
├─ levels/       lion_gate.tscn, cistern.tscn, rooms/
├─ props/        amphora, storage_jar, chest, wall_lamp, cracked_floor, vine, oil_jar,
│               alarm_tripod, door, fountain, statue, column
├─ ui/           hud, star_map, merchant, prompts, title, vase_cutscene
├─ art/          sprites, tiles, temple kit, light textures, normal maps
├─ audio/        music stems, sfx, ambience
└─ debug/        overlay.tscn (F3)
```

### Core systems

| System | Built from | Job |
| --- | --- | --- |
| Player | CharacterBody2D + state machine | Movement, combat, torch states, the Ember |
| Guard AI | CharacterBody2D + NavigationAgent2D + state machine | Patrol, react, fight; a shared "attack token" lets only one guard attack at a time |
| Perception | Script on each guard | Sight from cone + raycast + exposure; hearing from the NoiseBus |
| LightRegistry | Autoload | Tracks every light for the exposure maths, and tells guards when a lamp changes |
| NoiseBus | Autoload with one signal, `noise(position, radius, source)` | Every loud action calls it; guards in range react |
| Fountain zones | Area2D on each fountain | Sets the player's footstep noise to 0 inside the zone |
| Statues | StaticBody2D + LightOccluder2D | Block sight lines; a guard can idle in a statue pose |
| Interactable | Area2D component with two radii | The notice glyph and button prompt, reused everywhere |
| Gear and enemy data | Custom Resources (.tres files) | Tune numbers without touching code |
| AudioDirector | Autoload | Mixes music stems from the highest awareness; plays stingers |
| Saving | JSON in `user://`, written at relit lamps | Checkpoints |
| Debug overlay | A scene toggled with F3 | Draws vision cones, noise rings, exposure and AI states — also a demo tool for the technical score |

### Isometric gotchas

- Use a TileMapLayer with tile shape Isometric, layout Diamond Down, size 32×16, and Y-sort enabled on the parent. Put each wall tile's and column's Y-sort origin at its base.
- Columns and walls in front of the player: cut south walls away permanently, and fade columns with a dither shader while the player is behind them. Colonnades make this essential, not optional.
- Use one TileMapLayer per floor, offset 16 px up. Stairs, temple steps and ladders switch the player's collision layer.
- Movement input is screen-relative. Halve vertical speed if diagonal movement feels too fast on the 2:1 grid.
- For pathfinding, bake a NavigationRegion2D from the tiles, or use AStarGrid2D, which supports isometric cells.

### Working as two

- Use Git and GitHub from the first hour, with Godot's .gitignore (it ignores the `.godot/` folder).
- Godot scene files merge badly. Split the game into many small scenes, and let only one person edit a scene at a time.
- Commit small and often, and tag every build you might demo.

## Hackathon scope

Ship one polished 10–15 minute slice — the Lion Gate and the Cistern, ending on the first Belt Star — not three rough acts. Judges reward "fun to pick up and play" far more than content they'll never reach.

### What's in the slice

| Priority | Features |
| --- | --- |
| Must | Isometric movement with fixed jumps and ledges; columns that fade when you're behind them; torch with three sizes; darkness inside; Watchman and Spearman with lantern vision and awareness meters; attack, parry, dodge, shove; telegraph glints; cracked marble; pottery, chests and obols; Phineus selling 2 swords and 2 armour sets; the Ember (plant and recall); interaction prompts; decorative ivy; the Lion Gate and 5 rooms; title screen and end card; core sound effects and one music loop; brightness slider |
| Should | Hoplite; torch-thrust stun; fuel, with relit lamps as checkpoints; noise rings and knucklebones; fountains that hide footsteps; statues as cover; Ember Step as the end reward; adaptive music stems; normal-mapped marble; Dawn Rank screen; debug overlay |
| Could | Third sword and armour; disguise; alarm tripods; climbable vines; "statue or guard?"; Alcyone's seven-dot secrets; star map; black-figure vase intro; hard mode |
| Won't, this hackathon | Acts II and III, mirror puzzles, Shades, Antares, Focus and Flare, mobile controls, a full save system |

### The slice, room by room

1. **The Lion Gate** (moonlit cyclopean walls): sneak with the torch shrouded, shove a Watchman into the well, take his short sword and tunic, see the gate's glyph from afar, then "Enter".
2. **The colonnade:** the screen goes dark except your torch and stripes of moonlight between the columns. Learn the torch sizes, lamps and pottery, and parry your first Watchman.
3. **Storerooms** (rows of giant storage jars): plant the Ember to light a dark room from a distance, then recall it. Lure a guard across cracked marble.
4. **Phineus's cistern,** down a stepped tunnel: a safe room — save, shop, choose a loadout, hear a prophecy.
5. **The statue court:** the exam. Two Watchmen and a Spearman among statues, with a fountain to hide your footsteps. Ghost, trick or duel.
6. **The star shrine:** take the first Belt Star and gain Ember Step, then use it to escape as the floor collapses behind you. End card in vase-painting style with your Dawn Rank: "Orion is sinking."

### Who builds what

| Area | Person A: gameplay code | Person B: art, audio, levels, UI |
| --- | --- | --- |
| Player | Controller, states, combat, the Ember | Sprites and animations |
| Guards | AI, perception, attack token | Sprites, silhouettes, barks |
| World | Cracked floors, lamps, noise, fountains, exposure maths | Temple kit, tiles, light textures, normal maps, props |
| Levels | Scripted events, triggers | Room layouts built in the editor |
| UI and audio | Merchant logic, saving, debug overlay | HUD, merchant screen, vase-painting cards, music, sound effects |

Both of you: design decisions, room layouts drawn on paper first, and a 15-minute playtest every day. If you both code, split by systems instead: one takes player, combat and guards; the other takes lights, props, interactables, UI and audio.

Art is the bottleneck, and temples are big. Start every system with coloured grey-box diamonds and grey pillars, and swap in the temple kit once the mechanic is fun.

## Build roadmap

![Build roadmap: five phases, four gates, two lanes](images/build-roadmap.png)

If a gate fails, fix that phase before starting the next one: a fun greybox matters more than finished art. With 48 hours the phases run in hours; with two weeks, in days. The phases match the Persian version; the art tasks now centre on the modular temple kit.

## Build estimate

The slice as this doc describes it takes about 170–240 hours of work between you: roughly 3–4 weeks at 4 hours a day each. A 48-hour hackathon fits a three-room micro-slice, not the whole thing.

These are rough estimates. They assume you're new to Godot but not to coding or drawing; if neither of you has drawn pixel art before, add about a third to the art hours. Re-estimate after the greybox phase, because how long it took is your best guide.

### Hours by work area

| Work area | Owner | Hours | Includes |
| --- | --- | --- | --- |
| Setup and isometric foundation | A | 6–8 | Project settings, tile layers, Y-sorting, camera, fading columns |
| Player controller | A | 8–12 | 8-way movement, run and sneak, fixed jumps, ledges, vines |
| Light and stealth systems | A | 14–18 | Torch sizes, flicker, fuel, exposure maths, lamps, noise, fountains, statues |
| Guard AI | A | 12–16 | Patrol, sight and hearing, awareness states, navigation, three guard types |
| Combat | A | 10–14 | Combo, parry, dodge, glints, hit-stop, attack token, shove, torch thrust |
| World interactions | A | 10–14 | The Ember, cracked floors, prompts, pottery and obols, checkpoints |
| Merchant, gear and game flow | A | 8–10 | Gear data and its effects, the shop, title, end card, Dawn Rank |
| Debug, builds and bug fixing | A | 8–12 | F3 overlay, desktop and web builds, fixes |
| **Code subtotal** | A | **76–104** |  |
| Tiles and temple kit | B | 18–24 | Marble, mosaic and cracked floors; walls; cyclopean walls; columns, steps, pediments |
| Props | B | 8–12 | Amphorae, jars, chests, lamps, tripods, fountain, statues, ivy, trees |
| Cedalion's sprites | B | 18–25 | About 170 frames |
| Guards and Phineus | B | 22–30 | About 80 frames per guard type on one shared rig |
| UI and vase-painting cards | B | 8–12 | HUD, prompts, merchant screen, title, end card |
| Level building | B | 10–14 | The Lion Gate and 5 rooms, with lights and occluders placed |
| Music and sound | B | 12–16 | Four music stems, about 40 sound effects |
| **Art and audio subtotal** | B | **96–133** |  |
| **Total** | Both | **172–237** |  |

Art carries about a third more work than code. Once the core systems are done, move level building or the UI to Person A to even it out.

Spread over the roadmap, about 200 hours works out to roughly 30 for the greybox, 50 for the core loop, 60 for content, 40 for polish and 20 for demo prep.

### What fits in the time you have

| Time you have | Team hours | What fits |
| --- | --- | --- |
| A 48-hour hackathon | About 50–60 (sleep, food and judging take the rest) | A micro-slice: the Lion Gate, the colonnade and the statue court; Watchman and Spearman; torch sizes, exposure, the Ember (plant and recall), cracked floors, pottery and obols; simple sprites (about 60 frames for Cedalion); one music loop; no merchant, or a 2-item one |
| 1 week at about 4 h a day each | About 55 | The same micro-slice with more polish |
| 2 weeks at about 5 h a day each | About 140 | The Must list: all 6 rooms, Phineus and the gear choice, final art for Cedalion and two guard types |
| 3–4 weeks at about 4 h a day each, or 2–3 weeks full time | About 170–240 | Must plus Should: the slice exactly as this doc describes it |

### What to cut first

If time runs short, cut in this order. Agree on it now, not at 3 a.m.

1. The Hoplite (keep Watchman and Spearman).
2. Adaptive music stems (keep one loop).
3. Normal maps on marble.
4. Dawn Rank and the debug overlay's extras.
5. Rooms 3 and 6, and Ember Step.
6. Phineus's shop (keep the stolen sword and tunic only).

Never cut the torch sizes, the exposure maths, the guard awareness meter or the moment the lights go out. Those are the game.

### What to do before you build

- [ ] Close the remaining open questions.
- [ ] Read the hackathon rules: its length, whether you can build before it opens, and whether outside or AI assets are allowed.
- [ ] Install Godot 4.3+, Aseprite or Pixelorama, Git and Laigter, and make a shared GitHub repo.
- [ ] Coder: do Godot's official "Your first 2D game" tutorial (about 3–4 hours), then a 2-hour isometric tile test.
- [ ] Artist: a one-day style test — one floor tile, one column and Cedalion's idle in two facings, lit by a torch inside Godot. It sets the look and proves the pipeline.
- [ ] Both: draw the rooms on paper, with three ways through each.
- [ ] Whoever does music: a 30-second lyre theme in BeepBox to set the mood.
- [ ] If building early isn't allowed, practise only on throwaway projects. Skills carry over; assets don't.

## Demo to the panel

Win the panel in three minutes: show the moment the lights go out, one clever solution and the debug overlay, then hand a judge the controls.

### Judging criteria, mapped

| Criterion | What the judges should see | When in the demo |
| --- | --- | --- |
| 01 Creativity | Light that cuts both ways; the Ember; you play Cedalion, the eyes of the blind hunter; the castle laid out as Orion; the sky as the clock; a princess who saves herself | 0:00–0:20 and 1:20–1:40 |
| 02 Gameplay experience | A tight loop of read, choose, act; three solutions per room; telegraphs a stranger can read | 0:40–1:40 and the hands-on |
| 03 Design quality | A palette with meaning (warm, cool, red), marble that takes the torch's colour, readable silhouettes, vase-painting cutscenes, music that reacts | Throughout; point out the music shift |
| 04 Technical implementation | Light exposure, noise propagation, guard state machines, isometric Y-sorting with fading columns, data-driven gear, a web build | 2:00–2:30 with the F3 overlay |

### Three-minute script

1. **0:00** Title: a black-figure vase turns, showing blind Orion carrying Cedalion toward the sunrise. One line: "Light lets you see. It also lets them see you."
2. **0:20** The Lion Gate: sneak with the torch shrouded, shove a Watchman into the well, take his sword.
3. **0:40** "Enter" — the screen goes dark except stripes of moonlight between the columns. Raise and shroud the torch to show the trade-off.
4. **1:00** Smash an amphora and a guard turns. Parry him, and the sparks light the colonnade.
5. **1:20** Plant the Ember as a lure, recall it, and walk the Spearman onto cracked marble.
6. **1:40** At Phineus's stall, hear a prophecy and explain the Dendra plate's trade-offs in one sentence.
7. **2:00** Press F3: vision cones, noise rings, the exposure value. Explain the system in two sentences.
8. **2:30** Hand a judge the controls in the statue court.

### Demo risks

| Risk | Fix |
| --- | --- |
| The projector washes out the dark | Demo brightness preset; test on the real screen beforehand |
| A bug or crash on stage | Demo from a tagged build; a debug room select (F1–F6) to jump to any room |
| The laptop or browser runs slowly | Desktop build as the main copy, web link as backup; cap lights on screen |
| The live demo fails completely | A 90-second recorded video as a fallback |
| Judges don't know the controls | Prompts in the world, plus a one-card control sheet on the table |

## Open questions

- [x] Greek or Persian? Compare this doc with the [Persian version](https://claude.ai/artifact/DkETn7xHUMDvHV2gPv3CLH) and pick one. Decided: Greek, on 18 Oct 2026.
- [ ] How long is the hackathon, and can you build anything before it opens? That sets the roadmap's real dates.
- [ ] Are outside assets (fonts, CC0 sounds) or AI-generated assets allowed? Your reference images look like stock pictures, so keep them as mood only.
- [ ] Who draws and who codes? Has either of you used Godot, Aseprite or a music tool before?
- [ ] Princess: Alcyone, Bellatrix, or another name? Is she Cedalion's sister or his betrothed? A sister reads better with a small prince.
- [ ] Villain: Antares (the scorpion that killed Orion) or Oenopion (the king who blinded him)?
- [ ] How mixed should the eras be: classical temples on older cyclopean walls, as written here, or one era throughout?
- [ ] Desktop and web only, or does Android matter? Touch controls would need their own design.
- [ ] Are the names Cedalion and Phineus final?
