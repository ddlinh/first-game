class_name Swarm
extends Node3D

## Map vây: sống sót hết giờ. Quái spawn ở rìa sân, càng lâu càng dày.
## Số liệu cân bằng bắt nguồn từ bản web (commit cb5e5d9) nhưng đã siết lại hẳn
## cho khớp cú lăn né — xem tests/balance.gd và README.

const PCT := 0.2
const SURVIVE := 22.0
const MAX_ALIVE := 40
const FIELD_HALF := 10.0

const SAVE_PATH := "user://ky-luc.cfg"

## Chờ một nhịp sau khi kết thúc rồi mới nhận phím, tránh vừa chết đã chơi lại vì
## người chơi đang giữ Space để lăn.
const OVER_LOCK := 0.5

## Sét chỉ nhảy được trong tầm này (mét). Đủ ngắn để người chơi phải chủ động
## gom slime lại mới ăn được chuỗi dài.
const CHAIN_RANGE := 2.7
const SHOCK_TINT := Color(0.62, 0.88, 1.0)
const BOOM_TINT := Color(1.0, 0.62, 0.26)

## Quái bị hạ thì NỔ, sát thương lan ra quanh nó, con chết theo lại nổ tiếp.
## Giảm dần mỗi đời và chặn số đời, không thì một nhát chém giữa bãi đông có thể
## quét sạch sân và người chơi chẳng cần làm gì nữa.
const BLAST_RADIUS := 1.8
const BLAST_DAMAGE := 5
const BLAST_FALLOFF := 0.6
const BLAST_MAX_GEN := 3

## Vụ nổ KHÔNG chỉ hại quái: đứng trong bán kính thì người chơi cũng ăn đòn.
## Không có phần này thì cắm chân giữa sân là quái tự dồn thành đống rồi chuỗi nổ
## quét sạch hộ — đo được đúng như vậy: đứng im spam chuột thắng 16/16.
## Nhờ nó vòng chơi thành: chém vào đám đông rồi LĂN ra khỏi vụ nổ (lăn có miễn thương).
const BLAST_SELF := 0.35   ## phần sát thương dội lại người chơi
const BLAST_SELF_CAP := 8  ## chặn tổng mỗi chuỗi, không thì nổ dây 40 con là chết tức khắc

enum State { MENU, PLAYING, OVER }

const MOB_TYPES := [
	{"kind": "bat",   "hp": 5,  "dmg": 3, "spd": 1.6, "flies": true},
	{"kind": "slime", "hp": 10, "dmg": 2, "spd": 0.9, "flies": false, "wet": true},
	{"kind": "rat",   "hp": 4,  "dmg": 2, "spd": 2.1, "flies": false},
]

var MobScene := preload("res://scenes/Mob.tscn")

var state: State = State.MENU
var elapsed: float = 0.0
var kills: int = 0
var spawn_timer: float = 0.0
var best_kills: int = 0
## Test tắt cờ này. Không có nó thì bot trong tests/balance.gd chạy 8 lượt liền sẽ
## ghi kỷ lục của MÁY vào file save của người chơi, và không ai đuổi nổi con số đó.
var record_enabled: bool = true
var _over_lock: float = 0.0
## Hàng đợi nổ. Dùng hàng đợi chứ không đệ quy: nổ dây giữa 40 con quái mà gọi
## đệ quy thì tràn stack, còn thứ tự đời cũng không kiểm soát được.
var _blasts: Array[Dictionary] = []
var _gen: int = 0          ## đời của vụ nổ đang xử lý, để con chết theo biết mình là đời sau
var _blasting: bool = false
var _cam_base: Vector3
var _shake_tween: Tween

@onready var hero: Hero = $Hero
@onready var mobs_root: Node3D = $Mobs
@onready var cam: Camera3D = $Camera3D
@onready var lbl_time: Label = %TimeLabel
@onready var lbl_hp: Label = %HpLabel
@onready var lbl_dur: Label = %DurLabel
@onready var lbl_kills: Label = %KillsLabel
@onready var dash_bar: ProgressBar = %DashBar
@onready var swing_bar: ProgressBar = %SwingBar
@onready var menu_panel: PanelContainer = %MenuPanel
@onready var lbl_best: Label = %BestLabel
@onready var result_panel: PanelContainer = %ResultPanel
@onready var lbl_result: Label = %ResultLabel
@onready var sfx_swing: AudioStreamPlayer = %SfxSwing
@onready var sfx_hit: AudioStreamPlayer = %SfxHit
@onready var sfx_kill: AudioStreamPlayer = %SfxKill
@onready var sfx_hurt: AudioStreamPlayer = %SfxHurt
@onready var sfx_dash: AudioStreamPlayer = %SfxDash
@onready var sfx_broke: AudioStreamPlayer = %SfxBroke
@onready var sfx_zap: AudioStreamPlayer = %SfxZap
@onready var sfx_boom: AudioStreamPlayer = %SfxBoom
@onready var sfx_end: AudioStreamPlayer = %SfxEnd
@onready var drone: AudioStreamPlayer = %Drone


