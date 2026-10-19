class_name Autoshot
extends Node
## Plays a timeline of input actions and saves screenshots, for visual checks without a person at
## the keyboard. Started by main when run with user args, for example:
##   godot_console --path . --resolution 960x540 -- --room=colonnade --shots=C:/tmp/orion --script=walk
## Each "shot" saves <prefix>_<room>_<name>.png. The game quits after the last event.

## Events: [seconds, "press" | "release" | "tap" | "shot" | "call", action, (shot name)].
const SCRIPTS := {
	"title": [
		[3.8, "shot", "", "title"],
	],
	"idle": [
		[1.2, "shot", "", "start"],
		[3.0, "shot", "", "later"],
	],
	"walk": [
		[0.8, "shot", "", "start"],
		[1.0, "press", "move_right"],
		[2.2, "release", "move_right"],
		[2.3, "press", "move_up"],
		[3.3, "release", "move_up"],
		[3.4, "shot", "", "walked"],
		[3.5, "press", "move_down"],
		[3.5, "press", "move_right"],
		[4.6, "release", "move_down"],
		[4.6, "release", "move_right"],
		[4.7, "shot", "", "walked2"],
	],
	"fight": [
		[0.8, "shot", "", "start"],
		[1.0, "call", "debug"],
		[1.0, "press", "move_up"],
		[2.0, "release", "move_up"],
		[2.1, "shot", "", "approach"],
		[2.4, "tap", "attack"],
		[2.9, "tap", "attack"],
		[3.0, "shot", "", "swing"],
		[3.6, "tap", "toss"],
		[4.2, "shot", "", "after"],
	],
	"screens": [
		[0.8, "shot", "", "title"],
		[1.0, "call", "begin"],
		[2.0, "shot", "", "intro"],
		[2.2, "call", "end"],
		[3.2, "shot", "", "end_stamp"],
		[5.4, "shot", "", "end"],
		[5.5, "call", "death"],
		[6.2, "shot", "", "death"],
	],
	"intro": [
		[0.5, "call", "begin"],
		[1.8, "shot", "", "intro1"],
		[1.9, "call", "next"],
		[5.3, "shot", "", "intro2"],
		[5.4, "call", "next"],
		[7.2, "shot", "", "intro3"],
	],
	"duel": [
		[0.6, "call", "near_guard"],
		[0.9, "shot", "", "duel1"],
		[1.3, "shot", "", "duel2"],
		[1.7, "shot", "", "duel3"],
		[2.1, "shot", "", "duel4"],
		[2.5, "shot", "", "duel5"],
		[2.9, "shot", "", "duel6"],
	],
	"flash": [
		[0.6, "call", "near_guard"],
		[0.7, "call", "wait_flash"],
		[5.0, "shot", "", "later"],
	],
	"pause": [
		[1.0, "tap", "pause"],
		[1.5, "shot", "", "paused"],
		[1.6, "tap", "pause"],
		[2.0, "call", "shop"],
		[2.5, "shot", "", "shop"],
	],
}

var prefix := ""
var events: Array = []
var main: Node
var _t := 0.0
var _i := 0


func setup(p_main: Node, p_prefix: String, script_name: String) -> Autoshot:
	main = p_main
	prefix = p_prefix
	events = SCRIPTS.get(script_name, SCRIPTS.idle)
	return self


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_t += delta
	while _i < events.size() and _t >= events[_i][0]:
		_run(events[_i])
		_i += 1
	if _i >= events.size() and _t > events[-1][0] + 0.3:
		get_tree().quit()


func _run(e: Array) -> void:
	match e[1]:
		"press":
			Input.action_press(e[2])
		"release":
			Input.action_release(e[2])
		"tap":
			var ev := InputEventAction.new()
			ev.action = e[2]
			ev.pressed = true
			Input.parse_input_event(ev)
			Input.action_press(e[2])
			await get_tree().create_timer(0.05, true, false, true).timeout
			Input.action_release(e[2])
		"call":
			if e[2] == "debug":
				Game.set_debug_overlay(true)
			elif e[2] == "shop" and main.room:
				main.room.message.emit("shop")
			elif e[2] == "near_guard" and main.room and not main.room.guards.is_empty():
				# Arm Cedalion and stand him in front of the first guard.
				var g: Guard = main.room.guards[0]
				Game.give_weapon("xiphos")
				main.player.global_position = g.global_position + Iso.grid_to_screen(g.facing * 1.6)
				main.player.facing = -g.facing
				main.player.camera.reset_smoothing()
			elif e[2] == "wait_flash" and main.room and not main.room.guards.is_empty():
				# Shoot the moment a guard's glint flares, and again as the blade lands.
				var g: Guard = main.room.guards[0]
				while not (g._attack and g._phase == "windup" and g._phase_t >= g._attack.windup - Guard.FLASH_LEAD):
					await get_tree().process_frame
				_run([0, "shot", "", "flash"])
				await get_tree().create_timer(Guard.FLASH_LEAD, true, false, true).timeout
				_run([0, "shot", "", "strike"])
			elif e[2] == "next":
				for c in main.ui.get_children():
					if c is IntroCards:
						c._advance()
			elif e[2] == "begin":
				main.start_run()
			elif e[2] == "end":
				Game.finish_run()
				main._show_end()
			elif e[2] == "death":
				main.ui.add_child(MessageCard.new().setup("The dark took you.", "You wake at the last lamp, with what you carried there.", 3.0))
		"shot":
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var room_id: String = main.room.id if main.room else "screen"
			var path := "%s_%s_%s.png" % [prefix, room_id, e[3]]
			img.save_png(path)
			print("autoshot: ", path)
