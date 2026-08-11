class_name ArtCast
extends RefCounted
## The cast — the ginger cat hero, the three survivors and the two dungeon husks — as upright billboards standing in a lit 3/4 world.
##
## WHAT THIS FILE IS FOR. One chibi armature is drawn six times so the roster feels
## like a family: an oversized head, a soft rounded body, stubby limbs, no neck.
## What makes them read as bodies in a room rather than stickers on it is never the
## outline — it is that every mass (head, body, each limb, each accessory) gets its
## OWN `Art.paint()` call, so the vertical falloff runs across that form instead of
## across the whole figure, plus three things layered in a fixed order:
##
##   1. a contact smear pressed into the floor BEFORE anything else is drawn,
##   2. an upper-left rim light on each mass (`Art.LIGHT_DIR`), and
##   3. an INK crescent where each mass sits on the one below it (chin on chest,
##      arm on flank, hips on the floor) — the self-occlusion that gives a stack
##      of soft blobs a front and a back.
##
## Draw order inside every bake is: contact shade, far limbs, legs, body, tail,
## near limb, head, ears, face, accessory, then the occlusion pass last so it can
## darken across mass boundaries.
##
## Registered with the Assets autoload through `a.put(key, image)`. Runs after the
## legacy catalogue, so each key here replaces the old flat top-down sprite.

# Actor drawing constants, from the art brief. Silhouettes carry a heavy sticker
# outline; interior detail (bellies, aprons, stripes) gets half of it so it reads
# as marking on a surface rather than a separate cut-out object.
const OW := 6.0
const OW_IN := 3.0
const GRAD := 0.22          # per-mass falloff, LIT top to SHADE bottom
const RIM_A := 0.85         # rim strength for the warm-blooded cast

static func bake(a: Node) -> void:
	a.put("player", _player())
	a.put("player_back", _player_back())
	a.put("survivor_farmer", _farmer())
	a.put("survivor_smith", _smith())
	a.put("survivor_builder", _builder())
	a.put("enemy_husk", _husk())
	a.put("enemy_brute", _brute())

# ---------------------------------------------------------------------------
# Shared lighting helpers
# ---------------------------------------------------------------------------

## The smear a figure presses into the floor. Mandatory, drawn FIRST, before any
## paint, so the body sits down into it instead of hovering over it. `w` is the
## widest drawn mass, not the canvas.
static func _ground(im: Image, cx: float, feet_y: float, w: float,
		alpha: float = 0.55) -> void:
	Art.shade(im, [Art.e(cx, feet_y - 3.0, w * 0.52, w * 0.15)], Palette.INK, alpha, [], 5.0)

## Self-occlusion crescent: an ellipse sunk into the bottom of `mass` and clipped
## to it, so only the sliver that overlaps survives. This is what stops a round
## cute animal from going flat under the ambient multiply.
static func _ao(im: Image, mass: Array, cx: float, cy: float, rx: float,
		alpha: float = 0.28) -> void:
	Art.shade(im, [Art.e(cx, cy, rx, rx * 0.55)], Palette.INK, alpha, mass, 4.0)

## The LIT plane: a soft wash of `col` over the upper-left shoulder of a mass.
## Two steps above the SHADE side is what reads as 3D at 48 px.
static func _lit(im: Image, mass: Array, cx: float, cy: float, rx: float, ry: float,
		col: Color, alpha: float) -> void:
	Art.shade(im, [Art.e(cx, cy, rx, ry)], col, alpha, mass, 6.0)

## A short soft stroke clipped inside a mass — fur, wool, plating, cloth folds.
static func _stroke(im: Image, mass: Array, ax: float, ay: float, bx: float, by: float,
		r: float, col: Color, alpha: float) -> void:
	Art.shade(im, [Art.s(ax, ay, bx, by, r)], col, alpha, mass, r + 0.8)

## An arm: a tapering upper limb ending in a paw, painted as its own mass so it
## keeps its own falloff and rim. Returns the prims so the caller can sink an
## occlusion crescent where the limb crosses the torso — without that the limb
## and the flank are the same colour and the arm disappears.
static func _arm(im: Image, ax: float, ay: float, bx: float, by: float, r: float,
		paw: float, fill: Color, rim: float) -> Array:
	var prims: Array = [Art.s(ax, ay, bx, by, r), Art.c(bx, by + paw * 0.30, paw)]
	Art.paint(im, prims, fill, Palette.OUTLINE, OW, GRAD, [], rim)
	Art.shade(im, [Art.c(ax + 1.0, ay - 1.0, r * 1.5)], Palette.INK, 0.35, prims, 5.0)
	return prims

## Sweep a tapering disc along a polyline of [x, y] points. Nothing can be
## subtracted in this engine, so every curved, pointed form — tails, claws,
## horns, armour bands — is a necklace of circles, and a coarse necklace reads
## as a string of beads. Spacing is therefore proportional to the LOCAL radius
## (`density` x r): close enough that the union never scallops, but without
## paying for dozens of redundant circles at the fat end, since Art.paint costs
## pixels x prims and a fat tail is the most expensive thing in this file.
static func _sweep(pts: Array, r0: float, r1: float, density: float = 1.0) -> Array:
	var pv: Array = []
	for p: Array in pts:
		pv.append(Vector2(p[0], p[1]))
	var total := 0.0
	for i in range(pv.size() - 1):
		total += pv[i].distance_to(pv[i + 1])
	if total <= 0.001:
		return [Art.c(pv[0].x, pv[0].y, r0)]
	var out: Array = []
	var walked := 0.0        # path length already behind us
	var next_at := 0.0       # path length at which the next circle sits
	for i in range(pv.size() - 1):
		var a: Vector2 = pv[i]
		var b: Vector2 = pv[i + 1]
		var l: float = a.distance_to(b)
		while next_at <= walked + l and l > 0.0001:
			var t: float = (next_at - walked) / l
			var r: float = lerpf(r0, r1, next_at / total)
			out.append(Art.c(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t), r))
			next_at += maxf(1.0, r * density)
		walked += l
	var tip: Vector2 = pv[pv.size() - 1]
	out.append(Art.c(tip.x, tip.y, r1))
	return out

## Three curved talons splayed off a wrist — the husks have hands, not paws.
static func _claws(im: Image, cx: float, cy: float, spread: float, len_y: float,
		fill: Color, rim: float = 0.0, rim_col: Color = Palette.STEEL) -> void:
	for k: float in [-1.0, -0.1, 0.85]:
		Art.paint(im, _sweep([
			[cx + k * spread * 0.25, cy],
			[cx + k * spread * 0.65, cy + len_y * 0.42],
			[cx + k * spread * 0.9, cy + len_y * 0.74],
			[cx + k * spread, cy + len_y],
		], 3.4, 0.9, 1.2), fill, Palette.OUTLINE, 2.6, 0.24, [], rim, rim_col)

