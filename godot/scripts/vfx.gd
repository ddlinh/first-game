class_name Vfx
extends RefCounted
## Static, fire-and-forget world effects. Every call spawns nodes that clean
## themselves up, so callers never hold a handle or remember to free anything.
##
## Screen-level feedback (shake, hit-stop, flashes) lives in the `Juice` autoload
## instead — this file only ever touches the world.
##
## THE GRAMMAR
## Effects are built from a small vocabulary so that new ones automatically look
## like they belong to the same game:
##   arc      a swing sweeps (swing) — it never just appears and fades
##   ring     force spreading along the ground (shockwave)
##   flash    the instant of contact (impact)
##   motes    embers rise and glow, ash falls and doesn't, dust hugs the floor
## Anything on the ground plane is squashed by Palette.SQUASH so it lies flat
## rather than standing up like a decal facing the camera.
##
## Z-BANDS keep effects from being swallowed by the world or covering the HUD.

const Z_GROUND := -2      # scuffs and rings that lie on the floor, under actors
const Z_LOW := 20         # dust at ankle height
const Z_MID := 40         # slashes, afterimages
const Z_HIGH := 60        # sparks, impact flashes
const Z_TEXT := 100

# ===========================================================================
# Motes
# ===========================================================================

## Rising embers — the game's signature. Warm, buoyant, slightly random.
static func embers(parent: Node, gpos: Vector2, amount: int = 16,
		color: Color = Color("ff6b35")) -> void:
	var p := _particles(parent, gpos, "ember", maxi(1, amount), color)
	if p == null:
		return
	p.lifetime = 1.05
	p.explosiveness = 0.82
	p.direction = Vector2(0, -1)
	p.spread = 42.0
	p.gravity = Vector2(0, -58)          # embers fall UP: they are hot air
	p.initial_velocity_min = 24.0
	p.initial_velocity_max = 84.0
	p.scale_amount_min = Palette.PX * 0.5
	p.scale_amount_max = Palette.PX * 1.25
	p.damping_min = 8.0
	p.damping_max = 22.0
	p.z_index = Z_HIGH
	_fade_curve(p)
	p.emitting = true
	_free_later(p, 2.4)

## Cold ash, thrown outward then falling. What a husk leaves behind.
static func ash_burst(parent: Node, gpos: Vector2, amount: int = 14) -> void:
	var p := _particles(parent, gpos, "ash", amount, Color(1, 1, 1, 1))
	if p == null:
		return
	p.lifetime = 1.3
	p.explosiveness = 0.95
	p.direction = Vector2(0, -0.4)
	p.spread = 180.0
	p.gravity = Vector2(0, 120)          # ash is dead weight; it comes back down
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 130.0
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	p.scale_amount_min = Palette.PX * 0.6
	p.scale_amount_max = Palette.PX * 1.5
	p.damping_min = 30.0
	p.damping_max = 70.0
	p.z_index = Z_MID
	_fade_curve(p)
	p.emitting = true
	_free_later(p, 2.6)

## Floor dust. Hugs the ground, spreads sideways, dies fast — footfalls, dashes,
## anything heavy landing.
static func dust(parent: Node, gpos: Vector2, amount: int = 8,
		dir: Vector2 = Vector2.ZERO) -> void:
	var p := _particles(parent, gpos, "dust", amount, Color(1, 1, 1, 0.85))
	if p == null:
		return
	p.lifetime = 0.55
	p.explosiveness = 0.9
	p.direction = dir if dir.length() > 0.01 else Vector2(0, -0.25)
	p.spread = 65.0 if dir.length() > 0.01 else 180.0
	p.gravity = Vector2(0, -10)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = Palette.PX * 0.5
	p.scale_amount_max = Palette.PX * 1.4
	p.damping_min = 50.0
	p.damping_max = 90.0
	p.z_index = Z_LOW
	_fade_curve(p)
	p.emitting = true
	_free_later(p, 1.4)

