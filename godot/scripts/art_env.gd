class_name ArtEnv
extends RefCounted
## The world: ground tiles, wall blocks, the buildable structures and the crop
## growth stages.
##
## Baked through the shared `Art` engine and registered with the Assets autoload
## via `a.put(key, image)`.
##
## TILE SIZE — tiles stay 96x96 (Palette.TILE) because Village and Dungeon both
## lay them out on a square CELL grid. Palette.TILE_W/TILE_H (96x60) exist for the
## pre-squashed ground plane; switching to those means changing the layers' tile
## stride at the same time, so it is deliberately not done here.
##
## WHY THE GROUND ISN'T NOISE
## Scattering random blobs gives texture but no structure, and structure is what
## makes a floor look built rather than generated. Every tile here has a grid or
## a grain — flagstone joints, plough furrows, the lie of the grass — with the
## noise layered on top of it. Joints run to the tile edge and repeat, so they
## still tile seamlessly.

const T := 96          # tile edge, px

static func bake(a: Node) -> void:
	_grass(a)
	_path(a)
	_dirt(a)
	_flagstone(a)
	_wall(a)
	_cabin(a)
	_forge(a)
	_crop_bed(a)
	_scaffold(a)
	_crops(a)

# ===========================================================================
# Ground
# ===========================================================================

## Meadow: mottled turf with a prevailing lie to the blades, plus clover and the
## occasional ember-orange wildflower to catch the eye.
## Four independently-seeded variants, keyed `tile_grass` and `tile_grass_1..3`.
##
## A single 96 px tile laid across a whole meadow reads as a lattice no matter how
## carefully it is drawn — and mirroring it (which Village also does) only turns
## the lattice into symmetric pairs, which the eye finds just as fast. Four seeds
## times four mirror states is sixteen distinct cells, which is enough that the
## repeat stops being findable. Every variant is wrap-scattered, so they remain
## seamless against each other and under any flip.
##
## Features are also kept SMALL and low-contrast: one big dark blob per tile is
## worth more repetition than fifty quiet marks.
static func _grass(a: Node) -> void:
	for v in range(4):
		var im := Art.img(T, T)
		im.fill(Palette.GRASS2.lightened(Art.hash01(v * 617 + 3) * 0.06))
		var s: int = 21 + v * 977
		Art.scatter_wrap(im, Palette.GRASS2_D, 10, s, 7.0, 14.0, 0.70, 0.30)
		Art.scatter_wrap(im, Palette.MOSS, 9, s + 23, 5.0, 10.0, 0.65, 0.24)
		Art.scatter_wrap(im, Palette.LEAF, 8, s + 46, 4.0, 8.0, 0.60, 0.18)
		# Blades all lean the same way across every variant — a shared wind
		# direction is what stops four seeds reading as four different fields.
		_blades(im, Palette.MOSS, 30, s + 9, -3.0)
		_blades(im, Palette.LEAF, 22, s + 50, -4.5)
		_blades(im, Palette.GRASS2_D, 18, s + 75, -2.0)
		a.put("tile_grass" if v == 0 else "tile_grass_%d" % v, im)

## Trodden earth for paths: no plough furrows (those belong to the crop beds),
## just compacted dirt, wheel ruts and stones pressed into it.
static func _path(a: Node) -> void:
	var im := Art.img(T, T)
	im.fill(Palette.DIRT.darkened(0.10))
	Art.scatter_wrap(im, Palette.DIRT_D, 12, 131, 8.0, 18.0, 0.62, 0.40)
	Art.scatter_wrap(im, Palette.DIRT.lightened(0.12), 9, 157, 5.0, 12.0, 0.60, 0.30)
	Art.scatter_wrap(im, Palette.STONE2_D, 8, 173, 1.6, 3.2, 0.75, 0.55)
	Art.scatter_wrap(im, Palette.MOSS, 4, 191, 3.0, 6.0, 0.60, 0.22)
	a.put("tile_path", im)

