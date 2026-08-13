class_name ArtEnv
extends RefCounted
## The BUILT WORLD: the eight ground tiles, the dungeon wall block, the four
## platform-edge pieces, the four village buildings and the four crop stages.
## Everything here is drawn with `Art` and registered with Assets by `a.put()`.
##
## ONE CAMERA. Two rules encode it and nothing in this file may disagree:
##  * `_recede(d)` is the shear a face uses to travel `d` px away from the viewer,
##    so every side face and every top face in the catalogue slides up-and-left by
##    the same amount and the world agrees on where the eye is.
##  * Anything LYING on the floor is squashed to `LIE` (ry = 0.625 rx); anything
##    STANDING is drawn at full height. That split — not a gradient — is what
##    makes the plane read as tilted.
##
## Ground tiles are 96x60, opaque, and seamless in BOTH axes: every mark goes
## through the `_w*` helpers, which redraw whatever crosses an edge on the far
## side. Seamless is only half the job — a tile also has to be UNMEMORABLE, so no
## feature is wider than ~18 px, 90 % of every tile stays inside a narrow value
## band, and each variant uses its own seeds, counts and layout. Shared grain is
## what turns a field into a grid.

# --- Camera / plane constants ----------------------------------------------
const TW := 96      # ground tile width in texture px -> Palette.CELL on screen
const TH := 60      # ground tile height, already squashed by Palette.SQUASH
const LIE := 0.625  # ry/rx for anything lying flat on the ground plane

## The shear a surface uses to travel `d` texture px back into the scene.
static func _recede(d: float) -> Vector2:
	return Vector2(-0.36 * d, -0.30 * d)


static func bake(a: Node) -> void:
	# Ground
	a.put("tile_grass", _tile_grass())
	a.put("tile_grass2", _tile_grass2())
	a.put("tile_grass_worn", _tile_grass_worn())
	a.put("tile_dirt", _tile_dirt())
	a.put("tile_path", _tile_path())
	a.put("tile_water", _tile_water())
	a.put("tile_floor", _floor_base(0.0, false))
	a.put("tile_floor2", _floor_base(24.0, true))
	a.put("tile_floor_crack", _tile_floor_crack())
	# Height
	a.put("wall_block", _wall_block())
	a.put("tile_wall", _tile_wall())
	# The drop to the void
	a.put("edge_front", _edge_front())
	var side := _edge_side()
	a.put("edge_side", side)
	a.put("edge_right", _mirrored(side))
	a.put("edge_back", _edge_back())
	# Structures
	a.put("building_cabin", _cabin())
	a.put("building_forge", _forge())
	a.put("building_crop_bed", _crop_bed())
	a.put("building_workshop", _workshop())
	a.put("building_scaffold", _scaffold())
	for i in range(4):
		a.put("crop_%d" % i, _crop(i))


# ===========================================================================
# Wrap-safe drawing — the seamlessness machinery
# ===========================================================================



## Every torus copy of `prims` that can land on the canvas, the identity first.
## Most marks sit well inside the tile, so the common case builds no copies.
## `wrap_y` is off for the edge strips, which tile sideways only — wrapping them
## vertically sprouts grass out of the bottom of a cliff.
static func _copies(im: Image, prims: Array, m: float, wrap_y: bool = true) -> Array:
	var w := float(im.get_width())
	var h := float(im.get_height())
	var bb := Art.bbox(prims, m)
	if bb.position.x >= 0.0 and bb.position.y >= 0.0 and bb.end.x <= w and bb.end.y <= h:
		return [[prims, Vector2.ZERO]]
	var out: Array = []
	for ox: float in [0.0, -w, w]:
		for oy: float in ([0.0, -h, h] if wrap_y else [0.0]):
			var d := Vector2(ox, oy)
			var pr: Array = prims if d == Vector2.ZERO else Art.shift(prims, d)
			var b2 := Art.bbox(pr, m)
			if b2.end.x > 0.0 and b2.end.y > 0.0 and b2.position.x < w and b2.position.y < h:
				out.append([pr, d])
	return out


static func _wflat(im: Image, prims: Array, col: Color, wrap_y: bool = true) -> void:
	for cp: Array in _copies(im, prims, 2.0, wrap_y):
		Art.flat(im, cp[0], col)


static func _wpaint(im: Image, prims: Array, fill: Color, outline: Color, ow: float,
		grad: float = 0.0, wrap_y: bool = true) -> void:
	for cp: Array in _copies(im, prims, ow + 2.0, wrap_y):
		Art.paint(im, cp[0], fill, outline, ow, grad)


## Wrap-safe soft shade. The clip travels with the shape, so a crescent clipped
## into a speck still hugs that speck when it is redrawn across the seam.
static func _wshade(im: Image, prims: Array, col: Color, alpha: float,
		feather: float = 2.0, clip: Array = [], wrap_y: bool = true) -> void:
	for cp: Array in _copies(im, prims, feather + 2.0, wrap_y):
		var d: Vector2 = cp[1]
		var cl: Array = clip if (clip.is_empty() or d == Vector2.ZERO) else Art.shift(clip, d)
		Art.shade(im, cp[0], col, alpha, cl, feather)


## A polyline as a chain of capsules — ruts, cracks, roots.
static func _poly(pts: Array, r: float) -> Array:
	var out: Array = []
	for i in range(pts.size() - 1):
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		out.append(Art.s(p0.x, p0.y, p1.x, p1.y, r))
	return out


# ===========================================================================
# Shared lighting moves
# ===========================================================================

## The contact shadow every feet-anchored texture draws FIRST. Without it the
## sprite is a sticker; `w` is the widest drawn mass.
static func _ground(im: Image, cx: float, feet_y: float, w: float, alpha: float = 0.55) -> void:
	Art.shade(im, [Art.e(cx, feet_y - 3.0, w * 0.52, w * 0.15)], Palette.INK, alpha, [], 5.0)


## Sink an occlusion into the bottom-right of one mass, clipped to it. This is
## the SHADE step of the lighting model and it is what keeps a big flat fill from
## going to cardboard.
static func _ao(im: Image, mass: Array, alpha: float = 0.28) -> void:
	var bb := Art.bbox(mass, 0.0)
	Art.shade(im, [Art.e(bb.position.x + bb.size.x * 0.72, bb.end.y,
		bb.size.x * 0.78, bb.size.y * 0.44)], Palette.INK, alpha, mass, 4.0)


## Soft puffs drifting up and to the left, away from the key light.
static func _smoke(im: Image, x: float, y: float, n: int, step: Vector2,
		col: Color, alpha: float) -> void:
	for i in range(n):
		var k := float(i)
		Art.shade(im, [Art.e(x + step.x * k, y + step.y * k, 5.0 + k * 3.2, 3.6 + k * 2.4)],
			col, alpha, [], 5.0)


## A leaf, angled. `Art.e` cannot rotate, so a leaf is a fat capsule at the stem
## tapering into a thin one at the tip, with a lit vein up the middle.
static func _leaf(im: Image, a: Vector2, b: Vector2, w: float, col: Color, lit: Color) -> void:
	var mid := a.lerp(b, 0.45)
	var body := [Art.s(a.x, a.y, mid.x, mid.y, w), Art.s(mid.x, mid.y, b.x, b.y, w * 0.42)]
	Art.paint(im, body, col, Palette.OUTLINE, 2.5, 0.22, [], 0.5, Palette.RIM)
	Art.shade(im, [Art.s(a.x, a.y, b.x, b.y, 0.9)], lit, 0.45, body, 1.4)


# ===========================================================================
# GROUND TILES — 96 x 60, opaque, seamless, grad 0 everywhere
# ===========================================================================

## Base coat. ONE flat fill: a per-tile gradient stripes at every seam, so the
## tilt has to come from the specks, not from the ground colour.
static func _tile(base: Color) -> Image:
	var im := Art.img(TW, TH)
	Art.fill(im, base)
	return im


## Still water for the sanctuary's river/pond: a deep teal base with darker depth
## mottle and bright ripple dashes, kept off the edges so a band of tiles reads as
## one sheet of water.
static func _tile_water() -> Image:
	var im := Art.img(TW, TH)
	Art.fill(im, Palette.CYAN_D)
	for i in range(8):
		var x: float = 12.0 + Art.hash01(i * 17 + 1) * float(TW - 24)
		var y: float = 8.0 + Art.hash01(i * 17 + 3) * float(TH - 16)
		Art.shade(im, [Art.e(x, y, 11.0, 5.0)], Palette.INDIGO, 0.22, [], 7.0)
	for i in range(11):
		var rx: float = 12.0 + Art.hash01(i * 29 + 5) * float(TW - 24)
		var ry: float = 8.0 + Art.hash01(i * 29 + 9) * float(TH - 16)
		Art.shade(im, [Art.s(rx - 6.0, ry, rx + 6.0, ry, 1.4)],
				Palette.CYAN.lightened(0.25), 0.4, [], 1.4)
	return im