func _ready() -> void:
	_cam_base = cam.position
	hero.swung.connect(_on_hero_swung)
	hero.dashed.connect(func() -> void: sfx_dash.play())

	_loop_drone()
	_load_best()

	# Ở màn chờ thì nhân vật đứng im, chỉ có đuốc cháy và tiếng hầm mộ.
	hero.set_physics_process(false)
	result_panel.hide()
	menu_panel.show()
	lbl_best.text = "Kỷ lục: hạ %d con" % best_kills if best_kills > 0 else "Chưa có kỷ lục"
	_update_hud()


## Vũ khí của vòng đấu này. Bản web cho người chơi tự rèn; ở đây là một lưỡi
## cân bằng đủ dùng: cứng vừa để chém chết mob, dẻo dai để trụ hết 22 giây.
func _make_weapon() -> Weapon:
	var w := Weapon.new()
	w.hard = 4
	w.tough = 6
	w.weight = 0
	w.rust = 6
	w.shock = 3
	w.setup()
	return w


func start_game() -> void:
	# queue_free() chỉ xoá ở cuối frame, mà chừng đó vẫn đủ để quái cũ đánh trúng
	# người chơi vừa hồi sinh. Tách khỏi cây scene ngay rồi mới cho xoá.
	for child in mobs_root.get_children():
		mobs_root.remove_child(child)
		child.queue_free()

	elapsed = 0.0
	kills = 0
	spawn_timer = 0.0
	_blasts.clear()
	_gen = 0
	hero.reset(_make_weapon())
	hero.set_physics_process(true)
	cam.position = _cam_base

	menu_panel.hide()
	result_panel.hide()
	state = State.PLAYING
	_update_hud()


func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		if _over_lock > 0.0:
			_over_lock -= delta
		return

	elapsed += delta

	# Nhịp spawn siết dần. Số liệu này được chốt bằng tests/balance.gd: phải đủ
	# dày để người chơi đứng im thì CHẾT, nếu không thì vũ khí tự chém đã thắng hộ.
	spawn_timer -= delta
	var gap := maxf(0.18, 0.66 - elapsed * 0.036)
	var alive := _alive_count()
	if spawn_timer <= 0.0 and alive < MAX_ALIVE:
		_spawn_mob()
		if elapsed > 3.0 and alive < MAX_ALIVE - 6 and randf() < 0.85:
			_spawn_mob()
		spawn_timer = gap

	if not _blasts.is_empty():
		_run_blasts()        # lưới an toàn nếu có kill xảy ra ngoài lúc chém

	_update_hud()

	if hero.hp <= 0:
		_finish(false)
	elif elapsed >= SURVIVE:
		_finish(true)


## Chỉ đếm quái còn sống — quái đang tan biến vẫn nằm trong cây scene nên
## nếu đếm cả thì nhịp spawn bị bóp lại oan.
func _alive_count() -> int:
	var n := 0
	for child in mobs_root.get_children():
		var m := child as Mob
		if m and not m.dead:
			n += 1
	return n


func _spawn_mob() -> void:
	var t: Dictionary = MOB_TYPES[randi() % MOB_TYPES.size()]
	var m: Mob = MobScene.instantiate()
	m.kind = t["kind"]
	m.hp = t["hp"]
	m.damage = t["dmg"]
	m.speed_pct = float(t["spd"]) * 5.5
	m.flies = t["flies"]
	m.wet = t.get("wet", false)
	m.target = hero

	# Spawn ở một cạnh bất kỳ, ngay ngoài vùng nhân vật đi được nhưng vẫn TRONG
	# tường (mặt trong tường ở 11.25) để quái không hiện ra xuyên qua đá.
	var edge := randi() % 4
	var along := randf_range(-FIELD_HALF, FIELD_HALF)
	var out := FIELD_HALF + 0.8
	match edge:
		0: m.position = Vector3(along, 0, -out)
		1: m.position = Vector3(out, 0, along)
		2: m.position = Vector3(along, 0, out)
		_: m.position = Vector3(-out, 0, along)

	m.reached_player.connect(_on_mob_reached)
	m.killed.connect(_on_mob_killed)
	mobs_root.add_child(m)


