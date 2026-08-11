class_name Iso
extends RefCounted
## Pseudo-3D ("2.5D") presentation kit — the Hades camera in a 2D engine.
##
## THE MODEL
## The game simulates on a flat ground plane, but the camera looks at that plane
## from a low angle, so a step "north" covers less screen than a step "east":
##
##     screen.x = ground.x
##     screen.y = ground.y * Palette.SQUASH   (0.625)
##
## Rather than scaling a parent node (which would deform physics shapes), every
## layer simply *authors* its geometry in screen space already — cells are
## CELL x CELL_Y, not CELL x CELL — and actors compress the Y of their velocity
## with Iso.vel(). Collision stays uniform, circles stay circles, and the floor
## reads as tilted away from you.
##
## Consequences every module must respect:
##  1. A Node2D's `position` is its contact point with the floor (its feet), NOT
##     its visual centre. Anchor body sprites with Iso.anchor_feet().
##  2. Distances between things standing on the floor are ground distances —
##     use Iso.gdist(), never `distance_to`, or ranges become egg-shaped.
##  3. Depth is Y order. Layers set `y_sort_enabled = true` and everything that
##     stands on the floor keeps `z_index == 0` so it sorts by its feet.
##  4. Anything standing on the floor casts a contact shadow (Iso.shadow) —
##     without it a billboard looks like a sticker floating in space.

# Reciprocal of the squash, for converting screen deltas back to ground deltas.
const UNSQUASH := 1.0 / Palette.SQUASH   # 1.6

# ---------------------------------------------------------------------------
# Ground <-> screen maths
# ---------------------------------------------------------------------------

## Screen position of a point given in ground coordinates.
static func to_screen(ground: Vector2) -> Vector2:
	return Vector2(ground.x, ground.y * Palette.SQUASH)

## Ground coordinates of a point given in screen space (e.g. the mouse).
static func to_ground(screen: Vector2) -> Vector2:
	return Vector2(screen.x, screen.y * UNSQUASH)

## Screen-space velocity for a ground-space input direction, so a character
## covers the same *ground* distance in every direction while the floor still
## reads as tilted. Feed the raw Input.get_vector() result straight in.
static func vel(dir: Vector2, speed: float) -> Vector2:
	if dir.length_squared() > 1.0:
		dir = dir.normalized()
	return Vector2(dir.x, dir.y * Palette.SQUASH) * speed

## True distance across the floor between two screen-space points.
static func gdist(a: Vector2, b: Vector2) -> float:
	var d: Vector2 = b - a
	return Vector2(d.x, d.y * UNSQUASH).length()

## Unit direction across the floor, in GROUND space (y not compressed). Use for
## aiming, dot-product cones and knockback direction.
static func gdir(from: Vector2, to: Vector2) -> Vector2:
	var d: Vector2 = to - from
	var g := Vector2(d.x, d.y * UNSQUASH)
	return g.normalized() if g.length_squared() > 0.000001 else Vector2.RIGHT

## Screen-space velocity that walks `from` toward `to` at `speed` along the floor.
static func step(from: Vector2, to: Vector2, speed: float) -> Vector2:
	return vel(gdir(from, to), speed)

## Screen-space offset for a ground-space displacement (knockback, lunges).
static func offset(ground_dir: Vector2, amount: float) -> Vector2:
	return Vector2(ground_dir.x, ground_dir.y * Palette.SQUASH) * amount

# ---------------------------------------------------------------------------
# Billboards
# ---------------------------------------------------------------------------

## Anchor a centred Sprite2D so its BOTTOM edge sits on the node's position —
## the node position becomes the character's contact point with the floor.
## `sink` (texture px) pushes the sprite down into its own shadow so it is
## grounded rather than perched.
static func anchor_feet(s: Sprite2D, sink: float = 0.0) -> void:
	if s == null or s.texture == null:
		return
	s.offset = Vector2(0.0, -s.texture.get_height() * 0.5 + sink)

## Body-sprite scale for the upright cast: PX knocked down by ACTOR_SCALE so the
## hero and husks read at a Hades remove from the world instead of filling it.
static func actor_scale() -> Vector2:
	var k: float = Palette.PX * Palette.ACTOR_SCALE
	return Vector2(k, k)

## Turn a raw centred body Sprite2D into a grounded, Hades-scaled billboard: feet
## anchored to the node origin, knocked down by ACTOR_SCALE, and sunk a hair into
## its own shadow. Returns the base scale so a walk cycle can squash around it.
static func mount_body(s: Sprite2D, sink: float = 4.0) -> Vector2:
	var sc: Vector2 = actor_scale()
	s.scale = sc
	anchor_feet(s, sink)
	return sc