## Flat mottling. Sizes always span a wide range (one radius repeated is the
## loudest possible tell) and colours stay close to the base, so the field gets
## texture without any shape the eye can memorise.
static func _specks(im: Image, seed: int, n: int, rx_min: float, rx_max: float,
		cols: Array) -> void:
	for i in range(n):
		var k: int = seed * 7919 + i * 131
		var x: float = Art.hash01(k) * float(im.get_width())
		var y: float = Art.hash01(k + 1) * float(im.get_height())
		var rx: float = rx_min + Art.hash01(k + 2) * (rx_max - rx_min)
		var col: Color = cols[int(Art.hash01(k + 3) * 997.0) % cols.size()]
		_wflat(im, [Art.e(x, y, rx, rx * LIE)], col)


## Raised specks: lit chip up-left, INK crescent down-right. Those two marks are
## what dome a pebble or a clod off the plane instead of letting it lie in it.
static func _domes(im: Image, seed: int, n: int, rx_min: float, rx_max: float,
		body: Color, lit: Color, dark_a: float = 0.30) -> void:
	for i in range(n):
		var k: int = seed * 8171 + i * 271
		var x: float = Art.hash01(k) * float(im.get_width())
		var y: float = Art.hash01(k + 1) * float(im.get_height())
		var rx: float = rx_min + Art.hash01(k + 2) * (rx_max - rx_min)
		var ry: float = rx * LIE
		var mass := [Art.e(x, y, rx, ry)]
		_wflat(im, mass, body)
		_wshade(im, [Art.e(x - rx * 0.36, y - ry * 0.38, rx * 0.6, ry * 0.6)], lit, 0.38, 1.8, mass)
		_wshade(im, [Art.e(x + rx * 0.42, y + ry * 0.46, rx, ry)], Palette.INK, dark_a, 2.2, mass)


## Sunken specks — the raised recipe inverted, so divots read as holes.
static func _divots(im: Image, seed: int, n: int, rx_min: float, rx_max: float,
		body: Color, lit: Color) -> void:
	for i in range(n):
		var k: int = seed * 3299 + i * 353
		var x: float = Art.hash01(k) * float(im.get_width())
		var y: float = Art.hash01(k + 1) * float(im.get_height())
		var rx: float = rx_min + Art.hash01(k + 2) * (rx_max - rx_min)
		var ry: float = rx * LIE
		var mass := [Art.e(x, y, rx, ry)]
		_wflat(im, mass, body)
		_wshade(im, [Art.e(x - rx * 0.38, y - ry * 0.42, rx, ry)], Palette.INK, 0.26, 2.0, mass)
		_wshade(im, [Art.e(x + rx * 0.36, y + ry * 0.42, rx * 0.6, ry * 0.6)], lit, 0.3, 1.8, mass)


## One blade. STANDING, so it is drawn at full height and stays thin; the outline
## is dark GREEN, never ink, because forty black-edged blades on one tile read as
## scribble at 48 px rather than as grass.
static func _blade(im: Image, x: float, y: float, bh: float, lean: float, col: Color) -> void:
	_wshade(im, [Art.e(x + 1.8, y + 1.0, 3.4, 1.4)], Palette.INK, 0.2, 2.4)
	var mid := Vector2(x + lean * 0.3, y - bh * 0.55)
	var tip := Vector2(x + lean, y - bh)
	_wpaint(im, [Art.s(x, y, mid.x, mid.y, 1.2), Art.s(mid.x, mid.y, tip.x, tip.y, 0.4)],
		col, Palette.GRASS2_D.darkened(0.45), 0.7, 0.0)


## Grass grows in tufts, not in a uniform sprinkle. Clumping is what stops a
## field of these tiles reading as noise, and it leaves the eye somewhere to rest.
static func _tufts(im: Image, seed: int, clumps: int, dark: Color, lit: Color,
		h_min: float, h_max: float) -> void:
	var w := float(im.get_width())
	var h := float(im.get_height())
	for c in range(clumps):
		var k: int = seed * 4021 + c * 313
		var cx: float = Art.hash01(k) * w
		var cy: float = Art.hash01(k + 1) * h
		var scale: float = 0.7 + Art.hash01(k + 2) * 0.6
		var n: int = 2 + int(Art.hash01(k + 3) * 3.0)
		for i in range(n):
			var j: int = k + 17 + i * 53
			var x: float = cx + (Art.hash01(j) - 0.5) * 11.0
			var y: float = cy + (Art.hash01(j + 1) - 0.5) * 6.0
			var bh: float = (h_min + Art.hash01(j + 2) * (h_max - h_min)) * scale
			var lean: float = (Art.hash01(j + 3) - 0.5) * 9.0
			# The key light is upper-left, so tufts over there catch it.
			var chance: float = 0.7 - 0.4 * clampf((x / w + y / h) * 0.5, 0.0, 1.0)
			var col: Color = lit if Art.hash01(j + 4) < chance else dark
			if Art.hash01(j + 5) > 0.86:
				col = dark.darkened(0.16)
			_blade(im, x, y, bh, lean, col)


static func _tile_grass() -> Image:
	var im := _tile(Palette.GRASS2)
	var b := Palette.GRASS2
	# Three mottling passes, all within a narrow band of the base: broad soft
	# variation first, then finer grain over it.
	_specks(im, 11, 16, 8.0, 17.0, [b.lerp(Palette.MOSS, 0.45), b.lerp(Palette.GRASS, 0.5)])
	_specks(im, 23, 22, 3.0, 9.0, [b.lerp(Palette.MOSS, 0.6), b.lerp(Palette.MOSS_L, 0.3)])
	_specks(im, 29, 26, 1.4, 3.6, [b.darkened(0.1), b.lerp(Palette.MOSS_L, 0.22)])
	_domes(im, 37, 4, 2.4, 4.2, Palette.STONE2_D.lerp(Palette.EARTH, 0.55),
		Palette.STONE2_D.lerp(Palette.AMBER, 0.3))
	# Many small tufts rather than a few distinctive ones: a big silhouette is
	# what the eye memorises and then finds again in the next tile along.
	_tufts(im, 53, 17, Palette.MOSS, Palette.MOSS_L, 6.0, 12.0)
	return im


## A clover clump: a necklace of lying ellipses, deliberately straddling an edge
## so it reads as terrain running under the seam, not as tile decoration.
static func _clover(im: Image, cx: float, cy: float, rr: float, seed: int, col: Color) -> void:
	for i in range(9):
		var k: int = seed * 613 + i * 79
		var ang: float = Art.hash01(k) * TAU
		var d: float = Art.hash01(k + 1) * rr * 0.62
		var rx: float = rr * (0.26 + Art.hash01(k + 2) * 0.2)
		_wflat(im, [Art.e(cx + cos(ang) * d, cy + sin(ang) * d * LIE, rx, rx * LIE)], col)


static func _tile_grass2() -> Image:
	var im := _tile(Palette.GRASS2_D)
	var b := Palette.GRASS2_D
	_specks(im, 71, 18, 7.0, 16.0, [b.lerp(Palette.GRASS2, 0.55), b.lerp(Palette.MOSS, 0.4)])
	_specks(im, 79, 24, 2.8, 8.0, [b.lerp(Palette.MOSS_L, 0.24), b.darkened(0.09)])
	# The two big shapes this variant carries. They cross opposite edges, which is
	# what lets a run of tiles form patches instead of a checkerboard.
	_clover(im, 3.0, 20.0, 23.0, 5, b.lerp(Palette.MOSS_L, 0.3))
	_clover(im, 93.0, 47.0, 20.0, 9, b.lerp(Palette.MOSS_L, 0.22))
	_domes(im, 83, 3, 2.4, 4.4, Palette.STONE2_D.lerp(Palette.EARTH, 0.55),
		Palette.STONE2_D.lerp(Palette.AMBER, 0.3))
	_tufts(im, 97, 13, Palette.MOSS, Palette.MOSS_L, 5.0, 11.0)
	# Three tall bright tufts, this variant's only hero specks. They are blades and
	# not `_leaf` shapes: a leaf small enough for a tile is all outline and reads as
	# a black paperclip repeating across the field.
	_tufts(im, 101, 3, Palette.LEAF, Palette.MOSS_L, 12.0, 16.0)
	return im


