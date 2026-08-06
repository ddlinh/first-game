extends RefCounted

## MÀN YAOURT — lõi mô phỏng, KHÔNG biết gì tới màn hình, test headless được.
## Không class_name — nạp bằng preload.
##
## BÁM SINH HỌC THẬT (xem CO-SO-KHOA-HOC.md):
##  · Hai loài CỘNG SINH: S. thermophilus (ưa ~40°C, pH cao) khởi động, thải formate;
##    L. bulgaricus (ưa ~44°C, ưa axit) phân giải casein → peptide nuôi lại. Mỗi loài
##    cần loài kia → phải giữ CẢ HAI. Khi pH tụt, quyền dẫn TRAO TAY sang L. bulgaricus.
##  · Cả hai bơm axit lactic → pH 6.7 → 4.6 (điểm đẳng điện casein) → ĐÔNG = thắng.
##  · Mốc/tạp nhiễm luôn chực chờ, bị axit ĐÈ (competitive exclusion); nhiệt lệch → mốc thắng.
##  · Người chơi CHỈNH MÔI TRƯỜNG bằng HÀNH ĐỘNG (ủ ấm/làm mát/quấn/thêm men/tiệt trùng),
##    không phải slider. pH là ĐẦU RA, không chỉnh thẳng.

enum { PLAYING, WON, LOST }

const PH_START := 6.7
const PH_SET := 4.6            ## casein đông ở điểm đẳng điện
const PH_OVERSOUR := 3.85      ## lố → tách whey (thua)
const PH_FLOOR := 3.6
const SPOIL_LOSE := 0.62
const T_OPT_ST := 40.0         ## S. thermophilus ưa ~40°C
const T_OPT_LB := 44.0         ## L. bulgaricus ưa ~44°C
const TEMP_DEATH := 50.0
const TIME_LIMIT := 220.0

# hành động
const STOVE_STEP := 12.0
const WRAP_TIME := 8.0
const STARTER_ST := 0.10
const STARTER_LB := 0.08
const SANITIZE := 0.30

var temp := 28.0
var stove := 30.0             ## "bếp" 0..100 → nhiệt mục tiêu
var wrap := 0.0
var pH := PH_START
var st := 0.06                ## S. thermophilus
var lb := 0.05                ## L. bulgaricus
var spoil := 0.05
var elapsed := 0.0
var state := PLAYING
var lose_reason := ""
var auto_events := true        ## tắt để test lõi tất định
var events: Array = []        ## cho view đọc (toast/hiệu ứng), view tự clear
var _sched: Array = []
var rng := RandomNumberGenerator.new()


func _init(seed_val: int = 0) -> void:
	rng.seed = seed_val if seed_val != 0 else 4242
	reset()


func reset() -> void:
	temp = 28.0; stove = 30.0; wrap = 0.0; pH = PH_START
	st = 0.06; lb = 0.05; spoil = 0.05
	elapsed = 0.0; state = PLAYING; lose_reason = ""
	events.clear()
	_sched = [
		{"t": 24.0, "kind": "draft", "warned": false, "fired": false},
		{"t": 46.0, "kind": "phage", "warned": false, "fired": false},
		{"t": 66.0, "kind": "contam", "warned": false, "fired": false},
	]


# ─────────────────────────── hành động người chơi ───────────────────────────

func warm() -> void:    stove = clampf(stove + STOVE_STEP, 0.0, 100.0)
func cool() -> void:    stove = clampf(stove - STOVE_STEP, 0.0, 100.0)
func wrap_jar() -> void: wrap = WRAP_TIME
func add_starter() -> void:
	st = clampf(st + STARTER_ST, 0.0, 1.0)
	lb = clampf(lb + STARTER_LB, 0.0, 1.0)
	spoil = clampf(spoil + 0.03, 0.0, 1.0)   # mở nắp → chút nguy cơ
func sanitize() -> void: spoil = clampf(spoil - SANITIZE, 0.0, 1.0)

func can_chill() -> bool:
	return state == PLAYING and pH <= PH_SET

## Hành động CHỐT: chỉ bấm được khi đã tới 4.6. Trả true nếu chốt (thắng/thua tuỳ chất lượng).
func chill() -> bool:
	if not can_chill():
		return false
	if pH >= PH_OVERSOUR and spoil < 0.4:
		state = WON
	else:
		state = LOST
		lose_reason = "quá chua, whey tách ra"
	return true


func culture() -> float:
	return clampf(st + lb, 0.0, 1.0)

## Ai đang dẫn: -1 = S.thermophilus, 1 = L.bulgaricus (để view minh hoạ trao tay).
func leader() -> int:
	return 1 if lb > st else -1

