class_name ArtProps
extends RefCounted
## Freestanding scenery and interactables: the return portal, the supply gate, the
## cage, the brazier, the village bonfire, the dungeon arch, dead trees, stumps,
## rocks, fences, barrels, banners, the two floor decals and the four pickups.
##
## Baked through the shared `Art` engine and registered with the Assets autoload via
## `a.put(key, image)`. Runs after the legacy catalogue, so every key defined here
## replaces the old flat top-down version of that sprite.
##
## Everything is drawn for the 2.5D camera: one key light from the upper left, every
## side face sheared up-and-left by RECEDE so the whole catalogue agrees on one point
## of view, and a mandatory contact shade under every feet-anchored mass so nothing
## reads as a sticker. The brazier and the bonfire bake their own bloom (Art.glow) so
## they already read as light sources before the engine's PointLight2D lands on top.

# ---------------------------------------------------------------------------
# Drawing constants — the shared art-direction numbers
# ---------------------------------------------------------------------------

# Shear for every side face and every top-face depth. Depth 40 lands at (-14, -12).
const RECEDE_K := Vector2(-0.36, -0.30)

# Anything raised off the floor drops its shade along here, at 0.45 * its height.
const SHADOW_DIR := Vector2(0.73, 0.69)

# Freestanding prop: heavy sticker outline, two-step form shading, warm rim.
const OW := 5.0
const OW_IN := 2.5
const GRAD := 0.20
const RIM := 0.60

# Pickup / small prop: thinner line, gentler gradient, gold rim so it pops off a
# dark dungeon floor.
const OW_S := 3.5
const OW_S_IN := 1.5
const GRAD_S := 0.18
const RIM_S := 0.55

# Cold rim for the dungeon props. Palette.STEEL is *darker* than the stone it would
# edge, so the cold highlight is STEEL lifted toward the key light instead.
const RIM_COLD := Color("9fa9bd")


static func bake(a: Node) -> void:
	var t__portal := Time.get_ticks_msec()
	a.put("portal", _portal())
	print("TIME portal ", Time.get_ticks_msec() - t__portal)
	var t__supply_gate := Time.get_ticks_msec()
	a.put("supply_gate", _supply_gate())
	print("TIME supply_gate ", Time.get_ticks_msec() - t__supply_gate)
	var t__cage := Time.get_ticks_msec()
	a.put("cage", _cage())
	print("TIME cage ", Time.get_ticks_msec() - t__cage)
	var t__brazier := Time.get_ticks_msec()
	a.put("brazier", _brazier())
	print("TIME brazier ", Time.get_ticks_msec() - t__brazier)
	var t__bonfire := Time.get_ticks_msec()
	a.put("bonfire", _bonfire())
	print("TIME bonfire ", Time.get_ticks_msec() - t__bonfire)
	var t__arch := Time.get_ticks_msec()
	a.put("arch", _arch())
	print("TIME arch ", Time.get_ticks_msec() - t__arch)
	var t__dead_tree := Time.get_ticks_msec()
	a.put("dead_tree", _dead_tree())
	print("TIME dead_tree ", Time.get_ticks_msec() - t__dead_tree)
	var t__stump := Time.get_ticks_msec()
	a.put("stump", _stump())
	print("TIME stump ", Time.get_ticks_msec() - t__stump)
	var t__rock_s := Time.get_ticks_msec()
	a.put("rock_s", _rock_s())
	print("TIME rock_s ", Time.get_ticks_msec() - t__rock_s)
	var t__rock_l := Time.get_ticks_msec()
	a.put("rock_l", _rock_l())
	print("TIME rock_l ", Time.get_ticks_msec() - t__rock_l)
	var t__fence := Time.get_ticks_msec()
	a.put("fence", _fence())
	print("TIME fence ", Time.get_ticks_msec() - t__fence)
	var t__barrel := Time.get_ticks_msec()
	a.put("barrel", _barrel())
	print("TIME barrel ", Time.get_ticks_msec() - t__barrel)
	var t__banner := Time.get_ticks_msec()
	a.put("banner", _banner())
	print("TIME banner ", Time.get_ticks_msec() - t__banner)
	var t__bones := Time.get_ticks_msec()
	a.put("bones", _bones())
	print("TIME bones ", Time.get_ticks_msec() - t__bones)
	var t__rubble := Time.get_ticks_msec()
	a.put("rubble", _rubble())
	print("TIME rubble ", Time.get_ticks_msec() - t__rubble)
	# Living nature for the sunlit sanctuary base.
	a.put("tree", _tree())
	a.put("bush", _bush())
	a.put("flowers", _flowers())
	a.put("reeds", _reeds())
	a.put("bridge", _bridge())
	var t__mat_wood := Time.get_ticks_msec()
	a.put("material_wood", _mat_wood())
	print("TIME material_wood ", Time.get_ticks_msec() - t__mat_wood)
	var t__mat_stone := Time.get_ticks_msec()
	a.put("material_stone", _mat_stone())
	print("TIME material_stone ", Time.get_ticks_msec() - t__mat_stone)
	var t__mat_iron := Time.get_ticks_msec()
	a.put("material_iron", _mat_iron())
	print("TIME material_iron ", Time.get_ticks_msec() - t__mat_iron)
	var t__mat_food := Time.get_ticks_msec()
	a.put("material_food", _mat_food())
	print("TIME material_food ", Time.get_ticks_msec() - t__mat_food)


# ===========================================================================
# Geometry helpers — the engine has no boolean subtraction and no rotation, so
# rings are necklaces, tapers are segment runs and side faces are shifted copies.
# ===========================================================================

## Screen offset of a face `d` px deep. Everything recedes up-and-left.
static func _recede(d: float) -> Vector2:
	return RECEDE_K * d




## Fan-triangulate a convex polygon given as Vector2s.
##
## Each triangle is pushed `bloat` px out from its own centroid so the fan's internal
## diagonals OVERLAP. Without that, two triangles meeting on an exact shared edge both
## report distance 0 there, and the union's SDF creases into a bright seam straight
## across the shape — the single most visible artefact of drawing polygons this way.
static func _poly(pts: Array, bloat: float = 1.3) -> Array:
	var out: Array = []
	var p0: Vector2 = pts[0]
	for i in range(1, pts.size() - 1):
		var pa: Vector2 = pts[i]
		var pb: Vector2 = pts[i + 1]
		var mid: Vector2 = (p0 + pa + pb) / 3.0
		var a: Vector2 = p0 + (p0 - mid).normalized() * bloat
		var b: Vector2 = pa + (pa - mid).normalized() * bloat
		var c: Vector2 = pb + (pb - mid).normalized() * bloat
		out.append(Art.t(a.x, a.y, b.x, b.y, c.x, c.y))
	return out


## Ring or arc built from chained segments: smooth, and far cheaper than a bead
## necklace because a handful of prims covers the whole locus. Angles are radians,
## y down, so -PI/2 is the top of the locus.
static func _arc(cx: float, cy: float, rx: float, ry: float,
		a0: float, a1: float, n: int, r: float) -> Array:
	var out: Array = []
	var prev := Vector2(cx + rx * cos(a0), cy + ry * sin(a0))
	for i in range(1, n + 1):
		var ang: float = a0 + (a1 - a0) * (float(i) / float(n))
		var p := Vector2(cx + rx * cos(ang), cy + ry * sin(ang))
		out.append(Art.s(prev.x, prev.y, p.x, p.y, r))
		prev = p
	return out


## Ring of separate round beads on an elliptical locus, for the arch's masonry and
## the portal's ripples where the beading is the point.
static func _necklace(cx: float, cy: float, rx: float, ry: float,
		a0: float, a1: float, n: int, r: float) -> Array:
	var out: Array = []
	var closed: bool = absf(a1 - a0) >= TAU - 0.001
	var den: float = float(n) if closed else float(maxi(n - 1, 1))
	for i in range(n):
		var ang: float = a0 + (a1 - a0) * (float(i) / den)
		out.append(Art.c(cx + rx * cos(ang), cy + ry * sin(ang), r))
	return out


## Flat-fill a necklace bead by bead. One paint() over the whole ring would evaluate
## every bead's SDF for every pixel of the ring's bounding box; per-bead boxes draw
## the same picture for a fraction of the cost.
static func _beads(im: Image, prims: Array, col: Color, clip: Array = []) -> void:
	for p in prims:
		Art.paint(im, [p], col, col, 0.001, 0.0, clip)


## A tapering limb. Art.s carries a single radius, so branches, roots and horns are
## runs of overlapping segments whose radius shrinks along the run.
static func _taper(ax: float, ay: float, bx: float, by: float,
		r0: float, r1: float, n: int) -> Array:
	var out: Array = []
	var a := Vector2(ax, ay)
	var b := Vector2(bx, by)
	for i in range(n):
		var p0 := a.lerp(b, float(i) / float(n))
		var p1 := a.lerp(b, float(i + 1) / float(n))
		out.append(Art.s(p0.x, p0.y, p1.x, p1.y, lerpf(r0, r1, float(i + 1) / float(n))))
	return out