static func _tile_grass_worn() -> Image:
	# Trodden grass, NOT bare dirt. This tile is mixed one-in-ten into a grass
	# field, so a pure DIRT base turns every one of them into a brown rectangle;
	# meeting the grass most of the way keeps the wear reading as wear.
	var b := Palette.GRASS2_D.lerp(Palette.DIRT, 0.62)
	var im := _tile(b)
	# Every large shape stays low-contrast: a strong blob repeated every 96 px is
	# the most visible failure a tileset can have.
	_specks(im, 131, 14, 8.0, 17.0, [b.lerp(Palette.DIRT_D, 0.45), b.lerp(Palette.EARTH, 0.28)])
	_specks(im, 137, 22, 2.5, 7.0, [b.lerp(Palette.DIRT_D, 0.6), b.lerp(Palette.AMBER, 0.16)])
	_domes(im, 149, 7, 2.2, 4.6, Palette.SOIL, Palette.SOIL.lightened(0.16))
	# Grass thins rather than stopping at the tile border, so a worn patch in a
	# grass field reads as wear and not as a swapped square.
	_tufts(im, 163, 8, Palette.MOSS.darkened(0.12), Palette.MOSS, 5.0, 10.0)
	return im


static func _tile_dirt() -> Image:
	var im := _tile(Palette.DIRT_D)
	var b := Palette.DIRT_D
	_specks(im, 211, 16, 6.0, 15.0, [b.lerp(Palette.DIRT, 0.5), b.lerp(Palette.EARTH_D, 0.5)])
	_specks(im, 217, 28, 1.6, 5.0, [b.lerp(Palette.SOIL, 0.5), b.darkened(0.09)])
	_domes(im, 223, 14, 3.0, 8.0, Palette.DIRT, Palette.SOIL, 0.26)
	_divots(im, 227, 8, 3.0, 7.0, Palette.EARTH_D, Palette.DIRT)
	# Village stone is warmed toward earth. Raw STONE2_D on brown reads as spilled
	# blue beads, which is the loudest thing on the tile and the least wanted.
	_domes(im, 239, 3, 2.4, 4.0, Palette.STONE2_D.lerp(Palette.EARTH, 0.72),
		Palette.STONE2_D.lerp(Palette.AMBER, 0.3))
	return im


## One wheel rut: a wavy groove whose ends sit exactly on the tile edges so runs
## of path join up. The far wall of a groove catches the key light and the near
## one does not — that pair of lines is the whole read.
static func _rut(im: Image, y: float, seed: int, strength: float) -> void:
	var pts: Array = []
	for i in range(7):
		var x: float = float(i) * 16.0
		var j: float = 0.0 if (i == 0 or i == 6) else (Art.hash01(seed + i) - 0.5) * 7.0
		pts.append(Vector2(x, y + j))
	_wshade(im, _poly(pts, 2.6), Palette.SOIL_D, 0.85 * strength, 2.2)
	var lit: Array = []
	for p: Vector2 in pts:
		lit.append(p + Vector2(0.0, -3.8))
	_wshade(im, _poly(lit, 0.8), Palette.AMBER, 0.22 * strength, 1.3)


static func _tile_path() -> Image:
	var im := _tile(Palette.SOIL)
	# Verges are trodden darker than the crown, so the path has a centre.
	_wshade(im, [Art.e(30.0, 0.0, 44.0, 14.0)], Palette.SOIL_D, 0.45, 10.0)
	_wshade(im, [Art.e(66.0, 60.0, 44.0, 14.0)], Palette.SOIL_D, 0.45, 10.0)
	_specks(im, 307, 18, 5.0, 13.0, [Palette.SOIL.lerp(Palette.DIRT, 0.55),
		Palette.SOIL.lerp(Palette.SOIL_D, 0.4)])
	# TWO cart ruts, unevenly spaced. Three evenly spaced grooves across a brown
	# tile is floorboards, no matter how much they wobble.
	_rut(im, 15.0, 41, 1.0)
	_rut(im, 40.0, 67, 0.85)
	# Clods trodden into the ruts, which is what breaks the last of the plank read.
	_domes(im, 317, 16, 2.2, 6.0, Palette.SOIL.lerp(Palette.DIRT, 0.5),
		Palette.SOIL.lightened(0.14), 0.24)
	_specks(im, 311, 26, 1.4, 4.0, [Palette.DIRT_D, Palette.SOIL.lerp(Palette.AMBER, 0.22)])
	_domes(im, 331, 6, 2.0, 4.2, Palette.STONE2_D.lerp(Palette.EARTH, 0.72),
		Palette.STONE2_D.lerp(Palette.AMBER, 0.3))
	return im


## One flagstone. The PLUM base coat showing between stones IS the joint, so the
## stone itself is three nested rounded rects, all stone tones: a dark arris, the
## lit arris inset 1 px off the bottom-right, and the face inset 1 px off the
## top-left. Keeping the joint out of the nesting is what stops a floor of these
## reading as a brick WALL — a black ring round every stone is a mortar course,
## and mortar courses belong on a vertical surface.
static func _slab(im: Image, cx: float, cy: float, face: Color, seed: int) -> void:
	var tone: float = (Art.hash01(seed) - 0.5) * 0.2
	var f: Color = face.lightened(maxf(tone, 0.0)).darkened(maxf(-tone, 0.0))
	_wflat(im, [Art.rr(cx, cy, 22.0, 13.0, 2.0)], f.darkened(0.34))
	_wflat(im, [Art.rr(cx - 1.0, cy - 1.0, 21.5, 12.5, 2.0)], f.lerp(Palette.STONE2, 0.26))
	var face_prims := [Art.rr(cx, cy, 20.5, 11.5, 2.0)]
	_wflat(im, face_prims, f)
	# Mottling on the face, and the faintest fall-off toward the lower right. Kept
	# weak on purpose: strong per-stone shading turns a floor into a tray of pillows.
	for i in range(5):
		var k: int = seed * 71 + i * 43
		var gx: float = cx + (Art.hash01(k) - 0.5) * 36.0
		var gy: float = cy + (Art.hash01(k + 1) - 0.5) * 18.0
		var gr: float = 1.6 + Art.hash01(k + 2) * 4.0
		var dark: bool = Art.hash01(k + 3) > 0.45
		_wshade(im, [Art.e(gx, gy, gr, gr * LIE)],
			Palette.INK if dark else Palette.STONE2, 0.14, 2.2, face_prims)
	_wshade(im, [Art.e(cx + 16.0, cy + 11.0, 19.0, 11.0)], Palette.INK, 0.13, 8.0, face_prims)


## The dungeon flagstone floor. `shift` slides the grid half a stone in x (the
## variant), `alt` cools one stone and adds grit.
static func _floor_base(shift: float, alt: bool) -> Image:
	var im := _tile(Palette.PLUM)
	# The joint is the darkest thing on the tile, so the floor still has a true
	# black in it once the slabs have been baked bright.
	_specks(im, 417, 12, 2.0, 6.0, [Palette.PLUM.darkened(0.35), Palette.INK])
	var idx := 0
	for gy: float in [15.0, 45.0]:
		for gx: float in [24.0, 72.0]:
			var face: Color = Palette.PLUM_L
			if alt and idx == 2:
				face = Palette.COLD_FLOOR2.lerp(Palette.PLUM_L, 0.5)
			_slab(im, gx + shift, gy, face, 401 + idx * 37 + int(shift))
			idx += 1
	if alt:
		_specks(im, 421, 6, 1.4, 3.0, [Palette.PLUM_L.lerp(Palette.STEEL, 0.35)])
	return im


## A fracture. Both ends land exactly on a lattice corner, so a run of cracked
## floor forms one continuous break instead of eight stubs.
static func _crack(im: Image, a: Vector2, b: Vector2, seed: int, r: float) -> void:
	var pts: Array = []
	for i in range(6):
		var p := a.lerp(b, float(i) / 5.0)
		if i > 0 and i < 5:
			p += Vector2((Art.hash01(seed + i) - 0.5) * 10.0, (Art.hash01(seed + i * 3) - 0.5) * 7.0)
		pts.append(p)
	_wflat(im, _poly(pts, r), Palette.INK)
	var lit: Array = []
	for p: Vector2 in pts:
		lit.append(p + Vector2(-1.3, -1.3))
	_wshade(im, _poly(lit, 0.6), Palette.PLUM_L.lightened(0.24), 0.3, 1.1)


