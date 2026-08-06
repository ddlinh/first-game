extends SceneTree
## Chụp ảnh để kiểm tầng vẽ. Chạy KHÔNG kèm --headless:
##   godot --path godot --script proto2/shot.gd

var view: Node
var frames := 0
var pending := false
var done := false


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(4242)
	view = load("res://proto2/Agents.tscn").instantiate()
	root.add_child(view)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		view._card_shown = false   # bỏ thẻ chủng để chụp cảnh chơi
	if frames == 5:
		for _s in 30:
			view.col.add_nutrient(Vector2(0, 0), 8.0)      # dồn cho đông → biofilm tự kết
			for _i in 10:
				view.col.update(0.04)
	elif frames == 9 and not pending:
		pending = true
		RenderingServer.frame_post_draw.connect(_grab.bind("_shot-agents-a.png"), CONNECT_ONE_SHOT)
	elif frames == 40:
		view.col.spawn_phages(12)
		view.col.spawn_rivals(4)     # cho thấy T6SS đâm rival
		for _i in 16:
			view.col.update(0.04)   # tua ngắn: bắt lúc combat đang diễn ra
	elif frames == 42:
		for _i in 3:
			view.col.update(0.04)   # để combat sinh sự kiện, view kịp bung hiệu ứng
	elif frames == 44 and not pending:
		pending = true
		RenderingServer.frame_post_draw.connect(_grab.bind("_shot-agents-b.png"), CONNECT_ONE_SHOT)
	return done


func _grab(fname: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://proto2/%s" % fname)
	print("đã chụp proto2/%s  (dân số %d, biofilm %d, phage %d, cross-feeder %d)" % [
		fname, view.col.population(), view.col.buildings.size(),
		view.col.phages.size(), view.col.crossfeeders.size()])
	pending = false
	if fname == "_shot-agents-b.png":
		done = true


func _finalize() -> void:
	if view:
		view.free()
