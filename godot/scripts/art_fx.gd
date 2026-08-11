class_name ArtFx
extends RefCounted
## Engine and interface textures: the contact shadow, the point-light falloff,
## the particle set, the slash arc, and the ornate HUD iconography.
##
## Two very different jobs live here. The first two textures are *load-bearing
## engine data* — `shadow` is stamped under every standing thing in the game and
## `light_soft` is the falloff curve of every PointLight2D — so they are tuned as
## curves, not as pictures, and they look like nothing on a contact sheet. The rest
## are FX and `ui_*` chrome, drawn for a dark gilded panel: gold body, highlight on
## the upper-left of every bevel, shade on the lower-right, thick INK outline.
##
## Baked through the shared `Art` engine and registered with the Assets autoload
## via `a.put(key, image)`.

# ---------------------------------------------------------------------------
# Local helpers
# ---------------------------------------------------------------------------

## A ring as a closed chain of `n` segments on radius `r`, band half-width `w`,
## optionally only the arc a0..a1. `Art` has no boolean subtraction, so this is the
## ONLY way to build an annulus whose centre stays transparent — which is exactly
## what `ui_medallion` needs, since a portrait is drawn behind it.
static func _ring(cx: float, cy: float, r: float, w: float, n: int,
		a0: float = 0.0, a1: float = TAU) -> Array:
	var out: Array = []
	for i in range(n):
		var t0: float = a0 + (a1 - a0) * float(i) / float(n)
		var t1: float = a0 + (a1 - a0) * float(i + 1) / float(n)
		out.append(Art.s(cx + cos(t0) * r, cy + sin(t0) * r,
				cx + cos(t1) * r, cy + sin(t1) * r, w))
	return out

## Translucent flat fill. `Art.paint`/`Art.flat` use a colour's alpha channel for
## nothing — coverage comes from the SDF — so every see-through wash goes through
## `Art.shade` instead, with a 1-px feather that anti-aliases the edge without
## blurring the shape.
static func _wash(im: Image, prims: Array, col: Color, alpha: float,
		feather: float = 1.2) -> void:
	Art.shade(im, prims, col, alpha, [], feather)

## Stamp an opaque band around a circle, one small disc at a time.
##
## A ring passed to `paint`/`flat` as a single union is scanned over its whole
## bounding *disc*, which for a 100-px ring is 70x more pixels than the band
## itself; stamping is the same picture for a fraction of the cost. Only valid at
## full opacity — translucent discs would double-blend where they overlap, which
## is why the outlined rings above still go through one union.
static func _stamp_ring(im: Image, cx: float, cy: float, r: float, w: float,
		col: Color, a0: float = 0.0, a1: float = TAU) -> void:
	# Spacing is derived from the band width, never fixed: a thin filament stamped
	# at a coarse count comes out as a string of beads.
	var n: int = maxi(8, int(ceil(absf(a1 - a0) * r / maxf(w * 0.75, 0.5))))
	for i in range(n + 1):
		var ang: float = a0 + (a1 - a0) * float(i) / float(n)
		Art.flat(im, [Art.c(cx + cos(ang) * r, cy + sin(ang) * r, w)], col)

# ---------------------------------------------------------------------------
static func bake(a: Node) -> void:
	a.put("shadow", _shadow())
	a.put("light_soft", _light_soft())

	a.put("ember", _ember())
	a.put("spark", _spark())
	a.put("dust", _dust())
	a.put("slash", _slash())
	a.put("glow_ring", _glow_ring())
	a.put("impact", _impact())

	a.put("ui_medallion", _ui_medallion())
	a.put("ui_key", _ui_key())
	a.put("ui_flame", _ui_flame())
	a.put("ui_diamond", _ui_diamond())
	a.put("ui_corner", _ui_corner())
	a.put("ui_ember_seal", _ui_ember_seal())

# ===========================================================================
# ENGINE TEXTURES — curves, not pictures
# ===========================================================================

