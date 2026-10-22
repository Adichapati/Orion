extends Node
## Runs ORION: title → intro cards → the six rooms → the Dawn Rank card.
##
## The world renders into a 480x270 SubViewport shown at 2x; every Control lives on the UI
## CanvasLayer in 960x540 space. Main builds each room, spawns its guards and the player, and
## wires room, player and UI signals together.

const DEATH_LINES := [
	"The dark took you.",
	"A scorpion's sting.",
	"The vigil flame gutters.",
]

@onready var world_container: SubViewportContainer = $WorldContainer
@onready var world_viewport: SubViewport = $WorldContainer/WorldViewport
@onready var ui: CanvasLayer = $UI

var hud: Hud
var room: Room
var player: Player
var overlay: DebugOverlay
var _menu: Control = null
var _screen: Control = null
var _busy := false
var _fader: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world_container.process_mode = Node.PROCESS_MODE_PAUSABLE
	world_viewport.snap_2d_transforms_to_pixel = true
	world_viewport.snap_2d_vertices_to_pixel = true
	hud = Hud.new()
	hud.project = world_to_ui
	hud.visible = false
	ui.add_child(hud)
	_fader = ColorRect.new()
	_fader.color = Color(0.02, 0.02, 0.05, 0.0)
	_fader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fader.z_index = 100
	ui.add_child(_fader)
	var args := user_args()
	# The game fills the screen (F11 toggles a window); screenshot runs and `--windowed` keep the
	# window, and headless runs have no screen.
	if not args.has("shots") and not args.has("windowed") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if args.has("shots"):
		add_child(Autoshot.new().setup(self, args.shots, args.get("script", "idle")))
	if args.has("debug"):
		Game.set_debug_overlay(true)
	if args.has("room"):
		Game.reset_run()
		load_room(room_index_of(args.room))
	else:
		show_title()


## User arguments after `--`, as {"room": "colonnade", ...}. `--room=<id or index>` skips the
## title and starts in that room; `--shots=<path prefix> --script=<name>` runs an Autoshot
## timeline (scripts/dev/autoshot.gd); `--debug` turns on the F3 overlay; `--windowed` starts in a
## window instead of full screen.
static func user_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else "true"
	return out


static func room_index_of(key: String) -> int:
	for i in Game.rooms.size():
		if Game.rooms[i].get("id", "") == key:
			return i
	return clampi(key.to_int(), 0, Game.rooms.size() - 1)


## Maps a point in room space to the 960x540 UI.
func world_to_ui(p: Vector2) -> Vector2:
	return (world_viewport.get_canvas_transform() * p) * 2.0


# ============================================================== flow

func show_title() -> void:
	get_tree().paused = false
	_close_menu()
	_clear_room()
	Sfx.stop_music()
	Sfx.set_ambience("night")
	hud.visible = false
	var t := TitleScreen.new()
	t.begin.connect(start_run)
	_set_screen(t)


func start_run() -> void:
	Game.reset_run()
	var intro := IntroCards.new()
	intro.finished.connect(func():
		_screen = null
		load_room(0))
	_set_screen(intro)


func _set_screen(c: Control) -> void:
	if _screen and is_instance_valid(_screen):
		_screen.queue_free()
	_screen = c
	if c:
		ui.add_child(c)


func _clear_room() -> void:
	Juice.reset()
	Game.clear_attack_token()
	if room and is_instance_valid(room):
		world_viewport.remove_child(room)
		room.queue_free()
	room = null
	player = null
	overlay = null


