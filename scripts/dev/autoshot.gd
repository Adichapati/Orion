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
		[2.0, "call", "audio"],
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
	"death": [
		[0.5, "call", "death"],
		[1.0, "shot", "", "death_a"],
		[2.2, "shot", "", "death_b"],
	],
	"aim": [
		[0.8, "press", "move_right"],
		[1.3, "release", "move_right"],
		[1.4, "press", "toss"],
		[2.0, "shot", "", "aiming"],
		[2.1, "release", "toss"],
		[2.4, "shot", "", "thrown"],
	],
	"noise": [
		[0.8, "press", "run"],
		[0.8, "press", "move_down"],
		[1.6, "shot", "", "running"],
		[1.7, "release", "move_down"],
		[1.7, "release", "run"],
		[1.9, "tap", "attack"],
		[2.0, "shot", "", "swing"],
	],
	"statue": [
		[0.6, "call", "near_statue"],
		[1.2, "shot", "", "stone"],
		[1.3, "call", "wake_statue"],
		[1.45, "shot", "", "waking"],
		[2.2, "shot", "", "awake"],
	],
	"star": [
		[0.6, "call", "take_star"],
		[0.75, "shot", "", "burst"],
		[0.95, "shot", "", "floating"],
		[2.4, "shot", "", "escape"],
		[3.6, "shot", "", "collapse"],
		[4.4, "shot", "", "collapse2"],
	],
	"sneak": [
		[0.8, "shot", "", "stand"],
		[0.9, "press", "sneak"],
		[1.4, "shot", "", "crouch"],
		[1.5, "press", "move_right"],
		[2.2, "shot", "", "sneaking"],
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
	# Cistern: push against the exit door from inside (it used to lead out onto the sky), then
	# climb the steps to Phineus.
	"seal": [
		[0.5, "call", "goto", Vector2i(11, 9)],
		[0.7, "press", "move_down"],
		[0.7, "press", "move_right"],
		[2.2, "shot", "", "door_push"],
		[2.3, "release", "move_down"],
		[2.3, "release", "move_right"],
		[2.3, "call", "info"],
		[2.4, "call", "goto", Vector2i(2, 6)],
		[2.6, "press", "move_up"],
		[2.6, "press", "move_right"],
		[3.8, "release", "move_up"],
		[3.8, "release", "move_right"],
		[4.0, "call", "info"],
		[4.2, "shot", "", "phineus"],
	],
	# Cedalion's frames while he walks and swings: prints the clip and frame on every frame.
	"anim": [
		[0.5, "call", "give_sword"],
		[0.6, "call", "trace"],
		[0.7, "press", "move_right"],
		[1.3, "shot", "", "walk1"],
		[1.38, "shot", "", "walk2"],
		[1.46, "shot", "", "walk3"],
		[1.54, "shot", "", "walk4"],
		[1.9, "release", "move_right"],
		[2.2, "tap", "attack"],
		[2.24, "shot", "", "swing1"],
		[2.29, "shot", "", "swing2"],
		[2.33, "shot", "", "swing3"],
		[2.37, "shot", "", "swing4"],
		[2.42, "shot", "", "swing5"],
		[2.5, "shot", "", "swing6"],
		[2.8, "tap", "attack"],
		[3.0, "tap", "attack"],
		[3.4, "tap", "parry"],
		[3.48, "shot", "", "parry"],
		[3.8, "tap", "jump"],
		[3.95, "shot", "", "jump"],
		[4.4, "call", "untrace"],
		[4.5, "call", "unarm"],
		[4.7, "shot", "", "unarmed"],
	],
	# The swing facing away (up-right) and mirrored (up-left), in a dark room.
	"anim_back": [
		[0.5, "call", "give_sword"],
		[0.6, "press", "move_up"],
		[0.6, "press", "move_right"],
		[1.0, "release", "move_up"],
		[1.0, "release", "move_right"],
		[1.2, "tap", "attack"],
		[1.27, "shot", "", "back1"],
		[1.33, "shot", "", "back2"],
		[1.4, "shot", "", "back3"],
		[1.8, "press", "move_left"],
		[2.0, "release", "move_left"],
		[2.2, "tap", "attack"],
		[2.27, "shot", "", "left1"],
		[2.33, "shot", "", "left2"],
		[2.4, "shot", "", "left3"],
		[2.8, "press", "move_down"],
		[3.0, "release", "move_down"],
		[3.2, "tap", "attack"],
		[3.27, "shot", "", "down1"],
		[3.33, "shot", "", "down2"],
		[3.4, "shot", "", "down3"],
	],
	# The roll, the block and the get-hit from the v2 sheet: front (down-right), then back (up-right).
	"moves": [
		[0.5, "call", "give_sword"],
		[0.6, "call", "trace"],
		[0.8, "tap", "dodge"],
		[0.84, "shot", "", "roll1"],
		[0.93, "shot", "", "roll2"],
		[1.02, "shot", "", "roll3"],
		[1.6, "tap", "parry"],
		[1.7, "shot", "", "block"],
		[2.3, "call", "hurt"],
		# three shots: the hit's flicker hides him on every other twentieth of a second
		[2.38, "shot", "", "hurt"],
		[2.42, "shot", "", "hurt_b"],
		[2.47, "shot", "", "hurt_c"],
		[3.2, "press", "move_up"],
		[3.2, "press", "move_right"],
		[3.45, "release", "move_up"],
		[3.45, "release", "move_right"],
		[3.7, "tap", "dodge"],
		[3.74, "shot", "", "back_roll1"],
		[3.83, "shot", "", "back_roll2"],
		[3.92, "shot", "", "back_roll3"],
		[4.5, "tap", "parry"],
		[4.6, "shot", "", "back_block"],
		[5.2, "call", "hurt"],
		[5.28, "shot", "", "back_hurt"],
		[5.32, "shot", "", "back_hurt_b"],
		[5.37, "shot", "", "back_hurt_c"],
		[5.6, "call", "untrace"],
	],
	# Walk each of the four ways in turn, tracing the frame and mirroring every frame.
	"turns": [
		[0.5, "call", "give_sword"],
		[0.6, "call", "trace"],
		[0.7, "press", "move_left"],
		[1.5, "shot", "", "left"],
		[1.7, "release", "move_left"],
		[1.9, "press", "move_right"],
		[2.7, "shot", "", "right"],
		[2.9, "release", "move_right"],
		[3.1, "press", "move_up"],
		[3.9, "shot", "", "up"],
		[4.1, "release", "move_up"],
		[4.3, "press", "move_down"],
		[5.1, "shot", "", "down"],
		[5.3, "release", "move_down"],
		[5.4, "call", "untrace"],
	],
	# Stand by the Lion Gate's first cracked wall (3, 0), to look at its cracks.
	"ruins": [
		[0.5, "call", "goto", Vector2i(3, 2)],
		[1.2, "shot", "", "ruin"],
	],
	# The island from its front corner, where the underside shows.
	"vista": [
		[0.4, "call", "goto_corner"],
		[1.2, "shot", "", "corner"],
		[6.5, "shot", "", "corner_later"],
	],
	# Leaving by the exit: the climb to the next island.
	"transition": [
		[0.8, "call", "use_exit"],
		[1.05, "shot", "", "leave1"],
		[1.3, "shot", "", "leave2"],
		[1.55, "shot", "", "arrive1"],
		[1.8, "shot", "", "arrive2"],
		[2.3, "shot", "", "arrive3"],
	],
	# Cedalion walking in each screen direction, six frames apiece.
	"walk4": [
		[0.3, "call", "give_sword"],
		[0.60, "press", "move_right"],
		[0.950, "shot", "", "right0"],
		[1.025, "shot", "", "right1"],
		[1.100, "shot", "", "right2"],
		[1.175, "shot", "", "right3"],
		[1.250, "shot", "", "right4"],
		[1.325, "shot", "", "right5"],
		[1.45, "release", "move_right"],
		[1.70, "press", "move_down"],
		[2.050, "shot", "", "down0"],
		[2.125, "shot", "", "down1"],
		[2.200, "shot", "", "down2"],
		[2.275, "shot", "", "down3"],
		[2.350, "shot", "", "down4"],
		[2.425, "shot", "", "down5"],
		[2.55, "release", "move_down"],
		[2.80, "press", "move_left"],
		[3.150, "shot", "", "left0"],
		[3.225, "shot", "", "left1"],
		[3.300, "shot", "", "left2"],
		[3.375, "shot", "", "left3"],
		[3.450, "shot", "", "left4"],
		[3.525, "shot", "", "left5"],
		[3.65, "release", "move_left"],
		[3.90, "press", "move_up"],
		[4.250, "shot", "", "up0"],
		[4.325, "shot", "", "up1"],
		[4.400, "shot", "", "up2"],
		[4.475, "shot", "", "up3"],
		[4.550, "shot", "", "up4"],
		[4.625, "shot", "", "up5"],
		[4.75, "release", "move_up"],
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
var _tracing := false


func setup(p_main: Node, p_prefix: String, script_name: String) -> Autoshot:
	main = p_main
	prefix = p_prefix
	events = SCRIPTS.get(script_name, SCRIPTS.idle)
	return self


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_t += delta
	if _tracing and main.player:
		var p: Player = main.player
		var r: Rect2 = p.sprite.texture.region if p.sprite.texture is AtlasTexture else Rect2()
		print("trace %.3f %s %s frame=%d flip=%s gvel=%.2f sword=%s/%d" % [_t, Player.S.keys()[p.state], p._anim_base,
				int(r.position.x / maxf(1.0, r.size.x)) + 8 * int(r.position.y / maxf(1.0, r.size.y)), p.sprite.flip_h, p._gvel.length(),
				p.sword.visible, p.sword.frame] + " pos=%s idx=%d/%d hand=%s" % [p.sword.position, p.sword.get_index(), p.sprite.get_index(), p._hand])
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
			elif e[2] == "goto" and main.room:
				main.player.global_position = main.room.cell_center(e[3])
				main.player.camera.reset_smoothing()
			elif e[2] == "use_exit" and main.room:
				for it in main.room.interactables:
					if is_instance_valid(it) and it.verb == "Enter":
						it.used.emit(main.player)
						break
			elif e[2] == "goto_corner" and main.room:
				var c: Vector2i = main.room.nearest_walkable(main.room.size - Vector2i(2, 2))
				main.player.global_position = main.room.cell_center(c)
				main.player.camera.reset_smoothing()
			elif e[2] == "info" and main.room:
				var f: Interactable = main.player.focus
				print("autoshot info: player at %s, focus %s" % [main.player.grid_pos(), f.verb if f else "none"])
			elif e[2] == "give_sword":
				Game.give_weapon("xiphos")
			elif e[2] == "hurt" and main.player:
				# A harmless blow from the side he faces, to show the get-hit frame.
				main.player.take_hit(0, main.player.global_position + Iso.grid_to_screen(main.player.facing), 0.0)
			elif e[2] == "unarm":
				Game.weapon_id = ""
			elif e[2] == "trace":
				_tracing = true
			elif e[2] == "untrace":
				_tracing = false
			elif e[2] == "next":
				for c in main.ui.get_children():
					if c is IntroCards:
						c._advance()
			elif e[2] == "audio":
				print("autoshot audio: ambience '%s' playing=%s vol=%.1f dB, music playing=%s" % [Sfx._ambience_name, Sfx._ambience.playing, Sfx._ambience.volume_db, Sfx._explore.playing])
			elif e[2] in ["near_statue", "wake_statue"] and main.room:
				# Stand Cedalion 4 tiles (or 2, to wake him) in front of the first statue guard.
				for g in main.room.guards:
					if g.dormant:
						var dist := 4.0 if e[2] == "near_statue" else 2.0
						main.player.global_position = g.global_position + Iso.grid_to_screen(Vector2(0, 1) * dist + Vector2(-1, 0))
						main.player.camera.reset_smoothing()
						break
			elif e[2] == "take_star" and main.room:
				# Stand Cedalion by the altar and take the Belt Star.
				for it in main.room.interactables:
					if is_instance_valid(it) and it.verb.begins_with("Take the Belt"):
						main.player.global_position = it.global_position + Iso.grid_to_screen(Vector2(0, 1.2))
						main.player.camera.reset_smoothing()
						it.used.emit(main.player)
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
			var at := ""
			if main.player and is_instance_valid(main.player):
				at = " player at ui %s" % main.world_to_ui(main.player.global_position)
			if main.room and not main.room.guards.is_empty():
				at += " guard at ui %s" % main.world_to_ui(main.room.guards[0].global_position)
			print("autoshot: ", path, at)
