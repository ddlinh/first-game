extends Node
## Screen-level feedback: hit-stop, camera shake and full-screen flashes.
## Autoloaded as `Juice`.
##
## These are the three effects that cannot live on a single entity, because they
## act on the whole view. Everything else belongs in Vfx.
##
## WHY HIT-STOP MATTERS
## A melee hit that just plays a particle reads as "a thing happened near an
## enemy". Freezing the world for 40-90 ms at the moment of contact is what makes
## it read as "I hit that". The freeze is short enough to feel like weight rather
## than lag, and it scales with the size of the blow.
##
## Everything here is null-safe and self-restoring: if the camera or the tree goes
## away mid-effect (a layer swap, the player dying) nothing is left stuck.

# Hit-stop is measured in REAL time, so it cannot be stretched by the very
# time_scale change it is applying.
const STOP_SCALE := 0.045          # how far time slows during a freeze
const SHAKE_FALLOFF := 2.4         # >1 = the shake dies away faster than linear
const MAX_SHAKE := 14.0            # px, so a chain of hits can never go seasick

var _cam: Camera2D = null
var _shake_amp: float = 0.0
var _shake_left: float = 0.0
var _shake_dur: float = 0.0
var _stop_until_ms: int = 0
var _flash: ColorRect = null

func _ready() -> void:
	# Keep ticking while the tree is paused or time-scaled, otherwise a hit-stop
	# would freeze the very timer meant to end it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_flash_layer()

# The flash plate sits below the Hud (layer 10) so a hit never washes out the UI.
func _build_flash_layer() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cl.add_child(_flash)

# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

## Main hands its Camera2D over once. Shake is applied through `offset`, which
## leaves the camera's follow position free for Main to drive.
func register_camera(cam: Camera2D) -> void:
	_cam = cam

## Kick the camera. `amp` is peak displacement in px, `dur` its lifetime.
## Overlapping shakes take the strongest rather than summing, so a flurry of
## hits stays readable.
func shake(amp: float, dur: float = 0.22) -> void:
	amp = minf(amp, MAX_SHAKE)
	if amp <= _shake_amp and _shake_left > 0.0:
		return
	_shake_amp = amp
	_shake_dur = maxf(dur, 0.01)
	_shake_left = _shake_dur

# ---------------------------------------------------------------------------
# Hit-stop
# ---------------------------------------------------------------------------

## Freeze the world for `secs` of REAL time. Calls stack by taking the longest
## outstanding freeze rather than adding up into a lock-up.
func hitstop(secs: float) -> void:
	var until: int = Time.get_ticks_msec() + int(maxf(secs, 0.0) * 1000.0)
	if until <= _stop_until_ms:
		return
	_stop_until_ms = until
	Engine.time_scale = STOP_SCALE

# ---------------------------------------------------------------------------
# Flash
# ---------------------------------------------------------------------------

## A full-screen colour wash that fades out — impact confirmation for the big
## beats (taking a hit, finishing a building, freeing a survivor).
func flash(color: Color, alpha: float = 0.35, dur: float = 0.22) -> void:
	if _flash == null:
		return
	_flash.color = Color(color.r, color.g, color.b, alpha)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, dur).set_trans(Tween.TRANS_QUAD)

# ---------------------------------------------------------------------------
# Per-frame
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	# Undo a finished freeze. Compared in real ms so the slowed clock can't
	# stretch the freeze indefinitely.
	if _stop_until_ms > 0 and Time.get_ticks_msec() >= _stop_until_ms:
		_stop_until_ms = 0
		Engine.time_scale = 1.0

	if _shake_left <= 0.0:
		return
	# Advance in real time too — a shake during a hit-stop should still resolve.
	_shake_left -= delta / maxf(Engine.time_scale, 0.001)
	if not is_instance_valid(_cam):
		_shake_left = 0.0
		return
	if _shake_left <= 0.0:
		_cam.offset = Vector2.ZERO
		return
	var k: float = pow(_shake_left / _shake_dur, SHAKE_FALLOFF)
	var amp: float = _shake_amp * k
	_cam.offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp) * Palette.SQUASH)

## Drop the camera reference and cancel any in-flight effect. Called when a layer
## is torn down so a freed camera is never poked.
func reset() -> void:
	_shake_left = 0.0
	_shake_amp = 0.0
	if is_instance_valid(_cam):
		_cam.offset = Vector2.ZERO
	_stop_until_ms = 0
	Engine.time_scale = 1.0
