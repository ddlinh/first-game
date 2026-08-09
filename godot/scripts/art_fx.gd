class_name ArtFx
extends RefCounted
## Engine and interface textures: contact shadow, light falloff, particle motes,
## slash arcs, impact rings and the rest of the effect vocabulary.
##
## Baked through the shared `Art` engine and registered with the Assets autoload
## via `a.put(key, image)`.
##
## THE EFFECT VOCABULARY
## Everything the game throws at the screen is assembled from a small set of
## shapes, so hits, dashes and hammer blows all read as the same world:
##   arcs    a swing carves a tapered crescent (slash_light / _heavy / _thrust)
##   rings   an impact pushes a ring of air out along the ground (ring, ring_soft)
##   motes   heat rises as embers, matter falls as ash, ground kicks up dust
##   sparks  metal-on-metal throws hard four-point stars
## Warm = alive (ember, gold). Cold = the husks and the dark (steel, cyan).

# ---------------------------------------------------------------------------
# Public bake
# ---------------------------------------------------------------------------
static func bake(a: Node) -> void:
	_ground(a)
	_lights(a)
	_motes(a)
	_arcs(a)
	_impacts(a)
	_debris(a)

# ---------------------------------------------------------------------------
# Contact shadow + light falloff (required by Iso)
# ---------------------------------------------------------------------------

## The blob every standing thing drops on the floor. Baked WHITE with an alpha
## falloff — Iso.shadow tints it black — and pre-squashed to the ground plane so
## it lies flat instead of ballooning up the screen.
## Iso scales it by width/128, so 128 px across is the reference size.
static func _ground(a: Node) -> void:
	var sh := Art.img(128, 80)
	# Two stacked falloffs: a tight dark core under the feet, a wide soft skirt.
	Art.radial(sh, 64, 40, 62, 38, Color(1, 1, 1, 0.55), 2.2, 0.0)
	Art.radial(sh, 64, 40, 40, 24, Color(1, 1, 1, 0.62), 1.6, 0.18)
	a.put("shadow", sh)

	# A harder, smaller shadow for pickups and small props.
	var sm := Art.img(64, 40)
	Art.radial(sm, 32, 20, 30, 18, Color(1, 1, 1, 0.72), 1.8, 0.14)
	a.put("shadow_small", sm)

## Point-light falloff. Iso.light assumes 256 px across (texture_scale 1.0 ==
## 128 px radius). Slightly super-linear so lights have a defined pool edge
## rather than washing the whole room flat.
static func _lights(a: Node) -> void:
	var l := Art.img(256, 256)
	Art.radial(l, 128, 128, 127, 127, Color(1, 1, 1, 1.0), 2.35, 0.04)
	a.put("light_soft", l)

	# Tighter core light for lanterns and the hero's ember.
	var lc := Art.img(256, 256)
	Art.radial(lc, 128, 128, 127, 127, Color(1, 1, 1, 1.0), 3.4, 0.02)
	a.put("light_tight", lc)

