extends SceneTree
## Test tạm: chạy trọn một vòng map vây không cần cửa sổ, in trạng thái mỗi 5 giây.

var swarm: Node
var frames := 0


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	root.add_child(swarm)


func _process(_delta: float) -> bool:
	frames += 1
	if frames % 300 == 0:
		print("t=%5.1f  hp=%3d  dur=%5.1f  kills=%2d  alive=%2d  hero@(%.1f, %.1f)" % [
			swarm.elapsed, swarm.hero.hp, swarm.hero.weapon.dur, swarm.kills,
			swarm.mobs_root.get_child_count(),
			swarm.hero.global_position.x, swarm.hero.global_position.z])
	if not swarm.running:
		print("--- KẾT THÚC: ", swarm.lbl_result.text.replace("\n", " | "))
		return true
	if frames > 12000:
		print("!!! quá 12000 frame mà vòng đấu chưa kết thúc")
		return true
	return false
