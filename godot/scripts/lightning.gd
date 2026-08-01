class_name Lightning
extends MeshInstance3D

## Tia sét gấp khúc nối các con quái ướt bị giật điện.
##
## Vì sao dựng hình bằng ImmediateMesh chứ không dùng đường kẻ: đường kẻ 3D của
## Godot luôn dày đúng 1 pixel nên ở cỡ này gần như không thấy. Ở đây mỗi khúc
## được bồi thành một dải tam giác, bề rộng nằm theo phương vuông góc với hướng
## nhìn — nên tia luôn xoè mặt về phía camera thay vì mỏng dính.

const WIDTH := 0.07       ## nửa bề rộng dải, mét
const JAG := 0.3          ## độ lệch ngang lớn nhất của khúc gấp
const SEGS := 7           ## số khúc mỗi tia
const LIFE := 0.17


## `pairs` là mảng các cặp [Vector3, Vector3] theo toạ độ thế giới.
static func strike(parent: Node3D, pairs: Array, to_cam: Vector3, tint: Color) -> void:
	if pairs.is_empty():
		return
	var l := Lightning.new()
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = tint
	l.material_override = mat

	parent.add_child(l)
	l.global_position = Vector3.ZERO      # dùng thẳng toạ độ thế giới cho đỉnh
	l._build(pairs, to_cam.normalized())
	l._fade(mat, tint)


func _build(pairs: Array, to_cam: Vector3) -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for pair in pairs:
		_one_bolt(im, pair[0], pair[1], to_cam)
	im.surface_end()
	mesh = im


func _one_bolt(im: ImmediateMesh, a: Vector3, b: Vector3, to_cam: Vector3) -> void:
	var dir := b - a
	if dir.length_squared() < 0.0001:
		return
	# phương lệch của khúc gấp cũng phải nằm trong mặt phẳng nhìn, không thì
	# zigzag bị nén mất khi chiếu lên màn hình
	var perp := dir.cross(to_cam)
	if perp.length_squared() < 0.000001:
		return
	perp = perp.normalized()

	var pts: Array[Vector3] = [a]
	for i in range(1, SEGS):
		var t := float(i) / float(SEGS)
		var amp := JAG * sin(t * PI)          # bằng 0 ở hai đầu, phình ở giữa
		pts.append(a.lerp(b, t) + perp * randf_range(-amp, amp))
	pts.append(b)

	for i in pts.size() - 1:
		var p := pts[i]
		var q := pts[i + 1]
		var side := (q - p).cross(to_cam)
		if side.length_squared() < 0.000001:
			continue
		side = side.normalized() * WIDTH
		im.surface_add_vertex(p - side)
		im.surface_add_vertex(p + side)
		im.surface_add_vertex(q + side)
		im.surface_add_vertex(p - side)
		im.surface_add_vertex(q + side)
		im.surface_add_vertex(q - side)


func _fade(mat: StandardMaterial3D, tint: Color) -> void:
	var tw := create_tween()
	tw.tween_property(mat, "albedo_color", Color(tint.r, tint.g, tint.b, 0.0), LIFE)
	tw.tween_callback(queue_free)