# ---------------------------------------------------------------------------
# Particle motes
# ---------------------------------------------------------------------------
static func _motes(a: Node) -> void:
	# Ember: the game's signature mote. Halo -> body -> white-hot core, so it
	# still reads as fire when the particle system tints it.
	var em := Art.img(32, 32)
	Art.radial(em, 16, 16, 15, 15, Color(1.0, 0.45, 0.12, 0.30), 2.2, 0.0)
	Art.dot(em, 16, 16, 6.5, 6.5, Palette.EMBER)
	Art.dot(em, 16, 15.2, 3.4, 3.4, Palette.GOLD)
	Art.dot(em, 15.6, 14.6, 1.6, 1.6, Color(1, 1, 1, 0.92))
	a.put("ember", em)

	# Ash: cold, matte, irregular — what a husk leaves behind. No glow.
	var ash := Art.img(24, 24)
	Art.paint(ash, [Art.t(4, 13, 12, 4, 20, 12), Art.t(4, 13, 20, 12, 11, 20)],
			Palette.HUSK, Palette.HUSK_D, 1.4, 0.30)
	a.put("ash", ash)

	# Dust: soft, pale, no outline — kicked up by feet and dashes.
	var du := Art.img(48, 48)
	Art.radial(du, 24, 26, 23, 17, Color(0.86, 0.78, 0.64, 0.42), 1.7, 0.10)
	Art.radial(du, 19, 22, 11, 8, Color(0.95, 0.90, 0.79, 0.34), 1.5, 0.08)
	a.put("dust", du)

	# Smoke: darker, taller, slower — chimneys and dying braziers.
	var sm := Art.img(48, 48)
	Art.radial(sm, 24, 24, 22, 22, Color(0.42, 0.40, 0.46, 0.40), 1.9, 0.10)
	Art.radial(sm, 20, 20, 11, 11, Color(0.55, 0.53, 0.58, 0.30), 1.6, 0.05)
	a.put("smoke", sm)

	# Spark: hard four-point star. Metal on stone, hammer on nail.
	var sp := Art.img(40, 40)
	Art.radial(sp, 20, 20, 18, 18, Color(1.0, 0.80, 0.35, 0.22), 2.6, 0.0)
	_star4(sp, 20, 20, 18.0, 3.1, Palette.GOLD_L)
	Art.dot(sp, 20, 20, 3.0, 3.0, Color(1, 1, 1, 0.95))
	a.put("spark", sp)

	# Glint: the same star, smaller and cooler — pickups, completed builds.
	var gl := Art.img(32, 32)
	_star4(gl, 16, 16, 14.0, 2.2, Color(1, 1, 1, 0.95))
	Art.dot(gl, 16, 16, 2.4, 2.4, Color(1, 1, 1, 1))
	a.put("glint", gl)

	# Leaf/seed mote for harvests and crop growth.
	var lf := Art.img(24, 24)
	Art.paint(lf, [Art.e(12, 12, 9, 5)], Palette.LEAF, Palette.MOSS, 1.4, 0.22)
	a.put("leaf", lf)

# ---------------------------------------------------------------------------
# Slash arcs
# ---------------------------------------------------------------------------
## All three arcs are authored pointing RIGHT (+X) and centred on the texture,
## so gameplay code can just set `rotation = dir.angle()`.
static func _arcs(a: Node) -> void:
	# Light swing: a thin, fast, wide crescent — the bread-and-butter attack.
	var s1 := Art.img(128, 128)
	_arc(s1, 64, 64, 34.0, 50.0, -1.15, 1.15, 0.55,
			Color(1, 1, 1, 0.98), Color(1.0, 0.78, 0.42, 0.55))
	a.put("slash_light", s1)
	a.put("slash", s1)          # legacy key kept alive for existing call sites

	# Heavy swing: the combo finisher. Fatter, hotter, with an ember wash behind.
	var s2 := Art.img(160, 160)
	_arc(s2, 80, 80, 36.0, 66.0, -1.45, 1.45, 0.50,
			Color(1.0, 0.95, 0.80, 0.98), Palette.EMBER)
	_arc(s2, 80, 80, 52.0, 74.0, -1.30, 1.30, 0.70,
			Color(1.0, 0.55, 0.20, 0.40), Color(1.0, 0.35, 0.10, 0.0))
	a.put("slash_heavy", s2)

	# Dash strike: a forward lance rather than a sweep.
	var s3 := Art.img(160, 96)
	_cone(s3, 26, 48, 118.0, 30.0, Color(1, 1, 1, 0.92), Color(1.0, 0.72, 0.35, 0.0))
	a.put("slash_thrust", s3)

	# Dash streak: the smear the hero leaves in the air. Pure light, no outline.
	var st := Art.img(160, 48)
	_cone(st, 8, 24, 150.0, 20.0, Color(1.0, 0.86, 0.62, 0.55), Color(1.0, 0.55, 0.22, 0.0))
	a.put("streak", st)

