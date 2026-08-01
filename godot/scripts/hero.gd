class_name Hero
extends Node3D

## Nhân vật: di chuyển bằng WASD/mũi tên, CHUỘT TRÁI để chém, Space/Shift để LĂN NÉ
## (lao nhanh một quãng và miễn thương trong lúc lăn).
##
## Chém là chủ động, không tự động. Nhịp vũ khí giờ là hồi chiêu chứ không phải
## đồng hồ tự bắn — nghĩa là người chơi tự quyết lúc nào tiêu độ bền, nên việc
## gom quái lại rồi chém một nhát trở thành lựa chọn thật.
##
## Nhân vật là một RIG gồm 5 bộ phận rời (hai chân, thân, đầu, tay kiếm, tay đuốc),
## mỗi cái treo dưới một Node3D làm khớp. Không có frame vẽ sẵn nào: mọi tư thế
## đều tính bằng hàm liên tục trong _anim(), nên cử động mượt ở mọi tốc độ khung
## hình và các động tác chồng lên nhau được (vừa đi vừa chém, vừa lăn vừa ăn đòn).
##
## Ba tầng, tầng sau đè tầng trước:
##   1. nền   — đứng thở hoặc đi, nội suy qua nhau bằng _gait chứ không nhảy trạng thái
##   2. chồng — chém (tay kiếm), ăn đòn (ngửa người)
##   3. đè    — lăn, chiếm toàn quyền cả rig

signal swung(radius_m: float, damage: int)
signal dashed

const PCT := 0.2           ## 1% sân ảo = 0.2 m
const FIELD_HALF := 9.2    ## nửa cạnh sân, giữ nhân vật trong khung

const MAX_HP := 30

## Lăn né: nhanh gấp 3.4 lần, kéo 0.2 giây, hồi chiêu 1.1 giây.
## Miễn thương phủ hết cú lăn cộng một chút đuôi cho dễ né.
const DASH_MULT := 3.4
const DASH_TIME := 0.2
const DASH_CD := 1.1
const DASH_GRACE := 0.09

## Chiều cao gốc rig = GIỮA người, không phải bàn chân. Cú lăn cuộn quanh gốc này
## nên phải đặt ở giữa, để bàn chân thì thành lộn kiểu bánh xe.
const RIG_Y := 0.9

## Thời lượng từng động tác (giây).
const ROLL_ANIM := 0.3     ## khớp cửa sổ miễn thương (0.2 + 0.09)
const ATK_ANIM := 0.42     ## ngắn hơn nhịp chém 0.55 để kịp về tư thế nghỉ
const HURT_ANIM := 0.26

## Góc nghỉ của tay kiếm: chỉ chếch xuống dưới bên phải.
const REST_SWORD := -40.0

const RING_TINT := Color(1.0, 0.88, 0.6)
const TINT_SAFE := Color(0.6, 0.85, 1.4)    ## đang miễn thương
const TINT_HURT := Color(1.6, 0.55, 0.55)   ## vừa ăn đòn

var weapon: Weapon
var hp: int = MAX_HP

var _atk_cd: float = 0.0         ## còn bao lâu nữa mới chém lại được
var _flicker: float = randf() * TAU
var _dash_left: float = 0.0      ## thời gian còn lại của cú lăn
var _dash_cd: float = 0.0        ## thời gian còn lại tới khi lăn được tiếp
var _invuln: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO
var _ring_tween: Tween

# --- trạng thái animation ---
var _moving: bool = false
var _gait: float = 0.0           ## 0 = đứng, 1 = đi. Nội suy nên không nhảy tư thế.
var _walk_t: float = 0.0
var _idle_t: float = randf() * TAU
var _facing: float = 1.0         ## +1 nhìn phải màn hình, -1 nhìn trái (lật bằng scale.x)
var _atk_phase: float = -1.0     ## -1 = không chém, còn lại 0..1
var _roll_phase: float = -1.0
var _hurt_phase: float = -1.0
var _tint: Color = Color.WHITE
var _head_y: float = 0.0         ## chiều cao gốc của đầu, để thu vào khi lăn