## A flame teardrop: a round belly drawn out to a point. Stack three of these, each
## narrower and taller-based than the last, to get hot core / warm body / soft edge.
static func _teardrop(cx: float, base_y: float, tip_y: float, w: float) -> Array:
	var belly_y: float = base_y - w * 0.55
	return [
		Art.c(cx, belly_y, w),
		Art.t(cx, tip_y, cx - w * 0.82, belly_y, cx + w * 0.82, belly_y),
	]


# ===========================================================================
# Lighting helpers — the two shades that stop a sprite being a sticker
# ===========================================================================

## The mandatory contact shade. Drawn FIRST on every feet-anchored prop; `w` is the
## widest drawn mass. Squashed, because it lies on the tilted plane.
static func _ground(im: Image, cx: float, feet_y: float, w: float) -> void:
	Art.shade(im, [Art.e(cx, feet_y - 3.0, w * 0.52, w * 0.15)], Palette.INK, 0.55, [], 5.0)


## Self-occlusion crescent sunk into the bottom `depth` px of one mass and clipped to
## it, so the form domes toward the key light instead of reading as a flat cut-out.
static func _ao(im: Image, mass: Array, cx: float, bot: float, rx: float, depth: float) -> void:
	var ry: float = depth * 3.0
	Art.shade(im, [Art.e(cx + rx * 0.18, bot - depth + ry, rx * 1.2, ry)],
			Palette.INK, 0.28, mass, 4.0)


## Drop shade of a raised piece onto what is beneath it, thrown along SHADOW_DIR by
## 0.45 * the height it stands off that surface.
static func _drop(im: Image, prims: Array, h: float, clip: Array = [], alpha: float = 0.35) -> void:
	Art.shade(im, Art.shift(prims, SHADOW_DIR * (0.45 * h)), Palette.INK, alpha, clip, 3.0)


# ===========================================================================
# PORTAL 140 x 180 — the one cold light in the village
# ===========================================================================
static func _portal() -> Image:
	var im := Art.img(140, 180)
	var cx := 70.0
	# The opening: a slab with a round head. Doubles as the clip for the arcane light.
	var hole: Array = [Art.rr(cx, 130.0, 32.0, 48.0, 8.0), Art.c(cx, 96.0, 32.0)]
	# Legs and arch are painted separately (the arch overlaps and hides the legs'
	# top outline), which keeps each paint's bounding box small.
	var legs: Array = [Art.rr(26.0, 128.0, 14.0, 50.0, 4.0), Art.rr(114.0, 128.0, 14.0, 50.0, 4.0)]
	# Chained segments, not beads: a bead necklace scallops the outer silhouette.
	var span: Array = _arc(cx, 96.0, 44.0, 44.0, PI, TAU, 10, 15.0)
	var stone: Color = Palette.STONE2_D.darkened(0.22)

	_ground(im, cx, 178.0, 116.0)
	Art.shade(im, [Art.e(cx, 172.0, 52.0, 14.0)], Palette.CYAN, 0.24, [], 9.0)
	# A second copy of legs and arch, receded 30 px: that is the stone's thickness,
	# and being a left/top return face it sits two steps lighter than the front.
	var back := _recede(30.0)
	Art.paint(im, Art.shift(legs, back), stone.lightened(0.24), Palette.OUTLINE, OW, 0.08)
	Art.paint(im, Art.shift(span, back), stone.lightened(0.24), Palette.OUTLINE, OW, 0.08)

	Art.glow(im, cx, 96.0, 62.0, Palette.CYAN, 0.30)
	Art.paint(im, hole, Palette.INK, Palette.INK, 1.0, 0.0)
	Art.radial(im, cx, 96.0, 40.0, 54.0, Palette.CYAN, 1.6, 0.15)
	# Three ripples in the rift. Beads, not a ring — it should look unstable.
	_beads(im, _necklace(cx, 96.0, 30.0, 30.0, 0.0, TAU, 16, 3.2), Palette.CYAN_D, hole)
	_beads(im, _necklace(cx, 96.0, 39.0, 39.0, 0.0, TAU, 20, 3.6), Palette.CYAN_D, hole)
	_beads(im, _necklace(cx, 96.0, 48.0, 48.0, 0.0, TAU, 24, 3.0), Palette.CYAN_D, hole)
	# Where the rift meets the floor it spills forward instead of stopping dead.
	Art.shade(im, [Art.e(cx, 176.0, 30.0, 11.0)], Palette.CYAN, 0.5, hole, 7.0)

	Art.paint(im, legs, stone, Palette.OUTLINE, OW, GRAD, [], 0.5, Palette.RIM)
	Art.paint(im, span, stone, Palette.OUTLINE, OW, 0.14, [], 0.5, Palette.RIM)
	# Joint lines cut the arch into voussoirs so it is masonry, not a bent tube.
	for i in range(1, 7):
		var ang: float = PI + PI * float(i) / 7.0
		var d := Vector2(cos(ang), sin(ang))
		var p0 := Vector2(cx, 96.0) + d * 30.0
		var p1 := Vector2(cx, 96.0) + d * 59.0
		Art.shade(im, [Art.s(p0.x, p0.y, p1.x, p1.y, 1.4)], Palette.INK, 0.45, span, 1.5)
	# Keystone: a trapezoid seated on the crown, one value up.
	var key: Array = _poly([Vector2(54, 28), Vector2(86, 28), Vector2(80, 56), Vector2(60, 56)])
	Art.paint(im, key, Palette.STONE2_D, Palette.OUTLINE, OW, GRAD, [], 0.55, Palette.RIM)
	Art.shade(im, [Art.s(58.0, 32.0, 62.0, 54.0, 2.0)], Palette.GOLD_L, 0.3, key, 1.5)
	# The rift bounces cyan onto the inside face of its own frame.
	var frame: Array = legs + span
	Art.shade(im, [Art.rr(cx, 130.0, 43.0, 59.0, 12.0), Art.c(cx, 96.0, 43.0)],
			Palette.CYAN, 0.26, frame, 11.0)
	_ao(im, legs, cx, 178.0, 58.0, 16.0)
	return im


