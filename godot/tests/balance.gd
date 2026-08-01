extends SceneTree
## Đo độ khó: chạy nhiều lượt liên tiếp không cần cửa sổ với hai kiểu người chơi.
##
##   ... -- im     đứng im, không bấm gì cả
##   ... -- spam   đứng im nhưng chém liên tục mỗi khi hết hồi chiêu
##   ... -- bot    di chuyển, lăn né, và chỉ chém khi có quái trong tầm
##   ... -- bot speed=1 rounds=6      (chạy đúng tốc độ thật, để đối chiếu)
##
## Từ khi chém phải bấm chuột, kiểu "im" không còn là phép đo hữu ích nữa: không
## chém thì chắc chắn chết, nên nó chỉ còn dùng để kiểm tra game không tự thắng hộ.
## Phép đo thật là "spam" — nó đúng bằng hành vi auto-chém cũ:
##
##   "spam" phải THUA   (không thì đứng một chỗ nhả đòn là xong, vị trí vô nghĩa)
##   "bot"  phải THẮNG phần lớn
##
## CÁCH CHẠY NHANH HƠN THỜI GIAN THỰC — chỗ này từng làm sai và cho số liệu giả:
##
## Sai: chỉ đặt Engine.time_scale. Godot KHÔNG chạy thêm bước physics; nó nhân
## delta của mỗi bước lên. Ở time_scale 12 mỗi bước tiến 0.2 giây game thay vì
## 1/60, nên quái nhảy từng đoạn to và va chạm bị lấy mẫu quá thưa. Cùng một
## build, đo ở time_scale 8 ra "đứng im thắng 4/8", ở 12 ra "16/16".
##
## Đúng: tăng physics_ticks_per_second theo cùng hệ số. Khi đó
##   delta mỗi bước = time_scale / ticks = 1/60, y như lúc chơi thật,
## chỉ là mỗi giây thật chạy nhiều bước hơn. Kiểm chứng bằng speed=1.

const BASE_TICKS := 60

var rounds := 16
var speed := 10.0

var swarm: Swarm
var mode := "im"
var round_no := 0
var results: Array[Dictionary] = []
var started := false
var quit := false
var keys_down := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a in ["im", "spam", "bot"]:
			mode = a
		elif a.begins_with("speed="):
			speed = maxf(1.0, float(a.trim_prefix("speed=")))
		elif a.begins_with("rounds="):
			rounds = maxi(1, int(a.trim_prefix("rounds=")))

	Engine.physics_ticks_per_second = int(BASE_TICKS * speed)
	Engine.time_scale = speed
	var step := speed / float(Engine.physics_ticks_per_second)
	print("bước physics = %.6f s (phải bằng %.6f để khớp lúc chơi thật)"
		% [step, 1.0 / BASE_TICKS])

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
	_mouse(false)


var mouse_down := false

## Bơm nút chuột vào Input để hero.gd đọc được bằng Input.is_mouse_button_pressed().
func _mouse(pressed: bool) -> void:
	if mouse_down == pressed:
		return
	mouse_down = pressed
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	Input.parse_input_event(ev)


## Bot: chạy ra xa trọng tâm đám quái gần, thấy quá gần thì lăn, và chỉ chém khi
## có con nào lọt vào tầm chém — chém không thì lãng phí độ bền.
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

	_mouse(nearest < hero.weapon.swing_radius_pct() * Hero.PCT)

	# kéo nhẹ về giữa sân để không bị dồn vào góc
	away += -hero.global_position * 0.02

	if away.length_squared() < 0.000001:
		return

	# hero.gd quay hướng nhập liệu theo camera, nên phải quay ngược lại mới ra WASD
	var want := away.normalized().rotated(Vector3.UP, -cam.global_rotation.y)
	_key(KEY_W, want.z < -0.35)
	_key(KEY_S, want.z > 0.35)
	_key(KEY_A, want.x < -0.35)
	_key(KEY_D, want.x > 0.35)
	_key(KEY_SPACE, nearest < 1.6 and hero.dash_ready_ratio() >= 1.0)


func _physics_process(_delta: float) -> bool:
	# Chỉ _process mới dừng được vòng lặp, mà ở ticks cao physics chạy dày hơn
	# _process rất nhiều — không chặn ở đây thì sau khi báo cáo xong vẫn có thêm
	# hàng chục lượt bị ghi và in báo cáo lặp lại.
	if quit:
		return false
	if not started:
		started = true
		swarm.start_game()
		return false

	if swarm.state == Swarm.State.PLAYING:
		match mode:
			"bot": _drive()
			"spam": _mouse(true)      # đúng hành vi auto-chém cũ: luôn nhả đòn
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
	if round_no >= rounds:
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
