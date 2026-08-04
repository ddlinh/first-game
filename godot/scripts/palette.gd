class_name Palette
extends RefCounted

## Bảng màu của cả game, gom về một chỗ.
##
## Trước đây màu nằm rải ba nơi — mặc định trong dish.gdshader, dict COL của
## agents.gd, dict SPECIES_COLOR của hud.gd — nên đổi tone là ba lần sửa và chỉ cần
## quên một chỗ là chấm trong HUD lệch màu với quân trên đĩa.
##
## Mỗi chủng có HAI màu, cố ý:
##   · field  — tô ô trên mặt đĩa, chiếm phần lớn diện tích nên phải trầm.
##   · sprite — chibi và chấm trong HUD, phải sáng hơn nền đĩa mới nổi lên được.
## Trộn hai vai này vào một màu thì hoặc mặt đĩa chói, hoặc chibi chìm nghỉm.

enum Tone { DIM_LAB, MICROSCOPE, INK }

## Đổi ở đây là đổi cả game. tests/capture.gd đặt lại giá trị này trước khi dựng
## scene để chụp ảnh so sánh từng tone.
static var tone := Tone.MICROSCOPE

const TONES := {
	## Phòng tối: xanh lạnh, xám tro, ba chủng là ba viên đá quý trầm.
	Tone.DIM_LAB: {
		"field": {
			Sim.TOXIC: Color(0.44, 0.22, 0.68),
			Sim.SENSITIVE: Color(0.50, 0.37, 0.10),
			Sim.RESISTANT: Color(0.16, 0.33, 0.60),
		},
		"sprite": {
			Sim.TOXIC: Color(0.62, 0.40, 0.88),
			Sim.SENSITIVE: Color(0.80, 0.64, 0.28),
			Sim.RESISTANT: Color(0.36, 0.58, 0.90),
		},
		"agar": Color(0.035, 0.055, 0.085),
		"barrier": Color(0.26, 0.28, 0.33),
		"backdrop": Color(0.012, 0.018, 0.032),
		"glass": Color(0.09, 0.11, 0.16),
		"glass_inner": Color(0.05, 0.065, 0.10),
		"dish": Color(0.028, 0.042, 0.068),
		"rim": Color(0.42, 0.56, 0.78, 0.20),
		"panel": Color(0.048, 0.066, 0.108, 0.90),
		"toxin_sac": Color(0.36, 0.72, 0.44, 0.85),
		"overlay": Color(0.062, 0.080, 0.128, 0.98),
	},
	## Kính hiển vi: nền ngả ô liu như ảnh soi qua kính, chủng ngả đất nung.
	##
	## Kháng độc ở đây từng là xanh mòng két đúng nghĩa (0.13, 0.36, 0.44) — hợp
	## không khí nhưng nằm ngay cạnh sắc lục của nền, nên lúc nó chỉ còn dăm phần
	## trăm quân thì gần như biến mất vào mặt thạch. Kéo hẳn về phía lam, và rút bớt
	## lục trong màu nền, để hai thứ không còn tranh nhau một góc bánh xe màu.
	Tone.MICROSCOPE: {
		"field": {
			Sim.TOXIC: Color(0.40, 0.20, 0.50),
			Sim.SENSITIVE: Color(0.52, 0.40, 0.14),
			Sim.RESISTANT: Color(0.12, 0.34, 0.52),
		},
		"sprite": {
			Sim.TOXIC: Color(0.60, 0.40, 0.74),
			Sim.SENSITIVE: Color(0.82, 0.68, 0.34),
			Sim.RESISTANT: Color(0.30, 0.60, 0.82),
		},
		"agar": Color(0.050, 0.052, 0.040),
		"barrier": Color(0.28, 0.28, 0.24),
		"backdrop": Color(0.022, 0.028, 0.022),
		"glass": Color(0.10, 0.12, 0.10),
		"glass_inner": Color(0.06, 0.072, 0.058),
		"dish": Color(0.036, 0.048, 0.038),
		"rim": Color(0.56, 0.62, 0.44, 0.20),
		"panel": Color(0.055, 0.068, 0.055, 0.90),
		"toxin_sac": Color(0.44, 0.66, 0.34, 0.85),
		"overlay": Color(0.070, 0.085, 0.068, 0.98),
	},
	## Mực: tối nhất, gần như đơn sắc. Chỉ ba chủng có màu, mọi thứ khác là than chì.
	Tone.INK: {
		"field": {
			Sim.TOXIC: Color(0.36, 0.17, 0.55),
			Sim.SENSITIVE: Color(0.44, 0.33, 0.09),
			Sim.RESISTANT: Color(0.11, 0.26, 0.50),
		},
		"sprite": {
			Sim.TOXIC: Color(0.56, 0.34, 0.82),
			Sim.SENSITIVE: Color(0.74, 0.58, 0.24),
			Sim.RESISTANT: Color(0.30, 0.50, 0.84),
		},
		"agar": Color(0.022, 0.026, 0.036),
		"barrier": Color(0.20, 0.21, 0.24),
		"backdrop": Color(0.008, 0.010, 0.016),
		"glass": Color(0.062, 0.070, 0.090),
		"glass_inner": Color(0.032, 0.038, 0.052),
		"dish": Color(0.018, 0.022, 0.032),
		"rim": Color(0.34, 0.42, 0.58, 0.20),
		"panel": Color(0.030, 0.038, 0.056, 0.92),
		"toxin_sac": Color(0.28, 0.60, 0.38, 0.85),
		"overlay": Color(0.042, 0.052, 0.074, 0.98),
	},
}


static func of(key: String) -> Color:
	return TONES[tone][key]


## Màu tô ô trên mặt đĩa.
static func field(species: int) -> Color:
	return TONES[tone]["field"][species]


## Màu chibi và chấm trong HUD — luôn sáng hơn bản field của cùng chủng.
static func sprite(species: int) -> Color:
	return TONES[tone]["sprite"][species]
