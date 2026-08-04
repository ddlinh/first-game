extends SceneTree
## Đo giá của từng tầng vẽ. Chạy KHÔNG kèm --headless.
##
## Tự tắt vsync: trong phiên chạy tự động (cửa sổ không được hợp thành thật) trình
## quản lý cửa sổ giữ mỗi khung đúng một giây, nên bật vsync thì mọi con số đo được
## đều là 1000 ms và chẳng nói lên điều gì. Người chơi thật vẫn để vsync bật.

var colony: Colony
var frames := 0
var t0 := 0
var stage := 0
var sizes := [0, 30, 60, 120, 200]


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	colony = load("res://scenes/Dish.tscn").instantiate()
	colony.tutorial_enabled = false
	root.add_child(colony)
	print("card: %s" % RenderingServer.get_video_adapter_name())


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 5:
		while colony.state != Colony.State.PLAYING:
			colony._on_continue()
		_begin()
		return false
	# 40 khung cho mỗi mức, đủ để trung bình ổn định.
	if frames > 5 and (frames - 5) % 40 == 0:
		var ms := (Time.get_ticks_msec() - t0) / 40.0
		print("  %3d chibi: %5.1f ms/khung  (%.0f fps)" % [sizes[stage], ms, 1000.0 / ms])
		stage += 1
		if stage >= sizes.size():
			return true
		_begin()
	return false


func _begin() -> void:
	colony.agents.pool = sizes[stage]
	colony.agents.setup(colony.sim, colony.board)
	t0 = Time.get_ticks_msec()


func _finalize() -> void:
	if colony:
		colony.free()
