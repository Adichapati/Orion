class_name Interactable
extends Node2D
## The two-range interaction prompt from the design doc: a glyph floats over the object from
## 5 tiles away, and within reach the HUD shows "E — <verb>". Doors, chests, the weapon rack,
## the altar, Alcyone's marks and Phineus all use it.

signal used(player: Node)

var verb := "Use"
var glyph := "glyph_hand"
var notice_range := 5.0
var interact_range := 1.3
## Seconds the button must be held (chests). 0 = a single press.
var hold_time := 0.0
var glyph_height := 26.0
var enabled := true

var _glyph: Sprite2D
var _t := 0.0


func setup(p_verb: String, p_glyph: String, p_height := 26.0, p_hold := 0.0) -> Interactable:
	verb = p_verb
	glyph = p_glyph
	glyph_height = p_height
	hold_time = p_hold
	return self


func _ready() -> void:
	add_to_group("interactable")
	_glyph = Sprite2D.new()
	_glyph.texture = Art.tex(glyph)
	_glyph.position = Vector2(0, -glyph_height)
	_glyph.z_index = 60
	_glyph.visible = false
	add_child(_glyph)


func refresh(player_ground: Vector2) -> void:
	if not enabled:
		_glyph.visible = false
		return
	var d := Iso.tiles_between(global_position, player_ground)
	_glyph.visible = d <= notice_range
	_glyph.modulate = Color(1, 1, 1, 1.0 if d <= interact_range else 0.6)


func in_reach(player_ground: Vector2) -> bool:
	return enabled and Iso.tiles_between(global_position, player_ground) <= interact_range


func use(player: Node) -> void:
	if enabled:
		used.emit(player)


func _process(delta: float) -> void:
	_t += delta
	if _glyph.visible:
		_glyph.position.y = -glyph_height + roundf(sin(_t * 3.0) * 1.5)
