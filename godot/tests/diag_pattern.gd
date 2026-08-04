extends SceneTree
## Tìm độ linh động cho ra SÓNG XOẮN ỐC nhìn được, thay vì một bãi nhiễu hạt mịn.
##
## Bản đầu bê nguyên xác suất đổi chỗ của bản web (lưới 100) sang lưới 180, và ảnh
## chụp ra một đĩa lốm đốm không có lấy một vòng xoắn nào. Trong mô hình này bước
## sóng xoắn ốc tỉ lệ với độ linh động; đẩy cao thì hoa văn to ra, nhưng quá tay là
## đĩa hoá bình lắc và một chủng chết (kết quả kinh điển của Reichenbach 2007).
##
## Hai cột phải đọc CÙNG NHAU, đo riêng vì chúng đá nhau:
##   · đoạn TB @60s — quét ngang, một mảng cùng chủng dài trung bình bao nhiêu ô.
##     Mỗi ô rộng 3.6 px sau khi chiếu nên 8–14 ô là mảng 30–50 px, mắt bắt được.
##   · sống sót @90s — đĩa dài nhất trong game là 90 giây, nên đây mới là mốc phải
##     trụ được. Đo ở 60s thì độ linh động cao trông rất đẹp rồi sập sau đó.
##
## Cạm bẫy của thước đo: khi chỉ còn hai chủng thì "đoạn TB" vọt lên rất cao vì
## đĩa chỉ còn vài mảng khổng lồ. Đoạn dài mà kèm mất đa dạng là tin XẤU, không tốt.

const PATTERN_AT := 60.0
const SURVIVE_AT := 90.0
const STEP := 1.0 / 60.0
const TRIALS := 8


func _process(_delta: float) -> bool:
	# Không gieo hạt thì mỗi lần chạy ra một tỉ lệ sống sót khác — và chính chỗ này
	# đã lừa được một vòng: ×2.2 báo 4/4 an toàn, tới khi tests/balance.gd chạy với
	# hạt cố định mới lòi ra 3/4 thế cờ mất sạch Kháng độc.
	seed(20240)
	print("lưới  linh động   đoạn TB @60s   ~px   đủ 3 chủng @90s   tím/vàng/xanh @90s")
	for combo in [[180, 1.0], [180, 1.4], [180, 1.8], [180, 2.2]]:
		var side: int = combo[0]
		var m: float = combo[1]
		var runs := 0.0
		var survived := 0
		var line := ""
		for trial in TRIALS:
			var sim := Sim.new(side)
			sim.mobility = m
			sim.rebuild_rates()
			Stages.build(sim, Stages.make(Stages.Terrain.OPEN, Stages.Layout.SCATTER,
				Stages.Goal.HOLD, 77 + trial * 13))
			var t := 0.0
			while t < PATTERN_AT:
				sim.advance(STEP)
				t += STEP
			runs += _mean_run(sim)
			while t < SURVIVE_AT:
				sim.advance(STEP)
				t += STEP
			var alive := 0
			for s in Sim.SPECIES:
				if sim.ratio(s) > 0.02:
					alive += 1
			if alive == 3:
				survived += 1
			if trial == 0:
				line = "%2d/%2d/%2d" % [
					roundi(sim.ratio(Sim.TOXIC) * 100),
					roundi(sim.ratio(Sim.SENSITIVE) * 100),
					roundi(sim.ratio(Sim.RESISTANT) * 100)]
		# Quy ra pixel để so được giữa các cạnh lưới: đĩa luôn rộng 916 px trên màn
		# hình, nên ô ở lưới to thì nhỏ đi, và "12 ô" ở hai cạnh lưới khác nhau là hai
		# kích thước hoa văn hoàn toàn khác nhau.
		var px := runs / TRIALS * Board.DISH_WIDTH / (side * sqrt(2.0))
		print("%-5d ×%-8.1f %6.1f ô     %5.1f      %d/%d              %s" % [
			side, m, runs / TRIALS, px, survived, TRIALS, line])
	return true


## Quét mọi hàng qua lòng đĩa, đo trung bình độ dài một mảng liền chủng.
func _mean_run(sim: Sim) -> float:
	var total_runs := 0
	var total_cells := 0
	for y in range(20, sim.size - 20, 3):
		var prev := -1
		for x in range(20, sim.size - 20):
			var v := sim.grid[y * sim.size + x]
			if v == Sim.WALL:
				continue
			total_cells += 1
			if v != prev:
				total_runs += 1
				prev = v
	return float(total_cells) / maxf(1.0, float(total_runs))
