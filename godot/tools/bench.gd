extends Node
func _ready() -> void:
	var N := 400000
	var prims := [Art.e(60, 60, 30, 22), Art.c(40, 30, 18), Art.rr(70, 80, 20, 14, 6)]
	var im := Art.img(128, 128)
	var t := Time.get_ticks_msec()
	var acc := 0.0
	for i in range(N):
		acc += Art.sd_union(prims, Vector2(float(i % 128), float((i / 128) % 128)))
	print("sd_union x%d      : %d ms" % [N, Time.get_ticks_msec() - t])
	t = Time.get_ticks_msec()
	for i in range(N):
		Art.blend(im, i % 128, (i / 128) % 128, Color.RED, 0.5)
	print("blend    x%d      : %d ms" % [N, Time.get_ticks_msec() - t])
	t = Time.get_ticks_msec()
	for i in range(N):
		acc += Art.hash01(i)
	print("hash01   x%d      : %d ms  (loop floor)" % [N, Time.get_ticks_msec() - t])
	print(acc)
	get_tree().quit()