## Sao chất lượng khi thắng (giữ nhiệt sát + chốt gần 4.6 + ít mốc).
func stars() -> int:
	var q := 3
	if absf(pH - PH_SET) < 0.12: q += 1
	if spoil < 0.2: q += 1
	return clampi(q, 1, 5)


# ─────────────────────────── một khung ───────────────────────────

func update(dt: float) -> void:
	if state != PLAYING:
		return
	elapsed += dt

	# nhiệt bò về mục tiêu; quấn khăn giữ ổn (chậm đổi)
	var target := 20.0 + stove * 0.30
	var rate := 0.35 if wrap > 0.0 else 0.70
	temp += (target - temp) * clampf(rate * dt, 0.0, 1.0)
	if wrap > 0.0:
		wrap -= dt

	# tăng trưởng: chuông nhiệt riêng + ưa pH riêng + CỘNG SINH (cần loài kia)
	var tf_st := _bell(temp, T_OPT_ST, 9.0)
	var tf_lb := _bell(temp, T_OPT_LB, 9.0)
	var ph_st := clampf((pH - 4.4) / 2.0, 0.15, 1.0)       # st ưa pH CAO → chậm khi chua
	var ph_lb := clampf((6.9 - pH) / 1.6, 0.30, 1.0)       # lb ưa AXIT → nhanh khi chua
	var mut_st := 0.4 + 0.6 * minf(lb / 0.15, 1.0)         # st cần peptide của lb
	var mut_lb := 0.4 + 0.6 * minf(st / 0.15, 1.0)         # lb cần formate của st
	var cul := culture()
	st = clampf(st + tf_st * ph_st * mut_st * 0.70 * st * (1.0 - cul) * dt, 0.0, 1.0)
	lb = clampf(lb + tf_lb * ph_lb * mut_lb * 0.70 * lb * (1.0 - cul) * dt, 0.0, 1.0)
	if temp > TEMP_DEATH:                                  # nóng quá → men chết
		var kill := (temp - TEMP_DEATH) * 0.05 * dt
		st = maxf(0.0, st - kill); lb = maxf(0.0, lb - kill)

	# axit lactic → pH xuống (mạnh nhất khi nhiệt tốt)
	var acid := culture() * 0.28 * _bell(temp, 42.0, 11.0)
	pH = maxf(PH_FLOOR, pH - acid * dt)

	# TRAO TAY: pH thấp ức chế S. thermophilus → nhường sức chứa cho L. bulgaricus (aciduric)
	if pH < 5.3:
		st = maxf(0.0, st - (5.3 - pH) * 0.16 * dt)

	# mốc: tăng chậm khi nhiệt lệch + pH còn cao; men (axit) đè lại
	var heat := clampf(1.0 - absf(temp - 43.0) / 12.0, 0.0, 1.0)
	var room := clampf((pH - 4.5) / 2.0, 0.0, 1.0)
	spoil = clampf(spoil + ((0.09 - heat * 0.07) * room - culture() * 0.10) * dt, 0.0, 1.0)

	_run_events()
	_check_lose()


func _run_events() -> void:
	if not auto_events:
		return
	for e in _sched:
		if not e["warned"] and elapsed >= e["t"] - 4.0:
			e["warned"] = true
			events.append({"kind": "warn", "ev": e["kind"]})
		if not e["fired"] and elapsed >= e["t"]:
			e["fired"] = true
			_apply_event(e["kind"])
			events.append({"kind": "event", "ev": e["kind"]})


func _apply_event(kind: String) -> void:
	match kind:
		"draft":
			var drop := 4.0 if wrap > 0.0 else 11.0
			temp -= drop
			stove = clampf(stove - (4.0 if wrap > 0.0 else 10.0), 0.0, 100.0)
		"phage":
			if culture() > 0.35:
				st *= 0.45; lb *= 0.45
		"contam":
			spoil = clampf(spoil + 0.22, 0.0, 1.0)


func _check_lose() -> void:
	if spoil >= SPOIL_LOSE:
		state = LOST; lose_reason = "mốc đã chiếm mẻ"
	elif pH < PH_OVERSOUR:
		state = LOST; lose_reason = "quá chua, whey tách ra"
	elif temp > TEMP_DEATH + 2.0 and culture() < 0.06:
		state = LOST; lose_reason = "nóng quá, men chết"
	elif elapsed > TIME_LIMIT:
		state = LOST; lose_reason = "hết giờ, chưa tới pH 4.6"
	if state == LOST:
		events.append({"kind": "lose", "why": lose_reason})


func _bell(x: float, center: float, width: float) -> float:
	return clampf(1.0 - absf(x - center) / width, 0.0, 1.0)
