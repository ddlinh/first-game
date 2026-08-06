extends Node2D

## Phần vẽ + nhập liệu + tutorial + THẺ CHỦNG/SỔ TAY. Mỗi con khuẩn được nhân hoá
## (mắt + biểu cảm theo việc). Mỗi màn là một CHỦNG có thật (game giới thiệu, người
## chơi không chọn): vào màn hiện thẻ chủng + áp đặc tính, sổ tay điền dần. Người chơi
## chỉ rải thức ăn; biofilm khuẩn TỰ kết khi đủ đông (quorum). Luật ở agent_colony.gd.

const AgentColony := preload("res://proto2/agent_colony.gd")
const Strains := preload("res://proto2/strains.gd")

var col
var _font: Font
var _t := 0.0
var _painting := false        ## đang GIỮ-KÉO rải (cọ)

# sprite pixel-art (bake bằng bake_sprites.gd → proto2/sprites/*.png)
var _tex_phage: Texture2D
var _tex_rival: Texture2D
var _tex_spear: Texture2D
var _tex_spore: Texture2D
var _strain_tex: Array = []   ## thân RIÊNG từng chủng (theo thứ tự Strains.LIST)
var _body: Texture2D          ## thân của chủng màn này
var _rod := false             ## chủng này là trực khuẩn (xoay theo hướng bơi)?
var _is_bacillus := false     ## chủng tạo BÀO TỬ → con ngủ đông hiện endospore

# hiệu ứng combat + rung màn + âm thanh
var _fx: Array = []            ## {pos, kind, t, life, seed}
var _shake := 0.0
var _base_pos := Vector2.ZERO
var _players: Array = []
var _sounds := {}

var strain_idx := 0
var _met := {}
var _card_shown := true
var _book_shown := false

# tutorial dẫn dắt (chỉ chủng đầu)
var tut_step := 0
var _nut_placed := 0
var _biofilm_seen := false
var _tut_timer := 0.0
# toast/popup giải thích
var _toast := ""
var _toast_t := 0.0
var _toast_col := Color(1, 0.6, 0.6)

var _hud: CanvasLayer
var _tally: Label
var _legend: RichTextLabel
var _toast_lbl: Label
var _tut_panel: Panel
var _tut_label: Label
var _card_panel: Panel
var _card_lbl: RichTextLabel
var _book_panel: Panel
var _book_lbl: RichTextLabel

const BODY_R := 7.0
const DAB := 10.0             ## rải một nhấp chuột
const PAINT_RATE := 46.0      ## rải/giây khi GIỮ-KÉO (cọ vẽ dinh dưỡng)
const COLORS := {
	AgentColony.FORAGE: Color(0.46, 0.72, 0.96),
	AgentColony.EAT: Color(0.50, 0.90, 0.56),
	AgentColony.DIVIDE: Color(0.97, 0.86, 0.36),
	AgentColony.DORMANT: Color(0.56, 0.56, 0.63),
	AgentColony.DEFEND: Color(0.74, 0.46, 0.96),
	AgentColony.INFECTED: Color(0.97, 0.40, 0.40),
	AgentColony.BUILD: Color(0.90, 0.62, 0.34),
	AgentColony.STAB: Color(0.98, 0.52, 0.28),
}
const NUTRIENT_COL := Color(0.86, 0.70, 0.32)
const WASTE_COL := Color(0.52, 0.50, 0.40)
const PHAGE_COL := Color(0.97, 0.32, 0.56)
const SYMBIONT_COL := Color(0.35, 0.90, 0.80)
const MATRIX_COL := Color(0.40, 0.68, 0.60)
const BUILD_VIS_R := 18.0
const EYE := Color(0.05, 0.05, 0.08)

const C_BACKDROP := Color(0.022, 0.028, 0.022)
const C_GLASS := Color(0.10, 0.12, 0.10)
const C_DISH := Color(0.036, 0.048, 0.038)
const C_RIM := Color(0.56, 0.62, 0.44, 0.20)

