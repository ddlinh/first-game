extends SceneTree
## Bake sprite PIXEL-ART ra PNG. Art định nghĩa bằng LƯỚI KÝ TỰ + bảng màu (sửa tay,
## re-bake được — đây là "nguồn" của sprite sheet). Chạy:
##   godot --headless --path godot --script proto2/bake_sprites.gd
## Ra res://proto2/sprites/*.png. Thân khuẩn để THANG XÁM (tint theo việc bằng modulate);
## phage / rival / giáo T6SS bake sẵn màu.

const OUT := "res://proto2/sprites"

# Bảng màu chung cho các sprite vẽ bằng lưới ký tự.
const PAL := {
	".": Color(0, 0, 0, 0),
	# thân khuẩn — THANG XÁM để tint: k=viền, s=bóng, b=thân, h=sáng
	"k": Color(0.15, 0.15, 0.17), "s": Color(0.60, 0.60, 0.63),
	"b": Color(0.82, 0.82, 0.85), "h": Color(1.0, 1.0, 1.0),
	# phage (hồng)
	"P": Color(0.60, 0.20, 0.36), "p": Color(0.95, 0.44, 0.64),
	"t": Color(0.78, 0.26, 0.44), "g": Color(0.55, 0.18, 0.33),
	"c": Color(0.40, 0.86, 0.70),
	# rival (đối thủ — cam/đỏ, gai T6SS)
	"R": Color(0.34, 0.10, 0.06), "r": Color(0.88, 0.38, 0.22),
	"o": Color(0.98, 0.62, 0.30), "e": Color(0.10, 0.03, 0.02),
	# giáo T6SS (kim loại + ngạnh đỏ)
	"M": Color(0.90, 0.93, 0.97), "m": Color(0.66, 0.70, 0.78),
	"n": Color(0.42, 0.46, 0.54), "x": Color(0.92, 0.30, 0.24),
}

# Phage: đầu icosahedral + đuôi + chân + mũi tiêm DNA (cyan).
const PHAGE := [
	".....PP.....",
	"....PppP....",
	"...PppppP...",
	"..PppppppP..",
	"...PppppP...",
	"....PppP....",
	".....PP.....",
	".....tt.....",
	"....gttg....",
	"...g.tt.g...",
	"..g..tt..g..",
	".g...cc...g.",
	".....cc.....",
]

# Rival: cầu khuẩn địch có GAI bốn phía (gợi T6SS) — bake sẵn màu cam/đỏ.
const RIVAL := [
	".....RR.....",
	".....oo.....",
	"...RooooR...",
	"..RooooooR..",
	"..oorrrroo..",
	"RRorrrrrroRR",
	"RRorrrrrroRR",
	"..oorrrroo..",
	"..RooooooR..",
	"...RooooR...",
	".....oo.....",
	".....RR.....",
]

# Giáo T6SS: cán kim loại + đầu ngạnh đỏ, hướng sang PHẢI (view sẽ xoay).
const SPEAR := [
	"n.................",
	"nmmmmmmmmmmmm.x...",
	"nMMMMMMMMMMMMxxxxx",
	"nmmmmmmmmmmmm.x...",
	"n.................",
]


func _init() -> void:
	var d := DirAccess.open("res://proto2")
	if not d.dir_exists("sprites"):
		d.make_dir("sprites")
	# thân chung (dự phòng)
	_bake_cell("cell_coccus", 14, PAL["s"])
	_bake_rod("cell_rod", 22, 12)
	# ── thân RIÊNG TỪNG CHỦNG (hình thái thật) ──
	_bake_cell("cell_staph", 13, Color(0.62, 0.50, 0.16))   # cầu khuẩn, bóng ánh VÀNG (aureus)
	_bake_rod("cell_ecoli", 20, 9)                          # trực khuẩn THON, có tiên mao
	_bake_rod("cell_proteus", 30, 8)                        # tế bào SWARMER kéo dài
	_bake_rod("cell_bacillus", 20, 11)                      # trực khuẩn mập, mọc chuỗi + bào tử
	_save("spore", _bake_spore())                           # bào tử: oval SÁNG (không tint)
	_save("phage", _from_grid(PHAGE))
	_save("rival", _from_grid(RIVAL))
	_save("spear", _from_grid(SPEAR))
	print("OK — bake sprite xong vào ", OUT)
	quit()


func _blank(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func _from_grid(rows: Array) -> Image:
	var h := rows.size()
	var w: int = rows[0].length()
	var img := _blank(w, h)
	for y in h:
		var row: String = rows[y]
		for x in w:
			var ch := row[x] if x < row.length() else "."
			img.set_pixel(x, y, PAL.get(ch, PAL["."]))
	return img


# Cầu khuẩn tròn, thang xám: viền + thân + sáng trên + bóng dưới (để tint). `shadow` cho
# phép nhuốm bóng theo sắc tố chủng (vd Staph ánh vàng) mà vẫn tint được theo việc.
func _bake_cell(name: String, sz: int, shadow: Color) -> void:
	var img := _blank(sz, sz)
	var c := (sz - 1) * 0.5
	var r := c - 0.5
	for y in sz:
		for x in sz:
			var dx := x - c
			var dy := y - c
			var dist := sqrt(dx * dx + dy * dy)
			if dist > r:
				continue
			var col: Color
			if dist > r - 1.0:
				col = PAL["k"]                      # viền
			elif dy < -r * 0.35:
				col = PAL["h"]                      # đỉnh sáng
			elif dy > r * 0.45:
				col = shadow                        # đáy bóng (sắc tố chủng)
			else:
				col = PAL["b"]
			img.set_pixel(x, y, col)
	_save(name, img)


# Bào tử nội sinh (endospore): oval SÁNG, phase-bright — bake màu sẵn, KHÔNG tint theo việc.
func _bake_spore() -> Image:
	var w := 8
	var h := 6
	var img := _blank(w, h)
	var cx := (w - 1) * 0.5
	var cy := (h - 1) * 0.5
	for y in h:
		for x in w:
			var dx := (x - cx) / (cx + 0.2)
			var dy := (y - cy) / (cy + 0.2)
			var d := dx * dx + dy * dy
			if d > 1.0:
				continue
			if d > 0.6:
				img.set_pixel(x, y, Color(0.70, 0.85, 0.72))     # viền xanh nhạt
			else:
				img.set_pixel(x, y, Color(0.96, 1.0, 0.94))      # lõi sáng
	return img


# Trực khuẩn (rod) nằm ngang: viên nang thang xám để tint, đầu bên phải là "trước".
func _bake_rod(name: String, w: int, h: int) -> void:
	var img := _blank(w, h)
	var cy := (h - 1) * 0.5
	var ry := cy - 0.5
	var pad := ry                                   # bo tròn hai đầu
	for y in h:
		for x in w:
			var dy := y - cy
			var dx := 0.0
			if x < pad:
				dx = pad - x
			elif x > w - 1 - pad:
				dx = x - (w - 1 - pad)
			var dist := sqrt(dx * dx + dy * dy)
			if dist > ry:
				continue
			var col: Color
			if dist > ry - 1.0:
				col = PAL["k"]
			elif dy < -ry * 0.35:
				col = PAL["h"]
			elif dy > ry * 0.45:
				col = PAL["s"]
			else:
				col = PAL["b"]
			img.set_pixel(x, y, col)
	_save(name, img)


func _save(name: String, img: Image) -> void:
	img.save_png("%s/%s.png" % [OUT, name])