# ===========================================================================
# SUPPLY GATE 176 x 176 — timber posts, a lintel, crates receding behind
# ===========================================================================
static func _supply_gate() -> Image:
	var im := Art.img(176, 176)
	_ground(im, 88.0, 174.0, 148.0)

	# Three crates at three depths. Deepest first so the nearer ones overlap it, and
	# each shifted by RECEDE so the stack reads as going back, not stacking up.
	var depths: Array[float] = [56.0, 32.0, 10.0]
	var spots: Array[Vector2] = [Vector2(58, 138), Vector2(118, 146), Vector2(86, 158)]
	for i in range(3):
		var o: Vector2 = spots[i] + _recede(depths[i])
		var tone: Color = Palette.WOOD2_D.darkened(0.30 - 0.13 * float(i))
		var box: Array = [Art.rr(o.x, o.y, 23.0, 18.0, 3.0)]
		Art.paint(im, _poly([o + Vector2(-23, -18), o + Vector2(23, -18),
				o + Vector2(23, -18) + _recede(16), o + Vector2(-23, -18) + _recede(16)]),
				tone.lightened(0.30), Palette.OUTLINE, OW_IN, 0.0)
		Art.paint(im, box, tone, Palette.OUTLINE, OW_IN, 0.18, [], 0.35, Palette.RIM)
		# A plank seam and a slat, so a crate is not just a brown rectangle.
		Art.shade(im, [Art.s(o.x - 23, o.y - 4, o.x + 23, o.y - 4, 1.4)], Palette.WOOD_D, 0.65, box, 1.5)
		Art.shade(im, [Art.s(o.x - 23, o.y + 8, o.x + 23, o.y + 8, 1.4)], Palette.WOOD_D, 0.65, box, 1.5)
		Art.shade(im, [Art.e(o.x + 9, o.y + 17, 24.0, 9.0)], Palette.INK, 0.32, box, 4.0)

	# The gate itself: two posts and a lintel, each with a lit left return face.
	var post_l: Array = [Art.rr(30.0, 108.0, 13.0, 66.0, 4.0)]
	var post_r: Array = [Art.rr(146.0, 108.0, 13.0, 66.0, 4.0)]
	var lintel: Array = [Art.rr(88.0, 52.0, 76.0, 11.0, 4.0)]
	var back := _recede(22.0)
	for piece in [post_l, post_r, lintel]:
		var q: Dictionary = piece[0]
		var c: Vector2 = q["c"]
		var hw: float = q["hw"]
		var hh: float = q["hh"]
		Art.paint(im, _poly([c + Vector2(-hw, -hh), c + Vector2(-hw, hh),
				c + Vector2(-hw, hh) + back, c + Vector2(-hw, -hh) + back]),
				Palette.WOOD2.lightened(0.08), Palette.OUTLINE, OW_IN, 0.06)
	for piece2 in [post_l, post_r]:
		Art.paint(im, piece2, Palette.WOOD2_D, Palette.OUTLINE, OW, GRAD, [], RIM, Palette.RIM)
	Art.paint(im, lintel, Palette.WOOD2_D, Palette.OUTLINE, OW, 0.14, [], RIM, Palette.RIM)
	# Plank lines so the timber is sawn, not moulded.
	for py in [92.0, 124.0]:
		var y: float = py
		Art.shade(im, [Art.s(17.0, y, 43.0, y, 1.3)], Palette.WOOD_D, 0.6, post_l, 1.5)
		Art.shade(im, [Art.s(133.0, y, 159.0, y, 1.3)], Palette.WOOD_D, 0.6, post_r, 1.5)

	# Iron strap bands with rivets — the gate's only bright metal.
	for band in [Vector2(30, 74), Vector2(30, 142), Vector2(146, 74), Vector2(146, 142)]:
		var b: Vector2 = band
		Art.paint(im, [Art.rr(b.x, b.y, 15.0, 4.5, 1.5)], Palette.STEEL, Palette.OUTLINE, OW_IN, 0.30)
		Art.shade(im, [Art.s(b.x - 13, b.y - 3, b.x + 13, b.y - 3, 1.1)], Palette.GOLD_L, 0.45, [], 1.2)
		Art.dot(im, b.x - 9, b.y + 0.5, 2.1, 2.1, Palette.GOLD_L)
		Art.dot(im, b.x + 9, b.y + 0.5, 2.1, 2.1, Palette.GOLD_L)

	# Rolled canvas lashed under the lintel, with the coil showing at both ends.
	var roll: Array = [Art.s(40.0, 78.0, 136.0, 78.0, 10.0)]
	_drop(im, roll, 16.0, post_l + post_r, 0.30)
	Art.paint(im, roll, Palette.CREAM.darkened(0.38), Palette.OUTLINE, OW_IN, 0.22, [], 0.5, Palette.RIM)
	for ex in [40.0, 136.0]:
		var x: float = ex
		Art.paint(im, _arc(x, 78.0, 6.0, 6.0, -PI * 0.6, PI * 0.9, 6, 1.3),
				Palette.CREAM.darkened(0.55), Palette.CREAM.darkened(0.55), 0.001, 0.0, roll)
	for lx in [64.0, 88.0, 112.0]:
		var lxx: float = lx
		Art.paint(im, [Art.rr(lxx, 78.0, 3.2, 12.0, 1.5)], Palette.WOOD2_D.darkened(0.4),
				Palette.OUTLINE, 1.2, 0.0)

	# Lamp hanging under the lintel — the warm point the silhouette hangs off.
	Art.glow(im, 88.0, 40.0, 32.0, Palette.TORCH, 0.36)
	Art.paint(im, [Art.rr(88.0, 28.0, 2.5, 9.0, 1.0)], Palette.STEEL, Palette.OUTLINE, 1.5, 0.0)
	Art.paint(im, [Art.c(88.0, 41.0, 10.0)], Palette.GOLD, Palette.OUTLINE, OW_S, 0.0)
	Art.dot(im, 85.5, 38.5, 4.6, 4.6, Palette.GOLD_L)
	_ao(im, post_l, 30.0, 174.0, 14.0, 16.0)
	_ao(im, post_r, 146.0, 174.0, 14.0, 16.0)
	return im


# ===========================================================================
# CAGE 128 x 132 — an escape already happened
# ===========================================================================
static func _cage() -> Image:
	var im := Art.img(128, 132)
	var cx := 64.0
	var rx := 46.0
	var ry := 15.0
	var y_top := 30.0
	var y_bot := 114.0
	var iron: Color = Palette.STONE2_D.darkened(0.22)
	_ground(im, cx, 130.0, 104.0)

	# The far side of the cylinder, two values down, so you see THROUGH the cage.
	for i in range(5):
		var tb: float = PI + PI * (float(i) + 0.5) / 5.0
		var bxb: float = cx + rx * cos(tb)
		var yob: float = ry * sin(tb)
		Art.paint(im, [Art.s(bxb, y_top + yob, bxb, y_bot + yob, 3.2)], iron.darkened(0.45),
				Palette.OUTLINE, 1.4, 0.20)
	# Floor of the cage and the dark it holds.
	Art.paint(im, [Art.e(cx, y_bot, rx, ry)], Palette.INK, Palette.OUTLINE, OW_IN, 0.0)
	Art.shade(im, [Art.e(cx, 74.0, 40.0, 40.0)], Palette.INK, 0.55, [], 16.0)
	# Straw on the cage floor: lying, so near-horizontal and squashed.
	for i in range(7):
		var h := Art.hash01(i * 37 + 5)
		var sx: float = 32.0 + h * 58.0
		var sy: float = 110.0 + Art.hash01(i * 37 + 6) * 11.0
		Art.flat(im, [Art.s(sx, sy, sx + 10.0 + h * 9.0, sy - 2.0 + h * 4.0, 1.6)], Palette.SOIL)

	# Seven near-side bars. sin(theta) dips the front of both rims toward the camera,
	# which is what makes the cage read as round. Each bar is its own paint so the
	# engine only scans a sliver of the canvas per bar.
	var bars: Array = []
	for i in range(7):
		var th: float = PI * float(i) / 6.0
		var bx: float = cx + rx * cos(th)
		var yo: float = ry * sin(th)
		var bar: Array = []
		if i <= 1:
			# The two right-hand bars are bent outward — something got out of here.
			var bow: float = 13.0 - 4.0 * float(i)
			bar = [
				Art.s(bx, y_top + yo, bx + bow * 0.2, y_top + yo + 32.0, 3.6),
				Art.s(bx + bow * 0.2, y_top + yo + 32.0, bx + bow, y_top + yo + 56.0, 3.6),
				Art.s(bx + bow, y_top + yo + 56.0, bx + bow * 0.4, y_bot + yo, 3.6),
			]
		else:
			bar = [Art.s(bx, y_top + yo, bx, y_bot + yo, 3.6)]
		Art.paint(im, bar, iron, Palette.OUTLINE, OW_IN, 0.26, [], 0.6, RIM_COLD)
		bars.append_array(bar)
	# Cold rake down the left of every bar, inset enough to need no clip pass.
	for b in bars:
		var q: Dictionary = b
		var pa: Vector2 = q["a"]
		var pb: Vector2 = q["b"]
		Art.shade(im, [Art.s(pa.x - 1.3, pa.y + 2.0, pb.x - 1.3, pb.y - 2.0, 1.1)],
				Palette.IRON, 0.45, [], 1.2)

	# Top and bottom hoops, chained segments so the iron is smooth, not knobbly.
	Art.paint(im, _arc(cx, y_top, rx, ry, 0.0, TAU, 18, 3.7), iron.lightened(0.12),
			Palette.OUTLINE, OW_IN, 0.22, [], 0.6, RIM_COLD)
	Art.paint(im, _arc(cx, y_bot, rx, ry, 0.0, TAU, 18, 3.7), iron.darkened(0.15),
			Palette.OUTLINE, OW_IN, 0.22, [], 0.35, RIM_COLD)

	# A rag knotted on a bar — someone was kept here.
	var rag: Array = [Art.c(38.0, 56.0, 6.5),
			Art.t(34.0, 60.0, 26.0, 90.0, 42.0, 76.0),
			Art.t(42.0, 60.0, 52.0, 84.0, 38.0, 78.0)]
	Art.paint(im, rag, Palette.WINE, Palette.OUTLINE, OW_IN, 0.24, [], 0.5, Palette.RIM)
	Art.shade(im, [Art.s(31.0, 64.0, 28.0, 86.0, 2.2)], Palette.WINE.lightened(0.28), 0.7, rag, 2.0)
	# Where the cage meets the floor.
	Art.shade(im, [Art.e(cx, 126.0, 48.0, 10.0)], Palette.INK, 0.4, [], 6.0)
	return im


