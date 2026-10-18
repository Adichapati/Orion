class_name EndCard
extends Control
## The Dawn Rank card after the star shrine, in the colours of a black-figure vase.

signal to_title

const INK := Color(0.07, 0.04, 0.03)

var rank := {}
var _v: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	rank = Game.dawn_rank()
	var bg := ColorRect.new()
	bg.color = Color(0.36, 0.17, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	add_child(bg)
	var c := UiKit.center()
	add_child(c)
	_v = UiKit.vbox(8)
	c.add_child(_v)
	_line("The first Belt Star", 18)
	_line("Orion is sinking. Alcyone waits at the summit.", 16)
	_line("Dawn Rank: %s" % rank.grade, 40, Color(0.98, 0.88, 0.62))
	_line("Score %d" % rank.score, 16)
	_line("Time %s   ·   Spotted %d   ·   Knock-outs %d (%d by the world)" % [rank.time, rank.spotted, rank.kos, rank.env_kos], 15)
	_line("Guards ghosted %d   ·   Obols found %d   ·   Stars lost %d   ·   Marks read %d" % [rank.ghosted, rank.obols, rank.damage, rank.marks], 15)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	_v.add_child(gap)
	var b := UiKit.button("Back to the title")
	b.pressed.connect(func(): to_title.emit())
	_v.add_child(b)
	b.grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.0)


func _line(t: String, size: int, col := INK) -> void:
	var x := UiKit.label(t, size, col, HORIZONTAL_ALIGNMENT_CENTER)
	x.add_theme_constant_override("outline_size", 0 if col == INK else 4)
	_v.add_child(x)


func _draw() -> void:
	VaseBorder.draw_on(self, INK)
