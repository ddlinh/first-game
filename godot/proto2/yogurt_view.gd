extends Node2D

## View màn YAOURT — vẽ + nhập liệu + HUD. Chỉ ĐỌC lõi (yogurt_level.gd), không giữ luật.
## Người chơi chỉnh môi trường bằng HÀNH ĐỘNG (nút), không slider. pH là đồng hồ ĐÍCH.

const Yogurt := preload("res://proto2/yogurt_level.gd")

const DR := 150.0                 # bán kính hũ
const CREAM := Color(0.93, 0.94, 0.86)
const TAN := Color(0.85, 0.72, 0.45)
const MOLD := Color(0.44, 0.49, 0.30)

var y
var _font: Font
var _t := 0.0
var running := false
var _base := Vector2.ZERO
var _shake := 0.0
var _toast := ""
var _toast_t := 0.0
var _toast_col := Color(1, 0.72, 0.4)
var _pool: Array = []

var _tex_st: Texture2D            # cầu khuẩn (S. thermophilus)
var _tex_lb: Texture2D            # trực khuẩn (L. bulgaricus)

var _hud: CanvasLayer
var _btns := {}
var _intro: Panel
var _intro_lbl: RichTextLabel
var _result: Panel
var _result_lbl: RichTextLabel
var _tut: Panel
var _tut_lbl: Label
var tut_step := 0
var _tut_on := true               ## tắt sau khi học xong (hoặc [T]); không hiện lại

const TUT := [
	"Bấm [Ủ ấm] vài lần để đưa NHIỆT vào dải xanh 40–45°C — men cần ấm mới lên men.",
	"Tốt! Men đang chạy — nhìn pH TỰ tụt. Cứ giữ nhiệt trong dải xanh, chưa cần làm gì thêm.",
	"Nhìn thanh MEN: cầu khuẩn S. thermophilus (trắng) dẫn trước; khi chua dần, trực khuẩn L. bulgaricus (tan) TIẾP QUẢN — đó là cộng sinh.",
	"Thấy ⚠ là biến cố sắp tới — xử lý ngay: gió lùa → [Ủ ấm]/[Quấn khăn]; phage → [Thêm men]; mốc → [Tiệt trùng].",
	"Sắp tới đích! Khi pH chạm 4.6, nút [CHỐT] sáng lên — bấm để hoàn thành. Đừng để lố xuống dưới 4.3 (quá chua).",
]

const ACTIONS := [
	["warm", "Ủ ấm", "nhiệt ↑"], ["cool", "Làm mát", "nhiệt ↓"],
	["wrap", "Quấn khăn", "giữ ấm"], ["inoc", "Thêm men", "cấy/cứu"],
	["clean", "Tiệt trùng", "mốc ↓"], ["chill", "CHỐT", "kết ở 4.6"],
]


func _ready() -> void:
	y = Yogurt.new(4242)
	_font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex_st = _png("cell_staph")
	_tex_lb = _png("cell_ecoli")
	for i in 260:
		var a := randf() * TAU
		var r := sqrt(randf()) * (DR - 12.0)
		_pool.append({"p": Vector2(cos(a), sin(a)) * r, "ph": randf() * TAU})
	_build_hud()
	_place()
	get_viewport().size_changed.connect(_place)
	_show_intro()


func _png(name: String) -> Texture2D:
	var img := Image.new()
	if img.load("res://proto2/sprites/%s.png" % name) != OK:
		return null
	return ImageTexture.create_from_image(img)


func _place() -> void:
	var vp := get_viewport_rect().size
	_base = Vector2(vp.x * 0.34, vp.y * 0.46)
	position = _base
	var w := 560.0
	if _intro:
		_intro.size = Vector2(w, 240); _intro.position = Vector2((vp.x - w) * 0.5, vp.y * 0.28)
		_intro_lbl.position = Vector2(24, 20); _intro_lbl.size = Vector2(w - 48, 200)
	if _result:
		_result.size = Vector2(w, 240); _result.position = Vector2((vp.x - w) * 0.5, vp.y * 0.28)
		_result_lbl.position = Vector2(24, 20); _result_lbl.size = Vector2(w - 48, 200)
	if _tut:
		var tw := 760.0
		_tut.size = Vector2(tw, 56); _tut.position = Vector2((vp.x - tw) * 0.5, 44)
		_tut_lbl.position = Vector2(16, 8); _tut_lbl.size = Vector2(tw - 32, 40)


