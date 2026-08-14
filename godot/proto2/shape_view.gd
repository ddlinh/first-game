extends Node2D

## View màn MẠNG LƯỚI — vẽ + nhập liệu + HUD. Chỉ ĐỌC lõi (shape_level.gd), không giữ luật.
##
## Điều quan trọng nhất của màn này là NHÌN THẤY ĐIỂM SỐ trong lúc chơi:
##   ô đích chưa chiếm  → viền mờ      (còn phải phủ)
##   ô đích đã chiếm    → XANH LÁ      (ăn điểm)
##   ô chiếm ngoài đích → ĐỎ CAM       (tràn — trừ điểm, KHÔNG xoá được)
## Con trỏ tự đổi màu theo tầm với: xanh = khuẩn giữ được chỗ, vàng = bỏ mồi cho mốc.

const Shape := preload("res://proto2/shape_level.gd")
const AgentColony := preload("res://proto2/agent_colony.gd")

const C_GLASS := Color(0.13, 0.14, 0.16)
const C_DISH := Color(0.055, 0.06, 0.07)
const C_RIM := Color(0.36, 0.40, 0.34)
const C_TARGET := Color(0.42, 0.72, 0.95)      # hình đích chưa phủ
const C_HIT := Color(0.36, 0.86, 0.55)         # phủ đúng
const C_SPILL := Color(0.94, 0.45, 0.28)       # tràn ra ngoài
const C_NUT := Color(0.95, 0.82, 0.35)
const C_MOLD := Color(0.46, 0.52, 0.28)
const C_DRY := Color(0.55, 0.42, 0.26)

const REPEAT_EVERY := 0.35     ## giữ chuột thì rải lại sau ngần này giây

var s
var _font: Font
var _t := 0.0
var _base := Vector2.ZERO
var _shake := 0.0
var _hold := false
var _hold_cd := 0.0
var _toast := ""
var _toast_t := 0.0
var _toast_col := Color(1, 0.8, 0.4)
var _splash: Array = []        ## hiệu ứng giọt/mốc {pos, r, t, life, kind}
var _body: Texture2D

var _hud: CanvasLayer
var _seal_btn: Button
var _intro: Panel
var _intro_lbl: RichTextLabel
var _result: Panel
var _result_lbl: RichTextLabel
var _tut: Panel
var _tut_lbl: Label
var running := false
var tut_step := 0
var _tut_on := true

const TUT := [
	"Rải THỨC ĂN vào trong hình xanh, SÁT chỗ khuẩn đang có. Con trỏ XANH = khuẩn với tới; VÀNG = quá xa, mốc sẽ bén vào ăn mất chỗ đó.",
	"Khuẩn không nhắm đích ở xa — nó chỉ mọc lấn ở RÌA. Cứ rải đón đầu từng chặng rồi ĐỢI, đừng ném thẳng sang đầu kia.",
	"Ô xanh lá = phủ đúng (ăn điểm). Ô ĐỎ = mọc tràn ra ngoài hình — và vệt đã mọc thì KHÔNG xoá được, nên đừng rải quá tay.",
	"Thấy ⚠ là giọt nước sắp rơi xuống đúng chỗ đó và RỬA TRÔI thức ăn — đừng rải vào vùng ấy lúc này.",
	"Đủ khớp thì nút CHỐT sáng lên. Chốt sớm được ít sao; đợi lâu quá thì khuẩn mọc tràn, điểm lại tụt. Chọn đúng lúc!",
]


func _ready() -> void:
	s = Shape.new(0, 7)
	_font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body = _png("cell_ecoli")
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
	_base = Vector2(vp.x * 0.37, vp.y * 0.52)
	position = _base
	var w := 620.0
	if _intro:
		_intro.size = Vector2(w, 270); _intro.position = Vector2((vp.x - w) * 0.5, vp.y * 0.24)
		_intro_lbl.position = Vector2(24, 20); _intro_lbl.size = Vector2(w - 48, 230)
	if _result:
		_result.size = Vector2(w, 250); _result.position = Vector2((vp.x - w) * 0.5, vp.y * 0.26)
		_result_lbl.position = Vector2(24, 20); _result_lbl.size = Vector2(w - 48, 210)
	if _tut:
		var tw := 820.0
		_tut.size = Vector2(tw, 62); _tut.position = Vector2((vp.x - tw) * 0.5, 44)
		_tut_lbl.position = Vector2(16, 8); _tut_lbl.size = Vector2(tw - 32, 46)


