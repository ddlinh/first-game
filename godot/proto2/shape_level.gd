extends RefCounted

## MÀN MẠNG LƯỚI — lõi mô phỏng, KHÔNG biết gì tới màn hình, test headless được.
## Không class_name — nạp bằng preload.
##
## ĐÍCH = một TRẠNG THÁI HÌNH HỌC: dẫn khuẩn lạc mọc phủ đúng hình đích (nút + nhánh)
## rồi CHỐT — cùng khuôn với màn yaourt (chỉnh môi trường → đợi → chốt đúng lúc).
## Người chơi chỉ có MỘT động từ: rải thức ăn. Nhưng ngân sách CỐ ĐỊNH (không hồi) và
## rải sai chỗ thì mất trắng → "rải ở đâu" trở thành cả trò chơi.
##
## BÁM SINH HỌC THẬT (xem CO-SO-KHOA-HOC.md):
##  · Khuẩn KHÔNG nhắm đích ở xa (run-and-tumble cảm cục bộ) và lớn bằng phân đôi ở rìa
##    (range expansion). Muốn tới điểm B phải đặt mồi TRONG TẦM rìa hiện tại rồi ĐỢI nó
##    bò tới — nên hình phải dựng thành MẠNG LƯỚI từng chặng, không vẽ thẳng ra được.
##  · VỆT ĐÃ CHIẾM KHÔNG RÚT LẠI ĐƯỢC: khuẩn lạc là sinh khối tích luỹ. Mọc lố ra ngoài
##    hình là hỏng vĩnh viễn → phải CHỐT đúng lúc, đừng tham.
##  · KHÓ KHĂN = MẤT THỨC ĂN. Cả ba đều là chuyện có thật trên đĩa thạch:
##      MỐC   — bào tử nấm trong không khí bén vào chỗ dinh dưỡng GIÀU mà chưa ai chiếm
##              (niche trống), rồi ăn sạch dinh dưỡng vùng đó và ức chế khuẩn quanh nó.
##      GIỌT  — hơi nước ngưng tụ dưới nắp đĩa rơi xuống, RỬA TRÔI dinh dưỡng một vùng.
##      KHÔ   — thạch mất nước ở một mảng, dinh dưỡng ở đó tàn nhanh hơn hẳn.

const AgentColony := preload("res://proto2/agent_colony.gd")

enum { PLAYING, WON, LOST }

const NF := AgentColony.NF
const CELL := AgentColony.CELL
const DISH_R := AgentColony.DISH_R

# ── hình đích & vệt chiếm ──
## Bề rộng hình đích phải KHỚP với công cụ: một nhát rải phủ bán kính DEPOSIT_R (26px),
## khuẩn lấp kín chỗ đó rồi chiếm thêm CLAIM_R quanh mỗi con. Hình mảnh hơn thế thì
## không tay nghề nào vẽ nổi — đó là giới hạn của cái cọ, không phải của người chơi.
const CLAIM_R := 7.0           ## bán kính một con "chiếm" quanh nó
const NODE_R := 36.0           ## bán kính nút đích
const LINK_HW := 30.0          ## nửa bề rộng nhánh đích

# ── kinh tế: ngân sách CỐ ĐỊNH, không hồi ──
const DOSE := 14.0
## Ngưỡng CHỐT. Đặt ở đây vì đo được: chơi tuần tự đúng cách chạm ~0.64, còn "tô đáp án"
## (đổ thức ăn kín hình ngay từ đầu) chỉ tới ~0.48 — ngưỡng nằm giữa nên câu đố là thật.
const WIN_IOU := 0.55

# ── chủng × môi trường: định cư + thạch cứng = GIỮ HÌNH (điều kiện để vẽ được) ──
const MOTILITY := 0.18
const HARDNESS := 0.90
const RICHNESS := 1.0