## Tilled earth: parallel plough furrows with clods and stones worked into them.
static func _dirt(a: Node) -> void:
	var im := Art.img(T, T)
	im.fill(Palette.DIRT)
	# Furrows run edge to edge so neighbouring tiles line up into long rows.
	for row in range(5):
		var y: float = 9.0 + float(row) * 19.0
		for x in range(0, T, 3):
			var fy: float = y + sin(float(x) * 0.09 + float(row)) * 2.2
			Art.flat(im, [Art.e(float(x), fy, 2.6, 1.9)], Palette.DIRT_D)
			Art.flat(im, [Art.e(float(x), fy - 3.4, 2.4, 1.5)], Palette.DIRT.lightened(0.10))
	Art.scatter_wrap(im, Palette.DIRT_D, 9, 13, 5.0, 11.0, 0.62, 0.55)
	Art.scatter_wrap(im, Palette.SOIL_D, 7, 88, 2.0, 4.0, 0.70, 0.60)
	Art.scatter_wrap(im, Palette.STONE2_D, 4, 52, 1.6, 3.0, 0.75, 0.50)
	a.put("tile_dirt", im)

## Ruin floor: cut flagstones. The joints are the whole point — they give the
## dungeon a sense of having been built by somebody.
static func _flagstone(a: Node) -> void:
	var im := Art.img(T, T)
	# Baked LIGHTER than Palette.COLD_FLOOR: the dungeon multiplies an ambient
	# wash over the whole layer, and a floor painted at its final on-screen value
	# comes out as pure black once that lands on it. Braziers add back from here.
	var base: Color = Palette.COLD_FLOOR.lightened(0.22)
	im.fill(base)
	# Two courses of two slabs, offset so the pattern reads as masonry not graph
	# paper. Each slab gets its own tone.
	var slabs := [
		Rect2(2, 2, 54, 44), Rect2(58, 2, 36, 44),
		Rect2(2, 50, 36, 44), Rect2(40, 50, 54, 44),
	]
	var i := 0
	for r: Rect2 in slabs:
		var tone: float = 0.05 + Art.hash01(i * 97 + 3) * 0.10
		var col: Color = base.lightened(tone)
		Art.paint(im, [Art.rr(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5,
				r.size.x * 0.5, r.size.y * 0.5, 3.0)], col, Palette.COLD_FLOOR2, 2.0, 0.10)
		# A lit top-left lip on each slab: the floor is under a raking light.
		Art.flat(im, [Art.s(r.position.x + 4, r.position.y + 2.5,
				r.position.x + r.size.x - 4, r.position.y + 2.5, 1.1)],
				Palette.STEEL.darkened(0.25))
		i += 1
	# Wear: chips, damp patches, hairline cracks.
	Art.scatter_wrap(im, Palette.COLD_FLOOR2, 8, 17, 4.0, 9.0, 0.70, 0.45)
	Art.scatter_wrap(im, Palette.STEEL, 5, 41, 1.4, 2.6, 0.80, 0.35)
	Art.flat(im, [Art.s(14, 20, 34, 33, 0.8)], Palette.COLD_FLOOR2)
	Art.flat(im, [Art.s(62, 62, 80, 74, 0.8)], Palette.COLD_FLOOR2)
	a.put("tile_floor", im)

## Wall block: dark masonry courses with a lit upper lip, so a run of them reads
## as a raised barrier rather than a hole in the floor.
static func _wall(a: Node) -> void:
	var im := Art.img(T, T)
	im.fill(Palette.COLD_WALL)
	# Brick courses, offset every other row.
	var bh := 16
	var row := 0
	for y in range(0, T, bh):
		var off: int = 0 if row % 2 == 0 else 24
		for x in range(-48, T + 48, 48):
			var bx: float = float(x + off) + 24.0
			var by: float = float(y) + float(bh) * 0.5
			Art.paint(im, [Art.rr(bx, by, 22.0, float(bh) * 0.5 - 1.5, 2.0)],
					Palette.INDIGO.darkened(0.10 + Art.hash01(x * 7 + y) * 0.14),
					Palette.COLD_WALL, 1.8, 0.14)
		row += 1
	# The lit top lip — the single most important cue that this block is tall.
	Art.vgrad(im, 0, 0, T, 9, Palette.STEEL, Palette.STEEL.darkened(0.45))
	Art.vgrad(im, 0, 9, T, 14, Palette.INDIGO, Palette.COLD_WALL)
	# Ambient occlusion along the bottom, where the wall meets the floor.
	Art.vgrad(im, 0, T - 10, T, T, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.45))
	Art.scatter_wrap(im, Palette.COLD_WALL, 6, 23, 5.0, 11.0, 0.70, 0.40)
	a.put("tile_wall", im)