func _process(dt: float) -> void:
	_t += dt
	_shake = maxf(0.0, _shake - dt * 22.0)
	position = _base + Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0) * _shake
	if _toast_t > 0.0:
		_toast_t -= dt
	for f in _splash:
		f["t"] += dt
	if not _splash.is_empty():
		_splash = _splash.filter(func(f): return f["t"] < f["life"])
	if running and s.state == Shape.PLAYING:
		s.update(dt)
		_drain()
		_advance_tut()
		if _hold:
			_hold_cd -= dt
			if _hold_cd <= 0.0:
				_hold_cd = REPEAT_EVERY
				_try_deposit(get_local_mouse_position())
		if s.state != Shape.PLAYING:
			_show_result()
	if _seal_btn:
		_seal_btn.disabled = not s.can_seal()
		_seal_btn.text = "CHỐT\n%s" % ("khớp rồi!" if s.can_seal() else "cần %d%% khớp" % int(Shape.WIN_IOU * 100))
	_update_tut()
	queue_redraw()


func _advance_tut() -> void:
	match tut_step:
		0: if s.budget < s.budget_max - Shape.DOSE * 2.0: tut_step = 1
		1: if s.cover > 0.25: tut_step = 2
		2: if s.spill > 0.20 or s.cover > 0.55: tut_step = 3
		3: if s.elapsed > s.time_limit * 0.18: tut_step = 4
		4: if s.can_seal(): tut_step = 5
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
	for e in s.events:
		match e.get("kind"):
			"mold":
				_splash.append({"pos": e["pos"], "r": Shape.MOLD_R0, "t": 0.0, "life": 1.2, "kind": "mold"})
				_flash("MỐC BÉN VÀO! Chỗ dinh dưỡng giàu mà khuẩn chưa tới là niche trống — bào tử nấm chiếm ngay và ăn sạch chỗ đó.", Color(0.72, 0.82, 0.4))
			"warn":
				_flash("⚠ %s sắp tới — chỗ khoanh vàng sẽ mất thức ăn!" % _evname(e["ev"]), Color(0.95, 0.78, 0.35))
			"event":
				var lost: float = e.get("lost", 0.0)
				if e["ev"] == "drip":
					_splash.append({"pos": e["pos"], "r": Shape.DRIP_R, "t": 0.0, "life": 0.9, "kind": "drip"})
					_flash("GIỌT NGƯNG TỤ rơi xuống — rửa trôi mất %.0f phần thức ăn ở đó." % lost, Color(0.55, 0.8, 0.95))
				else:
					_flash("THẠCH KHÔ một mảng — thức ăn rải vào đó sẽ tàn rất nhanh, đi vòng qua.", Color(0.8, 0.62, 0.4))
				_shake = minf(_shake + 4.0, 8.0)
	s.events.clear()


func _evname(ev: String) -> String:
	return "Giọt ngưng tụ" if ev == "drip" else "Vùng khô"


func _flash(msg: String, col: Color) -> void:
	_toast = msg; _toast_col = col; _toast_t = 5.5


# ─────────────────────────── vẽ ───────────────────────────

func _draw() -> void:
	draw_circle(Vector2.ZERO, Shape.DISH_R + 8.0, C_GLASS)
	draw_circle(Vector2.ZERO, Shape.DISH_R, C_DISH)
	draw_arc(Vector2.ZERO, Shape.DISH_R, 0, TAU, 96, C_RIM, 2.0, true)

	_draw_score_grid()
	_draw_nut()
	for d in s.dries:
		draw_circle(d["pos"], d["r"], Color(C_DRY, 0.13))
		draw_arc(d["pos"], d["r"], 0, TAU, 40, Color(C_DRY, 0.4), 1.5, true)
	for m in s.molds:
		_draw_mold(m)
	_draw_nodes()
	for a in s.c.agents:
		_draw_agent(a)
	_draw_warn()
	_draw_splash()
	if running and s.state == Shape.PLAYING and not _intro.visible:
		_draw_cursor()
	_draw_panel()


## Một vòng qua lưới, vẽ luôn cả ba trạng thái điểm — đây là "bảng điểm sống".
func _draw_score_grid() -> void:
	var cell: float = Shape.CELL
	var half := cell * 0.5
	for i in s.mask.size():
		var m: int = s.mask[i]
		var cl: int = s.claimed[i]
		if m == 0 and cl == 0:
			continue
		var col: Color
		if m == 1 and cl == 1:
			col = Color(C_HIT, 0.55)
		elif m == 1:
			col = Color(C_TARGET, 0.13)
		else:
			col = Color(C_SPILL, 0.40)
		var w := Vector2((i % Shape.NF + 0.5) * cell - Shape.DISH_R,
			(i / Shape.NF + 0.5) * cell - Shape.DISH_R)
		draw_rect(Rect2(w - Vector2(half, half), Vector2(cell, cell)), col)


