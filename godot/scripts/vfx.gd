class_name Vfx
extends RefCounted
## Fire-and-forget juice for the 2.5D world: embers, dust, slashes, sparks,
## impacts, hit-stop and popping damage numbers. Every call is one-shot and
## self-destructs; callers never hold a handle.
##
## Two rules keep the effects sitting ON the tilted floor instead of floating in
## front of it (see Iso):
##  * anything that SPREADS across the ground is squashed in screen Y — either by
##    a squashed emission footprint, or by squashing the whole emitter node when
##    the particle velocities also need to lie in the floor plane;
##  * anything that RISES (embers, smoke, numbers) travels in un-squashed screen
##    Y, because that axis is "up", not "north".
##
## z_index follows the layer convention: slashes 40, particles 50, text 100.

# --- Shared resources, built once and reused by every burst ---
static var _add_mat: CanvasItemMaterial = null
static var _flare_curve: Curve = null   # flare out, then shrink to nothing
static var _puff_curve: Curve = null    # swell slowly, never shrink
static var _fade_ramp: Gradient = null  # hold, then fade the alpha out
# Bumped by every hitstop() so a later call always wins the restore.
static var _stop_token: int = 0

# ---------------------------------------------------------------------------
# Particle effects
# ---------------------------------------------------------------------------

## The game's signature effect: hot motes lifting off a point and dying out.
## Spawns across a squashed patch of floor, rises in screen Y.
static func embers(parent: Node, gpos: Vector2, amount: int = 16, color: Color = Color("ff6b35")) -> void:
	if not _usable(parent):
		return
	var spread_r: float = 5.0 + float(amount) * 0.45
	var p := _emitter(parent, gpos, "ember", amount, 1.05, spread_r)
	p.direction = Vector2(0, -1)
	p.spread = 34.0
	p.gravity = Vector2(0, -62)         # buoyancy, not gravity: embers climb
	p.initial_velocity_min = 26.0
	p.initial_velocity_max = 88.0
	p.damping_min = 8.0
	p.damping_max = 22.0
	p.scale_amount_min = Palette.PX * 0.55
	p.scale_amount_max = Palette.PX * 1.25
	p.scale_amount_curve = _flare()
	p.angular_velocity_min = -140.0
	p.angular_velocity_max = 140.0
	# Lift the tint toward white so the core reads as hot and the bloom bites.
	p.color = color.lerp(Color(1, 0.95, 0.85), 0.22)
	p.emitting = true
	_free_later(p, 2.4)
	# A big burst gets a soft flash so the glow lands before the motes disperse.
	if amount >= 12:
		_flash(parent, gpos, 44.0 + float(amount) * 1.1, color, 0.30)

## Ground-hugging puff for footsteps, landings and anything scraping the floor.
static func dust(parent: Node, pos: Vector2, amount: int = 7,
		color: Color = Color(0.68, 0.62, 0.53, 0.55)) -> void:
	if not _usable(parent):
		return
	var p := _emitter(parent, pos, "dust", amount, 0.55, 4.0)
	# The puff expands ALONG the floor, so squash the emitter itself: velocities,
	# footprint and the sprites all flatten into the ground plane together.
	p.scale = Vector2(1.0, Palette.SQUASH)
	p.emission_rect_extents = Vector2(5.0, 5.0)
	p.direction = Vector2(1, 0)
	p.spread = 180.0                     # a full ring, kicked outward
	p.gravity = Vector2(0, -14)
	p.initial_velocity_min = 18.0
	p.initial_velocity_max = 52.0
	p.damping_min = 40.0
	p.damping_max = 70.0                 # air-drag: the puff stalls and hangs
	p.scale_amount_min = Palette.PX * 0.8
	p.scale_amount_max = Palette.PX * 1.6
	p.scale_amount_curve = _puff()
	p.color = color
	p.emitting = true
	_free_later(p, 1.6)

# ---------------------------------------------------------------------------
# Melee
# ---------------------------------------------------------------------------

