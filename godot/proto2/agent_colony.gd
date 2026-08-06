extends RefCounted

## Lõi mô phỏng AGENT — mỗi con khuẩn là một CÁ THỂ có việc làm nhìn thấy được.
## Tách khỏi phần vẽ để test headless. Không class_name — nạp bằng preload.
##
## BÁM SINH HỌC THẬT:
##  · LAN: dinh dưỡng là TRƯỜNG khuếch tán bị ăn mòn cục bộ; khuẩn đi bằng
##    RUN-AND-TUMBLE (hoá hướng động E. coli), không nhắm đích ở xa.
##  · CROSS-FEEDING: khuẩn ăn dinh dưỡng thì THẢI phế phẩm (trường `waste`). Một
##    chủng CROSS-FEEDER trôi tới bén rễ ở chỗ phế phẩm đọng, ĂN phế phẩm và TÁI CHẾ
##    lại thành dinh dưỡng — mutualism hai chiều có thật.
##  · NGUỒN vi khuẩn mới = NHIỄM TẠP + CHIẾM NICHE: phage bén vào chỗ khuẩn ĐÔNG
##    (cần mật độ vật chủ cao); cross-feeder bén vào chỗ PHẾ PHẨM đọng (niche trống).
##  · BIOFILM do chính khuẩn tiết ra, chỉ ở chỗ ĐỦ ĐÔNG (quorum sensing) — người chơi
##    chỉ CHỈ ĐỊNH, cụm phải đạt mật độ thì mới kết được.
##  · CẠNH TRANH LIÊN KHUẨN: một chủng RIVAL trôi vào tranh niche dinh dưỡng. Khuẩn nhà
##    diệt nó bằng T6SS — vũ khí ĐÂM-CHẠM (contact-dependent), khác hẳn colicin (khuếch
##    tán, tầm xa, diệt phage). T6SS là nanomachine co rút đồng nguồn với đuôi phage.

enum { FORAGE, EAT, DIVIDE, DORMANT, DEFEND, INFECTED, BUILD, STAB }

const STATE_NAME := {
	FORAGE: "kiếm ăn", EAT: "đang ăn", DIVIDE: "phân đôi", DORMANT: "ngủ đông",
	DEFEND: "phòng thủ", INFECTED: "nhiễm phage", BUILD: "xây biofilm",
	STAB: "đâm giáo (T6SS)",
}

const DISH_R := 300.0
const MAX_POP := 84

# ── di chuyển: run-and-tumble ──
const SPEED := 42.0
const TUMBLE_HAPPY := 0.03
const TUMBLE_SAD := 0.28
const SESSILE_THRESH := 0.35   ## _mot dưới ngưỡng này = coi như KHÔNG di động (mọc tại chỗ)
const DIVIDE_STEP := 13.0      ## con mới của chủng định cư đặt cách xa cỡ này về phía có ăn
const ENERGY_DECAY := 0.05
const DIVIDE_ENERGY := 1.0
const DIVIDE_TIME := 1.0
const DORMANT_ENERGY := 0.08

# ── trường: dinh dưỡng (nut) + phế phẩm (waste) ──
const NF := 80
const CELL := 2.0 * DISH_R / NF
const FIELD_MAX := 2.5
const DEPOSIT_R := 26.0
const EAT_MIN := 0.06
const ENERGY_GAIN := 0.9
const FIELD_EAT := 0.9
const DIFFUSE := 3.0
const FIELD_DECAY := 0.04
const WASTE_EXCRETE := 0.5    ## phế phẩm thải ra khi ăn (nồng độ/giây)
const WASTE_DECAY := 0.06

# ── cross-feeder (bén vào niche phế phẩm, tái chế phế phẩm → dinh dưỡng) ──
const CF_MAX := 4
const CF_COOLDOWN := 11.0
const CF_LIFE := 42.0
const CF_SPEED := 34.0
const CF_NICHE := 0.4         ## nồng độ phế phẩm đủ để cross-feeder bén rễ / ăn
const CF_EAT := 0.7           ## phế phẩm ăn/giây
const CF_RECYCLE := 0.5       ## dinh dưỡng tái chế trả lại/giây

const SEP_R := 15.0