# ---------------------------------------------------------------------------
# Hero — a ginger tabby with a cream belly and the ember scarf
# ---------------------------------------------------------------------------
static func _player() -> Image:
	var im := Art.img(120, 140)
	_ground(im, 60, 138, 72)

	# Far side of the body first, a step darker so the near side comes forward.
	_arm(im, 82, 86, 94, 104, 9.0, 9.5, Palette.CAT.darkened(0.22), 0.28)
	var leg_far: Array = [Art.rr(76, 120, 10, 12, 8), Art.e(76, 130, 13, 10)]
	Art.paint(im, leg_far, Palette.CAT.darkened(0.14), Palette.OUTLINE, OW, GRAD, [], 0.32)
	var leg_near: Array = [Art.rr(44, 120, 10, 12, 8), Art.e(44, 130, 13, 10)]
	Art.paint(im, leg_near, Palette.CAT, Palette.OUTLINE, OW, GRAD, [], 0.55)

	# Torso — nearly as wide as the head, so the chibi still has a body.
	var body: Array = [Art.rr(60, 100, 28, 24, 20)]
	Art.paint(im, body, Palette.CAT, Palette.OUTLINE, OW, GRAD, [], RIM_A)
	_lit(im, body, 44, 86, 19, 15, Palette.AMBER, 0.26)
	Art.paint(im, [Art.e(60, 108, 17, 14)], Palette.CAT_BELLY, Palette.CAT_D, 2.0, 0.10, body)
	Art.paint(im, [Art.e(60, 84, 14, 7)], Palette.CAT_BELLY, Palette.CAT_D, 1.4, 0.0, body)
	# Tabby barring: light strokes up the lit flank, dark ones down the shaded one.
	_stroke(im, body, 38, 92, 48, 89, 2.4, Palette.CAT_BELLY, 0.30)
	_stroke(im, body, 38, 102, 47, 100, 2.2, Palette.CAT_BELLY, 0.24)
	_stroke(im, body, 82, 92, 73, 90, 2.6, Palette.CAT_D, 0.55)
	_stroke(im, body, 83, 102, 74, 101, 2.4, Palette.CAT_D, 0.50)
	_stroke(im, body, 81, 112, 73, 112, 2.2, Palette.CAT_D, 0.45)

	# Tail: swept, so it tapers to a tip instead of scalloping into beads.
	var tail := _sweep([
		[82.0, 118.0], [87.0, 116.0], [92.0, 113.0], [96.0, 109.0], [99.0, 104.0],
		[101.0, 98.0], [102.0, 92.0], [102.0, 85.0], [100.0, 78.0], [97.0, 72.0],
		[93.0, 68.0], [89.0, 66.0],
	], 9.0, 3.4)
	Art.paint(im, tail, Palette.CAT.darkened(0.10), Palette.OUTLINE, OW, 0.18, [], 0.60)
	_stroke(im, tail, 94, 111, 101, 108, 2.6, Palette.CAT_D, 0.6)
	_stroke(im, tail, 99, 97, 107, 96, 2.4, Palette.CAT_D, 0.6)
	_stroke(im, tail, 96, 80, 103, 78, 2.0, Palette.CAT_D, 0.55)

	# Near arm, the one the light hits.
	var arm := _arm(im, 38, 86, 25, 104, 9.5, 10.0, Palette.CAT, RIM_A)
	_ao(im, arm, 27, 112, 10, 0.30)

	# Head: skull, two cheek tufts widening the silhouette, two ears — one union
	# so the sticker outline runs unbroken around the whole thing.
	var head: Array = [
		Art.c(60, 56, 26),
		Art.c(38, 64, 8.5), Art.c(82, 64, 8.5),
		Art.t(36, 44, 38, 15, 58, 32),
		Art.t(84, 44, 82, 15, 62, 32),
	]
	Art.paint(im, head, Palette.CAT, Palette.OUTLINE, OW, GRAD, [], RIM_A)
	_lit(im, head, 46, 42, 18, 16, Palette.AMBER, 0.28)
	Art.paint(im, [Art.t(40, 41, 41, 21, 55, 33)], Palette.CAT_EAR, Palette.CAT_D, 1.5, 0.0, head)
	Art.paint(im, [Art.t(80, 41, 79, 21, 65, 33)], Palette.CAT_EAR, Palette.CAT_D, 1.5, 0.0, head)
	# Forehead tabby M and cheek fur.
	_stroke(im, head, 60, 31, 60, 42, 2.5, Palette.CAT_D, 0.60)
	_stroke(im, head, 50, 33, 47, 43, 2.1, Palette.CAT_D, 0.55)
	_stroke(im, head, 70, 33, 73, 43, 2.1, Palette.CAT_D, 0.55)
	_stroke(im, head, 37, 57, 31, 63, 2.4, Palette.CAT_BELLY, 0.32)
	_stroke(im, head, 83, 59, 89, 65, 2.4, Palette.CAT_D, 0.50)
	# Muzzle: two cheek puffs plus a chin, so it domes instead of being a patch.
	var muzzle: Array = [Art.e(53, 68, 10, 7), Art.e(67, 68, 10, 7), Art.e(60, 71, 8, 5)]
	Art.paint(im, muzzle, Palette.CAT_BELLY, Palette.CAT_D, 2.0, 0.08, head)
	_ao(im, muzzle, 60, 74, 13, 0.20)

	# Face. Big dark eyes with a gold iris so he still emotes at 60 px tall.
	for ex: float in [49.0, 71.0]:
		Art.dot(im, ex, 55, 7.0, 8.4, Palette.OUTLINE)
		Art.dot(im, ex, 56, 4.6, 5.8, Palette.GOLD)
		Art.dot(im, ex, 56.5, 2.0, 4.8, Palette.OUTLINE)
		Art.dot(im, ex - 2.4, 51.6, 2.2, 2.2, Palette.WHITE)
	Art.paint(im, [Art.t(55.5, 63, 64.5, 63, 60, 68)], Palette.CAT_EAR, Palette.OUTLINE, 1.6, 0.0)
	# Philtrum down from the nose, then the two upward curves of a cat's mouth.
	# Curving them DOWN from the nose instead just crosses the nose into an X.
	Art.paint(im, [Art.s(60, 67, 60, 72, 1.2), Art.s(60, 72, 53.5, 69, 1.3),
		Art.s(60, 72, 66.5, 69, 1.3)], Palette.OUTLINE, Palette.OUTLINE, 0.001, 0.0)
	# Whiskers are opaque, not translucent: a half-alpha line over a dark floor
	# just reads as a scratch.
	for w: Array in [[47.0, 70.0, 31.0, 66.0], [47.0, 74.0, 31.0, 77.0],
			[73.0, 70.0, 89.0, 66.0], [73.0, 74.0, 89.0, 77.0]]:
		Art.paint(im, [Art.s(w[0], w[1], w[2], w[3], 1.0)], Palette.CREAM, Palette.CREAM,
			0.001, 0.0)

	# The ember he carries: a warm bloom under the chin BEFORE the cloth, so the
	# halo spills onto chest and floor while the scarf itself stays crisp on top.
	Art.glow(im, 60, 90, 30, Palette.TORCH, 0.20)
	# The scarf is CLOTH: flat quads with straight edges meeting in a shallow
	# chevron. A swept tube of the same colour as the fur just reads as a sausage
	# laid across the chest, which is exactly what a rounded collar gave.
	var collar: Array = Art.quad(Vector2(36, 84), Vector2(60, 87), Vector2(60, 94),
		Vector2(36, 87))
	collar.append_array(Art.quad(Vector2(60, 87), Vector2(84, 84), Vector2(84, 87),
		Vector2(60, 94)))
	Art.paint(im, collar, Palette.EMBER, Palette.OUTLINE, 3.0, 0.06, [], 0.6, Palette.GOLD_L)
	Art.shade(im, [Art.s(41, 83.2, 60, 88.2, 1.0)], Palette.GOLD_L, 0.55, collar, 1.2)
	Art.shade(im, [Art.s(42, 87, 60, 92, 1.6), Art.s(60, 92, 78, 87, 1.6)],
		Palette.EMBER_D, 0.8, collar, 1.8)
	# The knot and its loose end, also flat cloth: a small slab plus a tapering
	# banner with one crease down it.
	Art.paint(im, [Art.rr(75, 88, 6, 6, 2)], Palette.EMBER, Palette.OUTLINE, 2.8, 0.10,
		[], 0.6, Palette.GOLD_L)
	var ribbon: Array = Art.quad(Vector2(72, 92), Vector2(79, 91), Vector2(85, 107),
		Vector2(79, 109))
	ribbon.append(Art.t(79, 109, 85, 107, 81, 117))
	Art.paint(im, ribbon, Palette.EMBER_D, Palette.OUTLINE, 2.8, 0.10, [], 0.45, Palette.GOLD_L)
	Art.shade(im, [Art.s(75, 93, 81, 108, 1.3)], Palette.EMBER, 0.8, ribbon, 1.6)

	# Occlusion pass: chin onto chest, chest onto hips, body onto its own base.
	_ao(im, body, 60, 92, 24, 0.26)
	_ao(im, body, 74, 124, 24, 0.30)
	Art.shade(im, [Art.e(88, 104, 16, 22)], Palette.INK, 0.20, body, 6.0)
	_ao(im, head, 72, 80, 20, 0.22)
	_ao(im, leg_far, 76, 138, 13, 0.34)
	_ao(im, leg_near, 44, 138, 13, 0.30)
	return im

