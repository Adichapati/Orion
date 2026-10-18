class_name WeaponData
extends Resource
## A sword Cedalion can carry. Sidegrades, not upgrades: each one is best at something.

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var price := 0
@export var damage := 1
## Seconds from pressing attack to the next swing being possible.
@export var swing_time := 0.4
## How far the blade reaches, in tiles.
@export var reach := 1.0
## Seconds the parry stays active after pressing parry.
@export var parry_window := 0.12
## Knocks out any unaware guard from behind in one hit.
@export var backstab_ko := false
## Can damage guards that block from the front.
@export var breaks_shields := false
