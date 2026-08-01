extends SceneTree
## Test tạm: chạy trọn một vòng map vây không cần cửa sổ, in trạng thái mỗi 5 giây.
##
## Có GIỮ CHUỘT suốt vòng đấu — từ khi chém là chủ động, không bấm chuột thì test
## này chỉ đứng chịu chết và chẳng chạy qua nhánh nào của chém, sét lan hay nổ dây.

var swarm: Swarm
var frames := 0


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false      # test không được ghi kỷ lục của người chơi
	root.add_child(swarm)


func _process(_delta: float) -> bool:
	frames += 1
	# _ready của scene chỉ chạy sau _initialize nên phải vào vòng đấu từ frame đầu,
	# lúc đó các @onready mới có giá trị.
	if frames == 1:
		swarm.start_game()          # bỏ qua màn chờ, vào thẳng vòng đấu
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		Input.parse_input_event(ev)   # giữ chuột, cho chém liên tục
		return false
	if frames % 300 == 0:
		print("t=%5.1f  hp=%3d  dur=%5.1f  kills=%2d  alive=%2d  dash=%.2f  hero@(%.1f, %.1f)" % [
			swarm.elapsed, swarm.hero.hp, swarm.hero.weapon.dur, swarm.kills,
			swarm._alive_count(), swarm.hero.dash_ready_ratio(),
			swarm.hero.global_position.x, swarm.hero.global_position.z])
	if swarm.state != Swarm.State.PLAYING:
		print("--- KẾT THÚC: ", swarm.lbl_result.text.replace("\n", " | "))
		return true
	if frames > 12000:
		print("!!! quá 12000 frame mà vòng đấu chưa kết thúc")
		return true
	return false


func _finalize() -> void:
	if swarm:
		swarm.free()          # tránh cảnh báo rò rỉ ObjectDB khi thoát
