class_name Art
extends RefCounted
## Shared vector-drawing engine for the procedural sprite bakers.
##
## Every texture in the game is drawn from code at startup out of signed-distance
## primitives, with analytic anti-aliasing, at 2x on-screen size (Palette.PX = 0.5).
## The look it serves is storybook / "Cult of the Lamb": bold flat fills, thick dark
## sticker outlines, soft rounded shapes — now lit for the 2.5D presentation, so
## paint() also does vertical form-shading and an optional upper-left rim light.
##
## The art catalogue is split by subject across art_env / art_props / art_cast /
## art_fx, which all bake through this one engine and register their results with
## the Assets autoload.
##
## Everything is static. Coordinates are texture pixels, y down.

# Primitive type codes. The signed-distance dispatch below runs once per shape per
# pixel, so it keys off these ints — matching on the "t" string built a throwaway
# String on every one of those evaluations and dominated the bake time.
const K_CIRCLE := 0
const K_ELLIPSE := 1
const K_RRECT := 2
const K_SEG := 3
const K_TRI := 4

# Direction the key light comes from, in texture space (upper-left). Rim lights and
# form shading both use this so the whole catalogue is lit consistently.
const LIGHT_DIR := Vector2(-0.55, -0.835)

# ---------------------------------------------------------------------------
# Canvas
# ---------------------------------------------------------------------------
static func img(w: int, h: int) -> Image:
	var im := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im

# ---------------------------------------------------------------------------
# Primitive constructors (keep call sites terse)
# ---------------------------------------------------------------------------
static func c(cx: float, cy: float, r: float) -> Dictionary:
	return {"k": K_CIRCLE, "t": "circle", "c": Vector2(cx, cy), "r": r}

static func e(cx: float, cy: float, rx: float, ry: float) -> Dictionary:
	return {"k": K_ELLIPSE, "t": "ellipse", "c": Vector2(cx, cy), "rx": rx, "ry": ry}

static func rr(cx: float, cy: float, hw: float, hh: float, r: float) -> Dictionary:
	return {"k": K_RRECT, "t": "rrect", "c": Vector2(cx, cy), "hw": hw, "hh": hh, "r": r}

static func s(ax: float, ay: float, bx: float, by: float, r: float) -> Dictionary:
	return {"k": K_SEG, "t": "seg", "a": Vector2(ax, ay), "b": Vector2(bx, by), "r": r}

static func t(ax: float, ay: float, bx: float, by: float, cx: float, cy: float) -> Dictionary:
	return {"k": K_TRI, "t": "tri", "a": Vector2(ax, ay), "b": Vector2(bx, by), "c": Vector2(cx, cy)}

## Copy `prims` displaced by `d` — receding side faces, drop shades of raised
## detail, doubled-up outlines, wrap-around copies of a tile mark.
static func shift(prims: Array, d: Vector2) -> Array:
	var out: Array = []
	for prim: Dictionary in prims:
		var q: Dictionary = prim.duplicate()
		var k: int = q["k"]
		if k == K_SEG:
			q["a"] = (prim["a"] as Vector2) + d
			q["b"] = (prim["b"] as Vector2) + d
		elif k == K_TRI:
			q["a"] = (prim["a"] as Vector2) + d
			q["b"] = (prim["b"] as Vector2) + d
			q["c"] = (prim["c"] as Vector2) + d
		else:
			# circle / ellipse / rrect all key their centre under "c".
			q["c"] = (prim["c"] as Vector2) + d
		out.append(q)
	return out

## A quad, as two triangles — the workhorse for 2.5D top faces and wall faces.
static func quad(a: Vector2, b: Vector2, cc: Vector2, d: Vector2) -> Array:
	return [
		{"k": K_TRI, "t": "tri", "a": a, "b": b, "c": cc},
		{"k": K_TRI, "t": "tri", "a": a, "b": cc, "c": d},
	]

