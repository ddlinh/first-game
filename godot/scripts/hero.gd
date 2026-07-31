class_name Hero
extends Node3D

## Nhân vật: di chuyển bằng WASD/mũi tên, vũ khí TỰ chém mọi quái trong bán kính.
## Space/Shift để LĂN NÉ: lao nhanh một quãng và miễn thương trong lúc lăn.

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

var weapon: Weapon
var hp: int = MAX_HP

var _atk_timer: float = 0.0
var _flicker: float = randf() * TAU
var _dash_left: float = 0.0      ## thời gian còn lại của cú lăn
var _dash_cd: float = 0.0        ## thời gian còn lại tới khi lăn được tiếp
var _invuln: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO

@onready var sprite: Sprite3D = $Sprite
@onready var aura: MeshInstance3D = $Aura
@onready var torch: OmniLight3D = $Torch


func _ready() -> void:
	if weapon == null:
		weapon = Weapon.new()
		weapon.setup()
	_refresh_aura()


## Đặt lại về đầu vòng đấu. Gọi khi chơi lượt mới mà không nạp lại scene.
func reset(w: Weapon) -> void:
	weapon = w
	hp = MAX_HP
	global_position = Vector3.ZERO
	_atk_timer = 0.0
	_dash_left = 0.0
	_dash_cd = 0.0
	_invuln = 0.0
	sprite.rotation.z = 0.0
	sprite.scale = Vector3.ONE
	sprite.modulate = Color.WHITE
	_refresh_aura()


func is_invulnerable() -> bool:
	return _invuln > 0.0


## 0.0 = vừa lăn xong, 1.0 = lăn được ngay. Dùng cho thanh hồi chiêu trên HUD.
func dash_ready_ratio() -> float:
	return 1.0 if _dash_cd <= 0.0 else 1.0 - _dash_cd / DASH_CD


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
		_dash_dir = dir if dir.length_squared() > 0.0 else _facing(cam)
		_dash_left = DASH_TIME
		_dash_cd = DASH_CD
		_invuln = DASH_TIME + DASH_GRACE
		dir = _dash_dir
		dashed.emit()
		_play_dash()

	# --- di chuyển ---
	if dir.length_squared() > 0.0:
		var speed := weapon.speed_pct() * PCT
		if _dash_left > 0.0:
			speed *= DASH_MULT
		global_position += dir * speed * delta
		global_position.x = clampf(global_position.x, -FIELD_HALF, FIELD_HALF)
		global_position.z = clampf(global_position.z, -FIELD_HALF, FIELD_HALF)

		# lật sprite theo hướng màn hình
		if cam:
			var side := dir.dot(cam.global_transform.basis.x)
			if absf(side) > 0.01:
				sprite.flip_h = side < 0.0

	# --- vũ khí tự chém ---
	_atk_timer -= delta
	if _atk_timer <= 0.0:
		_atk_timer = weapon.swing_interval()
		swung.emit(weapon.swing_radius_pct() * PCT, weapon.swing_damage())
		_play_swing()

	# --- đuốc nhấp nháy: đây là thứ bản HTML không làm được ---
	_flicker += delta * 9.0
	torch.light_energy = 2.4 + sin(_flicker) * 0.25 + sin(_flicker * 2.7) * 0.15

	# lúc miễn thương thì nhân vật ngả xanh để người chơi thấy mình đang an toàn
	if _invuln > 0.0:
		sprite.modulate = Color(0.6, 0.85, 1.4)
	elif sprite.modulate != Color.WHITE:
		sprite.modulate = Color.WHITE


## Hướng nhân vật đang nhìn, suy ra từ sprite đang lật bên nào.
func _facing(cam: Camera3D) -> Vector3:
	if cam == null:
		return Vector3.FORWARD
	var right := cam.global_transform.basis.x
	right.y = 0.0
	return (-right if sprite.flip_h else right).normalized()


func _play_swing() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "rotation:z", deg_to_rad(-10.0), 0.06)
	tw.tween_property(sprite, "rotation:z", 0.0, 0.14)

	var mat := aura.get_surface_override_material(0)
	if mat:
		var tw2 := create_tween()
		tw2.tween_property(mat, "emission_energy_multiplier", 3.5, 0.05)
		tw2.tween_property(mat, "emission_energy_multiplier", 0.6, 0.28)


## Lăn: bóp dẹt sprite rồi bung lại, nhìn ra được là đang lăn người.
func _play_dash() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector3(1.25, 0.7, 1.0), 0.07)
	tw.tween_property(sprite, "scale", Vector3.ONE, 0.16).set_ease(Tween.EASE_OUT)


## Vòng sáng dưới chân = bán kính chém. Đổi theo độ cứng của vũ khí.
func _refresh_aura() -> void:
	var r := weapon.swing_radius_pct() * PCT
	var mesh := aura.mesh as TorusMesh
	if mesh:
		mesh.outer_radius = r
		mesh.inner_radius = maxf(0.05, r - 0.08)


func on_weapon_changed() -> void:
	_refresh_aura()