## Contact shadow, 128 x 80, already in the squashed ground aspect. Baked WHITE
## with an alpha falloff; callers tint it through `modulate` (see Iso.shadow).
##
## The falloff is the whole point: `inner` 0.30 keeps a flat dense core directly
## under the feet — that is what says "touching the floor" — and the quadratic-plus
## skirt beyond it dies out over the remaining 70 % of the radius, so there is no
## edge to catch the eye. Harder and it reads as a sticker; softer and it is fog.
static func _shadow() -> Image:
	var im := Art.img(128, 80)
	Art.radial(im, 64, 40, 62, 38, Color(1, 1, 1, 1), 2.6, 0.30)
	return im

## PointLight2D falloff, 256 x 256 (so texture_scale 1.0 == a 128 px radius).
##
## A single radial pass is either a cone or a hot dot in a dead disc, and neither
## carves a *pool* out of the dark — which is the whole job of a brazier. Two
## passes sum into a smoothstep: a wide shallow haze that reaches exactly zero at
## the texture edge (so there is no square cut-off), and inside it a core that
## holds full intensity out to ~27 % of the radius before rolling off. That flat
## plateau is what gives a light a lit floor rather than a bright pinpoint.
static func _light_soft() -> Image:
	var im := Art.img(256, 256)
	Art.radial(im, 128, 128, 128, 128, Color(1, 1, 1, 0.55), 2.0, 0.10)
	Art.radial(im, 128, 128, 96, 96, Color(1, 1, 1, 1.0), 2.0, 0.35)
	return im

# ===========================================================================
# PARTICLES
# ===========================================================================

## A drifting ember: baked bloom, warm body, hot core offset up-left into the key.
static func _ember() -> Image:
	var im := Art.img(32, 32)
	Art.glow(im, 16, 16, 15, Palette.TORCH, 0.40)
	Art.flat(im, [Art.c(16, 16, 6)], Palette.TORCH)
	Art.flat(im, [Art.c(15, 15, 3)], Palette.TORCH_L)
	return im

## A struck spark: a hot head with a needle of a tail behind it. `Art.s` has a
## single radius, so the taper is a necklace of shrinking circles — and the needle
## has to stay under 3 px wide on a 24 px canvas or it reads as a club.
static func _spark() -> Image:
	var im := Art.img(24, 24)
	Art.glow(im, 12, 10, 10, Palette.TORCH, 0.34)
	var streak: Array = []
	for i in range(14):
		var k: float = float(i) / 13.0
		streak.append(Art.c(12.0, 4.0 + k * 17.0, maxf(1.5 - 1.35 * k, 0.35)))
	Art.flat(im, streak, Palette.GOLD_L)
	Art.flat(im, [Art.c(12, 4.6, 1.5)], Color(1, 1, 1, 1))
	return im

## A puff of kicked-up grit: outline-free, squashed to the ground plane, and very
## soft — a big generous feather on every blob, otherwise the puffs read as dirt
## blotches rather than airborne dust. The three lobes bulge up-left, into the key.
static func _dust() -> Image:
	var im := Art.img(40, 40)
	_wash(im, [Art.e(20, 23, 16, 9.5)], Palette.STONE2, 0.44, 9.0)
	_wash(im, [Art.e(16, 18, 11, 7), Art.e(27, 21, 8, 5)],
			Palette.STONE2.lightened(0.28), 0.38, 8.0)
	_wash(im, [Art.e(11, 26, 7, 4.5)], Palette.STONE2.lightened(0.12), 0.22, 7.0)
	return im

# --- slash -----------------------------------------------------------------
# The arc is swept about a centre well off the left edge, so the crescent bows to
# the right and its bbox lands centred in the 128 x 96 frame — rotating the sprite
# about its own centre then aims the swing.
const _SLASH_C := Vector2(18.0, 48.0)
const _SLASH_R := 52.0
const _SLASH_SPAN := 1.0821   # deg_to_rad(62)