# ---------------------------------------------------------------------------
# Signed distance (negative = inside), in pixel space
# ---------------------------------------------------------------------------
static func sd(prim: Dictionary, p: Vector2) -> float:
	match int(prim["k"]):
		K_CIRCLE:
			return (p - prim["c"]).length() - float(prim["r"])
		K_ELLIPSE:
			var q: Vector2 = p - prim["c"]
			var rx: float = prim["rx"]
			var ry: float = prim["ry"]
			var k1: float = Vector2(q.x / rx, q.y / ry).length()
			if k1 < 0.0001:
				return -minf(rx, ry)
			var k2: float = Vector2(q.x / (rx * rx), q.y / (ry * ry)).length()
			return k1 * (k1 - 1.0) / k2
		K_RRECT:
			var d: Vector2 = (p - prim["c"]).abs() - Vector2(prim["hw"], prim["hh"]) + Vector2(prim["r"], prim["r"])
			var od: float = Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length()
			return od + minf(maxf(d.x, d.y), 0.0) - float(prim["r"])
		K_SEG:
			var a: Vector2 = prim["a"]
			var b: Vector2 = prim["b"]
			var pa: Vector2 = p - a
			var ba: Vector2 = b - a
			var h: float = clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
			return (pa - ba * h).length() - float(prim["r"])
		K_TRI:
			return _sd_tri(p, prim["a"], prim["b"], prim["c"])
	return 1e9

static func _sd_tri(p: Vector2, p0: Vector2, p1: Vector2, p2: Vector2) -> float:
	var e0 := p1 - p0
	var e1 := p2 - p1
	var e2 := p0 - p2
	var v0 := p - p0
	var v1 := p - p1
	var v2 := p - p2
	var pq0 := v0 - e0 * clampf(v0.dot(e0) / e0.dot(e0), 0.0, 1.0)
	var pq1 := v1 - e1 * clampf(v1.dot(e1) / e1.dot(e1), 0.0, 1.0)
	var pq2 := v2 - e2 * clampf(v2.dot(e2) / e2.dot(e2), 0.0, 1.0)
	var sg := signf(e0.x * e2.y - e0.y * e2.x)
	var dx := minf(minf(pq0.dot(pq0), pq1.dot(pq1)), pq2.dot(pq2))
	var dy := minf(minf(sg * (v0.x * e0.y - v0.y * e0.x), sg * (v1.x * e1.y - v1.y * e1.x)), sg * (v2.x * e2.y - v2.y * e2.x))
	return -sqrt(dx) * signf(dy)

static func sd_union(prims: Array, p: Vector2) -> float:
	var d := 1e9
	for prim in prims:
		d = minf(d, sd(prim, p))
	return d

static func bbox(prims: Array, m: float) -> Rect2:
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for prim in prims:
		var b := _prim_bbox(prim, m)
		mn = Vector2(minf(mn.x, b.position.x), minf(mn.y, b.position.y))
		mx = Vector2(maxf(mx.x, b.end.x), maxf(mx.y, b.end.y))
	if mn.x > mx.x:
		return Rect2(0, 0, 0, 0)
	return Rect2(mn, mx - mn)

static func _prim_bbox(prim: Dictionary, m: float) -> Rect2:
	match int(prim["k"]):
		K_CIRCLE:
			var pc: Vector2 = prim["c"]
			var r: float = float(prim["r"]) + m
			return Rect2(pc - Vector2(r, r), Vector2(r, r) * 2.0)
		K_ELLIPSE:
			var c2: Vector2 = prim["c"]
			var ex := Vector2(prim["rx"], prim["ry"]) + Vector2(m, m)
			return Rect2(c2 - ex, ex * 2.0)
		K_RRECT:
			var c3: Vector2 = prim["c"]
			var e2 := Vector2(prim["hw"], prim["hh"]) + Vector2(m, m)
			return Rect2(c3 - e2, e2 * 2.0)
		K_SEG:
			var a: Vector2 = prim["a"]
			var b: Vector2 = prim["b"]
			var r2: float = float(prim["r"]) + m
			var mn := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(r2, r2)
			var mx := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(r2, r2)
			return Rect2(mn, mx - mn)
		K_TRI:
			var pa: Vector2 = prim["a"]
			var pb: Vector2 = prim["b"]
			var pcc: Vector2 = prim["c"]
			var mn2 := Vector2(minf(pa.x, minf(pb.x, pcc.x)), minf(pa.y, minf(pb.y, pcc.y))) - Vector2(m, m)
			var mx2 := Vector2(maxf(pa.x, maxf(pb.x, pcc.x)), maxf(pa.y, maxf(pb.y, pcc.y))) + Vector2(m, m)
			return Rect2(mn2, mx2 - mn2)
	return Rect2(0, 0, 0, 0)

