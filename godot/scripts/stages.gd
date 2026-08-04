class_name Stages
extends RefCounted

## Sinh màn chơi: [Địa hình] + [Thế cờ khởi tạo] + [Mục tiêu] (mục 5 tài liệu thiết kế).
## Toàn bộ là hàm static thao tác lên một Sim, không giữ trạng thái — test dựng lại
## y hệt một màn chỉ bằng cách truyền lại đúng hạt giống rng.

enum Terrain { OPEN, CHOKE, ISLANDS, FLOW }
enum Layout { SCATTER, CLUMPS, SIEGE, VORTEX }
enum Goal { HOLD, SURVIVE, BALANCE, BLITZ, ESCORT }

const TERRAIN_NAME := {
	Terrain.OPEN: "Đĩa trống",
	Terrain.CHOKE: "Thắt cổ chai",
	Terrain.ISLANDS: "Quần đảo",
	Terrain.FLOW: "Dòng chảy vi lưu",
}

const LAYOUT_NAME := {
	Layout.SCATTER: "gieo đều",
	Layout.CLUMPS: "ba cứ điểm",
	Layout.SIEGE: "bao vây",
	Layout.VORTEX: "xoáy tử thần",
}

## Mỗi mục tiêu kèm thời lượng riêng, đúng bảng mục 5C.
const GOAL_INFO := {
	Goal.HOLD: {
		"name": "Chiếm đất",
		"desc": "Giữ ≥ 45% diện tích đĩa khi hết giờ.",
		"seconds": 60.0,
	},
	Goal.SURVIVE: {
		"name": "Sinh tồn",
		"desc": "Đừng để quân số rơi dưới 10% trong suốt 90 giây.",
		"seconds": 90.0,
	},
	Goal.BALANCE: {
		"name": "Cân bằng",
		"desc": "Khi hết giờ cả ba chủng đều phải trên 15%.",
		"seconds": 75.0,
	},
	Goal.BLITZ: {
		"name": "Hỏa tốc",
		"desc": "Truy kích tàn quân Kháng độc xuống dưới 3% trong 40 giây.",
		"seconds": 40.0,
	},
	Goal.ESCORT: {
		"name": "Hộ tống",
		"desc": "Vi khuẩn Chúa ở tâm đĩa phải sống đủ 60 giây.",
		"seconds": 60.0,
	},
}

const QUEEN_RADIUS := 5

## Ngưỡng thắng của mục tiêu Hoả tốc. Ban đầu đặt "sạch bong 0 ô" đúng chữ trong
## tài liệu, nhưng trên lưới 32.400 ô thì sót đúng MỘT ô là hỏng cả màn, mà Kháng
## độc lại mọc lại được từ mọi mẩu sót. 3% là mức vừa gắt vừa đạt được — xem thêm
## _thin_resistant() ở dưới, hai thứ phải đi cùng nhau.
const BLITZ_TARGET := 0.03


## Một màn chơi hoàn chỉnh. Dùng Dictionary chứ không phải class riêng để test
## viết thẳng màn muốn thử bằng một literal.
static func make(terrain: Terrain, layout: Layout, goal: Goal, rng_seed: int) -> Dictionary:
	return {
		"terrain": terrain,
		"layout": layout,
		"goal": goal,
		"seed": rng_seed,
		"seconds": GOAL_INFO[goal]["seconds"],
	}


static func title(stage: Dictionary) -> String:
	return "%s — %s" % [GOAL_INFO[stage["goal"]]["name"], TERRAIN_NAME[stage["terrain"]]]


static func subtitle(stage: Dictionary) -> String:
	return "%s · thế cờ %s" % [GOAL_INFO[stage["goal"]]["desc"], LAYOUT_NAME[stage["layout"]]]


## Bốc một màn ngẫu nhiên cho chặng thứ index của run. Màn đầu luôn dễ thở:
## đĩa trống + gieo đều + chiếm đất, để người chơi kịp đọc hoa văn trước khi bị vặn.
static func roll(index: int, rng: RandomNumberGenerator) -> Dictionary:
	if index == 0:
		return make(Terrain.OPEN, Layout.SCATTER, Goal.HOLD, rng.randi())

	var terrains := [Terrain.OPEN, Terrain.CHOKE, Terrain.ISLANDS, Terrain.FLOW]
	var layouts := [Layout.SCATTER, Layout.CLUMPS, Layout.SIEGE, Layout.VORTEX]
	var goals := [Goal.HOLD, Goal.SURVIVE, Goal.BALANCE, Goal.BLITZ, Goal.ESCORT]

	var goal: Goal = goals[rng.randi() % goals.size()]
	var layout: Layout = layouts[rng.randi() % layouts.size()]
	var terrain: Terrain = terrains[rng.randi() % terrains.size()]

	if terrain == Terrain.ISLANDS and not is_allowed(terrain, layout, goal):
		terrain = Terrain.OPEN
	if not is_allowed(terrain, layout, goal):
		layout = Layout.CLUMPS
	return make(terrain, layout, goal, rng.randi())