## Little leaning grass blades, all sharing a wind direction.
static func _blades(im: Image, col: Color, n: int, seed: int, lean: float) -> void:
	for i in range(n):
		var k := seed * 7717 + i * 131
		var x: float = Art.hash01(k) * float(T)
		var y: float = 6.0 + Art.hash01(k + 1) * float(T - 6)
		var hgt: float = 5.0 + Art.hash01(k + 2) * 5.0
		Art.flat(im, [Art.s(x, y, x + lean, y - hgt, 1.3)], col)
		Art.flat(im, [Art.s(x + 2.4, y, x + 2.4 + lean * 0.6, y - hgt * 0.7, 1.1)], col)

# ===========================================================================
# Buildings
# ===========================================================================

## Cabin: the first thing the player raises, so it has to look like somewhere you
## would actually want to sleep. Volume comes from a shaded gable end, a roof
## overhang with a shadow under it, and light spilling out of the windows.
static func _cabin(a: Node) -> void:
	var im := Art.img(148, 156)

	# Chimney behind the roofline, with smoke.
	Art.paint(im, [Art.rr(112, 44, 11, 24, 3)], Palette.STONE2_D, Palette.OUTLINE, 4.0, 0.22)
	Art.paint(im, [Art.rr(112, 27, 13, 6, 2)], Palette.STONE2, Palette.OUTLINE, 3.5, 0.16)
	Art.radial(im, 112, 12, 15, 13, Color(0.55, 0.53, 0.58, 0.30), 1.8, 0.05)
	Art.radial(im, 104, 2, 11, 10, Color(0.55, 0.53, 0.58, 0.22), 1.8, 0.05)

	# Log wall, with the near gable in full light and a shaded return on the right.
	var wall := [Art.rr(70, 104, 44, 34, 6)]
	Art.paint(im, wall, Palette.WOOD2, Palette.OUTLINE, 5.0, 0.24, [], 0.55)
	Art.shade(im, [Art.rr(104, 104, 12, 32, 4)], Palette.NIGHT, 0.30, wall, 5.0)
	# Log courses.
	for i in range(4):
		var ly: float = 78.0 + float(i) * 15.0
		Art.flat(im, [Art.s(28, ly, 112, ly, 1.6)], Palette.WOOD2_D)
	# Corner notching — the detail that says "logs", not "brown box".
	for i in range(5):
		var ny: float = 74.0 + float(i) * 15.0
		Art.paint(im, [Art.rr(29, ny, 6, 4, 2)], Palette.WOOD2_D, Palette.OUTLINE, 2.0, 0.10)
		Art.paint(im, [Art.rr(111, ny, 6, 4, 2)], Palette.WOOD2_D, Palette.OUTLINE, 2.0, 0.10)

	# Roof: a steep thatch with a deep overhang and a ridge beam.
	Art.paint(im, [Art.t(10, 74, 74, 18, 138, 74), Art.rr(74, 74, 66, 5, 3)],
			Palette.ROOF2, Palette.OUTLINE, 5.0, 0.26, [], 0.6)
	for i in range(6):
		var t: float = float(i) / 5.0
		Art.flat(im, [Art.s(lerpf(20, 74, t), lerpf(72, 26, t),
				lerpf(28, 74, t), lerpf(72, 30, t), 1.6)], Palette.ROOF2_D)
		Art.flat(im, [Art.s(lerpf(128, 74, t), lerpf(72, 26, t),
				lerpf(120, 74, t), lerpf(72, 30, t), 1.6)], Palette.ROOF2_D)
	# The shadow the overhang throws down the wall.
	Art.shade(im, [Art.rr(70, 82, 42, 7, 3)], Palette.NIGHT, 0.38, wall, 4.0)

	# Windows: the warmth is the point. Glow first, then frame, then mullions.
	_window(im, 44, 100)
	_window(im, 96, 100)

	# Door with an ember mark burned into it — every rebuilt home gets one.
	Art.paint(im, [Art.rr(70, 124, 13, 19, 6)], Palette.WOOD2_D, Palette.OUTLINE, 3.5, 0.18)
	Art.flat(im, [Art.e(70, 120, 4.0, 5.0)], Palette.EMBER)
	Art.flat(im, [Art.e(70, 119, 1.8, 2.4)], Palette.GOLD)
	Art.flat(im, [Art.e(76, 126, 1.6, 1.6)], Palette.IRON)     # handle

	# Gable lantern under the ridge.
	Art.glow(im, 74, 60, 20.0, Palette.TORCH, 0.34)
	Art.paint(im, [Art.rr(74, 60, 6, 7, 3)], Palette.IRON, Palette.OUTLINE, 2.5, 0.16)
	Art.flat(im, [Art.e(74, 60, 3.0, 3.8)], Palette.TORCH_L)

	a.put("building_cabin", im)

