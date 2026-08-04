class_name Agents
extends Node2D

## Tầng lính tiền tuyến + hiệu ứng, vẽ đè lên mặt đĩa.
##
## Lưới có 32.400 ô nhưng chỉ dựng đúng POOL con chibi, và chỉ ở ranh giới giao
## tranh (mục 3 tài liệu). Quét cả lưới mỗi khung để tìm tiền tuyến thì quá đắt,
## nên nuôi một BỂ CỐ ĐỊNH: con nào còn đứng trên ranh giới thì giữ nguyên, con
## nào mất chỗ mới bốc ngẫu nhiên vài chục ô tìm chỗ khác. Bể ổn định qua các
## khung nên đám chibi trông như đang bám trụ chứ không nhấp nháy loạn.

## Số chibi dựng cùng lúc — núm chỉnh hiệu năng chính của cả game.
##
## tests/diag_render.gd đo trên Intel iGPU: 0 con 2.0 ms · 30 con 3.6 ms ·
## 60 con 6.5 ms · 120 con 16.6 ms · 200 con 24.8 ms. Tuyến tính khoảng
## 0.12 ms/con, vì mỗi con là sáu lệnh draw_circle riêng và chúng không gộp lô
## được. 64 là chỗ ngồi hợp lý: tiền tuyến vẫn kín người mà cả khung hình chỉ
## hết ~9 ms, còn dư gấp đôi ngân sách 60fps.
var pool := 64
## Cỡ chibi. Ở 1.0 mỗi con cao khoảng 10 px trên cái đĩa rộng 916 px — nhìn ra
## chấm bụi chứ không ra con vật, phí mất cả tầng biểu diễn mà tài liệu thiết kế
## đặt ngang hàng với mặt đĩa.
const SCALE := 1.7

const RESEAT_TRIES := 30
const RESEAT_BUDGET := 20   ## số con được phép tìm chỗ mới mỗi khung

var sim: Sim
var board: Board

var hover_cell := Vector2i(-1, -1)
var hover_radius := 0
var hover_ok := false

var _cells := PackedInt32Array()
var _phase := PackedFloat32Array()
var _time := 0.0
var _puffs: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func setup(s: Sim, b: Board) -> void:
	sim = s
	board = b
	_cells.resize(pool)
	_phase.resize(pool)
	for i in pool:
		_cells[i] = -1
		_phase[i] = _rng.randf() * TAU


## Mây độc bồng bềnh khi người chơi cấy quân hoặc khi có cú nổ lớn.
func puff(cx: float, cy: float, radius: float, col: Color) -> void:
	_puffs.append({
		"pos": board.cell_to_local(cx, cy),
		"r": radius * board.tile_w * 1.4,
		"t": 0.0,
		"life": 0.85,
		"col": col,
	})


func clear_effects() -> void:
	_puffs.clear()
	for i in pool:
		_cells[i] = -1


func _process(delta: float) -> void:
	if sim == null:
		return
	_time += delta

	var budget := RESEAT_BUDGET
	for i in pool:
		var c := _cells[i]
		if c >= 0 and sim.is_frontline(c % sim.size, c / sim.size):
			continue
		_cells[i] = -1
		if budget <= 0:
			continue
		budget -= 1
		for _t in RESEAT_TRIES:
			var j := _rng.randi() % sim.cells
			if sim.is_frontline(j % sim.size, j / sim.size):
				_cells[i] = j
				break

	var k := 0
	while k < _puffs.size():
		_puffs[k]["t"] += delta
		if _puffs[k]["t"] >= _puffs[k]["life"]:
			_puffs.remove_at(k)
		else:
			k += 1

	queue_redraw()


func _draw() -> void:
	if sim == null:
		return

	if hover_cell.x >= 0:
		_draw_hover()

	# Sắp xếp theo trục y màn hình: con đứng "gần" phải vẽ sau, không thì chibi ở
	# xa lại chồng lên chibi ở gần và mất hẳn cảm giác chiều sâu.
	var order: Array[Vector3i] = []
	for i in pool:
		var c := _cells[i]
		if c < 0:
			continue
		var gx := c % sim.size
		var gy := c / sim.size
		order.append(Vector3i(gx + gy, i, c))
	order.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.x < b.x)

	for o in order:
		var c := o.z
		var gx := c % sim.size
		var gy := c / sim.size
		var species := sim.grid[c]
		if species < Sim.TOXIC or species > Sim.RESISTANT:
			continue
		_draw_chibi(board.cell_to_local(gx, gy), species, _phase[o.y])

	for p in _puffs:
		_draw_puff(p)


