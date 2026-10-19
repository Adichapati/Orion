class_name IntroCards
extends Control
## Three short story cards before the first room, on a black-figure vase. A glaze band above the
## words tells the story in lamps: the vigil burning, snuffed one by one under Antares, then only
## Cedalion's flame and the three Belt Stars. Any key or click advances; Esc skips.

signal finished

const CARDS := [
	"On the longest night of the year, every lamp in the Star Citadel burns until dawn, for the blind hunter who walked toward the sun.",
	"At midnight Antares and the Scorpion Brotherhood climbed the walls, snuffed the vigil and dragged Princess Alcyone to the summit.",
	"You are Cedalion, the smallest prince, carrying the last flame. Find the three Belt Stars before Orion sets.",
]
const INK := Color(0.07, 0.04, 0.03)
const CLAY := Color(0.62, 0.31, 0.15)
const CLAY_LIGHT := Color(0.86, 0.5, 0.26)
const FLAME := Color(1.0, 0.78, 0.36)
const BAND := Rect2(60, 112, 840, 120)
const LAMPS := 9

var _i := 0
var _label: Label
var _t := 0.0
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = UiKit.label("", 20, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.position = Vector2(170, 270)
	_label.size = Vector2(620, 0)
	_label.custom_minimum_size = Vector2(620, 0)
	add_child(_label)
	var hint := UiKit.label("Press any key", 12, Color(0.85, 0.6, 0.4), HORIZONTAL_ALIGNMENT_CENTER)
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	hint.position = Vector2(380, 450)
	hint.size = Vector2(200, 20)
	add_child(hint)
	_show()


func _show() -> void:
	_label.text = CARDS[_i]
	_label.modulate.a = 0.0
	_t = 0.0
	create_tween().tween_property(_label, "modulate:a", 1.0, 0.6)


func _process(delta: float) -> void:
	_t += delta
	if _t > 9.0:
		_advance()
	queue_redraw()


func _draw() -> void:
	VaseBorder.draw_ground(self, 300.0)
	VaseBorder.draw_on(self, INK)
	draw_rect(BAND, INK)
	draw_rect(Rect2(BAND.position.x, BAND.position.y + 5, BAND.size.x, 2), CLAY)
	draw_rect(Rect2(BAND.position.x, BAND.end.y - 7, BAND.size.x, 2), CLAY)
	var now := Time.get_ticks_msec() / 1000.0
	for i in LAMPS:
		var x := 120.0 + i * 90.0
		var lit := 1.0
		if _i == 1:
			# Snuffed from the right, one every quarter second.
			lit = 1.0 if _t < 0.6 + (LAMPS - 1 - i) * 0.25 else 0.0
		elif _i == 2:
			lit = 1.0 if i == LAMPS / 2 and _t > 0.5 else 0.0
		_lamp(Vector2(x - 2, BAND.end.y - 32), lit, now + i * 1.7, _i == 1 and lit == 0.0, _t - (0.6 + (LAMPS - 1 - i) * 0.25))
	if _i == 1:
		# Antares rises red once the vigil is dark.
		var a := clampf((_t - 2.9) * 1.5, 0.0, 1.0)
		if a > 0.0:
			_star(Vector2(480, BAND.position.y + 40), 4, Color(1.0, 0.3, 0.22, a * (0.85 + 0.15 * sin(now * 4.0))))
	elif _i == 2:
		# The three Belt Stars over the last flame, one after another.
		for k in 3:
			var a := clampf((_t - 1.0 - k * 0.4) * 3.0, 0.0, 1.0)
			if a > 0.0:
				_star(Vector2(444 + k * 36, BAND.position.y + 44 - k * 10), 2, Color(0.85, 0.92, 1.0, a))


## A clay oil lamp reserved out of the glaze, with a flickering flame or, just snuffed, a curl of
## smoke.
func _lamp(at: Vector2, lit: float, seed: float, smoking: bool, since_out: float) -> void:
	# Drawn in 2x pixels like the rest of the UI.
	draw_set_transform(at.round(), 0.0, Vector2(2, 2))
	draw_rect(Rect2(-8, 0, 16, 6), CLAY)
	draw_rect(Rect2(-6, 6, 12, 2), CLAY)
	draw_rect(Rect2(8, 0, 6, 3), CLAY)
	draw_rect(Rect2(-12, -2, 4, 2), CLAY)
	draw_rect(Rect2(-12, 0, 2, 4), CLAY)
	draw_rect(Rect2(-6, 0, 10, 1), CLAY_LIGHT)
	draw_rect(Rect2(-2, 1, 4, 2), INK)
	if lit > 0.0:
		var hgt := 6.0 + roundf(1.5 * sin(seed * 9.0) + 0.8 * sin(seed * 23.0))
		draw_rect(Rect2(10, -hgt, 3, hgt), FLAME)
		draw_rect(Rect2(11, -hgt - 2, 1, 2), FLAME)
		draw_rect(Rect2(11, -hgt + 1, 1, hgt - 2), Color(1, 0.95, 0.75))
	elif smoking and since_out < 1.6:
		for k in 4:
			var y := -3.0 - k * 3.0 - roundf(since_out * 7.0)
			var x := 11.0 + roundf(sin(since_out * 5.0 + k))
			draw_rect(Rect2(x, y, 1, 1), Color(CLAY_LIGHT, 0.6 * (1.0 - since_out / 1.6)))
	draw_set_transform(Vector2.ZERO)


func _star(p: Vector2, r: int, col: Color) -> void:
	p = p.round()
	draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2, r * 2)), col)
	draw_rect(Rect2(p - Vector2(r * 3, 1), Vector2(r * 6, 2)), Color(col, col.a * 0.35))
	draw_rect(Rect2(p - Vector2(1, r * 3), Vector2(2, r * 6)), Color(col, col.a * 0.35))


func _advance() -> void:
	if _done:
		return
	_i += 1
	if _i >= CARDS.size():
		_done = true
		finished.emit()
		queue_free()
	else:
		_show()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_i = CARDS.size()
		_advance()
	elif (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) \
			and event.is_pressed() and not event.is_echo() and _t > 0.3:
		get_viewport().set_input_as_handled()
		_advance()