func _process(dt: float) -> void:
	_t += dt
	_shake = maxf(0.0, _shake - dt * 22.0)
	position = _base + Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0) * _shake
	if _toast_t > 0.0: _toast_t -= dt
	if running and y.state == Yogurt.PLAYING:
		y.update(dt)
		_drain()
		_advance_tut()
		if y.state != Yogurt.PLAYING:
			_show_result()
	if _btns.has("chill"):
		_btns["chill"].disabled = not y.can_chill()
	_update_tut()
	queue_redraw()


func _advance_tut() -> void:
	match tut_step:
		0: if y.temp >= 40.0: tut_step = 1
		1: if y.pH <= 5.8: tut_step = 2
		2: if y.pH <= 5.0: tut_step = 3
		3: if y.pH <= 4.7: tut_step = 4
		4: if y.can_chill(): tut_step = 5
	if tut_step >= TUT.size():
		_tut_on = false


func _update_tut() -> void:
	if _tut == null:
		return
	var show := _tut_on and running and not _intro.visible and not _result.visible and tut_step < TUT.size()
	_tut.visible = show
	if show:
		_tut_lbl.text = "HƯỚNG DẪN %d/%d   —   %s" % [tut_step + 1, TUT.size(), TUT[tut_step]]


func _drain() -> void:
	for e in y.events:
		match e.get("kind"):
			"warn": _flash("⚠ " + _emsg(e["ev"], true), Color(0.95, 0.75, 0.35))
			"event":
				_flash("✦ " + _emsg(e["ev"], false), Color(0.95, 0.45, 0.35))
				_shake = minf(_shake + 3.0, 8.0)
	y.events.clear()


func _emsg(ev: String, warn: bool) -> String:
	match ev:
		"draft": return "Sắp có gió lùa — thủ nhiệt!" if warn else "Gió lùa tràn vào!"
		"phage": return "Men đông — nguy cơ phage" if warn else "Phage tấn công men!"
		"contam": return "Cẩn thận nhiễm chéo" if warn else "Thìa bẩn — nhiễm mốc!"
	return ev


func _flash(msg: String, col: Color) -> void:
	_toast = msg; _toast_col = col; _toast_t = 3.5


# ─────────────────────────── vẽ ───────────────────────────

func _draw() -> void:
	# hũ sữa
	draw_circle(Vector2.ZERO, DR + 6.0, Color(0.09, 0.11, 0.08))
	draw_circle(Vector2.ZERO, DR, Color(0.10, 0.12, 0.09) if y.pH > 5.0 else CREAM.darkened(0.1))
	# màng gel khi pH thấp (đông dần)
	if y.pH < 5.2:
		var a := clampf((5.2 - y.pH) / 0.9, 0.0, 0.55)
		draw_circle(Vector2.ZERO, DR * 0.99, Color(CREAM, a))
	draw_arc(Vector2.ZERO, DR, 0, TAU, 64, Color(0.55, 0.6, 0.42, 0.4), 2.0, true)

	# hai loài (cầu khuẩn st + trực khuẩn lb)
	var n_st := int(y.st * _pool.size())
	var n_lb := int(y.lb * _pool.size())
	for i in n_st:
		var d = _pool[i]
		var j := Vector2(sin(_t * 2.0 + d["ph"]), cos(_t * 1.8 + d["ph"])) * 0.8
		_blit(_tex_st, d["p"] + j, 0.0, CREAM, 0.85)
	for i in n_lb:
		var d = _pool[_pool.size() - 1 - i]
		var j := Vector2(sin(_t * 2.0 + d["ph"]), cos(_t * 1.8 + d["ph"])) * 0.8
		_blit(_tex_lb, d["p"] + j, d["ph"], TAN, 0.8)
	# mốc
	var n_sp := int(y.spoil * 90)
	for i in n_sp:
		var d = _pool[i * 2 % _pool.size()]
		draw_circle(d["p"], 3.5, Color(MOLD, 0.85))

	# đồng hồ (bên phải hũ)
	var mx := DR + 40.0
	var my := -DR + 6.0
	_meter(Vector2(mx, my), 190, (y.temp - 15.0) / 40.0, _temp_col(),
		"NHIỆT °C", "%.1f" % y.temp, [[(40.0 - 15.0) / 40.0, (45.0 - 15.0) / 40.0]],
		[[(43.0 - 15.0) / 40.0, Color(0.34, 0.84, 0.6)]])
	var pf: float = 1.0 - (y.pH - 3.9) / 2.9        # đầy dần khi pH tụt về đích
	_meter(Vector2(mx, my + 44), 190, pf, Color(0.9, 0.76, 0.34),
		"pH (đích 4.6)", "%.2f" % y.pH,
		[], [[1.0 - (4.6 - 3.9) / 2.9, Color(0.34, 0.84, 0.6)], [1.0 - (4.3 - 3.9) / 2.9, Color(0.9, 0.4, 0.3)]])
	_meter(Vector2(mx, my + 88), 190, y.spoil, Color(MOLD).lerp(Color(0.9, 0.4, 0.3), y.spoil),
		"MỐC %", "%d" % int(y.spoil * 100), [], [[0.62, Color(0.9, 0.4, 0.3)]])
	# thanh men: xếp chồng st (cầu) + lb (trực) → thấy TRAO TAY
	_culture_bar(Vector2(mx, my + 132), 190)

	# pha + giờ
	var ph := _phase()
	draw_string(_font, Vector2(mx, my + 178), ph, HORIZONTAL_ALIGNMENT_LEFT, 190, 13, Color(0.9, 0.82, 0.5))
	draw_string(_font, Vector2(mx, my + 196), "⏱ %ds" % int(y.elapsed), HORIZONTAL_ALIGNMENT_LEFT, 190, 12, Color(0.6, 0.66, 0.55))

	# toast dưới hũ
	if _toast_t > 0.0:
		draw_string(_font, Vector2(-DR, DR + 26), _toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, _toast_col)


