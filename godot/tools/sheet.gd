extends Control
## Temporary QA tool: lays out every baked texture on a dark board and screenshots
## it to res://_shot_sheet.png so the art can be reviewed at a glance.

const KEYS := [
	"player", "survivor_farmer", "survivor_smith", "survivor_builder",
	"enemy_husk", "enemy_brute",
	"building_cabin", "building_forge", "building_crop_bed", "building_scaffold",
	"crop_0", "crop_1", "crop_2", "crop_3",
	"tile_grass", "tile_grass2", "tile_grass_worn", "tile_dirt", "tile_path",
	"tile_floor", "tile_floor2", "tile_floor_crack", "tile_wall", "wall_block",
	"edge_front", "edge_side", "edge_right", "edge_back",
	"portal", "supply_gate", "cage", "arch", "brazier", "bonfire",
	"dead_tree", "stump", "rock_s", "rock_l", "fence", "barrel", "banner",
	"bones", "rubble",
	"material_wood", "material_stone", "material_iron", "material_food",
	"shadow", "light_soft", "ember", "spark", "dust", "slash", "glow_ring", "impact",
	"ui_medallion", "ui_key", "ui_flame", "ui_diamond", "ui_corner", "ui_ember_seal",
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1a1622")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var grid := GridContainer.new()
	grid.columns = 10
	grid.position = Vector2(18, 16)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)

	for k in KEYS:
		var vb := VBoxContainer.new()
		vb.custom_minimum_size = Vector2(126, 0)
		var tr := TextureRect.new()
		tr.texture = Assets.tex(k)
		tr.custom_minimum_size = Vector2(118, 118)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb.add_child(tr)
		var l := Label.new()
		l.text = k
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", Color(1, 1, 1))
		vb.add_child(l)
		grid.add_child(vb)

	_cap()

func _cap() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://_shot_sheet.png")
	print("SHEET SAVED")
	get_tree().quit()
