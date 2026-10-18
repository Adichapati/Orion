class_name Knucklebone
extends Node2D
## A tossed knucklebone. Where it lands it makes a 4-tile noise that turns guards' heads.

var target := Vector2.ZERO
var start := Vector2.ZERO
var room: Room
var _t := 0.0
var _dur := 0.5
var _sprite: Sprite2D


func setup(p_room: Room, from_pos: Vector2, to_pos: Vector2) -> Knucklebone:
	room = p_room
	start = from_pos
	target = to_pos
	_dur = clampf(Iso.tiles_between(from_pos, to_pos) * 0.09, 0.25, 0.6)
	return self


func _ready() -> void:
	position = start
	_sprite = Sprite2D.new()
	_sprite.texture = Art.tex("knucklebone")
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / _dur, 0.0, 1.0)
	position = start.lerp(target, k)
	_sprite.position.y = -8.0 - sin(k * PI) * 22.0 * clampf(_dur / 0.45, 0.6, 1.3)
	_sprite.rotation += delta * 18.0
	if k >= 1.0:
		_land()


func _land() -> void:
	set_physics_process(false)
	_sprite.position.y = -1
	_sprite.rotation = 0
	Sfx.play("clack", position)
	NoiseBus.emit_noise(position, 4.0, self)
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
