extends SceneTree
## Chẩn đoán độ mượt của chuyển động.
##
## Ý tưởng: nhân vật được dịch trong _physics_process (60 lần/giây), còn màn hình
## vẽ theo tốc độ khác. Nếu vẽ nhanh hơn physics thì nhiều frame liên tiếp cùng
## dùng đúng một vị trí -> mắt thấy giật thành từng bậc.
##
## Cách đo: cho nhân vật chạy đều rồi trong _process đếm xem bao nhiêu frame có
## vị trí Y HỆT frame trước. Tỷ lệ đó chính là mức giật.
## Nếu bật nội suy, so thêm với get_global_transform_interpolated() — đây là cái
## mà renderer thực sự dùng.

var swarm: Swarm
var frames := 0
var phys := 0
var dup_raw := 0
var dup_interp := 0
var last_raw := Vector3.ZERO
var last_interp := Vector3.ZERO
var has_interp := false
var t := 0.0


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false
	root.add_child(swarm)


func _physics_process(_delta: float) -> bool:
	phys += 1
	if phys == 1:
		swarm.start_game()
		has_interp = swarm.hero.has_method("get_global_transform_interpolated")
		print("nội suy vật lý đang: %s" % (
			"BẬT" if ProjectSettings.get_setting(
				"physics/common/physics_interpolation", false) else "TẮT"))
		print("có get_global_transform_interpolated(): %s" % has_interp)
	# tự lái nhân vật chạy đều sang một hướng, không phụ thuộc bàn phím
	if phys > 5:
		t += 1.0 / 60.0
		swarm.hero.global_position = Vector3(sin(t * 0.8) * 5.0, 0, cos(t * 0.8) * 5.0)
	return false


func _process(_delta: float) -> bool:
	frames += 1
	if phys < 10:
		return false

	var raw: Vector3 = swarm.hero.global_position
	if raw.is_equal_approx(last_raw):
		dup_raw += 1
	last_raw = raw

	if has_interp:
		var ip: Vector3 = swarm.hero.get_global_transform_interpolated().origin
		if ip.is_equal_approx(last_interp):
			dup_interp += 1
		last_interp = ip

	if frames < 600:
		return false

	var measured := frames - 9
	print("")
	print("frame vẽ = %d, bước physics = %d  -> vẽ nhanh gấp %.2f lần physics"
		% [frames, phys, float(frames) / float(phys)])
	print("vị trí thô     : %d/%d frame trùng frame trước = %.1f%% giật"
		% [dup_raw, measured, 100.0 * dup_raw / measured])
	if has_interp:
		print("vị trí nội suy : %d/%d frame trùng frame trước = %.1f%% giật"
			% [dup_interp, measured, 100.0 * dup_interp / measured])
	return true


func _finalize() -> void:
	if swarm:
		swarm.free()
