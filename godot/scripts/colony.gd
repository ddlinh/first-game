class_name Colony
extends Node2D

## Trọng tài của trận: giữ Sim, chấm mục tiêu, nhận thao tác của người chơi và
## điều phối các lớp phủ. Người chơi KHÔNG điều khiển từng con vi khuẩn — chỉ có
## hai đòn can thiệp là cấy quân và khuấy đĩa, mọi thứ còn lại do lưới tự diễn.

const SAVE_PATH := "user://khuan-lac.cfg"

## Mất chủng của mình là thua ngay, khỏi cần chờ hết giờ.
const WIPEOUT := 0.004

## Mấy giây đầu KHÔNG áp luật thua-ngay.
##
## Thế cờ "ba cứ điểm" thả ba cụm nhỏ lên đĩa trống, mỗi chủng vỏn vẹn ~5% cho tới
## khi quân bò kín mặt thạch (mất khoảng hai giây). Không có khoảng ân hạn này thì
## mục tiêu Sinh tồn — thua nếu tụt dưới 10% — bắn ngay khung hình đầu tiên và
## người chơi thua trước khi kịp nhìn thấy cái đĩa. tests/smoke.gd bắt được đúng ca đó.
const GRACE := 4.0

const NARRATE_EVERY := 3.2
const QUAD_NAME := ["bắc", "đông", "nam", "tây"]

enum State { TUTORIAL, INTRO, PLAYING, RESULT, CARDS, RUN_END }

const TUTORIAL_STEPS := [
	{
		"title": "Bước 1 · Vòng khắc chế",
		"body": "Bạn nuôi chủng TIẾT ĐỘC (tím).\n\n"
			+ "Tiết độc diệt Nhạy cảm (vàng) · Nhạy cảm đè Kháng độc (xanh) · "
			+ "Kháng độc chặn Tiết độc.\n\n"
			+ "Không ai mạnh nhất. Muốn diệt Kháng độc thì phải NUÔI Nhạy cảm cho nó ăn hộ.",
		"button": "Tiếp theo →",
	},
	{
		"title": "Bước 2 · Hai đòn can thiệp",
		"body": "Bấm chuột trái lên đĩa để CẤY một cụm Tiết độc. Mỗi lượt cấy phải chờ hồi.\n\n"
			+ "Giữ Space để KHUẤY ĐĨA: quân bị trộn tung, sóng xoắn ốc tan ra. "
			+ "Khuấy cứu được thế bí, nhưng thanh khuấy cạn rất nhanh và trộn lâu thì "
			+ "cả đĩa cùng chết.",
		"button": "Tiếp theo →",
	},
	{
		"title": "Bước 3 · Một lượt chơi",
		"body": "Mỗi lượt đi qua 6–8 đĩa thạch, mỗi đĩa một mục tiêu và một kiểu địa hình khác nhau.\n\n"
			+ "Thắng một đĩa thì được chọn 1 trong 3 thẻ nâng cấp. Thua một đĩa là hết lượt.",
		"button": "Vào đĩa đầu tiên 🚀",
	},
]

## Chạy trước ngần này giây mô phỏng trước khi giao đĩa, để người chơi mở mắt ra
## là thấy sóng xoắn ốc chứ không phải một bãi nhiễu lốm đốm. Nằm sau lớp phủ giới
## thiệu đĩa nên khựng ~0,2 giây ở đây không ai thấy.
const WARM_UP := 1.5

## Test tắt cờ này để nhảy thẳng vào trận, khỏi phải bấm qua ba bước hướng dẫn.
var tutorial_enabled := true
## Cạnh lưới, đúng con số mục 4 tài liệu thiết kế. Để là biến chứ không phải hằng
## vì tests/diag_pattern.gd cần quét nhiều cỡ.
##
## Đã thử lưới to hơn với hy vọng hoa văn mịn và xoắn rõ hơn — SAI. Đo ra thì
## 180×2.2 cho mảng màu 37 px và giữ đủ ba chủng 4/4 lần, còn 220 phải đẩy linh
## động lên mới có hoa văn tương đương, mà lên tới đó thì 2/4 lần mất đa dạng, và
## 260 hỏng cả 4/4. Đây là trần vật lý của mô hình chứ không phải chuyện tinh chỉnh:
## xoáy to bằng cái đĩa thì một chủng chết.
var grid_size := 180

var sim: Sim
var run: Run
var state: State = State.INTRO

