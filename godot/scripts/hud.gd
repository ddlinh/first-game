class_name Hud
extends CanvasLayer

## Toàn bộ giao diện dựng bằng mã chứ không phải .tscn. Lý do: HUD này có gần 40
## node và ba lớp phủ (hướng dẫn / kết quả / chọn thẻ) dùng chung một khung —
## viết tay trong file scene thì sửa một khoảng cách phải dò qua chục dòng toạ độ,
## còn ở đây bố cục nằm ngay cạnh dữ liệu nó hiển thị.

signal continue_pressed
signal card_chosen(index: int)
signal restart_pressed
signal stir_changed(down: bool)

const EDGE := Color(1, 1, 1, 0.09)
const MUTED := Color(0.52, 0.58, 0.68)
const SPECIES_NAME := {
	Sim.TOXIC: "Tiết độc",
	Sim.SENSITIVE: "Nhạy cảm",
	Sim.RESISTANT: "Kháng độc",
}

var _root: Control
var _count_labels := {}
var _clock: Label
var _clock_bar: ProgressBar
var _goal_title: Label
var _goal_desc: Label
var _goal_progress: Label
var _stage_label: Label
var _plant_btn: Button
var _stir_btn: Button
var _stir_bar: ProgressBar
var _log: Label
var _overlay: Control
var _overlay_box: VBoxContainer
var _log_fade := 0.0


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_counts()
	_build_goal()
	_build_cycle()
	_build_bottom()
	_build_overlay()


# ─────────────────────────── dựng khung ───────────────────────────

func _panel(pos: Vector2, preset: int = Control.PRESET_TOP_LEFT) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.of("panel")
	sb.border_color = EDGE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	p.add_theme_stylebox_override("panel", sb)
	p.set_anchors_preset(preset)
	p.position = pos
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(p)
	return p


func _label(text: String, size: int, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _dot(col: Color) -> Panel:
	var d := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(6)
	d.add_theme_stylebox_override("panel", sb)
	d.custom_minimum_size = Vector2(11, 11)
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return d


func _build_counts() -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	for s in [Sim.TOXIC, Sim.SENSITIVE, Sim.RESISTANT]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		row.add_child(_dot(Palette.sprite(s)))
		var name_txt: String = SPECIES_NAME[s] + (" (bạn)" if s == Sim.TOXIC else "")
		row.add_child(_label(name_txt, 14, MUTED))
		var val := _label("0%", 15, Palette.sprite(s))
		val.custom_minimum_size.x = 46
		row.add_child(val)
		_count_labels[s] = val
		box.add_child(row)
	_panel(Vector2(18, 14)).add_child(box)


func _build_goal() -> void:
	var p := _panel(Vector2(-372, 14), Control.PRESET_TOP_RIGHT)
	p.custom_minimum_size.x = 354
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_goal_title = _label("Mục tiêu", 16, Palette.sprite(Sim.SENSITIVE))
	_goal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_goal_title)
	_clock = _label("60s", 20)
	head.add_child(_clock)
	v.add_child(head)

	_goal_desc = _label("", 13, MUTED)
	_goal_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_desc.custom_minimum_size.x = 330
	v.add_child(_goal_desc)

	_clock_bar = ProgressBar.new()
	_clock_bar.show_percentage = false
	_clock_bar.custom_minimum_size.y = 5
	_clock_bar.max_value = 1.0
	_clock_bar.value = 1.0
	_style_bar(_clock_bar, Palette.sprite(Sim.SENSITIVE))
	v.add_child(_clock_bar)

	_goal_progress = _label("", 13, Color(0.75, 0.82, 0.92))
	v.add_child(_goal_progress)
	p.add_child(v)

	_stage_label = _label("", 13, MUTED)
	_stage_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_stage_label.position = Vector2(-372, 118)
	_stage_label.custom_minimum_size.x = 354
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_stage_label)