@onready var aura: MeshInstance3D = $Aura
@onready var ring: MeshInstance3D = $SwingRing
@onready var torch: OmniLight3D = $Torch

@onready var rig: Node3D = $Rig
@onready var hip_back: Node3D = $Rig/HipBack
@onready var hip_front: Node3D = $Rig/HipFront
@onready var torso: Sprite3D = $Rig/Torso
@onready var head: Sprite3D = $Rig/Head
@onready var sh_sword: Node3D = $Rig/ShoulderSword
@onready var sh_torch: Node3D = $Rig/ShoulderTorch
@onready var arm_sword: Sprite3D = $Rig/ShoulderSword/ArmSword
@onready var arm_torch: Sprite3D = $Rig/ShoulderTorch/ArmTorch
@onready var leg_back: Sprite3D = $Rig/HipBack/LegBack
@onready var leg_front: Sprite3D = $Rig/HipFront/LegFront

var _parts: Array[Sprite3D] = []


func _ready() -> void:
	_parts = [torso, head, arm_sword, arm_torch, leg_back, leg_front]
	_head_y = head.position.y
	if weapon == null:
		weapon = Weapon.new()
		weapon.setup()
	_refresh_aura()


## Đặt lại về đầu vòng đấu. Gọi khi chơi lượt mới mà không nạp lại scene.
func reset(w: Weapon) -> void:
	weapon = w
	hp = MAX_HP
	global_position = Vector3.ZERO
	_atk_cd = 0.0
	_dash_left = 0.0
	_dash_cd = 0.0
	_invuln = 0.0
	_moving = false
	_gait = 0.0
	_walk_t = 0.0
	_atk_phase = -1.0
	_roll_phase = -1.0
	_hurt_phase = -1.0
	_facing = 1.0
	rig.rotation.z = 0.0
	rig.position.y = RIG_Y
	rig.scale = Vector3.ONE
	_hide_ring()
	_refresh_aura()


func is_invulnerable() -> bool:
	return _invuln > 0.0


## 0.0 = vừa lăn xong, 1.0 = lăn được ngay. Dùng cho thanh hồi chiêu trên HUD.
func dash_ready_ratio() -> float:
	return 1.0 if _dash_cd <= 0.0 else 1.0 - _dash_cd / DASH_CD


## 0.0 = vừa chém, 1.0 = chém được ngay. Dùng cho thanh hồi chiêu trên HUD.
func swing_ready_ratio() -> float:
	var gap := weapon.swing_interval()
	return 1.0 if _atk_cd <= 0.0 or gap <= 0.0 else 1.0 - _atk_cd / gap


## Một nhát chém. Quay mặt về phía con trỏ trước khi vung, để nhát chém trông như
## nhắm vào chỗ người chơi đang chỉ (vùng sát thương vẫn là vòng quanh chân).
func _swing(cam: Camera3D) -> void:
	_atk_cd = weapon.swing_interval()
	var aim := _aim_dir(cam)
	if cam and aim != Vector3.ZERO:
		var side := aim.dot(cam.global_transform.basis.x)
		if absf(side) > 0.01:
			_facing = 1.0 if side > 0.0 else -1.0
	_atk_phase = 0.0
	swung.emit(weapon.swing_radius_pct() * PCT, weapon.swing_damage())
	_play_ring()


## Hướng từ nhân vật tới con trỏ chuột, chiếu xuống mặt phẳng ngang ngang thân.
func _aim_dir(cam: Camera3D) -> Vector3:
	if cam == null:
		return Vector3.ZERO
	var mouse := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mouse)
	var ray := cam.project_ray_normal(mouse)
	if absf(ray.y) < 0.0001:
		return Vector3.ZERO
	var hit := from + ray * ((global_position.y + RIG_Y - from.y) / ray.y)
	var to := hit - global_position
	to.y = 0.0
	return to.normalized() if to.length_squared() > 0.0001 else Vector3.ZERO