# ===========================================================================
# BRAZIER 80 x 140 — the dungeon's light source
# ===========================================================================
static func _brazier() -> Image:
	var im := Art.img(80, 140)
	_ground(im, 40.0, 136.0, 74.0)

	# Three splayed legs; the back one is shorter so the tripod reads as a tripod.
	var legs: Array = [
		Art.s(40.0, 84.0, 9.0, 136.0, 6.0),
		Art.s(40.0, 84.0, 71.0, 136.0, 6.0),
		Art.s(40.0, 84.0, 40.0, 120.0, 6.0),
	]
	Art.paint(im, legs, Palette.STEEL, Palette.OUTLINE, OW, 0.26, [], 0.55, RIM_COLD)
	for lg in legs:
		var q: Dictionary = lg
		var pa: Vector2 = q["a"]
		var pb: Vector2 = q["b"]
		Art.shade(im, [Art.s(pa.x - 1.8, pa.y + 4.0, pb.x - 1.8, pb.y - 4.0, 1.4)],
				Palette.IRON, 0.35, legs, 1.5)

	# A wide bowl, so the fire has something to sit in that still reads at 40 px.
	var bowl: Array = [Art.e(40.0, 68.0, 31.0, 13.0), Art.rr(40.0, 77.0, 23.0, 12.0, 11.0)]
	Art.paint(im, bowl, Palette.STEEL, Palette.OUTLINE, OW, 0.28, [], 0.60, Palette.GOLD_L)
	Art.shade(im, [Art.e(37.0, 64.0, 27.0, 8.0)], Palette.GOLD_L, 0.42,
			[Art.e(40.0, 68.0, 31.0, 13.0)], 3.0)
	_ao(im, bowl, 40.0, 88.0, 23.0, 10.0)

	# Coals, then the bloom, then the flame — so the glow washes over the metal it is
	# actually lighting instead of sitting behind everything.
	for i in range(8):
		var h := Art.hash01(i * 53 + 11)
		Art.dot(im, 16.0 + h * 48.0, 61.0 + Art.hash01(i * 53 + 12) * 8.0,
				4.0 + h * 3.5, 3.0 + h * 2.0, Palette.TORCH)
	for i in range(4):
		Art.dot(im, 26.0 + float(i) * 9.5, 62.0 + float(i % 2) * 3.0, 3.4, 2.5, Palette.TORCH_L)
	Art.glow(im, 40.0, 46.0, 48.0, Palette.TORCH, 0.34)
	# Warm spill onto the floor between the legs.
	Art.shade(im, [Art.e(40.0, 130.0, 36.0, 11.0)], Palette.TORCH, 0.18, [], 8.0)

	Art.flat(im, _teardrop(40.0, 62.0, 14.0, 18.0), Palette.TORCH)
	Art.flat(im, _teardrop(40.0, 62.0, 28.0, 11.0), Palette.TORCH_L)
	Art.flat(im, _teardrop(40.0, 62.0, 40.0, 6.5), Palette.GOLD_L)
	return im


# ===========================================================================
# BONFIRE 140 x 140 — the Global Warmth Index made physical
# ===========================================================================
static func _bonfire() -> Image:
	var im := Art.img(140, 140)
	_ground(im, 70.0, 138.0, 124.0)

	# Ring of seven stones on a squashed locus, back row first so the front overlaps
	# it; each gets a lit chip up-left and an INK crescent down-right, so it domes.
	var ring: Array[Vector2] = []
	for i in range(7):
		var ang: float = -PI * 0.5 + TAU * float(i) / 7.0
		ring.append(Vector2(70.0 + 54.0 * cos(ang), 108.0 + 24.0 * sin(ang)))
	ring.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.y < q.y)
	for i in range(ring.size()):
		var p: Vector2 = ring[i]
		var r: float = 9.0 + Art.hash01(i * 71 + 3) * 4.0
		var stone: Array = [Art.e(p.x, p.y, r, r * 0.55)]
		Art.paint(im, stone, Palette.STONE2_D, Palette.OUTLINE, OW_IN, 0.18, [], 0.5, Palette.RIM)
		Art.shade(im, [Art.e(p.x - r * 0.3, p.y - r * 0.25, r * 0.6, r * 0.3)],
				Palette.STONE2, 0.55, stone, 2.0)
		Art.shade(im, [Art.e(p.x + r * 0.35, p.y + r * 0.45, r * 0.7, r * 0.4)],
				Palette.INK, 0.35, stone, 2.5)

	# Five crossed logs, each with end grain on the end you can see.
	var logs: Array[Vector4] = [
		Vector4(30, 110, 100, 88), Vector4(106, 108, 38, 86),
		Vector4(42, 96, 98, 106), Vector4(70, 82, 110, 102), Vector4(70, 84, 32, 100),
	]
	for l in logs:
		Art.paint(im, [Art.s(l.x, l.y, l.z, l.w, 7.0)], Palette.WOOD2_D, Palette.OUTLINE,
				OW_IN, 0.26, [], 0.5, Palette.RIM)
		Art.dot(im, l.x, l.y, 6.2, 6.6, Palette.WOOD2, 1.5)
		Art.dot(im, l.x, l.y, 2.6, 2.9, Palette.WOOD2_D)
		Art.shade(im, [Art.s(l.x, l.y + 3.5, l.z, l.w + 3.5, 2.5)], Palette.INK, 0.35,
				[Art.s(l.x, l.y, l.z, l.w, 7.0)], 3.0)

	Art.glow(im, 70.0, 74.0, 62.0, Palette.EMBER, 0.36)
	# Hot heart burning down inside the log pile.
	Art.dot(im, 70.0, 98.0, 22.0, 10.0, Palette.TORCH)
	Art.dot(im, 70.0, 97.0, 12.0, 5.5, Palette.TORCH_L)

	Art.flat(im, _teardrop(70.0, 96.0, 20.0, 26.0), Palette.EMBER)
	Art.flat(im, _teardrop(70.0, 96.0, 40.0, 16.0), Palette.TORCH)
	Art.flat(im, _teardrop(70.0, 96.0, 56.0, 9.5), Palette.GOLD_L)
	# Embers lifting off the flame.
	for i in range(6):
		var h := Art.hash01(i * 97 + 17)
		var r: float = 1.6 + h * 1.7
		Art.dot(im, 42.0 + h * 56.0, 12.0 + Art.hash01(i * 97 + 18) * 50.0, r, r, Palette.TORCH_L)
	return im


# ===========================================================================
# ARCH 176 x 176 — the dungeon entrance, cut voussoir by voussoir
# ===========================================================================
static func _arch() -> Image:
	var im := Art.img(176, 176)
	var cx := 88.0
	var cy := 96.0
	var ctr := Vector2(cx, cy)
	_ground(im, cx, 174.0, 152.0)

	# The soffit: a copy of the whole ring pushed back, so the arch has thickness and
	# you can see you are looking into a passage rather than at a painted hoop. Built
	# from chained segments — beads would scallop the outer edge.
	var soffit: Array = _arc(cx, cy, 63.0, 63.0, PI, TAU, 11, 14.0)
	soffit.append(Art.rr(26.0, 140.0, 13.0, 36.0, 2.0))
	soffit.append(Art.rr(150.0, 140.0, 13.0, 36.0, 2.0))
	Art.paint(im, Art.shift(soffit, _recede(30.0)), Palette.PLUM_L.darkened(0.40),
			Palette.OUTLINE, OW_IN, 0.10)

	# The opening, and the dark the passage dies into. No horizon, just VOID.
	var hole: Array = [Art.rr(cx, 138.0, 50.0, 38.0, 0.0), Art.c(cx, cy, 50.0)]
	Art.paint(im, hole, Palette.PLUM, Palette.INK, 1.0, 0.0)
	Art.shade(im, [Art.rr(cx, 214.0, 60.0, 62.0, 0.0)], Palette.VOID, 0.95, hole, 52.0)
	Art.shade(im, [Art.c(cx, 42.0, 42.0)], Palette.PLUM_L, 0.40, hole, 20.0)
	# One lit step just inside the threshold, so the passage has a floor.
	Art.shade(im, [Art.e(cx, 172.0, 40.0, 9.0)], Palette.PLUM_L, 0.55, hole, 6.0)

	# Piers on plinths.
	var piers: Array = [Art.rr(26.0, 138.0, 13.0, 34.0, 2.0), Art.rr(150.0, 138.0, 13.0, 34.0, 2.0)]
	var plinth: Array = [Art.rr(26.0, 170.0, 17.0, 7.0, 2.0), Art.rr(150.0, 170.0, 17.0, 7.0, 2.0)]
	Art.paint(im, piers, Palette.PLUM_L, Palette.OUTLINE, OW, GRAD, [], 0.5, Palette.STEEL)
	Art.paint(im, plinth, Palette.PLUM_L.lightened(0.10), Palette.OUTLINE, OW, 0.16, [], 0.5, Palette.STEEL)
	Art.shade(im, [Art.s(15.0, 108.0, 15.0, 168.0, 2.2), Art.s(139.0, 108.0, 139.0, 168.0, 2.2)],
			Palette.GOLD_L, 0.24, piers, 1.6)

	# Two chains hanging inside the opening, from the springing line.
	for sx in [46.0, 130.0]:
		var x: float = sx
		for j in range(6):
			Art.paint(im, [Art.c(x + (2.0 if j % 2 == 0 else -2.0), 100.0 + float(j) * 8.0, 3.2)],
					Palette.STEEL, Palette.OUTLINE, 1.6, 0.0, [], 0.7, RIM_COLD)

	# Eleven voussoirs: real radial trapezoids between r 50 and r 76, alternating one
	# value so the arch reads as cut stone rather than a bent tube.
	for i in range(11):
		var a0: float = PI + PI * float(i) / 11.0 + 0.014
		var a1: float = PI + PI * float(i + 1) / 11.0 - 0.014
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var vs: Array = _poly([ctr + d0 * 50.0, ctr + d0 * 76.0, ctr + d1 * 76.0, ctr + d1 * 50.0])
		var tone: Color = Palette.PLUM_L if i % 2 == 0 else Palette.PLUM_L.darkened(0.13)
		Art.paint(im, vs, tone, Palette.OUTLINE, OW_IN, 0.14, [], 0.5, Palette.STEEL)
		# Upper-left bevel on each stone: the one structural value that survives the
		# dungeon's ambient multiply.
		var p0: Vector2 = ctr + d0 * 51.5
		var p1: Vector2 = ctr + d0 * 74.5
		Art.shade(im, [Art.s(p0.x, p0.y, p1.x, p1.y, 2.4)], Palette.GOLD_L, 0.34, vs, 1.4)
		var mid: Vector2 = ctr + (d0 + d1).normalized() * 64.0
		Art.shade(im, [Art.e(mid.x + 4.0, mid.y + 4.0, 11.0, 11.0)], Palette.INK, 0.28, vs, 5.0)
	_ao(im, piers, cx, 172.0, 62.0, 16.0)
	return im