## A lit window: bloom, sill, frame, mullions. Used by the cabin.
static func _window(im: Image, cx: float, cy: float) -> void:
	Art.glow(im, cx, cy, 24.0, Palette.TORCH, 0.30)
	Art.paint(im, [Art.rr(cx, cy, 11, 11, 3)], Palette.WOOD2_D, Palette.OUTLINE, 3.5, 0.14)
	Art.paint(im, [Art.rr(cx, cy, 8, 8, 2)], Palette.GOLD, Palette.GOLD, 0.001, 0.0)
	Art.flat(im, [Art.rr(cx, cy - 3, 8, 3, 1)], Palette.TORCH_L)
	Art.flat(im, [Art.s(cx, cy - 8, cx, cy + 8, 1.2)], Palette.WOOD2_D)
	Art.flat(im, [Art.s(cx - 8, cy, cx + 8, cy, 1.2)], Palette.WOOD2_D)

## Forge: stone hearth, big flue, and the furnace mouth doing the lighting. An
## anvil out front gives it a working silhouette instead of a shed one.
static func _forge(a: Node) -> void:
	var im := Art.img(148, 156)

	# Flue, tapering, with heat haze and rising sparks baked in.
	Art.paint(im, [Art.rr(106, 52, 13, 34, 4), Art.rr(106, 20, 16, 7, 3)],
			Palette.STONE2_D, Palette.OUTLINE, 4.5, 0.24, [], 0.5)
	Art.radial(im, 106, 8, 14, 12, Color(0.55, 0.53, 0.58, 0.26), 1.8, 0.05)
	Art.flat(im, [Art.e(101, 12, 1.6, 1.6)], Palette.EMBER)
	Art.flat(im, [Art.e(110, 6, 1.3, 1.3)], Palette.GOLD)

	# Stone body: rough coursed blocks rather than one smooth slab.
	var body := [Art.rr(66, 106, 48, 34, 6)]
	Art.paint(im, body, Palette.STONE2, Palette.OUTLINE, 5.0, 0.26, [], 0.6)
	for r in range(3):
		var by: float = 82.0 + float(r) * 16.0
		Art.flat(im, [Art.s(20, by, 112, by, 1.4)], Palette.STONE2_D)
		for cxi in range(3):
			var jx: float = 34.0 + float(cxi) * 30.0 + (12.0 if r % 2 == 1 else 0.0)
			Art.flat(im, [Art.s(jx, by, jx, by + 16, 1.4)], Palette.STONE2_D)

	# The furnace mouth — an arch, not a hole, and the brightest thing on screen.
	Art.glow(im, 62, 116, 40.0, Palette.TORCH, 0.42)
	Art.paint(im, [Art.rr(62, 116, 20, 17, 9)], Palette.NIGHT, Palette.OUTLINE, 4.0, 0.0)
	Art.paint(im, [Art.e(62, 120, 15, 12)], Palette.EMBER_D, Palette.EMBER_D, 0.001, 0.0)
	Art.flat(im, [Art.e(62, 122, 11, 9)], Palette.EMBER)
	Art.flat(im, [Art.e(62, 124, 7, 6)], Palette.TORCH)
	Art.flat(im, [Art.e(62, 125, 3.4, 3.0)], Palette.TORCH_L)
	# Coal bed grate.
	for i in range(4):
		var gx: float = 50.0 + float(i) * 8.0
		Art.flat(im, [Art.s(gx, 128, gx, 132, 1.4)], Palette.OUTLINE)

	# Anvil on a stump, out front and to the side.
	Art.paint(im, [Art.rr(114, 132, 10, 8, 2)], Palette.WOOD2_D, Palette.OUTLINE, 3.0, 0.18)
	Art.paint(im, [
		Art.rr(114, 120, 14, 4, 2),
		Art.rr(114, 126, 6, 4, 1),
		Art.t(100, 118, 100, 122, 92, 120),
	], Palette.STEEL, Palette.OUTLINE, 3.5, 0.22, [], 0.8, Palette.GOLD_L)

	# Tongs hung on the wall.
	Art.flat(im, [Art.s(30, 78, 26, 100, 1.8)], Palette.IRON)
	Art.flat(im, [Art.s(34, 78, 32, 100, 1.8)], Palette.IRON)

	a.put("building_forge", im)