func _temp_col() -> Color:
	if y.temp > 48.0: return Color(0.9, 0.4, 0.3)
	if y.temp < 36.0: return Color(0.42, 0.7, 0.9)
	return Color(0.34, 0.84, 0.6)


func _meter(pos: Vector2, w: float, frac: float, col: Color, label: String, val: String,
		bands: Array, marks: Array) -> void:
	var h := 11.0
	draw_string(_font, pos + Vector2(0, -3), label, HORIZONTAL_ALIGNMENT_LEFT, 140, 12, Color(0.62, 0.68, 0.56))
	draw_string(_font, pos + Vector2(w - 46, -3), val, HORIZONTAL_ALIGNMENT_RIGHT, 46, 13, col)
	draw_rect(Rect2(pos + Vector2(0, 2), Vector2(w, h)), Color(0.06, 0.08, 0.05))
	for b in bands:
		draw_rect(Rect2(pos + Vector2(b[0] * w, 2), Vector2((b[1] - b[0]) * w, h)), Color(0.34, 0.84, 0.6, 0.22))
	draw_rect(Rect2(pos + Vector2(0, 2), Vector2(clampf(frac, 0, 1) * w, h)), col)
	for m in marks:
		var mxp: float = pos.x + m[0] * w
		draw_line(Vector2(mxp, pos.y), Vector2(mxp, pos.y + h + 4), m[1], 2.0)


func _culture_bar(pos: Vector2, w: float) -> void:
	var h := 11.0
	draw_string(_font, pos + Vector2(0, -3), "MEN (cầu S.th + trực L.b)", HORIZONTAL_ALIGNMENT_LEFT, w, 12, Color(0.62, 0.68, 0.56))
	draw_rect(Rect2(pos + Vector2(0, 2), Vector2(w, h)), Color(0.06, 0.08, 0.05))
	var sw := clampf(y.st, 0, 1) * w
	var lw := clampf(y.lb, 0, 1) * w
	draw_rect(Rect2(pos + Vector2(0, 2), Vector2(sw, h)), CREAM)
	draw_rect(Rect2(pos + Vector2(sw, 2), Vector2(lw, h)), TAN)


func _phase() -> String:
	if y.st + y.lb < 0.2 and y.pH > 6.4: return "Pha 1 · Cấy & ì — ủ ấm cho men chạy"
	if y.pH > 5.5: return "Pha 2 · S. thermophilus dẫn"
	if y.pH > 4.62: return "Pha 3 · Trao tay L. bulgaricus"
	return "Pha 4 · Điểm đông — CHỐT ngay!"


func _blit(tex: Texture2D, pos: Vector2, ang: float, mod: Color, sc: float) -> void:
	if tex == null:
		draw_circle(pos, 3.0, mod); return
	var s := tex.get_size()
	draw_set_transform(pos, ang, Vector2(sc, sc))
	draw_texture(tex, -s * 0.5, mod)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ─────────────────────────── HUD + nhập liệu ───────────────────────────