## Ăn đòn: trừ máu và giật người. Đi qua đây thay vì sửa hp trực tiếp từ ngoài,
## để cái giật người luôn khớp với lúc mất máu.
func take_damage(amount: int) -> void:
	hp -= amount
	_hurt_phase = 0.0


## Hướng nhập liệu tính theo MÀN HÌNH chứ không theo trục thế giới.
## Camera xoay 45 độ nên nếu dùng thẳng trục Z thì bấm W sẽ đi chéo.
func _input_dir(cam: Camera3D) -> Vector3:
	var input := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed(&"ui_up"):
		input.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed(&"ui_down"):
		input.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed(&"ui_left"):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed(&"ui_right"):
		input.x += 1.0

	if input.length_squared() == 0.0:
		return Vector3.ZERO
	input = input.normalized()
	if cam:
		input = input.rotated(Vector3.UP, cam.global_rotation.y)
	return input


func _physics_process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()

	_dash_cd = maxf(0.0, _dash_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)

	var dir := _input_dir(cam)

	# --- lăn né ---
	if _dash_left > 0.0:
		_dash_left -= delta
		dir = _dash_dir          # đang lăn thì khoá hướng, đổi phím giữa cú lăn không lái được
	elif _dash_cd <= 0.0 and (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT)):
		# đứng yên mà bấm lăn thì lăn theo hướng đang nhìn, cho khỏi mất chiêu
		_dash_dir = dir if dir.length_squared() > 0.0 else _face_dir(cam)
		_dash_left = DASH_TIME
		_dash_cd = DASH_CD
		_invuln = DASH_TIME + DASH_GRACE
		_roll_phase = 0.0
		dir = _dash_dir
		dashed.emit()

	# --- di chuyển ---
	_moving = dir.length_squared() > 0.0
	if _moving:
		var speed := weapon.speed_pct() * PCT
		if _dash_left > 0.0:
			speed *= DASH_MULT
		global_position += dir * speed * delta
		global_position.x = clampf(global_position.x, -FIELD_HALF, FIELD_HALF)
		global_position.z = clampf(global_position.z, -FIELD_HALF, FIELD_HALF)

		if cam:
			var side := dir.dot(cam.global_transform.basis.x)
			if absf(side) > 0.01:
				_facing = 1.0 if side > 0.0 else -1.0

	# --- chém: chỉ khi giữ/bấm chuột trái, và không chém giữa lúc đang lăn ---
	_atk_cd = maxf(0.0, _atk_cd - delta)
	if _atk_cd <= 0.0 and _dash_left <= 0.0 \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_swing(cam)


## Animation chạy trong _process chứ không phải _physics_process: nó thuần hình
## ảnh, và ở _process thì mượt theo tốc độ vẽ thật kể cả khi khác 60 Hz. Nhờ vậy
## nhân vật vẫn thở ở màn chờ, lúc _physics_process đã bị tắt.
func _process(delta: float) -> void:
	_anim(delta)