## Hard sparks in a cone — metal on metal, hammer on nail.
static func sparks(parent: Node, gpos: Vector2, amount: int = 8,
		dir: Vector2 = Vector2.ZERO, color: Color = Palette.GOLD_L) -> void:
	var p := _particles(parent, gpos, "spark", amount, color)
	if p == null:
		return
	p.lifetime = 0.42
	p.explosiveness = 1.0
	p.direction = dir if dir.length() > 0.01 else Vector2(0, -1)
	p.spread = 48.0
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 130.0
	p.initial_velocity_max = 300.0
	p.scale_amount_min = Palette.PX * 0.35
	p.scale_amount_max = Palette.PX * 0.9
	p.z_index = Z_HIGH
	_fade_curve(p)
	p.emitting = true
	_free_later(p, 1.2)

## Tumbling solid debris (wood chips, stone shards) for construction and breakage.
static func debris(parent: Node, gpos: Vector2, key: String = "chip_wood",
		amount: int = 8) -> void:
	var p := _particles(parent, gpos, key, amount, Color(1, 1, 1, 1))
	if p == null:
		return
	p.lifetime = 0.85
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 100.0
	p.gravity = Vector2(0, 420)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 210.0
	p.angular_velocity_min = -400.0
	p.angular_velocity_max = 400.0
	p.scale_amount_min = Palette.PX * 0.7
	p.scale_amount_max = Palette.PX * 1.3
	p.z_index = Z_MID
	_fade_curve(p)
	p.emitting = true
	_free_later(p, 2.0)

## Drifting leaf/seed motes for harvests and crop growth.
static func leaves(parent: Node, gpos: Vector2, amount: int = 10) -> void:
	var p := _particles(parent, gpos, "leaf", amount, Color(1, 1, 1, 1))
	if p == null:
		return
	p.lifetime = 1.2
	p.explosiveness = 0.85
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(14, 60)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	p.scale_amount_min = Palette.PX * 0.7
	p.scale_amount_max = Palette.PX * 1.4
	p.damping_min = 20.0
	p.damping_max = 50.0
	p.z_index = Z_MID
	_fade_curve(p)
	p.emitting = true
	_free_later(p, 2.4)

# ===========================================================================
# Melee
# ===========================================================================

## A melee swing that actually sweeps. The arc texture is pivoted on the
## attacker, started behind the aim direction and rotated through it, so the
## blade travels instead of a crescent blinking into existence.
##
## `kind` selects the arc: "light" | "heavy" | "thrust".
## `flip` mirrors the sweep so an A-B-A combo alternates shoulders.
static func swing(parent: Node, gpos: Vector2, dir: Vector2, kind: String = "light",
		flip: bool = false) -> void:
	if not _ok(parent):
		return
	# Scales are ABSOLUTE, not multiples of Palette.PX: the arc has to end up the
	# size of the hero's actual reach (~46 px), and the arcs are baked at
	# different radii, so each kind gets its own start/end pair.
	var key: String = "slash_light"
	var arc: float = 1.5
	var dur: float = 0.16
	var k0: float = 0.68        # start scale
	var k1: float = 1.00        # peak scale
	match kind:
		"heavy":
			key = "slash_heavy"
			arc = 2.1
			dur = 0.22
			k0 = 0.58
			k1 = 0.90
		"thrust":
			key = "slash_thrust"
			arc = 0.35
			dur = 0.14
			k0 = 0.45
			k1 = 0.75

	var s := Sprite2D.new()
	s.texture = Assets.tex(key)
	s.position = gpos
	s.scale = Vector2(k0, k0 * Palette.SQUASH)
	s.z_index = Z_MID
	# Over-bright, so the arc blooms against a dark chamber instead of reading as
	# a grey smear. Values above 1 are legal on modulate and clip to white.
	s.modulate = Color(1.30, 1.16, 0.98, 1.0)
	parent.add_child(s)

	# Start the blade behind the aim and sweep it through.
	var half: float = arc * 0.5 * (-1.0 if flip else 1.0)
	var base: float = dir.angle()
	s.rotation = base - half
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "rotation", base + half, dur).set_trans(Tween.TRANS_QUINT) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "scale", Vector2(k1, k1 * Palette.SQUASH), dur)
	tw.tween_property(s, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)