# ── MỐC: bén vào dinh dưỡng giàu mà khuẩn chưa tới ──
const MOLD_MAX := 5
const MOLD_SCAN := 1.5         ## nhịp dò chỗ bén
const MOLD_GRACE := 5.0        ## đầu màn chưa có mốc (cho người chơi kịp hiểu luật)
## Ngưỡng "giàu": phải bắt được lúc dinh dưỡng còn đọng. Rải xong là trường loang và tàn
## rất nhanh (đỉnh 1.6 → 0.6 chỉ trong 9s), nên ngưỡng cao quá thì mốc không bao giờ bén.
const MOLD_NUT := 0.55
## Khoảng "khuẩn giữ được chỗ". Rải trong tầm này là an toàn, ném xa hơn là bỏ mồi cho
## mốc — view vẽ hẳn VÒNG TẦM VỚI quanh khuẩn lạc để người chơi thấy được ranh giới này.
const MOLD_FREE := 52.0
const MOLD_R0 := 11.0
const MOLD_RMAX := 38.0
const MOLD_GROW := 1.5
const MOLD_SHRINK := 2.2       ## ăn hết chỗ dinh dưỡng dưới chân thì mốc lụi dần
const MOLD_FEED := 0.05        ## nồng độ dưới chân còn trên ngần này thì mốc còn lớn
const MOLD_EAT := 1.4          ## dinh dưỡng mốc ăn mất /giây
const MOLD_HARM := 0.40        ## năng lượng khuẩn bị bào mòn trong vùng mốc /giây
const MOLD_LOSE := 0.40        ## mốc phủ ngần này phần hình đích → thua

# ── GIỌT NGƯNG TỤ: rửa trôi dinh dưỡng ──
const DRIP_R := 54.0
const DRIP_WASH := 0.82        ## tỉ lệ dinh dưỡng bị cuốn đi trong vùng
const WARN_LEAD := 4.5         ## báo trước ngần này giây

# ── VÙNG KHÔ: dinh dưỡng tàn nhanh, tồn tại tới hết màn ──
const DRY_R := 60.0
const DRY_DECAY := 0.70

const SCORE_EVERY := 0.25      ## nhịp chấm điểm (quét lưới 80×80, không cần mỗi khung)

## Mỗi màn = một HÌNH, cùng một động từ. Nút [0] là chỗ cấy giống.
const LEVELS := [
	{
		"name": "Cầu",
		"goal": "Nối hai ổ bằng một nhánh thẳng.",
		"lesson": "Khuẩn chỉ cảm được thức ăn ở GẦN. Đặt mồi đón đầu rìa, đợi nó bò tới, rồi mới đặt nhát kế.",
		"nodes": [Vector2(-160, 0), Vector2(160, 0)],
		"links": [[0, 1]],
		"budget": 460.0, "time": 210.0,
	},
	{
		"name": "Chữ L",
		"goal": "Đi hết một cạnh rồi bẻ góc sang cạnh kia.",
		"lesson": "Ở góc cua, đừng rải theo đường chéo — khuẩn sẽ cắt góc và mọc tràn ra ngoài. Rải bám đúng khuỷu.",
		"nodes": [Vector2(-160, -120), Vector2(-160, 120), Vector2(160, 120)],
		"links": [[0, 1], [1, 2]],
		"budget": 760.0, "time": 330.0,
	},
	{
		"name": "Vòng",
		"goal": "Khép kín một vòng bốn nút.",
		"lesson": "Vòng phải GẶP nhau. Nuôi hai đầu tiến lại gần nhau, chừa ngân sách cho mối nối cuối.",
		"nodes": [Vector2(-140, -140), Vector2(140, -140), Vector2(140, 140), Vector2(-140, 140)],
		"links": [[0, 1], [1, 2], [2, 3], [3, 0]],
		"budget": 1200.0, "time": 520.0,
	},
]

var c                          ## AgentColony
var level := 0
var mask := PackedByteArray()  ## 1 = ô thuộc hình đích
var claimed := PackedByteArray()   ## 1 = ô khuẩn lạc đã từng chiếm (KHÔNG xoá được)
var molds: Array = []          ## {pos, r}
var dries: Array = []          ## {pos, r}
var budget := 0.0
var budget_max := 0.0
var time_limit := 0.0
var elapsed := 0.0
var state := PLAYING
var lose_reason := ""
var events: Array = []         ## view đọc rồi tự clear
var auto_events := true        ## tắt để test lõi tất định
var iou := 0.0
var cover := 0.0
var spill := 0.0
var mold_on_target := 0.0
var target_cells := 0
var rng := RandomNumberGenerator.new()

var _sched: Array = []
var _mold_cd := 0.0
var _score_cd := 0.0