func _draw_nut() -> void:
	var cell: float = Shape.CELL
	var half := cell * 0.5
	for i in s.c.nut.size():
		var v: float = s.c.nut[i]
		if v <= 0.05:
			continue
		var w := Vector2((i % Shape.NF + 0.5) * cell - Shape.DISH_R,
			(i / Shape.NF + 0.5) * cell - Shape.DISH_R)
		draw_rect(Rect2(w - Vector2(half, half), Vector2(cell, cell)),
			Color(C_NUT, clampf(v, 0.0, 1.0) * 0.40))


func _draw_mold(m: Dictionary) -> void:
	var r: float = m["r"]
	draw_circle(m["pos"], r, Color(C_MOLD, 0.42))
	draw_arc(m["pos"], r, 0, TAU, 32, Color(C_MOLD, 0.85), 2.0, true)
	# sợi nấm lởm chởm cho dễ nhận
	for k in 9:
		var a := TAU * k / 9.0 + _t * 0.25
		var d := Vector2(cos(a), sin(a))
		draw_line(m["pos"] + d * r * 0.75, m["pos"] + d * (r + 5.0), Color(C_MOLD, 0.8), 1.5)


func _draw_nodes() -> void:
	for n in s.nodes():
		draw_arc(n, Shape.NODE_R, 0, TAU, 36, Color(C_TARGET, 0.55), 2.0, true)
	for l in s.links():
		var a: Vector2 = s.nodes()[l[0]]
		var b: Vector2 = s.nodes()[l[1]]
		draw_line(a, b, Color(C_TARGET, 0.18), 1.5)


func _draw_agent(a: Dictionary) -> void:
	var col := Color(0.62, 0.88, 0.98)
	match a["state"]:
		AgentColony.EAT: col = Color(0.45, 0.92, 0.5)
		AgentColony.DIVIDE: col = Color(0.98, 0.85, 0.35)
		AgentColony.DORMANT: col = Color(0.55, 0.55, 0.6)
	if _body == null:
		draw_circle(a["pos"], 3.0, col)
		return
	var sz := _body.get_size()
	draw_set_transform(a["pos"], a["heading"].angle(), Vector2(0.85, 0.85))
	draw_texture(_body, -sz * 0.5, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Vòng khoanh chỗ biến cố SẮP rơi — báo trước nên người chơi né được.
func _draw_warn() -> void:
	for e in s._sched:
		if e["warned"] and not e["fired"]:
			var r: float = Shape.DRIP_R if e["kind"] == "drip" else Shape.DRY_R
			var p := 0.5 + 0.5 * sin(_t * 7.0)
			draw_arc(e["pos"], r, 0, TAU, 40, Color(0.95, 0.78, 0.35, 0.35 + p * 0.5), 2.5, true)
			draw_string(_font, e["pos"] + Vector2(-14, -r - 8), "⚠",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.78, 0.35))


func _draw_splash() -> void:
	for f in _splash:
		var k: float = f["t"] / f["life"]
		var col := Color(0.6, 0.85, 1.0) if f["kind"] == "drip" else C_MOLD
		draw_arc(f["pos"], f["r"] * (0.3 + k * 1.1), 0, TAU, 40, Color(col, (1.0 - k) * 0.9), 3.0, true)


## Con trỏ = cái cọ: đúng bán kính rải thật, đổi màu theo TẦM VỚI của khuẩn lạc.
func _draw_cursor() -> void:
	var m := get_local_mouse_position()
	if m.length() > Shape.DISH_R - 8.0:
		return
	var ok: bool = s.reach_ok(m) and s.budget >= Shape.DOSE
	var col := Color(0.45, 0.92, 0.6) if ok else Color(0.95, 0.72, 0.3)
	draw_arc(m, AgentColony.DEPOSIT_R, 0, TAU, 32, Color(col, 0.75), 1.5, true)
	draw_circle(m, 2.5, col)
	if not ok:
		var why: String = "hết ngân sách" if s.budget < Shape.DOSE else "quá xa khuẩn → mốc sẽ bén"
		draw_string(_font, m + Vector2(-56, -AgentColony.DEPOSIT_R - 8), why,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)