func _anim(delta: float) -> void:
	# đuốc nhấp nháy — thứ bản HTML không làm được
	_flicker += delta * 9.0
	torch.light_energy = 2.4 + sin(_flicker) * 0.25 + sin(_flicker * 2.7) * 0.15

	_apply_tint()

	# --- tầng 3: lăn chiếm toàn quyền, khỏi phải hoà với tư thế nền ---
	if _roll_phase >= 0.0:
		_roll_phase += delta / ROLL_ANIM
		if _roll_phase < 1.0:
			_pose_roll(_roll_phase)
			return
		_roll_phase = -1.0

	# --- tầng 1: nền, đứng <-> đi nội suy qua nhau ---
	_gait = move_toward(_gait, 1.0 if _moving else 0.0, delta * 7.0)
	_walk_t += delta * 10.0
	_idle_t += delta * 2.4

	var s := sin(_walk_t)                 # so le hai chân
	var step := absf(sin(_walk_t))        # nảy người mỗi bước
	var breathe := sin(_idle_t)

	var leg := deg_to_rad(30.0) * s * _gait
	hip_back.rotation.z = -leg
	hip_front.rotation.z = leg

	rig.rotation.z = 0.0
	head.position.y = _head_y
	rig.position.y = RIG_Y + lerpf(breathe * 0.018, step * 0.05, _gait)
	rig.scale = Vector3(_facing, 1.0, 1.0)

	var lean := deg_to_rad(lerpf(1.2 * breathe, -4.5 * s, _gait))
	torso.rotation.z = lean
	head.rotation.z = -lean * 0.6
	# tay đuốc đánh ngược pha với chân cho ra nhịp đi
	sh_torch.rotation.z = deg_to_rad(lerpf(3.5 * breathe, 11.0 * -s, _gait))

	var sword := REST_SWORD + lerpf(2.0 * breathe, -10.0 * s, _gait)

	# --- tầng 2: chồng lên nền ---
	if _atk_phase >= 0.0:
		_atk_phase += delta / ATK_ANIM
		if _atk_phase < 1.0:
			sword = _sword_arc(_atk_phase)
			torso.rotation.z += deg_to_rad(_atk_twist(_atk_phase))
		else:
			_atk_phase = -1.0

	if _hurt_phase >= 0.0:
		_hurt_phase += delta / HURT_ANIM
		if _hurt_phase < 1.0:
			var k := 1.0 - _hurt_phase        # giật mạnh nhất ngay lúc trúng rồi dịu đi
			torso.rotation.z += deg_to_rad(11.0 * k)
			head.rotation.z += deg_to_rad(14.0 * k)
			rig.position.y -= 0.03 * k
		else:
			_hurt_phase = -1.0

	sh_sword.rotation.z = deg_to_rad(sword)


## Cung chém: lấy đà ra sau, quét xuống rất nhanh, rồi thu về tư thế nghỉ.
## Chia ba đoạn vì một đường cong đơn không ra được cảm giác "nặng rồi dứt khoát".
func _sword_arc(p: float) -> float:
	const BACK := 55.0        ## đỉnh lấy đà, vung ngược lên sau vai
	const THROUGH := -95.0    ## điểm cuối nhát quét, thấp hơn cả tư thế nghỉ
	if p < 0.25:
		# lấy đà: chậm dần khi tới đỉnh
		return lerpf(REST_SWORD, BACK, ease(p / 0.25, 0.4))
	if p < 0.45:
		# quét: nhanh dần, đây là đoạn gây sát thương
		return lerpf(BACK, THROUGH, ease((p - 0.25) / 0.2, 2.2))
	# thu về
	return lerpf(THROUGH, REST_SWORD, ease((p - 0.45) / 0.55, 0.5))


## Thân xoay theo nhát chém cho có lực, ngược pha với tay.
func _atk_twist(p: float) -> float:
	if p < 0.25:
		return lerpf(0.0, -5.0, p / 0.25)
	if p < 0.45:
		return lerpf(-5.0, 7.0, (p - 0.25) / 0.2)
	return lerpf(7.0, 0.0, (p - 0.45) / 0.55)