func _init(level_idx: int = 0, seed_val: int = 0) -> void:
	rng.seed = seed_val if seed_val != 0 else 2024
	c = AgentColony.new(rng.seed)
	c.auto_threat = false      # màn này không dùng phage/rival — khó khăn là MẤT THỨC ĂN
	mask.resize(NF * NF)
	claimed.resize(NF * NF)
	load_level(level_idx)


func load_level(idx: int) -> void:
	level = clampi(idx, 0, LEVELS.size() - 1)
	_build_mask()
	reset()


func spec() -> Dictionary:
	return LEVELS[level]


func nodes() -> Array:
	return LEVELS[level]["nodes"]


func links() -> Array:
	return LEVELS[level]["links"]


func reset() -> void:
	c.set_environment(MOTILITY, HARDNESS, RICHNESS)
	c.reset()
	c.seed_at(nodes()[0], 10, 15.0)
	for i in claimed.size():
		claimed[i] = 0
	molds.clear()
	dries.clear()
	events.clear()
	budget_max = spec()["budget"]
	time_limit = spec()["time"]
	budget = budget_max
	elapsed = 0.0
	state = PLAYING
	lose_reason = ""
	iou = 0.0; cover = 0.0; spill = 0.0; mold_on_target = 0.0
	_mold_cd = MOLD_GRACE
	_score_cd = 0.0
	# Lịch biến cố tính theo TỈ LỆ thời hạn màn → hình dài hơn thì gặp đúng ngần ấy đợt.
	_sched = []
	for f in [0.19, 0.39, 0.59, 0.80]:
		var kind := "dry" if is_equal_approx(f, 0.39) else "drip"
		_sched.append({"t": time_limit * f, "kind": kind, "warned": false,
			"fired": false, "pos": Vector2.ZERO})
	_claim()      # ổ cấy tính là đã chiếm ngay
	_rescore()


# ─────────────────────────── hình đích ───────────────────────────

func _build_mask() -> void:
	target_cells = 0
	var ns := nodes()
	var ls := links()
	for i in mask.size():
		var w := _cell_world(i)
		var inside := false
		for n in ns:
			if w.distance_to(n) <= NODE_R:
				inside = true
				break
		if not inside:
			for l in ls:
				if _dist_to_seg(w, ns[l[0]], ns[l[1]]) <= LINK_HW:
					inside = true
					break
		mask[i] = 1 if inside else 0
		if inside:
			target_cells += 1


func _cell_world(i: int) -> Vector2:
	return Vector2((i % NF + 0.5) * CELL - DISH_R, (i / NF + 0.5) * CELL - DISH_R)


func _dist_to_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func in_target(pos: Vector2) -> bool:
	var i := _cell_of(pos)
	return i >= 0 and mask[i] == 1


func _cell_of(pos: Vector2) -> int:
	var cx := int((pos.x + DISH_R) / CELL)
	var cy := int((pos.y + DISH_R) / CELL)
	if cx < 0 or cy < 0 or cx >= NF or cy >= NF:
		return -1
	return cy * NF + cx


# ─────────────────────────── hành động người chơi ───────────────────────────

## Rải một nhát. Trả "" nếu rải được, còn lại là lý do (để view giải thích).
func deposit(pos: Vector2) -> String:
	if state != PLAYING:
		return "màn đã kết thúc"
	if budget < DOSE:
		return "hết ngân sách dinh dưỡng"
	if pos.length() > DISH_R - 8.0:
		return "ngoài đĩa"
	c.add_nutrient(pos, DOSE)
	budget -= DOSE
	return ""


func doses_left() -> int:
	return int(budget / DOSE)


## Chỗ này khuẩn còn "giữ" được không? Rải ngoài tầm với là bỏ mồi cho mốc — view dùng
## cái này tô con trỏ xanh/vàng để người chơi THẤY ranh giới thay vì phải đoán.
func reach_ok(pos: Vector2) -> bool:
	return _nearest_agent_dist(pos) < MOLD_FREE


func can_seal() -> bool:
	return state == PLAYING and iou >= WIN_IOU


## CHỐT: khoá kết quả lại. Chỉ bấm được khi hình đã đủ khớp.
func seal() -> bool:
	if not can_seal():
		return false
	state = WON
	events.append({"kind": "win", "iou": iou})
	return true


## 3 sao cơ bản, +1 nếu khớp đẹp, +1 nếu còn dư ngân sách (rải tiết kiệm).
func stars() -> int:
	var q := 3
	if iou >= WIN_IOU + 0.10: q += 1
	if budget >= budget_max * 0.18: q += 1
	return clampi(q, 1, 5)


