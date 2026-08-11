extends Node
## Texture catalogue. Fetch any sprite with Assets.tex("key").
##
## ART LIVES IN FILES. Every texture is a PNG in `res://art/<key>.png`, listed in
## `res://art/_manifest.txt`. At launch the game LOADS those files and nothing
## else — no drawing code runs on the normal path. Repaint a PNG (same name, same
## canvas) and the game shows it next launch; the code never changes. This is the
## whole point: art and code are decoupled.
##
## The code-drawn art is now only a DEFAULT GENERATOR / fallback. If a file (or the
## manifest) is missing, the modules below regenerate the defaults, then write the
## missing files back so the folder self-heals and the next launch is a pure load.
## Regenerate the whole set (e.g. after editing a generator) with
## `res://tools/export_art.tscn`. The generators, by subject:
##   art_env.gd    tiles, wall blocks, platform edges, buildings, crops
##   art_props.gd  portal, gate, cage, braziers, bonfire, scenery, pickups
##   art_cast.gd   the cat hero, the survivors, the husks
##   art_fx.gd     contact shadow, light falloff, particles, slashes, UI icons
##
## Textures are authored at 2x on-screen size (Palette.PX = 0.5) with a linear
## filter, so the art stays smooth when the camera zooms in.
##
## `_bake_legacy()` below is an older flat top-down catalogue; the modules overwrite
## it key by key, so the fallback is never missing a texture.

## Bump when a change to the art should invalidate the cache but the source files
## are unreadable (exported builds ship compiled scripts, not .gd text).
const ART_VERSION := 1

## Where baked PNGs are parked between launches:
##     user://artcache/<project location>/<art fingerprint>/
## Drawing the whole catalogue from scratch costs several seconds, a visible freeze
## on launch; reloading it costs a fraction of that. Editing any art file changes the
## fingerprint, so the cache can never go stale. The project-location level matters
## because user:// is shared by every copy of the project on the machine — without it,
## two checkouts running side by side would keep evicting each other.
const CACHE_ROOT := "user://artcache"

# Source files whose contents decide whether a cache entry is still valid.
const ART_SOURCES: Array[String] = [
	"res://scripts/art.gd", "res://scripts/art_env.gd", "res://scripts/art_props.gd",
	"res://scripts/art_cast.gd", "res://scripts/art_fx.gd", "res://scripts/palette.gd",
	"res://scripts/assets.gd",
]

var _tex: Dictionary = {}

## Folder of art files and the manifest that lists every key the game needs. A
## file named "<key>.png" IS the texture for that key. Edit it, and the game shows
## your art next launch — no code change. Delete it and the fallback regenerates
## the default and re-writes the file. See the README in that folder.
const OVERRIDE_DIR := "res://art"
const MANIFEST_PATH := "res://art/_manifest.txt"

func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	# PRIMARY PATH: render straight from the art files — NO drawing code runs. This
	# is the normal path; the game is purely a renderer of whatever is in res://art.
	if _render_from_art():
		print("Assets: rendered %d textures from %s (no bake) in %d ms"
			% [_tex.size(), OVERRIDE_DIR, Time.get_ticks_msec() - t0])
		return
	# FALLBACK (only if a file or the manifest is missing): generate the defaults
	# from the art modules, let any present files override them, then backfill the
	# missing files + manifest so the NEXT launch renders purely from files. This
	# is also how "delete a PNG to revert to the default" restores that file.
	var home := CACHE_ROOT.path_join(_project_id())
	var dir := home.path_join(_fingerprint())
	if not _load_cache(dir):
		_bake_all()
		_save_cache(home, dir)
	_apply_overrides()
	_export_defaults()
	print("Assets: generated defaults + backfilled %s in %d ms"
		% [OVERRIDE_DIR, Time.get_ticks_msec() - t0])

# Try to render entirely from res://art. Succeeds only when EVERY key the manifest
# lists has a loadable file, so a partial folder never leaves a texture missing.
func _render_from_art() -> bool:
	var req := _read_manifest()
	if req.is_empty():
		return false
	var loaded: Dictionary = {}
	for key in req:
		var tex := _load_art_file(String(key))
		if tex == null:
			push_warning("Assets: art file for '%s' missing — regenerating from code" % key)
			return false
		loaded[String(key)] = tex
	_tex = loaded
	return true

func _read_manifest() -> PackedStringArray:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return PackedStringArray()
	var out := PackedStringArray()
	for line in FileAccess.get_file_as_string(MANIFEST_PATH).split("\n", false):
		var k := line.strip_edges()
		if k != "":
			out.append(k)
	return out

# Load one res://art/<key>.png: editor-imported when available (works in exported
# builds), else read raw from disk (a fresh drop while running from source).
func _load_art_file(key: String) -> Texture2D:
	var path := OVERRIDE_DIR.path_join("%s.png" % key)
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path) as Texture2D
	var im := Image.load_from_file(path)
	if im != null:
		return ImageTexture.create_from_image(im)
	return null