# ---------------------------------------------------------------------------
# Hero from behind — same armature turned away: no face, ear-backs, a striped
# spine and the scarf knot trailing down the back. Shown when walking "up".
# ---------------------------------------------------------------------------
static func _player_back() -> Image:
	var im := Art.img(120, 140)
	_ground(im, 60, 138, 72)

	# Far arm + legs, same stack as the front so the flip/anchor line up.
	_arm(im, 82, 86, 94, 104, 9.0, 9.5, Palette.CAT.darkened(0.22), 0.28)
	var leg_far: Array = [Art.rr(76, 120, 10, 12, 8), Art.e(76, 130, 13, 10)]
	Art.paint(im, leg_far, Palette.CAT.darkened(0.14), Palette.OUTLINE, OW, GRAD, [], 0.32)
	var leg_near: Array = [Art.rr(44, 120, 10, 12, 8), Art.e(44, 130, 13, 10)]
	Art.paint(im, leg_near, Palette.CAT, Palette.OUTLINE, OW, GRAD, [], 0.55)

	# Torso back — all fur (no cream belly), a striped spine down the middle.
	var body: Array = [Art.rr(60, 100, 28, 24, 20)]
	Art.paint(im, body, Palette.CAT, Palette.OUTLINE, OW, GRAD, [], RIM_A)
	_lit(im, body, 44, 86, 19, 15, Palette.AMBER, 0.20)
	_stroke(im, body, 60, 82, 60, 116, 2.6, Palette.CAT_D, 0.5)
	_stroke(im, body, 48, 92, 44, 102, 2.4, Palette.CAT_D, 0.42)
	_stroke(im, body, 72, 92, 76, 102, 2.4, Palette.CAT_D, 0.42)
	_stroke(im, body, 50, 106, 46, 114, 2.2, Palette.CAT_D, 0.38)
	_stroke(im, body, 70, 106, 74, 114, 2.2, Palette.CAT_D, 0.38)

	# Tail curling up the near side, same as the front view.
	var tail := _sweep([
		[82.0, 118.0], [87.0, 116.0], [92.0, 113.0], [96.0, 109.0], [99.0, 104.0],
		[101.0, 98.0], [102.0, 92.0], [102.0, 85.0], [100.0, 78.0], [97.0, 72.0],
		[93.0, 68.0], [89.0, 66.0],
	], 9.0, 3.4)
	Art.paint(im, tail, Palette.CAT.darkened(0.10), Palette.OUTLINE, OW, 0.18, [], 0.60)
	_stroke(im, tail, 94, 111, 101, 108, 2.6, Palette.CAT_D, 0.6)
	_stroke(im, tail, 99, 97, 107, 96, 2.4, Palette.CAT_D, 0.6)
	_stroke(im, tail, 96, 80, 103, 78, 2.0, Palette.CAT_D, 0.55)

	# Near arm.
	var arm := _arm(im, 38, 86, 25, 104, 9.5, 10.0, Palette.CAT, RIM_A)
	_ao(im, arm, 27, 112, 10, 0.30)

	# Head from behind: the same domed silhouette, but the inner ears now read as
	# darker fur-backs and there is no face at all — just striped nape.
	var head: Array = [
		Art.c(60, 56, 26),
		Art.c(38, 64, 8.5), Art.c(82, 64, 8.5),
		Art.t(36, 44, 38, 15, 58, 32),
		Art.t(84, 44, 82, 15, 62, 32),
	]
	Art.paint(im, head, Palette.CAT, Palette.OUTLINE, OW, GRAD, [], RIM_A)
	_lit(im, head, 46, 42, 18, 16, Palette.AMBER, 0.24)
	Art.paint(im, [Art.t(40, 41, 41, 21, 55, 33)], Palette.CAT_D, Palette.CAT_D, 1.5, 0.0, head)
	Art.paint(im, [Art.t(80, 41, 79, 21, 65, 33)], Palette.CAT_D, Palette.CAT_D, 1.5, 0.0, head)
	_stroke(im, head, 60, 33, 60, 62, 2.6, Palette.CAT_D, 0.55)
	_stroke(im, head, 50, 40, 47, 60, 2.2, Palette.CAT_D, 0.5)
	_stroke(im, head, 70, 40, 73, 60, 2.2, Palette.CAT_D, 0.5)

	# The ember scarf seen from behind: a band across the nape with the knot and a
	# loose ribbon trailing down the spine.
	Art.glow(im, 60, 88, 24, Palette.TORCH, 0.16)
	var collar: Array = Art.quad(Vector2(36, 84), Vector2(60, 86), Vector2(60, 92),
		Vector2(36, 88))
	collar.append_array(Art.quad(Vector2(60, 86), Vector2(84, 84), Vector2(84, 88),
		Vector2(60, 92)))
	Art.paint(im, collar, Palette.EMBER, Palette.OUTLINE, 3.0, 0.06, [], 0.6, Palette.GOLD_L)
	Art.shade(im, [Art.s(40, 84, 60, 86, 1.1), Art.s(60, 86, 80, 84, 1.1)],
		Palette.GOLD_L, 0.4, collar, 1.3)
	Art.paint(im, [Art.rr(60, 90, 6, 6, 2)], Palette.EMBER, Palette.OUTLINE, 2.8, 0.10,
		[], 0.6, Palette.GOLD_L)
	var ribbon: Array = Art.quad(Vector2(56, 94), Vector2(64, 94), Vector2(63, 110),
		Vector2(57, 110))
	ribbon.append(Art.t(57, 110, 63, 110, 60, 118))
	Art.paint(im, ribbon, Palette.EMBER_D, Palette.OUTLINE, 2.8, 0.10, [], 0.45, Palette.GOLD_L)
	Art.shade(im, [Art.s(60, 95, 60, 110, 1.3)], Palette.EMBER, 0.7, ribbon, 1.5)

	# Occlusion pass.
	_ao(im, body, 60, 92, 24, 0.26)
	_ao(im, body, 74, 124, 24, 0.30)
	_ao(im, head, 72, 80, 20, 0.22)
	_ao(im, leg_far, 76, 138, 13, 0.34)
	_ao(im, leg_near, 44, 138, 13, 0.30)
	return im