## Builds room `index` from Game.rooms and drops Cedalion at its entrance.
func load_room(index: int, arrive := false) -> void:
	_clear_room()
	_set_screen(null)
	Game.room_index = index
	room = Room.new()
	room.name = "Room"
	world_viewport.add_child(room)
	room.build(Game.rooms[index])
	room.spawn_guards()

	player = Player.new()
	player.name = "Cedalion"
	player.room = room
	room.player = player
	player.position = room.cell_center(room.player_spawn)
	room.world.add_child(player)
	player.set_camera_limits(room.bounds())
	player.died.connect(_on_player_died)

	room.exit_reached.connect(_on_exit_reached)
	room.message.connect(_on_room_message)
	overlay = DebugOverlay.new()
	overlay.room = room
	room.add_child(overlay)

	hud.player = player
	hud.clear_transient()
	hud.visible = true
	hud.show_room(room.id, room.display_name)
	Sfx.start_music()
	Sfx.set_ambience({"storerooms": "indoor", "cistern": "cistern"}.get(room.id, "night"))
	if arrive:
		# Arriving from below: the island settles into place as the dark lifts.
		var cam := player.camera
		var base := cam.base_offset
		cam.base_offset.y = base.y + RISE_PX
		player.lock(true)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(cam, "base_offset:y", base.y, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_fader, "color:a", 0.0, 0.4)
		tw.chain().tween_callback(func():
			if player and is_instance_valid(player) and player.state == Player.S.LOCKED and _menu == null:
				player.lock(false))
	else:
		_fade(false)


## The climb between islands: the camera rises, so this island sinks away below and the next one
## comes down into view from above, the sky's layers sliding past at their own depths.
const RISE_PX := 150.0


func _on_exit_reached() -> void:
	if _busy:
		return
	_busy = true
	player.lock(true)
	Sfx.play("rise", null, -3.0, 0.0)
	var cam := player.camera
	var base := cam.base_offset
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cam, "base_offset:y", base.y - RISE_PX, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_fader, "color:a", 1.0, 0.3).set_delay(0.25)
	await tw.finished
	Game.take_snapshot()
	if Game.room_index + 1 < Game.rooms.size():
		load_room(Game.room_index + 1, true)
	else:
		Game.finish_run()
		_show_end()
	_busy = false


func _show_end() -> void:
	_clear_room()
	hud.visible = false
	Sfx.set_tension(0.0)
	var end := EndCard.new()
	end.to_title.connect(show_title)
	_set_screen(end)
	_fade(false)


func _on_player_died() -> void:
	if _busy:
		return
	_busy = true
	var card := MessageCard.new().setup(DEATH_LINES[randi() % DEATH_LINES.size()], "You wake at the last lamp, with what you carried there.")
	ui.add_child(card)
	await card.done
	Game.restore_snapshot()
	load_room(Game.room_index)
	_busy = false


func restart_room() -> void:
	get_tree().paused = false
	_close_menu()
	Game.restore_snapshot()
	load_room(Game.room_index)


func _on_room_message(text: String) -> void:
	if text == "shop" and _menu == null:
		player.lock(true)
		var shop := ShopPanel.new()
		shop.closed.connect(func():
			_menu = null
			if player and is_instance_valid(player):
				player.lock(false))
		_menu = shop
		ui.add_child(shop)


func _fade(to_black: bool) -> Signal:
	var tw := create_tween()
	tw.tween_property(_fader, "color:a", 1.0 if to_black else 0.0, 0.35)
	return tw.finished


# ============================================================== pause and debug

func _pause() -> void:
	var m := PauseMenu.new()
	m.resumed.connect(func():
		get_tree().paused = false
		_close_menu())
	m.restart_room.connect(restart_room)
	m.to_title.connect(show_title)
	_menu = m
	ui.add_child(m)
	get_tree().paused = true


func _close_menu() -> void:
	if _menu and is_instance_valid(_menu):
		_menu.queue_free()
	_menu = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		Game.set_debug_overlay(not Game.debug_overlay)
	elif event.is_action_pressed("pause") and room != null and _menu == null and not _busy and _screen == null:
		get_viewport().set_input_as_handled()
		_pause()


func _process(delta: float) -> void:
	if room and is_instance_valid(room):
		Sfx.set_tension(room.max_awareness() / 100.0)
		room.set_danger(room.max_awareness() / 100.0, delta)