# Fallback only: pull any present art files over the freshly-baked defaults.
func _apply_overrides() -> void:
	var d := DirAccess.open(OVERRIDE_DIR)
	if d == null:
		return
	for f in d.get_files():
		if not f.ends_with(".png"):
			continue
		var tex := _load_art_file(String(f).get_basename())
		if tex != null:
			_tex[String(f).get_basename()] = tex

# Fallback only, and only from source (res:// is read-only in an exported build,
# where the files already ship): freeze _tex to files — pristine copies to
# _templates/ (always), to art/ (only when absent, never clobbering edits), plus
# the manifest — so the next launch is a pure render.
func _export_defaults() -> void:
	DirAccess.make_dir_recursive_absolute(OVERRIDE_DIR.path_join("_templates"))
	var keys := _tex.keys()
	keys.sort()
	var names := PackedStringArray()
	for k in keys:
		names.append(String(k))
		var im: Image = (_tex[k] as Texture2D).get_image()
		if im == null:
			continue
		im.save_png(OVERRIDE_DIR.path_join("_templates/%s.png" % k))
		if not FileAccess.file_exists(OVERRIDE_DIR.path_join("%s.png" % k)):
			im.save_png(OVERRIDE_DIR.path_join("%s.png" % k))
	var mf := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if mf != null:
		mf.store_string("\n".join(names))

# ---------------------------------------------------------------------------
# Bake cache
# ---------------------------------------------------------------------------

# Which copy of the project this is, so sibling checkouts keep separate caches.
func _project_id() -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(ProjectSettings.globalize_path("res://").to_utf8_buffer())
	return ctx.finish().hex_encode().substr(0, 8)

# MD5 over every art source, so any edit to the drawing code produces a new
# cache directory and the old one is discarded.
func _fingerprint() -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(str(ART_VERSION).to_utf8_buffer())
	for path in ART_SOURCES:
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.is_empty():
			# Exported build: the .gd text is gone. Fall back to ART_VERSION alone.
			return "v%d" % ART_VERSION
		ctx.update(bytes)
	return ctx.finish().hex_encode().substr(0, 16)

func _load_cache(dir: String) -> bool:
	var d := DirAccess.open(dir)
	if d == null:
		return false
	var loaded := 0
	for f in d.get_files():
		if not f.ends_with(".png"):
			continue
		var im := Image.load_from_file(dir.path_join(f))
		if im == null:
			return false   # a truncated cache: fall through and re-bake
		_tex[f.get_basename()] = ImageTexture.create_from_image(im)
		loaded += 1
	return loaded > 0

func _save_cache(home: String, dir: String) -> void:
	# Drop this project's cache directories from previous art revisions. Scoped to
	# `home` so a sibling checkout's cache is never touched.
	DirAccess.make_dir_recursive_absolute(home)
	var root := DirAccess.open(home)
	if root != null:
		for sub in root.get_directories():
			if home.path_join(sub) != dir:
				OS.move_to_trash(ProjectSettings.globalize_path(home.path_join(sub)))
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		return
	for key in _tex:
		var tex: ImageTexture = _tex[key]
		var im := tex.get_image()
		if im != null:
			im.save_png(dir.path_join("%s.png" % key))

## Register a baked image under `key`, replacing anything already there.
## The art modules call this for every texture they draw.
func put(key: String, im: Image) -> void:
	Art.flush()   # the bakers draw into a cached byte buffer; commit it first
	_tex[key] = ImageTexture.create_from_image(im)

func tex(key: String) -> Texture2D:
	if not _tex.has(key):
		push_warning("Assets.tex: unknown key '%s'" % key)
		return _tex.get("player", null)
	return _tex[key]

func has(key: String) -> bool:
	return _tex.has(key)

