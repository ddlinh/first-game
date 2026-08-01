class_name Boom
extends Node3D

## Cú nổ khi quái bị hạ. Gồm hai phần:
##   - quả cầu sáng bung ra ở chỗ quái chết
##   - vòng sóng nằm trên mặt đất, lan tới ĐÚNG bán kính sát thương
##
## Vòng sóng là phần quan trọng về gameplay, không phải trang trí: nổ có lan sang
## quái xung quanh, nên người chơi phải thấy được nó với tới đâu mới học được cách
## xếp quái cho nổ dây.
##
## Tạo bằng code chứ không bằng .tscn vì material PHẢI riêng cho từng cú nổ — nếu
## lấy chung một StandardMaterial3D thì cú nổ sau sẽ tua lại độ mờ của cú trước và
## cả đám cùng nháy theo một nhịp. Mesh thì chia sẻ được vì không ai sửa nó.

const LIFE := 0.34
const CORE_FROM := 0.25
const CORE_TO := 1.5

static var _core_mesh: SphereMesh
static var _ring_mesh: TorusMesh


static func _shared_core() -> SphereMesh:
	if _core_mesh == null:
		_core_mesh = SphereMesh.new()
		_core_mesh.radius = 0.4
		_core_mesh.height = 0.8
		_core_mesh.radial_segments = 10
		_core_mesh.rings = 5
	return _core_mesh


## Vòng bán kính 1: phóng to bằng scale thành đúng bán kính nổ.
static func _shared_ring() -> TorusMesh:
	if _ring_mesh == null:
		_ring_mesh = TorusMesh.new()
		_ring_mesh.inner_radius = 0.9
		_ring_mesh.outer_radius = 1.0
	return _ring_mesh


static func _glow(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = tint
	return m


## Nổ ở vị trí thế giới `at`, vòng sóng lan tới `radius` mét. Tự dọn mình sau đó.
static func spawn(parent: Node3D, at: Vector3, tint: Color, radius: float) -> void:
	var b := Boom.new()
	b.position = Vector3(at.x, 0.0, at.z)
	parent.add_child(b)

	var core := MeshInstance3D.new()
	core.mesh = _shared_core()
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.position.y = maxf(at.y, 0.45)
	var core_mat := _glow(tint)
	core.material_override = core_mat
	core.scale = Vector3.ONE * CORE_FROM
	b.add_child(core)

	var ring := MeshInstance3D.new()
	ring.mesh = _shared_ring()
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position.y = 0.05
	var ring_mat := _glow(Color(tint.r, tint.g * 0.8, tint.b * 0.6, tint.a))
	ring.material_override = ring_mat
	ring.scale = Vector3(radius * 0.2, 1.0, radius * 0.2)
	b.add_child(ring)

	b._go(core, core_mat, ring, ring_mat, tint, radius)


func _go(core: MeshInstance3D, core_mat: StandardMaterial3D,
		ring: MeshInstance3D, ring_mat: StandardMaterial3D,
		tint: Color, radius: float) -> void:
	var clear := Color(tint.r, tint.g, tint.b, 0.0)
	var tw := create_tween().set_parallel(true)

	tw.tween_property(core, "scale", Vector3.ONE * CORE_TO, LIFE).set_ease(Tween.EASE_OUT)
	tw.tween_property(core_mat, "albedo_color", clear, LIFE * 0.8)

	# vòng sóng lan nhanh hơn quả cầu rồi tắt, đọc ra là một cú đẩy ra ngoài
	tw.tween_property(ring, "scale", Vector3(radius, 1.0, radius), LIFE * 0.7) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(ring_mat, "albedo_color", clear, LIFE)

	tw.chain().tween_callback(queue_free)
