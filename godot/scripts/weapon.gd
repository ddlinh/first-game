class_name Weapon
extends Resource

## Chỉ số vũ khí.
## Mọi công thức giữ NGUYÊN đơn vị của bản HTML (%/giây trên sân ảo 100x100)
## để hai bản đối chiếu được với nhau. Việc quy đổi sang mét nằm ở Const.PCT.

@export var hard: int = 4
@export var tough: int = 6
@export var weight: int = 0
@export var rust: int = 6
## Điện tích của lưỡi. Chém trúng quái ƯỚT thì sét nhảy sang các con ướt gần đó.
## Đây là chỉ số riêng của bản Godot, bản web không có.
@export var shock: int = 3

var max_dur: float = 26.0
var dur: float = 26.0
var broken: bool = false


func setup() -> void:
	max_dur = 8.0 + maxi(0, tough) * 3.0
	dur = max_dur
	broken = false


# --- công thức gốc từ bản web (xem thu-lua-roguelite.html ở commit cb5e5d9) ---

## Tốc độ chạy, đơn vị %/giây. Nhẹ = nhanh.
func speed_pct() -> float:
	return 26.0 - weight * 1.3

## Nhịp giữa hai nhát chém, giây. Nhẹ = chém dồn.
func swing_interval() -> float:
	return maxf(0.25, 0.55 + weight * 0.04)

## Bán kính chém quanh nhân vật, đơn vị %. Cứng = quét rộng.
func swing_radius_pct() -> float:
	return 10.0 + maxi(0, hard) * 0.7

## Sát thương mỗi nhát.
func swing_damage() -> int:
	return maxi(1, roundi(hard * 0.9))

## Sát thương mỗi nhịp sét nhảy. Yếu hơn một nhát chém vì nó đánh diện rộng.
func shock_damage() -> int:
	return maxi(1, roundi(shock * 0.9))

## Sét nhảy được mấy chặng. Điện càng mạnh thì chuỗi càng dài.
func chain_jumps() -> int:
	return clampi(shock, 0, 4)

## Cứng cao mà dẻo dai thấp -> lưỡi giòn, mẻ nhanh hơn 1.5 lần.
func is_brittle() -> bool:
	return hard - tough > 3


func take_wear(amount: float) -> void:
	if is_brittle():
		amount *= 1.5
	dur -= amount
	if dur <= 0.0:
		dur = 0.0
		if not broken:
			broken = true
			hard = maxi(1, roundi(hard * 0.4))
			# Lưỡi mẻ thì mạch điện cũng đứt theo. Cộng dồn với sát thương sụp,
			# đây là thứ khiến việc để vũ khí mẻ trở thành án tử.
			shock = shock / 2