## One disc of the swing arc at `u` (0 = trailing tip, 1 = leading tip). The
## reference radius `2 + 12*sin(u*PI)` is fat at mid-swing and needle-thin at both
## tips; `gain` scales it. `lead` = 1 keeps the pass flush with the band's OUTER
## edge, 0 centres it on the locus — deriving that offset from the LOCAL width,
## rather than using a constant, is what keeps a narrow pass inside the body all
## the way out to the tips instead of floating off the end of it.
static func _slash_blob(u: float, gain: float, lead: float) -> Dictionary:
	var ang: float = lerpf(-_SLASH_SPAN, _SLASH_SPAN, u)
	var dir := Vector2(cos(ang), sin(ang))
	var ref: float = 2.0 + 12.0 * sin(u * PI)
	var w: float = maxf(ref * gain, 0.5)
	var p: Vector2 = _SLASH_C + dir * (_SLASH_R + (ref - w) * lead)
	return Art.c(p.x, p.y, w)

static func _slash_arc(gain: float, lead: float, n: int) -> Array:
	var out: Array = []
	for i in range(n):
		out.append(_slash_blob(float(i) / float(n - 1), gain, lead))
	return out

## Stamp one opaque pass disc by disc. The thin passes need a sample every ~1 px
## or the filament comes out as a row of beads, and at that density a single union
## would be scanned over the whole crescent once per sample; stamping is seamless
## here precisely because the discs are opaque.
static func _stamp_arc(im: Image, gain: float, lead: float, n: int, col: Color) -> void:
	for i in range(n):
		Art.flat(im, [_slash_blob(float(i) / float(n - 1), gain, lead)], col)

## The melee arc. Four passes on one locus, the upper three flush with the leading
## (outer) edge, so the value ladder runs hot-white at the edge the blade travelled
## to and bleeds wine away behind it. That asymmetry is the whole difference
## between a crescent and something that reads as *swept*.
static func _slash() -> Image:
	var im := Art.img(128, 96)
	_wash(im, _slash_arc(1.25, 1.0, 22), Palette.WINE, 0.55, 4.0)
	_stamp_arc(im, 1.0, 0.0, 44, Palette.TORCH)
	_stamp_arc(im, 0.38, 0.88, 90, Palette.TORCH_L)
	_stamp_arc(im, 0.15, 0.84, 140, Palette.GOLD_L)
	return im

## Cold arcane ring — the portal pulse and the rescue flourish. A halo behind, a
## solid band, and a brighter filament running down the middle of the band so the
## ring has an edge to catch when it scales up and fades out.
static func _glow_ring() -> Image:
	var im := Art.img(128, 128)
	Art.glow(im, 64, 64, 60, Palette.CYAN, 0.18)
	_stamp_ring(im, 64, 64, 50, 7.0, Palette.CYAN_D)
	_stamp_ring(im, 64, 64, 50, 4.6, Palette.CYAN)
	_stamp_ring(im, 64, 64, 50, 1.6, Palette.CYAN.lightened(0.6))
	return im

## Hit burst: a hot core inside a star of alternating long and short spikes, so it
## breaks up rather than reading as a tidy asterisk.
static func _impact() -> Image:
	var im := Art.img(96, 96)
	Art.glow(im, 48, 48, 44, Palette.TORCH, 0.30)
	_stamp_ring(im, 48, 48, 30, 3.0, Palette.TORCH.darkened(0.40))
	var mid := Vector2(48, 48)
	# One call per spike: eight triangles in a single union would each be tested
	# against every pixel of the star's bounding box.
	for i in range(8):
		var ang: float = float(i) * PI * 0.25
		var reach: float = 40.0 if i % 2 == 0 else 26.0
		var dir := Vector2(cos(ang), sin(ang))
		var side := Vector2(-dir.y, dir.x)
		var tip: Vector2 = mid + dir * reach
		var b: Vector2 = mid + dir * 7.0 + side * 5.5
		var cc: Vector2 = mid + dir * 7.0 - side * 5.5
		Art.flat(im, [Art.t(tip.x, tip.y, b.x, b.y, cc.x, cc.y)], Palette.TORCH)
	Art.flat(im, [Art.c(48, 48, 10)], Palette.GOLD_L)
	Art.flat(im, [Art.c(48, 48, 5)], Palette.WHITE)
	return im

# ===========================================================================
# UI ICONOGRAPHY — gilded, for a near-black panel
# ===========================================================================