## Legacy entry point (DESIGN.md contract). A single light arc facing `dir`.
static func slash(parent: Node, gpos: Vector2, dir: Vector2) -> void:
	swing(parent, gpos, dir, "light", false)

## The moment of contact: a white-hot flash, a spray of sparks along the blow,
## and a small ground ring for heavy hits.
## `power` 0..1 scales everything, so a combo finisher lands harder than a jab.
static func impact(parent: Node, gpos: Vector2, dir: Vector2 = Vector2.RIGHT,
		power: float = 0.5) -> void:
	if not _ok(parent):
		return
	var s := Sprite2D.new()
	s.texture = Assets.tex("impact")
	s.position = gpos
	s.rotation = randf_range(0.0, TAU)
	var k: float = Palette.PX * lerpf(0.45, 0.95, power)
	s.scale = Vector2(k, k * 0.85)
	s.z_index = Z_HIGH
	parent.add_child(s)
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "scale", Vector2(k * 1.9, k * 1.6), 0.14) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, 0.14)
	tw.chain().tween_callback(s.queue_free)

	sparks(parent, gpos, int(round(lerpf(5.0, 14.0, power))), dir)
	if power > 0.6:
		shockwave(parent, gpos, lerpf(46.0, 78.0, power), Palette.GOLD_L, 0.30)

## A ring of force spreading across the floor. Pre-squashed, drawn under actors.
static func shockwave(parent: Node, gpos: Vector2, radius: float = 60.0,
		color: Color = Palette.GOLD_L, dur: float = 0.34,
		key: String = "ring") -> void:
	if not _ok(parent):
		return
	var s := Sprite2D.new()
	s.texture = Assets.tex(key)
	s.position = gpos
	s.modulate = color
	s.z_index = Z_GROUND
	# "ring" is baked 192 px wide, so scale 1.0 == 96 px radius.
	var k0: float = (radius * 0.25) / 96.0
	var k1: float = radius / 96.0
	s.scale = Vector2(k0, k0)
	parent.add_child(s)
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "scale", Vector2(k1, k1), dur) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)

# ===========================================================================
# Movement
# ===========================================================================

## A frozen ghost of a sprite, left behind by a dash. Several of these in a row
## are what turn a teleport into a movement the eye can follow.
static func afterimage(parent: Node, tex: Texture2D, gpos: Vector2,
		scale: Vector2, color: Color = Color(1.0, 0.75, 0.45, 0.55),
		dur: float = 0.26) -> void:
	if not _ok(parent) or tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.position = gpos
	s.scale = scale
	s.modulate = color
	s.z_index = Z_MID - 1
	parent.add_child(s)
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "modulate:a", 0.0, dur)
	tw.tween_property(s, "scale", scale * 0.9, dur)
	tw.chain().tween_callback(s.queue_free)

## The smear of light along a dash path.
static func streak(parent: Node, gpos: Vector2, dir: Vector2,
		length: float = 1.0) -> void:
	if not _ok(parent):
		return
	var s := Sprite2D.new()
	s.texture = Assets.tex("streak")
	s.position = gpos
	s.rotation = dir.angle() + PI          # trails BEHIND the direction of travel
	s.z_index = Z_MID
	s.modulate = Color(1, 1, 1, 0.85)
	var k: float = Palette.PX * length
	s.scale = Vector2(k * 0.5, k * 0.7)
	parent.add_child(s)
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "scale", Vector2(k * 1.25, k * 0.35), 0.22) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(s.queue_free)

# ===========================================================================
# Light and text
# ===========================================================================