# ---------------------------------------------------------------------------
# Pixel core
#
# Image.get_pixel / set_pixel are binding calls, and the bakers make millions of
# them, which made startup take ten seconds. So drawing goes through a single
# cached byte buffer instead: the first operation on an image checks it out with
# _bind(), everything after that reads and writes raw RGBA8 bytes, and the buffer
# is written back by flush(). Modules draw one texture at a time, so the buffer is
# checked out once per texture. Assets.put() flushes before it reads an image; if
# you ever need to look at pixels mid-bake, call Art.flush() first.
# ---------------------------------------------------------------------------
static var _cur: Image = null
static var _data: PackedByteArray = PackedByteArray()
static var _w: int = 0
static var _h: int = 0

static func _bind(im: Image) -> void:
	if im == _cur:
		return
	flush()
	_cur = im
	_w = im.get_width()
	_h = im.get_height()
	_data = im.get_data()

## Write the working buffer back into its Image. Safe to call at any time.
static func flush() -> void:
	if _cur == null:
		return
	_cur.set_data(_w, _h, false, Image.FORMAT_RGBA8, _data)
	_cur = null
	_data = PackedByteArray()

## Alpha-composite `src` over the pixel at x,y with coverage `a`.
static func blend(im: Image, x: int, y: int, src: Color, a: float) -> void:
	_bind(im)
	_put(x, y, src, a)

# Buffer-space composite. The caller must already have _bind()-ed the image.
static func _put(x: int, y: int, src: Color, a: float) -> void:
	if a <= 0.0:
		return
	if x < 0 or y < 0 or x >= _w or y >= _h:
		return
	if a > 1.0:
		a = 1.0
	var i: int = (y * _w + x) << 2
	var da: float = float(_data[i + 3]) * 0.003921569
	var oa: float = a + da * (1.0 - a)
	if oa <= 0.0001:
		return
	var keep: float = da * (1.0 - a) * 0.003921569
	var inv: float = 1.0 / oa
	_data[i] = int(clampf((src.r * a + float(_data[i]) * keep) * inv, 0.0, 1.0) * 255.0)
	_data[i + 1] = int(clampf((src.g * a + float(_data[i + 1]) * keep) * inv, 0.0, 1.0) * 255.0)
	_data[i + 2] = int(clampf((src.b * a + float(_data[i + 2]) * keep) * inv, 0.0, 1.0) * 255.0)
	_data[i + 3] = int(clampf(oa, 0.0, 1.0) * 255.0)

## Flood the whole image with one opaque colour — the base coat of a ground tile.
static func fill(im: Image, col: Color) -> void:
	_bind(im)
	var r := int(clampf(col.r, 0.0, 1.0) * 255.0)
	var g := int(clampf(col.g, 0.0, 1.0) * 255.0)
	var b := int(clampf(col.b, 0.0, 1.0) * 255.0)
	var a := int(clampf(col.a, 0.0, 1.0) * 255.0)
	for i in range(0, _data.size(), 4):
		_data[i] = r
		_data[i + 1] = g
		_data[i + 2] = b
		_data[i + 3] = a

## Scale existing alpha down a band of rows, `from_a` at y0 easing to `to_a` at y1.
## Used to dissolve a platform edge into the void instead of cutting it off.
static func fade_v(im: Image, y0: int, y1: int, from_a: float, to_a: float) -> void:
	_bind(im)
	var span: float = maxf(float(y1 - y0), 1.0)
	for y in range(maxi(0, y0), mini(_h, y1)):
		var k: float = lerpf(from_a, to_a, clampf(float(y - y0) / span, 0.0, 1.0))
		for x in range(_w):
			var i: int = (y * _w + x) << 2
			_data[i + 3] = int(float(_data[i + 3]) * k)

# ---------------------------------------------------------------------------
# The workhorse
# ---------------------------------------------------------------------------

