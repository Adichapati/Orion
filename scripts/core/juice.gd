class_name Juice
extends RefCounted
## Time effects and hit flashes shared by the player and the guards.
##
## freeze() is hit-stop (a few frames of near-stopped time on a hit); slowmo() is the longer
## slow beat on a perfect parry. Both run on real time and never cut a longer effect short.

## Active time holds as [end_msec, time_scale]; the slowest one wins until it ends.
static var _holds: Array = []
static var _flash_mat: ShaderMaterial


static func freeze(tree: SceneTree, seconds: float, time_scale := 0.05) -> void:
	await _hold(tree, seconds, time_scale)


static func slowmo(tree: SceneTree, seconds: float, time_scale := 0.3) -> void:
	await _hold(tree, seconds, time_scale)


## Clears every hold (on room loads, so a stray hold never outlives its scene).
static func reset() -> void:
	_holds.clear()
	Engine.time_scale = 1.0


static func _hold(tree: SceneTree, seconds: float, time_scale: float) -> void:
	if tree == null:
		return
	var h := [Time.get_ticks_msec() + int(seconds * 1000.0), time_scale]
	_holds.append(h)
	_apply()
	await tree.create_timer(seconds, true, false, true).timeout
	_holds.erase(h)
	_apply()


static func _apply() -> void:
	var s := 1.0
	var now := Time.get_ticks_msec()
	for h in _holds:
		if h[0] > now - 100:
			s = minf(s, h[1])
	Engine.time_scale = s


## Flashes a sprite solid colour for a moment, ignoring the room's darkness, then restores it.
static func flash(sprite: CanvasItem, seconds := 0.07, color := Color(1, 1, 1)) -> void:
	if sprite == null or not sprite.is_inside_tree():
		return
	if _flash_mat == null:
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
render_mode unshaded;
uniform vec4 flash_color : source_color = vec4(1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(flash_color.rgb, c.a * COLOR.a);
}"""
		_flash_mat = ShaderMaterial.new()
		_flash_mat.shader = sh
	var mat := _flash_mat.duplicate() as ShaderMaterial
	mat.set_shader_parameter("flash_color", color)
	sprite.material = mat
	await sprite.get_tree().create_timer(seconds, true, false, true).timeout
	if is_instance_valid(sprite) and sprite.material == mat:
		sprite.material = null
