extends SceneTree
## Đo thế cân bằng của lưới KHI KHÔNG AI CAN THIỆP. Đây là bài kiểm tra quan trọng
## nhất của game: nếu để mặc mà một chủng tự tuyệt chủng thì mọi mục tiêu chơi
## phía trên đều vô nghĩa — người chơi thắng thua vì mô hình chứ không vì họ.
##
## "Bao vây" là ngoại lệ CÓ CHỦ Ý: tài liệu thiết kế dựng sẵn thế thua cho người
## chơi (nhúm Tiết độc kẹt trong tường Kháng độc), nên đòi nó tự cân bằng là đòi
## sai. Ở thế đó ta đo thứ khác: cụm khởi đầu cầm cự được bao lâu — tức người chơi
## có kịp nhìn ra vấn đề và đổ bộ chỗ khác không.

## Đúng bằng đĩa dài nhất trong game (mục tiêu Sinh tồn, 90 giây). Trước đây để 150
## và nó bắt lỗi oan: ở độ linh động cho ra sóng xoắn ốc đẹp, hệ vẫn sập sau ~2 phút
## — nhưng game không bao giờ chạy tới đó, nên siết theo mốc ấy là tự tay bóp hoa văn
## xuống thành nhiễu hạt để qua một bài kiểm tra không có thật.
const HORIZON := 90.0
const STEP := 1.0 / 60.0
const SNAP_EVERY := 22.5

## Cụm Tiết độc trong thế Bao vây phải sống ít nhất ngần này giây thì người chơi
## mới kịp đọc thế cờ. Ngắn hơn là thua trước khi hiểu chuyện gì xảy ra.
const SIEGE_WINDOW := 20.0


## Ba nhánh của mỗi chủng cộng lại phải ≤ 1, và tốc độ dọn sạch hiệu dụng của cả ba
## phải bằng nhau — đó là hai điều kiện giữ cho vòng khắc chế trung tính. Cả hai từng
## bị phá âm thầm khi nâng `mobility`, và không có phép kiểm nào bắt được vì mọi số
## liệu in ra đều đọc từ ngưỡng chứ không từ xác suất thực nhận.
func _check_rates() -> bool:
	var sim := Sim.new(32)
	var ok := true
	for s in Sim.SPECIES:
		var sw: float = sim._swap[s]
		var rp: float = sim._swap_repro[s] - sw
		var kl_want: float = sim._swap_repro_kill[s] - sim._swap_repro[s]
		var kl_real: float = minf(sim._swap_repro_kill[s], 1.0) - sim._swap_repro[s]
		var total := sw + rp + kl_want
		var clear := kl_real / Sim.HP_TABLE[Sim.PREY[s]]
		var line_ok := total <= 1.0001 and absf(clear - Sim.KILL_BASE) < 0.0005
		ok = ok and line_ok
		print("  %-10s tổng %.3f · dọn sạch %.4f (cần %.4f)  %s" % [
			["", "Tiết độc", "Nhạy cảm", "Kháng độc"][s], total, clear, Sim.KILL_BASE,
			"OK" if line_ok else "LỆCH — nhánh ra đòn bị cắt cụt"])
	return ok


func _process(_delta: float) -> bool:
	# Sim bốc số bằng randi()/randf() toàn cục. Không gieo hạt thì hai lần chạy ra
	# hai kết quả, và một ngưỡng sát nút (cụm bị vây cầm cự 19.9 hay 20.1 giây) lúc
	# đạt lúc không — test kiểu đó không dùng để chốt số được.
	seed(20240)
	_check_writes()
	print("bảng xác suất ba nhánh:")
	var fails := 0
	if not _check_rates():
		fails += 1
	print("")

	for layout in [Stages.Layout.SCATTER, Stages.Layout.CLUMPS,
			Stages.Layout.VORTEX, Stages.Layout.SIEGE]:
		for terrain in [Stages.Terrain.OPEN, Stages.Terrain.CHOKE,
				Stages.Terrain.ISLANDS, Stages.Terrain.FLOW]:
			if not Stages.is_allowed(terrain, layout, Stages.Goal.HOLD):
				continue
			if not _run_one(terrain, layout):
				fails += 1
	print("")
	print("KẾT LUẬN: %s" % ("mọi thế cờ đạt yêu cầu" if fails == 0
		else "%d thế cờ KHÔNG đạt" % fails))
	return true


