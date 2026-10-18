class_name ArmourData
extends Resource
## Armour trades protection for noise and weight.

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var price := 0
## Extra stars of health.
@export var hp_bonus := 0
## Extra footstep noise radius in tiles while moving.
@export var noise_bonus := 0.0
## Heavy armour breaks cracked marble at once and can't climb.
@export var heavy := false