# ── biofilm: quorum sensing (TỰ kết khi đủ đông) ──
const QUORUM_R := 28.0        ## bán kính "cảm" hàng xóm
const QUORUM_N := 8           ## đủ ngần này con quây lại thì khuẩn TỰ tiết chất nền
const FORM_INTERVAL := 0.6    ## nhịp kiểm tra tự-kết-biofilm
const BIOFILM_CAP := 6
const BUILD_NEED := 1.0
const BUILD_RANGE := 17.0
const BUILD_RATE := 0.14
const BUILD_COST := 0.12
const BUILDER_MIN := 0.45
const RECRUIT_R := 140.0
const MAX_BUILDERS := 4
const SHELTER_R := 36.0

const PHAGE_SPEED := 58.0
const INFECT_RADIUS := 11.0
const INFECT_TIME := 2.6
const DEFEND_RANGE := 50.0
const TOXIN_RADIUS := 30.0
const TOXIN_COOLDOWN := 0.7

# ── nhiễm phage (đông → bén vào) ──
const THREAT_POP := 46
const THREAT_WAVE := 5
const THREAT_COOLDOWN := 15.0
const THREAT_GRACE := 8.0

# ── chủng RIVAL cạnh tranh + T6SS (đâm-chạm, khác colicin khuếch tán) ──
const RIVAL_MAX := 5
const RIVAL_POP := 28           ## khuẩn lạc thịnh → đối thủ trôi vào tranh niche
const RIVAL_WAVE := 3
const RIVAL_COOLDOWN := 13.0
const RIVAL_LIFE := 40.0
const RIVAL_SPEED := 34.0
const RIVAL_EAT := 0.6          ## rival cũng ăn dinh dưỡng (cạnh tranh kinh tế)
const T6SS_SENSE := 26.0        ## khuẩn nhà "thấy" rival trong tầm này thì lao tới đâm
const T6SS_RANGE := 12.0        ## CHẠM mới đâm được (contact-dependent) — khác colicin tầm 30
const T6SS_COOLDOWN := 0.6

var agents: Array = []
var nut := PackedFloat32Array()
var waste := PackedFloat32Array()
var phages: Array = []
var buildings: Array = []
var crossfeeders: Array = []   ## {pos, heading, prev, life}
var rivals: Array = []         ## chủng cạnh tranh {pos, heading, prev, life, cd}
var rng := RandomNumberGenerator.new()

## RẢI THỨC ĂN LÀ MỘT NGHỀ: ngân sách dinh dưỡng có hạn, hồi theo thời gian → rải ở đâu
## mới đáng. Rải lên chỗ đã bão hoà (trường chạm trần FIELD_MAX) là PHÍ ngân sách → kỹ
## năng là "đón đầu rìa đang mọc". Người chơi dùng deposit(); add_nutrient() vẫn thô (test).
const NUT_BUDGET_MAX := 120.0
const NUT_REGEN := 14.0        ## hồi/giây
var nutrient_budget := NUT_BUDGET_MAX

## Đặc tính CHỦNG × MÔI TRƯỜNG — một màn cấu hình một tổ hợp (xem set_environment):
##   motility      : đặc tính chủng, 0 = không di động (giữ hình), 1 = bơi khoẻ (lan)
##   agar_hardness : môi trường, 1 = thạch cứng (ghìm di động → giữ hình), 0 = mềm (bầy đàn)
##   richness      : môi trường, 1 = giàu (mọc đặc), thấp = nghèo (mọc nhánh, giới hạn khuếch tán)
## _mot là độ di động HIỆU DỤNG suy ra từ ba số trên (thạch cứng làm chủng bơi cũng ghìm lại).
var motility := 1.0
var agar_hardness := 0.4
var richness := 1.0
var _mot := 1.0

var elapsed := 0.0
var events: Array = []
var auto_threat := true
var _threat_cd := 0.0
var _cf_cd := 0.0
var _rival_cd := 0.0
var _form_timer := 0.0


func _init(seed_val: int = 0) -> void:
	rng.seed = seed_val if seed_val != 0 else 12345
	nut.resize(NF * NF)
	waste.resize(NF * NF)
	_recompute_mot()
	reset()


## Một màn cấu hình một tổ hợp chủng × môi trường (không giữ trạng thái colony).
func set_environment(strain_motility: float, hardness: float, rich: float) -> void:
	motility = strain_motility
	agar_hardness = hardness
	richness = rich
	_recompute_mot()


