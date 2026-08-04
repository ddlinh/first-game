extends SceneTree
## Chụp bốn kiểu mọc (chủng × môi trường) khi cấy thức ăn thành HÌNH DẤU CỘNG, để
## kiểm bằng mắt. Chạy: godot --path godot --script proto2/regimes.gd

const AgentColony := preload("res://proto2/agent_colony.gd")

const CONFIGS := [
	{"name": "giu-hinh", "mot": 0.0, "hard": 1.0, "rich": 1.0},   # định cư + thạch cứng
	{"name": "lan", "mot": 1.0, "hard": 0.4, "rich": 1.0},        # bơi vừa
	{"name": "bay-dan", "mot": 1.0, "hard": 0.0, "rich": 1.2},    # thạch mềm → bầy đàn
	{"name": "nhanh", "mot": 0.25, "hard": 1.0, "rich": 0.35},    # nghèo + cứng → nhánh
]

var view: Node
var idx := 0
var t := 0
var pending := false
var done := false
var _started := false


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(4242)
	view = load("res://proto2/Agents.tscn").instantiate()
	root.add_child(view)


func _setup(i: int) -> void:
	var c := AgentColony.new(4242)
	c.auto_threat = false
	c.set_environment(CONFIGS[i]["mot"], CONFIGS[i]["hard"], CONFIGS[i]["rich"])
	view.col = c
	t = 0


func _shape(c) -> void:
	for k in 20:
		c.add_nutrient(Vector2(-140 + k * 15, 0), 3.0)   # ngang
		c.add_nutrient(Vector2(0, -140 + k * 15), 3.0)   # dọc → dấu cộng


func _process(_delta: float) -> bool:
	if not _started:            # sau _ready của view, mới ép cấu hình (khỏi bị ghi đè)
		_started = true
		_setup(0)
	if idx >= CONFIGS.size():
		return true
	t += 1
	if t <= 40:
		_shape(view.col)
		for _i in 8:
			view.col.update(0.04)
	elif t == 42 and not pending:
		pending = true
		RenderingServer.frame_post_draw.connect(_grab.bind(CONFIGS[idx]["name"]), CONNECT_ONE_SHOT)
	return done


func _grab(name: String) -> void:
	root.get_texture().get_image().save_png("res://proto2/_shot-regime-%s.png" % name)
	print("đã chụp _shot-regime-%s.png  (dân số %d)" % [name, view.col.population()])
	pending = false
	idx += 1
	if idx < CONFIGS.size():
		_setup(idx)
	else:
		done = true


func _finalize() -> void:
	if view:
		view.free()
