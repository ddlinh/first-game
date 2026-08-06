extends SceneTree
## Chụp mỗi CHỦNG một ảnh để soi sprite riêng. Chạy KHÔNG kèm --headless:
##   godot --path godot --script proto2/shot_strains.gd

var view: Node
var frames := 0
var idx := 0
var pending := false
var done := false
const NAMES := ["ecoli", "staph", "proteus", "bacillus"]


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(4242)
	view = load("res://proto2/Agents.tscn").instantiate()
	root.add_child(view)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		view._card_shown = false
		_setup(idx)
	elif frames == 6 and not pending:
		pending = true
		RenderingServer.frame_post_draw.connect(
			_grab.bind("_shot-strain-%s.png" % NAMES[idx]), CONNECT_ONE_SHOT)
	elif frames == 10:
		idx += 1
		if idx >= NAMES.size():
			done = true
		else:
			frames = 0
			view._enter_strain(idx)
			view._card_shown = false
	return done


func _setup(i: int) -> void:
	# Bacillus: cho ít ăn rồi để ĐÓI dài → nhiều con ngủ đông (hiện BÀO TỬ).
	var meals := 12 if i == 3 else 34
	var steps := 26 if i == 3 else 10
	for _s in meals:
		view.col.add_nutrient(Vector2(0, 0), 8.0)
		for _i in steps:
			view.col.update(0.04)


func _grab(fname: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://proto2/%s" % fname)
	print("đã chụp proto2/%s  (dân số %d, ngủ đông %d)" % [
		fname, view.col.population(), view.col.tally()[3]])   # 3 = DORMANT
	pending = false


func _finalize() -> void:
	if view:
		view.free()
