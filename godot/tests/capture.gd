extends SceneTree
## Chạy có render rồi chụp bốn ảnh: hướng dẫn, mặt đĩa giữa trận, đĩa đã chín hoa
## văn, và màn chọn thẻ. Cần bản có cửa sổ — chạy KHÔNG kèm --headless.
##
## Truyền tên tone sau `--` để chụp một bảng màu khác và thêm hậu tố vào tên file:
##   godot --path godot --script tests/capture.gd -- ink
## Lưới được gieo hạt cố định nên các tone ra thế đĩa gần giống nhau, đủ để so màu.
## Nhưng KHÔNG giống hệt: sim chạy theo delta thật của từng khung nên máy nhanh chậm
## khác nhau là số nhịp khác nhau. Muốn hai ảnh trùng khít từng ô thì thêm
## `--fixed-fps 60` vào dòng lệnh.

var colony: Colony
var frames := 0
var pending := false
var done := false
var suffix := ""

## khung chụp -> tên file
const SHOTS := {
	40: "_shot-huong-dan.png",
	150: "_shot-tran-dau.png",
	900: "_shot-hoa-van.png",
	1000: "_shot-the-bai.png",
}


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(4242)

	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		var want := args[0].to_upper()
		if Palette.Tone.has(want):
			Palette.tone = Palette.Tone[want]
			suffix = "-" + args[0].to_lower()
		else:
			print("không có tone «%s», dùng %s" % [args[0], Palette.Tone.keys()])

	colony = load("res://scenes/Dish.tscn").instantiate()
	root.add_child(colony)


func _process(_delta: float) -> bool:
	frames += 1

	# Ép hiện lớp hướng dẫn thay vì xoá file lưu cho nó tự hiện: máy nào chơi rồi thì
	# cờ "đã xem hướng dẫn" đã bật, mà chụp ảnh không phải lý do để xoá tiến trình
	# của người chơi.
	if frames == 20:
		colony.state = Colony.State.TUTORIAL
		colony._tut_step = 0
		colony._show_tutorial()
	if frames == 45:
		while colony.state != Colony.State.PLAYING:
			colony._on_continue()
	# Vài nhát cấy cho có mây độc và cụm tím rõ trên ảnh.
	if frames in [120, 128, 136]:
		colony._try_plant(Vector2i(colony.grid_size / 2 + (frames - 128) * 2, colony.grid_size / 2))
		colony.charges = 1
	if frames == 990:
		colony._win("ảnh chụp")
		colony._on_continue()

	if frames in SHOTS and not pending:
		pending = true
		RenderingServer.frame_post_draw.connect(_grab.bind(SHOTS[frames]), CONNECT_ONE_SHOT)

	return done


func _grab(fname: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://%s" % fname.replace(".png", suffix + ".png"))
	print("đã chụp %s" % fname.replace(".png", suffix + ".png"))
	pending = false
	if fname == SHOTS.values()[-1]:
		done = true


func _finalize() -> void:
	if colony:
		colony.free()
