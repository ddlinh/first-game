extends SceneTree
## Đi qua CẢ NĂM mục tiêu chơi với cùng một bot, đo tỉ lệ thắng.
##
## Lượt roguelite bình thường dừng ngay khi thua nên smoke.gd hầu như chỉ chạm tới
## đĩa đầu tiên; bốn nhánh chấm điểm còn lại không ai đụng vào. Ở đây mỗi mục tiêu
## được ép thành một lượt một đĩa để chắc chắn nhánh nào cũng chạy, và để thấy mục
## tiêu nào dễ quá hay khó quá.

const TRIALS := 2

var colony: Colony
var jobs: Array[Dictionary] = []
var job := -1
var results: Array[Dictionary] = []
var frames := 0
var max_delta := 0.0
var over_cap := 0
var play_frames := 0


func _initialize() -> void:
	for goal in [Stages.Goal.HOLD, Stages.Goal.SURVIVE, Stages.Goal.BALANCE,
			Stages.Goal.BLITZ, Stages.Goal.ESCORT]:
		for t in TRIALS:
			jobs.append({
				"goal": goal,
				"stage": Stages.make(
					[Stages.Terrain.OPEN, Stages.Terrain.CHOKE][t % 2],
					[Stages.Layout.SCATTER, Stages.Layout.CLUMPS][t % 2],
					goal, 4400 + t * 31),
			})

	colony = load("res://scenes/Dish.tscn").instantiate()
	colony.tutorial_enabled = false
	Engine.time_scale = 4.0
	root.add_child(colony)


func _process(delta: float) -> bool:
	frames += 1
	# Colony._ready đã tự mở một lượt ngẫu nhiên. Phải cướp quyền ngay từ khung đầu,
	# không thì lượt đó chạy tới khi có kết quả rồi bị ghi vào jobs[-1] — tức đội
	# lốt mục tiêu CUỐI danh sách, và bảng tổng kết nói dối một dòng.
	if frames < 2:
		return _next_job()

	match colony.state:
		Colony.State.INTRO:
			colony._on_continue()
		Colony.State.PLAYING:
			# Chỉ soi khung lúc đang chơi: khung dựng màn có hâm nóng lưới nên dài
			# là chuyện đương nhiên, và trần nhịp sinh ra chính để đỡ khung đó.
			play_frames += 1
			max_delta = maxf(max_delta, delta)
			if delta > 0.12:
				over_cap += 1
			if colony.charges > 0 and colony.sim.ratio(Sim.TOXIC) < 0.55:
				var cell := _pick_target()
				if cell.x >= 0:
					colony._try_plant(cell)
		Colony.State.RESULT:
			results.append({
				"goal": jobs[job]["goal"],
				"won": colony.lost_reason.is_empty(),
				"why": colony.lost_reason if colony.lost_reason else "thắng",
				"mine": colony.sim.ratio(Sim.TOXIC),
			})
			return _next_job()
		_:
			# Lượt một đĩa: thắng thì Colony nhảy sang RUN_END, không có màn chọn thẻ.
			return _next_job()

	return false


func _next_job() -> bool:
	job += 1
	if job >= jobs.size():
		_report()
		return true
	var forced: Array[Dictionary] = [jobs[job]["stage"]]
	colony.start_run(7000 + job, forced)
	return false


func _report() -> void:
	print("")
	print("%-12s %-7s %s" % ["MỤC TIÊU", "THẮNG", "chi tiết"])
	for goal in [Stages.Goal.HOLD, Stages.Goal.SURVIVE, Stages.Goal.BALANCE,
			Stages.Goal.BLITZ, Stages.Goal.ESCORT]:
		var mine := results.filter(func(r: Dictionary) -> bool: return r["goal"] == goal)
		var wins := mine.filter(func(r: Dictionary) -> bool: return r["won"]).size()
		var why := mine.map(func(r: Dictionary) -> String: return r["why"])
		print("%-12s %d/%-5d %s" % [
			Stages.GOAL_INFO[goal]["name"], wins, mine.size(), " · ".join(why)])
	print("")
	print("khung lúc đang chơi: dài nhất %.3fs, %d/%d khung vượt trần — %s" % [
		max_delta, over_cap, play_frames,
		"số liệu đáng tin" if over_cap * 100 < play_frames
		else "MÔ PHỎNG BỊ BỎ NHỊP, số liệu trên không đáng tin"])


func _pick_target() -> Vector2i:
	var sim: Sim = colony.sim
	var fallback := Vector2i(-1, -1)
	for _try in 120:
		var i := randi() % sim.cells
		var cell := Vector2i(i % sim.size, i / sim.size)
		var v := sim.grid[i]
		if v == Sim.SENSITIVE:
			return cell
		if v == Sim.EMPTY and fallback.x < 0:
			fallback = cell
	return fallback


func _finalize() -> void:
	if colony:
		colony.free()