## Crop bed: a raised timber frame with corner posts and turned soil.
static func _crop_bed(a: Node) -> void:
	var im := Art.img(132, 104)
	# Soil first, so the frame overlaps it.
	Art.paint(im, [Art.rr(66, 62, 44, 20, 4)], Palette.DIRT, Palette.OUTLINE2, 2.5, 0.18)
	for row in range(3):
		var y: float = 54.0 + float(row) * 8.0
		Art.flat(im, [Art.s(26, y, 106, y, 1.6)], Palette.DIRT_D)
	Art.scatter(im, Palette.SOIL_D, 14, 61, 132, 104, 1.4, 2.8, 0.7, 0.6)
	# Timber frame: four rails, with the near rail catching the light.
	Art.paint(im, [Art.rr(66, 44, 52, 5, 2)], Palette.WOOD2_D, Palette.OUTLINE, 3.5, 0.16)
	Art.paint(im, [Art.rr(66, 80, 52, 6, 2)], Palette.WOOD2, Palette.OUTLINE, 4.0, 0.18, [], 0.6)
	Art.paint(im, [Art.rr(18, 62, 5, 22, 2), Art.rr(114, 62, 5, 22, 2)],
			Palette.WOOD2, Palette.OUTLINE, 3.5, 0.16)
	# Corner posts.
	for p in [Vector2(18, 42), Vector2(114, 42), Vector2(18, 82), Vector2(114, 82)]:
		Art.paint(im, [Art.rr(p.x, p.y, 6, 7, 2)], Palette.WOOD2_D, Palette.OUTLINE, 3.0, 0.20)
	a.put("building_crop_bed", im)

## Scaffold: the in-progress state. Lashed poles and a ladder — it should look
## like somebody is halfway through a job, not like a finished fence.
static func _scaffold(a: Node) -> void:
	var im := Art.img(148, 156)
	# Uprights and cross rails.
	Art.paint(im, [
		Art.rr(30, 96, 5, 48, 3), Art.rr(114, 96, 5, 48, 3),
		Art.rr(72, 54, 48, 5, 3), Art.rr(72, 100, 46, 4, 3),
	], Palette.WOOD2, Palette.OUTLINE, 4.0, 0.16, [], 0.5)
	# Diagonal brace.
	Art.paint(im, [Art.s(34, 138, 112, 62, 4.5)], Palette.WOOD2_D, Palette.OUTLINE, 3.5, 0.14)
	# Rope lashings at the joints.
	for p in [Vector2(30, 54), Vector2(114, 54), Vector2(30, 100), Vector2(114, 100)]:
		Art.paint(im, [Art.rr(p.x, p.y, 8, 5, 2)], Palette.BONE, Palette.OUTLINE, 2.2, 0.14)
		Art.flat(im, [Art.s(p.x - 6, p.y - 3, p.x + 6, p.y + 3, 1.0)], Palette.WOOD2_D)
	# A ladder leaning against the frame.
	Art.paint(im, [Art.s(52, 142, 66, 60, 3.0), Art.s(64, 144, 78, 62, 3.0)],
			Palette.WOOD2, Palette.OUTLINE, 2.5, 0.12)
	for i in range(6):
		var t: float = float(i) / 5.0
		Art.flat(im, [Art.s(lerpf(53, 66, t), lerpf(140, 63, t),
				lerpf(65, 78, t), lerpf(142, 65, t), 2.0)], Palette.WOOD2_D)
	# A pennant so an unfinished plot is findable across the village.
	Art.paint(im, [Art.rr(114, 42, 2.5, 14, 1)], Palette.WOOD2_D, Palette.OUTLINE, 1.8, 0.0)
	Art.paint(im, [Art.t(116, 30, 136, 37, 116, 44)], Palette.EMBER, Palette.OUTLINE, 3.0, 0.16)
	a.put("building_scaffold", im)