# ---------------------------------------------------------------------------
# Impact rings and flashes
# ---------------------------------------------------------------------------
static func _impacts(a: Node) -> void:
	# Ground shockwave: a hard-edged ring, pre-squashed so it lies on the floor.
	var r := Art.img(192, 120)
	_ring(r, 96, 60, 88.0, 55.0, 7.0, Color(1.0, 0.92, 0.74, 0.95))
	_ring(r, 96, 60, 78.0, 49.0, 3.0, Color(1.0, 0.62, 0.26, 0.45))
	a.put("ring", r)

	# Softer ring for dashes and build completions — a pressure wave, not a hit.
	var rs := Art.img(192, 120)
	_ring(rs, 96, 60, 86.0, 54.0, 12.0, Color(1.0, 0.88, 0.70, 0.34))
	a.put("ring_soft", rs)

	# Impact flash: the white-hot star at the point of contact.
	var im := Art.img(96, 96)
	Art.radial(im, 48, 48, 46, 46, Color(1.0, 0.85, 0.55, 0.30), 2.6, 0.0)
	_star4(im, 48, 48, 44.0, 8.0, Color(1, 1, 1, 0.95))
	_star4(im, 48, 48, 30.0, 12.0, Color(1.0, 0.90, 0.66, 0.85))
	Art.dot(im, 48, 48, 9.0, 9.0, Color(1, 1, 1, 0.98))
	a.put("impact", im)

	# Blocked / armoured hit: cold, tight, no warmth.
	var ic := Art.img(80, 80)
	_star4(ic, 40, 40, 34.0, 7.0, Color(0.85, 0.92, 1.0, 0.90))
	Art.dot(ic, 40, 40, 6.0, 6.0, Color(1, 1, 1, 0.95))
	a.put("impact_cold", ic)

# ---------------------------------------------------------------------------
# Debris (construction, breakage)
# ---------------------------------------------------------------------------
static func _debris(a: Node) -> void:
	# Wood chip: what flies off a scaffold when the hammer lands.
	var wc := Art.img(28, 20)
	Art.paint(wc, Art.quad(Vector2(3, 10), Vector2(12, 4), Vector2(25, 9), Vector2(14, 16)),
			Palette.WOOD2, Palette.OUTLINE, 1.8, 0.26)
	a.put("chip_wood", wc)

	# Stone chip: greyer, blockier.
	var sc := Art.img(24, 22)
	Art.paint(sc, Art.quad(Vector2(4, 11), Vector2(11, 4), Vector2(20, 10), Vector2(12, 18)),
			Palette.STONE2, Palette.OUTLINE, 1.8, 0.26)
	a.put("chip_stone", sc)

# ===========================================================================
# Local drawing helpers — shapes the Art engine has no SDF primitive for.
# ===========================================================================

## Four-point star (a "sparkle"): two tapered spikes crossed at right angles.
## `r` is the spike length, `w` the half-width at the centre.
static func _star4(im: Image, cx: float, cy: float, r: float, w: float, col: Color) -> void:
	Art.flat(im, [
		Art.t(cx - r, cy, cx, cy - w, cx, cy + w),
		Art.t(cx + r, cy, cx, cy - w, cx, cy + w),
		Art.t(cx, cy - r, cx - w, cy, cx + w, cy),
		Art.t(cx, cy + r, cx - w, cy, cx + w, cy),
	], col)

