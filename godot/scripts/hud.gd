class_name Hud
extends CanvasLayer
## Heads-up display: resource counts, HP pips, the GWI warmth meter, rescued
## roster, the interaction prompt, transient toasts, and the build menu.
## Driven by GameState signals; layers call toast()/open_build_menu().

signal build_selected(id: String)
signal build_cancelled

const RES_ORDER := ["wood", "stone", "iron", "food", "seeds"]
const RES_ICON := {
	"wood": "material_wood", "stone": "material_stone", "iron": "material_iron",
	"food": "material_food", "seeds": "crop_3",
}

var _root: Control
var _res_labels: Dictionary = {}
var _hp_box: HBoxContainer
var _gwi_fill: ColorRect
var _roster_box: HBoxContainer
var _prompt: Label
var _toast_box: VBoxContainer
var _menu: PanelContainer
var _menu_open: bool = false
var _menu_ids: Array[String] = []

func _ready() -> void:
	layer = 10
	_build_ui()
	GameState.resources_changed.connect(_refresh_resources)
	GameState.roster_changed.connect(_refresh_roster)
	GameState.gwi_changed.connect(set_gwi)
	_refresh_resources()
	_refresh_roster()
	set_gwi(GameState.gwi)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# --- Top-left: resources + HP ---
	var tl := VBoxContainer.new()
	tl.position = Vector2(14, 12)
	tl.add_theme_constant_override("separation", 6)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tl)

	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 12)
	res_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(res_row)
	for kind in RES_ORDER:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = Assets.tex(RES_ICON[kind])
		icon.custom_minimum_size = Vector2(22, 22)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chip.add_child(icon)
		var lab := _make_label("0", 18, Palette.WHITE)
		chip.add_child(lab)
		_res_labels[kind] = lab
		res_row.add_child(chip)

	_hp_box = HBoxContainer.new()
	_hp_box.add_theme_constant_override("separation", 3)
	_hp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_child(_hp_box)

	# --- Top-right: GWI meter + roster ---
	var tr := VBoxContainer.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tr.position = Vector2(-186, 12)
	tr.add_theme_constant_override("separation", 6)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tr)

	tr.add_child(_make_label("WARMTH", 13, Palette.AMBER))
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0, 0, 0, 0.5)
	bar_bg.custom_minimum_size = Vector2(170, 14)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.add_child(bar_bg)
	_gwi_fill = ColorRect.new()
	_gwi_fill.color = Palette.GWI_COLD
	_gwi_fill.position = Vector2(1, 1)
	_gwi_fill.size = Vector2(0, 12)
	_gwi_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.add_child(_gwi_fill)

	_roster_box = HBoxContainer.new()
	_roster_box.add_theme_constant_override("separation", 2)
	_roster_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.add_child(_roster_box)

	# --- Toasts: top-centre stack ---
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast_box.position = Vector2(-140, 54)
	_toast_box.custom_minimum_size = Vector2(280, 0)
	_toast_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast_box)

	# --- Interaction prompt: bottom centre ---
	_prompt = _make_label("", 20, Palette.GOLD)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-200, -70)
	_prompt.custom_minimum_size = Vector2(400, 0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_root.add_child(_prompt)

	# --- Build menu: centre (hidden until opened) ---
	_menu = PanelContainer.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_menu.position = Vector2(-150, -120)
	_menu.custom_minimum_size = Vector2(300, 0)
	_menu.visible = false
	_root.add_child(_menu)

func _make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# ---------------------------------------------------------------------------
func _refresh_resources(_a := 0) -> void:
	for kind in RES_ORDER:
		if _res_labels.has(kind):
			var lab: Label = _res_labels[kind]
			lab.text = str(GameState.amount(kind))

func set_hp(hp: int, max_hp: int) -> void:
	if _hp_box == null:
		return
	for c in _hp_box.get_children():
		c.queue_free()
	for i in range(max_hp):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.color = Palette.EMBER if i < hp else Color(0.25, 0.2, 0.2, 0.8)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hp_box.add_child(pip)

func set_gwi(v: float) -> void:
	if _gwi_fill == null:
		return
	_gwi_fill.size = Vector2(168.0 * clampf(v, 0.0, 1.0), 12)
	_gwi_fill.color = Palette.GWI_COLD.lerp(Palette.GWI_WARM, clampf(v, 0.0, 1.0))

func _refresh_roster(_a := 0) -> void:
	if _roster_box == null:
		return
	for c in _roster_box.get_children():
		c.queue_free()
	for pillar in GameState.rescued:
		var icon := TextureRect.new()
		var key := "survivor_" + str(pillar)
		icon.texture = Assets.tex(key) if Assets.has(key) else Assets.tex("survivor_farmer")
		icon.custom_minimum_size = Vector2(26, 26)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_roster_box.add_child(icon)

# ---------------------------------------------------------------------------
func show_prompt(text: String) -> void:
	if _prompt:
		_prompt.text = text
		_prompt.visible = true

func hide_prompt() -> void:
	if _prompt:
		_prompt.visible = false

func toast(text: String, color: Color = Color("f7c59f")) -> void:
	if _toast_box == null:
		return
	var l := _make_label(text, 18, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_box.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)

# ---------------------------------------------------------------------------
func open_build_menu(entries: Array) -> void:
	_menu_open = true
	_menu_ids.clear()
	for c in _menu.get_children():
		c.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_menu.add_child(vb)
	vb.add_child(_make_label("BUILD   (Esc to cancel)", 20, Palette.EMBER))
	var n := 1
	for e in entries:
		var id: String = str(e["id"])
		_menu_ids.append(id)
		var cost_str := _cost_to_string(e["cost"])
		var affordable: bool = bool(e["affordable"])
		var b := Button.new()
		b.text = "%d.  %s   —   %s" % [n, str(e["label"]), cost_str]
		b.disabled = not affordable
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_select.bind(id))
		vb.add_child(b)
		n += 1
	_menu.visible = true

func close_build_menu() -> void:
	_menu_open = false
	_menu.visible = false

func _select(id: String) -> void:
	close_build_menu()
	build_selected.emit(id)

func _cost_to_string(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for k in cost:
		parts.append("%d %s" % [int(cost[k]), str(k)])
	return ", ".join(parts)

func _input(event: InputEvent) -> void:
	if not _menu_open:
		return
	if event.is_action_pressed("cancel"):
		close_build_menu()
		build_cancelled.emit()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := -1
		match event.physical_keycode:
			KEY_1: idx = 0
			KEY_2: idx = 1
			KEY_3: idx = 2
			KEY_4: idx = 3
		if idx >= 0 and idx < _menu_ids.size():
			_select(_menu_ids[idx])
			get_viewport().set_input_as_handled()
