class_name ShakeCamera
extends Camera2D
## The player's camera: trauma-based shake, a short zoom punch, and a look-ahead toward where
## Cedalion is heading.
##
## Shake follows the "trauma" model: hits add trauma (0..1), it decays linearly, and the offset is
## trauma squared times smooth noise, so small knocks barely move the view and big ones punch.
## Offsets are rounded to whole pixels so the 480x270 world never shimmers.

## The camera in use, so effects anywhere can shake it without holding a reference.
static var current: ShakeCamera

const MAX_OFFSET := Vector2(7.0, 5.0)
const MAX_ROLL := 0.0  # rotation would break the pixel grid
const DECAY := 1.7  # trauma per second
const LOOK_SPEED := 3.5

var trauma := 0.0
var base_offset := Vector2(0, -12)
## Where the player wants the view to lean, in pixels (set every frame by the player).
var look := Vector2.ZERO

var _look_now := Vector2.ZERO
var _noise := FastNoiseLite.new()
var _t := 0.0
var _zoom_tween: Tween


func _ready() -> void:
	current = self
	_noise.frequency = 0.9
	_noise.seed = 11
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _exit_tree() -> void:
	if current == self:
		current = null


static func add_trauma(amount: float) -> void:
	if current and Game.screen_shake:
		current.trauma = clampf(current.trauma + amount, 0.0, 1.0)


## A quick zoom in and back out, for perfect parries and big hits.
static func punch(amount := 0.06, time := 0.22) -> void:
	if current == null or not Game.screen_shake:
		return
	var c := current
	if c._zoom_tween:
		c._zoom_tween.kill()
	c.zoom = Vector2.ONE * (1.0 + amount)
	c._zoom_tween = c.create_tween().set_ignore_time_scale(true)
	c._zoom_tween.tween_property(c, "zoom", Vector2.ONE, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	# Real time, so shake still decays during hit-stop and slow motion.
	var real := delta / maxf(0.05, Engine.time_scale)
	_t += real
	trauma = maxf(0.0, trauma - DECAY * real)
	_look_now = _look_now.lerp(look, clampf(LOOK_SPEED * delta, 0.0, 1.0))
	var shake := Vector2.ZERO
	if trauma > 0.0:
		var k := trauma * trauma
		shake = Vector2(_noise.get_noise_2d(_t * 60.0, 0.0), _noise.get_noise_2d(0.0, _t * 60.0)) * MAX_OFFSET * k * 1.6
	offset = (base_offset + _look_now + shake).round()
