extends SceneTree
## Hai pha, không cần cửa sổ:
##
## Pha 1 — chơi thật: bot tự cấy quân, thỉnh thoảng khuấy, đi tới khi thắng hoặc thua.
## Pha 2 — diễn tập chuyển đĩa: ép thắng từng đĩa để đi hết danh sách. Cần pha này
##   vì bot thường thua ngay đĩa đầu, mà thua là hết lượt — nghĩa là chuỗi
##   chọn thẻ → dựng đĩa mới → thẻ ngấm vào kit KHÔNG bao giờ được chạy ở pha 1,
##   và đó lại đúng là chỗ dễ hỏng nhất khi thêm thẻ hoặc thêm mục tiêu mới.

var colony: Colony
var frames := 0
var phase := 1
var plants := 0
var stages_seen := 0
var click_check := 0


func _initialize() -> void:
	colony = load("res://scenes/Dish.tscn").instantiate()
	colony.tutorial_enabled = false     # test không đi qua ba bước hướng dẫn
	# Tua nhanh bằng time_scale chứ KHÔNG phải bằng cách nhân riêng delta của mô
	# phỏng: nhân riêng thì đồng hồ đếm ngược vẫn chạy tốc độ thật còn lưới chạy
	# gấp mấy lần, nên bot gặp một trận hoàn toàn khác trận của người chơi. Trần 4
	# là để mỗi khung vẫn nằm dưới trần nhịp của Sim.advance().
	Engine.time_scale = 4.0
	root.add_child(colony)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 2:
		return false
	if frames > 30000:
		print("!!! quá 30000 khung mà chưa xong — nhiều khả năng kẹt ở state %d" % colony.state)
		return true
	return _phase_one() if phase == 1 else _phase_two()


func _phase_one() -> bool:
	match colony.state:
		Colony.State.INTRO:
			stages_seen += 1
			print("── đĩa %d/%d: %s" % [
				colony.run.index + 1, colony.run.stages.size(),
				Stages.title(colony.run.current())])
			colony._on_continue()
		Colony.State.PLAYING:
			if click_check == 0:
				_send_real_click()
			elif click_check == 1:
				# Nếu HUD nuốt mất cú bấm, hoặc phép đổi toạ độ màn hình → ô lưới sai,
				# thì mọi test khác vẫn xanh vì chúng gọi thẳng _try_plant() — còn
				# người chơi thì bấm vào đĩa mà không có gì xảy ra.
				click_check = 2
				print("   bấm chuột thật lên đĩa: %s" % ("OK" if colony.charges == 0
					else "HỎNG — cú bấm không tới được đĩa"))
			if colony.charges > 0 and colony.sim.ratio(Sim.TOXIC) < 0.55:
				var cell := _pick_target()
				if cell.x >= 0:
					colony._try_plant(cell)
					plants += 1
			colony.stirring = frames % 240 < 20
			if frames % 200 == 0:
				var p: Array = colony._progress()
				print("   t=%5.1f  tím %2d%%  vàng %2d%%  xanh %2d%%  | %s" % [
					colony.time_left,
					roundi(colony.sim.ratio(Sim.TOXIC) * 100),
					roundi(colony.sim.ratio(Sim.SENSITIVE) * 100),
					roundi(colony.sim.ratio(Sim.RESISTANT) * 100), p[0]])
		Colony.State.RESULT:
			print("   → %s" % ("THUA: " + colony.lost_reason if colony.lost_reason
				else "THẮNG"))
			colony._on_continue()
		Colony.State.CARDS:
			print("   thẻ: %s" % [colony._cards.map(
				func(c: Dictionary) -> String: return c["name"])])
			colony._on_card(0)
		Colony.State.RUN_END:
			print("PHA 1 xong: %d đĩa, %d nhát cấy, %d khung." % [stages_seen, plants, frames])
			print("")
			print("PHA 2 — diễn tập chuyển đĩa (ép thắng từng đĩa):")
			phase = 2
			colony.start_run(31337)
		_:
			pass
	return false


func _phase_two() -> bool:
	match colony.state:
		Colony.State.INTRO:
			print("   vào đĩa %d/%d: %s" % [colony.run.index + 1,
				colony.run.stages.size(), Stages.title(colony.run.current())])
			colony._on_continue()
		Colony.State.PLAYING:
			colony._win("diễn tập")
		Colony.State.RESULT:
			if not colony.lost_reason.is_empty():
				print("   !! đĩa vừa dựng đã thua ngay: %s (tím %.1f%%)" % [
					colony.lost_reason, colony.sim.ratio(Sim.TOXIC) * 100])
			colony._on_continue()
		Colony.State.CARDS:
			var card: Dictionary = colony._cards[0]
			colony._on_card(0)
			print("   đĩa %d → lấy thẻ «%s», kit: %s" % [
				colony.run.index, card["name"], _kit_line()])
		Colony.State.RUN_END:
			# Kit phải PHÌNH RA so với mặc định, nếu không thì thẻ chỉ là hoạt cảnh.
			var base := Run.default_kit()
			var grown: bool = colony.run.kit["plant_radius"] > base["plant_radius"] \
				or colony.run.kit["max_charges"] > base["max_charges"] \
				or colony.run.kit["repro_boost"] > base["repro_boost"] \
				or colony.run.kit["plant_cooldown"] < base["plant_cooldown"]
			print("PHA 2 xong: đi hết %d đĩa. Thẻ ngấm vào kit: %s" % [
				colony.run.stages.size(), "OK" if grown else "HỎNG — kit y như lúc đầu"])
			return true
		_:
			pass
	return false


## Bấm chuột thật vào tâm đĩa, đi trọn đường viewport → _unhandled_input như người
## chơi, thay vì gọi tắt vào _try_plant().
func _send_real_click() -> void:
	click_check = 1
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = colony.board.global_position
	Input.parse_input_event(ev)


## Bot chơi như người mới biết luật: đổ quân vào giữa đám Nhạy cảm, vì đó là con
## mồi của mình. Cấy bừa vào chỗ trống hay vào đám Kháng độc thì nhát cấy phí ngay.
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


func _kit_line() -> String:
	var k: Dictionary = colony.run.kit
	return "bk %d · hồi %.1fs · ống %d · sinh sản ×%.2f%s" % [
		k["plant_radius"], k["plant_cooldown"], k["max_charges"], k["repro_boost"],
		" · kháng sinh" if k["antibiotic"] else ""]


func _finalize() -> void:
	if colony:
		colony.free()