static func _tile_floor_crack() -> Image:
	var im := _floor_base(0.0, false)
	# ONE break across the tile plus a dead-end spur. Two crossing diagonals turned
	# a floor of these into a lattice, which is worse than no crack at all.
	_crack(im, Vector2(0.0, 0.0), Vector2(96.0, 60.0), 53, 1.3)
	_crack(im, Vector2(52.0, 33.0), Vector2(78.0, 14.0), 97, 0.9)
	# Where the break is widest the floor has dropped away.
	Art.shade(im, [Art.e(48.0, 30.0, 15.0, 9.0)], Palette.VOID, 0.45, [], 7.0)
	# Shards knocked loose along the break. They lie flat, so they are squashed
	# ellipses — triangles at this size read as little arrowheads, not stone.
	for i in range(6):
		var k: int = 601 + i * 211
		var x: float = 12.0 + Art.hash01(k) * 72.0
		var y: float = 8.0 + Art.hash01(k + 1) * 44.0
		var r: float = 2.0 + Art.hash01(k + 2) * 2.6
		_wflat(im, [Art.e(x, y, r, r * 0.5)], Palette.PLUM_L.lightened(0.12))
		_wshade(im, [Art.e(x + r * 0.5, y + 1.0, r, r * 0.5)], Palette.INK, 0.35, 1.8)
	return im


# ===========================================================================
# HEIGHT — the wall block
# ===========================================================================

## Rows 0-59 of the wall: the lit TOP face. Shared by `wall_block` and the legacy
## `tile_wall`, so a run of interior tops still tiles against the blocks. It tiles
## with itself in x, hence the wrap-safe marks and the joint at the right edge.
static func _wall_top(im: Image) -> void:
	var top := Palette.PLUM_L.lightened(0.16)
	Art.vgrad(im, 0, 0, TW, TH, top, top)
	# The top is a cut capstone, so it is broken into a few hard-edged facets with
	# real value steps between them. Soft blobs here just read as damp stains.
	_wflat(im, Art.quad(Vector2(0, 0), Vector2(58, 0), Vector2(44, 26), Vector2(0, 20)),
		top.lightened(0.06))
	_wflat(im, Art.quad(Vector2(52, 34), Vector2(96, 26), Vector2(96, 60), Vector2(40, 60)),
		top.darkened(0.1))
	_wflat(im, Art.quad(Vector2(6, 30), Vector2(30, 24), Vector2(38, 46), Vector2(10, 52)),
		top.darkened(0.05))
	_specks(im, 457, 9, 3.0, 8.0, [top.lightened(0.08), top.darkened(0.1)])
	_specks(im, 463, 18, 1.0, 2.6, [top.lightened(0.2), Palette.PLUM.darkened(0.05)])
	_wshade(im, _poly([Vector2(18, 8), Vector2(40, 18), Vector2(62, 15)], 0.8),
		Palette.INK, 0.4, 1.2)
	# Inner bevel: the block's top and left arrises catch the key light.
	_wshade(im, [Art.s(2.0, 2.0, 94.0, 2.0, 1.6)], Palette.GOLD_L, 0.4, 1.8)
	_wshade(im, [Art.s(2.0, 2.0, 2.0, 58.0, 1.6)], Palette.GOLD_L, 0.4, 1.8)
	# ...and the far corner, turned away from the light, falls off.
	Art.shade(im, [Art.rr(80.0, 54.0, 20.0, 12.0, 8.0)], Palette.INK, 0.34, [], 14.0)
	# The joints against the neighbouring blocks.
	Art.shade(im, [Art.s(95.0, 0.0, 95.0, 60.0, 1.1)], Palette.INK, 0.75, [], 1.4)
	Art.shade(im, [Art.s(93.0, 0.0, 93.0, 60.0, 0.7)], Palette.GOLD_L, 0.12, [], 1.2)


static func _tile_wall() -> Image:
	var im := Art.img(TW, TH)
	_wall_top(im)
	return im


static func _wall_block() -> Image:
	var im := Art.img(TW, 104)
	_wall_top(im)
	# Rows 60-65: the lit lip. This band is the whole illusion — the only place the
	# top plane meets the front plane — so it carries the brightest value in the
	# piece and is the one thing the dungeon ambient must not swallow.
	Art.vgrad(im, 0, 60, TW, 66, Palette.PLUM_L.lightened(0.55), Palette.PLUM_L.lightened(0.02))
	Art.shade(im, [Art.rr(48.0, 60.5, 48.0, 1.0, 0.0)], Palette.GOLD_L, 0.6, [], 1.3)
	# Rows 66-103: the front face, dropping into ink. Two full steps below the top
	# face, which is what makes the block read as a solid at 48 px.
	Art.vgrad(im, 0, 66, TW, 104, Palette.PLUM.lightened(0.06), Palette.INK)
	Art.shade(im, [Art.rr(2.5, 85.0, 2.5, 19.0, 0.0)], Palette.GOLD_L, 0.2, [], 3.5)
	# Coursed stonework. Each course is a row of individual stones — a dark mortar
	# line under it, a lit sliver on top of it, staggered vertical joints, and a
	# per-stone value nudge — because a smooth gradient with three lines ruled
	# across it reads as a painted bar, not as masonry.
	var courses: Array[float] = [66.0, 78.0, 90.0, 104.0]
	for i in range(3):
		var y0: float = courses[i]
		var y1: float = courses[i + 1]
		var stagger: float = 0.0 if i % 2 == 0 else 24.0
		for j in range(2):
			var sx: float = stagger + float(j) * 48.0
			var k: int = 991 + i * 37 + j * 13
			var v: float = (Art.hash01(k) - 0.5) * 0.7
			_wshade(im, [Art.rr(sx + 24.0, (y0 + y1) * 0.5, 22.0, (y1 - y0) * 0.5 - 1.2, 2.0)],
				Palette.GOLD_L if v > 0.0 else Palette.INK, absf(v) * 0.4, 3.0, [], false)
			_wshade(im, [Art.s(sx, y0 + 1.0, sx, y1 - 1.0, 1.0)], Palette.INK, 0.7, 1.3, [], false)
		Art.shade(im, [Art.s(0.0, y1, 96.0, y1, 1.1)], Palette.INK, 0.75, [], 1.3)
		Art.shade(im, [Art.s(0.0, y0 + 1.6, 96.0, y0 + 1.6, 0.8)], Palette.GOLD_L, 0.2, [], 1.2)
	# The base sinks into the floor instead of sitting on it.
	Art.shade(im, [Art.e(48.0, 103.0, 52.0, 7.0)], Palette.VOID, 0.62, [], 6.0)
	return im


# ===========================================================================
# PLATFORM EDGES — the drop that stops the world being an infinite bedsheet
# ===========================================================================

## Multiply the alpha of rows [y0, y1) by a 1 -> 0 ramp. `Art.blend` can only add
## coverage, so a texture that has to dissolve has to be faded directly.
static func _fade_rows(im: Image, y0: int, y1: int) -> void:
	var span: float = maxf(float(y1 - y0), 1.0)
	Art.fade_v(im, y0, y1, 1.0, 0.0)


