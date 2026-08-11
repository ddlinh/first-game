extends Node
## ACTION trailer: combat spectacle + village work. Directed (staged) so the camera
## catches the strong beats — red danger telegraphs, a càn-quét finisher with its
## shockwave, a Bloom + boon draft, a perfect parry — then the cozy half: building
## and a living, warm village. Runs at 1× so the effects are readable. Not shipped.
##
##   godot --path godot res://tools/trailer_action.tscn \
##       --write-movie <out.avi> --fixed-fps 30 --quit-after 1290

var main: Node
var f: int = 0
var _cap: Control = null
var _cap_label: Label = null
var _cap_tw: Tween = null
var _card: Control = null
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
		2:  _titlecard("REKINDLED", "Fight the dark.  Rebuild the warmth.")
		92: _card_hide()
		# ---- COMBAT ------------------------------------------------------------
		112: main.call("start_dungeon")
		128:
			var p := _player()
			if p != null:
				p.set("crit_chance", 1.0)     # everything crits for the sizzle reel
			_clear_enemies()
			_spawn("husk", Vector2(150, -30)); _spawn("charger", Vector2(-205, 20))
			_spawn("bomber", Vector2(95, 150)); _spawn("husk", Vector2(-95, 135))
			_caption("Fast, tactile combat — telegraphed, so you can react.")
		150: _force_windups()                 # red danger zones flare up
		205: _caption("Read the red. Dodge in, punish the recovery.")
		214:
			_set_move(Vector2(-1.0, 0.2)); _hero("_start_dash")   # dash the charger down
		250:
			_clear_enemies()                  # stage a tight cluster for the finisher
			_spawn("husk", Vector2(58, -6)); _spawn("husk", Vector2(-52, 10))
			_spawn("husk", Vector2(6, 46)); _spawn("charger", Vector2(-10, -46))
		268: _hero("_start_attack", 2)        # CÀN QUÉT spin: shockwave + crits + kick
		300: _caption("Every strike lands with weight — crunch, hit-stop, screen-kick.")
		330: _hero("_start_attack", 2)
		372: _cap_hide()
		# Bloom → the boon draft (pauses the world; we hold on the card, then pick)
		392:
			var p := _player()
			if p != null and p.has_method("gain_kindle"):
				p.call("gain_kindle", 9.0)
		408: _caption("Every Bloom, a boon to draft — no two runs alike.")
		520:
			var h := _hud()
			if h != null and h.has_method("boon_open") and bool(h.call("boon_open")):
				h.call("pick_boon_index", 0)
		534: _cap_hide()
		# Perfect parry
		548:
			_clear_enemies()
			_spawn("husk", Vector2(70, -10)); _spawn("husk", Vector2(-64, 6))
		566: _force_windups()
		584: _hero("_perfect_parry")          # radial stagger + PARRY freeze
		592: _caption("Time a Perfect Parry — the hardest freeze in the game.")
		612: _hero("_start_attack", 2)        # the empowered riposte
		660: _cap_hide()
		# ---- VILLAGE WORK ------------------------------------------------------
		676:
			# A rescued, rebuilt, warming home to return to.
			for pil in ["farmer", "smith", "builder"]:
				GameState.add_rescued(pil)
			_rebuilt_grid()
			var p := _player()
			if p != null:
				p.set("crit_chance", 0.22)
			main.call("return_to_village")
			GameState.set_gwi(0.5)
		700: _caption("Then home: build, farm, and warm a dead world back to life.")
		760:
			# Raise a fresh building on camera: drop a frame and hammer it up.
			_stage_build()
		860: _caption("Villagers you rescue settle in — and the world starts to breathe.")
		905:
			GameState.set_gwi(0.9)            # trees leaf out, the hearth swells, grass sways
		975: _caption("As warmth returns, the whole sanctuary thaws.")
		1080: _cap_hide()
		1100: _titlecard("REKINDLED", "A cozy-rebuild action roguelite  ·  English · Tiếng Việt")
		1288: get_tree().quit()

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

func _hero(method: String, arg = null) -> void:
	var p := _player()
	if p == null or not p.has_method(method):
		return
	if arg == null:
		p.call(method)
	else:
		p.call(method, arg)

func _set_move(dir: Vector2) -> void:
	var p := _player()
	if p != null:
		p.set("_move_dir", dir.normalized())
		p.set("facing", dir.normalized())

func _spawn(kind: String, off: Vector2) -> void:
	var lyr := _layer()
	var p := _player()
	if lyr == null or p == null:
		return
	var e = Enemy.new()
	e.configure(8, 110.0, "enemy_brute" if kind == "warden" else "enemy_husk", kind)
	e.position = p.global_position + Vector2(off.x, off.y * Palette.SQUASH)
	lyr.add_child(e)

func _clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e):
			(e as Node).queue_free()

func _force_windups() -> void:
	var p := _player()
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e.has_method("_begin_windup"):
			e.call("_begin_windup", p)

func _rebuilt_grid() -> void:
	GameState.grid[Vector2i(3, 3)] = {"type": "cabin", "built": true}
	GameState.grid[Vector2i(-3, 3)] = {"type": "forge", "built": true}
	GameState.grid[Vector2i(4, -2)] = {"type": "crop_bed", "built": true}
	GameState.grid[Vector2i(2, 1)] = {"type": "crop_bed", "built": true, "seeded": true}

# Raise a building on camera near the hearth — it pops up with a flourish, a
# "raised!" toast and (being a cabin) a smoking chimney.
func _stage_build() -> void:
	var lyr := _layer()
	if lyr == null or not lyr.has_method("finish_building"):
		return
	var cell := Vector2i(2, -1)
	GameState.grid[cell] = {"type": "cabin", "built": false}
	lyr.call("finish_building", cell, "cabin")

# ---------------------------------------------------------------------------
# Overlays (caption + title/end card)
func _build_overlays() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
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

func _caption(text: String) -> void:
	if _cap_tw != null and _cap_tw.is_valid(): _cap_tw.kill()
	_cap_label.text = text
	_cap_tw = _cap.create_tween()
	_cap_tw.tween_property(_cap, "modulate:a", 1.0, 0.45)

func _cap_hide() -> void:
	if _cap_tw != null and _cap_tw.is_valid(): _cap_tw.kill()
	_cap_tw = _cap.create_tween()
	_cap_tw.tween_property(_cap, "modulate:a", 0.0, 0.45)

func _titlecard(title: String, sub: String) -> void:
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
