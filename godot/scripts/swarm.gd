extends Node3D

## Map vây: sống sót hết giờ. Quái spawn ở rìa sân, càng lâu càng dày.
## Toàn bộ số liệu lấy nguyên từ bản HTML để so sánh được hai bản.

const PCT := 0.2
const SURVIVE := 22.0
const MAX_ALIVE := 24
const FIELD_HALF := 10.0

const MOB_TYPES := [
	{"kind": "bat",   "hp": 5,  "dmg": 3, "spd": 1.6, "flies": true},
	{"kind": "slime", "hp": 10, "dmg": 2, "spd": 0.9, "flies": false},
	{"kind": "rat",   "hp": 4,  "dmg": 2, "spd": 2.1, "flies": false},
]

var MobScene := preload("res://scenes/Mob.tscn")

var elapsed: float = 0.0
var kills: int = 0
var spawn_timer: float = 0.0
var running: bool = true

@onready var hero: Hero = $Hero
@onready var mobs_root: Node3D = $Mobs
@onready var lbl_time: Label = %TimeLabel
@onready var lbl_hp: Label = %HpLabel
@onready var lbl_dur: Label = %DurLabel
@onready var lbl_kills: Label = %KillsLabel
@onready var result_panel: PanelContainer = %ResultPanel
@onready var lbl_result: Label = %ResultLabel


func _ready() -> void:
	var w := Weapon.new()
	w.hard = 4
	w.tough = 6
	w.weight = 0
	w.rust = 6
	w.setup()
	hero.weapon = w
	hero.swung.connect(_on_hero_swung)
	result_panel.hide()
	_update_hud()


func _physics_process(delta: float) -> void:
	if not running:
		return

	elapsed += delta

	# nhịp spawn siết dần: 0.95 -> 0.35 giây
	spawn_timer -= delta
	var gap := maxf(0.35, 0.95 - elapsed * 0.022)
	var alive := mobs_root.get_child_count()
	if spawn_timer <= 0.0 and alive < MAX_ALIVE:
		_spawn_mob()
		if elapsed > 6.0 and alive < MAX_ALIVE - 6 and randf() < 0.7:
			_spawn_mob()
		spawn_timer = gap

	_update_hud()

	if hero.hp <= 0:
		_finish(false)
	elif elapsed >= SURVIVE:
		_finish(true)


func _spawn_mob() -> void:
	var t: Dictionary = MOB_TYPES[randi() % MOB_TYPES.size()]
	var m: Mob = MobScene.instantiate()
	m.kind = t["kind"]
	m.hp = t["hp"]
	m.damage = t["dmg"]
	m.speed_pct = float(t["spd"]) * 5.5
	m.flies = t["flies"]
	m.target = hero

	# spawn ở một cạnh bất kỳ, ngay ngoài rìa sân
	var edge := randi() % 4
	var along := randf_range(-FIELD_HALF, FIELD_HALF)
	var out := FIELD_HALF + 1.5
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
	for child in mobs_root.get_children():
		var m := child as Mob
		if m == null or m.dead:
			continue
		var d := m.global_position.distance_to(hero.global_position)
		if d < radius_m:
			m.take_hit(damage)
		if d < radius_m + 6.0 * PCT:
			near += 1

	# hao độ bền: chém giữa đám đông thì mẻ nhanh hơn
	var wear := 0.5
	if near > 4:
		wear += 0.4
	hero.weapon.take_wear(wear)
	if hero.weapon.broken:
		hero.on_weapon_changed()


func _on_mob_reached(damage: int) -> void:
	hero.hp -= damage
	_shake()


func _on_mob_killed() -> void:
	kills += 1


func _shake() -> void:
	var cam := $Camera3D as Camera3D
	var base: Vector3 = cam.position
	var tw := create_tween()
	tw.tween_property(cam, "position", base + Vector3(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12), 0), 0.04)
	tw.tween_property(cam, "position", base, 0.12)


func _update_hud() -> void:
	lbl_time.text = "⏳ %ds" % int(ceil(maxf(0.0, SURVIVE - elapsed)))
	lbl_hp.text = "❤️ %d" % maxi(0, hero.hp)
	lbl_dur.text = "🔧 %d/%d" % [int(round(hero.weapon.dur)), int(hero.weapon.max_dur)]
	lbl_kills.text = "💀 %d" % kills


func _finish(win: bool) -> void:
	running = false
	set_physics_process(false)
	hero.set_physics_process(false)
	for child in mobs_root.get_children():
		child.set_physics_process(false)
	lbl_result.text = ("SỐNG SÓT VÒNG VÂY\nHạ %d con." % kills) if win \
		else ("BỊ ĐÁNH GỤC\nTrụ %ds, hạ %d con." % [int(elapsed), kills])
	result_panel.show()


func _unhandled_input(event: InputEvent) -> void:
	if not running and event.is_action_pressed(&"ui_accept"):
		get_tree().reload_current_scene()
