extends SceneTree
## Chẩn đoán sprite (soi phần THÂN của rig): có vẽ ra pixel nào không, và
## rotation có tác dụng không?
##
## Đo ở màn chờ nên cảnh tĩnh hoàn toàn (không có quái, nhân vật đứng im) — hai
## ảnh khác nhau thì chắc chắn do thuộc tính mình đổi, không phải do game động.
##
## Phép đo then chốt: ẩn hẳn sprite rồi so với ảnh gốc. Y HỆT nghĩa là sprite
## vốn đã chẳng vẽ gì. LƯU Ý: đừng gán lại sp.rotation ở bước đo đầu tiên —
## làm vậy là xoá mất chính cấu hình đang cần kiểm tra.

var swarm: Swarm
var frames := 0
var shots: Array[PackedByteArray] = []
var labels: Array[String] = []
var stage := 0
var pending := false
var done := false


func _initialize() -> void:
	swarm = load("res://scenes/Swarm.tscn").instantiate()
	swarm.record_enabled = false
	root.add_child(swarm)


func _grab(label: String) -> void:
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	shots.append(img.get_data())
	labels.append(label)
	pending = false
	stage += 1


func _shoot(label: String) -> void:
	pending = true
	RenderingServer.frame_post_draw.connect(_grab.bind(label), CONNECT_ONE_SHOT)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 40 or pending:
		return done

	var sp: Sprite3D = swarm.hero.torso    # nhân vật giờ là rig, soi phần thân

	match stage:
		0:
			var b := sp.global_transform.basis
			print("billboard=%d  visible=%s  pixel_size=%.3f  alpha_cut=%d  double_sided=%s"
				% [sp.billboard, sp.visible, sp.pixel_size, sp.alpha_cut, sp.double_sided])
			print("texture=%s  size=%s" % [
				sp.texture.resource_path if sp.texture else "<null>",
				sp.texture.get_size() if sp.texture else "-"])
			print("euler(deg)=(%.1f, %.1f, %.1f)" % [
				rad_to_deg(sp.rotation.x), rad_to_deg(sp.rotation.y), rad_to_deg(sp.rotation.z)])
			print("truc +Z cua sprite (phai chi ve camera) = (%.3f, %.3f, %.3f)"
				% [b.z.x, b.z.y, b.z.z])
			var to_cam := (swarm.cam.global_position - sp.global_position).normalized()
			print("huong tu sprite den camera            = (%.3f, %.3f, %.3f)"
				% [to_cam.x, to_cam.y, to_cam.z])
			print("dot(+Z, den_camera) = %.3f   (1 = quay dung mat vao camera)"
				% b.z.normalized().dot(to_cam))
			print("AABB = %s" % sp.get_aabb())
			_shoot("gốc")
		1:
			sp.visible = false
			_shoot("ẩn hẳn sprite")
		2:
			sp.visible = true
			sp.rotation.z = deg_to_rad(40.0)
			_shoot("xoay z=40°")
		3:
			_report()
			done = true

	return done


func _report() -> void:
	print("")
	for i in range(1, shots.size()):
		print("%-18s so với gốc: %s" % [
			labels[i],
			"Y HỆT" if shots[i] == shots[0] else "KHÁC"])
	if shots.size() > 1 and shots[1] == shots[0]:
		print("=> KẾT LUẬN: sprite không vẽ ra pixel nào. Nó đang vô hình.")
	else:
		print("=> KẾT LUẬN: sprite có vẽ ra hình.")


func _finalize() -> void:
	if swarm:
		swarm.free()