## Melee arc, Hades-style: a bright crescent that snaps in near full size and
## sweeps quickly through the aim direction, trailed by a fainter, wider smear so
## the strike reads as a fast blade pass rather than a growing stamp. `dir` is a
## screen-space aim vector; the arc lives on a squashed plane so it lies on the
## floor. `big` = a crit: larger, hotter, wider sweep.
static func slash(parent: Node, gpos: Vector2, dir: Vector2, big: bool = false) -> void:
	slash_dir(parent, gpos, dir, big, false)

## Directional crescent: sweeps clockwise by default; `ccw` reverses it so a combo's
## second hit visibly returns across the first. `big` = a crit/pounce (larger, hotter).
static func slash_dir(parent: Node, gpos: Vector2, dir: Vector2, big: bool, ccw: bool) -> void:
	if not _usable(parent):
		return
	var start: float = 1.5 if big else 1.15
	var grow: float = 2.5 if big else 1.6
	var sweep: float = 1.15 if big else 0.95
	var dur: float = 0.14 if big else 0.12
	var hot: Color = Color(1.7, 1.45, 1.0, 1.0) if big else Color(1.4, 1.22, 1.0, 1.0)
	var ang: float = Iso.gdir(Vector2.ZERO, dir).angle()
	var sgn: float = -1.0 if ccw else 1.0
	var f: float = ang - sgn * sweep * 0.5
	var t: float = ang + sgn * sweep * 0.5
	# Trailing smear (behind, dimmer, slower) then the crisp leading crescent.
	_slash_arc(parent, gpos, start * 1.08, grow * 1.22, dur * 1.55, f, t,
		Color(hot.r, hot.g, hot.b, 0.32))
	_slash_arc(parent, gpos, start, grow, dur, f, t, hot)

## The càn-quét halo: two hot crescents 180° out of phase, each revolving a full
## turn, so together they read as one spinning blade ring sweeping all around.
static func spin_slash(parent: Node, gpos: Vector2, big: bool = false) -> void:
	if not _usable(parent):
		return
	var grow: float = 3.0 if big else 2.4
	var dur: float = 0.3
	var hot := Color(1.7, 1.45, 1.0, 1.0)
	for k: float in [0.0, PI]:
		_slash_arc(parent, gpos, 1.5, grow * 1.2, dur * 1.12, k, k + TAU,
			Color(hot.r, hot.g, hot.b, 0.3))
		_slash_arc(parent, gpos, 1.25, grow, dur, k, k + TAU, hot)

## The deflect signature: a hard, bright cyan→gold flash + a fast ring. Brighter and
## shorter than any hit — the rarest, most satisfying pop in the game.
static func parry_flash(parent: Node, gpos: Vector2) -> void:
	if not _usable(parent):
		return
	_flash(parent, gpos, 74.0, Palette.CYAN.lerp(Palette.GOLD_L, 0.4), 0.14)
	ring(parent, gpos, 52.0, Palette.CYAN.lerp(Palette.GOLD_L, 0.5), 0.22)

## One crescent on a squashed plane, rotating from `rot_from` to `rot_to` (absolute
## radians — a signed span past ±PI spins a full ring) and fading as it goes.
static func _slash_arc(parent: Node, gpos: Vector2, s0: float, s1: float,
		secs: float, rot_from: float, rot_to: float, mod: Color) -> void:
	var plane := Node2D.new()
	plane.position = gpos
	plane.z_index = 40
	plane.scale = Vector2(s0, s0 * Palette.SQUASH)
	parent.add_child(plane)
	var s := Sprite2D.new()
	s.texture = Assets.tex("slash")
	s.scale = Vector2(Palette.PX, Palette.PX)
	s.rotation = rot_from
	s.modulate = mod
	plane.add_child(s)
	var tw := plane.create_tween()
	tw.tween_property(plane, "scale", Vector2(s1, s1 * Palette.SQUASH), secs) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "rotation", rot_to, secs) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, secs).set_delay(secs * 0.35)
	tw.tween_callback(plane.queue_free)