# ===========================================================================
# DEAD TREE 120 x 180
# ===========================================================================
static func _dead_tree() -> Image:
	var im := Art.img(120, 180)
	_ground(im, 58.0, 178.0, 96.0)

	# The crown is painted first and the trunk over it, so every fork's joint is
	# hidden behind the thing it grows out of — and each paint scans a smaller box.
	var crown: Array = _taper(34.0, 92.0, 14.0, 58.0, 5.0, 2.0, 2)
	crown.append_array(_taper(88.0, 88.0, 106.0, 54.0, 5.0, 2.0, 2))
	crown.append_array(_taper(38.0, 46.0, 30.0, 16.0, 3.6, 1.6, 2))
	crown.append_array(_taper(80.0, 48.0, 94.0, 20.0, 3.6, 1.6, 2))
	crown.append_array(_taper(57.0, 74.0, 38.0, 46.0, 6.0, 3.6, 2))
	crown.append_array(_taper(57.0, 70.0, 80.0, 48.0, 6.0, 3.6, 2))
	# Two snapped-off stubs, so the crown is not a tidy fan.
	crown.append_array(_taper(34.0, 92.0, 26.0, 74.0, 3.4, 1.5, 1))
	crown.append_array(_taper(88.0, 88.0, 100.0, 76.0, 3.4, 1.5, 1))
	Art.paint(im, crown, Palette.WOOD2_D, Palette.OUTLINE, OW, 0.22, [], RIM, Palette.RIM)

	# Trunk and the two low forks, doglegged so nothing is a straight stick. The root
	# flare is part of the same union, so the tree grows out of the ground.
	var trunk: Array = _taper(60.0, 178.0, 55.0, 124.0, 14.0, 9.5, 2)
	trunk.append_array(_taper(55.0, 124.0, 62.0, 90.0, 9.5, 7.5, 2))
	trunk.append_array(_taper(62.0, 90.0, 55.0, 62.0, 7.5, 6.0, 2))
	trunk.append_array(_taper(58.0, 116.0, 34.0, 92.0, 7.5, 5.0, 2))
	trunk.append_array(_taper(60.0, 106.0, 88.0, 88.0, 7.5, 5.0, 2))
	trunk.append_array(_taper(58.0, 160.0, 26.0, 176.0, 9.0, 4.0, 2))
	trunk.append_array(_taper(60.0, 158.0, 92.0, 174.0, 9.0, 4.0, 2))
	Art.paint(im, trunk, Palette.WOOD2_D, Palette.OUTLINE, OW, 0.24, [], RIM, Palette.RIM)

	# Bark grooves, a lit rake down the trunk's left, a deep shade down its right.
	for i in range(5):
		var gx: float = 52.0 + Art.hash01(i * 41 + 7) * 11.0
		var gy: float = 96.0 + float(i) * 16.0
		Art.shade(im, [Art.s(gx, gy, gx + 2.0, gy + 19.0, 1.3)], Palette.WOOD_D, 0.7, trunk, 1.5)
	Art.shade(im, [Art.s(49.0, 70.0, 50.0, 172.0, 2.6)], Palette.GOLD_L, 0.32, trunk, 2.0)
	Art.shade(im, [Art.s(68.0, 92.0, 70.0, 176.0, 5.0)], Palette.INK, 0.34, trunk, 3.0)
	# A knot hole where a limb tore out.
	Art.paint(im, [Art.e(58.0, 132.0, 5.5, 7.0)], Palette.INK, Palette.WOOD_D, 1.6, 0.0, trunk)
	# Moss creeping up the base — the only green on a dead thing.
	Art.shade(im, [Art.e(44.0, 170.0, 15.0, 10.0), Art.e(76.0, 174.0, 12.0, 6.0)],
			Palette.MOSS, 0.55, trunk, 4.0)
	_ao(im, trunk, 60.0, 178.0, 32.0, 20.0)
	return im


# ===========================================================================
# STUMP 80 x 60 — a sawn-off trunk, deliberately lumpier than the barrel
# ===========================================================================
static func _stump() -> Image:
	var im := Art.img(80, 60)
	_ground(im, 40.0, 58.0, 70.0)
	# Irregular sawn trunk. The lumps are buttress roots, and they are what keep the
	# silhouette from reading as a tin can next to the barrel.
	var top: Array = [Art.e(39.0, 24.0, 28.0, 11.0), Art.e(28.0, 22.0, 15.0, 7.5)]
	var body: Array = [Art.rr(40.0, 39.0, 28.0, 15.0, 5.0), Art.e(13.0, 49.0, 12.0, 9.0),
			Art.e(69.0, 50.0, 10.0, 8.0), Art.e(40.0, 51.0, 25.0, 7.0)]
	body.append_array(top)
	Art.paint(im, body, Palette.WOOD2, Palette.OUTLINE, OW, 0.36, [], RIM, Palette.RIM)
	Art.paint(im, top, Palette.WOOD2.lightened(0.18), Palette.OUTLINE, OW_IN, 0.06,
			[], 0.5, Palette.RIM)
	# Growth rings, squashed onto the sawn face, plus one radial split.
	for spec in [Vector2(21, 1.4), Vector2(13, 1.2), Vector2(6, 1.0)]:
		var sp: Vector2 = spec
		Art.paint(im, _arc(37.0, 24.0, sp.x, sp.x * 0.40, 0.0, TAU, 12, sp.y),
				Palette.WOOD2_D, Palette.WOOD2_D, 0.001, 0.0, top)
	Art.paint(im, [Art.s(37.0, 24.0, 62.0, 30.0, 1.1)], Palette.WOOD2_D, Palette.WOOD2_D,
			0.001, 0.0, top)
	Art.shade(im, [Art.e(46.0, 30.0, 22.0, 9.0)], Palette.INK, 0.24, top, 5.0)
	# Bark: vertical notches down the front face.
	for i in range(7):
		var nx: float = 12.0 + float(i) * 9.0 + Art.hash01(i * 29) * 4.0
		Art.shade(im, [Art.s(nx, 30.0, nx + 1.5, 50.0, 1.7)], Palette.WOOD2_D, 0.65, body, 1.5)
	_ao(im, body, 40.0, 56.0, 30.0, 14.0)
	return im


# ===========================================================================
# ROCKS — faceted, never smooth blobs, and deliberately unlike each other
# ===========================================================================

## Shared rock build. `left` / `top` / `front` are polygons in texture px, and the
## silhouette additionally gets a bead at every outer vertex so the corners round off
## — a rock with razor-sharp corners reads as a cut gem, not as stone. The three
## planes then take hard value breaks; that hardness is what makes it look carved.
static func _rock(w: int, h: int, feet: float, left: Array, top: Array, front: Array,
		ridge: Array, cracks: Array, seed: int) -> Image:
	var im := Art.img(w, h)
	var pl: Array = _poly(left)
	var pt: Array = _poly(top)
	var pf: Array = _poly(front)
	var sil: Array = []
	sil.append_array(pl)
	sil.append_array(pt)
	sil.append_array(pf)
	for arr in [left, top, front]:
		for v in arr:
			var p: Vector2 = v
			sil.append(Art.c(p.x, p.y, 3.4))
	_ground(im, float(w) * 0.5, feet, float(w) * 1.06)
	# Base coat is the TOP facet's value; the other two planes are laid over it.
	Art.paint(im, sil, Palette.STONE2.darkened(0.08), Palette.OUTLINE, OW, 0.12, [], 0.65, Palette.RIM)
	# Left facet one step up. Partial alpha so the rim survives underneath it.
	Art.shade(im, pl, Palette.STONE2.lightened(0.12), 0.55, sil, 1.1)
	# The front-right plane is opaque and much darker: that two-step gap is the 3D.
	var dark: Color = Palette.STONE2_D.darkened(0.14)
	Art.paint(im, pf, dark, dark, 0.001, 0.0, sil)
	for seg in ridge:
		var g: Dictionary = seg
		Art.shade(im, [g], Palette.GOLD_L, 0.30, sil, 1.2)
	for seg in cracks:
		var k: Dictionary = seg
		Art.shade(im, [k], Palette.INK, 0.45, sil, 1.4)
	# Weathering: a few pits and lit chips so the planes are not painted metal.
	for i in range(7):
		var hx := Art.hash01(seed * 131 + i * 17)
		var hy := Art.hash01(seed * 131 + i * 17 + 1)
		var r: float = 1.6 + Art.hash01(seed * 131 + i * 17 + 2) * 2.6
		var px: float = 6.0 + hx * (float(w) - 12.0)
		var py: float = 6.0 + hy * (feet - 10.0)
		Art.shade(im, [Art.e(px, py, r, r * 0.7)], Palette.INK, 0.28, sil, 1.6)
		Art.shade(im, [Art.e(px - r, py - r * 0.8, r * 0.7, r * 0.5)],
				Palette.STONE2.lightened(0.3), 0.4, sil, 1.2)
	Art.shade(im, [Art.e(float(w) * 0.5, feet + 3.0, float(w) * 0.42, 10.0)],
			Palette.INK, 0.38, sil, 6.0)
	return im


