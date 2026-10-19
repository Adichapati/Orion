class_name MessageCard
extends Control
## A short full-screen message (the death card): fades in, holds, emits `done`, then fades out.
## Above the words a torch gutters and goes out, and its smoke curls away.

signal done

var text := ""
var sub := ""
var hold := 1.6
var _t := 0.0
var _art: Control


func setup(p_text: String, p_sub := "", p_hold := 1.6) -> MessageCard:
	text = p_text
	sub = p_sub
	hold = p_hold
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.backdrop(0.85))
	_art = Control.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.draw.connect(_draw_torch)
	add_child(_art)
	var c := UiKit.center()
	add_child(c)
	var v := UiKit.vbox(10)
	c.add_child(v)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 70)
	v.add_child(gap)
	v.add_child(UiKit.label(text, 30, UiKit.RED, HORIZONTAL_ALIGNMENT_CENTER))
	if sub != "":
		v.add_child(UiKit.label(sub, 16, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.4)
	tw.tween_interval(hold)
	tw.tween_callback(func(): done.emit())
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_art.queue_redraw()


func _draw_torch() -> void:
	# A torch in 2x pixels, centred above the words: the flame gutters and dies over ~0.9 s.
	_art.draw_set_transform(Vector2(480, 226), 0.0, Vector2(2, 2))
	_art.draw_rect(Rect2(-1, 0, 3, 18), Color(0.42, 0.26, 0.16))
	_art.draw_rect(Rect2(-1, 0, 1, 18), Color(0.55, 0.36, 0.22))
	_art.draw_rect(Rect2(-2, -2, 5, 3), Color(0.25, 0.16, 0.12))
	var life := clampf(1.0 - (_t - 0.3) / 0.9, 0.0, 1.0)
	if life > 0.0:
		var flick := sin(_t * 31.0) * 0.5 + sin(_t * 17.0) * 0.5
		var hgt := roundf((4.0 + 6.0 * life) * (0.85 + 0.15 * flick))
		var w := 2.0 if life < 0.4 else 4.0
		_art.draw_rect(Rect2(-w / 2.0 + 0.5, -2 - hgt, w, hgt), Color(1.0, 0.55, 0.22, life))
		_art.draw_rect(Rect2(0, -2 - hgt * 0.7, 1, hgt * 0.6), Color(1.0, 0.9, 0.6, life))
	else:
		# Ember and smoke.
		var since := _t - 1.2
		_art.draw_rect(Rect2(0, -3, 1, 1), Color(1.0, 0.4, 0.15, clampf(1.0 - since, 0.0, 1.0)))
		for k in 6:
			var y := -4.0 - k * 3.0 - roundf(since * 8.0)
			var x := roundf(sin(since * 2.5 + k * 0.9) * (1.0 + k * 0.5))
			var a := clampf(0.5 - since * 0.2, 0.0, 0.5) * (1.0 - k / 7.0)
			_art.draw_rect(Rect2(x, y, 1, 1), Color(0.7, 0.68, 0.75, a))
	_art.draw_set_transform(Vector2.ZERO)