## Vòng khắc chế luôn hiện: người chơi phải nhớ được ai ăn ai mới chơi nổi.
func _build_cycle() -> void:
	var p := _panel(Vector2(18, -132), Control.PRESET_BOTTOM_LEFT)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.add_child(_label("VÒNG KHẮC CHẾ", 12, MUTED))
	var rows := [
		[Sim.TOXIC, "diệt", Sim.SENSITIVE],
		[Sim.SENSITIVE, "đè", Sim.RESISTANT],
		[Sim.RESISTANT, "chặn", Sim.TOXIC],
	]
	for r in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		h.add_child(_dot(Palette.sprite(r[0])))
		h.add_child(_label(SPECIES_NAME[r[0]], 13, Palette.sprite(r[0])))
		h.add_child(_label("→ %s →" % r[1], 12, MUTED))
		h.add_child(_dot(Palette.sprite(r[2])))
		h.add_child(_label(SPECIES_NAME[r[2]], 13, Palette.sprite(r[2])))
		v.add_child(h)
	p.add_child(v)


func _build_bottom() -> void:
	_log = _label("", 14, Color(0.80, 0.86, 0.95))
	_log.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_log.position = Vector2(0, -104)
	_log.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_log.add_theme_constant_override("shadow_outline_size", 4)
	_root.add_child(_log)

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.position = Vector2(0, -74)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)

	_plant_btn = _button("🧪 Cấy quân  (chuột trái)")
	_plant_btn.disabled = true       # nút chỉ để hiển thị, cấy bằng cách bấm vào đĩa
	_plant_btn.focus_mode = Control.FOCUS_NONE
	bar.add_child(_plant_btn)

	var stir_wrap := VBoxContainer.new()
	stir_wrap.add_theme_constant_override("separation", 3)
	_stir_btn = _button("🌀 Khuấy đĩa  (giữ Space)")
	_stir_btn.button_down.connect(func() -> void: stir_changed.emit(true))
	_stir_btn.button_up.connect(func() -> void: stir_changed.emit(false))
	stir_wrap.add_child(_stir_btn)
	_stir_bar = ProgressBar.new()
	_stir_bar.show_percentage = false
	_stir_bar.custom_minimum_size.y = 4
	_stir_bar.max_value = 1.0
	_stir_bar.value = 1.0
	_style_bar(_stir_bar, Palette.sprite(Sim.RESISTANT))
	stir_wrap.add_child(_stir_bar)
	bar.add_child(stir_wrap)

	var again := _button("🔄 Chơi lại  (R)")
	again.pressed.connect(func() -> void: restart_pressed.emit())
	bar.add_child(again)


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.of("panel") if state != "hover" \
			else Palette.of("overlay").lightened(0.12)
		if state == "pressed":
			sb.bg_color = Palette.sprite(Sim.TOXIC).darkened(0.55)
		sb.border_color = EDGE
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 9
		sb.content_margin_bottom = 9
		b.add_theme_stylebox_override(state, sb)
	return b


func _style_bar(bar: ProgressBar, col: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.10)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_root.add_child(_overlay)

	var dim := ColorRect.new()
	dim.color = Color(Palette.of("backdrop"), 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP    # chặn chuột rơi xuống đĩa
	_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)

	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.of("overlay")
	sb.border_color = Color(1, 1, 1, 0.13)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	frame.add_theme_stylebox_override("panel", sb)
	center.add_child(frame)

	_overlay_box = VBoxContainer.new()
	_overlay_box.add_theme_constant_override("separation", 14)
	_overlay_box.alignment = BoxContainer.ALIGNMENT_CENTER
	frame.add_child(_overlay_box)


func _clear_overlay() -> void:
	for c in _overlay_box.get_children():
		c.queue_free()
		_overlay_box.remove_child(c)


# ─────────────────────────── cập nhật mỗi khung ───────────────────────────

func set_counts(sim: Sim) -> void:
	for s in [Sim.TOXIC, Sim.SENSITIVE, Sim.RESISTANT]:
		_count_labels[s].text = "%d%%" % roundi(sim.ratio(s) * 100.0)