func _recompute_mot() -> void:
	# Thạch cứng (hardness→1) ghìm di động; mềm (→0) khuếch đại thành bầy đàn.
	_mot = clampf(motility * (0.2 + 1.6 * (1.0 - agar_hardness)), 0.0, 1.6)


func reset() -> void:
	agents.clear()
	phages.clear()
	buildings.clear()
	crossfeeders.clear()
	rivals.clear()
	events.clear()
	for i in nut.size():
		nut[i] = 0.0
		waste[i] = 0.0
	elapsed = 0.0
	nutrient_budget = NUT_BUDGET_MAX
	_threat_cd = THREAT_GRACE
	_cf_cd = THREAT_GRACE
	_rival_cd = THREAT_GRACE
	_form_timer = 0.0
	for i in 10:
		agents.append(_new_agent(_rand_in_dish(70.0), 0.55))


func _new_agent(pos: Vector2, energy: float) -> Dictionary:
	var ang := rng.randf() * TAU
	return {"pos": pos, "vel": Vector2.ZERO, "heading": Vector2(cos(ang), sin(ang)),
		"prev_nut": 0.0, "state": FORAGE, "energy": energy, "timer": 0.0, "flash": 0.0,
		"build": -1}


func _rand_in_dish(radius: float) -> Vector2:
	var a := rng.randf() * TAU
	return Vector2(cos(a), sin(a)) * sqrt(rng.randf()) * radius


# ─────────────────────────── trường ───────────────────────────

func _cell(pos: Vector2) -> int:
	var cx := int((pos.x + DISH_R) / CELL)
	var cy := int((pos.y + DISH_R) / CELL)
	if cx < 0 or cy < 0 or cx >= NF or cy >= NF:
		return -1
	return cy * NF + cx


func _cell_world(i: int) -> Vector2:
	return Vector2((i % NF + 0.5) * CELL - DISH_R, (i / NF + 0.5) * CELL - DISH_R)


func nutrient_at(pos: Vector2) -> float:
	var i := _cell(pos)
	return nut[i] if i >= 0 else 0.0


func waste_at(pos: Vector2) -> float:
	var i := _cell(pos)
	return waste[i] if i >= 0 else 0.0


func add_nutrient(pos: Vector2, amount: float) -> void:
	var strength := amount * 0.10 * richness   # môi trường nghèo → nhát rải mỏng hơn
	var rc := int(ceil(DEPOSIT_R / CELL))
	var c0 := _cell(pos)
	if c0 < 0:
		return
	var ccx := c0 % NF
	var ccy := c0 / NF
	for dy in range(-rc, rc + 1):
		for dx in range(-rc, rc + 1):
			var cx := ccx + dx
			var cy := ccy + dy
			if cx < 0 or cy < 0 or cx >= NF or cy >= NF:
				continue
			var wc := Vector2((cx + 0.5) * CELL - DISH_R, (cy + 0.5) * CELL - DISH_R)
			var f := 1.0 - pos.distance_to(wc) / DEPOSIT_R
			if f > 0.0:
				var i := cy * NF + cx
				nut[i] = minf(FIELD_MAX, nut[i] + strength * f)


## Rải của NGƯỜI CHƠI — tiêu ngân sách, không rải quá cái đang có. Trả về lượng đã rải
## thật (để view phản hồi). Rải lên chỗ bão hoà vẫn tốn ngân sách mà trường không tăng
## thêm (add_nutrient tự chặn ở FIELD_MAX) → "phí", đó là chỗ để rèn kỹ năng đón rìa.
func deposit(pos: Vector2, amount: float) -> float:
	var applied := minf(amount, nutrient_budget)
	if applied <= 0.0:
		return 0.0
	add_nutrient(pos, applied)
	nutrient_budget -= applied
	return applied


func _add_nut(pos: Vector2, amt: float) -> void:
	var i := _cell(pos)
	if i >= 0:
		nut[i] = minf(FIELD_MAX, nut[i] + amt)


func _deplete_nut(pos: Vector2, amt: float) -> void:
	var i := _cell(pos)
	if i >= 0:
		nut[i] = maxf(0.0, nut[i] - amt)


