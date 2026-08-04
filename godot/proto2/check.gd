extends SceneTree
## Test headless cho lõi agent. Chạy: ./play.sh check

const AgentColony := preload("res://proto2/agent_colony.gd")


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

	print("OK — lan + cross-feeding + biofilm tự-kết + nguồn tự phát chạy đúng")
	quit()