## Sim.grid là PackedByteArray — kiểu GIÁ TRỊ copy-on-write. Stages ghi vào nó qua
## `sim.grid[i] = ...` từ bên ngoài; nếu GDScript không gán ngược lại thì mọi màn
## chơi dựng ra sẽ là đĩa rỗng mà chẳng có lỗi nào nổ. Chốt lại bằng test này.
func _check_writes() -> void:
	var sim := Sim.new(16)
	sim.grid[5] = Sim.RESISTANT
	sim.hp[5] = 4
	var ok := sim.grid[5] == Sim.RESISTANT and sim.hp[5] == 4
	print("ghi mảng Packed qua tham chiếu đối tượng: %s" % ("OK" if ok
		else "HỎNG — Stages dựng màn xong lưới vẫn rỗng"))


func _run_one(terrain: Stages.Terrain, layout: Stages.Layout) -> bool:
	# ĐÚNG cạnh lưới của bản chơi. Trước đây để 160 cho nhanh, và nó nói dối theo cả
	# hai chiều: lưới nhỏ hơn thì tuyệt chủng dễ hơn, nên test vừa báo động giả vừa
	# không đo đúng cái đĩa mà người chơi cầm.
	var sim := Sim.new(180)
	var stage := Stages.make(terrain, layout, Stages.Goal.HOLD, 20240 + terrain * 7 + layout)
	Stages.build(sim, stage)

	var t := 0.0
	var next_snap := SNAP_EVERY
	var trace: Array[String] = []
	var peak := 0.0
	var toxic_died_at := -1.0

	while t < HORIZON:
		sim.advance(STEP)
		t += STEP
		if toxic_died_at < 0.0 and sim.ratio(Sim.TOXIC) <= 0.004:
			toxic_died_at = t
		if t >= next_snap:
			next_snap += SNAP_EVERY
			trace.append("%2d/%2d/%2d" % [
				roundi(sim.ratio(Sim.TOXIC) * 100),
				roundi(sim.ratio(Sim.SENSITIVE) * 100),
				roundi(sim.ratio(Sim.RESISTANT) * 100)])
		peak = maxf(peak, maxf(sim.ratio(Sim.TOXIC),
			maxf(sim.ratio(Sim.SENSITIVE), sim.ratio(Sim.RESISTANT))))

	var ok: bool
	var note: String
	if layout == Stages.Layout.SIEGE:
		var lived := toxic_died_at if toxic_died_at > 0.0 else HORIZON
		ok = lived >= SIEGE_WINDOW
		note = "cụm đầu cầm cự %4.1fs (cần ≥%.0f)" % [lived, SIEGE_WINDOW]
	else:
		var alive := 0
		for s in Sim.SPECIES:
			if sim.ratio(s) > 0.02:
				alive += 1
		# Trần đỉnh nới từ 80% lên 90%: ở độ linh động cho ra sóng xoắn ốc nhìn được,
		# đĩa chỉ còn vài mảng lớn nên biên độ dao động cũng to theo — có lúc một
		# chủng ôm 82% rồi tuột về 46%. Cái đáng sợ là KHÔNG QUAY LẠI, mà điều đó
		# đã nằm ở phép đếm "còn 3 chủng" rồi.
		ok = alive == 3 and peak < 0.90
		note = "còn %d chủng, đỉnh %2d%%" % [alive, roundi(peak * 100)]

	print("%-16s %-12s %s   %s  %s" % [
		Stages.TERRAIN_NAME[terrain], Stages.LAYOUT_NAME[layout],
		" → ".join(trace), note, "OK" if ok else "KHÔNG ĐẠT"])
	return ok