static func _edge_front() -> Image:
	var im := Art.img(TW, 56)
	Art.vgrad(im, 0, 0, TW, 6, Palette.EARTH.lightened(0.38), Palette.EARTH.lightened(0.12))
	Art.vgrad(im, 0, 5, TW, 34, Palette.EARTH, Palette.EARTH_D)
	Art.vgrad(im, 0, 34, TW, 56, Palette.EARTH_D, Palette.VOID)
	# The lip is the brightest line in the piece: it is the last floor you see.
	Art.shade(im, [Art.s(0.0, 1.2, 96.0, 1.2, 1.2)], Palette.GOLD_L, 0.45, [], 1.3)
	# Everything below wraps in x only: this strip runs along one side of the
	# platform, so a vertical wrap would sprout grass out of the bottom of a cliff.
	# Soil strata: two ragged bands with a lit upper lip. A cliff face without
	# layers is a smear, and layers are also what sell it as cut ground.
	for si in range(2):
		var sy: float = 15.0 + float(si) * 12.0
		var band: Array = []
		for j in range(5):
			var jitter: float = 0.0 if (j == 0 or j == 4) else (Art.hash01(881 + si * 9 + j) - 0.5) * 5.0
			band.append(Vector2(float(j) * 24.0, sy + jitter))
		_wshade(im, _poly(band, 2.4), Palette.EARTH_D.darkened(0.25), 0.4, 3.0, [], false)
		_wshade(im, _poly(band, 0.8), Palette.AMBER, 0.14, 1.4, [], false)
	for i in range(5):
		var k: int = 733 + i * 149
		var x: float = 6.0 + Art.hash01(k) * 86.0
		var dx: float = (Art.hash01(k + 1) - 0.5) * 11.0
		_wshade(im, _poly([Vector2(x, 5.0), Vector2(x + dx * 0.5, 24.0), Vector2(x + dx, 44.0)], 1.5),
			Palette.EARTH_D.darkened(0.5), 0.8, 1.6, [], false)
	# Stones embedded IN the face, not balanced on the lip, and warm rather than
	# blue: nothing in the village reads cold except the portal.
	var stone := Palette.STONE2_D.lerp(Palette.EARTH, 0.72)
	for i in range(4):
		var k2: int = 907 + i * 173
		var px: float = 10.0 + Art.hash01(k2) * 76.0
		var pr: float = 2.2 + Art.hash01(k2 + 1) * 1.8
		var py: float = 11.0 + Art.hash01(k2 + 2) * 16.0
		var body := [Art.e(px, py, pr, pr * 0.85)]
		_wflat(im, body, stone, false)
		_wshade(im, [Art.e(px - pr * 0.4, py - pr * 0.4, pr * 0.6, pr * 0.5)],
			stone.lightened(0.22), 0.42, 1.5, [], false)
		_wshade(im, [Art.e(px + pr * 0.5, py + pr * 0.6, pr, pr * 0.85)], Palette.INK,
			0.45, 2.0, body, false)
	# A dense fringe of grass rooted just under the lip, so the floor above does
	# not simply stop at a ruled line.
	for i in range(16):
		var k3: int = 1013 + i * 97
		var gx: float = 1.0 + Art.hash01(k3) * 94.0
		var gh: float = 5.0 + Art.hash01(k3 + 2) * 6.0
		_wpaint(im, [Art.s(gx, 4.0, gx + (Art.hash01(k3 + 1) - 0.5) * 5.0, 4.0 - gh, 1.0)],
			Palette.MOSS if i % 3 == 0 else Palette.MOSS_L.darkened(0.1),
			Palette.GRASS2_D.darkened(0.45), 0.7, 0.0, false)
	# The bottom eight rows dissolve, so the platform has no hard lower border.
	_fade_rows(im, 48, 56)
	return im


static func _edge_side() -> Image:
	var im := Art.img(28, TH)
	# Art.vgrad cannot run horizontally, so the sideways falloff is 28 one-px
	# columns; each still gets its own vertical ramp for the lip at the top.
	for x in range(28):
		var k: float = float(x) / 27.0
		var col: Color = Palette.EARTH_D.lerp(Palette.VOID, k)
		var a: float = lerpf(1.0, 0.15, k)
		Art.vgrad(im, x, 0, x + 1, TH,
			Color(col.lightened(0.2), a), Color(col.darkened(0.25), a))
	for sx: float in [7.0, 17.0]:
		Art.shade(im, [Art.s(sx, 2.0, sx - 1.0, 58.0, 1.2)], Palette.INK, 0.4, [], 1.5)
	Art.shade(im, [Art.s(0.0, 1.0, 13.0, 1.5, 1.0)], Palette.GOLD_L, 0.3, [], 1.4)
	return im


static func _edge_back() -> Image:
	var im := Art.img(TW, 28)
	Art.vgrad(im, 0, 0, TW, 28, Color(Palette.VOID, 0.95), Color(Palette.VOID, 0.0))
	return im


static func _mirrored(src: Image) -> Image:
	var im := Image.create_from_data(src.get_width(), src.get_height(), false,
		src.get_format(), src.get_data())
	im.flip_x()
	return im


# ===========================================================================
# BUILDINGS — 3/4, sheared by _recede, base flush with the bottom edge
# ===========================================================================

const B_OW := 5.0        # building silhouette outline
const B_OW_IN := 2.5     # internal detail outline
const B_GRAD := 0.12
const B_RIM := 0.45


## Warm window: a gold core in a dark frame, a bloom behind it and a spill fan
## widening down the wall. This is where the village's light comes from.
static func _window(im: Image, cx: float, cy: float, hw: float, hh: float, wall: Array) -> void:
	Art.glow(im, cx, cy, hw * 3.0, Palette.TORCH, 0.26)
	Art.paint(im, [Art.rr(cx, cy, hw + 2.5, hh + 2.5, 3.0)], Palette.WOOD2_D, Palette.OUTLINE,
		B_OW_IN, 0.0)
	var pane := [Art.rr(cx, cy, hw, hh, 2.0)]
	Art.flat(im, pane, Palette.GOLD_L)
	Art.shade(im, [Art.rr(cx, cy + hh * 0.55, hw * 0.85, hh * 0.4, 1.0)], Palette.TORCH, 0.45, [], 2.0)
	Art.shade(im, [Art.s(cx, cy - hh, cx, cy + hh, 0.8)], Palette.WOOD2_D, 0.8, pane, 1.2)
	var spill := Art.quad(
		Vector2(cx - hw, cy + hh + 2.0), Vector2(cx + hw, cy + hh + 2.0),
		Vector2(cx + hw * 2.8, cy + hh + 46.0), Vector2(cx - hw * 2.8, cy + hh + 46.0))
	Art.shade(im, spill, Palette.TORCH, 0.24, wall, 7.0)


static func _cabin() -> Image:
	var im := Art.img(160, 180)
	_ground(im, 86.0, 178.0, 132.0)
	# Left return face, sheared back by RECEDE(40) = (-14, -12): it faces the key
	# light, so it is the LIT plane of the box.
	var ret := Art.quad(Vector2(42, 106), Vector2(42, 174), Vector2(28, 161), Vector2(28, 93))
	Art.paint(im, ret, Palette.WOOD2.lightened(0.18), Palette.OUTLINE, B_OW, B_GRAD, [],
		B_RIM, Palette.GOLD_L)
	var wall := [Art.rr(86, 140, 44, 34, 5)]
	Art.paint(im, wall, Palette.WOOD2, Palette.OUTLINE, B_OW, B_GRAD, [], 0.3, Palette.GOLD_L)
	for i in range(4):
		var py: float = 116.0 + float(i) * 14.0
		Art.shade(im, [Art.s(44, py, 128, py, 0.9)], Palette.WOOD2_D, 0.5, wall, 1.3)
		Art.shade(im, [Art.s(44, py - 1.6, 128, py - 1.6, 0.6)], Palette.GOLD_L, 0.12, wall, 1.1)
	_ao(im, wall, 0.3)
	# Roof: two triangles meeting at the apex, split at the ridge into a lit plane
	# and a shaded one — two full steps apart, which is what reads as 3D at 48 px.
	var roof_l := [Art.t(86, 40, 20, 114, 86, 114)]
	var roof_r := [Art.t(86, 40, 86, 114, 152, 114)]
	Art.paint(im, roof_l, Palette.ROOF2.lightened(0.2), Palette.OUTLINE, B_OW, B_GRAD, [],
		0.55, Palette.GOLD_L)
	Art.paint(im, roof_r, Palette.ROOF2.darkened(0.18), Palette.OUTLINE, B_OW, B_GRAD)
	# Shingle courses, drawn parallel to the eaves so the roof has a surface.
	for i in range(4):
		var sy: float = 62.0 + float(i) * 14.0
		var half: float = (sy - 40.0) / 74.0 * 66.0
		Art.shade(im, [Art.s(86 - half, sy, 86, sy, 1.0)], Palette.ROOF2_D, 0.55, roof_l, 1.3)
		Art.shade(im, [Art.s(86, sy, 86 + half, sy, 1.0)], Palette.ROOF2_D, 0.7, roof_r, 1.3)
		Art.shade(im, [Art.s(86 - half, sy - 1.8, 86, sy - 1.8, 0.7)], Palette.GOLD_L, 0.18,
			roof_l, 1.1)
	var eave := [Art.rr(86, 114, 68, 3, 2)]
	Art.paint(im, eave, Palette.ROOF2_D, Palette.OUTLINE, B_OW_IN, 0.1)
	Art.shade(im, [Art.s(20, 112, 84, 112, 1.0)], Palette.GOLD_L, 0.32, eave, 1.3)
	# The ridge slab recedes from the apex: without it the roof is a cutout.
	Art.paint(im, [Art.s(86, 40, 72, 28, 5)], Palette.ROOF2.lightened(0.28), Palette.OUTLINE,
		4.0, 0.1, [], 0.65, Palette.GOLD_L)
	Art.shade(im, [Art.rr(86, 121, 44, 6, 3)], Palette.INK, 0.38, wall, 5.0)
	# Chimney, drawn down to the roof surface (y ~ 83 at x = 124) so it grows out of
	# the slope rather than hovering over it.
	var chim := [Art.rr(124, 52, 8, 34, 3)]
	Art.paint(im, chim, Palette.STONE2_D.lerp(Palette.EARTH, 0.45), Palette.OUTLINE, 4.0,
		0.14, [], 0.5, Palette.GOLD_L)
	Art.shade(im, [Art.s(118, 22, 118, 82, 1.4)], Palette.GOLD_L, 0.32, chim, 1.6)
	_smoke(im, 120.0, 14.0, 3, Vector2(-5.0, -6.0), Palette.CREAM, 0.18)
	_window(im, 63.0, 133.0, 13.0, 10.0, wall)
	var door := [Art.rr(107, 152, 14, 21, 6)]
	Art.paint(im, door, Palette.WOOD_D, Palette.OUTLINE, B_OW_IN, 0.18, [], 0.4, Palette.GOLD_L)
	Art.shade(im, [Art.s(96, 134, 96, 172, 1.2)], Palette.GOLD_L, 0.3, door, 1.5)
	Art.dot(im, 116.0, 154.0, 2.0, 2.0, Palette.GOLD_L)
	Art.shade(im, [Art.e(107, 174, 17, 5)], Palette.INK, 0.45, [], 4.0)
	return im


