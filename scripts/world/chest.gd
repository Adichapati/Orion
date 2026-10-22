class_name Chest
extends Node2D
## A cedar chest. Hold interact for 1.5 s to open it; the lid makes a 3-tile noise.

var room: Room
var cell := Vector2i.ZERO
var _sprite: Sprite2D
var _it: Interactable


func setup(p_room: Room, p_cell: Vector2i) -> Chest:
	room = p_room
	cell = p_cell
	return self


func _ready() -> void:
	_sprite = Art.feet_sprite("chest", 3)
	add_child(_sprite)
	_it = Interactable.new().setup("Open", "glyph_coin", 22.0, 1.5)
	add_child(_it)
	room.interactables.append(_it)
	_it.used.connect(_open)
	# Opened on an earlier visit: it stays open and empty.
	if Game.remembered(room.id, "opened", cell):
		_it.enabled = false
		_sprite.texture = Art.tex("chest_open")


func _open(_p: Node) -> void:
	_it.enabled = false
	_sprite.texture = Art.tex("chest_open")
	Game.remember(room.id, "opened", cell)
	var pos: Vector2 = get_parent().global_position
	Sfx.play("chest", pos)
	NoiseBus.emit_noise(pos, 3.0, self)
	room.spawn_obols(pos + Vector2(0, 4), randi_range(10, 25))
