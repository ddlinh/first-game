extends Node
## A DIRECTED trailer (not the autoplay montage): deliberately paced, and built to
## emphasise the game's thesis — civilisation lives in PEOPLE and KNOWLEDGE. It
## dwells on a rescue and holds on the Codex of real, science-vetted inventions with
## narration on why each changed the world. Runs at 1× for a measured feel.
##
## Record with Godot Movie Maker (30 fps, ~42 s):
##   godot --path godot res://tools/trailer_director.tscn \
##       --write-movie <out.avi> --fixed-fps 30 --quit-after 1260
##
## Not shipped.

var main: Node
var f: int = 0
var _cap: Control = null            # lower-third caption
var _cap_label: Label = null
var _cap_tw: Tween = null
var _card: Control = null           # full-screen title / end card
var _card_tw: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.tutorial_seen = true
	GameState.combat_tutorial_seen = true
	GameState.lang = "en"
	Engine.time_scale = 1.0
	main = Main.new()
	main.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(main)
	_build_overlays()

# ---------------------------------------------------------------------------
func _process(_d: float) -> void:
	f += 1
	match f:
		2:  _card_show("REKINDLED", "Civilisation lives in people and knowledge — not loot")
		96: _card_hide()
		120: _cap_show("The world went cold. A ginger cat keeps the last Ember alive.")
		215: _cap_hide()
		228: main.call("start_dungeon")
		250: _walk_in()
		262: _cap_show("Descend into the ruins — and free the survivors trapped in the dark.")
		345: _free_survivor()
		365: _cap_show("Each one remembers a craft the world forgot.")
		452: _cap_hide()
		466:
			# The knowledge layer, front and centre: recover every invention, open the Codex.
			GameState.unlock_codex("agriculture")
			GameState.unlock_codex("metallurgy")
			GameState.unlock_codex("construction")
			var h := _hud(); if h != null: h.call("toggle_codex")
		480: _cap_show("Recover REAL inventions — and the Ember tells you why each changed the world.")
		585: _cap_hide()                                   # leave the Codex clear to read
		820:
			var h := _hud(); if h != null: h.call("toggle_codex")   # close after the long hold
		838:
			var p := _player()
			if p != null and p.has_method("apply_boon"):
				p.call("apply_boon", "ember_fang")
				p.call("apply_boon", "keen_eye")
			var h := _hud(); if h != null: h.call("toggle_character")
		852: _cap_show("Knowledge becomes power — the crafts you recover change how you play.")
		958: _cap_hide()
		972:
			var h := _hud(); if h != null: h.call("toggle_character")
			_rebuilt_grid()                                # a settled village to return to
			main.call("return_to_village")
			GameState.set_gwi(0.85)                        # trees leaf out, the hearth swells
		1000: _cap_show("Rebuild the village. Reignite a dead world.")
		1090: _cap_hide()
		1108: _card_show("REKINDLED", "A cozy-rebuild action roguelite  ·  English · Tiếng Việt")
		1258: get_tree().quit()

# ---------------------------------------------------------------------------
# Scene poking
func _hud() -> Node:
	for c in main.get_children():
		if c is CanvasLayer and c.has_method("toast"): return c
	return null
func _layer() -> Node2D:
	for c in main.get_children():
		if c is Node2D and c.has_method("spawn_point"): return c as Node2D
	return null
func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _walk_in() -> void:
	var p := _player()
	if p != null:
		p.global_position += Vector2(0.0, -150.0 * Palette.SQUASH)

func _free_survivor() -> void:
	var p := _player()
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.has_method("free_it"):
			n.call("free_it", p)
			return

# A believable rebuilt village for the warm finale (all three crafts standing).
func _rebuilt_grid() -> void:
	GameState.grid[Vector2i(3, 3)] = {"type": "cabin", "built": true}
	GameState.grid[Vector2i(-3, 3)] = {"type": "forge", "built": true}
	GameState.grid[Vector2i(4, -2)] = {"type": "crop_bed", "built": true}
	GameState.grid[Vector2i(2, 1)] = {"type": "crop_bed", "built": true, "seeded": true}

# ---------------------------------------------------------------------------
# Overlays
func _build_overlays() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	# Lower-third caption on a soft dark bar.
	_cap = Control.new()
	_cap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cap.modulate.a = 0.0
	cl.add_child(_cap)
	var bar := ColorRect.new()
	bar.color = Color(0.02, 0.02, 0.03, 0.66)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -118.0
	bar.offset_bottom = -34.0
	_cap.add_child(bar)
	_cap_label = _lbl("", 30, Palette.GOLD_L)
	_cap_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cap_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bar.add_child(_cap_label)

func _cap_show(text: String) -> void:
	if _cap_tw != null and _cap_tw.is_valid(): _cap_tw.kill()
	_cap_label.text = text
	_cap_tw = _cap.create_tween()
	_cap_tw.tween_property(_cap, "modulate:a", 1.0, 0.45)

func _cap_hide() -> void:
	if _cap_tw != null and _cap_tw.is_valid(): _cap_tw.kill()
	_cap_tw = _cap.create_tween()
	_cap_tw.tween_property(_cap, "modulate:a", 0.0, 0.45)

func _card_show(title: String, sub: String) -> void:
	if _card != null and is_instance_valid(_card): _card.queue_free()
	var cl := CanvasLayer.new()
	cl.layer = 130
	add_child(cl)
	_card = Control.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_card)
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.05, 1.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.add_child(cc)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 20)
	cc.add_child(col)
	var t := _lbl(title, 84, Palette.GOLD_L)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var s := _lbl(sub, 26, Palette.AMBER)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(s)
	_card.modulate.a = 0.0
	_card_tw = _card.create_tween()
	_card_tw.tween_property(_card, "modulate:a", 1.0, 0.9)

func _card_hide() -> void:
	if _card == null or not is_instance_valid(_card): return
	if _card_tw != null and _card_tw.is_valid(): _card_tw.kill()
	_card_tw = _card.create_tween()
	_card_tw.tween_property(_card, "modulate:a", 0.0, 0.9)

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
