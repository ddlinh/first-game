extends SceneTree
## Xem đúng thứ người chơi thấy trong 60 giây đầu ở tốc độ thật, trên lưới 180 của
## bản chơi (tests/balance.gd chạy lưới 160 và tận 150 giây nên nó bỏ sót đoạn quá
## độ mở màn — mà đoạn đó mới là toàn bộ một đĩa).

func _process(_delta: float) -> bool:
	for warm in [0.0, 4.0, 8.0, 14.0]:
		var worst := 1.0
		var line: Array[String] = []
		for trial in 3:
			var sim := Sim.new(180)
			Stages.build(sim, Stages.make(Stages.Terrain.OPEN, Stages.Layout.SCATTER,
				Stages.Goal.HOLD, 900 + trial))
			var t0 := Time.get_ticks_msec()
			sim.warm_up(warm)
			var warm_ms := Time.get_ticks_msec() - t0

			var lo := 1.0
			var t := 0.0
			var next_mark := 15.0
			var marks: Array[String] = []
			while t < 60.0:
				sim.advance(1.0 / 60.0)
				t += 1.0 / 60.0
				lo = minf(lo, sim.ratio(Sim.TOXIC))
				if t >= next_mark:
					next_mark += 15.0
					marks.append("%d/%d/%d" % [
						roundi(sim.ratio(Sim.TOXIC) * 100),
						roundi(sim.ratio(Sim.SENSITIVE) * 100),
						roundi(sim.ratio(Sim.RESISTANT) * 100)])
			worst = minf(worst, lo)
			line.append("%s (đáy %d%%)" % [" ".join(marks), roundi(lo * 100)])
			if trial == 0:
				print("  hâm nóng %.0fs tốn %d ms" % [warm, warm_ms])
		print("hâm nóng %4.0fs → %s" % [warm, "  |  ".join(line)])
		print("           đáy thấp nhất của Tiết độc qua 3 lần: %d%%" % roundi(worst * 100))
	return true