var time_left := 0.0
var stage_seconds := 0.0
var charges := 1
var plant_cd := 0.0
var stir_energy := 1.0
var stirring := false
var queen := PackedInt32Array()
var lost_reason := ""

var _tut_step := 0
var _cards: Array[Dictionary] = []
var _narrate_t := 0.0
var _prev_quad := PackedFloat32Array([0, 0, 0, 0])
var _rng := RandomNumberGenerator.new()

@onready var board: Board = $Board
@onready var agents: Agents = $Board/Agents
@onready var hud: Hud = $Hud


func _ready() -> void:
	sim = Sim.new(grid_size)
	# Nền đặt từ mã chứ không để nguyên giá trị trong Dish.tscn: để trong scene thì
	# nó là màu thứ tư nằm ngoài Palette và đổi tone sẽ bỏ sót đúng cái nền.
	$Backdrop/Bg.color = Palette.of("backdrop")
	board.setup(sim)
	agents.setup(sim, board)
	_place_board()
	get_viewport().size_changed.connect(_place_board)

	hud.continue_pressed.connect(_on_continue)
	hud.card_chosen.connect(_on_card)
	hud.restart_pressed.connect(func() -> void: start_run())
	hud.stir_changed.connect(func(down: bool) -> void: stirring = down)

	start_run()
	if tutorial_enabled and not _tutorial_seen():
		state = State.TUTORIAL
		_tut_step = 0
		_show_tutorial()


func _place_board() -> void:
	var vp := get_viewport_rect().size
	# Đẩy tâm đĩa lên trên một chút: dải nút và nhật ký chiến sự chiếm đáy màn hình.
	board.position = Vector2(vp.x * 0.5, vp.y * 0.5 - 18.0)


# ─────────────────────────── vòng đời một lượt ───────────────────────────

## forced: test dựng sẵn danh sách đĩa để soi đúng một mục tiêu, thay vì bốc ngẫu
## nhiên rồi cầu may cho nó rơi trúng nhánh cần kiểm.
func start_run(run_seed: int = 0, forced: Array[Dictionary] = []) -> void:
	run = Run.new(run_seed)
	if not forced.is_empty():
		run.stages = forced
	enter_stage()


func enter_stage() -> void:
	var stage := run.current()
	queen = Stages.build(sim, stage)
	sim.repro_boost = run.kit["repro_boost"]
	sim.rebuild_rates()
	# Hâm nóng TRƯỚC khi chốt danh sách ô Vi khuẩn Chúa thì cụm chúa đã bị gặm mất
	# một phần ngay lúc bắt đầu, nên thứ tự ở đây quan trọng: Stages.build cấy chúa
	# xong mới hâm, và mục tiêu Hộ tống bỏ qua hâm nóng.
	if stage["goal"] != Stages.Goal.ESCORT:
		sim.warm_up(WARM_UP)

	stage_seconds = stage["seconds"]
	time_left = stage_seconds
	charges = run.kit["max_charges"]
	plant_cd = 0.0
	stir_energy = 1.0
	stirring = false
	lost_reason = ""
	_narrate_t = 0.0
	_prev_quad = _sample_quadrants()
	agents.clear_effects()

	hud.set_goal(stage, run.index, run.stages.size())
	hud.set_counts(sim)
	hud.set_clock(time_left, stage_seconds)

	state = State.INTRO
	hud.show_message(
		"Đĩa %d/%d — %s" % [run.index + 1, run.stages.size(), Stages.title(stage)],
		Stages.subtitle(stage),
		"Thả vào đĩa ▶",
		Palette.sprite(Sim.TOXIC))


func begin_play() -> void:
	state = State.PLAYING
	hud.hide_overlay()
	hud.log_line("Đĩa đã cấy. Đọc hoa văn rồi chọn chỗ đổ bộ!")


func _on_continue() -> void:
	match state:
		State.TUTORIAL:
			_tut_step += 1
			if _tut_step >= TUTORIAL_STEPS.size():
				_mark_tutorial_seen()
				enter_stage()
			else:
				_show_tutorial()
		State.INTRO:
			begin_play()
		State.RESULT:
			# Thắng thì sang màn chọn thẻ, thua thì kết thúc lượt.
			if lost_reason.is_empty():
				_offer_cards()
			else:
				_end_run(false)
		State.RUN_END:
			start_run()
		_:
			pass