func _add_waste(pos: Vector2, amt: float) -> void:
	var i := _cell(pos)
	if i >= 0:
		waste[i] = minf(FIELD_MAX, waste[i] + amt)


func _deplete_waste(pos: Vector2, amt: float) -> void:
	var i := _cell(pos)
	if i >= 0:
		waste[i] = maxf(0.0, waste[i] - amt)


## Khuếch tán nhẹ + nhạt dần. Trả về mảng mới (né bẫy copy-on-write của Packed).
func _diffused(src: PackedFloat32Array, delta: float, decay_rate: float) -> PackedFloat32Array:
	var out := src.duplicate()
	var blend := clampf(DIFFUSE * delta, 0.0, 0.5)
	var decay := 1.0 - decay_rate * delta
	for cy in NF:
		for cx in NF:
			var i := cy * NF + cx
			var v: float = src[i]
			var s := 0.0
			var n := 0
			if cx > 0: s += src[i - 1]; n += 1
			if cx < NF - 1: s += src[i + 1]; n += 1
			if cy > 0: s += src[i - NF]; n += 1
			if cy < NF - 1: s += src[i + NF]; n += 1
			out[i] = (v * (1.0 - blend) + (s / maxf(1.0, float(n))) * blend) * decay
	return out


func total_nutrient() -> float:
	var t := 0.0
	for v in nut:
		t += v
	return t


func local_density(pos: Vector2, r: float) -> int:
	var rr := r * r
	var c := 0
	for a in agents:
		if pos.distance_squared_to(a["pos"]) <= rr:
			c += 1
	return c


func max_local_density() -> int:
	var m := 0
	for a in agents:
		var n := local_density(a["pos"], QUORUM_R)
		if n > m:
			m = n
	return m


## Quorum sensing: chỗ nào khuẩn quây đủ đông thì chúng TỰ tiết chất nền kết biofilm.
## Không ai đặt — người chơi chỉ dồn khuẩn cho đông bằng cách cho ăn.
func _maybe_form_biofilm(delta: float) -> void:
	_form_timer -= delta
	if _form_timer > 0.0 or buildings.size() >= BIOFILM_CAP:
		return
	_form_timer = FORM_INTERVAL
	var best = null
	var bestn := 0
	for a in agents:
		var n := local_density(a["pos"], QUORUM_R)
		if n > bestn:
			bestn = n
			best = a
	if best == null or bestn < QUORUM_N:
		return
	for b in buildings:
		if best["pos"].distance_to(b["pos"]) < SHELTER_R * 1.4:
			return
	buildings.append({"pos": best["pos"], "progress": 0.0, "active": false})
	events.append({"kind": "biofilm_formed", "pos": best["pos"]})


# ─────────────────────────── điều khiển ngoài ───────────────────────────

## Biofilm chỉ kết được ở chỗ ĐỦ ĐÔNG (quorum sensing). Trả "" nếu đặt được, còn lại
## là lý do (để giao diện giải thích).
func place_building(pos: Vector2) -> String:
	if pos.length() > DISH_R - SHELTER_R:
		return "quá sát rìa đĩa"
	for b in buildings:
		if pos.distance_to(b["pos"]) < SHELTER_R:
			return "đã có biofilm ở đó"
	if local_density(pos, QUORUM_R) < QUORUM_N:
		return "chưa đủ đông — biofilm cần mật độ (quorum sensing)"
	buildings.append({"pos": pos, "progress": 0.0, "active": false})
	return ""


func spawn_phages(n: int) -> void:
	for i in n:
		phages.append({"pos": Vector2(cos(TAU * i / n), sin(TAU * i / n)) * (DISH_R - 10.0),
			"vel": Vector2.ZERO})


func population() -> int:
	return agents.size()


func spawn_rivals(n: int) -> void:
	for i in n:
		var a := TAU * i / maxf(1.0, float(n)) + rng.randf()
		var ang := rng.randf() * TAU
		rivals.append({"pos": Vector2(cos(a), sin(a)) * (DISH_R - 12.0),
			"heading": Vector2(cos(ang), sin(ang)), "prev": 0.0, "life": RIVAL_LIFE, "cd": 0.0})


func tally() -> Dictionary:
	var t := {FORAGE: 0, EAT: 0, DIVIDE: 0, DORMANT: 0, DEFEND: 0, INFECTED: 0, BUILD: 0, STAB: 0}
	for a in agents:
		t[a["state"]] += 1
	return t