# ===========================================================================
# Crops — four clearly different reads, because the player has to judge ripeness
# at a glance from across the village.
# ===========================================================================
static func _crops(a: Node) -> void:
	# 0: just-turned soil with a single pale shoot.
	var c0 := Art.img(104, 118)
	Art.paint(c0, [Art.e(52, 98, 20, 8)], Palette.DIRT, Palette.OUTLINE2, 2.5, 0.16)
	Art.flat(c0, [Art.e(46, 96, 3, 2)], Palette.DIRT_D)
	Art.flat(c0, [Art.e(58, 99, 2.6, 1.8)], Palette.DIRT_D)
	Art.paint(c0, [Art.s(52, 96, 52, 84, 2.4)], Palette.LEAF, Palette.OUTLINE, 2.0, 0.0)
	Art.paint(c0, [Art.e(52, 82, 5, 4)], Palette.LEAF, Palette.OUTLINE, 2.0, 0.10)
	a.put("crop_0", c0)

	# 1: two true leaves on a real stem.
	var c1 := Art.img(104, 118)
	Art.paint(c1, [Art.e(52, 100, 18, 7)], Palette.DIRT, Palette.OUTLINE2, 2.0, 0.14)
	Art.paint(c1, [Art.s(52, 98, 52, 62, 3.4)], Palette.MOSS, Palette.OUTLINE, 2.5, 0.0)
	Art.paint(c1, [Art.e(38, 66, 12, 7)], Palette.LEAF, Palette.OUTLINE, 3.0, 0.14)
	Art.paint(c1, [Art.e(66, 70, 11, 6)], Palette.LEAF, Palette.OUTLINE, 3.0, 0.14)
	Art.flat(c1, [Art.s(30, 66, 48, 66, 1.2)], Palette.MOSS)
	a.put("crop_1", c1)

	# 2: a full bush, leaning — the busiest silhouette of the four.
	var c2 := Art.img(104, 118)
	Art.paint(c2, [Art.e(52, 102, 18, 7)], Palette.DIRT, Palette.OUTLINE2, 2.0, 0.14)
	Art.paint(c2, [Art.s(52, 100, 56, 52, 4.0)], Palette.MOSS, Palette.OUTLINE, 2.5, 0.0)
	Art.paint(c2, [
		Art.e(32, 62, 14, 9), Art.e(74, 58, 13, 8),
		Art.e(52, 44, 16, 11), Art.e(40, 78, 11, 7),
	], Palette.LEAF, Palette.OUTLINE, 3.5, 0.18, [], 0.5)
	Art.flat(c2, [Art.s(40, 62, 60, 52, 1.3)], Palette.MOSS)
	Art.flat(c2, [Art.s(66, 58, 56, 50, 1.3)], Palette.MOSS)
	a.put("crop_2", c2)

	# 3: ripe. Heavy golden heads bending the stem — the harvest cue.
	var c3 := Art.img(104, 118)
	Art.paint(c3, [Art.e(52, 104, 18, 7)], Palette.DIRT, Palette.OUTLINE2, 2.0, 0.14)
	Art.paint(c3, [Art.s(52, 102, 58, 54, 4.0)], Palette.MOSS, Palette.OUTLINE, 2.5, 0.0)
	Art.paint(c3, [Art.e(34, 76, 13, 8), Art.e(76, 72, 12, 7)],
			Palette.LEAF, Palette.OUTLINE, 3.0, 0.16)
	# Three grain heads, different sizes, all hanging the same way.
	_grain(c3, 58, 40, 1.0)
	_grain(c3, 36, 52, 0.78)
	_grain(c3, 78, 50, 0.70)
	Art.glow(c3, 58, 40, 26.0, Palette.GOLD, 0.22)
	a.put("crop_3", c3)

## One drooping head of grain.
static func _grain(im: Image, cx: float, cy: float, k: float) -> void:
	Art.paint(im, [Art.e(cx, cy, 13 * k, 16 * k)], Palette.GOLD, Palette.OUTLINE, 3.5 * k, 0.22,
			[], 0.7, Palette.GOLD_L)
	for i in range(3):
		var y: float = cy - 8.0 * k + float(i) * 8.0 * k
		Art.flat(im, [Art.s(cx - 9 * k, y, cx + 9 * k, y, 1.4 * k)], Palette.AMBER.darkened(0.25))
	Art.flat(im, [Art.e(cx - 4 * k, cy - 7 * k, 3 * k, 3.4 * k)], Palette.AMBER)
