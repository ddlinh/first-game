extends SceneTree
## Chụp bằng chứng cho các hiệu ứng. Chúng chỉ sống khoảng 0.2-0.3 giây nên không
## thể trông vào ảnh chụp ngẫu nhiên giữa trận — ở đây dựng hẳn một cảnh: xếp một
## dãy slime trong tầm sét cùng vài con máu thấp cho nổ dây, bắt nhân vật chém, rồi
## chụp ngay frame sau.

var swarm: Swarm
var frames := 0
var stage := 0
var pending := false
var done := false

## Dãy slime: con đầu nằm trong tầm chém, các con sau cách nhau dưới tầm sét
## (2.7 m) nên điện phải nhảy hết chuỗi. Con đầu để 1 máu cho chắc chắn nổ.
## Ba con đầu để 1 máu và sát nhau (dưới bán kính nổ 1.8 m) nên chết là nổ dây
## ngay; hai con sau đủ máu để sống, làm mồi cho sét lan.
const SLIMES := [
	{"pos": Vector3(1.4, 0, 0.2), "hp": 1},
	{"pos": Vector3(2.6, 0, 1.2), "hp": 1},
	{"pos": Vector3(3.9, 0, 2.0), "hp": 1},
	{"pos": Vector3(5.6, 0, 2.6), "hp": 10},
	{"pos": Vector3(7.2, 0, 3.4), "hp": 10},
]


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false
	root.add_child(swarm)


func _process(_delta: float) -> bool:
	frames += 1
	# Lỗi script KHÔNG làm dừng SceneTree — thiếu trần này thì một hàm gọi sai tên
	# sẽ khiến test chạy mãi và in lỗi hàng nghìn lần.
	if frames > 600:
		push_error("quá 600 frame mà chưa chụp xong")
		return true
	if pending:
		return done

	match stage:
		0:
			if frames < 30:
				return false
			swarm.start_game()
			stage = 1
		1:
			# dẹp sạch quái tự spawn rồi xếp dãy slime của mình vào
			for c in swarm.mobs_root.get_children():
				swarm.mobs_root.remove_child(c)
				c.queue_free()
			var scene: PackedScene = load("res://scenes/Mob.tscn")
			for entry in SLIMES:
				var m: Mob = scene.instantiate()
				m.kind = "slime"
				m.hp = int(entry["hp"])
				m.damage = 2
				m.speed_pct = 0.0            # đứng yên cho ảnh sạch
				m.wet = true
				m.target = swarm.hero
				m.position = entry["pos"]
				m.killed.connect(swarm._on_mob_killed)
				swarm.mobs_root.add_child(m)
			stage = 2
		2:
			var r: float = swarm.hero.weapon.swing_radius_pct() * Hero.PCT
			var dmg: int = swarm.hero.weapon.swing_damage()
			print("bán kính chém = %.2f m, sát thương = %d, sét nhảy %d chặng"
				% [r, dmg, swarm.hero.weapon.chain_jumps()])
			# _swing() tự phát signal swung nên swarm xử lý sát thương, sét và nổ;
			# gọi một chỗ này là đủ cả animation lẫn hiệu ứng.
			swarm.hero._swing(swarm.cam)
			_count_fx()
			pending = true
			RenderingServer.frame_post_draw.connect(_grab, CONNECT_ONE_SHOT)
		3:
			done = true

	return done


## Đếm node hiệu ứng đang có trong cây scene — chứng cứ độc lập với ảnh chụp.
func _count_fx() -> void:
	var booms := 0
	var bolts := 0
	for c in swarm.get_children():
		if c is Boom:
			booms += 1
		elif c is Lightning:
			bolts += 1
	print("node Boom đang sống = %d, node Lightning = %d" % [booms, bolts])
	for c in swarm.get_children():
		if c is Lightning:
			var m := (c as Lightning).mesh
			print("mesh tia sét: %d mặt (0 = không vẽ được gì)"
				% (m.get_faces().size() / 3 if m else 0))
	for c in swarm.get_children():
		if c is Boom:
			print("một cú nổ có %d phần (cầu sáng + vòng sóng mặt đất)"
				% c.get_child_count())
			break
	var ring: MeshInstance3D = swarm.hero.ring
	var mat := ring.get_surface_override_material(0) as StandardMaterial3D
	print("vòng chém: scale=%.2f  alpha=%.2f" % [ring.scale.x, mat.albedo_color.a])


func _grab() -> void:
	var img := root.get_texture().get_image()
	img.save_png("res://_shot-fx.png")
	print("đã chụp _shot-fx.png")
	pending = false
	stage = 3


func _finalize() -> void:
	if swarm:
		swarm.free()
