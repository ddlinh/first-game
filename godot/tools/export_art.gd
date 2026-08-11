extends Node
## One-shot: freeze the code-drawn catalogue to PNG files under res://art/ so the
## game can render purely from files. Writes pristine copies to art/_templates/
## (always) and to art/ (only if absent, never clobbering hand-edited art).
func _ready() -> void:
	# Force a fresh bake of the whole catalogue so NEW code-drawn keys are generated
	# even when the runtime normally renders straight from res://art (no bake).
	Assets._bake_all()
	var keys: Array = Assets._tex.keys()
	keys.sort()
	DirAccess.make_dir_recursive_absolute("res://art/_templates")
	var manifest: Array[String] = []
	for k in keys:
		var tex: Texture2D = Assets._tex[k]
		var im: Image = tex.get_image()
		im.save_png("res://art/_templates/%s.png" % k)
		if not FileAccess.file_exists("res://art/%s.png" % k):
			im.save_png("res://art/%s.png" % k)
		manifest.append("%s|%d|%d" % [k, im.get_width(), im.get_height()])
	# The manifest file lists every key the game needs; the loader checks res://art
	# against it to decide whether it can render purely from files.
	var names: Array[String] = []
	for k in keys:
		names.append(str(k))
	var f := FileAccess.open("res://art/_manifest.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(names))
	print("MANIFEST_BEGIN")
	for line in manifest:
		print(line)
	print("MANIFEST_END total=", keys.size())
	get_tree().quit()
