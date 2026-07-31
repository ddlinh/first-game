extends SceneTree
## Kiểm chứng ba thứ dễ vỡ nhất: cú lăn né có miễn thương thật không, quái có
## trượt đòn khi ta đang lăn không, và bấm Enter lúc kết thúc có chơi lại được không.
##
## Mọi mong đợi đều CHỜ tới khi đúng (có hạn) thay vì kiểm tra ngay frame sau.
## _process chạy theo tốc độ vẽ còn game chạy theo nhịp physics, nên kiểm tra
## tức thì sau khi bơm phím là hên xui.

var swarm: Swarm
var fails: Array[String] = []

var _steps: Array = []
var _idx := 0
var _waited := 0
var _wait_frames := 0
var _hp_guard := -1        ## máu lúc bắt đầu miễn thương, -1 = không canh
var _old_mobs := {}        ## instance id của đám quái lượt trước, để soi lúc chơi lại

const WAIT_MAX := 400      ## quá số frame này coi như mong đợi không bao giờ đúng


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false      # test không được ghi kỷ lục của người chơi
	root.add_child(swarm)
	_build()


func _build() -> void:
	_note("— màn chờ —")
	_expect(func() -> bool: return swarm.state == Swarm.State.MENU, "mở game là vào màn chờ")
	_expect(func() -> bool: return swarm.menu_panel.visible, "panel menu hiện")
	_expect(func() -> bool: return not swarm.hero.is_physics_processing(),
		"nhân vật đứng im ở màn chờ")

	_note("— vào trận —")
	_tap(KEY_ENTER)
	_expect(func() -> bool: return swarm.state == Swarm.State.PLAYING,
		"Enter bắt đầu được vòng đấu")
	_expect(func() -> bool: return not swarm.menu_panel.visible, "panel menu ẩn khi vào trận")
	_expect(func() -> bool: return swarm.hero.dash_ready_ratio() == 1.0,
		"lăn né sẵn sàng từ đầu")
	_expect(func() -> bool: return swarm._alive_count() >= 3, "quái có spawn vào sân")

	_note("— lăn né —")
	_do(func() -> void:
		_hp_guard = swarm.hero.hp          # từ đây máu không được tụt khi đang miễn thương
		_key(KEY_SPACE, true))
	_expect(func() -> bool: return swarm.hero.is_invulnerable(), "đang lăn thì miễn thương")
	_expect(func() -> bool: return swarm.hero.dash_ready_ratio() < 1.0,
		"lăn xong là vào hồi chiêu")
	_do(func() -> void: _key(KEY_SPACE, false))
	_expect(func() -> bool: return not swarm.hero.is_invulnerable(), "miễn thương có hết hạn")
	_expect(func() -> bool: return swarm.hero.hp == _hp_guard, "không mất máu nào suốt cú lăn")
	_do(func() -> void: _hp_guard = -1)

	_note("— kết thúc —")
	_do(func() -> void: swarm.hero.hp = 0)
	_expect(func() -> bool: return swarm.state == Swarm.State.OVER,
		"hết máu là kết thúc vòng đấu")
	_expect(func() -> bool: return swarm.result_panel.visible, "panel kết quả hiện")

	# Vừa chết mà bấm Enter thì phải bị chặn. Đây là mong đợi "vẫn giữ nguyên"
	# nên phải chờ vài frame cho phím được xử lý rồi mới soi.
	_tap(KEY_ENTER)
	_wait(20)
	_expect(func() -> bool: return swarm.state == Swarm.State.OVER,
		"chặn bấm nhầm ngay lúc vừa chết")

	_note("— chơi lại —")
	_expect(func() -> bool: return swarm._over_lock <= 0.0, "khoá chống bấm nhầm có mở ra")
	# Ghi lại đám quái của lượt cũ. Không kiểm tra "sân sạch quái" được vì lượt mới
	# spawn con đầu tiên ngay frame đầu — thứ phải đúng là quái CŨ không sót lại.
	_do(func() -> void:
		_old_mobs.clear()
		for m in swarm.mobs_root.get_children():
			_old_mobs[m.get_instance_id()] = true)
	_tap(KEY_ENTER)
	_expect(func() -> bool: return swarm.state == Swarm.State.PLAYING,
		"Enter chơi lại được sau khi hết chặn")
	_expect(func() -> bool: return swarm.hero.hp == Hero.MAX_HP, "chơi lại thì hồi đầy máu")
	_expect(func() -> bool: return swarm.kills == 0, "chơi lại thì đếm mạng về 0")
	_expect(func() -> bool: return swarm.elapsed < 0.5, "chơi lại thì đồng hồ về đầu")
	_expect(func() -> bool:
		for m in swarm.mobs_root.get_children():
			if _old_mobs.has(m.get_instance_id()):
				return false
		return _old_mobs.size() > 0,       # phải có quái cũ để so, không thì test vô nghĩa
		"chơi lại thì quái của lượt cũ biến hết")
	_expect(func() -> bool: return swarm.hero.global_position == Vector3.ZERO,
		"chơi lại thì về giữa sân")


# --- khung chạy kịch bản ---

func _do(fn: Callable) -> void:
	_steps.append(["do", fn])


func _expect(cond: Callable, what: String) -> void:
	_steps.append(["expect", cond, what])


func _wait(frames: int) -> void:
	_steps.append(["wait", frames])


func _note(text: String) -> void:
	_steps.append(["note", text])


## Bơm phím vào Input để hero.gd đọc được bằng Input.is_key_pressed().
func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _tap(code: Key) -> void:
	_do(func() -> void: _key(code, true))
	_wait(4)
	_do(func() -> void: _key(code, false))


func _process(_delta: float) -> bool:
	# canh liên tục: đang miễn thương thì tuyệt đối không được mất máu
	if _hp_guard >= 0 and swarm.hero.is_invulnerable() and swarm.hero.hp < _hp_guard:
		fails.append("máu tụt trong lúc đang miễn thương")
		_hp_guard = -1

	if _idx >= _steps.size():
		_report()
		return true

	var step: Array = _steps[_idx]
	match step[0]:
		"note":
			print(step[1])
			_advance()
		"do":
			step[1].call()
			_advance()
		"wait":
			_wait_frames += 1
			if _wait_frames >= int(step[1]):
				_wait_frames = 0
				_advance()
		"expect":
			if step[1].call():
				print("  OK   " + step[2])
				_advance()
			else:
				_waited += 1
				if _waited > WAIT_MAX:
					print("  SAI  " + step[2])
					fails.append(step[2])
					_advance()
	return false


func _advance() -> void:
	_idx += 1
	_waited = 0


func _report() -> void:
	print("")
	if fails.is_empty():
		print("=== TẤT CẢ ĐỀU ĐẠT ===")
	else:
		print("=== %d MỤC SAI ===" % fails.size())
		for f in fails:
			print("  - " + f)


func _finalize() -> void:
	if swarm:
		swarm.free()
