class_name Board
extends Node2D

## Tầng biểu diễn 2.5D. Chỉ ĐỌC Sim rồi chiếu lên màn hình, tuyệt đối không ghi
## ngược — mọi thay đổi lưới đều đi qua Colony (luồng một chiều, mục 3 tài liệu).
##
## Phép chiếu isometric đúng công thức tài liệu: x_iso = (x - y) * TW,
## y_iso = (x + y) * TH. Cả lưới được đẩy lên GPU thành một texture R8 duy nhất,
## nên chi phí vẽ 32.400 ô gần như bằng chi phí vẽ một hình chữ nhật.

## Bề ngang mặt thạch trên màn hình. Cỡ ô suy ra từ đây chứ không cố định, để đổi
## cạnh lưới không làm cái đĩa tràn ra ngoài cửa sổ.
const DISH_WIDTH := 916.0

var tile_w := 3.6
var tile_h := 1.8

var sim: Sim

var _species_img: Image
var _species_tex: ImageTexture
var _hp_img: Image
var _hp_tex: ImageTexture
var _mat: ShaderMaterial
var _wave := 0.0

@onready var grid_sprite: Sprite2D = $Grid


func setup(s: Sim) -> void:
	sim = s
	# Đĩa chiếu 45 độ rộng đúng size*√2*tile_w, nên chia ngược ra là được cỡ ô.
	tile_w = DISH_WIDTH / (sim.size * sqrt(2.0))
	tile_h = tile_w * 0.5
	_species_img = Image.create_from_data(sim.size, sim.size, false, Image.FORMAT_R8, sim.grid)
	_species_tex = ImageTexture.create_from_image(_species_img)
	_hp_img = Image.create_from_data(sim.size, sim.size, false, Image.FORMAT_R8, sim.hp)
	_hp_tex = ImageTexture.create_from_image(_hp_img)

	grid_sprite.texture = _species_tex
	grid_sprite.centered = false
	# Ma trận chiếu: trục x của sprite đi theo (TW, TH), trục y theo (-TW, TH).
	# Gốc kéo lên -L*TH để tâm lưới rơi đúng vào gốc toạ độ của Board.
	grid_sprite.transform = Transform2D(
		Vector2(tile_w, tile_h), Vector2(-tile_w, tile_h), Vector2(0.0, -sim.size * tile_h))

	_mat = ShaderMaterial.new()
	_mat.shader = load("res://scripts/dish.gdshader")
	_mat.set_shader_parameter("species_tex", _species_tex)
	_mat.set_shader_parameter("hp_tex", _hp_tex)
	_mat.set_shader_parameter("grid_size", float(sim.size))
	# Màu truyền từ Palette xuống chứ không để shader dùng giá trị mặc định của nó:
	# mặc định trong shader là bản sao thứ hai của bảng màu, và bản sao thứ hai thì
	# sớm muộn cũng lệch khỏi bản chính.
	_mat.set_shader_parameter("col_toxic", Palette.field(Sim.TOXIC))
	_mat.set_shader_parameter("col_sensitive", Palette.field(Sim.SENSITIVE))
	_mat.set_shader_parameter("col_resistant", Palette.field(Sim.RESISTANT))
	_mat.set_shader_parameter("col_agar", Palette.of("agar"))
	_mat.set_shader_parameter("col_barrier", Palette.of("barrier"))
	grid_sprite.material = _mat


func _process(delta: float) -> void:
	if sim == null:
		return
	_wave += delta
	# Image.create_from_data chỉ bọc lại mảng có sẵn của Sim chứ không sao chép ô
	# nào, nên đẩy texture mỗi khung rẻ hơn hẳn việc tự tô 32.400 điểm ảnh.
	_species_img.set_data(sim.size, sim.size, false, Image.FORMAT_R8, sim.grid)
	_species_tex.update(_species_img)
	_hp_img.set_data(sim.size, sim.size, false, Image.FORMAT_R8, sim.hp)
	_hp_tex.update(_hp_img)
	_mat.set_shader_parameter("wave_time", _wave)
	queue_redraw()


## Ô lưới -> điểm trên màn hình (toạ độ cục bộ của Board). Cộng 0.5 để lấy tâm ô.
func cell_to_local(x: float, y: float) -> Vector2:
	return Vector2(
		(x - y) * tile_w,
		(x + y) * tile_h - sim.size * tile_h)


## Nghịch đảo của cell_to_local — dùng cho chuột.
func local_to_cell(p: Vector2) -> Vector2i:
	var sum := (p.y + sim.size * tile_h) / tile_h
	var diff := p.x / tile_w
	return Vector2i(int(floor((sum + diff) * 0.5)), int(floor((sum - diff) * 0.5)))


## Bán trục của mặt đĩa sau khi chiếu. Chiếu 45 độ biến hình tròn bán kính R
## thành ellipse ngang R*√2*TW, dọc R*√2*TH.
func dish_radii() -> Vector2:
	var r := sim.size * 0.5
	return Vector2(r * sqrt(2.0) * tile_w, r * sqrt(2.0) * tile_h)


func _draw() -> void:
	if sim == null:
		return
	var rad := dish_radii()

	# Bóng đổ của đĩa trên bàn thí nghiệm.
	_ellipse(Vector2(0, 14), rad * 1.03, Color(0, 0, 0, 0.45))
	# Thành đĩa Petri: một vành thuỷ tinh dày, sáng ở mép trên.
	_ellipse(Vector2.ZERO, rad * 1.05, Palette.of("glass"))
	_ellipse(Vector2(0, -3), rad * 1.02, Palette.of("glass_inner"))
	# Mặt thạch. Sprite lưới phủ lên phần này, nhưng shader discard mọi điểm ngoài
	# vành nên hai đường sáng dưới đây vẫn thấy được — khỏi cần lớp vẽ đè lên trên.
	_ellipse(Vector2.ZERO, rad, Palette.of("dish"))
	var rim := Palette.of("rim")
	_ellipse_outline(Vector2.ZERO, rad * 1.01, rim, 3.0)
	_ellipse_outline(Vector2.ZERO, rad * 1.05, Color(rim, rim.a * 0.55), 2.0)


func _ellipse(center: Vector2, radii: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 64:
		var a := TAU * i / 64.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, col)


func _ellipse_outline(center: Vector2, radii: Vector2, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i in 65:
		var a := TAU * i / 64.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polyline(pts, col, width, true)