const TUT := [
	"Rải THỨC ĂN: bấm — hoặc GIỮ & KÉO để VẼ vệt (ngân sách 'Dinh dưỡng %' có hạn, tự hồi). Khuẩn bơi theo vệt tới ĂN (xanh lá) rồi PHÂN ĐÔI (vàng). Rải ĐÓN ĐẦU rìa đang mọc cho khỏi phí.",
	"Giờ cứ rải THÊM vào MỘT CHỖ để dồn khuẩn lại thật ĐÔNG — đủ đông thì chúng sẽ tự làm một điều đặc biệt…",
	"Cứ nuôi tiếp! Phế phẩm đọng sẽ hút CROSS-FEEDER (cyan); khuẩn đông thì PHAGE (hồng) bén vào — biofilm che chở.",
]


func _ready() -> void:
	col = AgentColony.new(4242)
	_font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel-art: không làm nhoè
	_load_sprites()
	_build_audio()
	_build_hud()
	_place()
	get_viewport().size_changed.connect(_place)
	_enter_strain(0)


func _load_sprites() -> void:
	# Nạp thẳng từ PNG (bỏ qua import pipeline → chạy được headless, không cần .import).
	# Thân riêng từng chủng, khớp thứ tự Strains.LIST (E. coli, Staph, Proteus, Bacillus).
	_strain_tex = [
		_load_png("cell_ecoli"), _load_png("cell_staph"),
		_load_png("cell_proteus"), _load_png("cell_bacillus"),
	]
	_tex_phage = _load_png("phage")
	_tex_rival = _load_png("rival")
	_tex_spear = _load_png("spear")
	_tex_spore = _load_png("spore")
	_body = _strain_tex[0]


func _load_png(name: String) -> Texture2D:
	var img := Image.new()
	var err := img.load("res://proto2/sprites/%s.png" % name)
	if err != OK:
		push_error("Không nạp được sprite %s — chạy bake_sprites.gd trước." % name)
		return null
	return ImageTexture.create_from_image(img)


## Vẽ một sprite tâm tại pos, xoay `angle`, nhân màu `mod`, phóng `scale`.
func _blit(tex: Texture2D, pos: Vector2, angle: float = 0.0,
		mod: Color = Color.WHITE, scale: float = 1.0) -> void:
	if tex == null:
		return
	var sz := tex.get_size()
	draw_set_transform(pos, angle, Vector2(scale, scale))
	draw_texture(tex, -sz * 0.5, mod)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _enter_strain(i: int) -> void:
	strain_idx = i
	var s: Dictionary = Strains.LIST[i]
	col.set_environment(s["mot"], s["hard"], s["rich"])
	# Hình thái theo chủng: sprite riêng + cờ để vẽ đúng nét (que xoay, bào tử…).
	_body = _strain_tex[i] if i < _strain_tex.size() and _strain_tex[i] != null else _strain_tex[0]
	_rod = s["mot"] >= AgentColony.SESSILE_THRESH   # có tiên mao → trực khuẩn (xoay theo hướng bơi)
	_is_bacillus = s["name"].begins_with("Bacillus")
	col.reset()
	_met[i] = true
	_nut_placed = 0
	_biofilm_seen = false
	_toast_t = 0.0
	tut_step = 0 if i == 0 else TUT.size()   # chỉ chủng đầu có tutorial dẫn dắt
	_card_shown = true
	_book_shown = false


func _place() -> void:
	var vp := get_viewport_rect().size
	_base_pos = Vector2(vp.x * 0.5, vp.y * 0.5 - 8.0)
	position = _base_pos
	if _tut_panel:
		var w := 700.0
		var h := 96.0
		_tut_panel.size = Vector2(w, h)
		_tut_panel.position = Vector2((vp.x - w) * 0.5, vp.y - h - 22.0)
		_tut_label.position = Vector2(18, 12)
		_tut_label.size = Vector2(w - 36, h - 24)
	_center_panel(_card_panel, _card_lbl, vp, 660, 300)
	_center_panel(_book_panel, _book_lbl, vp, 660, 360)