## Tổ hợp này có được phép sinh ra không.
##
## Tách riêng để tests/balance.gd hỏi được: quét mọi tổ hợp rồi bắt lỗi một tổ hợp
## mà game không bao giờ sinh ra là bắt lỗi oan, và tệ hơn là dụ người sửa đi chỉnh
## số liệu cho vừa một màn chơi không tồn tại.
static func is_allowed(terrain: Terrain, layout: Layout, goal: Goal) -> bool:
	# Hai thế cờ đồng tâm (Hộ tống, Bao vây) cần tâm đĩa liền mạch. Quần đảo băm đĩa
	# thành mấy hòn rời nên vòng vây thủng lỗ chỗ và cụm khởi đầu chết trong 14 giây.
	if terrain == Terrain.ISLANDS and (goal == Goal.ESCORT or layout == Layout.SIEGE):
		return false
	# Hộ tống đặt Vi khuẩn Chúa ở tâm, Bao vây cũng chiếm tâm — chồng lên nhau.
	return not (goal == Goal.ESCORT and layout == Layout.SIEGE)


## Dựng màn lên lưới. Trả về danh sách ô Vi khuẩn Chúa (rỗng nếu màn không phải Hộ tống).
static func build(sim: Sim, stage: Dictionary) -> PackedInt32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = stage["seed"]

	sim.grid.fill(Sim.EMPTY)
	sim.hp.fill(0)
	sim.stirring = false
	sim.set_flow(0.0)

	_carve_dish(sim)
	match stage["terrain"]:
		Terrain.CHOKE: _carve_choke(sim, rng)
		Terrain.ISLANDS: _carve_islands(sim, rng)
		Terrain.FLOW: sim.set_flow(0.45)
		_: pass
	sim.recount()

	match stage["layout"]:
		Layout.CLUMPS: _lay_clumps(sim, rng)
		Layout.SIEGE: _lay_siege(sim)
		Layout.VORTEX: _lay_vortex(sim)
		_: _lay_scatter(sim, rng)

	if stage["goal"] == Goal.BLITZ:
		_thin_resistant(sim, rng)
	sim.recount()

	if stage["goal"] == Goal.ESCORT:
		return _lay_queen(sim)
	return PackedInt32Array()


# ─────────────────────────── địa hình ───────────────────────────

## Ngoài vành đĩa là thuỷ tinh: đánh WALL để lưới toroidal không cho quân vòng qua
## mép này sang mép kia — trên đĩa Petri thì chuyện đó vô lý.
static func _carve_dish(sim: Sim) -> void:
	var c := sim.size * 0.5 - 0.5
	var r := sim.size * 0.5 - 1.0
	var rr := r * r
	for y in sim.size:
		for x in sim.size:
			var dx := x - c
			var dy := y - c
			if dx * dx + dy * dy > rr:
				sim.grid[y * sim.size + x] = Sim.WALL


## Hai vách nhựa dọc chừa 1–2 khe hẹp: quân hai bên chỉ gặp nhau ở khe.
static func _carve_choke(sim: Sim, rng: RandomNumberGenerator) -> void:
	var l := sim.size
	var thickness := maxi(2, l / 60)
	var gap := maxi(6, l / 22)
	for band in [l / 3, 2 * l / 3]:
		var hole := rng.randi_range(int(l * 0.25), int(l * 0.75))
		for y in l:
			if absi(y - hole) <= gap:
				continue
			for t in thickness:
				sim.grid[y * l + band + t] = Sim.WALL


## 3–4 hòn đảo nối bằng cầu thạch: mọi thứ ngoài đảo và cầu đều là vách.
static func _carve_islands(sim: Sim, rng: RandomNumberGenerator) -> void:
	var l := sim.size
	var centers: Array[Vector2] = []
	var count := rng.randi_range(3, 4)
	var radius := l * 0.20
	for i in count:
		var ang := TAU * i / count + rng.randf() * 0.3
		centers.append(Vector2(l * 0.5, l * 0.5) + Vector2(cos(ang), sin(ang)) * l * 0.26)

	var keep := PackedByteArray()
	keep.resize(sim.cells)
	for y in l:
		for x in l:
			var p := Vector2(x, y)
			for c in centers:
				if p.distance_to(c) <= radius:
					keep[y * l + x] = 1
					break
	# Cầu thạch: nối tâm đảo i với đảo kế tiếp bằng một dải rộng vài ô.
	var bridge := maxi(2, l / 40)
	for i in count:
		var a := centers[i]
		var b := centers[(i + 1) % count]
		var steps := int(a.distance_to(b)) + 1
		for s in steps + 1:
			var p := a.lerp(b, float(s) / steps)
			for dy in range(-bridge, bridge + 1):
				for dx in range(-bridge, bridge + 1):
					var gx := int(p.x) + dx
					var gy := int(p.y) + dy
					if gx >= 0 and gx < l and gy >= 0 and gy < l:
						keep[gy * l + gx] = 1
	for i in sim.cells:
		if keep[i] == 0:
			sim.grid[i] = Sim.WALL