## One frame of the shared walk/idle cycle for a body billboard. `face_left`
## mirrors the sprite (the whole turnaround — the cast is drawn front-3/4 and read
## left or right by flip); walking adds a step-bob and a light squash-stretch, idle
## a slow breathe. Kept off `modulate` and `offset` so hurt-flashes and the feet
## anchor are never fought.
static func walk_anim(s: Sprite2D, base_scale: Vector2, t: float, moving: bool,
		face_left: bool, bob: float = 2.6) -> void:
	if s == null:
		return
	s.flip_h = face_left
	if moving:
		# A soft two-step bob with a gentle squash and a slight lean into the run —
		# smoother and more alive than a flat slide.
		var b: float = absf(sin(t * 8.5))
		s.position.y = -b * bob
		var q: float = sin(t * 17.0) * 0.026
		s.scale = Vector2(base_scale.x * (1.0 + q), base_scale.y * (1.0 - q))
		s.skew = -0.05 if face_left else 0.05
	else:
		var br: float = sin(t * 2.2) * 0.018
		s.position.y = 0.0
		s.scale = Vector2(base_scale.x * (1.0 - br), base_scale.y * (1.0 + br))
		s.skew = 0.0

## Soft elliptical contact shadow, pre-squashed to the ground plane. Added as a
## child of `parent` at its origin, drawn behind the body but above the floor.
## `width` is the shadow's full on-screen width in px.
static func shadow(parent: Node2D, width: float, alpha: float = 0.45) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Assets.tex("shadow")
	var k: float = width / 128.0        # "shadow" is baked 128 px wide
	s.scale = Vector2(k, k)
	s.modulate = Color(0, 0, 0, alpha)
	s.z_index = -1                      # behind the body, above the floor tiles
	s.z_as_relative = true
	parent.add_child(s)
	return s

# ---------------------------------------------------------------------------
# Lighting
# ---------------------------------------------------------------------------

## Dark ambient wash for a whole layer. Point lights add back into it; without
## one of these, lights do nothing visible.
static func ambient(parent: Node, color: Color) -> CanvasModulate:
	var cm := CanvasModulate.new()
	cm.color = color
	parent.add_child(cm)
	return cm

## Warm (or cold) point light. `radius` is the on-screen radius in px.
## Flattened to the ground plane so pools of light lie on the floor rather than
## ballooning up the screen.
static func light(parent: Node2D, color: Color, radius: float,
		energy: float = 1.0, flatten: bool = true) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = Assets.tex("light_soft")
	l.color = color
	l.energy = energy
	l.blend_mode = Light2D.BLEND_MODE_ADD
	l.shadow_enabled = false
	# "light_soft" is baked 256 px across, so texture_scale 1.0 == 128 px radius.
	l.texture_scale = radius / 128.0
	if flatten:
		l.scale = Vector2(1.0, Palette.SQUASH)
	parent.add_child(l)
	return l

## Give a light a living flicker (torches, braziers, the bonfire). Returns the
## tween so callers can keep or kill it.
static func flicker(l: PointLight2D, base: float, amount: float = 0.18,
		period: float = 0.11) -> Tween:
	var tw := l.create_tween()
	tw.set_loops()
	tw.tween_property(l, "energy", base * (1.0 + amount), period) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(l, "energy", base * (1.0 - amount * 0.6), period * 1.7) \
		.set_trans(Tween.TRANS_SINE)
	tw.tween_property(l, "energy", base, period * 1.3).set_trans(Tween.TRANS_SINE)
	return tw

# ---------------------------------------------------------------------------
# Standing props
# ---------------------------------------------------------------------------

## One-liner for the common case: an upright, feet-anchored sprite with a contact
## shadow, ready to be positioned on the floor and y-sorted.
static func prop(parent: Node2D, tex_key: String, pos: Vector2,
		shadow_width: float = 0.0, sink: float = 0.0) -> Node2D:
	var root := Node2D.new()
	root.position = pos
	parent.add_child(root)
	if shadow_width > 0.0:
		shadow(root, shadow_width, 0.38)
	var s := Sprite2D.new()
	s.texture = Assets.tex(tex_key)
	s.scale = Vector2(Palette.PX, Palette.PX)
	root.add_child(s)
	anchor_feet(s, sink)
	return root