## A crescent slice of an annulus, tapering to nothing at both ends.
##
## Centred on (cx, cy), spanning `a0`..`a1` radians (0 = +X, so the arc points
## right by default). `r_in`/`r_out` bound it radially; `bias` in 0..1 slides the
## brightest point along the arc (0.5 = middle, <0.5 = leading edge hotter).
## Colour lerps from `col_in` at the inner edge to `col_out` at the outer edge.
static func _arc(im: Image, cx: float, cy: float, r_in: float, r_out: float,
		a0: float, a1: float, bias: float, col_in: Color, col_out: Color) -> void:
	var x0 := maxi(0, int(floor(cx - r_out)) - 2)
	var y0 := maxi(0, int(floor(cy - r_out)) - 2)
	var x1 := mini(im.get_width() - 1, int(ceil(cx + r_out)) + 2)
	var y1 := mini(im.get_height() - 1, int(ceil(cy + r_out)) + 2)
	var span: float = maxf(a1 - a0, 0.0001)
	var mid: float = r_in + (r_out - r_in) * 0.5
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx: float = x + 0.5 - cx
			var dy: float = y + 0.5 - cy
			var d: float = sqrt(dx * dx + dy * dy)
			if d < r_in - 1.5 or d > r_out + 1.5:
				continue
			var ang: float = atan2(dy, dx)
			# Normalised position along the sweep, 0..1.
			var u: float = (ang - a0) / span
			if u < 0.0 or u > 1.0:
				continue
			# Taper: full thickness at `bias`, pinched to a point at both ends.
			var taper: float = 1.0 - absf(u - bias) / maxf(bias, 1.0 - bias)
			taper = clampf(taper, 0.0, 1.0)
			taper = taper * taper * (3.0 - 2.0 * taper)   # smoothstep
			if taper <= 0.001:
				continue
			# Radial coverage, narrowed by the taper so the ends are thin as well
			# as faint — a real blade sweep, not a rubber band.
			var half: float = (r_out - r_in) * 0.5 * taper
			var rd: float = absf(d - mid)
			var cov: float = clampf((half - rd) + 0.75, 0.0, 1.0)
			if cov <= 0.0:
				continue
			var k: float = clampf((d - r_in) / maxf(r_out - r_in, 0.001), 0.0, 1.0)
			var col: Color = col_in.lerp(col_out, k)
			Art.blend(im, x, y, col, cov * col.a * taper)

## A tapered lance pointing +X: full height at the base, a point at the tip.
static func _cone(im: Image, bx: float, by: float, length: float, half_h: float,
		col_base: Color, col_tip: Color) -> void:
	var x0 := maxi(0, int(floor(bx)) - 2)
	var y0 := maxi(0, int(floor(by - half_h)) - 2)
	var x1 := mini(im.get_width() - 1, int(ceil(bx + length)) + 2)
	var y1 := mini(im.get_height() - 1, int(ceil(by + half_h)) + 2)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var u: float = (x + 0.5 - bx) / maxf(length, 0.001)
			if u < 0.0 or u > 1.0:
				continue
			# Ogive rather than a straight cone — reads as speed, not a triangle.
			var h: float = half_h * pow(1.0 - u, 0.62)
			var dy: float = absf(y + 0.5 - by)
			var cov: float = clampf((h - dy) + 0.75, 0.0, 1.0)
			if cov <= 0.0:
				continue
			var col: Color = col_base.lerp(col_tip, u)
			Art.blend(im, x, y, col, cov * col.a)

## An elliptical ring of constant thickness — the shockwave primitive. Squashed
## rings (ry < rx) lie flat on the 2.5D ground plane.
static func _ring(im: Image, cx: float, cy: float, rx: float, ry: float,
		thick: float, col: Color) -> void:
	var x0 := maxi(0, int(floor(cx - rx)) - 2)
	var y0 := maxi(0, int(floor(cy - ry)) - 2)
	var x1 := mini(im.get_width() - 1, int(ceil(cx + rx)) + 2)
	var y1 := mini(im.get_height() - 1, int(ceil(cy + ry)) + 2)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx: float = (x + 0.5 - cx) / maxf(rx, 0.001)
			var dy: float = (y + 0.5 - cy) / maxf(ry, 0.001)
			var q: float = sqrt(dx * dx + dy * dy)
			# Convert the normalised radius back to pixels so `thick` is uniform.
			var px: float = (q - 1.0) * minf(rx, ry)
			var cov: float = clampf((thick * 0.5 - absf(px)) + 0.75, 0.0, 1.0)
			if cov <= 0.0:
				continue
			Art.blend(im, x, y, col, cov * col.a)
