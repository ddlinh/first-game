extends SceneTree
## Test headless cho lõi agent. Chạy: ./play.sh check

const AgentColony := preload("res://proto2/agent_colony.gd")
const Yogurt := preload("res://proto2/yogurt_level.gd")


func _spread(c) -> float:
	var m := 0.0
	for a in c.agents:
		m = maxf(m, a["pos"].length())
	return m


func _init() -> void:
	# Lan + phân đôi (tất định).
	var c := AgentColony.new(99)
	c.auto_threat = false
	var start := c.population()
	c.add_nutrient(Vector2(0, 0), 40.0)
	c.add_nutrient(Vector2(60, -20), 30.0)
	for _i in 400:
		c.update(0.05)
	print("dân số: %d → %d" % [start, c.population()])
	assert(c.population() > start, "khuẩn phải phân đôi làm dân số tăng")

	# Dồn khuẩn về một chỗ cho đông → biofilm TỰ kết (quorum); rồi cross-feeder & phage
	# tự tới. Đây là cả vòng emergent.
	var g := AgentColony.new(7)   # auto_threat mặc định bật
	var kinds := {}
	for i in 900:
		if i % 6 == 0:
			g.add_nutrient(Vector2(0, 0), 8.0)   # dồn một chỗ cho đủ đông
		g.update(0.05)
		for e in g.events:
			kinds[e["kind"]] = true
		g.events.clear()
	print("sự kiện emergent: %s  (dân số %d, biofilm %d, phage %d, cross-feeder %d)" % [
		kinds.keys(), g.population(), g.buildings.size(), g.phages.size(), g.crossfeeders.size()])
	assert(kinds.has("biofilm_formed"), "đủ đông thì biofilm phải TỰ kết (quorum)")
	assert(kinds.has("phage_wave"), "đông → phage bén vào")
	assert(kinds.has("crossfeeder"), "phế phẩm đọng → cross-feeder bén vào")
	assert(not g.buildings.is_empty() and g.buildings[0]["active"], "biofilm phải xây xong")

	# Con trong biofilm được che chở.
	var shel_inf := 0
	for a in g.agents:
		if a["state"] == AgentColony.INFECTED:
			for b in g.buildings:
				if b["active"] and a["pos"].distance_to(b["pos"]) < AgentColony.SHELTER_R:
					shel_inf += 1
					break
	assert(shel_inf == 0, "con trong biofilm phải được che chở")
	print("con trong biofilm bị nhiễm: %d" % shel_inf)

	# Đặc tính CHỦNG × MÔI TRƯỜNG: chủng bơi (thạch mềm) lan XA; chủng định cư (thạch
	# cứng) mọc GỌN quanh chỗ cấy (giữ hình).
	var mot := AgentColony.new(11)
	mot.auto_threat = false
	mot.set_environment(1.0, 0.0, 1.2)   # bơi khoẻ + thạch mềm = bầy đàn/lan
	var ses := AgentColony.new(11)
	ses.auto_threat = false
	ses.set_environment(0.0, 1.0, 1.2)   # không di động + thạch cứng = giữ hình
	for i in 300:
		if i % 5 == 0:
			mot.add_nutrient(Vector2(0, 0), 7.0)
			ses.add_nutrient(Vector2(0, 0), 7.0)
		mot.update(0.05)
		ses.update(0.05)
	print("bán kính lan: bơi %.0f  vs  định cư %.0f" % [_spread(mot), _spread(ses)])
	assert(_spread(ses) < _spread(mot), "chủng định cư phải mọc gọn hơn chủng bơi")

	# Đói kéo dài → ngủ đông.
	var d := AgentColony.new(7)
	d.auto_threat = false
	for _i in 200:
		d.update(0.05)
	assert(d.tally()[AgentColony.DORMANT] > 0, "hết ăn thì phải có con ngủ đông")

	# CẠNH TRANH LIÊN KHUẨN + T6SS: nuôi một cụm khuẩn nhà, thả rival ở rìa; rival trôi
	# vào tranh ăn và bị khuẩn nhà ĐÂM CHẠM (T6SS) tiêu diệt — khác colicin (tầm xa, phage).
	var w := AgentColony.new(3)
	w.auto_threat = false
	for i in 300:
		if i % 4 == 0:
			w.add_nutrient(Vector2(0, 0), 8.0)
		w.update(0.05)
	var pop_before := w.population()
	w.spawn_rivals(4)
	var rv_start := w.rivals.size()
	var t6ss := false
	for i in 500:
		if i % 4 == 0:
			w.add_nutrient(Vector2(0, 0), 8.0)
		w.update(0.05)
		for e in w.events:
			if e["kind"] == "t6ss":
				t6ss = true
		w.events.clear()
	print("T6SS: rival %d → %d, dân số %d → %d, có đâm=%s" % [
		rv_start, w.rivals.size(), pop_before, w.population(), t6ss])
	assert(t6ss, "khuẩn nhà phải đâm rival bằng T6SS (contact-dependent)")
	assert(w.rivals.size() < rv_start, "rival phải bị khuẩn nhà tiêu diệt")
	assert(w.population() > 0, "khuẩn nhà phải sống sót cuộc cạnh tranh")

	_check_paint()
	_check_yogurt()

	print("OK — lan + cross-feeding + biofilm tự-kết + nguồn tự phát + T6SS chạy đúng")
	quit()


