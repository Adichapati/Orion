class_name AttackData
extends Resource
## One guard attack. A white glint means it can be parried; a red glint means dodge.

@export var id: StringName
## Seconds of wind-up while the glint shows.
@export var windup := 0.6
## Seconds the guard needs to recover after striking.
@export var recover := 0.6
## Reach in tiles.
@export var reach := 1.1
## Half-angle of the strike arc, in degrees.
@export var half_angle := 60.0
@export var damage := 1
@export var parryable := true
## Tiles of knockback on a hit.
@export var knockback := 0.5
## How likely the guard is to pick this attack (relative weight).
@export var weight := 1.0