# ─────────────────────────── một khung ───────────────────────────

func update(delta: float) -> void:
	elapsed += delta
	nutrient_budget = minf(NUT_BUDGET_MAX, nutrient_budget + NUT_REGEN * delta)
	nut = _diffused(nut, delta, FIELD_DECAY)
	waste = _diffused(waste, delta, WASTE_DECAY)

	if auto_threat:
		# Đông → phage bén vào (nhiễm tạp cần mật độ vật chủ cao).
		_threat_cd -= delta
		if _threat_cd <= 0.0 and population() >= THREAT_POP:
			spawn_phages(THREAT_WAVE)
			_threat_cd = THREAT_COOLDOWN
			events.append({"kind": "phage_wave", "pop": population()})
		# Phế phẩm đọng → cross-feeder trôi tới bén rễ (chiếm niche trống).
		_cf_cd -= delta
		if _cf_cd <= 0.0 and crossfeeders.size() < CF_MAX:
			var spot = _find_waste_niche()
			if spot != null:
				var ang := rng.randf() * TAU
				crossfeeders.append({"pos": spot, "heading": Vector2(cos(ang), sin(ang)),
					"prev": 0.0, "life": CF_LIFE})
				_cf_cd = CF_COOLDOWN
				events.append({"kind": "crossfeeder"})
		# Khuẩn lạc thịnh → chủng RIVAL trôi vào tranh niche (khuẩn nhà diệt bằng T6SS).
		_rival_cd -= delta
		if _rival_cd <= 0.0 and rivals.size() < RIVAL_MAX and population() >= RIVAL_POP:
			spawn_rivals(RIVAL_WAVE)
			_rival_cd = RIVAL_COOLDOWN
			events.append({"kind": "rival", "pop": population()})
		_maybe_form_biofilm(delta)

	_recruit_builders()

	var newborns: Array = []
	var new_phages: Array = []
	for a in agents:
		if a["flash"] > 0.0:
			a["flash"] -= delta
		_step_agent(a, delta, newborns, new_phages)

	_separate(delta)

	agents = agents.filter(func(a): return not a.get("dead", false))
	agents.append_array(newborns)

	_step_phages(delta)
	phages.append_array(new_phages)
	phages = phages.filter(func(p): return not p.get("dead", false))

	_step_crossfeeders(delta)
	_step_rivals(delta)


func _find_waste_niche():
	for _try in 40:
		var i := rng.randi() % nut.size()
		if waste[i] > CF_NICHE:
			var w := _cell_world(i)
			if w.length() < DISH_R - 10.0:
				return w
	return null


func _recruit_builders() -> void:
	for bi in buildings.size():
		var bld: Dictionary = buildings[bi]
		if bld["active"]:
			continue
		var count := 0
		for a in agents:
			if a.get("build", -1) == bi and not a.get("dead", false):
				count += 1
		var need := MAX_BUILDERS - count
		while need > 0:
			var best = null
			var best_d := RECRUIT_R * RECRUIT_R
			for a in agents:
				if a["state"] != FORAGE or a["energy"] < BUILDER_MIN or a.get("build", -1) != -1:
					continue
				var dd: float = a["pos"].distance_squared_to(bld["pos"])
				if dd < best_d:
					best_d = dd
					best = a
			if best == null:
				break
			best["state"] = BUILD
			best["build"] = bi
			need -= 1