func _build_hud() -> void:
	_hud = CanvasLayer.new(); add_child(_hud)
	var back := CanvasLayer.new(); back.layer = -10; add_child(back)
	var bg := ColorRect.new(); bg.color = Color(0.07, 0.08, 0.055)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; back.add_child(bg)

	var title := Label.new()
	title.text = "MÀN YAOURT — dẫn vại sữa tới pH 4.6 rồi CHỐT   ·   [R] chơi lại · [T] ẩn/hiện hướng dẫn"
	title.position = Vector2(24, 14); title.add_theme_font_size_override("font_size", 15)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE; _hud.add_child(title)

	_tut = _mk_panel(Color(0.98, 0.92, 0.55, 0.85))
	_tut_lbl = Label.new()
	_tut_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tut_lbl.add_theme_font_size_override("font_size", 15)
	_tut.add_child(_tut_lbl)
	_tut.visible = false

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -70; bar.offset_bottom = -18; bar.offset_left = 24; bar.offset_right = -24
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_hud.add_child(bar)
	for a in ACTIONS:
		var b := Button.new()
		b.custom_minimum_size = Vector2(140, 46)
		b.text = a[1] + "\n" + a[2]
		b.add_theme_font_size_override("font_size", 14)
		var id: String = a[0]
		b.pressed.connect(func(): _do(id))
		bar.add_child(b); _btns[id] = b

	_intro = _mk_panel(Color(0.55, 0.85, 0.95, 0.9))
	_intro_lbl = _mk_rich(_intro, 16)
	_result = _mk_panel(Color(0.85, 0.78, 0.5, 0.9))
	_result_lbl = _mk_rich(_result, 16)
	_result.visible = false


func _mk_panel(border: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.07, 0.97); sb.set_corner_radius_all(10)
	sb.border_color = border; sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	_hud.add_child(p); return p


func _mk_rich(panel: Panel, size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true; r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", size)
	panel.add_child(r); return r


func _do(id: String) -> void:
	if _intro.visible:
		_begin()
		return
	if y.state != Yogurt.PLAYING:
		return
	match id:
		"warm": y.warm()
		"cool": y.cool()
		"wrap": y.wrap_jar()
		"inoc": y.add_starter()
		"clean": y.sanitize()
		"chill":
			if y.can_chill():
				y.chill(); _show_result()
			else:
				_flash("Chưa tới pH 4.6 — chưa chốt được!", Color(0.95, 0.75, 0.35))


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_R:
			_restart()
		elif ev.keycode == KEY_T:
			_tut_on = not _tut_on
		elif ev.keycode == KEY_SPACE and _intro.visible:
			_begin()


func _show_intro() -> void:
	running = false; _result.visible = false; _intro.visible = true
	_intro_lbl.text = "[b]Mẻ yaourt[/b]\n\n[b]Đích:[/b] dẫn vại sữa hạ pH tới [b]4.6[/b] (casein đông) rồi bấm CHỐT — đừng để mốc chiếm, đừng lố dưới 4.3.\n\nỦ ấm cho Nhiệt vào [color=#57d69b]dải xanh 40–45°C[/color] → men chạy, pH tự tụt. Có [color=#f0a63c]⚠[/color] thì xử lý (gió lùa→ủ ấm/quấn, phage→thêm men).\n\n[color=#f7dc5c]▶ Bấm nút bất kỳ hoặc [Space] để bắt đầu[/color]"


func _begin() -> void:
	_intro.visible = false; running = true
	_flash("Việc đầu: bấm “Ủ ấm” cho nhiệt vào dải xanh.", Color(0.6, 0.9, 0.7))


func _show_result() -> void:
	running = false; _result.visible = true
	if y.state == Yogurt.WON:
		var s: int = y.stars()
		_result_lbl.text = "[b]Yaourt đã đông![/b]  %s\n\nCasein đông ở [b]pH 4.6[/b] (điểm đẳng điện). Men lành đã hạ axit đủ nhanh để đè mốc — và [b]hai loài cộng sinh[/b] mới làm nổi: S. thermophilus khởi động, L. bulgaricus về đích.\n\n[color=#9fb4c8][R] chơi lại[/color]" % ("★".repeat(s) + "☆".repeat(5 - s))
	else:
		_result_lbl.text = "[b]Mẻ hỏng[/b] — %s\n\nYaourt là cuộc đua: men phải hạ pH đủ nhanh để đè mốc, giữ nhiệt ~43°C, và chốt đúng ở 4.6.\n\n[color=#9fb4c8][R] chơi lại[/color]" % y.lose_reason


func _restart() -> void:
	y.reset(); tut_step = 0; _show_intro()