static func _forge() -> Image:
	var im := Art.img(160, 180)
	_ground(im, 80.0, 178.0, 120.0)
	# Squat stone box with a FLAT roof — deliberately the cabin's opposite mass, so
	# the two silhouettes stay sortable with the fills removed. The stone is warmed
	# toward earth: nothing in the village may read cold except the portal.
	var stone := Palette.STONE2_D.lerp(Palette.EARTH, 0.62)
	var stone_l := Palette.STONE2_D.lerp(Palette.AMBER, 0.46)
	var stack := [Art.rr(52, 64, 13, 52, 4)]
	Art.paint(im, stack, stone, Palette.OUTLINE, B_OW, 0.16, [], 0.5, Palette.GOLD_L)
	Art.shade(im, [Art.s(42, 18, 42, 110, 1.8)], Palette.GOLD_L, 0.3, stack, 1.8)
	Art.shade(im, [Art.rr(60, 68, 5, 46, 2)], Palette.INK, 0.32, stack, 3.0)
	for i in range(5):
		var sy: float = 26.0 + float(i) * 17.0
		Art.shade(im, [Art.s(38, sy, 66, sy, 0.9)], Palette.INK, 0.38, stack, 1.2)
		Art.shade(im, [Art.s(38, sy - 1.6, 66, sy - 1.6, 0.6)], Palette.GOLD_L, 0.14, stack, 1.1)
	# A flared cap, so the stack ends in a chimney and not in a sawn-off pipe.
	Art.paint(im, [Art.rr(52, 15, 16, 5, 2)], stone_l, Palette.OUTLINE, B_OW_IN, 0.14, [],
		0.6, Palette.GOLD_L)
	Art.shade(im, [Art.e(52, 14, 9, 3)], Palette.INK, 0.6, [], 2.5)
	_smoke(im, 47.0, 8.0, 4, Vector2(-4.5, -2.4), Palette.CREAM, 0.15)
	var back := _recede(42.0)
	var top := Art.quad(Vector2(38, 110) + back, Vector2(134, 110) + back,
		Vector2(134, 110), Vector2(38, 110))
	Art.paint(im, top, stone_l, Palette.OUTLINE, B_OW, 0.1, [], 0.5, Palette.GOLD_L)
	# Parapet along the front of the flat roof: the lit lip that tells the eye the
	# top plane and the front plane are two different surfaces.
	Art.shade(im, [Art.s(38, 108, 134, 108, 1.8)], Palette.GOLD_L, 0.3, top, 2.0)
	Art.shade(im, [Art.rr(86, 104, 48, 4, 2)], Palette.INK, 0.22, top, 4.0)
	var ret := Art.quad(Vector2(38, 110), Vector2(38, 174),
		Vector2(38, 174) + back, Vector2(38, 110) + back)
	Art.paint(im, ret, stone.lightened(0.2), Palette.OUTLINE, B_OW, B_GRAD, [], B_RIM, Palette.GOLD_L)
	var front := [Art.rr(86, 142, 48, 32, 4)]
	Art.paint(im, front, stone, Palette.OUTLINE, B_OW, B_GRAD, [], 0.3, Palette.GOLD_L)
	# Individual stones, not ruled courses: each block gets its own value nudge, a
	# lit top-left arris and a dark joint, which is what tells a stone hut apart
	# from a grey appliance at 48 px.
	for i in range(3):
		var y0: float = 112.0 + float(i) * 20.0
		for j in range(3):
			var k: int = 733 + i * 19 + j * 5
			var sx: float = 46.0 + float(j) * 30.0 + (12.0 if i == 1 else 0.0)
			var v: float = (Art.hash01(k) - 0.5) * 0.55
			var blk := [Art.rr(sx, y0 + 9.0, 14.0, 8.0, 2.0)]
			Art.shade(im, blk, Palette.GOLD_L if v > 0.0 else Palette.INK,
				absf(v) * 0.3, front, 2.5)
			Art.shade(im, [Art.s(sx - 13.0, y0 + 1.6, sx + 13.0, y0 + 1.6, 0.8)],
				Palette.GOLD_L, 0.16, front, 1.1)
			Art.shade(im, [Art.s(sx - 14.0, y0 + 18.0, sx + 14.0, y0 + 18.0, 0.9)],
				Palette.INK, 0.4, front, 1.2)
			Art.shade(im, [Art.s(sx + 15.0, y0 + 1.0, sx + 15.0, y0 + 18.0, 0.9)],
				Palette.INK, 0.35, front, 1.2)
	_ao(im, front, 0.3)
	# Furnace mouth: an ARCH, not a disc — a perfect circle of orange on a grey box
	# reads as a washing machine. Concentric arches from ink to flame core, a baked
	# bloom and a spill fan on the ground: the village's second light source.
	Art.flat(im, [Art.c(104, 148, 20), Art.rr(104, 158, 20, 12, 2)], Palette.INK)
	Art.glow(im, 104.0, 152.0, 44.0, Palette.TORCH, 0.34)
	Art.flat(im, [Art.c(104, 150, 13), Art.rr(104, 159, 13, 10, 2)], Palette.TORCH)
	Art.flat(im, [Art.c(104, 154, 6), Art.rr(104, 161, 6, 7, 2)], Palette.TORCH_L)
	Art.shade(im, [Art.e(104, 177, 38, 11)], Palette.TORCH, 0.22, [], 9.0)
	# Anvil, standing on the ground in front of the right-hand corner. Dark iron,
	# so it does not read as a pale plug stuck on the wall, with a warm rim on the
	# side that faces the furnace.
	var iron := Palette.STEEL.darkened(0.42)
	Art.shade(im, [Art.e(138, 176, 22, 7)], Palette.INK, 0.55, [], 4.0)
	Art.paint(im, [Art.rr(137, 168, 5, 8, 1)], iron.darkened(0.25), Palette.OUTLINE, B_OW_IN, 0.2)
	var anvil := [Art.rr(137, 157, 14, 6, 2), Art.t(151, 152, 151, 162, 159, 157),
		Art.rr(137, 163, 8, 4, 2)]
	Art.paint(im, anvil, iron, Palette.OUTLINE, 3.5, 0.24, [], 0.7, Palette.GOLD_L)
	Art.shade(im, [Art.s(125, 152.5, 148, 152.5, 1.2)], Palette.GOLD_L, 0.6, anvil, 1.4)
	Art.shade(im, [Art.s(126, 158, 126, 166, 1.4)], Palette.TORCH, 0.4, anvil, 2.0)
	return im