# ---------------------------------------------------------------------------
# Farmer — a woolly lamb under a wide straw brim
# ---------------------------------------------------------------------------
static func _farmer() -> Image:
	var im := Art.img(120, 140)
	_ground(im, 60, 138, 74)

	# A sheaf of barley leaning against the far side, drawn behind the fleece: one
	# stalk per ear, well separated, or the heads merge into a yellow mitten.
	for i in range(3):
		var sx: float = 97.0 + float(i) * 6.0
		var tip: float = 40.0 + float(i) * 12.0
		Art.paint(im, [Art.s(92, 124, sx, tip + 8.0, 1.6)], Palette.GOLD.darkened(0.34),
			Palette.OUTLINE, 1.6, 0.14)
		var ear: Array = [Art.e(sx, tip + 5.0, 3.6, 8.0)]
		Art.paint(im, ear, Palette.GOLD, Palette.OUTLINE, 2.0, 0.22, [], 0.6, Palette.GOLD_L)
		Art.shade(im, [Art.s(sx - 4.0, tip + 2.0, sx + 4.0, tip + 4.0, 0.9),
			Art.s(sx - 4.0, tip + 8.0, sx + 4.0, tip + 10.0, 0.9)],
			Palette.GOLD.darkened(0.40), 0.7, ear, 1.1)
	for hx: float in [74.0, 46.0]:
		var hoof: Array = [Art.rr(hx, 120, 8, 13, 6), Art.e(hx, 132, 11, 8)]
		Art.paint(im, hoof, Palette.HAIR.lightened(0.18 if hx < 60.0 else 0.04),
			Palette.OUTLINE, OW, GRAD, [], 0.35)
		_ao(im, hoof, hx, 139, 11, 0.32)

	# Fleece: nine overlapping circles painted as ONE union, so the outline traces
	# a lumpy dome instead of nine separate balls.
	var lobes: Array = [
		[38.0, 96.0, 13.0], [60.0, 92.0, 14.0], [82.0, 96.0, 13.0],
		[36.0, 110.0, 11.0], [58.0, 112.0, 13.0], [80.0, 109.0, 12.0],
		[46.0, 82.0, 11.0], [74.0, 82.0, 11.0], [60.0, 78.0, 10.0],
	]
	var fleece: Array = []
	for lb: Array in lobes:
		fleece.append(Art.c(lb[0], lb[1], lb[2]))
	Art.paint(im, fleece, Palette.CREAM, Palette.OUTLINE, OW, 0.18, [], RIM_A)
	# Each lobe gets a crescent on its lower right and a chip of light upper left:
	# that pair, repeated, is what makes wool look like wool rather than a cloud.
	for lb2: Array in lobes:
		var lx: float = lb2[0]
		var ly: float = lb2[1]
		var lr: float = lb2[2]
		var lobe: Array = [Art.c(lx, ly, lr)]
		Art.shade(im, [Art.c(lx + lr * 0.44, ly + lr * 0.50, lr * 0.66)],
			Palette.BONE.darkened(0.30), 0.24, lobe, 4.0)
		Art.shade(im, [Art.c(lx - lr * 0.34, ly - lr * 0.42, lr * 0.46)], Palette.WHITE,
			0.65, lobe, 4.0)
	# Front hooves peeking out of the wool, so he shares the roster's armature.
	for mx: float in [93.0, 27.0]:
		var mitt: Array = [Art.e(mx, 114, 7.5, 9)]
		Art.paint(im, mitt, Palette.HAIR.lightened(0.18 if mx < 60.0 else 0.04),
			Palette.OUTLINE, OW_IN + 1.5, GRAD, [], 0.4)

	# Ears first so the long face overlaps them.
	for ear_x: float in [33.0, 87.0]:
		Art.paint(im, [Art.e(ear_x, 70, 14, 7)], Palette.BONE.darkened(0.12),
			Palette.OUTLINE, OW_IN + 1.0, 0.18, [], 0.5)
	var face: Array = [Art.e(60, 68, 15, 19)]
	Art.paint(im, face, Palette.BONE, Palette.OUTLINE, OW_IN + 1.0, 0.18, [], RIM_A)
	for ex: float in [52.5, 67.5]:
		Art.dot(im, ex, 66, 4.2, 4.4, Palette.OUTLINE)
		Art.dot(im, ex - 1.4, 64.4, 1.9, 1.9, Palette.WHITE)
	Art.dot(im, 56.5, 78, 1.8, 1.4, Palette.HAIR)
	Art.dot(im, 63.5, 78, 1.8, 1.4, Palette.HAIR)
	# A soft upturned mouth: the lamb is the gentle one.
	Art.shade(im, [Art.s(55, 82, 60, 84, 1.2), Art.s(60, 84, 65, 82, 1.2)],
		Palette.HAIR, 0.6, face, 1.5)

	# Straw hat: crown first, then the band, then the brim lands on top of both.
	var crown: Array = [Art.c(60, 26, 16)]
	Art.paint(im, crown, Palette.GOLD.darkened(0.14), Palette.OUTLINE, OW_IN + 1.0, 0.16,
		[], 0.6, Palette.GOLD_L)
	Art.paint(im, [Art.rr(60, 34, 16, 4, 2)], Palette.WINE, Palette.WINE.darkened(0.35),
		1.4, 0.0, crown)
	var brim: Array = [Art.e(60, 48, 31, 11)]
	Art.paint(im, brim, Palette.GOLD, Palette.OUTLINE, OW_IN + 1.5, 0.16, [], 0.7, Palette.GOLD_L)
	# Woven straw: spokes running out to the brim edge, lit on the key-light side.
	for i in range(9):
		var ang: float = PI * (0.08 + 0.84 * float(i) / 8.0)
		var lit_side: bool = cos(ang) > 0.2
		Art.shade(im, [Art.s(60 - cos(ang) * 12.0, 48 - sin(ang) * 4.0,
			60 - cos(ang) * 30.0, 48 - sin(ang) * 10.0, 1.4)],
			Palette.GOLD_L if lit_side else Palette.GOLD.darkened(0.28),
			0.30 if lit_side else 0.34, brim, 1.8)

	_ao(im, face, 60, 58, 16, 0.40)
	_ao(im, fleece, 60, 82, 18, 0.26)
	_ao(im, fleece, 74, 120, 22, 0.26)
	Art.shade(im, [Art.e(88, 100, 14, 20)], Palette.INK, 0.18, fleece, 6.0)
	return im

