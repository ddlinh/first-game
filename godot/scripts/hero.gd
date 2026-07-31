class_name Hero
extends Node3D

## Nhân vật: di chuyển bằng WASD/mũi tên, vũ khí TỰ chém mọi quái trong bán kính.

signal swung(radius_m: float, damage: int)

const PCT := 0.2           ## 1% sân ảo = 0.2 m
const FIELD_HALF := 9.2    ## nửa cạnh sân, giữ nhân vật trong khung

var weapon: Weapon
var hp: int = 30

var _atk_timer: float = 0.0
var _flicker: float = randf() * TAU

@onready var sprite: Sprite3D = $Sprite
@onready var aura: MeshInstance3D = $Aura
@onready var torch: OmniLight3D = $Torch


func _ready() -> void:
	if weapon == null:
		weapon = Weapon.new()
		weapon.setup()
	_refresh_aura()


func _physics_process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()

	# --- hướng nhập liệu, tính theo MÀN HÌNH chứ không theo trục thế giới ---
	# Camera xoay 45 độ nên nếu dùng thẳng trục Z thì bấm W sẽ đi chéo.
	var input := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed(&"ui_up"):
		input.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed(&"ui_down"):
		input.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed(&"ui_left"):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed(&"ui_right"):
		input.x += 1.0

	if input.length_squared() > 0.0:
		input = input.normalized()
		if cam:
			input = input.rotated(Vector3.UP, cam.global_rotation.y)
		global_position += input * weapon.speed_pct() * PCT * delta
		global_position.x = clampf(global_position.x, -FIELD_HALF, FIELD_HALF)
		global_position.z = clampf(global_position.z, -FIELD_HALF, FIELD_HALF)

		# lật sprite theo hướng màn hình
		if cam:
			var side := input.dot(cam.global_transform.basis.x)
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


func _play_swing() -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "rotation:z", deg_to_rad(-10.0), 0.06)
	tw.tween_property(sprite, "rotation:z", 0.0, 0.14)

	var mat := aura.get_surface_override_material(0)
	if mat:
		var tw2 := create_tween()
		tw2.tween_property(mat, "emission_energy_multiplier", 3.5, 0.05)
		tw2.tween_property(mat, "emission_energy_multiplier", 0.6, 0.28)


## Vòng sáng dưới chân = bán kính chém. Đổi theo độ cứng của vũ khí.
func _refresh_aura() -> void:
	var r := weapon.swing_radius_pct() * PCT
	var mesh := aura.mesh as TorusMesh
	if mesh:
		mesh.outer_radius = r
		mesh.inner_radius = maxf(0.05, r - 0.08)


func on_weapon_changed() -> void:
	_refresh_aura()
