class_name IntroCards
extends Control
## Three short story cards before the first room. Any key or click advances; Esc skips.

signal finished

const CARDS := [
	"On the longest night of the year, every lamp in the Star Citadel burns until dawn, for the blind hunter who walked toward the sun.",
	"At midnight Antares and the Scorpion Brotherhood climbed the walls, snuffed the vigil and dragged Princess Alcyone to the summit.",
	"You are Cedalion, the smallest prince, carrying the last flame. Find the three Belt Stars before Orion sets.",
]
const INK := Color(0.07, 0.04, 0.03)

var _i := 0
var _label: Label
var _t := 0.0
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.36, 0.17, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	add_child(bg)
	var c := UiKit.center()
	add_child(c)
	_label = UiKit.label("", 20, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(620, 0)
	c.add_child(_label)
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


func _draw() -> void:
	VaseBorder.draw_on(self, INK)


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