# ─────────────────────────── một khung ───────────────────────────

func update(dt: float) -> void:
	if state != PLAYING:
		return
	elapsed += dt
	c.update(dt)
	_claim()
	_step_molds(dt)
	_step_dries(dt)
	if auto_events:
		_seek_mold(dt)
		_run_events()
	_score_cd -= dt
	if _score_cd <= 0.0:
		_score_cd = SCORE_EVERY
		_rescore()
	_check_lose()


## Khuẩn đi tới đâu thì SƠN vệt tới đó. Vệt tích luỹ (84 con sống cùng lúc là quá ít để
## "vẽ" hình, nhưng dấu chân của chúng theo thời gian thì đủ) và KHÔNG bao giờ xoá.
func _claim() -> void:
	var rc := int(ceil(CLAIM_R / CELL))
	for a in c.agents:
		if a["state"] == AgentColony.DORMANT:
			continue
		var i0 := _cell_of(a["pos"])
		if i0 < 0:
			continue
		var ccx := i0 % NF
		var ccy := i0 / NF
		for dy in range(-rc, rc + 1):
			for dx in range(-rc, rc + 1):
				var cx := ccx + dx
				var cy := ccy + dy
				if cx < 0 or cy < 0 or cx >= NF or cy >= NF:
					continue
				var i := cy * NF + cx
				if claimed[i] == 1:
					continue
				if a["pos"].distance_to(_cell_world(i)) <= CLAIM_R:
					claimed[i] = 1


func _rescore() -> void:
	var inter := 0
	var claim := 0
	var mold_hit := 0
	for i in mask.size():
		var m := mask[i]
		if claimed[i] == 1:
			claim += 1
			if m == 1:
				inter += 1
		if m == 1 and _mold_covers(_cell_world(i)):
			mold_hit += 1
	var uni := claim + target_cells - inter
	iou = float(inter) / maxf(1.0, float(uni))
	cover = float(inter) / maxf(1.0, float(target_cells))
	spill = float(claim - inter) / maxf(1.0, float(claim))
	mold_on_target = float(mold_hit) / maxf(1.0, float(target_cells))


func _mold_covers(w: Vector2) -> bool:
	for m in molds:
		if w.distance_to(m["pos"]) <= m["r"]:
			return true
	return false


# ─────────────────────────── khó khăn: MẤT THỨC ĂN ───────────────────────────

## Bào tử mốc bén vào chỗ dinh dưỡng GIÀU mà khuẩn CHƯA tới — tức là chỗ người chơi rải
## quá tay hoặc rải quá xa rìa. Đây chính là hình phạt cho "đổ thức ăn bừa".
func _seek_mold(dt: float) -> void:
	_mold_cd -= dt
	if _mold_cd > 0.0 or molds.size() >= MOLD_MAX:
		return
	_mold_cd = MOLD_SCAN
	var best := -1
	var best_v := MOLD_NUT
	for i in c.nut.size():
		var v: float = c.nut[i]
		if v <= best_v:
			continue
		var w := _cell_world(i)
		if w.length() > DISH_R - 14.0:
			continue
		if _nearest_agent_dist(w) < MOLD_FREE:
			continue          # đã có khuẩn giữ chỗ → niche không trống
		if _mold_covers(w):
			continue
		best_v = v
		best = i
	if best < 0:
		return
	var pos := _cell_world(best)
	molds.append({"pos": pos, "r": MOLD_R0})
	events.append({"kind": "mold", "pos": pos})


func _nearest_agent_dist(w: Vector2) -> float:
	var d := INF
	for a in c.agents:
		d = minf(d, w.distance_squared_to(a["pos"]))
	return sqrt(d)


## Mốc chỉ lớn được KHI CÒN DINH DƯỠNG dưới chân — ăn sạch chỗ đó thì nó lụi. Nhờ vậy
## mảng mốc là hậu quả CÓ HẠN của một nhát rải hỏng, không phải án tử của cả màn.
func _step_molds(dt: float) -> void:
	for m in molds:
		if c.nutrient_at(m["pos"]) > MOLD_FEED:
			m["r"] = minf(MOLD_RMAX, m["r"] + MOLD_GROW * dt)
		else:
			m["r"] -= MOLD_SHRINK * dt
		_scale_nut_in(m["pos"], m["r"], MOLD_EAT * dt)     # mốc ĂN SẠCH dinh dưỡng vùng nó
		var rr: float = m["r"] * m["r"]
		for a in c.agents:
			if a["pos"].distance_squared_to(m["pos"]) <= rr:
				a["energy"] = maxf(0.0, a["energy"] - MOLD_HARM * dt)
	molds = molds.filter(func(m): return m["r"] > 2.0)