func _offer_cards() -> void:
	if run.is_last():
		_end_run(true)
		return
	_cards = run.draw_cards()
	state = State.CARDS
	hud.show_cards(_cards)


func _on_card(index: int) -> void:
	if state != State.CARDS or index >= _cards.size():
		return
	run.take_card(_cards[index])
	run.index += 1
	enter_stage()


func _end_run(victory: bool) -> void:
	state = State.RUN_END
	var best := _best_stage()
	if run.index + (1 if victory else 0) > best:
		_save_best(run.index + (1 if victory else 0))
	if victory:
		hud.show_message(
			"THẮNG CẢ LƯỢT! 🏆",
			"Bạn giữ được chủng Tiết độc qua trọn %d đĩa thạch." % run.stages.size(),
			"Lượt mới ↻", Color(0.45, 0.90, 0.55))
	else:
		hud.show_message(
			"HẾT LƯỢT 💀",
			"%s\nĐi được %d/%d đĩa. Kỷ lục: %d đĩa." % [
				lost_reason, run.index, run.stages.size(), maxi(best, run.index)],
			"Lượt mới ↻", Color(1.0, 0.45, 0.45))


# ─────────────────────────── mỗi khung ───────────────────────────

func _process(delta: float) -> void:
	if state != State.PLAYING:
		agents.hover_cell = Vector2i(-1, -1)
		return

	sim.stirring = stirring and stir_energy > 0.0
	sim.advance(delta)

	if sim.stirring:
		stir_energy = maxf(0.0, stir_energy - delta * 0.55)
		if stir_energy <= 0.0:
			stirring = false
	else:
		stir_energy = minf(1.0, stir_energy + delta * run.kit["stir_recharge"])

	if charges < run.kit["max_charges"]:
		plant_cd -= delta
		if plant_cd <= 0.0:
			charges += 1
			if charges < run.kit["max_charges"]:
				plant_cd = run.kit["plant_cooldown"]

	time_left -= delta
	_narrate_t += delta
	if _narrate_t >= NARRATE_EVERY:
		_narrate_t = 0.0
		_narrate()

	_update_hud()
	_judge()


func _update_hud() -> void:
	hud.set_counts(sim)
	hud.set_clock(time_left, stage_seconds)
	var cd_ratio := 1.0 - clampf(plant_cd / maxf(run.kit["plant_cooldown"], 0.001), 0.0, 1.0)
	hud.set_plant(charges, run.kit["max_charges"], cd_ratio)
	hud.set_stir(stir_energy, sim.stirring)

	var p := _progress()
	hud.set_progress(p[0], p[1])
	_hover()


## Dòng tiến độ ngay dưới mục tiêu — người chơi phải biết mình đang thiếu bao nhiêu.
func _progress() -> Array:
	var mine := sim.ratio(Sim.TOXIC)
	match run.current()["goal"]:
		Stages.Goal.HOLD:
			return ["Đang giữ %d%% / cần 45%%" % roundi(mine * 100), mine >= 0.45]
		Stages.Goal.SURVIVE:
			return ["Quân số %d%% / ngưỡng chết 10%%" % roundi(mine * 100), mine >= 0.10]
		Stages.Goal.BALANCE:
			var lo := minf(minf(mine, sim.ratio(Sim.SENSITIVE)), sim.ratio(Sim.RESISTANT))
			return ["Chủng yếu nhất %d%% / cần > 15%%" % roundi(lo * 100), lo > 0.15]
		Stages.Goal.BLITZ:
			var r := sim.ratio(Sim.RESISTANT)
			return ["Kháng độc còn %.1f%% / cần dưới %.0f%%" % [
				r * 100, Stages.BLITZ_TARGET * 100], r < Stages.BLITZ_TARGET]
		Stages.Goal.ESCORT:
			var q := _queen_health()
			return ["Vi khuẩn Chúa còn %d%%" % roundi(q * 100), q > 0.5]
	return ["", true]