func _step_agent(a: Dictionary, delta: float, newborns: Array, new_phages: Array) -> void:
	match a["state"]:
		FORAGE:
			a["energy"] -= ENERGY_DECAY * delta
			if a["energy"] <= DORMANT_ENERGY:
				a["state"] = DORMANT
				a["vel"] = Vector2.ZERO
				return
			var cur := nutrient_at(a["pos"])
			if cur > EAT_MIN:
				a["state"] = EAT
			else:
				var speed := SPEED * _mot
				if speed >= 3.0:
					_run_and_tumble(a, cur, delta, speed)
				else:
					# Không di động: gần như đứng yên, chỉ nhích rất chậm về phía có ăn.
					a["pos"] += _best_nutrient_dir(a["pos"]) * SPEED * 0.12 * delta
					a["vel"] = Vector2.ZERO
			# Rival ở sát (đâm-chạm) được ưu tiên hơn phage (khuếch tán, tầm xa).
			if _nearest_rival(a["pos"], T6SS_SENSE) != null:
				a["state"] = STAB
				a["timer"] = 0.0
			elif _phage_near(a["pos"], DEFEND_RANGE) and not _sheltered(a["pos"]):
				a["state"] = DEFEND
				a["timer"] = 0.0

		EAT:
			var cur := nutrient_at(a["pos"])
			if cur <= EAT_MIN:
				a["state"] = FORAGE
				return
			a["energy"] += ENERGY_GAIN * delta
			_deplete_nut(a["pos"], FIELD_EAT * delta)
			_add_waste(a["pos"], WASTE_EXCRETE * delta)   # ăn thì thải phế phẩm
			if a["energy"] >= DIVIDE_ENERGY and agents.size() + newborns.size() < MAX_POP:
				a["state"] = DIVIDE
				a["timer"] = DIVIDE_TIME
			elif _nearest_rival(a["pos"], T6SS_SENSE) != null:
				a["state"] = STAB
				a["timer"] = 0.0
			elif _phage_near(a["pos"], DEFEND_RANGE) and not _sheltered(a["pos"]):
				a["state"] = DEFEND
				a["timer"] = 0.0

		DIVIDE:
			a["timer"] -= delta
			if a["timer"] <= 0.0:
				a["state"] = FORAGE
				if agents.size() + newborns.size() < MAX_POP:
					a["energy"] *= 0.5
					var cp: Vector2
					if _mot < SESSILE_THRESH:
						# Chủng định cư: con mới mọc VỀ PHÍA CÓ ĂN (range expansion) → giữ hình.
						cp = a["pos"] + _best_nutrient_dir(a["pos"]) * DIVIDE_STEP
					else:
						cp = a["pos"] + _rand_in_dish(9.0)
					newborns.append(_new_agent(cp, a["energy"]))

		DORMANT:
			if nutrient_at(a["pos"]) > EAT_MIN * 1.5:
				a["energy"] = maxf(a["energy"], 0.3)
				a["state"] = FORAGE

		DEFEND:
			a["timer"] -= delta
			if a["timer"] <= 0.0:
				var killed := _release_toxin(a["pos"])
				a["timer"] = TOXIN_COOLDOWN
				a["flash"] = 0.2
				if killed > 0:
					events.append({"kind": "toxin", "pos": a["pos"]})
			if not _phage_near(a["pos"], DEFEND_RANGE):
				a["state"] = FORAGE

		STAB:
			# T6SS: phải CHẠM mới đâm được. Không có rival trong tầm cảm → thôi.
			var target = _nearest_rival(a["pos"], T6SS_SENSE)
			if target == null:
				a["state"] = FORAGE
			else:
				a["timer"] -= delta
				if a["pos"].distance_to(target["pos"]) > T6SS_RANGE:
					_swim(a, target["pos"], delta)   # lao tới cho chạm
				elif a["timer"] <= 0.0:
					target["dead"] = true              # đâm thủng → rival chết
					a["timer"] = T6SS_COOLDOWN
					a["flash"] = 0.2
					events.append({"kind": "t6ss", "pos": a["pos"], "to": target["pos"]})

		INFECTED:
			a["timer"] -= delta
			a["flash"] = 0.15
			if a["timer"] <= 0.0:
				a["dead"] = true
				events.append({"kind": "lyse", "pos": a["pos"]})   # tế bào vỡ, phóng phage
				new_phages.append({"pos": a["pos"], "vel": Vector2.ZERO})
				new_phages.append({"pos": a["pos"] + _rand_in_dish(6.0), "vel": Vector2.ZERO})

		BUILD:
			var bi: int = a.get("build", -1)
			if bi < 0 or bi >= buildings.size() or buildings[bi]["active"] or a["energy"] < 0.15:
				a["state"] = FORAGE
				a["build"] = -1
				return
			var bld: Dictionary = buildings[bi]
			if a["pos"].distance_to(bld["pos"]) > BUILD_RANGE:
				_swim(a, bld["pos"], delta)
			else:
				bld["progress"] += BUILD_RATE * delta
				a["energy"] -= BUILD_COST * delta
				a["flash"] = 0.15
				if bld["progress"] >= BUILD_NEED:
					bld["progress"] = BUILD_NEED
					bld["active"] = true

	_clamp_to_dish(a)