static func _rock_s() -> Image:
	# Low angular wedge: one long lit flank, a small cap, a deep shaded nose.
	return _rock(64, 44, 42.0,
		[Vector2(5, 29), Vector2(17, 11), Vector2(28, 25), Vector2(12, 41)],
		[Vector2(17, 11), Vector2(33, 7), Vector2(45, 19), Vector2(28, 25)],
		[Vector2(28, 25), Vector2(45, 19), Vector2(58, 30), Vector2(53, 41), Vector2(12, 41)],
		[Art.s(18.0, 12.0, 32.0, 8.5, 1.5), Art.s(6.5, 28.0, 17.0, 12.0, 1.5)],
		[Art.s(35, 27, 41, 39, 1.1), Art.s(48, 23, 52, 31, 1.0)], 3)


static func _rock_l() -> Image:
	# Tall boulder with a shelf and a second lump budding off the right — nothing
	# about its outline echoes rock_s.
	var im := _rock(96, 64, 62.0,
		[Vector2(7, 40), Vector2(15, 17), Vector2(34, 9), Vector2(40, 34), Vector2(17, 59)],
		[Vector2(34, 9), Vector2(57, 13), Vector2(65, 28), Vector2(40, 34)],
		[Vector2(40, 34), Vector2(65, 28), Vector2(73, 44), Vector2(61, 59), Vector2(17, 59)],
		[Art.s(35.0, 10.5, 56.0, 14.5, 1.6), Art.s(16.5, 17.5, 34.0, 10.5, 1.6)],
		[Art.s(45, 37, 51, 57, 1.2), Art.s(23, 26, 30, 45, 1.1)], 9)
	# The budding lump, painted after the main mass so it overlaps it.
	var lump: Array = _poly([Vector2(66, 34), Vector2(80, 30), Vector2(91, 44),
			Vector2(85, 59), Vector2(66, 59)])
	for v in [Vector2(66, 34), Vector2(80, 30), Vector2(91, 44), Vector2(85, 59)]:
		var p: Vector2 = v
		lump.append(Art.c(p.x, p.y, 3.0))
	Art.paint(im, lump, Palette.STONE2.darkened(0.08), Palette.OUTLINE, OW, 0.12, [], 0.60, Palette.RIM)
	Art.shade(im, _poly([Vector2(66, 34), Vector2(80, 30), Vector2(84, 44), Vector2(70, 48)]),
			Palette.STONE2.lightened(0.12), 0.55, lump, 1.1)
	var dark2: Color = Palette.STONE2_D.darkened(0.14)
	Art.paint(im, _poly([Vector2(84, 44), Vector2(91, 44), Vector2(85, 59), Vector2(70, 59)]),
			dark2, dark2, 0.001, 0.0, lump)
	_ao(im, lump, 79.0, 59.0, 13.0, 8.0)
	return im


# ===========================================================================
# FENCE 96 x 72
# ===========================================================================
static func _fence() -> Image:
	var im := Art.img(96, 72)
	_ground(im, 48.0, 70.0, 82.0)
	# Left post upright, right post leaning 6 degrees — nothing out here is level.
	var posts: Array = [Art.rr(18.0, 44.0, 5.0, 26.0, 3.0), Art.s(80.0, 70.0, 74.0, 18.0, 5.0)]
	var rails: Array = [Art.s(16.0, 34.0, 78.0, 31.0, 4.0), Art.s(16.0, 56.0, 79.0, 53.0, 4.0)]
	Art.paint(im, posts, Palette.WOOD2_D, Palette.OUTLINE, OW, GRAD, [], RIM, Palette.RIM)
	Art.paint(im, rails, Palette.WOOD2, Palette.OUTLINE, OW, 0.24, [], RIM, Palette.RIM)
	for r in rails:
		var q: Dictionary = r
		var pa: Vector2 = q["a"]
		var pb: Vector2 = q["b"]
		Art.shade(im, [Art.s(pa.x, pa.y - 2.5, pb.x, pb.y - 2.5, 1.2)], Palette.GOLD_L, 0.25, rails, 1.5)
		Art.shade(im, [Art.s(pa.x, pa.y + 2.0, pb.x, pb.y + 2.0, 1.6)], Palette.INK, 0.28, rails, 1.5)
	# Moss tuft at each base, lying on the plane with blades standing out of it.
	for bx in [18.0, 78.0]:
		var x: float = bx
		Art.paint(im, [Art.e(x, 68.0, 11.0, 5.0)], Palette.MOSS, Palette.OUTLINE, OW_S_IN, 0.0)
		Art.flat(im, [Art.s(x - 4, 68, x - 6, 59, 1.4), Art.s(x + 3, 68, x + 6, 60, 1.4)],
				Palette.MOSS_L)
	_ao(im, posts, 48.0, 70.0, 32.0, 12.0)
	return im


# ===========================================================================
# BARREL 64 x 86
# ===========================================================================
static func _barrel() -> Image:
	var im := Art.img(64, 86)
	_ground(im, 32.0, 84.0, 50.0)
	# Bulged staves: the extra ellipse at the waist is what separates a barrel from
	# a tin can at 32 px on screen.
	var body: Array = [Art.rr(32.0, 54.0, 20.0, 28.0, 10.0), Art.e(32.0, 54.0, 24.0, 21.0)]
	Art.paint(im, body, Palette.WOOD2, Palette.OUTLINE, OW, GRAD, [], RIM, Palette.RIM)
	# Stave lines follow the bulge, so they bow out from the centre line.
	for i in range(5):
		var x: float = 13.0 + float(i) * 9.5
		var bow: float = (x - 32.0) * 0.16
		Art.shade(im, [Art.s(x - bow, 32.0, x + bow, 78.0, 1.3)], Palette.WOOD2_D, 0.45, body, 1.5)
	# Two iron hoops with a lit top edge and a dark underside.
	for hy in [38.0, 70.0]:
		var y: float = hy
		var hw: float = 23.5 if y < 50.0 else 21.5
		Art.paint(im, [Art.rr(32.0, y, hw, 3.6, 3.0)], Palette.STEEL, Palette.OUTLINE,
				OW_IN, 0.24, body)
		Art.shade(im, [Art.s(32.0 - hw + 2.0, y - 2.4, 32.0 + hw - 2.0, y - 2.4, 1.1)],
				Palette.GOLD_L, 0.45, body, 1.2)
	Art.paint(im, [Art.e(32.0, 28.0, 20.0, 8.0)], Palette.WOOD2.lightened(0.16),
			Palette.OUTLINE, OW_IN, 0.06, [], 0.5, Palette.RIM)
	Art.flat(im, [Art.e(32.0, 28.0, 7.5, 3.0)], Palette.WOOD2_D)
	_ao(im, body, 32.0, 82.0, 22.0, 14.0)
	return im


# ===========================================================================
# BANNER 72 x 140
# ===========================================================================
static func _banner() -> Image:
	var im := Art.img(72, 140)
	Art.shade(im, [Art.e(36.0, 133.0, 20.0, 6.0)], Palette.INK, 0.40, [], 5.0)
	# The V is BUILT, not cut: two tapering panels meeting at a point.
	var cloth: Array = _poly([Vector2(8, 16), Vector2(36, 16), Vector2(36, 132), Vector2(8, 104)])
	cloth.append_array(_poly([Vector2(36, 16), Vector2(64, 16), Vector2(64, 104), Vector2(36, 132)]))
	Art.paint(im, cloth, Palette.WINE, Palette.OUTLINE, OW, 0.22, [], RIM, Palette.RIM)
	# One lit fold down the left third and one dark fold to the right, so the cloth
	# hangs instead of lying flat.
	Art.shade(im, _poly([Vector2(10, 18), Vector2(22, 18), Vector2(24, 110), Vector2(11, 100)]),
			Palette.WINE.lightened(0.20), 0.75, cloth, 3.0)
	Art.shade(im, _poly([Vector2(45, 18), Vector2(56, 18), Vector2(55, 102), Vector2(45, 116)]),
			Palette.INK, 0.32, cloth, 3.0)
	# Ember sigil: a flame on a gold disc.
	Art.paint(im, [Art.c(36.0, 66.0, 15.0)], Palette.GOLD, Palette.OUTLINE, OW_S, 0.0,
			[], 0.5, Palette.GOLD_L)
	Art.flat(im, _teardrop(36.0, 74.0, 54.0, 7.0), Palette.EMBER)
	Art.flat(im, _teardrop(36.0, 74.0, 62.0, 3.8), Palette.TORCH_L)
	# Rod last, so it sits over the cloth it carries.
	Art.paint(im, [Art.s(6.0, 14.0, 66.0, 14.0, 3.0)], Palette.STEEL, Palette.OUTLINE,
			OW_IN, 0.20, [], 0.7, RIM_COLD)
	Art.paint(im, [Art.c(6.0, 14.0, 4.5), Art.c(66.0, 14.0, 4.5)], Palette.STEEL.darkened(0.25),
			Palette.OUTLINE, 2.0, 0.0, [], 0.6, RIM_COLD)
	return im