## Bảng số bên phải đĩa.
func _draw_panel() -> void:
	var x := Shape.DISH_R + 44.0
	var y := -Shape.DISH_R + 10.0
	var spec: Dictionary = s.spec()
	draw_string(_font, Vector2(x, y), "HÌNH: %s" % spec["name"],
		HORIZONTAL_ALIGNMENT_LEFT, 240, 17, Color(0.75, 0.88, 0.98))
	draw_string(_font, Vector2(x, y + 20), spec["goal"],
		HORIZONTAL_ALIGNMENT_LEFT, 250, 12, Color(0.6, 0.68, 0.62))

	_meter(Vector2(x, y + 52), 210, s.cover, C_HIT, "PHỦ ĐÚNG", "%d%%" % int(s.cover * 100), [])
	_meter(Vector2(x, y + 96), 210, s.spill, C_SPILL, "TRÀN RA NGOÀI", "%d%%" % int(s.spill * 100), [])
	_meter(Vector2(x, y + 140), 210, s.iou, Color(0.55, 0.8, 0.95), "KHỚP (điểm)",
		"%d%%" % int(s.iou * 100), [Shape.WIN_IOU])
	_meter(Vector2(x, y + 184), 210, s.budget / maxf(1.0, s.budget_max), C_NUT,
		"THỨC ĂN CÒN", "%d nhát" % s.doses_left(), [])
	_meter(Vector2(x, y + 228), 210, s.mold_on_target / Shape.MOLD_LOSE, C_MOLD,
		"MỐC TRÊN HÌNH", "%d%%" % int(s.mold_on_target * 100), [1.0])

	draw_string(_font, Vector2(x, y + 276), "⏱ %ds / %ds" % [int(s.elapsed), int(s.time_limit)],
		HORIZONTAL_ALIGNMENT_LEFT, 210, 13, Color(0.6, 0.66, 0.58))
	draw_string(_font, Vector2(x, y + 300), "dân số %d" % s.c.population(),
		HORIZONTAL_ALIGNMENT_LEFT, 210, 12, Color(0.5, 0.56, 0.5))

	if _toast_t > 0.0:
		draw_string(_font, Vector2(-Shape.DISH_R, Shape.DISH_R + 30), _toast,
			HORIZONTAL_ALIGNMENT_LEFT, 640, 14, _toast_col)


func _meter(pos: Vector2, w: float, frac: float, col: Color, label: String,
		val: String, marks: Array) -> void:
	var h := 12.0
	draw_string(_font, pos + Vector2(0, -3), label, HORIZONTAL_ALIGNMENT_LEFT, 150, 12,
		Color(0.6, 0.66, 0.58))
	draw_string(_font, pos + Vector2(w - 60, -3), val, HORIZONTAL_ALIGNMENT_RIGHT, 60, 13, col)
	draw_rect(Rect2(pos + Vector2(0, 2), Vector2(w, h)), Color(0.05, 0.06, 0.05))
	draw_rect(Rect2(pos + Vector2(0, 2), Vector2(clampf(frac, 0, 1) * w, h)), col)
	for m in marks:
		var mx: float = pos.x + float(m) * w
		draw_line(Vector2(mx, pos.y), Vector2(mx, pos.y + h + 4), Color(0.95, 0.95, 0.95, 0.7), 2.0)


# ─────────────────────────── nhập liệu + HUD ───────────────────────────

func _try_deposit(m: Vector2) -> void:
	var why: String = s.deposit(m)
	if why != "":
		_flash(why, Color(0.95, 0.6, 0.4))


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if _intro.visible:
			if ev.pressed:
				_begin()
			return
		if s.state != Shape.PLAYING:
			return
		_hold = ev.pressed
		if ev.pressed:
			_hold_cd = REPEAT_EVERY
			_try_deposit(get_local_mouse_position())
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_R: _restart()
			KEY_T: _tut_on = not _tut_on
			KEY_SPACE: if _intro.visible: _begin()
			KEY_1: _load(0)
			KEY_2: _load(1)
			KEY_3: _load(2)


func _load(i: int) -> void:
	s.load_level(i)
	tut_step = 0 if i == 0 else TUT.size()
	_splash.clear()
	_show_intro()


func _restart() -> void:
	s.reset()
	tut_step = 0
	_splash.clear()
	_show_intro()