func _check_paint() -> void:
	# RẢI = NGHỀ: có ngân sách, tiêu khi rải, hồi theo giờ, không rải quá cái đang có.
	var b := AgentColony.new(5)
	b.auto_threat = false
	var full := b.nutrient_budget
	var applied := b.deposit(Vector2.ZERO, 20.0)
	assert(applied == 20.0 and b.nutrient_budget < full, "rải phải tiêu ngân sách")
	# hồi theo thời gian
	var low := b.nutrient_budget
	for _i in 30: b.update(0.1)                  # 3s
	assert(b.nutrient_budget > low, "ngân sách phải HỒI theo thời gian")
	# không rải quá cái đang có
	b.nutrient_budget = 5.0
	var over := b.deposit(Vector2.ZERO, 50.0)
	assert(over <= 5.0 + 0.001 and b.nutrient_budget >= -0.001, "không rải quá ngân sách")
	print("Rải-là-nghề: ngân sách tiêu/hồi/chặn đúng")


func _check_yogurt() -> void:
	# CHĂM ĐÚNG (ủ ~43°C) → pH tụt tới 4.6, CHỐT được → THẮNG.
	var y := Yogurt.new(3)
	y.auto_events = false
	for _i in 4: y.warm()                       # bếp lên ~ mục tiêu 43°C
	var lead_hi := 0                            # ai dẫn lúc pH còn cao
	var share_early := -1.0                     # tỉ phần L. bulgaricus lúc đầu
	var steps := 0
	while y.state == Yogurt.PLAYING and steps < 3000:
		y.update(0.1); steps += 1
		if y.pH > 5.4: lead_hi = y.leader()
		if share_early < 0.0 and y.pH < 6.2: share_early = y.lb / y.culture()
		if y.can_chill(): break
	var share_late := y.lb / y.culture()
	print("Yaourt: pH %.2f sau %.1fs, mốc %d%%, tỉ phần Lb %.2f→%.2f, chốt=%s" % [
		y.pH, steps * 0.1, int(y.spoil * 100), share_early, share_late, y.can_chill()])
	assert(y.can_chill(), "chăm đúng thì pH phải tụt tới 4.6")
	assert(y.spoil < 0.4, "chăm đúng thì mốc không được chiếm")
	assert(y.chill() and y.state == Yogurt.WON, "chốt ở 4.6 phải THẮNG")

	# TRAO TAY: S. thermophilus dẫn lúc pH cao; khi pH tụt, tỉ phần L. bulgaricus TĂNG.
	assert(lead_hi == -1, "lúc pH cao S. thermophilus phải dẫn")
	assert(share_late > share_early + 0.05, "khi pH tụt, tỉ phần L. bulgaricus phải tăng (trao tay)")

	# BỎ MẶC (để nguội, không làm gì) → mốc/hết giờ → THUA.
	var n := Yogurt.new(3)
	n.auto_events = false
	n.stove = 0.0                               # để nguội hẳn
	var s2 := 0
	while n.state == Yogurt.PLAYING and s2 < 4000:
		n.update(0.1); s2 += 1
	print("Yaourt bỏ mặc: %s (%s)" % [n.state, n.lose_reason])
	assert(n.state == Yogurt.LOST, "bỏ mặc mẻ phải hỏng")

	# BIẾN CỐ ngoại cảnh chạy theo lịch (cảnh báo trước rồi kích hoạt).
	var e := Yogurt.new(3)
	e.stove = 70.0                              # giữ ~41°C cho mẻ sống tới lúc biến cố
	var fired := false
	for _i in 260:
		e.update(0.1)
		for ev in e.events:
			if ev["kind"] == "warn" or ev["kind"] == "event": fired = true
		e.events.clear()
		if fired or e.state != Yogurt.PLAYING: break
	assert(fired, "biến cố ngoại cảnh phải chạy theo thời gian")
	print("Yaourt: trao tay + bỏ-mặc-thua + biến cố đều đúng")
