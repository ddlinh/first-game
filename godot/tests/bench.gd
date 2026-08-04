extends SceneTree
## Đo tốc độ vòng lặp nóng của Sim. Con số này quyết định cạnh lưới dám chọn là bao
## nhiêu: mỗi khung 60fps chỉ có 16.6ms, mà tầng vẽ 2.5D còn phải ăn một phần.
##
## Việc phải nằm trong _process chứ không phải _initialize: quit() gọi từ
## _initialize không cắt được vòng lặp chính, tiến trình treo và stdout (đang gom
## khối vì bị pipe) không bao giờ được xả — nhìn ra ngoài y hệt như treo máy.

func _process(_delta: float) -> bool:
	seed(7)
	for l in [100, 128, 160, 180]:
		var sim := Sim.new(l)
		var rng := RandomNumberGenerator.new()
		rng.seed = 1
		sim.scatter(Sim.TOXIC, 0.2, rng)
		sim.scatter(Sim.SENSITIVE, 0.2, rng)
		sim.scatter(Sim.RESISTANT, 0.2, rng)
		var per_frame := int(Sim.CHURN * sim.cells / 60.0)

		var t0 := Time.get_ticks_usec()
		for _f in 60:
			sim.step(per_frame)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0 / 60.0

		var before := sim.counts.duplicate()
		var t1 := Time.get_ticks_usec()
		sim.recount()
		var recount_ms := (Time.get_ticks_usec() - t1) / 1000.0
		# Đếm tăng dần trong vòng lặp nóng phải khớp với đếm quét lại, lệch là
		# một nhánh nào đó quên cộng trừ.
		var drift := "khớp" if before == sim.counts else "LỆCH %s vs %s" % [before, sim.counts]

		print("lưới %3dx%-3d  %6d nhịp/khung  sim %5.2f ms/khung  recount %.2f ms  đếm %s  %s" % [
			l, l, per_frame, ms, recount_ms, drift, "OK" if ms < 8.0 else "QUÁ CHẬM"])
	return true