## Vẽ một con chibi.
##
## Mọi hình ở đây là draw_circle chứ không phải draw_colored_polygon với mảng đỉnh
## tự dựng: bản đầu tiên tính tay ~1000 PackedVector2Array mỗi khung và tầng lính
## một mình ăn 15 trong 17 ms — đo bằng cách bật tắt từng tầng. draw_circle dựng
## đỉnh trong C++, còn hình bầu dục thì nhờ draw_set_transform bóp trục y hộ, nên
## vòng lặp này không cấp phát gì cả.
func _draw_chibi(at: Vector2, species: int, phase: float) -> void:
	var col := Palette.sprite(species)
	var bob := sin(_time * 5.0 + phase)

	# Bóng đổ dẹt: thứ duy nhất neo con chibi xuống mặt đĩa, thiếu nó là chúng
	# trông như đang lơ lửng.
	draw_set_transform(at + Vector2(0, 1), 0.0, Vector2(SCALE, SCALE * 0.48))
	draw_circle(Vector2.ZERO, 4.5, Color(0, 0, 0, 0.35))

	match species:
		Sim.TOXIC:
			# Bé xíu, mắt to, vác túi độc phập phồng sau lưng.
			draw_set_transform(at, 0.0, Vector2(SCALE, SCALE))
			draw_circle(Vector2(3.4, -5.0), 2.2 + 0.5 * sin(_time * 3.0 + phase),
				Color(0.45, 0.95, 0.55, 0.85))
			var lift := Vector2(0, -5.0 - bob * 0.7)
			draw_circle(lift, 4.0, col)
			draw_circle(lift + Vector2(0, -1.2), 3.4, col.lightened(0.18))
			_eyes(lift + Vector2(0, -1.0), 1.5, 0.7, bob)
		Sim.SENSITIVE:
			# Tròn xoe, nhún nhảy liên tục: bẹp xuống rồi bật lên theo nhịp.
			var squash := 1.0 + 0.22 * sin(_time * 9.0 + phase)
			var hop := absf(sin(_time * 4.5 + phase)) * 2.4
			draw_set_transform(at + Vector2(0, (-3.6 - hop) * SCALE), 0.0,
				Vector2(SCALE / squash, SCALE * squash))
			draw_circle(Vector2.ZERO, 3.8, col)
			_eyes(Vector2(0, -0.4), 1.2, 0.55, bob)
		Sim.RESISTANT:
			# Mập mạp, đội mũ bảo hiểm, giơ khiên. Đi chậm nên chỉ lắc rất nhẹ.
			draw_set_transform(at + Vector2(bob * 0.2, -5.0 * SCALE), 0.0,
				Vector2(SCALE, SCALE * 0.92))
			draw_circle(Vector2.ZERO, 4.6, col)
			draw_circle(Vector2(0, -3.0), 4.0, col.darkened(0.35))     # mũ bảo hiểm
			draw_circle(Vector2(-4.6, 0.4), 2.2, col.lightened(0.35))  # khiên mo quạ
			_eyes(Vector2(0, 0.2), 1.3, 0.6, 0.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Toạ độ ở đây nằm trong hệ đã bị draw_set_transform bóp, nên đừng cộng thêm vị
## trí tuyệt đối vào — con chibi sẽ văng ra khỏi thân mình.
func _eyes(center: Vector2, spread: float, r: float, look: float) -> void:
	for s in [-1.0, 1.0]:
		var e := center + Vector2(s * spread, 0)
		draw_circle(e, r, Color(1, 1, 1, 0.95))
		draw_circle(e + Vector2(look * 0.25, 0.15), r * 0.5, Color(0.05, 0.05, 0.1))


func _draw_puff(p: Dictionary) -> void:
	var k: float = p["t"] / p["life"]
	var r: float = p["r"] * (0.35 + k * 1.25)
	var col: Color = p["col"]
	col.a = (1.0 - k) * 0.55
	# Bóp trục y một nửa cho khối mây nằm đúng mặt phẳng nghiêng của đĩa.
	draw_set_transform(p["pos"], 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, r, col)
	col.a *= 0.7
	# Hai bọt lệch nhau cho ra khối xốp nảy, không phải một vòng tròn phẳng.
	draw_circle(Vector2(-r * 0.35, -r * 0.55), r * 0.6, col)
	draw_circle(Vector2(r * 0.4, -r * 0.4), r * 0.55, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hover() -> void:
	var col := Color(Palette.sprite(Sim.TOXIC).lightened(0.2), 0.9) if hover_ok \
		else Color(0.85, 0.32, 0.32, 0.75)
	var pts := PackedVector2Array()
	for i in 41:
		var a := TAU * i / 40.0
		pts.append(board.cell_to_local(
			hover_cell.x + cos(a) * hover_radius, hover_cell.y + sin(a) * hover_radius))
	draw_polyline(pts, col, 2.0, true)
	var c := board.cell_to_local(hover_cell.x, hover_cell.y)
	draw_line(c + Vector2(-7, 0), c + Vector2(7, 0), col, 1.5)
	draw_line(c + Vector2(0, -4), c + Vector2(0, 4), col, 1.5)