func _on_hero_swung(radius_m: float, damage: int) -> void:
	var near := 0
	var hits := 0
	var kills_before := kills
	var wet_hits: Array[Mob] = []
	for child in mobs_root.get_children():
		var m := child as Mob
		if m == null or m.dead:
			continue
		var d := m.global_position.distance_to(hero.global_position)
		if d < radius_m:
			m.take_hit(damage)
			hits += 1
			if m.wet:
				wet_hits.append(m)
		if d < radius_m + 6.0 * PCT:
			near += 1

	sfx_swing.play()
	if hits > 0:
		sfx_hit.play()
	var zaps := _chain_shock(wet_hits)   # có thể hạ thêm quái, nên đếm mạng sau nó
	if kills > kills_before:
		sfx_kill.play()

	# Hao độ bền theo SỐ quái đang kẹp quanh mình, chứ không phải một mức cố định.
	# Đây là thứ khiến việc di chuyển có ý nghĩa: cắm chân giữa đám đông thì lưỡi mẻ
	# rất nhanh, mẻ rồi thì sát thương sụp và người chơi bị vùi. Kéo quái ra mà chém
	# lẻ thì vũ khí trụ được hết vòng đấu.
	# Mỗi nhịp sét cũng ăn vào độ bền: phóng điện thì mạch trong lưỡi yếu đi.
	# Nhờ vậy sét không phải sát thương miễn phí — cắm chân giữa đám slime thì
	# ăn được chuỗi dài nhưng vũ khí đứt rất nhanh.
	var wear := 0.35 + 0.1 * near + 0.22 * zaps
	var was_broken := hero.weapon.broken
	hero.weapon.take_wear(wear)
	if hero.weapon.broken and not was_broken:
		hero.on_weapon_changed()
		sfx_broke.play()

	_run_blasts()


func _on_mob_reached(damage: int) -> void:
	hero.take_damage(damage)   # trừ máu VÀ giật người, hai thứ phải khớp nhau
	sfx_hurt.play()
	_shake()


## Sét lan giữa quái ƯỚT. Từ mỗi con ướt bị chém trúng, điện nhảy sang con ướt
## gần nhất chưa bị giật, tối đa chain_jumps() chặng, mỗi chặng yếu đi 30%.
## Con đã chết vẫn dẫn tiếp được — xác ướt thì vẫn là nước.
## Trả về số nhịp sét đã phóng, để bên gọi tính hao độ bền.
func _chain_shock(seeds: Array[Mob]) -> int:
	var jumps := hero.weapon.chain_jumps()
	if jumps <= 0 or seeds.is_empty():
		return 0

	var zapped := {}
	for sd in seeds:
		zapped[sd] = true

	var bolts: Array = []
	for sd in seeds:
		var cur: Mob = sd
		var dmg := hero.weapon.shock_damage()
		for _i in jumps:
			var nxt := _nearest_wet(cur, zapped)
			if nxt == null:
				break
			zapped[nxt] = true
			bolts.append([
				cur.global_position + Vector3.UP * 0.5,
				nxt.global_position + Vector3.UP * 0.5,
			])
			nxt.take_hit(dmg)
			cur = nxt
			dmg = maxi(1, roundi(dmg * 0.7))

	if bolts.is_empty():
		return 0
	# Camera trực giao nên hướng nhìn là hằng số, lấy từ trục Z của nó thay vì
	# tính theo từng vị trí.
	Lightning.strike(self, bolts, cam.global_transform.basis.z, SHOCK_TINT)
	sfx_zap.play()
	return bolts.size()


func _nearest_wet(from: Mob, zapped: Dictionary) -> Mob:
	var best: Mob = null
	var best_d := CHAIN_RANGE
	for child in mobs_root.get_children():
		var m := child as Mob
		if m == null or m.dead or not m.wet or zapped.has(m):
			continue
		var d := m.global_position.distance_to(from.global_position)
		if d < best_d:
			best_d = d
			best = m
	return best


func _on_mob_killed(at: Vector3) -> void:
	kills += 1
	# Xếp vào hàng đợi thay vì nổ ngay: hàm này bị gọi từ giữa vòng lặp quét quái,
	# nổ tại chỗ sẽ sửa danh sách đang duyệt.
	if _gen <= BLAST_MAX_GEN:
		_blasts.append({"at": at, "gen": _gen})


