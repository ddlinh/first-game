class_name Run
extends RefCounted

## Một lượt roguelite: 6–8 đĩa ngẫu nhiên, thắng đĩa nào thì bốc 1 trong 3 thẻ
## nâng cấp (mục 6 tài liệu). Toàn bộ sức mạnh người chơi gom vào `kit` để Colony
## chỉ phải đọc một chỗ và test dựng lại đúng cấu hình bằng vài dòng.

const STAGES_MIN := 6
const STAGES_MAX := 8

## Thẻ nâng cấp. `apply` nhận kit và sửa tại chỗ; `usable` để thẻ đã lấy rồi thì
## không hiện lại (chỉ cần cho thẻ bật/tắt một lần).
const CARDS := [
	{
		"id": "spore",
		"name": "Bào tử dày",
		"desc": "Mỗi nhát cấy phủ rộng thêm 3 ô.",
	},
	{
		"id": "metabolism",
		"name": "Trao đổi chất nhanh",
		"desc": "Hồi lượt cấy nhanh hơn 28%.",
	},
	{
		"id": "toxin",
		"name": "Độc tố cô đặc",
		"desc": "Chủng Tiết độc sinh sản nhanh hơn 30%.",
	},
	{
		"id": "vial",
		"name": "Thêm ống nghiệm",
		"desc": "Tích trữ thêm 1 lượt cấy.",
	},
	{
		"id": "paddle",
		"name": "Cánh khuấy lớn",
		"desc": "Thanh khuấy hồi nhanh hơn hẳn.",
	},
	{
		"id": "antibiotic",
		"name": "Kháng sinh phổ hẹp",
		"desc": "Nhát cấy quét sạch Kháng độc ngay tại tâm.",
		"once": true,
	},
]

var stages: Array[Dictionary] = []
var index := 0
var kit := default_kit()
var taken: Array[String] = []
var rng := RandomNumberGenerator.new()


static func default_kit() -> Dictionary:
	return {
		"plant_radius": 7,
		"plant_cooldown": 5.0,
		"max_charges": 1,
		"stir_recharge": 0.22,
		"repro_boost": 1.0,
		"antibiotic": false,
	}


func _init(run_seed: int = 0) -> void:
	rng.seed = run_seed if run_seed != 0 else randi()
	var count := rng.randi_range(STAGES_MIN, STAGES_MAX)
	for i in count:
		var s := Stages.roll(i, rng)
		# Bốc lại nếu trùng mục tiêu đĩa trước. Không chặn thì có lượt ra ba đĩa
		# Hộ tống liên tiếp, đọc bảng nào cũng thấy y hệt nhau và lượt chơi nhạt hẳn.
		for _retry in 4:
			if stages.is_empty() or s["goal"] != stages[-1]["goal"]:
				break
			s = Stages.roll(i, rng)
		stages.append(s)


func current() -> Dictionary:
	return stages[mini(index, stages.size() - 1)]


func is_last() -> bool:
	return index >= stages.size() - 1


## Bốc 3 thẻ khác nhau, bỏ qua thẻ một-lần đã lấy.
func draw_cards() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for c in CARDS:
		if c.get("once", false) and taken.has(c["id"]):
			continue
		pool.append(c)
	var out: Array[Dictionary] = []
	while out.size() < 3 and pool.size() > 0:
		out.append(pool.pop_at(rng.randi() % pool.size()))
	return out


func take_card(card: Dictionary) -> void:
	taken.append(card["id"])
	match card["id"]:
		"spore": kit["plant_radius"] += 3
		"metabolism": kit["plant_cooldown"] *= 0.72
		"toxin": kit["repro_boost"] += 0.3
		"vial": kit["max_charges"] += 1
		"paddle": kit["stir_recharge"] += 0.18
		"antibiotic": kit["antibiotic"] = true