## Lăn: cuộn trọn một vòng quanh giữa người, thu mình lại ở giữa cú lăn.
## Không nhân hướng vào góc quay — rig đã bị lật bằng scale.x nên vòng cuộn tự
## đảo chiều theo hướng nhìn.
func _pose_roll(p: float) -> void:
	var tuck := sin(p * PI)           # 0 ở hai đầu, thu mình nhất ở giữa
	rig.rotation.z = -TAU * p
	rig.scale = Vector3(_facing * (1.0 - 0.12 * tuck), 1.0 - 0.2 * tuck, 1.0)
	rig.position.y = RIG_Y - 0.1 * tuck

	# Hai chân gập CÙNG chiều về phía trước bụng, không xoè ngược nhau — xoè ra
	# thì lúc lộn người trông như rời rạc chứ không phải một khối cuộn.
	hip_back.rotation.z = deg_to_rad(88.0 * tuck)
	hip_front.rotation.z = deg_to_rad(104.0 * tuck)
	torso.rotation.z = deg_to_rad(-10.0 * tuck)
	head.rotation.z = deg_to_rad(-14.0 * tuck)
	# Đầu cách tâm rig 0.79 m nên khi cuộn nó vẽ một vòng rất rộng và trông như
	# rụng khỏi cổ. Kéo hẳn nó thu vào thân để cả người thành một khối tròn.
	head.position.y = _head_y - 0.26 * tuck
	# Thanh kiếm dài 1.1 m nên phải quặp hẳn vào dọc thân, không thì nó chìa ra
	# như cái càng suốt cú lăn.
	sh_sword.rotation.z = deg_to_rad(REST_SWORD - 125.0 * tuck)
	sh_torch.rotation.z = deg_to_rad(62.0 * tuck)


func _apply_tint() -> void:
	var want := Color.WHITE
	if _hurt_phase >= 0.0:
		want = TINT_HURT
	elif _invuln > 0.0:
		want = TINT_SAFE
	if want == _tint:
		return
	_tint = want
	for part in _parts:
		part.modulate = want


## Hướng nhân vật đang nhìn, theo trục phải của camera.
func _face_dir(cam: Camera3D) -> Vector3:
	if cam == null:
		return Vector3.FORWARD
	var right := cam.global_transform.basis.x
	right.y = 0.0
	return (right * _facing).normalized()


## Vòng sóng bung ra tới đúng tầm chém, để người chơi đọc được mình quét tới đâu.
func _play_ring() -> void:
	var mat := ring.get_surface_override_material(0) as StandardMaterial3D
	if mat == null:
		return
	if _ring_tween and _ring_tween.is_valid():
		_ring_tween.kill()

	var r := weapon.swing_radius_pct() * PCT
	ring.scale = Vector3(r * 0.32, 1.0, r * 0.32)
	mat.albedo_color = Color(RING_TINT.r, RING_TINT.g, RING_TINT.b, 0.9)

	_ring_tween = create_tween().set_parallel(true)
	_ring_tween.tween_property(ring, "scale", Vector3(r * 1.03, 1.0, r * 1.03), 0.24) \
		.set_ease(Tween.EASE_OUT)
	_ring_tween.tween_property(mat, "albedo_color",
		Color(RING_TINT.r, RING_TINT.g, RING_TINT.b, 0.0), 0.24)

	var mat_aura := aura.get_surface_override_material(0)
	if mat_aura:
		var tw := create_tween()
		tw.tween_property(mat_aura, "emission_energy_multiplier", 3.5, 0.05)
		tw.tween_property(mat_aura, "emission_energy_multiplier", 0.6, 0.28)


func _hide_ring() -> void:
	if _ring_tween and _ring_tween.is_valid():
		_ring_tween.kill()
	var mat := ring.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(RING_TINT.r, RING_TINT.g, RING_TINT.b, 0.0)


## Vòng sáng dưới chân = bán kính chém. Đổi theo độ cứng của vũ khí.
func _refresh_aura() -> void:
	var r := weapon.swing_radius_pct() * PCT
	var mesh := aura.mesh as TorusMesh
	if mesh:
		mesh.outer_radius = r
		mesh.inner_radius = maxf(0.05, r - 0.08)


func on_weapon_changed() -> void:
	_refresh_aura()