## Chấm mục tiêu. Thua trắng (mất sạch chủng) luôn được xét trước mọi luật khác.
func _judge() -> void:
	var mine := sim.ratio(Sim.TOXIC)
	var goal: Stages.Goal = run.current()["goal"]
	var settled := stage_seconds - time_left >= GRACE

	if settled and mine <= WIPEOUT:
		_lose("Chủng Tiết độc bị xoá sổ khỏi đĩa thạch.")
		return

	match goal:
		Stages.Goal.SURVIVE:
			if settled and mine < 0.10:
				_lose("Quân số tụt dưới 10% — phòng tuyến sụp.")
				return
		Stages.Goal.BLITZ:
			if sim.ratio(Sim.RESISTANT) < Stages.BLITZ_TARGET:
				_win("Kháng độc bị đánh sập, chỉ còn %.1f%%!" % (sim.ratio(Sim.RESISTANT) * 100))
				return
		Stages.Goal.ESCORT:
			if settled and _queen_health() <= 0.25:
				_lose("Vi khuẩn Chúa đã bị nuốt.")
				return
		_:
			pass

	if time_left > 0.0:
		return

	match goal:
		Stages.Goal.HOLD:
			if mine >= 0.45:
				_win("Chiếm %d%% diện tích đĩa." % roundi(mine * 100))
			else:
				_lose("Hết giờ mà mới giữ được %d%%, cần 45%%." % roundi(mine * 100))
		Stages.Goal.SURVIVE:
			_win("Trụ đủ 90 giây với %d%% quân số." % roundi(mine * 100))
		Stages.Goal.BALANCE:
			var lo := minf(minf(mine, sim.ratio(Sim.SENSITIVE)), sim.ratio(Sim.RESISTANT))
			if lo > 0.15:
				_win("Cả ba chủng cùng sống, chủng yếu nhất %d%%." % roundi(lo * 100))
			else:
				_lose("Hệ sinh thái lệch — chủng yếu nhất chỉ còn %d%%." % roundi(lo * 100))
		Stages.Goal.BLITZ:
			_lose("Hết 40 giây mà Kháng độc vẫn còn %d%%." % roundi(sim.ratio(Sim.RESISTANT) * 100))
		Stages.Goal.ESCORT:
			_win("Vi khuẩn Chúa sống sót qua 60 giây.")


func _win(reason: String) -> void:
	state = State.RESULT
	lost_reason = ""
	stirring = false
	sim.stirring = false
	hud.show_message("QUA ĐĨA! ✅", reason, "Nhận thẻ nâng cấp →", Color(0.45, 0.90, 0.55))


func _lose(reason: String) -> void:
	state = State.RESULT
	lost_reason = reason
	stirring = false
	sim.stirring = false
	hud.show_message("VỠ TRẬN 💀", reason, "Xem kết quả →", Color(1.0, 0.45, 0.45))


func _queen_health() -> float:
	if queen.is_empty():
		return 1.0
	var alive := 0
	for i in queen:
		if sim.grid[i] == Sim.TOXIC:
			alive += 1
	return float(alive) / float(queen.size())


# ─────────────────────────── thao tác người chơi ───────────────────────────

func _hover() -> void:
	var cell := board.local_to_cell(board.to_local(get_global_mouse_position()))
	agents.hover_radius = run.kit["plant_radius"]
	if _can_plant_at(cell):
		agents.hover_cell = cell
		agents.hover_ok = charges > 0
	elif cell.x >= 0 and cell.x < grid_size and cell.y >= 0 and cell.y < grid_size:
		agents.hover_cell = cell
		agents.hover_ok = false
	else:
		agents.hover_cell = Vector2i(-1, -1)


