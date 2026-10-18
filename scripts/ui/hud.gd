class_name Hud
extends Control
## The in-game HUD in 960x540 UI space: stars (health), pomegranates, obols, gear, toasts, the
## "E — verb" prompt with hold progress, floating texts and barks, and the room-name banner.
##
## World positions are mapped to UI space through `project` (set by main), so floating texts
## follow the camera.

const TOAST_TIME := 4.5
## The UI's fixed design size (project.godot's base viewport).
const W := 960.0
const H := 540.0

var project: Callable = func(p: Vector2) -> Vector2: return p
var player: Node = null

var _stars: HBoxContainer
var _pom: Label
var _obols: Label
var _gear: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _toasts: Array[String] = []
var _toast_t := 0.0
var _prompt: Label
var _hold: ProgressBar
var _banner: Label
var _floaters: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_left := UiKit.vbox(4)
	top_left.position = Vector2(16, 12)
	add_child(top_left)
	_stars = UiKit.hbox(2)
	top_left.add_child(_stars)
	_pom = UiKit.label("", 13, UiKit.DIM)
	top_left.add_child(_pom)

	var top_right := UiKit.hbox(6)
	top_right.position = Vector2(W - 196, 12)
	top_right.custom_minimum_size = Vector2(180, 24)
	top_right.alignment = BoxContainer.ALIGNMENT_END
	add_child(top_right)
	top_right.add_child(UiKit.icon("hud_obol", 2))
	_obols = UiKit.label("0", 18, UiKit.GOLD)
	top_right.add_child(_obols)

	_gear = UiKit.label("", 13, UiKit.DIM)
	_gear.position = Vector2(16, H - 30)
	add_child(_gear)

	_toast_panel = UiKit.panel(UiKit.INK)
	_toast_panel.visible = false
	add_child(_toast_panel)
	_toast_label = UiKit.label("", 15)
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.custom_minimum_size = Vector2(520, 0)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_panel.add_child(_toast_label)

	_prompt = UiKit.label("", 15, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_prompt.visible = false
	_prompt.size = Vector2(240, 22)
	add_child(_prompt)
	_hold = ProgressBar.new()
	_hold.show_percentage = false
	_hold.max_value = 1.0
	_hold.size = Vector2(60, 6)
	_hold.visible = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiKit.GOLD
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	_hold.add_theme_stylebox_override("fill", fill)
	_hold.add_theme_stylebox_override("background", bg)
	add_child(_hold)

	_banner = UiKit.label("", 30, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.position = Vector2(W / 2.0 - 300, 70)
	_banner.size = Vector2(600, 40)
	_banner.modulate.a = 0.0
	add_child(_banner)

	Game.health_changed.connect(func(_h, _m): _refresh())
	Game.obols_changed.connect(func(_o): _refresh())
	Game.gear_changed.connect(_refresh)
	Game.toast.connect(show_toast)
	Game.floating_text.connect(float_text)
	_refresh()


func _refresh() -> void:
	for c in _stars.get_children():
		c.queue_free()
	for i in Game.max_hp():
		_stars.add_child(UiKit.icon("hud_star" if i < Game.hp else "hud_star_empty", 2))
	_pom.text = "Pomegranates %d/%d  (H)" % [Game.pomegranates, Game.POMEGRANATE_LIMIT] if Game.pomegranates > 0 else ""
	_obols.text = str(Game.obols)
	var w := Game.weapon()
	var a := Game.armour()
	_gear.text = "%s  ·  %s" % [w.display_name if w else "No sword", a.display_name if a else ""]


func show_toast(text: String) -> void:
	if _toasts.has(text) or (_toast_panel.visible and _toast_label.text == text):
		return
	_toasts.append(text)
	if not _toast_panel.visible:
		_next_toast()


func _next_toast() -> void:
	if _toasts.is_empty():
		_toast_panel.visible = false
		return
	_toast_label.text = _toasts.pop_front()
	_toast_panel.visible = true
	_toast_panel.reset_size()
	_toast_panel.position = Vector2((W - _toast_panel.size.x) / 2.0, H - _toast_panel.size.y - 48)
	_toast_t = TOAST_TIME + _toast_label.text.length() * 0.02


func float_text(world_pos: Vector2, text: String, color: Color) -> void:
	var l := UiKit.label(text, 14, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.size = Vector2(160, 20)
	add_child(l)
	_floaters.append({"label": l, "pos": world_pos, "t": 0.0})


func show_banner(text: String) -> void:
	_banner.text = text
	var tw := create_tween()
	_banner.modulate.a = 0.0
	tw.tween_property(_banner, "modulate:a", 1.0, 0.5)
	tw.tween_interval(2.0)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.8)


func clear_transient() -> void:
	_toasts.clear()
	_toast_panel.visible = false
	for f in _floaters:
		f.label.queue_free()
	_floaters.clear()


func _process(delta: float) -> void:
	if _toast_panel.visible:
		_toast_t -= delta
		if _toast_t <= 0.0:
			_next_toast()
	for f in _floaters:
		f.t += delta
		var l: Label = f.label
		var p: Vector2 = project.call(f.pos)
		l.position = p + Vector2(-80, -20 - f.t * 24.0)
		l.modulate.a = clampf(2.0 - f.t * 1.6, 0.0, 1.0)
	for f in _floaters.filter(func(f): return f.t > 1.3):
		f.label.queue_free()
	_floaters = _floaters.filter(func(f): return f.t <= 1.3)
	_update_prompt()


func _update_prompt() -> void:
	var it: Interactable = null
	if player != null and is_instance_valid(player) and player.state != Player.S.LOCKED:
		it = player.focus
	if it == null or not is_instance_valid(it):
		_prompt.visible = false
		_hold.visible = false
		return
	var p: Vector2 = project.call(it.global_position + Vector2(0, -it.glyph_height - 10))
	_prompt.text = "E — %s" % it.verb + ("  (hold)" if it.hold_time > 0.0 else "")
	_prompt.position = p + Vector2(-120, -26)
	_prompt.visible = true
	_hold.visible = player.holding == it and player.hold_progress > 0.0
	_hold.value = player.hold_progress
	_hold.position = p + Vector2(-30, -2)