func _center_panel(panel: Panel, lbl: RichTextLabel, vp: Vector2, w: float, h: float) -> void:
	if panel == null:
		return
	panel.size = Vector2(w, h)
	panel.position = Vector2((vp.x - w) * 0.5, (vp.y - h) * 0.5 - 16.0)
	lbl.position = Vector2(22, 20)
	lbl.size = Vector2(w - 44, h - 40)


func _process(delta: float) -> void:
	_t += delta
	for f in _fx:
		f["t"] += delta
	if not _fx.is_empty():
		_fx = _fx.filter(func(f): return f["t"] < f["life"])
	_shake = maxf(0.0, _shake - delta * 22.0)
	position = _base_pos + Vector2(randf() * 2.0 - 1.0, randf() * 2.0 - 1.0) * _shake
	if not _card_shown and not _book_shown:
		col.update(delta)
		_drain_events()
		_advance_tutorial(delta)
		if _painting:                      # cọ: rải liên tục theo con trỏ khi giữ chuột
			var m := get_local_mouse_position()
			if m.length() < AgentColony.DISH_R - 6.0:
				col.deposit(m, PAINT_RATE * delta)
	if _toast_t > 0.0:
		_toast_t -= delta
	_update_hud()
	queue_redraw()


func _drain_events() -> void:
	for e in col.events:
		match e.get("kind"):
			"toxin":
				_spawn_fx(e["pos"], "toxin")
			"infect":
				_spawn_fx(e["pos"], "infect")
			"lyse":
				_spawn_fx(e["pos"], "lyse")
				_shake = minf(_shake + 2.2, 7.0)
			"biofilm_formed":
				_biofilm_seen = true
				_toast = "BIOFILM TỰ THÀNH!  Khuẩn đủ đông thì 'đếm' được mật độ của nhau (quorum sensing) rồi cùng tiết chất nền dựng pháo đài — che chở khỏi phage."
				_toast_col = Color(0.5, 0.92, 0.78)
				_toast_t = 8.0
				_play("biofilm_formed")
			"phage_wave":
				_toast = "Khuẩn lạc đông (%d con) → phage từ môi trường BÉN VÀO đĩa. Phage cần mật độ vật chủ cao mới lây." % e["pop"]
				_toast_col = Color(1.0, 0.55, 0.55)
				_toast_t = 6.0
				_shake = minf(_shake + 4.0, 8.0)
				_play("phage_wave")
			"crossfeeder":
				_toast = "Phế phẩm đọng → một chủng CROSS-FEEDER trôi tới bén rễ: nó ĂN phế phẩm và TÁI CHẾ thành dinh dưỡng cho bạn."
				_toast_col = Color(0.5, 0.95, 0.85)
				_toast_t = 6.0
				_play("crossfeeder")
			"t6ss":
				_spawn_fx(e["pos"], "t6ss", e.get("to", e["pos"]))
			"rival":
				_toast = "Khuẩn lạc thịnh (%d con) → một CHỦNG ĐỐI THỦ trôi vào tranh niche. Khuẩn nhà diệt nó bằng T6SS — cây giáo ĐÂM-CHẠM (khác colicin khuếch tán)." % e["pop"]
				_toast_col = Color(1.0, 0.62, 0.4)
				_toast_t = 6.5
				_shake = minf(_shake + 2.5, 8.0)
				_play("rival")
	col.events.clear()


func _advance_tutorial(delta: float) -> void:
	match tut_step:
		0: if _nut_placed >= 1: tut_step = 1
		1: if _biofilm_seen: tut_step = 2; _tut_timer = 10.0
		2:
			_tut_timer -= delta
			if _tut_timer <= 0.0:
				tut_step = 3


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_N: _enter_strain((strain_idx + 1) % Strains.LIST.size())
			KEY_B: _book_shown = not _book_shown
			KEY_R: _restart()
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
				if _card_shown:
					_card_shown = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _card_shown:
				_card_shown = false
				return
			if _book_shown:
				_book_shown = false
				return
			_painting = true
			var p := to_local(event.position)
			if p.length() < AgentColony.DISH_R - 6.0:
				col.deposit(p, DAB)         # nhấp = một dấu; giữ-kéo = vẽ vệt
				_nut_placed += 1
		else:
			_painting = false