# ---------------------------------------------------------------------------
# Smith — a badger built as a trapezoid, widest at the shoulders
# ---------------------------------------------------------------------------
static func _smith() -> Image:
	var im := Art.img(120, 140)
	_ground(im, 60, 138, 78)

	# Hammer goes down first: the shoulder covers where he grips it, so it reads
	# as carried over the back rather than pasted beside him.
	Art.paint(im, [Art.s(105, 132, 97, 54, 5)], Palette.WOOD2, Palette.OUTLINE,
		OW_IN + 1.0, 0.20, [], 0.5)
	var mallet: Array = [Art.rr(99, 46, 14, 10, 3)]
	Art.paint(im, mallet, Palette.STEEL, Palette.OUTLINE, OW_IN + 1.5, 0.22, [], 0.7, Palette.GOLD_L)
	Art.shade(im, [Art.s(88, 42, 108, 42, 2.0)], Palette.GOLD_L, 0.55, mallet, 2.2)

	_arm(im, 82, 90, 93, 108, 9.5, 10.0, Palette.HUSK_D.darkened(0.18), 0.28)
	for lx: float in [74.0, 46.0]:
		var leg: Array = [Art.rr(lx, 120, 10, 13, 7), Art.e(lx, 132, 12, 8)]
		Art.paint(im, leg, Palette.HAIR.lightened(0.18 if lx < 60.0 else 0.04),
			Palette.OUTLINE, OW, GRAD, [], 0.35)
		_ao(im, leg, lx, 139, 12, 0.32)

	# Trapezoid torso: a wide shoulder slab welded onto a narrower hip block.
	var body: Array = [Art.rr(60, 90, 31, 11, 8), Art.rr(60, 110, 27, 20, 12)]
	Art.paint(im, body, Palette.HUSK_D, Palette.OUTLINE, OW, GRAD, [], RIM_A)
	# Badger saddle: the pale grey back, the one broad light value on him.
	Art.paint(im, [Art.rr(60, 92, 29, 6, 5)], Palette.STONE2, Palette.HUSK_D.darkened(0.3),
		2.0, 0.14, body)
	_lit(im, body, 40, 88, 16, 10, Palette.WHITE, 0.30)
	# Leather apron, clipped so it wraps the barrel instead of hanging beside it.
	var apron: Array = [Art.rr(60, 114, 20, 20, 4)]
	Art.paint(im, apron, Palette.WOOD2_D, Palette.OUTLINE, OW_IN, 0.18, body)
	Art.paint(im, [Art.s(48, 100, 55, 90, 3.0), Art.s(72, 100, 65, 90, 3.0)],
		Palette.WOOD2_D, Palette.OUTLINE, 1.6, 0.1, body)
	Art.shade(im, [Art.s(45, 104, 75, 104, 1.6)], Palette.GOLD_L, 0.22, apron, 1.8)
	for rv: float in [47.0, 60.0, 73.0]:
		Art.dot(im, rv, 108, 2.0, 2.0, Palette.IRON)
	Art.dot(im, 52, 126, 2.0, 2.0, Palette.IRON)
	Art.dot(im, 68, 126, 2.0, 2.0, Palette.IRON)
	# Scorch marks: he works a furnace.
	Art.shade(im, [Art.e(52, 120, 7, 5)], Palette.INK, 0.35, apron, 3.0)
	Art.shade(im, [Art.e(70, 112, 5, 4)], Palette.INK, 0.30, apron, 3.0)

	var arm := _arm(im, 38, 90, 26, 108, 10.0, 10.5, Palette.HUSK_D.lightened(0.12), RIM_A)
	_ao(im, arm, 29, 116, 10, 0.30)

	# Badger head: pale face, two narrow black bands running nose-to-ear through
	# the eyes, black ears. Ears first so the face overlaps their lower half.
	for ear_x: float in [42.0, 78.0]:
		Art.paint(im, [Art.c(ear_x, 42, 9)], Palette.HAIR, Palette.OUTLINE, OW_IN + 1.0,
			0.18, [], 0.4)
		Art.dot(im, ear_x, 43, 4.5, 4.5, Palette.HAIR.lightened(0.26))
	var head: Array = [Art.e(60, 62, 26, 23)]
	Art.paint(im, head, Palette.BONE, Palette.OUTLINE, OW, GRAD, [], RIM_A)
	Art.paint(im, [Art.s(52, 74, 46, 42, 6.0)], Palette.HAIR, Palette.HAIR, 1.0, 0.16, head)
	Art.paint(im, [Art.s(68, 74, 74, 42, 6.0)], Palette.HAIR, Palette.HAIR, 1.0, 0.16, head)
	_lit(im, head, 45, 48, 15, 12, Palette.WHITE, 0.35)
	for ex: float in [50.0, 70.0]:
		Art.dot(im, ex, 60, 4.4, 4.8, Palette.BONE)
		Art.dot(im, ex, 60.5, 2.4, 3.0, Palette.OUTLINE)
		Art.dot(im, ex - 1.5, 58.6, 1.5, 1.5, Palette.WHITE)
	Art.paint(im, [Art.e(60, 78, 6.5, 5)], Palette.OUTLINE, Palette.OUTLINE, 0.001, 0.0, head)
	Art.shade(im, [Art.s(55, 84, 65, 84, 1.3)], Palette.OUTLINE, 0.7, head, 1.5)
	# Ember headband, tied off on the right — the crew mark he has always worn.
	# Kept dark with a lit top edge; a flat bright bar reads as plastic tape.
	var band: Array = [Art.s(38, 46, 84, 46, 2.4), Art.c(85, 47, 3.6)]
	Art.paint(im, band, Palette.EMBER_D, Palette.OUTLINE, 1.8, 0.0, [], 0.6, Palette.GOLD_L)
	Art.paint(im, _sweep([[87.0, 50.0], [92.0, 57.0], [95.0, 66.0]], 3.0, 1.1),
		Palette.EMBER_D, Palette.OUTLINE, 1.6, 0.1)
	Art.shade(im, [Art.s(39, 44.6, 82, 44.6, 1.1)], Palette.EMBER, 0.85, band, 1.4)
	Art.shade(im, [Art.s(41, 43.8, 74, 43.8, 0.8)], Palette.GOLD_L, 0.45, band, 1.1)

	_ao(im, body, 60, 84, 26, 0.30)
	_ao(im, body, 72, 128, 24, 0.30)
	Art.shade(im, [Art.e(88, 108, 14, 20)], Palette.INK, 0.22, body, 6.0)
	_ao(im, head, 72, 84, 20, 0.24)
	return im

