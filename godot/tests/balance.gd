extends SceneTree
## Đo độ khó: chạy nhiều lượt liên tiếp không cần cửa sổ với hai kiểu người chơi.
##
##   godot --headless --path . --script tests/balance.gd -- im    (đứng im, không bấm gì)
##   godot --headless --path . --script tests/balance.gd -- bot    (né và lăn tự động)
##
## Mục tiêu cân bằng: kiểu "im" phải THUA gần như luôn, kiểu "bot" phải THẮNG
## phần lớn. Nếu "im" mà thắng thì game tự chơi hộ người chơi.

const ROUNDS := 8

## Godot headless vẫn tiến theo thời gian thực, nên phải kéo nhanh thời gian lên
## nếu không mỗi kiểu người chơi mất gần 3 phút. Mọi thứ trong game tính theo
## delta nên kết quả không đổi, chỉ có bước physics chạy dày hơn mỗi giây thật.
const SPEED := 8.0

var swarm: Swarm
var mode := "im"
var round_no := 0
var results: Array[Dictionary] = []
var started := false
var quit := false
var keys_down := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a in ["im", "bot"]:
			mode = a
	Engine.time_scale = SPEED
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false      # test không được ghi kỷ lục của người chơi
	root.add_child(swarm)


func _key(code: Key, pressed: bool) -> void:
	if keys_down.get(code, false) == pressed:
		return
	keys_down[code] = pressed
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _release_all() -> void:
	for code in keys_down.keys():
		_key(code, false)


## Bot: chạy ra xa trọng tâm đám quái gần, thấy quá gần thì lăn.
func _drive() -> void:
	var hero := swarm.hero
	var cam := swarm.cam

	var away := Vector3.ZERO
	var nearest := 999.0
	for child in swarm.mobs_root.get_children():
		var m := child as Mob
		if m == null or m.dead:
			continue
		var to := hero.global_position - m.global_position
		to.y = 0.0
		var d := maxf(0.4, to.length())
		nearest = minf(nearest, d)
		away += to / d / d          # càng gần càng đẩy mạnh

	# kéo nhẹ về giữa sân để không bị dồn vào góc
	away += -hero.global_position * 0.02

	if away.length_squared() < 0.000001:
		_release_all()
		return

	# hero.gd quay hướng nhập liệu theo camera, nên phải quay ngược lại mới ra WASD
	var want := away.normalized().rotated(Vector3.UP, -cam.global_rotation.y)
	_key(KEY_W, want.z < -0.35)
	_key(KEY_S, want.z > 0.35)
	_key(KEY_A, want.x < -0.35)
	_key(KEY_D, want.x > 0.35)
	_key(KEY_SPACE, nearest < 1.6 and hero.dash_ready_ratio() >= 1.0)


func _physics_process(_delta: float) -> bool:
	if not started:
		started = true
		swarm.start_game()
		return false

	if swarm.state == Swarm.State.PLAYING:
		if mode == "bot":
			_drive()
		return false

	# vừa xong một lượt
	_release_all()
	results.append({
		"win": swarm.elapsed >= Swarm.SURVIVE,
		"t": swarm.elapsed,
		"kills": swarm.kills,
		"hp": maxi(0, swarm.hero.hp),
	})
	round_no += 1
	if round_no >= ROUNDS:
		_report()
		quit = true
		return false
	swarm.start_game()
	return false


func _process(_delta: float) -> bool:
	return quit


func _report() -> void:
	var wins := 0
	var sum_t := 0.0
	var sum_k := 0
	var sum_hp := 0
	print("kiểu người chơi: %s   (%d lượt)" % [mode, results.size()])
	for i in results.size():
		var r: Dictionary = results[i]
		if r["win"]:
			wins += 1
		sum_t += r["t"]
		sum_k += int(r["kills"])
		sum_hp += int(r["hp"])
		print("  lượt %2d: %s  t=%5.1fs  hạ=%2d  máu còn=%2d" % [
			i + 1, "THẮNG" if r["win"] else "thua ", r["t"], r["kills"], r["hp"]])
	var n := float(results.size())
	print("→ thắng %d/%d   trung bình: trụ %.1fs, hạ %.1f con, máu còn %.1f" % [
		wins, results.size(), sum_t / n, sum_k / n, sum_hp / n])


func _finalize() -> void:
	if swarm:
		swarm.free()