# ===========================================================================
# SDF vector engine
# ===========================================================================
func _img(w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

func _finish(img: Image, key: String) -> void:
	_tex[key] = ImageTexture.create_from_image(img)

# --- Signed distance for each primitive (negative = inside), in pixel space ---
func _sd(prim: Dictionary, p: Vector2) -> float:
	match String(prim["t"]):
		"circle":
			return (p - prim["c"]).length() - float(prim["r"])
		"ellipse":
			var q: Vector2 = p - prim["c"]
			var rx: float = prim["rx"]
			var ry: float = prim["ry"]
			var k1: float = Vector2(q.x / rx, q.y / ry).length()
			if k1 < 0.0001:
				return -minf(rx, ry)
			var k2: float = Vector2(q.x / (rx * rx), q.y / (ry * ry)).length()
			return k1 * (k1 - 1.0) / k2
		"rrect":
			var d: Vector2 = (p - prim["c"]).abs() - Vector2(prim["hw"], prim["hh"]) + Vector2(prim["r"], prim["r"])
			var od: float = Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length()
			return od + minf(maxf(d.x, d.y), 0.0) - float(prim["r"])
		"seg":
			var a: Vector2 = prim["a"]
			var b: Vector2 = prim["b"]
			var pa: Vector2 = p - a
			var ba: Vector2 = b - a
			var h: float = clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
			return (pa - ba * h).length() - float(prim["r"])
		"tri":
			return _sd_tri(p, prim["a"], prim["b"], prim["c"])
	return 1e9

func _sd_tri(p: Vector2, p0: Vector2, p1: Vector2, p2: Vector2) -> float:
	var e0 := p1 - p0
	var e1 := p2 - p1
	var e2 := p0 - p2
	var v0 := p - p0
	var v1 := p - p1
	var v2 := p - p2
	var pq0 := v0 - e0 * clampf(v0.dot(e0) / e0.dot(e0), 0.0, 1.0)
	var pq1 := v1 - e1 * clampf(v1.dot(e1) / e1.dot(e1), 0.0, 1.0)
	var pq2 := v2 - e2 * clampf(v2.dot(e2) / e2.dot(e2), 0.0, 1.0)
	var s := signf(e0.x * e2.y - e0.y * e2.x)
	var dx := minf(minf(pq0.dot(pq0), pq1.dot(pq1)), pq2.dot(pq2))
	var dy := minf(minf(s * (v0.x * e0.y - v0.y * e0.x), s * (v1.x * e1.y - v1.y * e1.x)), s * (v2.x * e2.y - v2.y * e2.x))
	return -sqrt(dx) * signf(dy)

func _sd_union(prims: Array, p: Vector2) -> float:
	var d := 1e9
	for prim in prims:
		d = minf(d, _sd(prim, p))
	return d

# Alpha-composite `src` (premultiplied by coverage `a`) over the pixel at x,y.
func _blend(img: Image, x: int, y: int, src: Color, a: float) -> void:
	if a <= 0.0:
		return
	a = clampf(a, 0.0, 1.0)
	var dst := img.get_pixel(x, y)
	var oa := a + dst.a * (1.0 - a)
	if oa <= 0.0001:
		return
	var r := (src.r * a + dst.r * dst.a * (1.0 - a)) / oa
	var g := (src.g * a + dst.g * dst.a * (1.0 - a)) / oa
	var b := (src.b * a + dst.b * dst.a * (1.0 - a)) / oa
	img.set_pixel(x, y, Color(r, g, b, oa))

# Paint one outlined blob (union of `prims`): dark outline ring of width `ow`
# around the silhouette, `fill` inside with a soft top-light / bottom-shade.
# `clip` (optional) keeps the paint inside another blob (for belly patches etc).
func _paint(img: Image, prims: Array, fill: Color, outline: Color, ow: float,
		grad: float = 0.16, clip: Array = []) -> void:
	var top := 1e9
	var bot := -1e9
	for prim in prims:
		var bb := _prim_bbox(prim, ow + 2.0)
		top = minf(top, bb.position.y)
		bot = maxf(bot, bb.end.y)
	var span: float = maxf(bot - top, 1.0)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var p := Vector2(x + 0.5, y + 0.5)
			var d := _sd_union(prims, p)
			if d > ow + 1.0:
				continue
			var a_out := clampf(ow - d + 0.75, 0.0, 1.0)
			if a_out <= 0.0:
				continue
			if not clip.is_empty():
				var dc := _sd_union(clip, p)
				a_out *= clampf(-dc + 0.75, 0.0, 1.0)
				if a_out <= 0.0:
					continue
			var a_fill := clampf(-d + 0.75, 0.0, 1.0)
			var ty := clampf((y - top) / span, 0.0, 1.0)
			var fcol := fill.darkened(grad * ty)
			if ty < 0.4:
				fcol = fcol.lightened(0.08 * (0.4 - ty) / 0.4)
			var col := outline.lerp(fcol, a_fill)
			_blend(img, x, y, col, a_out)

func _prim_bbox(prim: Dictionary, m: float) -> Rect2:
	match String(prim["t"]):
		"circle":
			var c: Vector2 = prim["c"]
			var r: float = float(prim["r"]) + m
			return Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
		"ellipse":
			var c2: Vector2 = prim["c"]
			var e := Vector2(prim["rx"], prim["ry"]) + Vector2(m, m)
			return Rect2(c2 - e, e * 2.0)
		"rrect":
			var c3: Vector2 = prim["c"]
			var e2 := Vector2(prim["hw"], prim["hh"]) + Vector2(m, m)
			return Rect2(c3 - e2, e2 * 2.0)
		"seg":
			var a: Vector2 = prim["a"]
			var b: Vector2 = prim["b"]
			var r2: float = float(prim["r"]) + m
			var mn := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(r2, r2)
			var mx := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(r2, r2)
			return Rect2(mn, mx - mn)
		"tri":
			var pa: Vector2 = prim["a"]
			var pb: Vector2 = prim["b"]
			var pc: Vector2 = prim["c"]
			var mn2 := Vector2(minf(pa.x, minf(pb.x, pc.x)), minf(pa.y, minf(pb.y, pc.y))) - Vector2(m, m)
			var mx2 := Vector2(maxf(pa.x, maxf(pb.x, pc.x)), maxf(pa.y, maxf(pb.y, pc.y))) + Vector2(m, m)
			return Rect2(mn2, mx2 - mn2)
	return Rect2(0, 0, 0, 0)

# --- Primitive constructors (keep call sites terse) ---
func _c(cx: float, cy: float, r: float) -> Dictionary:
	return {"t": "circle", "c": Vector2(cx, cy), "r": r}
func _e(cx: float, cy: float, rx: float, ry: float) -> Dictionary:
	return {"t": "ellipse", "c": Vector2(cx, cy), "rx": rx, "ry": ry}
func _rr(cx: float, cy: float, hw: float, hh: float, r: float) -> Dictionary:
	return {"t": "rrect", "c": Vector2(cx, cy), "hw": hw, "hh": hh, "r": r}
func _s(ax: float, ay: float, bx: float, by: float, r: float) -> Dictionary:
	return {"t": "seg", "a": Vector2(ax, ay), "b": Vector2(bx, by), "r": r}
func _t(ax: float, ay: float, bx: float, by: float, cx: float, cy: float) -> Dictionary:
	return {"t": "tri", "a": Vector2(ax, ay), "b": Vector2(bx, by), "c": Vector2(cx, cy)}

# Convenience: a single filled ellipse dot (no vertical shading), e.g. eyes.
func _dot(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color, ow: float = 0.0, oc: Color = Palette.OUTLINE) -> void:
	_paint(img, [_e(cx, cy, rx, ry)], col, oc, maxf(ow, 0.001), 0.0)

# ===========================================================================
# Bake catalogue
# ===========================================================================
func _bake_all() -> void:
	_timed("legacy", func(): _bake_legacy())
	_timed("env", func(): ArtEnv.bake(self))
	_timed("props", func(): ArtProps.bake(self))
	_timed("cast", func(): ArtCast.bake(self))
	_timed("fx", func(): ArtFx.bake(self))

# Bake budget matters: this runs before the first frame, so a slow module shows up
# as a hang on launch. Keep the total well under two seconds.
func _timed(what: String, fn: Callable) -> void:
	var t := Time.get_ticks_msec()
	fn.call()
	print("  bake %-7s %5d ms" % [what, Time.get_ticks_msec() - t])

# ===========================================================================
# LEGACY flat top-down catalogue (superseded module by module; then deleted)
# ===========================================================================
func _bake_legacy() -> void:
	_bake_cat()
	_bake_survivors()
	_bake_enemies()
	_bake_buildings()
	_bake_crops()
	_bake_tiles()
	_bake_props()
	_bake_materials()
	_bake_fx()

# --- Hero: a ginger cat with an ember scarf -------------------------------
func _bake_cat() -> void:
	var W := 120
	var img := _img(W, 128)
	var cx := 60.0
	var ow := 5.0
	# Body silhouette (head + torso + ears + limbs + tail), one union → one outline.
	var body := [
		_e(cx, 92, 30, 27),                 # torso
		_c(cx, 50, 33),                     # head
		_t(32, 30, 47, 6, 54, 34),          # left ear
		_t(88, 30, 73, 6, 66, 34),          # right ear
		_e(38, 96, 12, 14), _e(82, 96, 12, 14),   # arms
		_e(46, 116, 12, 10), _e(74, 116, 12, 10), # feet
		_s(86, 92, 108, 78, 8),             # tail
	]
	_paint(img, body, Palette.CAT, Palette.OUTLINE, ow)
	# Cream belly + muzzle (clipped inside body).
	_paint(img, [_e(cx, 96, 17, 19)], Palette.CAT_BELLY, Palette.OUTLINE, 0.001, 0.06, body)
	_paint(img, [_e(cx, 56, 16, 12)], Palette.CAT_BELLY, Palette.OUTLINE, 0.001, 0.0, body)
	# Inner ears.
	_paint(img, [_t(37, 30, 46, 14, 51, 32)], Palette.CAT_EAR, Palette.OUTLINE, 0.001, 0.0)
	_paint(img, [_t(83, 30, 74, 14, 69, 32)], Palette.CAT_EAR, Palette.OUTLINE, 0.001, 0.0)
	# Tabby stripes on the head.
	_paint(img, [_s(cx, 24, cx, 34, 2.4)], Palette.CAT_D, Palette.CAT_D, 0.001, 0.0)
	_paint(img, [_s(48, 26, 44, 35, 2.0)], Palette.CAT_D, Palette.CAT_D, 0.001, 0.0)
	_paint(img, [_s(72, 26, 76, 35, 2.0)], Palette.CAT_D, Palette.CAT_D, 0.001, 0.0)
	# Eyes (big dark ovals + glint) and pink nose.
	_dot(img, 50, 50, 6.5, 9.0, Palette.OUTLINE)
	_dot(img, 70, 50, 6.5, 9.0, Palette.OUTLINE)
	_dot(img, 52, 47, 2.2, 2.6, Palette.WHITE)
	_dot(img, 72, 47, 2.2, 2.6, Palette.WHITE)
	_paint(img, [_t(56, 58, 64, 58, 60, 63)], Palette.CAT_EAR, Palette.OUTLINE, 0.001, 0.0)
	# Ember scarf across the neck with a hanging tail.
	_paint(img, [_rr(cx, 72, 22, 5, 4), _rr(74, 82, 5, 10, 3)], Palette.EMBER, Palette.OUTLINE, 3.0, 0.1)
	_finish(img, "player")

# --- Animal survivors -----------------------------------------------------
func _bake_survivors() -> void:
	# Farmer: a woolly lamb with a straw hat.
	var lamb := _img(120, 128)
	var lx := 60.0
	var wool := [
		_e(lx, 94, 30, 26),
		_c(lx, 52, 30),
		_c(38, 46, 12), _c(82, 46, 12), _c(46, 30, 13), _c(74, 30, 13), _c(60, 26, 13),
		_c(40, 66, 12), _c(80, 66, 12),
		_e(40, 112, 10, 12), _e(80, 112, 10, 12),
	]
	_paint(lamb, wool, Palette.CREAM, Palette.OUTLINE, 5.0, 0.1)
	_paint(lamb, [_e(lx, 58, 16, 15)], Palette.BONE, Palette.OUTLINE, 3.0, 0.06)   # face
	_paint(lamb, [_e(38, 60, 7, 11), _e(82, 60, 7, 11)], Palette.BONE, Palette.OUTLINE, 3.0, 0.05)  # ears
	_dot(lamb, 53, 58, 3.4, 4.2, Palette.OUTLINE)
	_dot(lamb, 67, 58, 3.4, 4.2, Palette.OUTLINE)
	_paint(lamb, [_e(lx, 40, 26, 7)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.12)     # hat brim
	_paint(lamb, [_e(lx, 32, 15, 10)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.14)    # hat crown
	_finish(lamb, "survivor_farmer")

	# Smith: a badger with a face stripe and a leather apron.
	var badg := _img(120, 128)
	var bx := 60.0
	var bbody := [
		_e(bx, 94, 30, 26), _c(bx, 52, 30),
		_c(40, 32, 10), _c(80, 32, 10),                 # round ears
		_e(40, 100, 11, 13), _e(80, 100, 11, 13),
		_e(44, 114, 10, 9), _e(76, 114, 10, 9),
	]
	_paint(badg, bbody, Palette.STONE2_D, Palette.OUTLINE, 5.0, 0.14)
	_paint(badg, [_rr(bx, 50, 8, 20, 6)], Palette.CREAM, Palette.OUTLINE, 2.5, 0.05)  # white face stripe
	_dot(badg, 51, 52, 3.2, 3.8, Palette.OUTLINE)
	_dot(badg, 69, 52, 3.2, 3.8, Palette.OUTLINE)
	_paint(badg, [_rr(bx, 96, 16, 16, 4)], Palette.WOOD2, Palette.OUTLINE, 3.0, 0.12, bbody)  # apron
	_paint(badg, [_s(46, 30, 74, 30, 3.0)], Palette.EMBER, Palette.OUTLINE, 2.0, 0.0)          # headband
	_finish(badg, "survivor_smith")

	# Builder: a frog with a hard hat.
	var frog := _img(120, 128)
	var fx := 60.0
	var fbody := [
		_e(fx, 96, 31, 25), _e(fx, 56, 32, 27),
		_c(44, 34, 13), _c(76, 34, 13),                 # eye bumps
		_e(38, 104, 11, 12), _e(82, 104, 11, 12),
		_e(44, 116, 12, 8), _e(76, 116, 12, 8),
	]
	_paint(frog, fbody, Palette.LEAF, Palette.OUTLINE, 5.0, 0.16)
	_paint(frog, [_e(fx, 92, 15, 12)], Color("cfe3a0"), Palette.OUTLINE, 0.001, 0.05, fbody)   # belly
	_dot(frog, 44, 34, 8, 8, Palette.WHITE, 3.0)
	_dot(frog, 76, 34, 8, 8, Palette.WHITE, 3.0)
	_dot(frog, 44, 35, 3.4, 3.8, Palette.OUTLINE)
	_dot(frog, 76, 35, 3.4, 3.8, Palette.OUTLINE)
	_paint(frog, [_s(46, 62, 74, 62, 3.0)], Palette.OUTLINE, Palette.OUTLINE, 0.001, 0.0)       # wide smile
	_paint(frog, [_e(fx, 26, 24, 8)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.12)                  # hard-hat brim
	_paint(frog, [_e(fx, 20, 14, 9)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.14)                  # hard-hat dome
	_finish(frog, "survivor_builder")

# --- Dungeon husks: shadow critters with horns and red eyes ---------------
func _bake_enemies() -> void:
	_husk(120, 128, 1.0, "enemy_husk")
	_husk(150, 158, 1.28, "enemy_brute")

func _husk(w: int, h: int, k: float, key: String) -> void:
	var img := _img(w, h)
	var cx := w * 0.5
	var body := [
		_e(cx, 92 * k, 30 * k, 27 * k),
		_c(cx, 50 * k, 32 * k),
		_t(30 * k, 34 * k, 40 * k, 2 * k, 52 * k, 30 * k),   # left horn
		_t((w - 30 * k), 34 * k, (w - 40 * k), 2 * k, (w - 52 * k), 30 * k),  # right horn
		_e(36 * k, 96 * k, 11 * k, 13 * k), _e((w - 36 * k), 96 * k, 11 * k, 13 * k),
		_e(46 * k, 116 * k, 11 * k, 9 * k), _e((w - 46 * k), 116 * k, 11 * k, 9 * k),
	]
	_paint(img, body, Palette.SHADOW, Palette.OUTLINE, 5.0 * k, 0.22)
	# Glowing red eyes (soft outer glow + bright core).
	_dot(img, cx - 12 * k, 50 * k, 8 * k, 7 * k, Color(1.0, 0.3, 0.3, 0.5))
	_dot(img, cx + 12 * k, 50 * k, 8 * k, 7 * k, Color(1.0, 0.3, 0.3, 0.5))
	_dot(img, cx - 12 * k, 50 * k, 4.5 * k, 4.5 * k, Palette.EYE_RED)
	_dot(img, cx + 12 * k, 50 * k, 4.5 * k, 4.5 * k, Palette.EYE_RED)
	# Jagged mouth.
	_paint(img, [_t(cx - 10 * k, 62 * k, cx + 10 * k, 62 * k, cx, 70 * k)], Palette.NIGHT, Palette.OUTLINE, 1.5, 0.0)
	_finish(img, key)

# --- Buildings ------------------------------------------------------------
func _bake_buildings() -> void:
	# Cabin: cosy hut, red-brown roof, glowing window, round door.
	var cab := _img(132, 140)
	var cx := 66.0
	_paint(cab, [_rr(cx, 96, 42, 34, 8)], Palette.WOOD2, Palette.OUTLINE, 5.0, 0.18)   # walls
	_paint(cab, [_s(28, 84, 104, 84, 2.0)], Palette.WOOD2_D, Palette.WOOD2_D, 0.001, 0.0)
	_paint(cab, [_s(28, 108, 104, 108, 2.0)], Palette.WOOD2_D, Palette.WOOD2_D, 0.001, 0.0)
	_paint(cab, [_t(14, 66, cx, 18, 118, 66)], Palette.ROOF2, Palette.OUTLINE, 5.0, 0.2)  # roof
	_paint(cab, [_e(cx, 62, 8, 8)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.1)              # gable lantern
	_paint(cab, [_rr(cx, 112, 12, 18, 10)], Palette.OUTLINE2, Palette.OUTLINE, 3.0, 0.0)  # door
	_paint(cab, [_rr(38, 92, 10, 10, 4)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.1)        # window (glow)
	_paint(cab, [_rr(94, 92, 10, 10, 4)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.1)
	_finish(cab, "building_cabin")

	# Forge: stone hearth, glowing furnace mouth, chimney with embers.
	var fg := _img(132, 140)
	var gx := 66.0
	_paint(fg, [_rr(gx, 98, 42, 32, 8)], Palette.STONE2, Palette.OUTLINE, 5.0, 0.18)
	_paint(fg, [_rr(96, 58, 10, 26, 4)], Palette.STONE2_D, Palette.OUTLINE, 4.0, 0.12)   # chimney
	_paint(fg, [_e(gx, 104, 20, 18)], Palette.NIGHT, Palette.OUTLINE, 3.5, 0.0)          # furnace mouth
	_paint(fg, [_e(gx, 108, 13, 11)], Palette.EMBER, Palette.OUTLINE, 0.001, 0.1)        # fire
	_paint(fg, [_e(gx, 110, 7, 6)], Palette.GOLD, Palette.GOLD, 0.001, 0.0)              # fire core
	# stone speckle
	for sp in [_e(40, 90, 3, 3), _e(52, 110, 3, 3), _e(90, 96, 3, 3), _e(84, 118, 3, 3)]:
		_paint(fg, [sp], Palette.STONE2_D, Palette.STONE2_D, 0.001, 0.0)
	_finish(fg, "building_forge")

	# Crop bed: framed soil plot.
	var cb := _img(120, 96)
	_paint(cb, [_rr(60, 60, 44, 24, 6)], Palette.WOOD2, Palette.OUTLINE, 5.0, 0.16)
	_paint(cb, [_rr(60, 60, 36, 16, 4)], Palette.DIRT, Palette.OUTLINE2, 2.0, 0.12)
	_paint(cb, [_s(30, 60, 90, 60, 2.0)], Palette.DIRT_D, Palette.DIRT_D, 0.001, 0.0)
	_finish(cb, "building_crop_bed")

	# Scaffold: skeletal blueprint frame.
	var sc := _img(132, 140)
	var posts := [
		_rr(30, 92, 5, 44, 3), _rr(102, 92, 5, 44, 3),
		_rr(66, 52, 42, 5, 3), _rr(66, 96, 40, 4, 3),
	]
	_paint(sc, posts, Palette.WOOD2, Palette.OUTLINE, 4.0, 0.12)
	_paint(sc, [_s(34, 128, 100, 60, 4.0)], Palette.WOOD2_D, Palette.OUTLINE, 3.0, 0.0)   # brace
	_finish(sc, "building_scaffold")

# --- Crops (bottom-anchored growth stages) --------------------------------
func _bake_crops() -> void:
	var c0 := _img(96, 110)
	_paint(c0, [_e(48, 88, 14, 7)], Palette.DIRT, Palette.OUTLINE2, 2.0, 0.1)
	_paint(c0, [_c(48, 80, 4)], Palette.LEAF, Palette.OUTLINE, 1.5, 0.0)
	_finish(c0, "crop_0")

	var c1 := _img(96, 110)
	_paint(c1, [_s(48, 88, 48, 62, 4.0)], Palette.MOSS, Palette.OUTLINE, 2.0, 0.0)
	_paint(c1, [_e(38, 66, 9, 6), _e(58, 66, 9, 6)], Palette.LEAF, Palette.OUTLINE, 2.0, 0.06)
	_finish(c1, "crop_1")

	var c2 := _img(96, 110)
	_paint(c2, [_s(48, 90, 48, 46, 4.5)], Palette.MOSS, Palette.OUTLINE, 2.0, 0.0)
	_paint(c2, [_e(34, 62, 11, 8), _e(62, 62, 11, 8), _e(48, 48, 12, 9)], Palette.LEAF, Palette.OUTLINE, 2.5, 0.08)
	_finish(c2, "crop_2")

	var c3 := _img(96, 110)
	_paint(c3, [_s(48, 92, 48, 44, 4.5)], Palette.MOSS, Palette.OUTLINE, 2.0, 0.0)
	_paint(c3, [_e(34, 60, 10, 7), _e(62, 60, 10, 7)], Palette.LEAF, Palette.OUTLINE, 2.5, 0.08)
	_paint(c3, [_e(48, 40, 18, 14)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.12)   # ripe fruit/grain
	_paint(c3, [_e(48, 38, 6, 5)], Palette.AMBER, Palette.AMBER, 0.001, 0.0)
	_finish(c3, "crop_3")

# --- Tiles (fully opaque, seamless-ish 96x96) -----------------------------
func _bake_tiles() -> void:
	var gr := _img(96, 96)
	gr.fill(Palette.GRASS2)
	_scatter_ellipses(gr, Palette.GRASS2_D, 8, 10, 22, 6, 12, 11)
	_grass_tufts(gr, Palette.MOSS, 18, 30)
	_grass_tufts(gr, Palette.LEAF, 10, 71)
	_finish(gr, "tile_grass")

	var dt := _img(96, 96)
	dt.fill(Palette.DIRT)
	_scatter_ellipses(dt, Palette.DIRT_D, 10, 8, 20, 5, 10, 13)
	_scatter_ellipses(dt, Palette.WOOD2_D, 6, 3, 5, 3, 5, 29)
	_finish(dt, "tile_dirt")

	var fl := _img(96, 96)
	fl.fill(Palette.COLD_FLOOR)
	_scatter_ellipses(fl, Palette.COLD_FLOOR2, 9, 9, 20, 6, 11, 17)
	_scatter_ellipses(fl, Palette.STEEL, 4, 3, 5, 3, 4, 41)
	# faint grout cross
	_paint(fl, [_s(0, 48, 96, 48, 1.0)], Palette.COLD_FLOOR2, Palette.COLD_FLOOR2, 0.001, 0.0)
	_paint(fl, [_s(48, 0, 48, 96, 1.0)], Palette.COLD_FLOOR2, Palette.COLD_FLOOR2, 0.001, 0.0)
	_finish(fl, "tile_floor")

	var wl := _img(96, 96)
	wl.fill(Palette.COLD_WALL)
	wl.fill_rect(Rect2i(0, 0, 96, 12), Palette.STEEL)   # lit top lip
	wl.fill_rect(Rect2i(0, 12, 96, 4), Palette.INDIGO)
	_scatter_ellipses(wl, Palette.INDIGO, 8, 8, 18, 5, 9, 23)
	_finish(wl, "tile_wall")

# Deterministic scatter of soft filled ellipses across a tile.
func _scatter_ellipses(img: Image, col: Color, n: int, rmin: int, rmax: int, ry_min: int, ry_max: int, seed: int) -> void:
	var v := seed
	for i in range(n):
		v = (v * 1103515245 + 12345) & 0x7fffffff
		var x := float(v % 96)
		v = (v * 1103515245 + 12345) & 0x7fffffff
		var y := float(v % 96)
		v = (v * 1103515245 + 12345) & 0x7fffffff
		var rx := float(rmin + v % maxi(1, rmax - rmin))
		v = (v * 1103515245 + 12345) & 0x7fffffff
		var ryy := float(ry_min + v % maxi(1, ry_max - ry_min))
		_paint(img, [_e(x, y, rx, ryy)], col, col, 0.001, 0.0)

# Little upright grass blades.
func _grass_tufts(img: Image, col: Color, n: int, seed: int) -> void:
	var v := seed
	for i in range(n):
		v = (v * 1103515245 + 12345) & 0x7fffffff
		var x := float(6 + v % 84)
		v = (v * 1103515245 + 12345) & 0x7fffffff
		var y := float(10 + v % 80)
		_paint(img, [_s(x, y, x - 2, y - 8, 1.4)], col, col, 0.001, 0.0)
		_paint(img, [_s(x + 2, y, x + 4, y - 7, 1.4)], col, col, 0.001, 0.0)

# --- Props ----------------------------------------------------------------
func _bake_props() -> void:
	# Return portal: stone arch framing a teal rift.
	var pt := _img(120, 150)
	_paint(pt, [_rr(20, 92, 9, 46, 5), _rr(100, 92, 9, 46, 5), _rr(60, 46, 46, 9, 6)], Palette.STONE2, Palette.OUTLINE, 5.0, 0.16)
	_paint(pt, [_e(60, 96, 26, 40)], Palette.TEAL, Palette.OUTLINE, 4.0, 0.0)
	_paint(pt, [_e(60, 96, 15, 26)], Color("7ff0e6"), Color("7ff0e6"), 0.001, 0.0)
	_paint(pt, [_e(60, 90, 6, 12)], Palette.WHITE, Palette.WHITE, 0.001, 0.0)
	_finish(pt, "portal")

	# Cage: steel bars (gaps left transparent so the captive shows through).
	var cg := _img(116, 124)
	var bars := []
	for i in range(5):
		var bxp := 20.0 + i * 19.0
		bars.append(_rr(bxp, 66, 4, 44, 2))
	bars.append(_rr(58, 24, 44, 5, 3))
	bars.append(_rr(58, 108, 44, 5, 3))
	_paint(cg, bars, Palette.STONE2, Palette.OUTLINE, 3.0, 0.1)
	_paint(cg, [_e(58, 66, 6, 6)], Palette.GOLD, Palette.OUTLINE, 2.0, 0.0)   # lock
	_finish(cg, "cage")

	# Supply gate: timber arch with an ember banner + lantern (run start).
	var sg := _img(150, 150)
	_paint(sg, [_rr(26, 92, 10, 50, 5), _rr(124, 92, 10, 50, 5), _rr(75, 42, 58, 11, 6)], Palette.WOOD2, Palette.OUTLINE, 5.0, 0.18)
	_paint(sg, [_rr(75, 78, 26, 30, 4)], Palette.RED, Palette.OUTLINE, 4.0, 0.14)      # banner
	_paint(sg, [_t(60, 96, 90, 96, 75, 108)], Palette.RED, Palette.OUTLINE, 3.0, 0.0)  # banner point
	_paint(sg, [_e(75, 76, 8, 10)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.1)           # ember mark
	_paint(sg, [_c(40, 60, 7)], Palette.GOLD, Palette.OUTLINE, 2.5, 0.0)               # lantern
	_finish(sg, "supply_gate")

# --- Material pickups (small) ---------------------------------------------
func _bake_materials() -> void:
	var wood := _img(52, 52)
	_paint(wood, [_rr(26, 30, 18, 8, 5)], Palette.WOOD2, Palette.OUTLINE, 3.0, 0.14)
	_paint(wood, [_e(16, 30, 4, 6)], Palette.WOOD2_D, Palette.OUTLINE, 2.0, 0.0)
	_finish(wood, "material_wood")

	var stone := _img(52, 52)
	_paint(stone, [_e(26, 32, 16, 11)], Palette.STONE2, Palette.OUTLINE, 3.0, 0.16)
	_paint(stone, [_e(21, 27, 4, 3)], Palette.WHITE, Palette.WHITE, 0.001, 0.0)
	_finish(stone, "material_stone")

	var iron := _img(52, 52)
	_paint(iron, [_e(26, 32, 16, 11)], Palette.IRON, Palette.OUTLINE, 3.0, 0.16)
	_paint(iron, [_e(21, 27, 4, 3)], Palette.WHITE, Palette.WHITE, 0.001, 0.0)
	_finish(iron, "material_iron")

	var food := _img(52, 52)
	_paint(food, [_e(26, 30, 16, 12)], Palette.GOLD, Palette.OUTLINE, 3.0, 0.14)
	_paint(food, [_s(18, 26, 34, 26, 1.6)], Palette.AMBER, Palette.AMBER, 0.001, 0.0)
	_finish(food, "material_food")

# --- FX -------------------------------------------------------------------
func _bake_fx() -> void:
	# Soft ember glow mote for particles.
	var e := _img(28, 28)
	_dot(e, 14, 14, 11, 11, Color(1.0, 0.55, 0.2, 0.28))
	_dot(e, 14, 14, 6, 6, Palette.EMBER)
	_dot(e, 14, 13, 3, 3, Palette.GOLD)
	_finish(e, "ember")

	# Melee slash crescent (right-facing; rotated in-world toward the cursor).
	var s := _img(96, 96)
	for y in range(96):
		for x in range(96):
			var dx := x - 24.0
			var dy := y - 48.0
			var d := sqrt(dx * dx + dy * dy)
			if dx >= 0.0 and d >= 30.0 and d <= 45.0:
				var a := clampf(minf(d - 30.0, 45.0 - d) / 6.0, 0.0, 1.0)
				var col := Palette.WHITE if d < 39.0 else Palette.AMBER
				_blend(s, x, y, col, a * 0.9)
	_finish(s, "slash")
