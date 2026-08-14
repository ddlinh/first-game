extends SceneTree
## Chụp ảnh màn mạng lưới để kiểm view. Chạy KHÔNG kèm --headless:
##   godot --path godot --script proto2/shot_shape.gd

const Shape := preload("res://proto2/shape_level.gd")

var view: Node
var frames := 0
var pending := false
var done := false


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(4242)
	view = load("res://proto2/Shape.tscn").instantiate()
	root.add_child(view)
	# View KHÔNG được tự chạy: script này tua lõi bằng tay rồi mới chụp. Để `running`
	# bật thì view cũng update lõi theo dt thật (frame tua mất hàng chục giây → một
	# bước dt khổng lồ) và cảnh chụp ra sẽ không khớp con số đã in.
	view.running = false


## Chơi hộ một đoạn: rải đón đầu rìa dọc nhánh để ảnh có cả xanh (phủ), đỏ (tràn),
## thức ăn đang đọng và một mảng mốc do rải hớ.
func _autoplay() -> void:
	var s = view.s
	var a: Vector2 = s.nodes()[0]
	var b: Vector2 = s.nodes()[1]
	var ab := b - a
	for _step in 900:
		var t := 0.0
		for ag in s.c.agents:
			var u: float = clampf((ag["pos"] - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			if ag["pos"].distance_to(a + ab * u) <= Shape.LINK_HW + 12.0:
				t = maxf(t, u)
		var target: Vector2 = a + ab * t + ab.normalized() * 30.0
		if (target - a).length() > ab.length():
			target = b
		if s.c.nutrient_at(target) < 0.25:
			s.deposit(target)
		s.update(0.05)
		if s.elapsed > 62.0:
			break
	# Vài nhát rải HỚ ra ngoài tầm với → mốc bén vào ăn mất chỗ đó (cho ảnh có đủ ba
	# trạng thái điểm lẫn một khó khăn đang diễn ra).
	for _i in 4:
		s.deposit(Vector2(40, -195))
	for _i in 90:          # chụp lúc mốc đang phình — nó ăn xong chỗ đó là lụi
		s.update(0.05)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		view._intro.visible = false      # bỏ bảng mở màn, KHÔNG bật running
		_autoplay()
	elif frames == 6 and not pending:
		pending = true
		RenderingServer.frame_post_draw.connect(_grab.bind("_shot-shape.png"), CONNECT_ONE_SHOT)
	return done or frames > 40      # chốt cứng: dù _grab lỗi cũng KHÔNG treo cửa sổ


func _grab(fname: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://proto2/%s" % fname)
	var s = view.s
	print("đã chụp proto2/%s  (khớp %d%%, phủ %d%%, tràn %d%%, mốc %d, còn %d nhát)" % [
		fname, int(s.iou * 100), int(s.cover * 100), int(s.spill * 100),
		s.molds.size(), s.doses_left()])
	done = true


func _finalize() -> void:
	if view: view.free()