## Light contact: a few white sparks and a pinprick flash. Cheap, spammable.
static func hit_spark(parent: Node, gpos: Vector2) -> void:
	if not _usable(parent):
		return
	var p := _emitter(parent, gpos, "spark", 7, 0.34, 3.0)
	p.direction = Vector2(0, -1)
	p.spread = 120.0
	p.gravity = Vector2(0, 190)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 210.0
	p.damping_min = 30.0
	p.damping_max = 60.0
	p.scale_amount_min = Palette.PX * 0.5
	p.scale_amount_max = Palette.PX * 1.0
	p.scale_amount_curve = _flare()
	p.color = Color(1, 0.96, 0.86)
	p.emitting = true
	_free_later(p, 1.0)
	_flash(parent, gpos, 34.0, Color(1, 0.9, 0.7), 0.16)

## A solid, weighty hit: expanding ring, a fan of sparks thrown along `dir`
## across the floor, a kick of dust, and a bite of camera trauma.
static func impact(parent: Node, pos: Vector2, dir: Vector2) -> void:
	if not _usable(parent):
		return
	var ground: Vector2 = Iso.gdir(Vector2.ZERO, dir)

	_flash(parent, pos, 76.0, Color(1, 0.86, 0.62), 0.26)

	# Sparks travel along the floor, so the whole emitter is squashed (as in dust)
	# and the cone is aimed with the GROUND direction, not the screen one.
	var p := _emitter(parent, pos, "spark", 14, 0.42, 3.0)
	p.scale = Vector2(1.0, Palette.SQUASH)
	p.emission_rect_extents = Vector2(4.0, 4.0)
	p.direction = ground
	p.spread = 52.0
	p.gravity = Vector2(0, 30)
	p.initial_velocity_min = 130.0
	p.initial_velocity_max = 300.0
	p.damping_min = 90.0
	p.damping_max = 150.0
	p.scale_amount_min = Palette.PX * 0.7
	p.scale_amount_max = Palette.PX * 1.5
	p.scale_amount_curve = _flare()
	p.color = Color(1, 0.88, 0.66)
	p.emitting = true
	_free_later(p, 1.2)

	dust(parent, pos, 6, Color(0.72, 0.66, 0.58, 0.45))
	Main.shake(0.14)

## A crunch star stamped on a decisive hit (a killing blow): the baked impact
## burst snapping out to size and fading. Faces the blow when a direction is given.
static func crunch(parent: Node, pos: Vector2, dir: Vector2 = Vector2.ZERO) -> void:
	if not _usable(parent):
		return
	var s := Sprite2D.new()
	s.texture = Assets.tex("impact")
	s.position = pos
	s.z_index = 60
	s.material = _additive()
	s.rotation = dir.angle() if dir.length_squared() > 0.0001 else 0.0
	s.modulate = Color(1.25, 1.08, 0.85, 1.0)
	var target: float = Palette.PX * 1.35
	s.scale = Vector2(target * 0.3, target * 0.3)
	parent.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(target, target), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.18)
	tw.tween_callback(s.queue_free)

## An expanding ring pulse lying on the floor — portal breaths, rescues, wards.
## Squashed into the ground plane so it reads as a ripple, not a hoop facing you.
static func ring(parent: Node, pos: Vector2, radius: float, color: Color,
		secs: float = 0.6) -> void:
	if not _usable(parent):
		return
	var s := Sprite2D.new()
	s.texture = Assets.tex("glow_ring")
	s.position = pos
	s.z_index = 45
	s.material = _additive()
	s.modulate = Color(color.r, color.g, color.b, 0.9)
	var k: float = radius / 64.0        # "glow_ring" is baked 128 px across
	s.scale = Vector2(k * 0.25, k * 0.25 * Palette.SQUASH)
	parent.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(k, k * Palette.SQUASH), secs) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, secs)
	tw.tween_callback(s.queue_free)

# ---------------------------------------------------------------------------
# Time and text
# ---------------------------------------------------------------------------

## Freeze-frame on a hit. Uses Engine.time_scale, restored by a timer that runs
## on real time; overlapping calls are safe, the newest one owns the restore.
## `strength` is the time scale to hold — smaller bites harder.
static func hitstop(node: Node, seconds: float = 0.06, strength: float = 0.06) -> void:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return
	_stop_token += 1
	var token: int = _stop_token
	Engine.time_scale = clampf(strength, 0.01, 1.0)
	# process_always, not in physics, and ignoring the very time scale we set.
	var t := node.get_tree().create_timer(maxf(seconds, 0.01), true, false, true)
	t.timeout.connect(func() -> void:
		if token == _stop_token:
			Engine.time_scale = 1.0)

