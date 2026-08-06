extends SceneTree
## Chụp ảnh màn yaourt để kiểm view. Chạy KHÔNG kèm --headless:
##   godot --path godot --script proto2/shot_yogurt.gd

var view: Node
var frames := 0
var pending := false
var done := false


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(4242)
	view = load("res://proto2/Yogurt.tscn").instantiate()
	root.add_child(view)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		view._begin()
		for _i in 4: view.y.warm()          # ủ ~43°C
		for _i in 140: view.y.update(0.1)    # tua tới lúc đang lên men
	elif frames == 6 and not pending:
		pending = true
		RenderingServer.frame_post_draw.connect(_grab.bind("_shot-yogurt.png"), CONNECT_ONE_SHOT)
	return done


func _grab(fname: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://proto2/%s" % fname)
	print("đã chụp proto2/%s  (pH %.2f, men %.2f, mốc %d%%, state %d)" % [
		fname, view.y.pH, view.y.culture(), int(view.y.spoil * 100), view.y.state])
	done = true


func _finalize() -> void:
	if view: view.free()