## Roster frame, 88 x 88. Built as a necklace so the centre is genuinely
## transparent: the survivor portrait is drawn behind it and shows through.
static func _ui_medallion() -> Image:
	var im := Art.img(88, 88)
	Art.paint(im, _ring(44, 44, 36, 6.0, 20), Palette.UI_EDGE, Palette.INK, 3.0, 0.55)
	# Bevel: glint along the upper-left of the band, shade along the lower-right.
	_stamp_ring(im, 44, 44, 33.5, 1.6, Palette.UI_EDGE_L, PI * 1.05, PI * 1.95)
	_stamp_ring(im, 44, 44, 38.5, 1.4, Palette.UI_EDGE_D, PI * 0.05, PI * 0.95)
	for i in range(4):
		var ang: float = PI * 0.25 + float(i) * PI * 0.5
		Art.dot(im, 44 + cos(ang) * 36, 44 + sin(ang) * 36, 4.5, 4.5,
				Palette.GOLD_L, 2.0, Palette.INK)
	# Crest at 12 o'clock, so a row of medallions has an up direction.
	Art.paint(im, [Art.t(44, 0, 52, 9, 44, 18), Art.t(44, 0, 36, 9, 44, 18)],
			Palette.UI_EDGE, Palette.INK, 2.5, 0.5)
	return im

## Keycap plate, 48 x 48. The gilded frame is simply a thick outline around the
## outer plate; the HUD draws the letter itself so the cap can be relabelled.
static func _ui_key() -> Image:
	var im := Art.img(48, 48)
	Art.paint(im, [Art.rr(24, 25, 19, 18, 7)], Palette.UI_BG, Palette.UI_EDGE, 3.0, 0.0)
	Art.paint(im, [Art.rr(24, 23, 15, 14, 5)], Palette.UI_BG2.lightened(0.20),
			Palette.INK, 2.0, 0.50)
	# Cap bevel. Both marks hug the face's own border, because a bevel line that
	# floats clear of the edge reads as a stripe printed on the key instead.
	_wash(im, [Art.rr(24, 11.4, 11.5, 1.2, 1.1)], Palette.UI_EDGE_L, 0.60, 1.2)
	_wash(im, [Art.rr(24, 34.6, 11.5, 1.8, 1.6)], Palette.INK, 0.60, 1.6)
	return im

## Warmth-gauge flame, 48 x 56. Baked NEUTRAL cream on purpose: the HUD modulates
## this same silhouette from GWI_COLD to GOLD_L, and any baked hue would turn the
## cold end muddy.
static func _ui_flame() -> Image:
	var im := Art.img(48, 56)
	# A bulb with a necklace tapering off the top of it, leaning right as it rises.
	# A triangle sitting on a circle reads as a ghost; a tapered, curved lick reads
	# as fire, and the silhouette is all the HUD has to work with.
	var body: Array = [Art.e(24, 38, 15, 12)]
	for i in range(12):
		var k: float = float(i) / 11.0
		body.append(Art.c(24.0 + sin(k * 1.5) * 3.0, 38.0 - k * 32.0, 12.0 - 10.6 * k))
	Art.paint(im, body, Palette.UI_TEXT.darkened(0.24), Palette.INK, 3.0, 0.28,
			[], 0.75, Palette.WHITE)
	# Inner flame, same construction one size down: body 0.72 luma, core 0.93,
	# hot dot 1.0, so the shape keeps its form through any HUD modulate.
	var core: Array = [Art.e(24, 41, 8, 7)]
	for i in range(9):
		var k2: float = float(i) / 8.0
		core.append(Art.c(24.0 + sin(k2 * 1.5) * 2.0, 41.0 - k2 * 20.0, 7.0 - 6.0 * k2))
	Art.flat(im, core, Palette.UI_TEXT)
	_wash(im, [Art.e(23.5, 40, 4.2, 5.0)], Color(1, 1, 1, 1), 0.95, 2.4)
	return im