## Paint one outlined blob: the union of `prims` gets a dark outline ring of width
## `ow`, filled with `fill` shaded vertically by `grad` (lighter at the top, darker
## at the bottom), optionally clipped inside `clip` (for belly patches, aprons...)
## and optionally lifted by a `rim` light along its upper-left edge.
##
## Only the union's bounding box is scanned, so detail is cheap — call this many
## times per texture rather than trying to do everything in one union.
static func paint(im: Image, prims: Array, fill: Color, outline: Color, ow: float,
		grad: float = 0.16, clip: Array = [], rim: float = 0.0,
		rim_col: Color = Palette.RIM) -> void:
	if prims.is_empty():
		return
	_bind(im)
	var bb := bbox(prims, ow + 2.0)
	var x0 := maxi(0, int(floor(bb.position.x)))
	var y0 := maxi(0, int(floor(bb.position.y)))
	var x1 := mini(_w - 1, int(ceil(bb.end.x)))
	var y1 := mini(_h - 1, int(ceil(bb.end.y)))
	var top := bb.position.y
	var span: float = maxf(bb.size.y, 1.0)
	var rim_w: float = maxf(ow * 1.8, 4.0)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var d := sd_union(prims, p)
			if d > ow + 1.0:
				continue
			var a_out := clampf(ow - d + 0.75, 0.0, 1.0)
			if a_out <= 0.0:
				continue
			if not clip.is_empty():
				var dc := sd_union(clip, p)
				a_out *= clampf(-dc + 0.75, 0.0, 1.0)
				if a_out <= 0.0:
					continue
			var a_fill := clampf(-d + 0.75, 0.0, 1.0)
			var ty := clampf((y - top) / span, 0.0, 1.0)
			var fcol := fill.darkened(grad * ty)
			if ty < 0.4:
				fcol = fcol.lightened(0.08 * (0.4 - ty) / 0.4)
			# Rim light: brighten the band just inside the upper-left silhouette.
			if rim > 0.0 and a_fill > 0.0 and d > -rim_w:
				var nx := sd_union(prims, p + Vector2(1.0, 0.0)) - d
				var ny := sd_union(prims, p + Vector2(0.0, 1.0)) - d
				var n := Vector2(nx, ny)
				if n.length_squared() > 0.0001:
					n = n.normalized()
					var facing: float = clampf(n.dot(LIGHT_DIR), 0.0, 1.0)
					var band: float = clampf((d + rim_w) / rim_w, 0.0, 1.0)
					fcol = fcol.lerp(rim_col, facing * band * band * rim)
			var col := outline.lerp(fcol, a_fill)
			_put(x, y, col, a_out)

## Flat fill with no shading and no outline — for decals, stripes and details.
static func flat(im: Image, prims: Array, col: Color) -> void:
	paint(im, prims, col, col, 0.001, 0.0)

## A single soft ellipse dot (eyes, glints, pebbles).
static func dot(im: Image, cx: float, cy: float, rx: float, ry: float, col: Color,
		ow: float = 0.0, oc: Color = Palette.OUTLINE) -> void:
	paint(im, [e(cx, cy, rx, ry)], col, oc, maxf(ow, 0.001), 0.0)

## Soft translucent shading blob, clipped inside `clip` (contact shadow under a
## roof overhang, ambient occlusion where a wall meets the floor...).
static func shade(im: Image, prims: Array, col: Color, alpha: float, clip: Array = [],
		feather: float = 3.0) -> void:
	if prims.is_empty():
		return
	_bind(im)
	var bb := bbox(prims, feather + 2.0)
	var x0 := maxi(0, int(floor(bb.position.x)))
	var y0 := maxi(0, int(floor(bb.position.y)))
	var x1 := mini(_w - 1, int(ceil(bb.end.x)))
	var y1 := mini(_h - 1, int(ceil(bb.end.y)))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var d := sd_union(prims, p)
			var a: float = clampf(-d / maxf(feather, 0.001), 0.0, 1.0)
			if a <= 0.0:
				continue
			if not clip.is_empty():
				a *= clampf(-sd_union(clip, p) + 0.75, 0.0, 1.0)
				if a <= 0.0:
					continue
			_put(x, y, col, a * alpha)

# ---------------------------------------------------------------------------
# Fields (gradients, glows, falloffs)
# ---------------------------------------------------------------------------