## Hoả tốc bắt đầu bằng tàn quân Kháng độc chứ không phải một đĩa cân bằng.
##
## Người chơi chỉ nuôi được Tiết độc, mà Tiết độc ĂN Nhạy cảm — đúng cái chủng
## đang gặm Kháng độc hộ mình. Nghĩa là đòi họ tự tay hạ Kháng độc từ 33% xuống 0
## trong 40 giây là đòi một việc bộ công cụ không làm được: tests/goals.gd cho bot
## thua 2/2, dừng ở 20–26%. Đổi thành cuộc TRUY KÍCH: Kháng độc đã yếu sẵn, việc
## của người chơi là biết kiềm chế, đừng cấy đè lên đám Nhạy cảm đang xung trận.
static func _thin_resistant(sim: Sim, rng: RandomNumberGenerator) -> void:
	for i in sim.cells:
		if sim.grid[i] == Sim.RESISTANT and rng.randf() < 0.62:
			sim.grid[i] = Sim.SENSITIVE
			sim.hp[i] = Sim.HP_TABLE[Sim.SENSITIVE]


# ─────────────────────────── thế cờ ───────────────────────────

## Gieo đều rồi để lưới tự đẻ xoắn ốc — đây là thế cờ đẹp nhất của mô hình này.
static func _lay_scatter(sim: Sim, rng: RandomNumberGenerator) -> void:
	for i in sim.cells:
		if sim.grid[i] == Sim.WALL:
			continue
		var r := rng.randf()
		if r < 0.22:
			sim.grid[i] = Sim.TOXIC
		elif r < 0.44:
			sim.grid[i] = Sim.SENSITIVE
		elif r < 0.66:
			sim.grid[i] = Sim.RESISTANT
		else:
			continue
		sim.hp[i] = Sim.HP_TABLE[sim.grid[i]]


static func _lay_clumps(sim: Sim, rng: RandomNumberGenerator) -> void:
	var l := sim.size
	var r := int(l * 0.11)
	var off := l * 0.26
	var base := rng.randf() * TAU
	var order := [Sim.TOXIC, Sim.SENSITIVE, Sim.RESISTANT]
	for i in 3:
		var ang: float = base + TAU * i / 3.0
		sim.seed_circle(
			int(l * 0.5 + cos(ang) * off), int(l * 0.5 + sin(ang) * off), r, order[i])


## Bao vây: một nhúm Tiết độc kẹt trong tường Kháng độc, ngoài là biển Nhạy cảm.
## Cách thoát duy nhất là mở đường cho Nhạy cảm ăn Kháng độc hộ mình.
## Cụm bị vây chết theo chu vi chứ không theo diện tích, nên thời gian cầm cự tỉ lệ
## với BÁN KÍNH lõi. tests/balance.gd đo được: lõi 0.15 chỉ trụ 14–20 giây, người
## chơi thua trước khi kịp hiểu mình đang bị vây. Lõi 0.22 kéo lên khoảng 30 giây —
## đủ để nhìn ra là phải bỏ cụm này mà đổ bộ ra biển Nhạy cảm bên ngoài.
static func _lay_siege(sim: Sim) -> void:
	var l := sim.size
	var c := int(l * 0.5)
	sim.seed_circle(c, c, int(l * 0.46), Sim.SENSITIVE)
	sim.seed_circle(c, c, int(l * 0.30), Sim.RESISTANT)
	sim.seed_circle(c, c, int(l * 0.22), Sim.TOXIC)


## Hai xoáy xoắn ốc dựng sẵn, quay ổn định. Pha màu = góc + bán kính nên ba chủng
## xếp thành cánh quạt — đúng dạng hút của mô hình, nên nó tự quay chứ không tan.
static func _lay_vortex(sim: Sim) -> void:
	var l := sim.size
	var hubs := [Vector2(l * 0.33, l * 0.42), Vector2(l * 0.67, l * 0.60)]
	for y in l:
		for x in l:
			var i := y * l + x
			if sim.grid[i] == Sim.WALL:
				continue
			var p := Vector2(x, y)
			var hub: Vector2 = hubs[0] if p.distance_to(hubs[0]) < p.distance_to(hubs[1]) else hubs[1]
			var d := p - hub
			var phase := d.angle() + d.length() * 0.22
			var s: int = Sim.SPECIES[int(floor(phase / TAU * 3.0)) % 3]
			sim.grid[i] = s
			sim.hp[i] = Sim.HP_TABLE[s]


## Vi khuẩn Chúa: một cụm Tiết độc ở tâm. Trả về chỉ số các ô để còn chấm công sau.
static func _lay_queen(sim: Sim) -> PackedInt32Array:
	var c := int(sim.size * 0.5)
	sim.seed_circle(c, c, QUEEN_RADIUS + 3, Sim.EMPTY)
	sim.seed_circle(c, c, QUEEN_RADIUS, Sim.TOXIC)
	var out := PackedInt32Array()
	for dy in range(-QUEEN_RADIUS, QUEEN_RADIUS + 1):
		for dx in range(-QUEEN_RADIUS, QUEEN_RADIUS + 1):
			if dx * dx + dy * dy <= QUEEN_RADIUS * QUEEN_RADIUS:
				out.append((c + dy) * sim.size + c + dx)
	return out