## The Carpenter's Workshop: an open-front timber shed with a single-slope roof — a
## silhouette that reads apart from the cabin's peak and the forge's flat stone box.
## A workbench with a standing saw sits in the open front; fresh planks stack beside it.
static func _workshop() -> Image:
	var im := Art.img(160, 180)
	_ground(im, 82.0, 178.0, 124.0)
	var back := _recede(48.0)

	# Left return face (lit, receding) — the timber side wall.
	var ret := Art.quad(Vector2(40, 100), Vector2(40, 172),
		Vector2(40, 172) + back * 0.72, Vector2(40, 92) + back * 0.72)
	Art.paint(im, ret, Palette.WOOD2.lightened(0.18), Palette.OUTLINE, B_OW, B_GRAD, [],
		B_RIM, Palette.GOLD_L)

	# Dim interior back wall, seen through the open front.
	var inner := [Art.rr(90, 150, 44, 28, 3)]
	Art.paint(im, inner, Palette.WOOD2_D.darkened(0.12), Palette.OUTLINE, B_OW, 0.14)
	Art.shade(im, inner, Palette.INK, 0.34, inner, 6.0)
	for i in range(3):
		var wy: float = 130.0 + float(i) * 13.0
		Art.shade(im, [Art.s(48, wy, 132, wy, 0.9)], Palette.INK, 0.4, inner, 1.2)

	# Two front posts carrying the roof's front edge.
	var post_l := [Art.rr(48, 136, 4, 42, 2)]
	var post_r := [Art.rr(128, 136, 4, 42, 2)]
	Art.paint(im, post_l, Palette.WOOD_D, Palette.OUTLINE, B_OW_IN, 0.2, [], 0.4, Palette.GOLD_L)
	Art.paint(im, post_r, Palette.WOOD_D, Palette.OUTLINE, B_OW_IN, 0.2, [], 0.4, Palette.GOLD_L)

	# Workbench with a plank clamped and a saw standing in the cut.
	var bench := [Art.rr(88, 152, 30, 5, 2), Art.rr(66, 162, 3, 14, 1), Art.rr(110, 162, 3, 14, 1)]
	Art.paint(im, bench, Palette.WOOD2, Palette.OUTLINE, B_OW_IN, 0.2, [], 0.5, Palette.GOLD_L)
	Art.shade(im, [Art.s(60, 150, 116, 150, 1.0)], Palette.GOLD_L, 0.4, bench, 1.3)
	Art.paint(im, [Art.rr(88, 147, 26, 3, 1)], Palette.WOOD, Palette.OUTLINE, B_OW_IN, 0.16)
	var blade := [Art.t(80, 147, 94, 147, 87, 122)]
	Art.paint(im, blade, Palette.STEEL, Palette.OUTLINE, B_OW_IN, 0.14, [], 0.7, Palette.GOLD_L)
	Art.shade(im, [Art.s(82, 145, 87, 124, 1.0)], Palette.GOLD_L, 0.5, blade, 1.2)
	Art.paint(im, [Art.rr(87, 120, 5, 6, 2)], Palette.WOOD_D, Palette.OUTLINE, B_OW_IN, 0.2)

	# The mono-pitch roof: a single slab sloping down toward the viewer (higher, receded
	# at the back), drawn over the posts. Plank courses run down the slope.
	var fl := Vector2(30, 102)
	var fr := Vector2(130, 102)
	var bl := Vector2(38, 94) + back
	var br := Vector2(122, 94) + back
	var roof := Art.quad(fl, fr, br, bl)   # quad already returns an Array of prims
	Art.paint(im, roof, Palette.WOOD.lightened(0.16), Palette.OUTLINE, B_OW, B_GRAD, [],
		0.55, Palette.GOLD_L)
	for i in range(1, 6):
		var t: float = float(i) / 6.0
		Art.shade(im, [Art.s(lerpf(30.0, 130.0, t), 102.0,
			lerpf(38.0, 122.0, t) + back.x, 94.0 + back.y, 1.0)], Palette.WOOD_D, 0.4, roof, 1.2)
	var eave := [Art.rr(80, 102, 52, 3, 2)]
	Art.paint(im, eave, Palette.WOOD_D, Palette.OUTLINE, B_OW_IN, 0.1)
	Art.shade(im, [Art.s(30, 100, 130, 100, 1.2)], Palette.GOLD_L, 0.34, eave, 1.4)

	# A stack of fresh planks on the ground, left of the shed.
	Art.shade(im, [Art.e(24, 176, 20, 6)], Palette.INK, 0.4, [], 4.0)
	for i in range(4):
		var py: float = 172.0 - float(i) * 5.0
		var lit: Color = Palette.WOOD2 if i % 2 == 0 else Palette.WOOD
		Art.paint(im, [Art.rr(24, py, 16, 3, 1)], lit, Palette.OUTLINE, B_OW_IN, 0.16, [],
			0.4, Palette.GOLD_L)
	# sawdust specks scattered in the front
	for i in range(6):
		var k: int = 917 + i * 7
		Art.dot(im, 62.0 + Art.hash01(k) * 60.0, 170.0 + Art.hash01(k + 1) * 8.0, 1.4, 1.0,
			Palette.WOOD.lightened(0.22))
	return im


static func _crop_bed() -> Image:
	var im := Art.img(128, 96)
	_ground(im, 64.0, 94.0, 112.0)
	# No vertical mass at all: a flat wide lozenge, so it never competes with the
	# cabin or the forge in the glance test.
	# Everything is DARK soil, not DIRT. `DIRT` is a wood brown: painted into a
	# rounded box with lines ruled across it, it reads as a plank trough every time.
	var berm := [Art.rr(64, 70, 56, 18, 8)]
	Art.paint(im, berm, Palette.SOIL_D.darkened(0.15), Palette.OUTLINE, B_OW, B_GRAD, [],
		B_RIM, Palette.GOLD_L)
	# The top face carries NO outline of its own: an outlined ellipse sitting on an
	# outlined berm is a second silhouette, and reads as a rim.
	var face := [Art.e(64, 61, 52, 15)]
	Art.flat(im, face, Palette.DIRT_D)
	Art.shade(im, [Art.e(44, 53, 38, 11)], Palette.DIRT.lightened(0.12), 0.45, face, 8.0)
	# Furrows are ROWS OF CLODS, not ruled lines: a ploughed bed is lumpy, and a
	# continuous stroke across a brown ellipse is indistinguishable from a plank.
	for i in range(4):
		var y: float = 51.0 + float(i) * 7.0
		for j in range(13):
			var k: int = 613 + i * 31 + j * 7
			var cx: float = 14.0 + float(j) * 8.0 + (Art.hash01(k) - 0.5) * 4.0
			var cy: float = y + (Art.hash01(k + 1) - 0.5) * 2.6
			var cr: float = 2.6 + Art.hash01(k + 2) * 2.4
			# Trough behind the clod, then the clod, then its own cast shade.
			Art.shade(im, [Art.e(cx, cy + 2.4, cr * 1.3, cr * 0.7)], Palette.INK, 0.3, face, 2.2)
			Art.shade(im, [Art.e(cx, cy, cr, cr * LIE)], Palette.SOIL, 0.5, face, 1.6)
			Art.shade(im, [Art.e(cx - cr * 0.3, cy - cr * 0.3, cr * 0.6, cr * 0.4)],
				Palette.AMBER, 0.22, face, 1.4)
	_ao(im, berm, 0.26)
	# Corner stakes: the bed's only verticals, kept thin so the flat lozenge
	# silhouette survives the glance test against the cabin and the forge.
	for p: Vector2 in [Vector2(13, 54), Vector2(115, 54), Vector2(10, 78), Vector2(118, 78)]:
		Art.shade(im, [Art.e(p.x + 2.0, p.y + 8.0, 5.0, 2.6)], Palette.INK, 0.45, [], 3.0)
		Art.paint(im, [Art.rr(p.x, p.y, 2.0, 8.0, 1.0)], Palette.WOOD2_D, Palette.OUTLINE,
			2.0, 0.2, [], 0.5, Palette.GOLD_L)
	return im