## Vertical gradient across a rectangle. Opaque; the base coat for wall faces,
## cliff edges and UI plates.
static func vgrad(im: Image, x0: int, y0: int, x1: int, y1: int, top: Color, bot: Color) -> void:
	_bind(im)
	var h: float = maxf(float(y1 - y0), 1.0)
	for y in range(maxi(0, y0), mini(_h, y1)):
		var k: float = clampf((y - y0) / h, 0.0, 1.0)
		var col := top.lerp(bot, k)
		for x in range(maxi(0, x0), mini(_w, x1)):
			_put(x, y, col, col.a)

## Radial falloff disc: `col` at the centre easing to fully transparent at radius
## `r`. `curve` > 1 tightens the core (2.0 = quadratic ease-out). This is what the
## contact-shadow and point-light textures are made of.
static func radial(im: Image, cx: float, cy: float, rx: float, ry: float, col: Color,
		curve: float = 2.0, inner: float = 0.0) -> void:
	_bind(im)
	var x0 := maxi(0, int(floor(cx - rx)) - 1)
	var y0 := maxi(0, int(floor(cy - ry)) - 1)
	var x1 := mini(_w - 1, int(ceil(cx + rx)) + 1)
	var y1 := mini(_h - 1, int(ceil(cy + ry)) + 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := (x + 0.5 - cx) / maxf(rx, 0.001)
			var dy := (y + 0.5 - cy) / maxf(ry, 0.001)
			var q: float = sqrt(dx * dx + dy * dy)
			if q >= 1.0:
				continue
			var k: float = 1.0
			if q > inner:
				var u: float = (q - inner) / maxf(1.0 - inner, 0.001)
				k = pow(1.0 - u, curve)
			_put(x, y, col, col.a * k)

## Soft additive-looking bloom around a light source (baked into the sprite).
static func glow(im: Image, cx: float, cy: float, r: float, col: Color, alpha: float = 0.35) -> void:
	radial(im, cx, cy, r, r, Color(col.r, col.g, col.b, alpha), 2.4, 0.05)

# ---------------------------------------------------------------------------
# Deterministic noise (tiles must bake identically every run)
# ---------------------------------------------------------------------------

## Cheap hash -> [0,1). Feed it a counter; same seed, same texture, every launch.
static func hash01(n: int) -> float:
	var v: int = (n * 1103515245 + 12345) & 0x7fffffff
	v = ((v >> 13) ^ v) * 60493 & 0x7fffffff
	return float(v % 100000) / 100000.0

## Scatter `n` soft ellipses over a `w` x `h` area — ground grain, moss, speckle.
## Ellipses are drawn wide-and-flat by default because the ground is a tilted plane.
static func scatter(im: Image, col: Color, n: int, seed: int, w: int, h: int,
		rx_min: float, rx_max: float, squash: float = 0.625, alpha: float = 1.0) -> void:
	var cc := Color(col.r, col.g, col.b, col.a * alpha)
	for i in range(n):
		var k := seed * 7919 + i * 131
		var x: float = hash01(k) * float(w)
		var y: float = hash01(k + 1) * float(h)
		var rx: float = rx_min + hash01(k + 2) * (rx_max - rx_min)
		flat(im, [e(x, y, rx, rx * squash)], cc)

## Wrap-safe version for seamless ground tiles: anything crossing an edge is drawn
## again on the opposite side so neighbouring tiles line up.
static func scatter_wrap(im: Image, col: Color, n: int, seed: int,
		rx_min: float, rx_max: float, squash: float = 0.625, alpha: float = 1.0) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var cc := Color(col.r, col.g, col.b, col.a * alpha)
	for i in range(n):
		var k := seed * 6151 + i * 97
		var x: float = hash01(k) * float(w)
		var y: float = hash01(k + 1) * float(h)
		var rx: float = rx_min + hash01(k + 2) * (rx_max - rx_min)
		var ry: float = rx * squash
		for ox in [-w, 0, w]:
			for oy in [-h, 0, h]:
				var px: float = x + float(ox)
				var py: float = y + float(oy)
				if px + rx < 0.0 or px - rx > float(w) or py + ry < 0.0 or py - ry > float(h):
					continue
				flat(im, [e(px, py, rx, ry)], cc)