func _restart() -> void:
	col.reset()
	_nut_placed = 0
	_biofilm_seen = false
	_toast_t = 0.0
	if strain_idx == 0:
		tut_step = 0


# ─────────────────────────── vẽ ───────────────────────────

func _draw() -> void:
	draw_circle(Vector2.ZERO, AgentColony.DISH_R + 8.0, C_GLASS)
	draw_circle(Vector2.ZERO, AgentColony.DISH_R, C_DISH)
	draw_arc(Vector2.ZERO, AgentColony.DISH_R, 0, TAU, 96, C_RIM, 2.0, true)

	_draw_field()
	_draw_waste()
	for b in col.buildings:
		_draw_building(b)
	for c in col.crossfeeders:
		_draw_symbiont(c["pos"])
	for c in col.rivals:
		_draw_rival(c)
	for p in col.phages:
		_draw_phage(p["pos"])
	for a in col.agents:
		_draw_agent(a)
	_draw_fx()
	if not _card_shown and not _book_shown:
		_draw_ghost()
		_draw_hover()


func _draw_field() -> void:
	var nf := AgentColony.NF
	var cell: float = AgentColony.CELL
	var half := cell * 0.5
	for cy in nf:
		for cx in nf:
			var v: float = col.nut[cy * nf + cx]
			if v <= 0.04:
				continue
			var c := Vector2((cx + 0.5) * cell - AgentColony.DISH_R, (cy + 0.5) * cell - AgentColony.DISH_R)
			draw_rect(Rect2(c - Vector2(half, half), Vector2(cell, cell)),
				Color(NUTRIENT_COL, clampf(v, 0.0, 1.0) * 0.42))


func _draw_waste() -> void:
	var nf := AgentColony.NF
	var cell: float = AgentColony.CELL
	var half := cell * 0.5
	for cy in nf:
		for cx in nf:
			var v: float = col.waste[cy * nf + cx]
			if v <= 0.06:
				continue
			var c := Vector2((cx + 0.5) * cell - AgentColony.DISH_R, (cy + 0.5) * cell - AgentColony.DISH_R)
			draw_rect(Rect2(c - Vector2(half, half), Vector2(cell, cell)),
				Color(WASTE_COL, clampf(v, 0.0, 1.0) * 0.30))


func _draw_building(b: Dictionary) -> void:
	var pos: Vector2 = b["pos"]
	draw_arc(pos, AgentColony.SHELTER_R, 0, TAU, 40,
		Color(MATRIX_COL, 0.5 if b["active"] else 0.18), 1.5, true)
	if b["active"]:
		draw_circle(pos, BUILD_VIS_R, MATRIX_COL)
		draw_arc(pos, BUILD_VIS_R * 0.62, 0, TAU, 24, Color(0.15, 0.28, 0.26, 0.7), 2.0, true)
	else:
		draw_arc(pos, BUILD_VIS_R, 0, TAU, 32, Color(MATRIX_COL, 0.5), 1.5, true)
		draw_circle(pos, BUILD_VIS_R * b["progress"], Color(MATRIX_COL, 0.55))


func _draw_symbiont(pos: Vector2) -> void:
	draw_circle(pos, 12.0, Color(SYMBIONT_COL, 0.10))
	for i in 5:
		var a := TAU * i / 5.0 + _t * 0.6
		draw_circle(pos + Vector2(cos(a), sin(a)) * 6.5, 2.6, SYMBIONT_COL)
	draw_circle(pos, 4.0, SYMBIONT_COL.lerp(Color(1, 1, 1), 0.3))


func _draw_phage(pos: Vector2) -> void:
	var bob := sin(_t * 7.0 + pos.x * 0.3) * 0.7
	_blit(_tex_phage, pos + Vector2(0, bob), 0.0, Color.WHITE, 1.0)


