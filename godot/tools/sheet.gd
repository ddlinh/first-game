extends Control
## QA tool: lays every baked texture out on a contact sheet and saves it to
## res://_shot_sheet.png so the whole catalogue can be judged at a glance.
##   godot --path . res://tools/sheet.tscn
##
## Renders into an off-screen SubViewport rather than the game window, so the
## board can be taller than the monitor.

# Sections are drawn in this order. Anything baked but not listed here lands in
# a trailing "misc" row, so a new texture can never silently go unreviewed.
const SECTIONS := [
	{"title": "CAST", "keys": [
		"player", "survivor_farmer", "survivor_smith", "survivor_builder",
		"enemy_husk", "enemy_brute",
	]},
	{"title": "BUILDINGS & CROPS", "keys": [
		"building_cabin", "building_forge", "building_crop_bed", "building_scaffold",
		"crop_0", "crop_1", "crop_2", "crop_3",
	]},
	{"title": "PROPS", "keys": [
		"portal", "cage", "supply_gate", "bonfire", "brazier", "rubble", "banner",
		"material_wood", "material_stone", "material_iron", "material_food",
	]},
	{"title": "GROUND & WALLS", "keys": [
		"tile_grass", "tile_grass_1", "tile_grass_2", "tile_grass_3",
		"tile_path", "tile_dirt", "tile_floor", "tile_wall",
	]},
	{"title": "EFFECTS", "keys": [
		"slash_light", "slash_heavy", "slash_thrust", "streak",
		"ring", "ring_soft", "impact", "impact_cold",
		"ember", "ash", "dust", "smoke", "spark", "glint", "leaf",
		"chip_wood", "chip_stone", "shadow", "shadow_small", "light_soft", "light_tight",
	]},
]

const COLS := 7
const CELL_W := 168
const CELL_H := 176
const PAD := 20

var _board: Control = null

func _ready() -> void:
	var vp := SubViewport.new()
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	_board = Control.new()
	vp.add_child(_board)

	var height := _build(_board)
	vp.size = Vector2i(COLS * CELL_W + PAD * 2, height)

	_cap(vp)

# Lay out every section; returns the total board height in px.
func _build(root: Control) -> int:
	var bg := ColorRect.new()
	bg.color = Color("1a1620")
	root.add_child(bg)

	var listed := {}
	for sec in SECTIONS:
		for k in sec["keys"]:
			listed[k] = true

	var y := PAD
	for sec in SECTIONS:
		var keys: Array = []
		for k in sec["keys"]:
			if Assets.has(k):
				keys.append(k)
		if keys.is_empty():
			continue
		y = _section(root, String(sec["title"]), keys, y)

	# Anything baked that no section claims.
	var extra: Array = []
	for k in Assets.keys():
		if not listed.has(k):
			extra.append(k)
	extra.sort()
	if not extra.is_empty():
		y = _section(root, "UNSORTED", extra, y)

	bg.size = Vector2(COLS * CELL_W + PAD * 2, y + PAD)
	return y + PAD

func _section(root: Control, title: String, keys: Array, y0: int) -> int:
	var head := Label.new()
	head.text = title
	head.position = Vector2(PAD, y0)
	head.add_theme_font_size_override("font_size", 19)
	head.add_theme_color_override("font_color", Color("c9a227"))
	root.add_child(head)

	var rule := ColorRect.new()
	rule.color = Color("3a3050")
	rule.position = Vector2(PAD, y0 + 26)
	rule.size = Vector2(COLS * CELL_W - PAD, 2)
	root.add_child(rule)

	var y := y0 + 38
	var i := 0
	for k in keys:
		var col: int = i % COLS
		var row: int = i / COLS
		var at := Vector2(PAD + col * CELL_W, y + row * CELL_H)
		_cell(root, String(k), at)
		i += 1
	var rows: int = int(ceil(float(keys.size()) / float(COLS)))
	return y + rows * CELL_H + 14

# One framed swatch: checkerboard, texture centred, key underneath.
func _cell(root: Control, key: String, at: Vector2) -> void:
	var frame := ColorRect.new()
	frame.color = Color("221c2e")
	frame.position = at
	frame.size = Vector2(CELL_W - 12, CELL_H - 34)
	root.add_child(frame)

	# Checkerboard so alpha is visible (the FX section is mostly transparent).
	var sq := 11
	var cw: int = int(frame.size.x)
	var ch: int = int(frame.size.y)
	for cy in range(0, ch, sq):
		for cx in range(0, cw, sq):
			if ((cx / sq) + (cy / sq)) % 2 == 1:
				continue
			var t := ColorRect.new()
			t.color = Color("2a2338")
			t.position = at + Vector2(cx, cy)
			t.size = Vector2(mini(sq, cw - cx), mini(sq, ch - cy))
			root.add_child(t)

	var tr := TextureRect.new()
	tr.texture = Assets.tex(key)
	tr.position = at
	tr.size = frame.size
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.add_child(tr)

	var tex := Assets.tex(key)
	var l := Label.new()
	l.text = "%s  %dx%d" % [key, tex.get_width(), tex.get_height()]
	l.position = at + Vector2(0, frame.size.y + 4)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color("bdb2cc"))
	root.add_child(l)

func _cap(vp: SubViewport) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png("res://_shot_sheet.png")
	print("SHEET SAVED  %dx%d" % [img.get_width(), img.get_height()])
	get_tree().quit()