func _can_plant_at(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_size or cell.y >= grid_size:
		return false
	return sim.grid[cell.y * grid_size + cell.x] != Sim.WALL


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				if state == State.PLAYING:
					stirring = true
				else:
					_on_continue()
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				_on_continue()
			KEY_R:
				start_run()
			KEY_1, KEY_2, KEY_3:
				if state == State.CARDS:
					_on_card(event.keycode - KEY_1)
	elif event is InputEventKey and not event.pressed and event.keycode == KEY_SPACE:
		stirring = false
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if state == State.PLAYING:
			_try_plant(board.local_to_cell(board.to_local(event.position)))


func _try_plant(cell: Vector2i) -> void:
	if charges <= 0 or not _can_plant_at(cell):
		return
	var radius: int = run.kit["plant_radius"]

	# Kháng sinh phổ hẹp: dọn Kháng độc ở lõi trước rồi mới cấy, nếu không thì
	# quân vừa thả xuống đã bị chính đám đó chặn đứng.
	if run.kit["antibiotic"]:
		var core := maxi(2, int(radius * 0.55))
		for dy in range(-core, core + 1):
			for dx in range(-core, core + 1):
				if dx * dx + dy * dy > core * core:
					continue
				var gx := (cell.x + dx + grid_size) % grid_size
				var gy := (cell.y + dy + grid_size) % grid_size
				if sim.grid[gy * grid_size + gx] == Sim.RESISTANT:
					sim.put(gx, gy, Sim.EMPTY)

	sim.seed_circle(cell.x, cell.y, radius, Sim.TOXIC)
	agents.puff(cell.x, cell.y, radius, Palette.sprite(Sim.TOXIC))
	charges -= 1
	if charges < run.kit["max_charges"]:
		plant_cd = run.kit["plant_cooldown"]
	hud.log_line("💥 Đổ bộ phía %s!" % QUAD_NAME[_quadrant_of(cell.x, cell.y)])


# ─────────────────────────── nhật ký chiến sự ───────────────────────────

## Chia đĩa theo bốn hướng NHÌN THẤY TRÊN MÀN HÌNH chứ không theo trục lưới:
## sau khi chiếu iso, trục x của lưới chạy chéo xuống phải, nên "phía bắc" của
## người chơi là chỗ (x + y) nhỏ, chứ không phải y nhỏ.
func _quadrant_of(x: int, y: int) -> int:
	var du := (x + y) - grid_size
	var dv := x - y
	if absi(du) > absi(dv):
		return 2 if du > 0 else 0
	return 1 if dv > 0 else 3


## Lấy mẫu 1200 ô là đủ để biết mặt trận nào đang chuyển, rẻ hơn quét cả lưới.
func _sample_quadrants() -> PackedFloat32Array:
	var mine := PackedFloat32Array([0, 0, 0, 0])
	var total := PackedFloat32Array([0, 0, 0, 0])
	for _i in 1200:
		var c := _rng.randi() % sim.cells
		var v := sim.grid[c]
		if v == Sim.WALL:
			continue
		var q := _quadrant_of(c % grid_size, c / grid_size)
		total[q] += 1.0
		if v == Sim.TOXIC:
			mine[q] += 1.0
	for q in 4:
		mine[q] = mine[q] / maxf(total[q], 1.0)
	return mine


func _narrate() -> void:
	var now := _sample_quadrants()
	var best_q := 0
	var best_d := 0.0
	for q in 4:
		var d := now[q] - _prev_quad[q]
		if absf(d) > absf(best_d):
			best_d = d
			best_q = q
	_prev_quad = now

	if sim.stirring:
		hud.log_line("🌀 Đĩa đang bị khuấy — hoa văn xoắn ốc tan thành nhiễu.")
		return
	var mine := sim.ratio(Sim.TOXIC)
	if mine < 0.08:
		hud.log_line("⚠️ Quân số nguy kịch, chỉ còn %d%%!" % roundi(mine * 100))
	elif best_d > 0.06:
		hud.log_line("Mặt trận phía %s đang lan rộng." % QUAD_NAME[best_q])
	elif best_d < -0.06:
		hud.log_line("Mặt trận phía %s vỡ rồi!" % QUAD_NAME[best_q])
	elif sim.ratio(Sim.RESISTANT) > 0.45:
		hud.log_line("Kháng độc phình to — nuôi Nhạy cảm cho nó ăn đi.")
	elif sim.ratio(Sim.SENSITIVE) < 0.08:
		hud.log_line("Nhạy cảm gần tuyệt chủng, sắp hết thứ khắc chế Kháng độc.")
	else:
		hud.log_line("Đĩa thạch giằng co, sóng xoắn ốc vẫn quay đều.")


# ─────────────────────────── lưu trữ ───────────────────────────

func _show_tutorial() -> void:
	var s: Dictionary = TUTORIAL_STEPS[_tut_step]
	hud.show_message(s["title"], s["body"], s["button"], Palette.sprite(Sim.TOXIC))


func _cfg() -> ConfigFile:
	var c := ConfigFile.new()
	c.load(SAVE_PATH)
	return c


func _tutorial_seen() -> bool:
	return _cfg().get_value("tien_trinh", "da_xem_huong_dan", false)


func _mark_tutorial_seen() -> void:
	var c := _cfg()
	c.set_value("tien_trinh", "da_xem_huong_dan", true)
	c.save(SAVE_PATH)


func _best_stage() -> int:
	return _cfg().get_value("tien_trinh", "ky_luc_dia", 0)


func _save_best(v: int) -> void:
	var c := _cfg()
	c.set_value("tien_trinh", "ky_luc_dia", v)
	c.save(SAVE_PATH)