## Damage / reward number. Pops in with a slight overshoot, then arcs up and
## sideways and settles before fading — reads as a hit, not a drifting balloon.
static func float_text(parent: Node, gpos: Vector2, text: String, color: Color = Color(1, 1, 1, 1)) -> void:
	if not _usable(parent):
		return
	var holder := Node2D.new()
	holder.position = gpos
	holder.z_index = 100
	holder.scale = Vector2(0.35, 0.35)
	parent.add_child(holder)

	# Centre the label over the holder by hand: a Label anchors to its top-left.
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(140, 0)
	l.position = Vector2(-70, -30)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_font_size_override("font_size", 15)
	holder.add_child(l)

	var drift: float = randf_range(-18.0, 18.0)

	var pop := holder.create_tween()
	pop.tween_property(holder, "scale", Vector2(1.18, 1.18), 0.11) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(holder, "scale", Vector2(1.0, 1.0), 0.09)

	# x drifts steadily while y throws up fast and eases back: a real arc.
	holder.create_tween().tween_property(holder, "position:x", gpos.x + drift, 0.88)
	var arc := holder.create_tween()
	arc.tween_property(holder, "position:y", gpos.y - 36.0, 0.32) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc.tween_property(holder, "position:y", gpos.y - 24.0, 0.56) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var die := holder.create_tween()
	die.tween_interval(0.46)
	die.tween_property(holder, "modulate:a", 0.0, 0.42)
	die.tween_callback(holder.queue_free)

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

static func _usable(parent: Node) -> bool:
	return is_instance_valid(parent) and parent.is_inside_tree()

# Every burst shares this setup: one-shot, explosive, and spawning across a
# patch of FLOOR (hence the squashed emission rectangle).
static func _emitter(parent: Node, pos: Vector2, tex_key: String, amount: int,
		lifetime: float, ground_radius: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = Assets.tex(tex_key)
	p.position = pos
	p.amount = maxi(1, amount)
	p.one_shot = true
	p.explosiveness = 0.9
	p.randomness = 0.45
	p.lifetime = lifetime
	p.z_index = 50
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(ground_radius, ground_radius * Palette.SQUASH)
	p.color_ramp = _ramp()
	parent.add_child(p)
	return p

# Additive disc that blooms and dies — the light half of an impact. Squashed so
# it lies on the floor like a pool rather than facing the camera.
static func _flash(parent: Node, pos: Vector2, width: float, color: Color, secs: float) -> void:
	var s := Sprite2D.new()
	s.texture = Assets.tex("glow_ring")
	s.position = pos
	s.z_index = 50
	s.material = _additive()
	s.modulate = Color(color.r, color.g, color.b, 0.85)
	var k: float = width / 128.0        # "glow_ring" is baked 128 px across
	s.scale = Vector2(k * 0.35, k * 0.35 * Palette.SQUASH)
	parent.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2(k, k * Palette.SQUASH), secs) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, secs)
	tw.tween_callback(s.queue_free)

static func _additive() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat

static func _flare() -> Curve:
	if _flare_curve == null:
		_flare_curve = Curve.new()
		_flare_curve.add_point(Vector2(0.0, 0.55))
		_flare_curve.add_point(Vector2(0.18, 1.0))
		_flare_curve.add_point(Vector2(1.0, 0.05))
	return _flare_curve

static func _puff() -> Curve:
	if _puff_curve == null:
		_puff_curve = Curve.new()
		_puff_curve.add_point(Vector2(0.0, 0.45))
		_puff_curve.add_point(Vector2(1.0, 1.0))
	return _puff_curve

static func _ramp() -> Gradient:
	if _fade_ramp == null:
		_fade_ramp = Gradient.new()
		_fade_ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		_fade_ramp.colors = PackedColorArray([
			Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0),
		])
	return _fade_ramp

static func _free_later(node: Node, secs: float) -> void:
	var t := node.get_tree().create_timer(secs)
	t.timeout.connect(node.queue_free)
