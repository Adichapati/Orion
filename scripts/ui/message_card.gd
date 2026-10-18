class_name MessageCard
extends Control
## A short full-screen message (the death card): fades in, holds, emits `done`, then fades out.

signal done

var text := ""
var sub := ""
var hold := 1.6


func setup(p_text: String, p_sub := "", p_hold := 1.6) -> MessageCard:
	text = p_text
	sub = p_sub
	hold = p_hold
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.backdrop(0.85))
	var c := UiKit.center()
	add_child(c)
	var v := UiKit.vbox(10)
	c.add_child(v)
	v.add_child(UiKit.label(text, 28, UiKit.RED, HORIZONTAL_ALIGNMENT_CENTER))
	if sub != "":
		v.add_child(UiKit.label(sub, 15, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.4)
	tw.tween_interval(hold)
	tw.tween_callback(func(): done.emit())
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