# ---------------------------------------------------------------------------
# Builder — a frog: wide-bottomed pear, eyes above the head line
# ---------------------------------------------------------------------------
static func _builder() -> Image:
	var im := Art.img(120, 140)
	_ground(im, 60, 138, 80)

	for fx: float in [80.0, 40.0]:
		var foot: Array = [Art.e(fx, 132, 18, 8)]
		Art.paint(im, foot, Palette.MOSS.darkened(0.16 if fx > 60.0 else 0.0),
			Palette.OUTLINE, OW, 0.18, [], 0.35)
		# Webbed toes: two dark notches split each paddle.
		Art.shade(im, [Art.s(fx - 5.5, 127, fx - 7.0, 139, 1.6)], Palette.INK, 0.40, foot, 2.0)
		Art.shade(im, [Art.s(fx + 5.5, 127, fx + 7.0, 139, 1.6)], Palette.INK, 0.40, foot, 2.0)
		_ao(im, foot, fx, 138, 17, 0.30)

	_arm(im, 82, 90, 92, 108, 8.5, 9.0, Palette.MOSS.darkened(0.20), 0.28)

	var body: Array = [Art.rr(60, 100, 30, 25, 21)]
	Art.paint(im, body, Palette.MOSS, Palette.OUTLINE, OW, GRAD, [], RIM_A)
	_lit(im, body, 42, 86, 18, 14, Palette.MOSS_L, 0.50)
	Art.paint(im, [Art.e(60, 110, 18, 13)], Palette.MOSS_L, Palette.MOSS.darkened(0.30),
		2.0, 0.10, body)
	# Warty speckle, light on the lit flank and dark on the shaded one.
	for i in range(10):
		var hx: float = 36.0 + Art.hash01(i * 17 + 3) * 48.0
		var hy: float = 80.0 + Art.hash01(i * 17 + 9) * 36.0
		var is_lit: bool = hx < 58.0
		Art.shade(im, [Art.e(hx, hy, 3.4, 2.6)],
			Palette.MOSS_L if is_lit else Palette.MOSS.darkened(0.40),
			0.45 if is_lit else 0.55, body, 2.2)

	var arm := _arm(im, 38, 90, 27, 106, 8.5, 9.0, Palette.MOSS.lightened(0.08), RIM_A)
	_ao(im, arm, 29, 113, 9, 0.30)

	# Head is fused to the body; the eye domes are what break the silhouette.
	var head: Array = [Art.e(60, 70, 26, 18), Art.c(42, 55, 12), Art.c(78, 55, 12)]
	Art.paint(im, head, Palette.MOSS, Palette.OUTLINE, OW, GRAD, [], RIM_A)
	_lit(im, head, 44, 60, 16, 12, Palette.MOSS_L, 0.45)
	Art.paint(im, [Art.e(60, 86, 13, 5)], Palette.MOSS_L, Palette.MOSS.darkened(0.30),
		1.6, 0.06, head)
	for ex: float in [42.0, 78.0]:
		Art.dot(im, ex, 53, 7.6, 7.6, Palette.WHITE, 2.4)
		Art.dot(im, ex, 54, 4.6, 5.0, Palette.GOLD)
		Art.dot(im, ex, 54.5, 2.1, 3.0, Palette.OUTLINE)
		Art.dot(im, ex - 2.3, 50.4, 1.9, 1.9, Palette.WHITE)
	# A proper frog grin: four short chords, because two long ones meet in a hard
	# V that reads as a scowl rather than a curve.
	Art.paint(im, [Art.s(38, 69, 48, 76, 2.1), Art.s(48, 76, 60, 78.5, 2.1),
		Art.s(60, 78.5, 72, 76, 2.1), Art.s(72, 76, 82, 69, 2.1)],
		Palette.OUTLINE, Palette.OUTLINE, 0.001, 0.0, head)
	Art.dot(im, 55, 64, 1.6, 1.4, Palette.OUTLINE)
	Art.dot(im, 65, 64, 1.6, 1.4, Palette.OUTLINE)

	# Hard hat: a tall cap so it still reads once the brim covers its base.
	var cap: Array = [Art.e(60, 27, 15, 14)]
	Art.paint(im, cap, Palette.GOLD.darkened(0.10), Palette.OUTLINE, OW_IN, 0.16, [],
		0.6, Palette.GOLD_L)
	Art.shade(im, [Art.s(60, 15, 60, 40, 2.0)], Palette.GOLD_L, 0.35, cap, 2.2)
	var brim: Array = [Art.e(60, 40, 25, 8)]
	Art.paint(im, brim, Palette.GOLD, Palette.OUTLINE, OW_IN, 0.16, [], 0.7, Palette.GOLD_L)
	Art.shade(im, [Art.e(60, 44, 24, 4)], Palette.INK, 0.35, brim, 3.0)

	# Tool belt: three tools of different shape and material, so at 60 px they are
	# a hammer, a peg and a chisel rather than three identical grey teeth.
	Art.paint(im, [Art.rr(60, 116, 27, 5, 3)], Palette.WOOD2_D, Palette.OUTLINE, 2.0, 0.14, body)
	Art.paint(im, [Art.rr(47, 123, 8, 3.5, 1.5)], Palette.STEEL, Palette.OUTLINE, 2.2, 0.22, body)
	Art.paint(im, [Art.rr(47, 130, 2.0, 6, 1)], Palette.WOOD2, Palette.OUTLINE, 1.8, 0.22, body)
	Art.paint(im, [Art.rr(73, 126, 3.0, 10, 1.6)], Palette.IRON, Palette.OUTLINE, 2.2, 0.22, body)

	_ao(im, body, 60, 86, 24, 0.32)
	_ao(im, body, 74, 122, 22, 0.30)
	Art.shade(im, [Art.e(88, 104, 14, 20)], Palette.INK, 0.20, body, 6.0)
	_ao(im, head, 70, 86, 20, 0.26)
	return im