func _draw_rival(c: Dictionary) -> void:
	# Kẻ xâm lấn: gai góc, khẽ rung để ra chất địch.
	var jitter := Vector2(sin(_t * 20.0 + c["pos"].y), cos(_t * 17.0 + c["pos"].x)) * 0.6
	_blit(_tex_rival, c["pos"] + jitter, 0.0, Color.WHITE, 1.25)


func _draw_agent(a: Dictionary) -> void:
	var pos: Vector2 = a["pos"]
	var st: int = a["state"]
	var base: Color = COLORS[st]
	if st == AgentColony.DEFEND:                    # colicin: đám mây khuếch tán (tầm xa)
		draw_arc(pos, AgentColony.TOXIN_RADIUS, 0, TAU, 28, Color(base, 0.20), 2.0, true)
	if st == AgentColony.INFECTED:
		base = base.lerp(Color(1, 1, 1), (0.5 + 0.5 * sin(_t * 18.0)) * 0.3)
	var ang := 0.0
	if _rod:
		var dir: Vector2 = a["vel"] if a["vel"].length() > 6.0 else a["heading"]
		if dir.length() > 0.01:
			ang = dir.angle()
	if _is_bacillus and st == AgentColony.DORMANT:  # đói → Bacillus tạo BÀO TỬ (endospore)
		_blit(_body, pos, ang, base.darkened(0.25))
		_blit(_tex_spore, pos, ang)                 # oval sáng phase-bright, không tint
		return
	if st == AgentColony.DIVIDE:                    # đang tách đôi dọc trục dài
		var along := Vector2(cos(ang), sin(ang))
		_blit(_body, pos + along * 4.0, ang, base)
		_blit(_body, pos - along * 4.0, ang, base)
	else:
		_blit(_body, pos, ang, base)
	_face(pos, st, base, a["vel"])


func _face(pos: Vector2, st: int, base: Color, vel: Vector2) -> void:
	if st == AgentColony.FORAGE and vel.length() > 6.0:
		draw_line(pos, pos - vel.normalized() * 10.0, Color(base, 0.5), 1.5)
	var eyeL := pos + Vector2(-2.6, -1.4)
	var eyeR := pos + Vector2(2.6, -1.4)
	if st == AgentColony.DORMANT:
		draw_line(eyeL - Vector2(1.5, 0), eyeL + Vector2(1.5, 0), Color(0, 0, 0, 0.6), 1.2)
		draw_line(eyeR - Vector2(1.5, 0), eyeR + Vector2(1.5, 0), Color(0, 0, 0, 0.6), 1.2)
		return
	var look := (vel.normalized() * 1.2) if vel.length() > 3.0 else Vector2.ZERO
	var er := 1.0 if st == AgentColony.INFECTED else 1.1
	draw_circle(eyeL, 2.1, Color(1, 1, 1, 0.95))
	draw_circle(eyeR, 2.1, Color(1, 1, 1, 0.95))
	draw_circle(eyeL + look, er, EYE)
	draw_circle(eyeR + look, er, EYE)
	var m := pos + Vector2(0, 3.2)
	match st:
		AgentColony.EAT, AgentColony.DIVIDE:
			_mouth(m, [Vector2(-2, -0.4), Vector2(0, 1.2), Vector2(2, -0.4)])
		AgentColony.DEFEND, AgentColony.STAB:
			_mouth(m, [Vector2(-2, 1.0), Vector2(0, -0.4), Vector2(2, 1.0)])
		AgentColony.INFECTED:
			draw_circle(m, 1.3, Color(0, 0, 0, 0.55))
		_:
			draw_line(m - Vector2(1.6, 0), m + Vector2(1.6, 0), Color(0, 0, 0, 0.5), 1.2)


func _mouth(m: Vector2, pts: Array) -> void:
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(m + p)
	draw_polyline(poly, Color(0, 0, 0, 0.6), 1.3, true)


