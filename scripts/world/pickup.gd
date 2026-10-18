class_name Pickup
extends Node2D
## An obol (or the dropped sword) that hops out of a pot, chest or guard and is collected by
## walking over it.

var kind := "obol"
var amount := 1
var room: Node
var _sprite: Sprite2D
var _vel := Vector2.ZERO
var _height := 0.0
var _vz := 0.0
var _settled := false
var _life := 0.0


func setup(p_room: Node, p_kind: String, p_amount: int, launch_dir: Vector2) -> Pickup:
	room = p_room
	kind = p_kind
	amount = p_amount
	_vel = Iso.grid_to_screen(launch_dir) * randf_range(0.8, 1.6)
	_vz = randf_range(55.0, 80.0)
	return self


func _ready() -> void:
	_sprite = Art.feet_sprite("obol" if kind == "obol" else "sword_drop")
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_life += delta
	if not _settled:
		position += _vel * delta
		_vel *= 0.9
		_vz -= 260.0 * delta
		_height = maxf(0.0, _height + _vz * delta)
		if _height <= 0.0 and _vz < 0.0:
			if absf(_vz) > 40.0:
				_vz = -_vz * 0.35
			else:
				_settled = true
				_height = 0.0
		_sprite.position.y = -_height
	if _life < 0.35 or room == null or room.player == null:
		return
	if Iso.tiles_between(global_position, room.player.global_position) < 0.75:
		_collect()


func _collect() -> void:
	if kind == "obol":
		Game.add_obols(amount, global_position + Vector2(0, -12))
		Sfx.play("coin", null, -4.0, 0.12)
	elif kind == "sword":
		if Game.weapon_id == "":
			Game.give_weapon("xiphos")
			Game.toast.emit("You take the Watchman's short sword. Attack: left click or J.")
			Sfx.play("pickup")
	queue_free()