func _run_and_tumble(a: Dictionary, cur: float, delta: float, speed: float) -> void:
	var improving: bool = cur > float(a["prev_nut"]) + 0.0005
	var tumble := TUMBLE_HAPPY if improving else TUMBLE_SAD
	if rng.randf() < tumble:
		var ang := rng.randf() * TAU
		a["heading"] = Vector2(cos(ang), sin(ang))
	a["prev_nut"] = cur
	a["vel"] = a["heading"] * speed
	a["pos"] += a["vel"] * delta


## Hướng có nhiều dinh dưỡng nhất quanh một điểm (cho chủng định cư mọc về phía có ăn).
func _best_nutrient_dir(pos: Vector2) -> Vector2:
	var best_dir := Vector2.ZERO
	var best_v := -1.0
	for k in 8:
		var d := Vector2(cos(TAU * k / 8.0), sin(TAU * k / 8.0))
		var v := nutrient_at(pos + d * CELL * 1.6)
		if v > best_v:
			best_v = v
			best_dir = d
	if best_v <= 0.001:
		var ang := rng.randf() * TAU
		return Vector2(cos(ang), sin(ang))
	return best_dir


## Cross-feeder: dò phế phẩm bằng run-and-tumble; tới chỗ có phế phẩm thì ĂN nó và
## TÁI CHẾ thành dinh dưỡng (trả lại cho khuẩn lạc). Sống một lúc rồi rời đi.
func _step_crossfeeders(delta: float) -> void:
	for c in crossfeeders:
		c["life"] -= delta
		var cur := waste_at(c["pos"])
		if cur > CF_NICHE:
			_deplete_waste(c["pos"], CF_EAT * delta)
			_add_nut(c["pos"], CF_RECYCLE * delta)
		var improving: bool = cur > float(c["prev"]) + 0.0005
		var tumble := TUMBLE_HAPPY if improving else TUMBLE_SAD
		if rng.randf() < tumble:
			var ang := rng.randf() * TAU
			c["heading"] = Vector2(cos(ang), sin(ang))
		c["prev"] = cur
		c["pos"] += c["heading"] * CF_SPEED * delta
		if c["pos"].length() > DISH_R - 8.0:
			c["pos"] = c["pos"].normalized() * (DISH_R - 8.0)
			var ang2 := rng.randf() * TAU
			c["heading"] = Vector2(cos(ang2), sin(ang2))
	crossfeeders = crossfeeders.filter(func(c): return c["life"] > 0.0)


## Chủng RIVAL: dò dinh dưỡng bằng run-and-tumble, ĂN nó (cạnh tranh), và cũng có T6SS —
## đâm chết khuẩn nhà khi CHẠM nếu con đó không kịp đâm lại và không được biofilm che.
func _step_rivals(delta: float) -> void:
	for c in rivals:
		c["life"] -= delta
		c["cd"] = maxf(0.0, c["cd"] - delta)
		var cur := nutrient_at(c["pos"])
		if cur > EAT_MIN:
			_deplete_nut(c["pos"], RIVAL_EAT * delta)   # tranh ăn của khuẩn nhà
		var improving: bool = cur > float(c["prev"]) + 0.0005
		var tumble := TUMBLE_HAPPY if improving else TUMBLE_SAD
		if rng.randf() < tumble:
			var ang := rng.randf() * TAU
			c["heading"] = Vector2(cos(ang), sin(ang))
		c["prev"] = cur
		# Kẻ xâm lấn nhắm vào NICHE đang bị chiếm: lệch hướng về khuẩn nhà gần nhất.
		var prey = _nearest_target(c["pos"])
		if prey != null:
			var to_prey: Vector2 = (prey["pos"] - c["pos"]).normalized()
			c["heading"] = (c["heading"] + to_prey * 0.9).normalized()
		c["pos"] += c["heading"] * RIVAL_SPEED * delta
		if c["pos"].length() > DISH_R - 8.0:
			c["pos"] = c["pos"].normalized() * (DISH_R - 8.0)
			var ang2 := rng.randf() * TAU
			c["heading"] = Vector2(cos(ang2), sin(ang2))
		if c["cd"] <= 0.0:
			var victim = _rival_victim(c["pos"])
			if victim != null:
				victim["dead"] = true
				c["cd"] = T6SS_COOLDOWN
				events.append({"kind": "t6ss", "pos": c["pos"], "to": victim["pos"]})
	rivals = rivals.filter(func(c): return c["life"] > 0.0 and not c.get("dead", false))