func _draw_ghost() -> void:
	var mm := get_local_mouse_position()
	if mm.length() < AgentColony.DISH_R - 6.0:
		var frac: float = col.nutrient_budget / AgentColony.NUT_BUDGET_MAX
		# hết ngân sách → cọ đỏ mờ; còn thì vàng dinh dưỡng, đậm hơn khi đang vẽ
		var ring := Color(0.9, 0.4, 0.3, 0.6) if frac < 0.06 else Color(NUTRIENT_COL, 0.7 if _painting else 0.5)
		draw_arc(mm, 15.0, 0, TAU, 20, ring, 2.0 if _painting else 1.5, true)
		if frac >= 0.06:
			draw_circle(mm, 15.0 * frac, Color(NUTRIENT_COL, 0.12))   # lõi = còn bao nhiêu ngân sách


func _draw_hover() -> void:
	var m := get_local_mouse_position()
	var best = null
	var best_d := 18.0 * 18.0
	for a in col.agents:
		var d: float = m.distance_squared_to(a["pos"])
		if d < best_d:
			best_d = d
			best = a
	if best == null:
		return
	var pos: Vector2 = best["pos"]
	draw_arc(pos, 11.0, 0, TAU, 20, Color(1, 1, 1, 0.8), 1.5, true)
	var label: String = AgentColony.STATE_NAME[best["state"]]
	var box := Vector2(pos.x + 12, pos.y - 22)
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 12
	draw_rect(Rect2(box, Vector2(w, 20)), Color(0, 0, 0, 0.7))
	draw_string(_font, box + Vector2(6, 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLORS[best["state"]])


# ─────────────────────────── HUD ───────────────────────────

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)

	var back_layer := CanvasLayer.new()
	back_layer.layer = -10
	add_child(back_layer)
	var bg := ColorRect.new()
	bg.color = C_BACKDROP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_layer.add_child(bg)

	_tally = _mk_label(Vector2(24, 14), 15)

	_legend = _mk_rich(Vector2(24, 40), 1180)
	_legend.text = "[b]Màu = việc mỗi con:[/b]  [color=#75b8f5]kiếm ăn[/color] · [color=#80e58f]ăn[/color] · [color=#f7dc5c]phân đôi[/color] · [color=#e59c57]xây[/color] · [color=#bd75f5]phòng thủ (colicin)[/color] · [color=#fa8547]đâm (T6SS)[/color] · [color=#8f8fa0]ngủ đông[/color] · [color=#f76666]nhiễm[/color]   |   [color=#dcb352]thức ăn[/color] · [color=#857f66]phế phẩm[/color] · [color=#66ad99]biofilm[/color] · [color=#f7528f]phage[/color] · [color=#f79e4d]đối thủ[/color] · [color=#59e6cc]cross-feeder[/color]"

	_toast_lbl = Label.new()
	_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast_lbl.offset_top = 74
	_toast_lbl.offset_bottom = 106
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_font_size_override("font_size", 17)
	_toast_lbl.visible = false
	_hud.add_child(_toast_lbl)

	_tut_panel = _mk_panel(Color(0.98, 0.92, 0.55, 0.85))
	_tut_label = Label.new()
	_tut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tut_label.add_theme_font_size_override("font_size", 16)
	_tut_panel.add_child(_tut_label)

	_card_panel = _mk_panel(Color(0.55, 0.85, 0.95, 0.9))
	_card_lbl = _mk_rich_in(_card_panel, 16)
	_book_panel = _mk_panel(Color(0.85, 0.78, 0.5, 0.9))
	_book_lbl = _mk_rich_in(_book_panel, 15)


func _mk_label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	_hud.add_child(l)
	return l


func _mk_rich(pos: Vector2, w: float) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.bbcode_enabled = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.fit_content = true
	r.position = pos
	r.custom_minimum_size = Vector2(w, 26)
	r.add_theme_font_size_override("normal_font_size", 14)
	_hud.add_child(r)
	return r


func _mk_panel(border: Color) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.10, 0.96)
	sb.set_corner_radius_all(10)
	sb.border_color = border
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	_hud.add_child(p)
	return p