func _build_hud() -> void:
	_hud = CanvasLayer.new(); add_child(_hud)
	var back := CanvasLayer.new(); back.layer = -10; add_child(back)
	var bg := ColorRect.new(); bg.color = Color(0.045, 0.05, 0.055)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; back.add_child(bg)

	var title := Label.new()
	title.text = "MÀN MẠNG LƯỚI — rải thức ăn dẫn khuẩn lạc mọc PHỦ ĐÚNG HÌNH rồi CHỐT   ·   [1][2][3] đổi hình · [R] chơi lại · [T] hướng dẫn"
	title.position = Vector2(24, 14); title.add_theme_font_size_override("font_size", 14)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE; _hud.add_child(title)

	_tut = _mk_panel(Color(0.98, 0.92, 0.55, 0.85))
	_tut_lbl = Label.new()
	_tut_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tut_lbl.add_theme_font_size_override("font_size", 14)
	_tut.add_child(_tut_lbl)
	_tut.visible = false

	_seal_btn = Button.new()
	_seal_btn.custom_minimum_size = Vector2(200, 54)
	_seal_btn.add_theme_font_size_override("font_size", 16)
	_seal_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_seal_btn.offset_left = -240; _seal_btn.offset_top = -84
	_seal_btn.offset_right = -40; _seal_btn.offset_bottom = -30
	_seal_btn.pressed.connect(_do_seal)
	_hud.add_child(_seal_btn)

	_intro = _mk_panel(Color(0.55, 0.85, 0.95, 0.9))
	_intro_lbl = _mk_rich(_intro, 15)
	_result = _mk_panel(Color(0.85, 0.78, 0.5, 0.9))
	_result_lbl = _mk_rich(_result, 15)
	_result.visible = false


func _mk_panel(border: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.09, 0.97); sb.set_corner_radius_all(10)
	sb.border_color = border; sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	_hud.add_child(p); return p


func _mk_rich(panel: Panel, size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true; r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", size)
	panel.add_child(r); return r


func _do_seal() -> void:
	if _intro.visible:
		_begin()
		return
	if s.can_seal():
		s.seal()
		_show_result()
	else:
		_flash("Hình chưa khớp đủ %d%% — phủ thêm (hoặc bớt tràn) rồi mới chốt được." % int(Shape.WIN_IOU * 100),
			Color(0.95, 0.75, 0.35))


func _show_intro() -> void:
	running = false; _result.visible = false; _intro.visible = true
	var spec: Dictionary = s.spec()
	_intro_lbl.text = "[b]Hình %d — %s[/b]\n\n[b]Đích:[/b] %s Dẫn khuẩn lạc mọc phủ đúng hình xanh, đạt [b]%d%% khớp[/b] rồi bấm CHỐT.\n\n[b]Mẹo:[/b] %s\n\n[color=#c8b45a]Khó khăn: mốc bén vào thức ăn bỏ hoang · giọt nước rửa trôi · thạch khô.[/color]\n\n[color=#f7dc5c]▶ Bấm chuột hoặc [Space] để bắt đầu[/color]" % [
		s.level + 1, spec["name"], spec["goal"], int(Shape.WIN_IOU * 100), spec["lesson"]]


func _begin() -> void:
	_intro.visible = false; running = true
	_flash("Việc đầu: rải sát ổ khuẩn, lấn dần theo hình. Con trỏ xanh là rải được.", Color(0.6, 0.9, 0.7))


func _show_result() -> void:
	running = false; _result.visible = true; _hold = false
	if s.state == Shape.WON:
		var st: int = s.stars()
		_result_lbl.text = "[b]Mạng lưới thành hình![/b]  %s\n\nKhớp [b]%d%%[/b] — phủ %d%%, tràn %d%%, còn %d nhát thức ăn.\n\nBạn không vẽ cái hình này: bạn [b]lái một quá trình mọc[/b] có độ trễ và quán tính. Khuẩn chỉ cảm được thức ăn ở gần và chỉ lấn được ở rìa — nên hình phải dựng từng chặng.\n\n[color=#9fb4c8][R] chơi lại · [1][2][3] đổi hình[/color]" % [
			"★".repeat(st) + "☆".repeat(5 - st), int(s.iou * 100), int(s.cover * 100),
			int(s.spill * 100), s.doses_left()]
	else:
		_result_lbl.text = "[b]Hỏng[/b] — %s\n\nKhớp được %d%% (phủ %d%%, tràn %d%%).\n\nRải sát rìa đang mọc rồi ĐỢI; ném thức ăn xa quá là bỏ mồi cho mốc, mà rải quá tay thì khuẩn mọc tràn ra ngoài hình — vệt đã mọc không rút lại được.\n\n[color=#9fb4c8][R] chơi lại · [1][2][3] đổi hình[/color]" % [
			s.lose_reason, int(s.iou * 100), int(s.cover * 100), int(s.spill * 100)]
