extends SceneTree
## Kiểm chứng nổ lan: quái bị hạ thì nổ, con bên cạnh chết theo lại nổ tiếp.
##
## Hai thứ phải đúng:
##   1. chuỗi có LAN thật — xếp một dãy quái sát nhau, hạ con đầu thì phải chết
##      nhiều hơn một con
##   2. chuỗi có DỪNG — sát thương giảm mỗi đời và số đời bị chặn, nên một cú nổ
##      không được quét sạch cả sân
##
## Và vụ nổ phải DỘI LẠI người chơi khi đứng trong bán kính, nhưng không dội nếu
## đang lăn né (miễn thương) — đây là thứ khiến cắm chân giữa đám đông thành sai.
##
## Kèm phép thử chịu tải: dồn 40 con vào một chỗ rồi cho nổ. Chỗ này dùng hàng đợi
## chứ không đệ quy chính là để không tràn stack ở tình huống đó.

var swarm: Swarm
var fails: Array[String] = []
var frames := 0
var stage := 0
var wait := 0
var before := 0


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false
	root.add_child(swarm)


func check(ok: bool, what: String) -> void:
	print(("  OK   " if ok else "  SAI  ") + what)
	if not ok:
		fails.append(what)


func _clear() -> void:
	for c in swarm.mobs_root.get_children():
		swarm.mobs_root.remove_child(c)
		c.queue_free()


## Đặt `n` con vào sân. `gap` là khoảng cách giữa hai con liền nhau (mét).
func _line(n: int, gap: float, hp: int) -> Array[Mob]:
	var scene: PackedScene = load("res://scenes/Mob.tscn")
	var out: Array[Mob] = []
	for i in n:
		var m: Mob = scene.instantiate()
		m.kind = "bat"
		m.hp = hp
		m.damage = 0
		m.speed_pct = 0.0             # đứng yên, không thì chúng bò lại gần nhau
		m.target = swarm.hero
		m.position = Vector3(3.0 + i * gap, 0, 6.0)
		m.killed.connect(swarm._on_mob_killed)
		swarm.mobs_root.add_child(m)
		out.append(m)
	return out


func _alive() -> int:
	return swarm._alive_count()


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 20:
		return false
	if wait > 0:
		wait -= 1
		return false

	match stage:
		0:
			swarm.start_game()
			swarm.set_physics_process(false)     # tự điều khiển nhịp, không cho spawn thêm
			stage = 1
		1:
			print("bán kính nổ = %.1f m, sát thương đời đầu = %d, tối đa %d đời"
				% [Swarm.BLAST_RADIUS, Swarm.BLAST_DAMAGE, Swarm.BLAST_MAX_GEN])
			print("— dãy 6 con sát nhau (cách 1.5 m, trong tầm nổ) —")
			_clear()
			var line := _line(6, 1.5, 5)
			before = swarm.kills
			line[0].take_hit(99)                  # hạ con đầu dãy
			swarm._run_blasts()
			wait = 3
			stage = 2
		2:
			var died := swarm.kills - before
			print("  chết %d/6 con" % died)
			check(died > 1, "nổ có lan sang con bên cạnh")
			check(died < 6, "chuỗi có dừng, không quét sạch cả dãy")
			stage = 3
		3:
			print("— dãy 6 con cách xa nhau (cách 4 m, ngoài tầm nổ) —")
			_clear()
			var far := _line(6, 4.0, 5)
			before = swarm.kills
			far[0].take_hit(99)
			swarm._run_blasts()
			wait = 3
			stage = 4
		4:
			var died2 := swarm.kills - before
			print("  chết %d/6 con" % died2)
			check(died2 == 1, "ngoài tầm nổ thì không con nào chết theo")
			stage = 5
		5:
			print("— chịu tải: 40 con dồn một chỗ —")
			_clear()
			var pile := _line(40, 0.15, 5)
			before = swarm.kills
			pile[0].take_hit(99)
			swarm._run_blasts()
			wait = 3
			stage = 6
		6:
			var died3 := swarm.kills - before
			print("  chết %d/40 con, còn sống %d" % [died3, _alive()])
			check(true, "40 con nổ dây không làm sập game (chạy tới được đây)")
			check(died3 < 40, "dồn đống cũng không quét sạch — số đời vẫn bị chặn")
			stage = 7
		7:
			print("— nổ ngay cạnh người chơi —")
			_clear()
			swarm.hero.global_position = Vector3.ZERO
			var near := _line(1, 1.0, 5)
			near[0].position = Vector3(1.0, 0, 0)      # trong bán kính nổ 1.8 m
			before = swarm.hero.hp
			near[0].take_hit(99)
			swarm._run_blasts()
			wait = 3
			stage = 8
		8:
			print("  máu %d -> %d" % [before, swarm.hero.hp])
			check(swarm.hero.hp < before, "đứng trong vụ nổ thì người chơi cũng mất máu")
			stage = 9
		9:
			print("— nổ cạnh người chơi TRONG lúc lăn né —")
			_clear()
			swarm.hero.global_position = Vector3.ZERO
			swarm.hero._invuln = 5.0                   # giả lập đang lăn, miễn thương
			var near2 := _line(1, 1.0, 5)
			near2[0].position = Vector3(1.0, 0, 0)
			before = swarm.hero.hp
			near2[0].take_hit(99)
			swarm._run_blasts()
			wait = 3
			stage = 10
		10:
			print("  máu %d -> %d" % [before, swarm.hero.hp])
			check(swarm.hero.hp == before, "đang lăn né thì vụ nổ không dội vào mình")
			swarm.hero._invuln = 0.0
			stage = 11
		11:
			print("")
			if fails.is_empty():
				print("=== TẤT CẢ ĐỀU ĐẠT ===")
			else:
				print("=== %d MỤC SAI ===" % fails.size())
				for f in fails:
					print("  - " + f)
			return true

	return false


func _finalize() -> void:
	if swarm:
		swarm.free()
