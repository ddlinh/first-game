extends SceneTree
## Test tạm: chạy scene có render rồi chụp hai ảnh — màn chờ và giữa vòng đấu.

var swarm: Swarm
var frames := 0
var shots := 0
var pending := false
var done := false

## frame chụp -> tên file
const SHOTS := {60: "_shot-menu.png", 900: "_shot-game.png"}


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false      # test không được ghi kỷ lục của người chơi
	root.add_child(swarm)


func _process(_delta: float) -> bool:
	frames += 1

	if frames == 90:
		swarm.start_game()

	# cho nhân vật đi chéo và lăn một nhịp để thấy sprite lật, đèn di chuyển
	if swarm.state == Swarm.State.PLAYING:
		swarm.hero.global_position.x = sin(frames * 0.01) * 3.0
		swarm.hero.global_position.z = cos(frames * 0.008) * 2.0

	if frames in SHOTS and not pending:
		pending = true
		RenderingServer.frame_post_draw.connect(_grab.bind(SHOTS[frames]), CONNECT_ONE_SHOT)

	return done


func _grab(fname: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://%s" % fname)
	print("đã chụp %s: %dx%d" % [fname, img.get_width(), img.get_height()])
	pending = false
	shots += 1
	if shots >= SHOTS.size():
		done = true


func _finalize() -> void:
	if swarm:
		swarm.free()          # tránh cảnh báo rò rỉ ObjectDB khi thoát