# ---------------------------------------------------------------------------
# Husks — the same armature, hollowed out. Threatening by absence, not gore.
# ---------------------------------------------------------------------------

## One tapering drip of the husk's hem, as a necklace: it has no feet, its edge
## melts toward the floor and never makes clean contact.
static func _drip(x: float, y0: float, y1: float, r0: float, dx: float) -> Array:
	return _sweep([[x, y0], [x + dx * 0.5, lerpf(y0, y1, 0.5)], [x + dx, y1]],
		r0, r0 * 0.55, 1.5)

static func _husk() -> Image:
	var im := Art.img(120, 140)
	# Lighter contact than the living cast: it has no feet to press down with.
	_ground(im, 62, 138, 58, 0.42)

	var hide := Palette.SHADOW_D
	# Arms too long for the torso and hanging slack — the proportions are wrong
	# on purpose; nothing about this thing was assembled right.
	Art.paint(im, [Art.s(88, 86, 98, 110, 6.5)], hide.darkened(0.18), Palette.OUTLINE,
		OW, GRAD, [], 0.4, Palette.STEEL)
	_claws(im, 98, 112, 7.0, 16.0, hide.darkened(0.18), 0.4)

	# Torso: a hunched shoulder blade, a narrow chest and a dissolving hem, all one
	# union so the drips ARE the silhouette.
	var body: Array = [Art.rr(63, 102, 26, 26, 18), Art.c(46, 88, 17)]
	body.append_array(_drip(49, 118, 137, 9.0, -5.0))
	body.append_array(_drip(64, 122, 140, 9.5, 1.0))
	body.append_array(_drip(79, 118, 134, 8.0, 5.0))
	Art.paint(im, body, hide, Palette.OUTLINE, OW, GRAD, [], 0.75, Palette.STEEL)
	_lit(im, body, 46, 84, 20, 17, Palette.STEEL, 0.55)
	# Seam cracks: the fire that left this thing tore it open on the way out.
	for cy: float in [98.0, 108.0, 118.0]:
		Art.shade(im, [Art.s(50, cy, 82, cy + 3.0, 2.0)], Palette.WINE, 0.75, body, 2.2)
		Art.shade(im, [Art.s(50, cy - 2.2, 82, cy + 0.8, 0.9)], Palette.RED, 0.55, body, 1.2)

	Art.paint(im, [Art.s(38, 88, 29, 110, 7.5)], hide, Palette.OUTLINE, OW, GRAD, [],
		0.75, Palette.STEEL)
	_claws(im, 29, 112, -7.0, 16.0, hide, 0.55)

	# Hunched: head shoved forward and down. One ear is a long crooked spike, the
	# other was torn off at the base — nothing about this shape is symmetrical.
	var head: Array = [
		Art.c(68, 62, 24),
		Art.t(50, 48, 45, 16, 68, 40),
		Art.t(86, 52, 90, 38, 78, 44),
	]
	Art.paint(im, head, hide, Palette.OUTLINE, OW, GRAD, [], 0.75, Palette.STEEL)
	_lit(im, head, 54, 52, 18, 16, Palette.STEEL, 0.55)
	# Two nicks bitten out of the stub's edge, so it reads as broken not stunted.
	Art.shade(im, [Art.c(90, 38, 3.2), Art.c(85, 44, 2.6)], Palette.INK, 0.85, head, 1.6)

	# No mouth — just the eyes, and the light they leak.
	for ex: float in [59.0, 78.0]:
		Art.glow(im, ex, 62, 16, Palette.EYE_RED, 0.45)
	for ex2: float in [59.0, 78.0]:
		Art.dot(im, ex2, 62, 5.5, 5.5, Palette.EYE_RED)
		Art.dot(im, ex2, 60.8, 2.0, 2.0, Palette.TORCH_L)

	_ao(im, body, 66, 84, 22, 0.34)
	_ao(im, body, 78, 118, 22, 0.30)
	_ao(im, head, 78, 84, 20, 0.28)
	return im

