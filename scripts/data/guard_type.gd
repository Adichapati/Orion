class_name GuardType
extends Resource
## Everything that makes a Watchman, Spearman or Hoplite different. Sight numbers match
## art/maps/rooms.json's guardTypes so the map mock-ups and the game agree.

@export var id: StringName
@export var display_name := ""
@export var hp := 3
## Tiles per second.
@export var walk_speed := 1.6
@export var chase_speed := 3.2
## Sight range in tiles and half-angle of the vision cone in degrees.
@export var sight_range := 5.0
@export var half_angle := 30.0
## Heavy guards break cracked marble at once.
@export var heavy := false
## Blocks every attack that comes from the front (unless stunned or the sword breaks shields).
@export var blocks_front := false
## Preferred fighting distance in tiles (the Spearman keeps his distance).
@export var keep_distance := 0.9
## AttackData resources.
@export var attacks: Array = []
@export var drop_min := 2
@export var drop_max := 5
@export var sprite_se := "watchman_se"
@export var sprite_ne := "watchman_ne"
@export var lantern_color := Color(1.0, 0.81, 0.48)
## Seconds a torch thrust stuns this guard.
@export var thrust_stun := 1.2