func _step_dries(dt: float) -> void:
	for d in dries:
		_scale_nut_in(d["pos"], d["r"], DRY_DECAY * dt)


## Bào mòn dinh dưỡng trong một vùng (dùng cho mốc ăn / khô / giọt rửa trôi).
## Trả về TỔNG dinh dưỡng đã mất — để biến cố nói được "mất bao nhiêu" và test đo được.
func _scale_nut_in(pos: Vector2, r: float, amount: float) -> float:
	var rc := int(ceil(r / CELL))
	var i0 := _cell_of(pos)
	if i0 < 0:
		return 0.0
	var ccx := i0 % NF
	var ccy := i0 / NF
	var k := clampf(amount, 0.0, 1.0)
	var lost := 0.0
	for dy in range(-rc, rc + 1):
		for dx in range(-rc, rc + 1):
			var cx := ccx + dx
			var cy := ccy + dy
			if cx < 0 or cy < 0 or cx >= NF or cy >= NF:
				continue
			var i := cy * NF + cx
			if _cell_world(i).distance_to(pos) <= r:
				var before: float = c.nut[i]
				c.nut[i] = before * (1.0 - k)
				lost += before - c.nut[i]
	return lost


func _run_events() -> void:
	for e in _sched:
		if not e["warned"] and elapsed >= e["t"] - WARN_LEAD:
			e["warned"] = true
			e["pos"] = _pick_hot()        # chốt chỗ rơi TỪ LÚC CẢNH BÁO → người chơi né được
			events.append({"kind": "warn", "ev": e["kind"], "pos": e["pos"]})
		if not e["fired"] and elapsed >= e["t"]:
			e["fired"] = true
			var lost := _apply_event(e["kind"], e["pos"])
			events.append({"kind": "event", "ev": e["kind"], "pos": e["pos"], "lost": lost})


## Chỗ "ướt" nhất = chỗ nhiều dinh dưỡng nhất (SÁNG TẠO: giọt thật thì rơi ngẫu nhiên,
## nhắm vào chỗ giàu cho biến cố luôn có sức nặng — nhưng đã báo trước nên vẫn công bằng).
func _pick_hot() -> Vector2:
	var best := -1
	var best_v := 0.15
	for i in c.nut.size():
		var v: float = c.nut[i]
		if v > best_v and _cell_world(i).length() < DISH_R - 20.0:
			best_v = v
			best = i
	if best < 0:
		var a := rng.randf() * TAU
		return Vector2(cos(a), sin(a)) * sqrt(rng.randf()) * (DISH_R - 60.0)
	return _cell_world(best)


## Trả về lượng dinh dưỡng MẤT NGAY (vùng khô thì mất dần về sau nên trả 0).
func _apply_event(kind: String, pos: Vector2) -> float:
	match kind:
		"drip":
			return _scale_nut_in(pos, DRIP_R, DRIP_WASH)      # rửa trôi
		"dry":
			dries.append({"pos": pos, "r": DRY_R})
	return 0.0


func _check_lose() -> void:
	if mold_on_target >= MOLD_LOSE:
		state = LOST
		lose_reason = "mốc đã chiếm hình đích"
	elif elapsed > time_limit:
		state = LOST
		lose_reason = "hết giờ, hình chưa khớp đủ"
	elif budget < DOSE and c.total_nutrient() < 0.6 and iou < WIN_IOU:
		# Hết ngân sách mới là thua khi hình CHƯA đủ khớp — còn khớp rồi thì cứ để người
		# chơi CHỐT, đừng cướp một ván đang thắng.
		state = LOST
		lose_reason = "hết ngân sách mà hình còn dở"
	elif c.population() == 0:
		state = LOST
		lose_reason = "khuẩn lạc chết sạch"
	if state == LOST:
		events.append({"kind": "lose", "why": lose_reason})