## A light that blooms and dies in a fraction of a second. Used on rescues,
## build completions and heavy hits so those moments physically brighten the room.
static func light_pop(parent: Node, gpos: Vector2, color: Color = Palette.TORCH,
		radius: float = 160.0, dur: float = 0.45) -> void:
	if not _ok(parent) or not (parent is Node2D):
		return
	var l := PointLight2D.new()
	l.texture = Assets.tex("light_soft")
	l.color = color
	l.energy = 0.0
	l.blend_mode = Light2D.BLEND_MODE_ADD
	l.shadow_enabled = false
	l.texture_scale = radius / 128.0
	l.scale = Vector2(1.0, Palette.SQUASH)
	l.position = gpos
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 1.6, dur * 0.22).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(l, "energy", 0.0, dur * 0.78).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(l.queue_free)

## A single sparkle — pickups, ripe crops, a finished build.
static func glint(parent: Node, gpos: Vector2, color: Color = Color(1, 1, 1, 1)) -> void:
	if not _ok(parent):
		return
	var s := Sprite2D.new()
	s.texture = Assets.tex("glint")
	s.position = gpos
	s.modulate = color
	s.scale = Vector2.ZERO
	s.z_index = Z_HIGH
	parent.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(Palette.PX * 1.5, Palette.PX * 1.5), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "scale", Vector2.ZERO, 0.22).set_ease(Tween.EASE_IN)
	tw.tween_callback(s.queue_free)

## Rising damage/reward number with a scale punch, so it registers even in a
## crowded frame.
static func float_text(parent: Node, gpos: Vector2, text: String,
		color: Color = Color(1, 1, 1, 1)) -> void:
	if not _ok(parent):
		return
	var l := Label.new()
	l.text = text
	l.z_index = Z_TEXT
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_font_size_override("font_size", 16)
	l.pivot_offset = Vector2(14, 10)
	l.scale = Vector2(0.4, 0.4)
	# Scatter slightly so a burst of numbers doesn't stack into one blur.
	l.position = gpos + Vector2(randf_range(-8.0, 8.0), randf_range(-4.0, 4.0))
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2(1.15, 1.15), 0.11) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.08)
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 30.0, 0.72) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.72).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)

## Small white burst kept for the DESIGN.md contract; now reads as a real hit.
static func hit_spark(parent: Node, gpos: Vector2) -> void:
	impact(parent, gpos, Vector2.RIGHT, 0.35)

# ===========================================================================
# Internals
# ===========================================================================

static func _ok(parent: Node) -> bool:
	return is_instance_valid(parent) and parent.is_inside_tree()

## Shared CPUParticles2D setup. Returns null (and spawns nothing) if the parent
## has already left the tree, which happens constantly during layer swaps.
static func _particles(parent: Node, gpos: Vector2, tex_key: String, amount: int,
		color: Color) -> CPUParticles2D:
	if not _ok(parent):
		return null
	var p := CPUParticles2D.new()
	p.texture = Assets.tex(tex_key)
	p.position = gpos
	p.amount = maxi(1, amount)
	p.one_shot = true
	p.emitting = false
	p.color = color
	parent.add_child(p)
	return p

## Fade every particle out over its life instead of popping off.
##
## CPUParticles2D has no alpha curve — the lifetime fade goes through `color_ramp`
## (a Gradient), which MULTIPLIES with `color`, so a white-to-transparent ramp
## fades the particle while leaving each emitter's tint intact. One shared
## gradient is reused by every emitter.
static var _fade_ramp: Gradient = null

static func _fade_curve(p: CPUParticles2D) -> void:
	if _fade_ramp == null:
		var g := Gradient.new()
		g.set_offset(0, 0.0)
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_offset(1, 1.0)
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.65, Color(1, 1, 1, 0.85))
		_fade_ramp = g
	p.color_ramp = _fade_ramp

static func _free_later(node: Node, secs: float) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	# Bind the node's OWN queue_free rather than a lambda that captures it: Godot
	# drops a connection automatically when its target object is freed, whereas a
	# capturing lambda outlives the node and warns when the timer fires.
	var t := node.get_tree().create_timer(secs)
	t.timeout.connect(node.queue_free)
