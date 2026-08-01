extends SceneTree
## Bảng tư thế: ép nhân vật vào từng mốc của từng động tác, crop quanh người rồi
## ghép tất cả vào MỘT ảnh (_shot-pose.png). Có bảng này mới soi được rig ghép
## đúng chỗ chưa và thứ tự chiều sâu có sai không — chụp giữa trận thì animation
## trôi quá nhanh, không bắt được mốc nào.
##
## Cách ép tư thế: gán thẳng biến trạng thái rồi gọi _anim(0.0). Delta 0 nên không
## pha nào tự chạy tiếp, tư thế đứng im đúng mốc mình muốn.

const CROP := Vector2i(150, 215)     ## vùng crop quanh nhân vật, pixel màn hình
const ZOOM := 2
const COLS := 5

## [tên, hàm dựng trạng thái]
var poses: Array = []

var swarm: Swarm
var hero: Hero
var sheet: Image
var frames := 0
var idx := 0
var pending := false
var done := false


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false
	root.add_child(swarm)


func _build_poses() -> void:
	poses = [
		["đứng thở", func() -> void:
			hero._gait = 0.0
			hero._idle_t = PI * 0.5],
		["đi — chân phải trước", func() -> void:
			hero._gait = 1.0
			hero._walk_t = PI * 0.5],
		["đi — hai chân chụm", func() -> void:
			hero._gait = 1.0
			hero._walk_t = PI],
		["đi — chân trái trước", func() -> void:
			hero._gait = 1.0
			hero._walk_t = PI * 1.5],
		["chém — lấy đà", func() -> void:
			hero._gait = 0.0
			hero._atk_phase = 0.24],
		["chém — giữa nhát quét", func() -> void:
			hero._gait = 0.0
			hero._atk_phase = 0.36],
		["chém — hết đà", func() -> void:
			hero._gait = 0.0
			hero._atk_phase = 0.46],
		["lăn — 1/4 vòng", func() -> void:
			hero._roll_phase = 0.25],
		["lăn — nửa vòng", func() -> void:
			hero._roll_phase = 0.5],
		["ăn đòn — giật người", func() -> void:
			hero._gait = 0.0
			hero._hurt_phase = 0.05],
	]


## Xoá mọi pha chồng lấn để tư thế sau không dính đuôi tư thế trước.
func _clear() -> void:
	hero._atk_phase = -1.0
	hero._roll_phase = -1.0
	hero._hurt_phase = -1.0
	hero._gait = 0.0
	hero._walk_t = 0.0
	hero._idle_t = 0.0


func _process(_delta: float) -> bool:
	frames += 1
	if pending:
		return done
	if frames < 30:
		return false

	if hero == null:
		hero = swarm.hero
		# Vào trận để panel menu biến đi (nó che đúng chỗ nhân vật), rồi đóng băng
		# toàn bộ: không spawn quái, không tự chém, không đếm giờ. Ẩn luôn HUD cho
		# vùng crop sạch.
		swarm.start_game()
		swarm.set_physics_process(false)
		hero.set_physics_process(false)
		for c in swarm.mobs_root.get_children():
			swarm.mobs_root.remove_child(c)
			c.queue_free()
		(swarm.get_node("HUD") as CanvasLayer).hide()
		_build_poses()
		var rows := int(ceil(float(poses.size()) / COLS))
		sheet = Image.create(CROP.x * ZOOM * COLS, CROP.y * ZOOM * rows, false, Image.FORMAT_RGB8)
		sheet.fill(Color(0.02, 0.02, 0.03))
		print("bảng %d tư thế, %d cột:" % [poses.size(), COLS])

	if idx >= poses.size():
		sheet.save_png("res://_shot-pose.png")
		print("đã ghép _shot-pose.png (%dx%d)" % [sheet.get_width(), sheet.get_height()])
		done = true
		return true

	_clear()
	(poses[idx][1] as Callable).call()
	hero._anim(0.0)                 # delta 0: áp tư thế, không cho pha chạy tiếp
	print("  %2d. %s" % [idx + 1, poses[idx][0]])
	pending = true
	RenderingServer.frame_post_draw.connect(_grab, CONNECT_ONE_SHOT)
	return false


func _grab() -> void:
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)

	# tâm crop lấy đúng bằng phép chiếu vị trí giữa người lên màn hình
	var mid := hero.global_position + Vector3.UP * Hero.RIG_Y
	var at := Vector2i(swarm.cam.unproject_position(mid)) - CROP / 2
	at = at.clamp(Vector2i.ZERO, Vector2i(img.get_width(), img.get_height()) - CROP)

	var cell := img.get_region(Rect2i(at, CROP))
	cell.resize(CROP.x * ZOOM, CROP.y * ZOOM, Image.INTERPOLATE_NEAREST)
	var col := idx % COLS
	var row := idx / COLS
	sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()),
		Vector2i(col * CROP.x * ZOOM, row * CROP.y * ZOOM))

	pending = false
	idx += 1


func _finalize() -> void:
	if swarm:
		swarm.free()