## Khuẩn nhà mà rival đâm được: trong tầm CHẠM, không đang đâm lại (STAB), không được che.
func _rival_victim(pos: Vector2):
	var rr := T6SS_RANGE * T6SS_RANGE
	for a in agents:
		if a.get("dead", false) or a["state"] == STAB or a["state"] == INFECTED:
			continue
		if _sheltered(a["pos"]):
			continue
		if pos.distance_squared_to(a["pos"]) <= rr:
			return a
	return null


func _nearest_rival(pos: Vector2, r: float):
	var rr := r * r
	var best = null
	var best_d := rr
	for c in rivals:
		if c.get("dead", false):
			continue
		var d: float = pos.distance_squared_to(c["pos"])
		if d <= best_d:
			best_d = d
			best = c
	return best


func _step_phages(delta: float) -> void:
	for p in phages:
		var a = _nearest_target(p["pos"])
		if a == null:
			p["pos"] += _wander() * 0.3
		else:
			p["vel"] = p["vel"].lerp((a["pos"] - p["pos"]).normalized() * PHAGE_SPEED, 0.12)
			p["pos"] += p["vel"] * delta
			if p["pos"].distance_to(a["pos"]) <= INFECT_RADIUS \
					and a["state"] != INFECTED and a["state"] != DORMANT \
					and not _sheltered(a["pos"]):
				a["state"] = INFECTED
				a["timer"] = INFECT_TIME
				events.append({"kind": "infect", "pos": a["pos"]})
		if p["pos"].length() > DISH_R - 4.0:
			p["pos"] = p["pos"].normalized() * (DISH_R - 4.0)


# ─────────────────────────── trợ giúp ───────────────────────────

func _separate(delta: float) -> void:
	for a in agents:
		if a.get("dead", false):
			continue
		var push := Vector2.ZERO
		for b in agents:
			if b == a or b.get("dead", false):
				continue
			var off: Vector2 = a["pos"] - b["pos"]
			var d := off.length()
			if d < SEP_R and d > 0.01:
				push += off / d * (SEP_R - d)
		if push != Vector2.ZERO:
			a["pos"] += push.limit_length(7.0) * delta * 9.0
			_clamp_to_dish(a)


func _swim(a: Dictionary, target: Vector2, delta: float) -> void:
	a["vel"] = a["vel"].lerp((target - a["pos"]).normalized() * SPEED, 0.1) + _wander() * 0.15
	a["pos"] += a["vel"] * delta


func _wander() -> Vector2:
	return Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * 20.0


func _clamp_to_dish(a: Dictionary) -> void:
	if a["pos"].length() > DISH_R - 6.0:
		a["pos"] = a["pos"].normalized() * (DISH_R - 6.0)
		a["vel"] = a["vel"] * -0.4
		var ang := rng.randf() * TAU
		a["heading"] = Vector2(cos(ang), sin(ang))


func _sheltered(pos: Vector2) -> bool:
	for b in buildings:
		if b["active"] and pos.distance_squared_to(b["pos"]) <= SHELTER_R * SHELTER_R:
			return true
	return false


func _nearest_target(pos: Vector2):
	var best = null
	var best_d := INF
	for a in agents:
		if a["state"] == INFECTED or a["state"] == DORMANT or a.get("dead", false):
			continue
		var d: float = pos.distance_squared_to(a["pos"])
		if d < best_d:
			best_d = d
			best = a
	return best


func _phage_near(pos: Vector2, r: float) -> bool:
	var rr := r * r
	for p in phages:
		if pos.distance_squared_to(p["pos"]) <= rr:
			return true
	return false


func _release_toxin(pos: Vector2) -> int:
	var rr := TOXIN_RADIUS * TOXIN_RADIUS
	var killed := 0
	for p in phages:
		if not p.get("dead", false) and pos.distance_squared_to(p["pos"]) <= rr:
			p["dead"] = true
			killed += 1
	return killed
