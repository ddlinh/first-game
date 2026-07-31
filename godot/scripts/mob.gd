class_name Mob
extends Node3D

## Quái nhỏ: đuổi thẳng về phía nhân vật, chạm được thì gây damage rồi biến mất.
## Không dùng physics body — khoảng cách tính tay, đúng như bản HTML, nhẹ và dễ đọc.

signal reached_player(damage: int)
signal killed

const PCT := 0.2          ## 1% sân ảo = 0.2 m (sân 20x20 m)
const TOUCH_PCT := 4.5    ## chạm nhân vật ở khoảng cách này (%)

const TEXTURES := {
	"bat": "res://art/bat.svg",
	"slime": "res://art/slime.svg",
	"rat": "res://art/rat.svg",
}

var kind: String = "bat"
var hp: int = 5
var damage: int = 3
var speed_pct: float = 1.6 * 5.5   ## %/giây — hệ số 5.5 lấy từ bản HTML
var flies: bool = false
var dead: bool = false

var target: Hero

var _wob: float = randf() * TAU
var _flash: float = 0.0
var _base_y: float = 0.0

@onready var sprite: Sprite3D = $Sprite


func _ready() -> void:
	sprite.texture = load(TEXTURES.get(kind, TEXTURES["bat"]))
	_base_y = 1.1 if flies else 0.45
	sprite.position.y = _base_y


func _physics_process(delta: float) -> void:
	if dead or target == null:
		return

	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			sprite.modulate = Color.WHITE

	var to := target.global_position - global_position
	to.y = 0.0
	var d := to.length()

	if d > 0.001:
		global_position += to / d * speed_pct * PCT * delta
		# quay mặt về phía nhân vật (dùng trục phải của camera để đúng hướng màn hình)
		var cam := get_viewport().get_camera_3d()
		if cam:
			sprite.flip_h = to.dot(cam.global_transform.basis.x) < 0.0

	if flies:
		_wob += delta * 6.0
		sprite.position.y = _base_y + sin(_wob) * 0.15

	# Chạm được nhưng nhân vật đang lăn né thì đòn trượt: quái không chết, cứ đuổi tiếp.
	if d < TOUCH_PCT * PCT and not target.is_invulnerable():
		reached_player.emit(damage)
		_die(false)


## Nhận sát thương từ nhát chém. Trả về true nếu chết vì đòn này.
func take_hit(amount: int) -> bool:
	if dead:
		return false
	hp -= amount
	_flash = 0.12
	sprite.modulate = Color(3.0, 3.0, 3.0)
	if hp <= 0:
		_die(true)
		return true
	return false


func _die(by_weapon: bool) -> void:
	if dead:
		return
	dead = true
	if by_weapon:
		killed.emit()
	set_physics_process(false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "scale", Vector3.ZERO, 0.22).set_ease(Tween.EASE_IN)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(queue_free)