static func _scaffold() -> Image:
	var im := Art.img(160, 180)
	_ground(im, 83.0, 178.0, 124.0)
	# Sawdust and offcuts on the ground, lying flat (ry = 0.4 rx).
	for i in range(6):
		var k: int = 977 + i * 137
		var x: float = 24.0 + Art.hash01(k) * 110.0
		var y: float = 164.0 + Art.hash01(k + 1) * 12.0
		var r: float = 4.0 + Art.hash01(k + 2) * 5.0
		Art.flat(im, [Art.e(x, y, r, r * 0.4)], Palette.SOIL)
	for i in range(3):
		var ox: float = 32.0 + float(i) * 40.0
		var oy: float = 170.0 + float(i % 2) * 5.0
		Art.shade(im, [Art.e(ox + 3.0, oy + 2.0, 13.0, 4.0)], Palette.INK, 0.4, [], 3.0)
		Art.paint(im, [Art.e(ox, oy, 12.0, 4.0)], Palette.WOOD2, Palette.OUTLINE, 3.0, 0.15)
	# The frame. Every member is painted on its own so each gets its own falloff and
	# its own rim — a single union would go flat.
	for x: float in [26.0, 58.0, 104.0, 140.0]:
		Art.shade(im, [Art.e(x + 3.0, 176.0, 9.0, 4.0)], Palette.INK, 0.45, [], 3.0)
		Art.paint(im, [Art.s(x, 40, x, 176, 4)], Palette.WOOD2_D, Palette.OUTLINE, B_OW_IN,
			0.22, [], B_RIM, Palette.GOLD_L)
	Art.paint(im, [Art.s(26, 124, 104, 74, 3)], Palette.WOOD2_D.darkened(0.12), Palette.OUTLINE,
		B_OW_IN, 0.2, [], B_RIM, Palette.GOLD_L)
	Art.paint(im, [Art.s(58, 74, 140, 124, 3)], Palette.WOOD2_D.darkened(0.12), Palette.OUTLINE,
		B_OW_IN, 0.2, [], B_RIM, Palette.GOLD_L)
	for y: float in [74.0, 124.0]:
		Art.paint(im, [Art.s(26, y, 140, y, 4)], Palette.WOOD2, Palette.OUTLINE, B_OW_IN,
			0.2, [], B_RIM, Palette.GOLD_L)
	# Half-clad wall: only the lower left is boarded, so you still see through it.
	for i in range(5):
		var py: float = 130.0 + float(i) * 11.0
		Art.paint(im, [Art.rr(58, py, 32, 4.5, 2)], Palette.WOOD2, Palette.OUTLINE, 2.0,
			0.22, [], 0.4, Palette.GOLD_L)
	# Ladder.
	for rx: float in [110.0, 134.0]:
		Art.paint(im, [Art.s(rx, 80, rx, 176, 3)], Palette.WOOD2, Palette.OUTLINE, 2.0,
			0.2, [], B_RIM, Palette.GOLD_L)
	for i in range(5):
		var ry: float = 96.0 + float(i) * 16.0
		Art.paint(im, [Art.s(110, ry, 134, ry, 2.5)], Palette.WOOD2, Palette.OUTLINE, 1.8, 0.2)
	# Tarp lashed over the top-left corner of the frame. The hem is scalloped with
	# three circles on the bottom edge — a bare quad reads as a folded paper dart.
	var tarp := Art.quad(Vector2(18, 46), Vector2(70, 40), Vector2(74, 68), Vector2(22, 74))
	tarp.append(Art.c(34, 73, 7))
	tarp.append(Art.c(50, 71, 8))
	tarp.append(Art.c(66, 68, 6))
	tarp.append(Art.t(70, 66, 78, 92, 56, 76))
	Art.paint(im, tarp, Palette.CREAM.darkened(0.32).lerp(Palette.WOOD2, 0.2), Palette.OUTLINE,
		B_OW, 0.26, [], 0.5, Palette.GOLD_L)
	Art.shade(im, [Art.s(24, 50, 68, 46, 2.4)], Palette.CREAM, 0.3, tarp, 3.5)
	Art.shade(im, [Art.s(22, 66, 76, 62, 3.2)], Palette.INK, 0.34, tarp, 4.5)
	Art.shade(im, [Art.s(44, 42, 48, 74, 1.6)], Palette.INK, 0.22, tarp, 3.0)
	# Cord lashing it to the two uprights it hangs from.
	for lx: float in [26.0, 58.0]:
		Art.shade(im, [Art.s(lx - 5.0, 43.0, lx + 5.0, 45.0, 1.1)], Palette.WOOD2_D, 0.8, [], 1.4)
	# Bucket on the left ledger.
	Art.paint(im, [Art.s(34, 78, 46, 78, 1.2)], Palette.STEEL, Palette.OUTLINE, 1.6, 0.0)
	Art.paint(im, [Art.rr(40, 90, 8, 9, 3)], Palette.WOOD2_D, Palette.OUTLINE, B_OW_IN,
		0.22, [], 0.5, Palette.GOLD_L)
	return im


# ===========================================================================
# CROPS — four stages that must sort by height alone at 48 px
# ===========================================================================

static func _crop(stage: int) -> Image:
	var im := Art.img(96, 110)
	_ground(im, 48.0, 108.0, 56.0)
	var mound := [Art.e(48, 100, 26, 9)]
	Art.paint(im, mound, Palette.DIRT_D, Palette.OUTLINE, 3.5, 0.14, [], 0.4, Palette.GOLD_L)
	Art.shade(im, [Art.e(40, 96, 14, 5)], Palette.DIRT, 0.5, mound, 3.0)
	_ao(im, mound, 0.3)
	match stage:
		0:
			# Two shoots, barely up. They are lit and the mound is not, because the
			# player has to tell this apart from bare soil at a glance.
			for sx: float in [43.0, 53.0]:
				Art.paint(im, [Art.s(sx, 98, sx + (sx - 48.0) * 0.25, 90, 2.0)], Palette.SPROUT,
					Palette.OUTLINE, 1.8, 0.2, [], 0.6, Palette.GOLD_L)
		1:
			Art.paint(im, [Art.s(48, 99, 48, 74, 2.6)], Palette.MOSS, Palette.OUTLINE, 2.2,
				0.2, [], 0.5, Palette.GOLD_L)
			_leaf(im, Vector2(48, 84), Vector2(32, 76), 4.5, Palette.LEAF, Palette.MOSS_L)
			_leaf(im, Vector2(48, 88), Vector2(64, 82), 4.2, Palette.LEAF.darkened(0.1), Palette.MOSS_L)
			_leaf(im, Vector2(48, 76), Vector2(52, 62), 4.0, Palette.LEAF, Palette.MOSS_L)
		2:
			Art.paint(im, [Art.s(48, 99, 48, 58, 3.0)], Palette.MOSS, Palette.OUTLINE, 2.2,
				0.2, [], 0.5, Palette.GOLD_L)
			_leaf(im, Vector2(48, 90), Vector2(24, 82), 5.5, Palette.LEAF.darkened(0.12), Palette.MOSS_L)
			_leaf(im, Vector2(48, 86), Vector2(72, 78), 5.5, Palette.LEAF.darkened(0.12), Palette.MOSS_L)
			_leaf(im, Vector2(48, 76), Vector2(26, 64), 5.0, Palette.LEAF, Palette.MOSS_L)
			_leaf(im, Vector2(48, 72), Vector2(72, 62), 5.0, Palette.LEAF, Palette.MOSS_L)
			_leaf(im, Vector2(48, 62), Vector2(44, 46), 4.6, Palette.MOSS_L, Palette.GOLD_L)
		_:
			Art.paint(im, [Art.s(48, 99, 48, 46, 3.4)], Palette.MOSS, Palette.OUTLINE, 2.2,
				0.2, [], 0.5, Palette.GOLD_L)
			_leaf(im, Vector2(48, 92), Vector2(20, 84), 6.0, Palette.LEAF.darkened(0.12), Palette.MOSS_L)
			_leaf(im, Vector2(48, 88), Vector2(76, 80), 6.0, Palette.LEAF.darkened(0.12), Palette.MOSS_L)
			_leaf(im, Vector2(48, 76), Vector2(22, 62), 5.4, Palette.LEAF, Palette.MOSS_L)
			_leaf(im, Vector2(48, 72), Vector2(74, 58), 5.4, Palette.LEAF, Palette.MOSS_L)
			_leaf(im, Vector2(48, 58), Vector2(28, 46), 4.8, Palette.MOSS_L, Palette.GOLD_L)
			# The bloom: the only saturated gold in the crop line, so a ripe plot
			# reads from across the village.
			Art.glow(im, 48.0, 34.0, 26.0, Palette.GOLD, 0.18)
			Art.paint(im, [Art.c(48, 34, 15)], Palette.GOLD, Palette.OUTLINE, 3.5, 0.2, [],
				0.7, Palette.GOLD_L)
			Art.paint(im, [Art.c(48, 34, 6)], Palette.AMBER, Palette.OUTLINE, 1.6, 0.0)
			Art.shade(im, [Art.c(42, 28, 6)], Palette.GOLD_L, 0.5, [Art.c(48, 34, 15)], 3.0)
	return im