## Separator rhombus, 24 x 24, with an explicit lit facet and a shaded one so it
## still reads as a solid gem at the 14 px the resource stack uses.
static func _ui_diamond() -> Image:
	var im := Art.img(24, 24)
	var q: Array = Art.quad(Vector2(12, 1), Vector2(23, 12), Vector2(12, 23), Vector2(1, 12))
	Art.paint(im, q, Palette.UI_EDGE, Palette.INK, 2.5, 0.55)
	Art.flat(im, [Art.t(12, 4, 12, 12, 5, 12)], Palette.UI_EDGE_L)
	Art.flat(im, [Art.t(12, 12, 19, 12, 12, 20)], Palette.UI_EDGE_D)
	return im

## Filigree bracket, 56 x 56, drawn for the TOP-LEFT corner; the HUD rotates it by
## PI/2 into the others. Both curls stay tight against the elbow — at the 28-32 px
## the HUD draws this, a loose curl reads as a stray hook rather than ornament.
static func _ui_corner() -> Image:
	var im := Art.img(56, 56)
	# Both arms are exact mirrors across the 45-degree diagonal, each closing with
	# a quarter curl that turns back into the panel and terminates in a pearl. The
	# symmetry is what makes it read as ornament: the moment the two curls disagree
	# about which way they turn, the piece reads as a hook.
	var arms: Array = [Art.c(9, 9, 6.0), Art.s(9, 9, 32, 9, 3.4), Art.s(9, 9, 9, 32, 3.4)]
	arms.append_array(_ring(32, 17, 8, 2.7, 6, PI * 1.5, TAU))
	arms.append_array(_ring(17, 32, 8, 2.7, 6, PI, PI * 0.5))
	Art.paint(im, arms, Palette.UI_EDGE, Palette.INK, 2.5, 0.5)
	_wash(im, [Art.s(15, 6.6, 31, 6.6, 1.0), Art.s(6.6, 15, 6.6, 31, 1.0)],
			Palette.UI_EDGE_L, 0.7, 1.0)
	Art.dot(im, 40, 17, 3.0, 3.0, Palette.GOLD_L, 1.6, Palette.INK)
	Art.dot(im, 17, 40, 3.0, 3.0, Palette.GOLD_L, 1.6, Palette.INK)
	Art.dot(im, 9, 9, 2.4, 2.4, Palette.GOLD_L, 1.3, Palette.INK)
	return im

## The game's mark, 72 x 72, and the loudest icon in the HUD: an ember held inside
## a studded gold ring on a dark field, with its own baked bloom behind it.
static func _ui_ember_seal() -> Image:
	var im := Art.img(72, 72)
	Art.glow(im, 36, 38, 34, Palette.TORCH, 0.20)
	Art.paint(im, [Art.c(36, 36, 26)], Palette.INK, Palette.UI_EDGE_D, 2.0, 0.0)
	Art.paint(im, _ring(36, 36, 30, 4.5, 20), Palette.UI_EDGE, Palette.INK, 3.0, 0.55)
	_stamp_ring(im, 36, 36, 28.0, 1.3, Palette.UI_EDGE_L, PI * 1.05, PI * 1.95)
	for i in range(6):
		var ang: float = float(i) * PI / 3.0
		Art.dot(im, 36 + cos(ang) * 30, 36 + sin(ang) * 30, 3.2, 3.2,
				Palette.GOLD_L, 1.5, Palette.INK)
	var fl: Array = [Art.e(36, 44, 11, 9)]
	for i in range(10):
		var k: float = float(i) / 9.0
		fl.append(Art.c(36.0 + sin(k * 1.5) * 2.4, 44.0 - k * 24.0, 9.0 - 7.8 * k))
	Art.paint(im, fl, Palette.TORCH, Palette.INK, 2.5, 0.25, [], 0.8, Palette.GOLD_L)
	var fcore: Array = [Art.e(36, 46, 5.5, 4.6)]
	for i in range(7):
		var k2: float = float(i) / 6.0
		fcore.append(Art.c(36.0 + sin(k2 * 1.5) * 1.5, 46.0 - k2 * 14.0, 4.6 - 3.9 * k2))
	Art.flat(im, fcore, Palette.TORCH_L)
	_wash(im, [Art.e(35.6, 45, 3.0, 3.4)], Palette.GOLD_L, 0.95, 2.0)
	return im