## Giải quyết hết chuỗi nổ đang chờ. Mỗi vụ nổ gây sát thương quanh nó; con nào
## chết theo sẽ tự xếp vào hàng đợi ở đời sau, cứ thế tới khi hết hoặc quá số đời.
func _run_blasts() -> void:
	if _blasting:
		return
	_blasting = true
	var self_dmg := 0
	while not _blasts.is_empty():
		var b: Dictionary = _blasts.pop_front()
		var gen: int = b["gen"]
		var at: Vector3 = b["at"]

		Boom.spawn(self, at, BOOM_TINT, BLAST_RADIUS)
		# tiếng nổ trầm dần theo đời, nghe ra được là một chuỗi chứ không phải một tiếng
		if not sfx_boom.playing:
			sfx_boom.pitch_scale = maxf(0.6, 1.0 - 0.13 * gen)
			sfx_boom.play()

		var dmg := maxi(1, roundi(BLAST_DAMAGE * pow(BLAST_FALLOFF, gen)))
		_gen = gen + 1        # con chết vì cú nổ này thuộc đời sau
		for child in mobs_root.get_children():
			var m := child as Mob
			if m == null or m.dead:
				continue
			if m.global_position.distance_to(at) < BLAST_RADIUS:
				m.take_hit(dmg)

		# Dồn lại rồi trừ một lần ở cuối, chứ trừ ngay từng vụ thì một chuỗi 40 vụ
		# là chết tức khắc và người chơi không hiểu vì sao.
		if not hero.is_invulnerable() \
				and hero.global_position.distance_to(at) < BLAST_RADIUS:
			self_dmg += maxi(1, ceili(dmg * BLAST_SELF))
	_gen = 0
	_blasting = false

	if self_dmg > 0:
		hero.take_damage(mini(self_dmg, BLAST_SELF_CAP))
		sfx_hurt.play()
		_shake()


## Rung camera. Luôn giật quanh _cam_base chứ không quanh vị trí hiện tại —
## nếu lấy vị trí hiện tại làm gốc thì bị đánh dồn sẽ khiến camera trôi dần đi.
func _shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	var jolt := Vector3(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12), 0.0)
	_shake_tween = create_tween()
	_shake_tween.tween_property(cam, "position", _cam_base + jolt, 0.04)
	_shake_tween.tween_property(cam, "position", _cam_base, 0.12)


func _update_hud() -> void:
	lbl_time.text = "⏳ %ds" % int(ceil(maxf(0.0, SURVIVE - elapsed)))
	lbl_hp.text = "❤️ %d" % maxi(0, hero.hp)
	lbl_dur.text = "🔧 %d/%d" % [int(round(hero.weapon.dur)), int(hero.weapon.max_dur)]
	lbl_kills.text = "💀 %d" % kills
	dash_bar.value = hero.dash_ready_ratio() * 100.0
	swing_bar.value = hero.swing_ready_ratio() * 100.0


func _finish(win: bool) -> void:
	state = State.OVER
	_over_lock = OVER_LOCK
	hero.set_physics_process(false)
	for child in mobs_root.get_children():
		child.set_physics_process(false)

	var record := ""
	if kills > best_kills:
		best_kills = kills
		_save_best()
		record = "\n★ KỶ LỤC MỚI"

	lbl_result.text = ("SỐNG SÓT VÒNG VÂY\nHạ %d con.%s" % [kills, record]) if win \
		else ("BỊ ĐÁNH GỤC\nTrụ %ds, hạ %d con.%s" % [int(elapsed), kills, record])
	lbl_result.text += "\n\nNhấn Enter để chơi lại"
	result_panel.show()

	sfx_end.stream = load("res://audio/win.wav") if win else load("res://audio/lose.wav")
	sfx_end.play()


func _unhandled_input(event: InputEvent) -> void:
	if state == State.PLAYING or _over_lock > 0.0:
		return
	# Space vừa là phím lăn né nên ở màn chờ chỉ nhận Enter, tránh bấm nhầm.
	if event.is_action_pressed(&"ui_accept") and not (event is InputEventKey and event.keycode == KEY_SPACE):
		start_game()


## Nền hầm mộ phát lặp liên tục. File WAV được sinh khớp đầu-cuối nên vòng lại không cộp.
func _loop_drone() -> void:
	var s := drone.stream as AudioStreamWAV
	if s:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	drone.play()


func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_kills = int(cfg.get_value("record", "best_kills", 0))


func _save_best() -> void:
	if not record_enabled:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("record", "best_kills", best_kills)
	cfg.save(SAVE_PATH)
