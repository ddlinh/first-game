extends SceneTree
## Test tạm: chạy scene có render, tới giây thứ ~7 thì chụp viewport ra PNG.

var swarm: Node
var frames := 0
var asked := false
var done := false


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	root.add_child(swarm)


func _process(_delta: float) -> bool:
	frames += 1
	# cho nhân vật đi chéo một chút để thấy sprite lật và đèn di chuyển
	if swarm and swarm.hero and frames > 120:
		swarm.hero.global_position.x = sin(frames * 0.01) * 3.0
		swarm.hero.global_position.z = cos(frames * 0.008) * 2.0
	if frames > 420 and not asked:
		asked = true
		RenderingServer.frame_post_draw.connect(_grab, CONNECT_ONE_SHOT)
	return done


func _grab() -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://_shot.png")
	print("đã chụp: ", img.get_width(), "x", img.get_height())
	done = true