func _mk_rich_in(panel: Panel, size: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.bbcode_enabled = true
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", size)
	panel.add_child(r)
	return r


func _update_hud() -> void:
	if _tally == null:
		return
	var s: Dictionary = Strains.LIST[strain_idx]
	var t: Dictionary = col.tally()
	_tally.text = "CHỦNG: %s   |   Dinh dưỡng %d%%   |   Dân số %d · ăn %d · phân đôi %d · thủ %d · đâm %d · nhiễm %d   |   phage %d · đối thủ %d · cross-feeder %d · biofilm %d      [N] đổi chủng · [B] sổ tay" % [
		s["name"], int(col.nutrient_budget / AgentColony.NUT_BUDGET_MAX * 100.0),
		col.population(), t[AgentColony.EAT], t[AgentColony.DIVIDE],
		t[AgentColony.DEFEND], t[AgentColony.STAB], t[AgentColony.INFECTED],
		col.phages.size(), col.rivals.size(), col.crossfeeders.size(), col.buildings.size()]

	_toast_lbl.visible = _toast_t > 0.0 and not _card_shown and not _book_shown
	if _toast_lbl.visible:
		_toast_lbl.text = _toast
		_toast_lbl.modulate = _toast_col

	_card_panel.visible = _card_shown
	if _card_shown:
		_card_lbl.text = "[b]%s[/b]    [i]%s[/i]\n\n%s\n\n[color=#9fb4c8]%s[/color]\n\n[color=#f7dc5c]Bấm chuột / [Space] để bắt đầu[/color]      ·      [N] đổi chủng   ·   [B] sổ tay" % [
			s["name"], s["latin"], s["trait"], s["note"]]

	_book_panel.visible = _book_shown
	if _book_shown:
		var txt := "[b]SỔ TAY VI KHUẨN[/b]   (gặp %d/%d chủng)\n\n" % [_met.size(), Strains.LIST.size()]
		for i in Strains.LIST.size():
			var st: Dictionary = Strains.LIST[i]
			if _met.has(i):
				txt += "[b]%s[/b]  [i]%s[/i]\n    %s\n\n" % [st["name"], st["latin"], st["trait"]]
			else:
				txt += "[color=#666]??? — chưa gặp[/color]\n\n"
		txt += "[color=#9fb4c8][B] đóng[/color]"
		_book_lbl.text = txt

	var show_tut: bool = not _card_shown and not _book_shown and tut_step < TUT.size()
	_tut_panel.visible = show_tut
	if show_tut:
		var body: String = TUT[tut_step]
		if tut_step == 1:
			body += "\n(đang đông nhất: %d / cần %d con quây lại)" % [
				col.max_local_density(), AgentColony.QUORUM_N]
		_tut_label.text = "HƯỚNG DẪN · %d/%d          [R] chơi lại\n%s" % [tut_step + 1, TUT.size(), body]


# ─────────────────────────── hiệu ứng combat + âm thanh ───────────────────────────

func _spawn_fx(pos: Vector2, kind: String, to: Vector2 = Vector2.INF) -> void:
	var life := 0.3
	match kind:
		"toxin": life = 0.35
		"infect": life = 0.28
		"lyse": life = 0.5
		"t6ss": life = 0.26
	_fx.append({"pos": pos, "kind": kind, "t": 0.0, "life": life, "seed": randf() * TAU,
		"to": pos if to == Vector2.INF else to})
	if _fx.size() > 240:
		_fx.pop_front()
	_play(kind)


func _draw_fx() -> void:
	for f in _fx:
		var pr: float = clampf(f["t"] / f["life"], 0.0, 1.0)
		var fade := 1.0 - pr
		var pos: Vector2 = f["pos"]
		match f["kind"]:
			"toxin":                                   # nổ độc: vòng lan + tia
				var r := lerpf(6.0, AgentColony.TOXIN_RADIUS * 1.15, pr)
				draw_arc(pos, r, 0, TAU, 30, Color(0.55, 0.95, 0.85, fade * 0.85), 2.5 * fade + 0.6, true)
				for k in 6:
					var a: float = f["seed"] + TAU * k / 6.0
					draw_line(pos + Vector2(cos(a), sin(a)) * r * 0.5, pos + Vector2(cos(a), sin(a)) * r,
						Color(0.7, 1.0, 0.9, fade), 1.3)
			"infect":                                  # phage cắm trúng: loé đỏ
				var r := lerpf(3.0, 15.0, pr)
				draw_arc(pos, r, 0, TAU, 18, Color(1.0, 0.4, 0.4, fade), 2.2 * fade + 0.5, true)
			"lyse":                                    # tế bào vỡ: bung mảnh + phage văng ra
				var r := lerpf(4.0, 28.0, pr)
				draw_arc(pos, r, 0, TAU, 22, Color(1.0, 0.75, 0.75, fade * 0.9), 2.0 * fade + 0.5, true)
				for k in 7:
					var a: float = f["seed"] + TAU * k / 7.0
					draw_circle(pos + Vector2(cos(a), sin(a)) * r, 2.0 * fade + 0.6, Color(PHAGE_COL, fade))
			"t6ss":                                    # T6SS: cú ĐÂM giáo (đâm ra rồi rút)
				var to: Vector2 = f["to"]
				var dir: Vector2 = to - pos
				if dir.length() < 0.01:
					dir = Vector2(1, 0)
				var ang := dir.angle()
				var thrust := sin(pr * PI)               # 0 → 1 → 0: đâm ra rồi rút về
				var reach := lerpf(5.0, maxf(dir.length(), AgentColony.T6SS_RANGE), thrust)
				var native := _tex_spear.get_size().x
				draw_set_transform(pos, ang, Vector2(reach / native, 1.0))
				draw_texture(_tex_spear, Vector2(0, -_tex_spear.get_size().y * 0.5),
					Color(1, 1, 1, 0.4 + 0.6 * thrust))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if thrust > 0.5:                         # loé đỏ chỗ trúng
					draw_circle(pos + dir.normalized() * reach, 3.0 * thrust, Color(1.0, 0.35, 0.28, fade))


func _build_audio() -> void:
	for i in 8:
		var pl := AudioStreamPlayer.new()
		pl.volume_db = -8.0
		add_child(pl)
		_players.append(pl)
	for kind in ["toxin", "infect", "lyse", "phage_wave", "biofilm_formed", "crossfeeder",
			"t6ss", "rival"]:
		_sounds[kind] = _make_sound(kind)


## Tổng hợp một tiếng ngắn bằng mã (PLACEHOLDER — cần nghe để chỉnh, hoặc thay .ogg).
func _make_sound(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.16)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var tt := float(i) / rate
		var env := exp(-tt * 20.0)
		var s := 0.0
		match kind:
			"toxin": s = sin(TAU * (700.0 - 2200.0 * tt) * tt)
			"infect": s = (randf() * 2.0 - 1.0) * 0.6 + sin(TAU * 150.0 * tt) * 0.4
			"lyse": s = randf() * 2.0 - 1.0
			"phage_wave":
				s = sin(TAU * 90.0 * tt) * 0.8
				env = exp(-tt * 6.0)
			"biofilm_formed":
				s = sin(TAU * (300.0 + 400.0 * tt) * tt)
				env = exp(-tt * 5.0)
			"crossfeeder":
				s = sin(TAU * (500.0 + 300.0 * tt) * tt)
				env = exp(-tt * 8.0)
			"t6ss":                                     # cú đâm: nhiễu ngắn, đanh
				s = (randf() * 2.0 - 1.0) * 0.7 + sin(TAU * 320.0 * tt) * 0.3
				env = exp(-tt * 34.0)
			"rival":                                    # đối thủ tới: tiếng trầm đe doạ
				s = sin(TAU * (120.0 - 60.0 * tt) * tt)
				env = exp(-tt * 5.0)
		var v := int(clampf(s * env, -1.0, 1.0) * 30000.0)
		data[i * 2] = v & 0xff
		data[i * 2 + 1] = (v >> 8) & 0xff
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


func _play(kind: String) -> void:
	if not _sounds.has(kind):
		return
	for pl in _players:
		if not pl.playing:
			pl.stream = _sounds[kind]
			pl.play()
			return
	_players[0].stream = _sounds[kind]
	_players[0].play()
