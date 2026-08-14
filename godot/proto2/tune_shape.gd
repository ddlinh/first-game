extends SceneTree
## Script TẠM để dò cân bằng màn mạng lưới (không thuộc bộ test — xoá được).
##   godot --headless --path godot --script proto2/tune_shape.gd

const Shape := preload("res://proto2/shape_level.gd")


## Rìa đang mọc trên một nhánh: hình chiếu xa nhất của một con khuẩn lên đoạn a→b
## (chỉ tính con thật sự bám nhánh, khỏi bị con lạc đường kéo lệch).
func _frontier_t(s, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	var best := 0.0
	for ag in s.c.agents:
		var t: float = clampf((ag["pos"] - a).dot(ab) / l2, 0.0, 1.0)
		if ag["pos"].distance_to(a + ab * t) <= Shape.LINK_HW + 12.0:
			best = maxf(best, t)
	return best


## "Người chơi giỏi": làm từng nhánh một, luôn rải ĐÓN ĐẦU rìa `lead` px, và chỉ rải khi
## chỗ đó đã ăn gần hết (khỏi phí ngân sách).
func _play(level: int, lead: float, verbose: bool) -> Dictionary:
	var s = Shape.new(level, 7)
	var peak := 0.0
	var peak_t := 0.0
	var steps := 0
	var li := 0
	var max_steps := int(s.time_limit / 0.05) + 20
	while s.state == Shape.PLAYING and steps < max_steps:
		var ls: Array = s.links()
		if li < ls.size():
			var a: Vector2 = s.nodes()[ls[li][0]]
			var b: Vector2 = s.nodes()[ls[li][1]]
			var t := _frontier_t(s, a, b)
			if t >= 0.96:
				li += 1                       # nhánh xong → sang nhánh kế
			else:
				var dir := (b - a).normalized()
				var target: Vector2 = a + (b - a) * t + dir * lead
				if (target - a).length() > (b - a).length():
					target = b
				if s.c.nutrient_at(target) < 0.25:
					s.deposit(target)
		s.update(0.05)
		steps += 1
		if s.iou > peak:
			peak = s.iou
			peak_t = s.elapsed
		if verbose and steps % 600 == 0:
			print("   t=%5.1fs iou=%.3f cover=%.2f spill=%.2f pop=%2d ngân sách=%4d mốc=%d nhánh=%d" % [
				s.elapsed, s.iou, s.cover, s.spill, s.c.population(), int(s.budget), s.molds.size(), li])
	return {"peak": peak, "at": peak_t, "s": s}


## "Tô đáp án": đổ thức ăn kín hình ngay từ đầu. Nếu cách này thắng thì câu đố là giả.
func _trace(level: int) -> float:
	var s = Shape.new(level, 7)
	var pts: Array = []
	for l in s.links():
		var a: Vector2 = s.nodes()[l[0]]
		var b: Vector2 = s.nodes()[l[1]]
		var n := int(a.distance_to(b) / 24.0)
		for i in n + 1:
			pts.append(a + (b - a) * (float(i) / float(n)))
	var k := 0
	while s.budget >= Shape.DOSE:
		s.deposit(pts[k % pts.size()])
		k += 1
	var peak := 0.0
	var steps := 0
	var max_steps := int(s.time_limit / 0.05) + 20
	while s.state == Shape.PLAYING and steps < max_steps:
		s.update(0.05)
		steps += 1
		peak = maxf(peak, s.iou)
	return peak


func _init() -> void:
	for lv in Shape.LEVELS.size():
		var probe = Shape.new(lv, 7)
		print("── màn %d “%s”: %d ô đích · ngân sách %d nhát · hạn %ds" % [
			lv + 1, probe.spec()["name"], probe.target_cells,
			int(probe.budget / Shape.DOSE), int(probe.time_limit)])
		for lead in [26.0, 34.0, 44.0]:
			var r := _play(lv, lead, false)
			var s = r["s"]
			print("   đón đầu %2.0fpx → IoU đỉnh %.3f (ở %3.0fs) · cover %.2f spill %.2f · kết: %s" % [
				lead, r["peak"], r["at"], s.cover, s.spill,
				"THẮNG được" if r["peak"] >= Shape.WIN_IOU else "thua (" + s.lose_reason + ")"])
		print("   tô đáp án → IoU đỉnh %.3f  (ngưỡng thắng %.2f)" % [_trace(lv), Shape.WIN_IOU])
	quit()
