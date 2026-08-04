extends SceneTree
## Ba trục sinh màn có thật sự tạo ra màn chơi KHÁC NHAU không, hay chỉ khác nhau
## trên giấy?
##
## "Có mặt trong enum" không đồng nghĩa với "người chơi thấy khác". Hai phép đo:
##
## 1. ĐỊA HÌNH — đếm ô vách và độ đẩy của dòng chảy. Địa hình khác nhau thì con số
##    này phải khác nhau, nếu trùng thì hai địa hình đó là một.
##
## 2. THẾ CỜ — đây mới là phép đo đáng ngại. Lưới ô tự hành có dạng hút riêng của
##    nó, nên mọi thế cờ khởi tạo đều bị kéo về cùng một chỗ; câu hỏi là SAU BAO
##    LÂU. Nếu bốn thế cờ hoà làm một sau năm giây thì trục đó gần như không tồn
##    tại, và một đĩa 60 giây thật ra chỉ được định danh bởi địa hình + mục tiêu.
##    Đo bằng cách chạy song song bốn thế cờ trên cùng hạt giống rồi so tỉ lệ ba
##    chủng theo thời gian: còn lệch nhau nhiều là còn khác biệt.

const STEP := 1.0 / 60.0
const SEEDS := 5


func _process(_delta: float) -> bool:
	seed(90210)
	_terrains()
	print("")
	_layouts()
	return true


func _terrains() -> void:
	print("── TRỤC ĐỊA HÌNH ──")
	print("%-18s %8s %8s  %s" % ["địa hình", "ô vách", "đẩy nam", "ghi chú"])
	for t in [Stages.Terrain.OPEN, Stages.Terrain.CHOKE,
			Stages.Terrain.ISLANDS, Stages.Terrain.FLOW]:
		var sim := Sim.new(180)
		Stages.build(sim, Stages.make(t, Stages.Layout.SCATTER, Stages.Goal.HOLD, 7))
		# Độ đẩy đọc từ bảng hướng: đếm số ô mang hướng nam trong 16 ô.
		var south := 0
		for i in sim._dirs.size():
			if sim._dirs[i] == 2:
				south += 1
		var wall_pct := 100.0 * sim.counts[Sim.WALL] / sim.cells
		var playable_pct := 100.0 * sim.playable / sim.cells
		print("%-18s %7.1f%% %6d/16  đất chơi được %.0f%%" % [
			Stages.TERRAIN_NAME[t], wall_pct, south, playable_pct])


func _layouts() -> void:
	print("── TRỤC THẾ CỜ: bao lâu thì bốn thế cờ hoà vào nhau? ──")
	var marks := [0.0, 2.0, 5.0, 10.0, 20.0, 40.0]
	var layouts := [Stages.Layout.SCATTER, Stages.Layout.CLUMPS,
			Stages.Layout.SIEGE, Stages.Layout.VORTEX]

	# tỉ lệ ba chủng của từng thế cờ tại từng mốc, gộp trung bình qua các hạt giống
	var track := {}
	for l in layouts:
		track[l] = []
		for _m in marks:
			track[l].append(Vector3.ZERO)

	for s in SEEDS:
		for l in layouts:
			var sim := Sim.new(180)
			Stages.build(sim, Stages.make(Stages.Terrain.OPEN, l, Stages.Goal.HOLD, 500 + s))
			var t := 0.0
			for mi in marks.size():
				while t < marks[mi]:
					sim.advance(STEP)
					t += STEP
				track[l][mi] += Vector3(sim.ratio(Sim.TOXIC),
					sim.ratio(Sim.SENSITIVE), sim.ratio(Sim.RESISTANT)) / SEEDS

	print("%-14s %s" % ["thế cờ", " ".join(marks.map(
		func(m: float) -> String: return "t=%-11s" % ("%.0fs" % m)))])
	for l in layouts:
		var cells: Array[String] = []
		for mi in marks.size():
			var v: Vector3 = track[l][mi]
			cells.append("%2d/%2d/%2d    " % [
				roundi(v.x * 100), roundi(v.y * 100), roundi(v.z * 100)])
		print("%-14s %s" % [Stages.LAYOUT_NAME[l], " ".join(cells)])

	_spread_vs_noise(marks, layouts)


## Độ tản GIỮA các thế cờ, đặt cạnh độ tản của CÙNG một thế cờ chạy nhiều hạt giống.
##
## Không có cột thứ hai thì cột thứ nhất vô nghĩa: mô hình này tự dao động biên độ
## rất lớn, nên hai ván cùng thế cờ đã lệch nhau sẵn. Chỉ khi tản-giữa lớn hơn hẳn
## tản-trong thì mới kết luận được là thế cờ có ảnh hưởng thật.
func _spread_vs_noise(marks: Array, layouts: Array) -> void:
	# Chạy lại, lần này giữ riêng từng hạt giống thay vì gộp trung bình.
	var runs := {}
	for l in layouts:
		runs[l] = []
		for s in SEEDS:
			var sim := Sim.new(180)
			Stages.build(sim, Stages.make(Stages.Terrain.OPEN, l, Stages.Goal.HOLD, 500 + s))
			var series: Array[Vector3] = []
			var t := 0.0
			for m in marks:
				while t < m:
					sim.advance(STEP)
					t += STEP
				series.append(Vector3(sim.ratio(Sim.TOXIC),
					sim.ratio(Sim.SENSITIVE), sim.ratio(Sim.RESISTANT)))
			runs[l].append(series)

	var between: Array[String] = []
	var within: Array[String] = []
	var verdict: Array[String] = []
	for mi in marks.size():
		# tản-trong: trung bình khoảng cách giữa hai ván CÙNG thế cờ
		var win_sum := 0.0
		var win_n := 0
		for l in layouts:
			for a in SEEDS:
				for b in range(a + 1, SEEDS):
					win_sum += (runs[l][a][mi] - runs[l][b][mi]).length()
					win_n += 1
		var win := win_sum / maxi(win_n, 1)

		# tản-giữa: trung bình khoảng cách giữa hai ván KHÁC thế cờ
		var btw_sum := 0.0
		var btw_n := 0
		for ia in layouts.size():
			for ib in range(ia + 1, layouts.size()):
				for a in SEEDS:
					for b in SEEDS:
						btw_sum += (runs[layouts[ia]][a][mi]
							- runs[layouts[ib]][b][mi]).length()
						btw_n += 1
		var btw := btw_sum / maxi(btw_n, 1)

		between.append("%5.0f%%" % (btw * 100))
		within.append("%5.0f%%" % (win * 100))
		verdict.append("%5.2f " % (btw / maxf(win, 0.001)))

	print("")
	print("%-22s %s" % ["mốc thời gian", " ".join(marks.map(
		func(m: float) -> String: return "%6s" % ("t=%.0fs" % m)))])
	print("%-22s %s" % ["tản GIỮA các thế cờ", " ".join(between)])
	print("%-22s %s" % ["tản TRONG một thế cờ", " ".join(within)])
	print("%-22s %s" % ["tỉ số giữa/trong", " ".join(verdict)])
	print("(tỉ số ~1.0 = thế cờ không phân biệt được với nhiễu ngẫu nhiên giữa hai ván)")
