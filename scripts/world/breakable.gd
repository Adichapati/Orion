class_name Breakable
extends Node2D
## Amphorae (one hit, 1–3 obols) and giant storage jars (two hits, 5–8 obols). Smashing either
## is loud: a 6-tile noise that every guard in range turns toward.

var room: Room
var cell := Vector2i.ZERO
var kind := "a"
var hits_left := 1
var _sprite: Sprite2D


func setup(p_room: Room, p_cell: Vector2i, p_kind: String) -> Breakable:
	room = p_room
	cell = p_cell
	kind = p_kind
	hits_left = 2 if kind == "J" else 1
	return self


func _ready() -> void:
	add_to_group("breakable")
	_sprite = Art.feet_sprite("jar" if kind == "J" else "amphora", 3)
	add_child(_sprite)
	# Smashed on an earlier visit: just shards, no obols, no noise.
	if Game.remembered(room.id, "broken", cell):
		hits_left = 0
		_shatter_sprite()
		var body := get_parent() as StaticBody2D
		if body:
			body.collision_layer = 0
		# the room is still being built: mark the cell, and its paths are built with it
		room._broken[cell] = true
		remove_from_group("breakable")


func _shatter_sprite() -> void:
	_sprite.texture = Art.tex("shards")
	_sprite.offset = Vector2(-8, -7)


func hit(_from: Vector2) -> void:
	if hits_left <= 0:
		return
	hits_left -= 1
	var pos: Vector2 = get_parent().global_position
	if hits_left > 0:
		Sfx.play("pot_crack", pos)
		var tw := create_tween()
		tw.tween_property(_sprite, "position", Vector2(1, 0), 0.04)
		tw.tween_property(_sprite, "position", Vector2(-1, 0), 0.04)
		tw.tween_property(_sprite, "position", Vector2.ZERO, 0.04)
		return
	Sfx.play("pot_smash", pos)
	NoiseBus.emit_noise(pos, 6.0, self)
	_shatter_sprite()
	Game.remember(room.id, "broken", cell)
	var amount := randi_range(5, 8) if kind == "J" else randi_range(1, 3)
	room.spawn_obols(pos, amount)
	var body := get_parent() as StaticBody2D
	if body:
		body.collision_layer = 0
	room.on_broken(cell)
	remove_from_group("breakable")


func is_intact() -> bool:
	return hits_left > 0
