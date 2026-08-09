class_name ActorAnim
extends RefCounted
## Procedural life for a single-frame billboard.
##
## The cast is baked as one static sprite each, so all of the motion has to come
## from the transform. That is not a compromise — it is how storybook 2D games
## (Cult of the Lamb, Hades' minor cast) animate most of their crowd: a squashing,
## bobbing, leaning billboard reads as alive from three tiles away, and it costs
## one sine per actor per frame instead of an atlas of hand-drawn frames.
##
## WHAT IT DRIVES
##   bob       vertical hop on |sin|, so both feet land per cycle
##   squash    volume-preserving — taller when rising, wider when landing
##   lean      rotation into the direction of travel, eased so it never snaps
##   flip      mirror on facing, which matters because the cast is asymmetric
##   shadow    shrinks as the actor rises, which is what sells the hop as height
##   punch     a transient squash for hits, swings and landings
##
## USAGE
##   _anim = ActorAnim.new(_sprite, _shadow)
##   _anim.tick(delta, velocity)          # every frame
##   _anim.punch(0.22)                    # on impact
##   if _anim.tick(...): footstep_dust()  # returns true on each footfall

const IDLE_FREQ := 2.4        # breathing, rad/s
const WALK_FREQ := 11.0       # stride, rad/s
const MOVING_EPS := 6.0       # px/s below which an actor counts as standing

var bob: float = 3.4          # peak hop height, px
var lean_max: float = 0.15    # peak lean, radians
var squash: float = 0.07      # peak stride squash, fraction of scale
var flip_enabled: bool = true

var _s: Sprite2D = null
var _shadow: Sprite2D = null
var _base_scale: Vector2 = Vector2.ONE
var _base_y: float = 0.0
var _shadow_scale: Vector2 = Vector2.ONE
var _t: float = 0.0
var _lean: float = 0.0
var _punch: float = 0.0
var _flip: float = 1.0
var _was_rising: bool = false

## `sprite` must already be positioned/anchored — its current scale and y offset
## are captured as the rest pose and everything animates around them.
func _init(sprite: Sprite2D, shadow: Sprite2D = null) -> void:
	_s = sprite
	_shadow = shadow
	if _s != null:
		_base_scale = _s.scale
		_base_y = _s.position.y
	if _shadow != null:
		_shadow_scale = _shadow.scale
	# Desync actors spawned on the same frame, so a room of husks doesn't pulse
	# in lockstep like a chorus line.
	_t = randf() * TAU

## Advance one frame. `vel` is the actor's current screen-space velocity.
## Returns true on the frame a foot hits the ground (for dust / step sounds).
func tick(delta: float, vel: Vector2) -> bool:
	if _s == null or not is_instance_valid(_s):
		return false
	var speed: float = vel.length()
	var moving: bool = speed > MOVING_EPS
	_t += delta * (WALK_FREQ if moving else IDLE_FREQ)

	var sn: float = sin(_t)
	var y_off: float = 0.0
	var sx: float = 1.0
	var sy: float = 1.0
	var footfall: bool = false

	if moving:
		# |sin| gives two hops per cycle — one per foot.
		var lift: float = absf(sn)
		y_off = -lift * bob
		sy = 1.0 + lift * squash - squash * 0.5
		sx = 1.0 - lift * squash * 0.8 + squash * 0.4
		# A footfall is the moment the body stops falling and starts rising.
		var rising: bool = cos(_t) * signf(sn) > 0.0
		if rising and not _was_rising:
			footfall = true
		_was_rising = rising
	else:
		# Idle breathing: much slower, much smaller, no vertical travel.
		sy = 1.0 + sn * 0.022
		sx = 1.0 - sn * 0.018
		_was_rising = false

	# Transient punch from hits and swings, decaying back to rest.
	if _punch > 0.001:
		sy -= _punch
		sx += _punch * 0.85
		_punch = move_toward(_punch, 0.0, delta * 3.4)

	# Lean into the run. Eased, so a direction change reads as weight shifting.
	var target: float = clampf(vel.x / 200.0, -1.0, 1.0) * lean_max
	if not moving:
		target = 0.0
	_lean = lerpf(_lean, target, clampf(delta * 9.0, 0.0, 1.0))

	# Face the direction of travel.
	if flip_enabled and absf(vel.x) > MOVING_EPS:
		_flip = -1.0 if vel.x < 0.0 else 1.0

	_s.position.y = _base_y + y_off
	_s.rotation = _lean * _flip
	_s.scale = Vector2(_base_scale.x * sx * _flip, _base_scale.y * sy)

	# The shadow tightens as the actor leaves the ground — this is what makes the
	# hop read as height rather than as the sprite growing.
	if _shadow != null and is_instance_valid(_shadow):
		var k: float = 1.0 - (absf(y_off) / maxf(bob, 0.001)) * 0.16
		_shadow.scale = _shadow_scale * k
		_shadow.modulate.a = lerpf(_shadow.modulate.a, 0.30 + 0.16 * k, 0.4)

	return footfall

## Squash the actor briefly. 0.15 = a jab landing, 0.35 = a heavy blow.
func punch(amount: float) -> void:
	_punch = maxf(_punch, amount)

## Force the facing without needing velocity (aiming while standing still).
func face(dir_x: float) -> void:
	if flip_enabled and absf(dir_x) > 0.01:
		_flip = -1.0 if dir_x < 0.0 else 1.0

## Current facing sign, so callers can place effects on the correct side.
func facing_sign() -> float:
	return _flip