static func _brute() -> Image:
	var im := Art.img(150, 176)
	_ground(im, 75, 175, 100)

	var hide := Palette.SHADOW_D.darkened(0.15)
	var brute_ow := 7.0

	# Arms hang almost to the floor and the near one is 1.4x thicker: that pair of
	# facts is most of what says "brute" before you read any detail.
	Art.paint(im, [Art.s(124, 104, 128, 144, 11), Art.c(128, 147, 13)],
		hide.darkened(0.16), Palette.OUTLINE, brute_ow, 0.24, [], 0.35, Palette.CYAN)
	_claws(im, 128, 154, 10.0, 17.0, Palette.BONE.darkened(0.52), 0.4, Palette.CYAN)
	for lx: float in [98.0, 52.0]:
		var leg: Array = [Art.rr(lx, 150, 16, 18, 12), Art.e(lx, 165, 20, 10)]
		Art.paint(im, leg, hide.darkened(0.02 if lx < 75.0 else 0.16), Palette.OUTLINE,
			brute_ow, 0.24, [], 0.45, Palette.CYAN)
		_ao(im, leg, lx, 173, 20, 0.34)

	# Torso: a hip block with two enormous trapezius bumps for shoulders, so the
	# mass sits high and wide the way the husk's never does.
	var hips: Array = [Art.rr(75, 124, 42, 26, 20)]
	Art.paint(im, hips, hide, Palette.OUTLINE, brute_ow, 0.24, [], 0.80, Palette.CYAN)
	var shoulders: Array = [Art.c(42, 100, 24), Art.c(108, 100, 24)]
	Art.paint(im, shoulders, hide, Palette.OUTLINE, brute_ow, 0.24, [], 0.80, Palette.CYAN)
	var body: Array = hips + shoulders
	_lit(im, shoulders, 40, 90, 22, 17, Palette.SHADOW.lightened(0.20), 0.70)
	_lit(im, shoulders, 104, 90, 18, 14, Palette.SHADOW, 0.35)
	# Seams left exposed by the broken corner of the chest plate.
	for cy: float in [128.0, 138.0, 148.0]:
		Art.shade(im, [Art.s(76, cy, 110, cy + 3.0, 2.4)], Palette.WINE, 0.75, body, 2.6)
		Art.shade(im, [Art.s(76, cy - 3.0, 110, cy, 1.1)], Palette.RED, 0.55, body, 1.4)

	var arm_near: Array = [Art.s(35, 116, 30, 146, 15), Art.c(30, 149, 16)]
	Art.paint(im, arm_near, hide, Palette.OUTLINE, brute_ow, 0.24, [], 0.80, Palette.CYAN)
	_claws(im, 30, 156, -11.0, 17.0, Palette.BONE.darkened(0.52), 0.5, Palette.CYAN)
	_ao(im, arm_near, 36, 142, 15, 0.30)

	# Elite mark: a war plate lashed over the chest, and already broken. The
	# lower-right of the slab is simply never drawn, so the gap where armour
	# should be IS the missing chunk — nothing here can be subtracted away — and
	# the seams glowing through that gap are what say this one has been hit
	# before and kept coming. Straps go on first, plate over them.
	Art.paint(im, [Art.s(50, 94, 55, 112, 4.5), Art.s(102, 94, 98, 114, 4.5)],
		Palette.WOOD2_D, Palette.OUTLINE, 3.0, 0.24, [], 0.4, Palette.CYAN)
	# The slab covers the left of the chest only, and its right edge is a ragged
	# diagonal of bites, so the armour ends where it was torn away rather than at
	# a tidy border. Boxes rather than quads wherever the shape allows: a quad is
	# two triangle fields, and this slab covers a lot of pixels.
	var plate: Array = [
		Art.rr(64, 124, 20, 15, 4), Art.rr(57, 141, 13, 8, 3),
		Art.t(82, 111, 95, 120, 82, 128), Art.t(80, 130, 89, 136, 76, 142),
	]
	Art.paint(im, plate, Palette.STONE2_D.darkened(0.12), Palette.OUTLINE, 5.0, 0.26,
		[], 0.35, Palette.CYAN)
	# Bevel along the lit top and left edges, then the crack that broke it.
	Art.shade(im, [Art.s(48, 112, 88, 114, 2.0), Art.s(48, 112, 47, 146, 2.0)],
		Palette.STONE2, 0.40, plate, 2.2)
	Art.shade(im, [Art.s(70, 110, 62, 128, 2.2), Art.s(62, 128, 66, 146, 1.8)],
		Palette.INK, 0.85, plate, 2.4)
	Art.shade(im, [Art.s(52, 132, 74, 128, 1.6), Art.s(56, 120, 70, 118, 1.4)],
		Palette.INK, 0.35, plate, 1.8)
	Art.shade(im, [Art.s(82, 112, 93, 120, 2.6)], Palette.GOLD_L, 0.22, plate, 2.8)
	for rv: Array in [[52.0, 116.0], [52.0, 140.0]]:
		Art.dot(im, rv[0], rv[1], 2.2, 2.2, Palette.STONE2)
	# Two bone spikes driven through the near shoulder.
	for sp: Array in [[26.0, 88.0], [38.0, 76.0]]:
		Art.paint(im, [Art.t(sp[0] - 4.5, sp[1] + 5.0, sp[0] + 4.5, sp[1] + 5.0,
			sp[0] - 2.0, sp[1] - 11.0)], Palette.BONE.darkened(0.38), Palette.OUTLINE,
			2.5, 0.24, [], 0.5, Palette.CYAN)

	# Head sunk between the shoulders — no neck at all, the skull grows out of the
	# mass — under two crooked horns twice the size of the husk's.
	var horns: Array = [Art.s(52, 54, 43, 32, 7), Art.s(43, 32, 33, 16, 4.5)]
	Art.paint(im, horns, Palette.BONE.darkened(0.30), Palette.OUTLINE, 5.0, 0.26, [],
		0.5, Palette.GOLD_L)
	Art.paint(im, [Art.s(98, 54, 108, 34, 7)], Palette.BONE.darkened(0.30),
		Palette.OUTLINE, 5.0, 0.26, [], 0.5, Palette.GOLD_L)
	# The right horn is snapped: a jagged stump with bright bone showing.
	Art.paint(im, [Art.t(103, 32, 116, 30, 108, 20)], Palette.BONE.darkened(0.30),
		Palette.OUTLINE, 4.0, 0.26, [], 0.5, Palette.GOLD_L)
	Art.shade(im, [Art.e(110, 27, 7, 5)], Palette.BONE, 0.6, [], 3.0)
	Art.shade(im, [Art.c(33, 16, 5)], Palette.GOLD_L, 0.4, horns, 4.0)

	var head: Array = [Art.c(75, 76, 34)]
	Art.paint(im, head, hide, Palette.OUTLINE, brute_ow, 0.24, [], 0.80, Palette.CYAN)
	_lit(im, head, 58, 60, 19, 16, Palette.STEEL, 0.34)
	# Heavy brow over the eyes and a jaw slung under them: two value breaks are
	# what turn a dark ball into a skull.
	Art.shade(im, [Art.s(56, 52, 94, 52, 3.4)], Palette.INK, 0.55, head, 3.6)
	Art.shade(im, [Art.e(75, 100, 24, 13)], Palette.STEEL, 0.18, head, 6.0)
	Art.shade(im, [Art.e(75, 108, 26, 10)], Palette.INK, 0.35, head, 5.0)

	# Four eyes in two pairs: the second pair is what you notice a beat later.
	for ex: float in [61.0, 89.0]:
		Art.glow(im, ex, 72, 21, Palette.EYE_RED, 0.45)
	for ex2: float in [61.0, 89.0]:
		Art.dot(im, ex2, 72, 7.0, 7.0, Palette.EYE_RED)
		Art.dot(im, ex2, 70.4, 2.8, 2.8, Palette.TORCH_L)
	for ex3: float in [66.0, 84.0]:
		Art.glow(im, ex3, 92, 12, Palette.EYE_RED, 0.35)
		Art.dot(im, ex3, 92, 4.2, 4.2, Palette.EYE_RED)

	_ao(im, body, 75, 98, 32, 0.34)
	_ao(im, body, 92, 148, 30, 0.30)
	_ao(im, head, 90, 104, 24, 0.28)
	Art.shade(im, [Art.e(114, 116, 18, 26)], Palette.INK, 0.22, body, 7.0)
	return im