# ===========================================================================
# FLOOR DECALS — centred, lying flat on the tilted plane
# ===========================================================================
static func _bones() -> Image:
	var im := Art.img(80, 40)
	# A spine running back-right, three ribs curving off it, a skull, one femur.
	var spine: Array = _arc(38.0, 24.0, 16.0, 4.0, PI * 1.1, PI * 1.95, 4, 2.2)
	var ribs: Array = []
	for i in range(3):
		ribs.append_array(_arc(34.0 + float(i) * 10.0, 22.0, 8.0 + float(i), 7.0,
				-PI * 0.92, -PI * 0.08, 5, 2.0))
	var skull: Array = [Art.e(17.0, 23.0, 10.0, 7.5), Art.e(20.0, 29.0, 6.5, 3.5)]
	var femur: Array = [Art.s(56.0, 33.0, 74.0, 29.0, 2.6),
			Art.c(56.0, 33.0, 3.8), Art.c(74.0, 29.0, 3.8)]

	for piece in [spine, ribs, skull, femur]:
		var pc: Array = piece
		Art.shade(im, Art.shift(pc, SHADOW_DIR * 3.0), Palette.INK, 0.35, [], 3.0)
	Art.paint(im, spine, Palette.BONE.darkened(0.10), Palette.OUTLINE, 3.0, 0.14)
	Art.paint(im, ribs, Palette.BONE, Palette.OUTLINE, 3.0, 0.14)
	Art.paint(im, femur, Palette.BONE, Palette.OUTLINE, 3.0, 0.14)
	Art.paint(im, skull, Palette.BONE, Palette.OUTLINE, 3.0, 0.14)
	Art.dot(im, 13.5, 22.0, 2.7, 2.2, Palette.INK)
	Art.dot(im, 21.0, 22.5, 2.7, 2.2, Palette.INK)
	Art.flat(im, [Art.s(15.0, 27.5, 24.0, 27.0, 0.8)], Palette.INK)
	return im


static func _rubble() -> Image:
	var im := Art.img(88, 52)
	# A dirt stain first, so the debris looks like it came from somewhere.
	Art.shade(im, [Art.e(44.0, 28.0, 38.0, 13.0)], Palette.INK, 0.32, [], 9.0)
	# Three broken slabs give the pile a size; the chips fill in around them.
	var slabs: Array = [
		_poly([Vector2(12, 26), Vector2(28, 20), Vector2(36, 30), Vector2(18, 36)]),
		_poly([Vector2(38, 18), Vector2(58, 16), Vector2(60, 26), Vector2(40, 28)]),
		_poly([Vector2(50, 30), Vector2(72, 28), Vector2(74, 38), Vector2(54, 40)]),
	]
	for i in range(slabs.size()):
		var sl: Array = slabs[i]
		var col: Color = Palette.STONE2_D if i != 1 else Palette.PLUM_L
		Art.shade(im, Art.shift(sl, SHADOW_DIR * 3.2), Palette.INK, 0.40, [], 3.0)
		Art.paint(im, sl, col, Palette.OUTLINE, 3.0, 0.14, [], 0.45, RIM_COLD)
		Art.shade(im, Art.shift(sl, Vector2(3.5, 3.5)), Palette.INK, 0.30, sl, 2.0)
	for i in range(9):
		var h := Art.hash01(i * 83 + 13)
		var x: float = 8.0 + h * 72.0
		var y: float = 16.0 + Art.hash01(i * 83 + 14) * 24.0
		var rx: float = 3.0 + Art.hash01(i * 83 + 15) * 4.0
		var chip: Array = [Art.e(x, y, rx, rx * 0.4)]
		var col2: Color = Palette.STONE2_D if i % 3 != 0 else Palette.PLUM_L
		Art.shade(im, Art.shift(chip, SHADOW_DIR * 2.4), Palette.INK, 0.38, [], 2.5)
		Art.paint(im, chip, col2, Palette.OUTLINE, 2.2, 0.0)
		Art.flat(im, [Art.e(x - rx * 0.3, y - rx * 0.16, rx * 0.42, rx * 0.16)], col2.lightened(0.30))
	return im


# ===========================================================================
# MATERIAL PICKUPS 56 x 56 — centred, no ground shade: they hover and bob
# ===========================================================================
static func _mat_wood() -> Image:
	var im := Art.img(56, 56)
	Art.glow(im, 28.0, 28.0, 24.0, Palette.WOOD2, 0.16)
	# Three logs seen end-on, two under one, so the bundle reads as a stack.
	var logs: Array = [Art.c(18.0, 36.0, 9.5), Art.c(37.0, 36.0, 9.5), Art.c(27.0, 20.0, 9.5)]
	Art.paint(im, logs, Palette.WOOD2, Palette.OUTLINE, OW_S, GRAD_S, [], RIM_S, Palette.GOLD_L)
	for l in logs:
		var q: Dictionary = l
		var c: Vector2 = q["c"]
		Art.paint(im, [Art.c(c.x, c.y, 5.6)], Palette.WOOD2.lightened(0.14),
				Palette.WOOD2_D, 1.6, 0.0)
		Art.paint(im, _arc(c.x, c.y, 3.0, 3.0, 0.0, TAU, 8, 0.7), Palette.WOOD2_D,
				Palette.WOOD2_D, 0.001, 0.0)
	# Rope tie with a knot, warm enough to read against the log ends.
	Art.paint(im, [Art.rr(27.0, 30.0, 23.0, 3.4, 1.6)], Palette.SOIL, Palette.OUTLINE,
			OW_S_IN, 0.0, logs)
	Art.paint(im, [Art.c(27.0, 30.0, 5.0)], Palette.SOIL.lightened(0.18), Palette.OUTLINE,
			OW_S_IN, 0.0, [], 0.5, Palette.GOLD_L)
	return im


static func _mat_stone() -> Image:
	var im := Art.img(56, 56)
	Art.glow(im, 28.0, 28.0, 24.0, Palette.STONE2, 0.16)
	var chunks: Array = [
		_poly([Vector2(8, 30), Vector2(16, 18), Vector2(28, 24), Vector2(20, 40)]),
		_poly([Vector2(24, 15), Vector2(38, 11), Vector2(45, 25), Vector2(28, 28)]),
		_poly([Vector2(26, 31), Vector2(43, 28), Vector2(47, 42), Vector2(28, 45)]),
	]
	for i in range(chunks.size()):
		var f: Array = chunks[i]
		Art.paint(im, f, Palette.STONE2, Palette.OUTLINE, OW_S, GRAD_S, [], RIM_S, Palette.GOLD_L)
		# One hard shaded facet per chunk, so none of them reads as a smooth pebble.
		Art.paint(im, Art.shift(f, Vector2(6, 6)), Palette.STONE2_D.darkened(0.12),
				Palette.STONE2_D.darkened(0.12), 0.001, 0.0, f)
	return im


static func _mat_iron() -> Image:
	var im := Art.img(56, 56)
	Art.glow(im, 28.0, 28.0, 24.0, Palette.STEEL, 0.20)
	# Trapezoid ingot: the sloped sides are what say "cast", not "brick".
	var ingot: Array = _poly([Vector2(9, 39), Vector2(16, 21), Vector2(41, 21), Vector2(48, 39)])
	Art.paint(im, ingot, Palette.STEEL.lightened(0.10), Palette.OUTLINE, OW_S, GRAD_S,
			[], RIM_S, Palette.GOLD_L)
	# Lit top face, then a hard specular streak across its upper-left.
	Art.paint(im, _poly([Vector2(16, 21), Vector2(41, 21), Vector2(44, 28), Vector2(13, 28)]),
			Palette.IRON.darkened(0.10), Palette.IRON.darkened(0.10), 0.001, 0.0, ingot)
	Art.shade(im, [Art.s(16.0, 24.5, 32.0, 24.5, 1.8)], Palette.GOLD_L, 0.9, ingot, 1.1)
	Art.paint(im, _poly([Vector2(30, 31), Vector2(48, 39), Vector2(9, 39), Vector2(9, 36)]),
			Palette.STEEL.darkened(0.30), Palette.STEEL.darkened(0.30), 0.001, 0.0, ingot)
	return im