func set_clock(left: float, total: float) -> void:
	_clock.text = "%.0fs" % ceilf(maxf(left, 0.0))
	_clock_bar.value = clampf(left / maxf(total, 0.001), 0.0, 1.0)
	_clock.add_theme_color_override(
		"font_color", Color(1.0, 0.42, 0.42) if left <= 10.0 else Color.WHITE)


func set_goal(stage: Dictionary, index: int, total: int) -> void:
	_goal_title.text = Stages.GOAL_INFO[stage["goal"]]["name"]
	_goal_desc.text = Stages.GOAL_INFO[stage["goal"]]["desc"]
	_stage_label.text = "Đĩa %d/%d · %s · thế cờ %s" % [
		index + 1, total, Stages.TERRAIN_NAME[stage["terrain"]],
		Stages.LAYOUT_NAME[stage["layout"]]]


func set_progress(text: String, good: bool) -> void:
	_goal_progress.text = text
	_goal_progress.add_theme_color_override(
		"font_color", Color(0.45, 0.90, 0.55) if good else Color(1.0, 0.55, 0.45))


func set_plant(charges: int, max_charges: int, cd_ratio: float) -> void:
	if charges > 0:
		_plant_btn.text = "🧪 Cấy quân  ×%d/%d" % [charges, max_charges]
	else:
		_plant_btn.text = "🧪 Đang nuôi cấy…  %d%%" % roundi(cd_ratio * 100.0)


func set_stir(energy: float, active: bool) -> void:
	_stir_bar.value = energy
	_stir_btn.text = "🌀 ĐANG KHUẤY!" if active else "🌀 Khuấy đĩa  (giữ Space)"


func log_line(text: String) -> void:
	_log.text = text
	_log_fade = 4.0


func _process(delta: float) -> void:
	if _log_fade > 0.0:
		_log_fade -= delta
		_log.modulate.a = clampf(_log_fade, 0.0, 1.0)


# ─────────────────────────── lớp phủ ───────────────────────────

func hide_overlay() -> void:
	_overlay.visible = false


func show_message(title: String, body: String, button: String, tint := Color.WHITE) -> void:
	_clear_overlay()
	var t := _label(title, 30, tint)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_box.add_child(t)

	var b := _label(body, 15, MUTED)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = 520
	_overlay_box.add_child(b)

	var go := _button(button)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void: continue_pressed.emit())
	_overlay_box.add_child(go)
	_overlay.visible = true


func show_cards(cards: Array[Dictionary]) -> void:
	_clear_overlay()
	var t := _label("Thắng đĩa! Chọn một thẻ nâng cấp", 26, Palette.sprite(Sim.TOXIC))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_box.add_child(t)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in cards.size():
		row.add_child(_card_button(cards[i], i))
	_overlay_box.add_child(row)

	var hint := _label("Bấm thẻ hoặc gõ phím 1 / 2 / 3", 13, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_box.add_child(hint)
	_overlay.visible = true


func _card_button(card: Dictionary, index: int) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(210, 132)
	b.pressed.connect(func() -> void: card_chosen.emit(index))
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.of("overlay").lightened(0.04)
		if state == "hover":
			sb.bg_color = Palette.sprite(Sim.TOXIC).darkened(0.72)
		if state == "pressed":
			sb.bg_color = Palette.sprite(Sim.TOXIC).darkened(0.52)
		sb.border_color = Color(Palette.sprite(Sim.TOXIC),
			0.4 if state == "normal" else 0.85)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(14)
		b.add_theme_stylebox_override(state, sb)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16
	v.offset_right = -16
	v.offset_top = 16
	v.offset_bottom = -16
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_label("%d." % (index + 1), 13, MUTED))
	var n := _label(card["name"], 18, Palette.sprite(Sim.TOXIC).lightened(0.25))
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(n)
	var d := _label(card["desc"], 13, MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	b.add_child(v)
	return b