static func _mat_food() -> Image:
	var im := Art.img(56, 56)
	Art.glow(im, 28.0, 28.0, 24.0, Palette.AMBER, 0.16)
	# A baked crust, not raw dough: the loaf sits two steps below its lit top.
	var loaf: Array = [Art.e(26.0, 35.0, 18.0, 13.0)]
	Art.paint(im, loaf, Palette.AMBER.darkened(0.34), Palette.OUTLINE, OW_S, GRAD_S,
			[], RIM_S, Palette.GOLD_L)
	Art.shade(im, [Art.e(24.0, 29.0, 15.0, 7.0)], Palette.AMBER, 0.85, loaf, 3.0)
	for i in range(3):
		var x: float = 17.0 + float(i) * 9.0
		Art.shade(im, [Art.s(x, 30.0, x + 5.0, 39.0, 1.7)], Palette.WOOD2_D, 0.55, loaf, 1.4)
	Art.paint(im, [Art.c(42.0, 19.0, 7.0)], Palette.RED, Palette.OUTLINE, OW_S_IN, 0.0,
			[], 0.6, Palette.GOLD_L)
	Art.dot(im, 40.0, 17.0, 2.2, 2.2, Palette.CREAM)
	Art.paint(im, [Art.e(23.0, 16.0, 8.0, 4.5), Art.e(14.0, 20.0, 6.0, 3.5)],
			Palette.LEAF, Palette.OUTLINE, OW_S_IN, 0.10, [], 0.5, Palette.GOLD_L)
	return im



# ===========================================================================
# LIVING NATURE — greenery + water for the open-air sanctuary base
# ===========================================================================

## A lush round-canopy tree: a warm trunk under a stack of green leaf blobs, each
## clump lit upper-left and shaded lower-right so the mass reads as foliage.
static func _tree() -> Image:
	var im := Art.img(140, 172)
	_ground(im, 70.0, 168.0, 96.0)
	var trunk: Array = [Art.rr(70.0, 132.0, 9.0, 30.0, 5.0), Art.e(70.0, 160.0, 22.0, 8.0)]
	Art.paint(im, trunk, Palette.WOOD2, Palette.OUTLINE, OW, GRAD, [], RIM, Palette.RIM)
	Art.shade(im, [Art.s(65.0, 112.0, 63.0, 152.0, 2.2)], Palette.WOOD2_D, 0.5, trunk, 1.6)
	Art.shade(im, [Art.s(75.0, 116.0, 76.0, 150.0, 1.4)], Palette.WOOD2.lightened(0.2), 0.4, trunk, 1.4)
	var canopy: Array = [
		Art.c(70.0, 66.0, 45.0), Art.c(40.0, 84.0, 29.0), Art.c(100.0, 84.0, 29.0),
		Art.c(52.0, 44.0, 27.0), Art.c(90.0, 46.0, 26.0), Art.c(70.0, 98.0, 30.0),
	]
	Art.paint(im, canopy, Palette.MOSS, Palette.OUTLINE, OW, 0.22, [], RIM, Palette.RIM)
	for lb in canopy:
		var b: Dictionary = lb
		var cc: Vector2 = b["c"]
		var r: float = b["r"]
		Art.shade(im, [Art.c(cc.x - r * 0.34, cc.y - r * 0.40, r * 0.55)], Palette.MOSS_L, 0.55, canopy, 3.5)
		Art.shade(im, [Art.c(cc.x + r * 0.40, cc.y + r * 0.44, r * 0.52)], Palette.MOSS.darkened(0.32), 0.45, canopy, 3.5)
	# A scatter of bright leaf glints in the key-lit crown.
	for i in range(9):
		var gx: float = 34.0 + Art.hash01(i * 23 + 3) * 72.0
		var gy: float = 32.0 + Art.hash01(i * 23 + 7) * 60.0
		Art.shade(im, [Art.e(gx, gy, 3.0, 2.2)], Palette.LEAF.lightened(0.18), 0.5, canopy, 2.0)
	_ao(im, canopy, 70.0, 112.0, 42.0, 12.0)
	return im

## A low leafy shrub — three green lobes with the same lit/shaded clump treatment.
static func _bush() -> Image:
	var im := Art.img(84, 60)
	_ground(im, 42.0, 56.0, 66.0)
	var lobes: Array = [Art.c(30.0, 34.0, 17.0), Art.c(54.0, 34.0, 17.0), Art.c(42.0, 24.0, 16.0)]
	Art.paint(im, lobes, Palette.MOSS, Palette.OUTLINE, OW_IN + 1.0, 0.2, [], RIM, Palette.RIM)
	for lb in lobes:
		var b: Dictionary = lb
		var cc: Vector2 = b["c"]
		var r: float = b["r"]
		Art.shade(im, [Art.c(cc.x - r * 0.34, cc.y - r * 0.4, r * 0.55)], Palette.MOSS_L, 0.55, lobes, 3.0)
		Art.shade(im, [Art.c(cc.x + r * 0.4, cc.y + r * 0.45, r * 0.5)], Palette.MOSS.darkened(0.3), 0.45, lobes, 3.0)
	# A couple of berries for life.
	Art.dot(im, 36.0, 30.0, 2.2, 2.2, Palette.RED)
	Art.dot(im, 50.0, 36.0, 2.0, 2.0, Palette.RED)
	return im

## A small wildflower cluster on a grass tuft — dots of colour that read as blooms.
static func _flowers() -> Image:
	var im := Art.img(64, 44)
	_ground(im, 32.0, 42.0, 46.0)
	# Grass blades.
	for i in range(7):
		var bx: float = 14.0 + float(i) * 5.5 + Art.hash01(i * 13) * 2.0
		Art.paint(im, [Art.s(bx, 40.0, bx - 2.0, 26.0 - Art.hash01(i * 7) * 6.0, 1.6)],
				Palette.MOSS, Palette.MOSS.darkened(0.2), 0.001, 0.0)
	# Blooms: a few stems tipped with coloured petals + a gold centre.
	var cols: Array = [Palette.GOLD, Palette.RED, Palette.WHITE, Palette.EMBER]
	for i in range(4):
		var fx: float = 16.0 + float(i) * 10.0
		var fy: float = 18.0 + Art.hash01(i * 17 + 2) * 6.0
		Art.paint(im, [Art.s(fx, 40.0, fx, fy + 4.0, 1.4)], Palette.MOSS.darkened(0.1),
				Palette.MOSS.darkened(0.1), 0.001, 0.0)
		var col: Color = cols[i % cols.size()]
		Art.dot(im, fx, fy, 4.2, 4.2, col, 1.4, Palette.OUTLINE)
		Art.dot(im, fx, fy, 1.6, 1.6, Palette.GOLD_L)
	return im

## Riverbank reeds — tall thin blades that break the water's edge.
static func _reeds() -> Image:
	var im := Art.img(56, 74)
	_ground(im, 28.0, 70.0, 40.0)
	for i in range(9):
		var rx: float = 10.0 + float(i) * 4.2 + Art.hash01(i * 19) * 2.0
		var h: float = 30.0 + Art.hash01(i * 11 + 5) * 30.0
		var lean: float = (Art.hash01(i * 7) - 0.5) * 8.0
		var col: Color = Palette.MOSS_L if i % 2 == 0 else Palette.MOSS
		Art.paint(im, [Art.s(rx, 68.0, rx + lean, 68.0 - h, 1.8)], col,
				Palette.OUTLINE, 1.4, 0.0, [], 0.5, Palette.GOLD_L)
		# A cattail tip on the taller ones.
		if h > 46.0:
			Art.dot(im, rx + lean, 68.0 - h, 2.4, 5.0, Palette.WOOD2_D, 1.0, Palette.OUTLINE)
	return im

## A plank footbridge for crossing the stream — laid flat, so it is authored short
## in Y (it lies on the ground plane) with two rails.
static func _bridge() -> Image:
	var im := Art.img(128, 72)
	_ground(im, 64.0, 68.0, 120.0)
	var deck: Array = [Art.rr(64.0, 40.0, 58.0, 16.0, 4.0)]
	Art.paint(im, deck, Palette.WOOD2, Palette.OUTLINE, OW, 0.14, [], RIM, Palette.RIM)
	# Planks across the deck.
	for i in range(11):
		var px: float = 12.0 + float(i) * 10.0
		Art.shade(im, [Art.s(px, 26.0, px, 54.0, 1.4)], Palette.WOOD2_D, 0.6, deck, 1.3)
	# Two rails, lit on top.
	Art.paint(im, [Art.rr(64.0, 26.0, 58.0, 2.6, 2.0)], Palette.WOOD2.lightened(0.14),
			Palette.OUTLINE, 2.0, 0.0, [], 0.5, Palette.GOLD_L)
	Art.paint(im, [Art.rr(64.0, 54.0, 58.0, 2.6, 2.0)], Palette.WOOD2_D,
			Palette.OUTLINE, 2.0, 0.0)
	return im
