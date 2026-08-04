class_name Sim
extends RefCounted

## Lưới ô tự hành — toàn bộ trận đánh nằm ở đây, không một dòng nào biết tới màn hình.
## Nhờ vậy tests/ chạy headless đo cân bằng được mà khỏi mở cửa sổ, và tầng vẽ 2.5D
## chỉ đọc chứ không bao giờ ghi ngược vào lưới (luồng dữ liệu một chiều, mục 3 tài liệu).
##
## Luật gốc là mô hình colicin của E. coli: ba chủng khắc chế vòng tròn, mỗi nhịp bốc
## ngẫu nhiên một cặp ô kề nhau rồi xử lý. Chính kiểu cập nhật BẤT ĐỒNG BỘ này đẻ ra
## sóng xoắn ốc — cập nhật đồng bộ cả lưới một lượt thì hoa văn tan thành nhiễu.
##
## Hai chỗ có thật trong sinh học, không phải bịa cho vui:
##
## · VÒNG KHẮC CHẾ — Kerr, Riley, Feldman & Bohannan, "Local dispersal promotes
##   biodiversity in a real-life game of rock–paper–scissors", Nature 418:171–174
##   (2002). Ba chủng E. coli thật: C tiết colicin diệt S; S nhanh hơn R vì đột biến
##   kháng thuốc làm R vận chuyển dinh dưỡng kém đi; R nhanh hơn C vì không phải trả
##   giá sản xuất độc tố. Đúng ba mũi của TOXIC / SENSITIVE / RESISTANT ở đây.
##
## · KHUẤY ĐĨA GIẾT ĐA DẠNG — cũng chính bài đó: nuôi trên mặt thạch (phát tán cục
##   bộ) thì cả ba chủng cùng sống, nuôi trong bình lắc (trộn đều) thì đa dạng sập
##   nhanh chóng. Cơ chế "khuấy đĩa" của game là kết quả trung tâm của bài báo, chứ
##   không phải một nút bấm nghĩ ra để cho vui.
##
## · SÓNG XOẮN ỐC & TRẦN LINH ĐỘNG — Reichenbach, Mobilia & Frey, "Mobility promotes
##   and jeopardizes biodiversity in rock–paper–scissors games", Nature 448:1046–1049
##   (2007). Trên lưới, độ linh động vừa phải sinh sóng xoắn ốc, quá ngưỡng thì một
##   chủng chết. tests/diag_pattern.gd đo lại được đúng hiện tượng đó (xem `mobility`).
##
## Còn MÁU (HP_TABLE) thì KHÔNG có gốc sinh học nào — vi khuẩn thật không có thanh
## máu. Đó là thứ tài liệu thiết kế thêm vào để chủng Kháng độc "dày" hơn khi chơi.

const EMPTY := 0
const TOXIC := 1       ## Tiết độc — chủng của người chơi
const SENSITIVE := 2   ## Nhạy cảm
const RESISTANT := 3   ## Kháng độc
const WALL := 4        ## vách nhựa / ngoài rìa đĩa, không ai chiếm được

const SPECIES := [TOXIC, SENSITIVE, RESISTANT]

## Bảng số liệu bám đúng mục 2 tài liệu thiết kế.
const SPEED := [0.0, 0.62, 1.16, 0.55]
const MAX_HP := [0, 2, 1, 5]
const REPRO := [0.0, 1.0, 3.0, 1.6]

## Bản Packed của hai bảng trên. Array hằng của GDScript trả về Variant mỗi lần
## đọc; trong vòng lặp nóng chạy nửa triệu nhịp mỗi giây thì khác biệt thấy rõ.
## Con mồi của từng chủng: 1 diệt 2, 2 đè 3, 3 chặn 1.
static var PREY := PackedByteArray([0, SENSITIVE, RESISTANT, TOXIC, 0])
static var HP_TABLE := PackedByteArray([0, 2, 1, 5, 0])

## Quy đổi bảng số liệu sang xác suất mỗi nhịp. Bốn nhánh: đổi chỗ / sinh sản /
## tấn công / đứng yên, cộng lại phải ≤ 1.
##
## Bài học xương máu khi cân bằng bản này: KHÔNG được để nhánh tấn công là phần
## dư còn lại như bản web. Nhạy cảm sinh sản gấp ba nên phần dư của nó tụt về 0,
## Kháng độc thành bất khả xâm phạm, vòng khắc chế đứt và ván nào người chơi cũng
## bị nghiền trong bảy giây. Ba nhánh giờ đều có xác suất riêng, phần dư là đứng yên.
const SWAP_BASE := 0.09
const REPRO_BASE := 0.28
const KILL_BASE := 0.10

## Mặc định của `mobility` — xem chú thích của biến đó ở dưới.
const MOBILITY := 1.8

## Chênh lệch trong bảng thiết kế quá gắt để dùng thẳng làm hệ số nhân (Nhạy cảm
## sinh sản gấp 3 lần Tiết độc thì không mô hình nào giữ nổi thế cân bằng). Nén
## chúng lại quanh mốc 1.0: vẫn cảm nhận được chủng nào nhanh chủng nào chậm,
## nhưng cả ba cùng sống được trên một đĩa.
const STAT_STRENGTH := 0.35

## Xác suất ra đòn tỉ lệ THUẬN với máu con mồi, nên tốc độ dọn sạch hiệu dụng
## (xác suất chia cho máu) của cả ba chủng bằng đúng KILL_BASE. Vòng khắc chế nhờ
## đó trung tính, không ai tự thắng.
##
## Đây là chỗ đã tự bắn vào chân một lần: bù một phần (mũ 0.6) nghe có vẻ tinh tế
## hơn, nhưng nó cho Tiết độc tốc độ dọn 0.19 so với 0.10 của Nhạy cảm — tức chủng
## người chơi tự leo lên 65% trong 60 giây mà không cần đụng chuột, mục tiêu
## "giữ 45%" thắng bằng cách ngồi yên. tests/diag_opening.gd đo ra đúng con số đó.
const HP_COMPENSATION := 1.0

## Khuấy đĩa: trộn mạnh, gần như ngừng sinh sản. Phá cấu trúc xoắn ốc trong vài giây.
const STIR_SWAP := 0.75
const STIR_REPRO := 0.05

## Số tương tác mỗi giây tính trên một ô. Bản web chạy 0.55*N mỗi khung ở 30fps
## nên mỗi ô được đụng tới ~16.5 lần/giây — giữ đúng con số đó để hoa văn chạy
## cùng nhịp dù lưới to nhỏ khác nhau.
const CHURN := 16.5

var size: int          ## cạnh lưới
var cells: int         ## size * size
var grid: PackedByteArray
var hp: PackedByteArray
var counts := PackedInt32Array([0, 0, 0, 0, 0])   ## đếm sẵn theo chủng, kể cả WALL
var playable: int      ## số ô không phải vách — mẫu số của mọi phép tính phần trăm

var stirring := false

## Bảng hướng 16 ô. Biến thể "dòng chảy vi lưu" chỉ việc nhồi thêm hướng nam vào
## bảng này, vòng lặp nóng không phải đẻ thêm một lần random nào.
var _dirs := PackedByteArray()

## Ngưỡng cộng dồn của ba nhánh, tra thẳng bằng mã chủng trong vòng lặp nóng.
var _swap := PackedFloat32Array([0, 0, 0, 0, 0])
var _swap_repro := PackedFloat32Array([0, 0, 0, 0, 0])
var _swap_repro_kill := PackedFloat32Array([0, 0, 0, 0, 0])
var _stir_swap := PackedFloat32Array([0, 0, 0, 0, 0])
var _stir_swap_repro := PackedFloat32Array([0, 0, 0, 0, 0])
var _stir_swap_repro_kill := PackedFloat32Array([0, 0, 0, 0, 0])

## Nhân với xác suất sinh sản của riêng chủng người chơi (thẻ nâng cấp roguelite).
var repro_boost := 1.0

## Độ linh động của vi khuẩn trên thạch (nhân vào xác suất đổi chỗ của mọi chủng).
## Đây là núm quyết định KÍCH THƯỚC hoa văn — và là thứ suýt làm hỏng cả game:
## bê nguyên con số của bản web chạy lưới 100 sang lưới 180 thì mặt đĩa ra một bãi
## nhiễu hạt mịn, không có lấy một vòng xoắn nào, tức mất đúng thứ mà tên game dựa vào.
##
## tests/diag_pattern.gd quét dải này (mảng màu trung bình @60s, còn đủ 3 chủng @90s):
##   ×1.0 → 19 px, 8/8  ·  ×1.4 → 22 px, 8/8  ·  ×1.8 → 26 px, 8/8  ·  ×2.2 → 29 px, 7/8
## Càng lên cao mảng màu càng to, nhưng qua ×1.8 là bắt đầu có ván mất chủng — hiệu
## ứng bình lắc kinh điển: xoáy nở to gần bằng cái đĩa rồi một chủng chết hẳn.
## Ba px đổi lấy một ván hỏng trên tám là món hời ngược, nên dừng ở ×1.8.
var mobility := MOBILITY
var _leftover := 0.0   ## phần lẻ số nhịp giữa hai khung hình, cộng dồn cho khỏi trôi


func _init(grid_size: int = 180) -> void:
	size = grid_size
	cells = size * size
	grid = PackedByteArray()
	grid.resize(cells)
	hp = PackedByteArray()
	hp.resize(cells)
	playable = cells
	set_flow(0.0)
	rebuild_rates()
	recount()


## Nén một chỉ số về quanh mốc 1.0 so với trung bình ba chủng.
static func _temper(value: float, mean: float) -> float:
	return 1.0 + STAT_STRENGTH * (value / mean - 1.0)


## Xây lại bảng xác suất. Gọi lại sau mỗi thẻ nâng cấp.
func rebuild_rates() -> void:
	var mean_speed: float = (SPEED[1] + SPEED[2] + SPEED[3]) / 3.0
	var mean_repro: float = (REPRO[1] + REPRO[2] + REPRO[3]) / 3.0

	for s in range(1, 4):
		var sw := SWAP_BASE * mobility * _temper(SPEED[s], mean_speed)
		var rp := REPRO_BASE * _temper(REPRO[s], mean_repro)
		if s == TOXIC:
			rp *= repro_boost
		var kl := KILL_BASE * pow(float(HP_TABLE[PREY[s]]), HP_COMPENSATION)

		# Ba nhánh cộng lại KHÔNG được vượt 1, nếu không nhánh cuối bị randf() cắt cụt
		# âm thầm. Đúng chuyện đã xảy ra: Nhạy cảm cần 0.500 để ra đòn nhưng tổng lên
		# 1.029, nên nó chỉ thật sự đánh 0.470 — tốc độ dọn sạch hụt 6% so với hai
		# chủng kia, mà mọi con số in ra vẫn đẹp vì chúng đọc từ NGƯỠNG chứ không phải
		# từ xác suất thực nhận. Lỗi bò vào lúc nâng `mobility` lên 1.8.
		#
		# Khi phải cắt thì cắt đổi-chỗ và sinh-sản, giữ nguyên ra-đòn: tốc độ dọn sạch
		# bằng nhau là thứ giữ cho vòng khắc chế trung tính, còn nhanh chậm một chút
		# chỉ là hương vị.
		var room := 1.0 - kl
		if sw + rp > room:
			var shrink := room / (sw + rp)
			sw *= shrink
			rp *= shrink

		_swap[s] = sw
		_swap_repro[s] = sw + rp
		_swap_repro_kill[s] = sw + rp + kl
		_stir_swap[s] = STIR_SWAP
		_stir_swap_repro[s] = STIR_SWAP + STIR_REPRO
		_stir_swap_repro_kill[s] = STIR_SWAP + STIR_REPRO + KILL_BASE


## strength 0 = đĩa phẳng lặng, 1 = mọi va chạm đều bị đẩy về phía nam.
func set_flow(strength: float) -> void:
	_dirs = PackedByteArray()
	var south := int(round(clampf(strength, 0.0, 1.0) * 8.0))
	for i in 4:
		for _k in 4:
			_dirs.append(i)
	for k in south:
		_dirs[k * 2] = 2      # 2 = nam (+y)


## Chạy mô phỏng đúng delta giây. Trả về số nhịp đã chạy (test dùng để in).
##
## CÓ TRẦN: một khung hình giật dài không được phép kéo theo một cú tính toán
## khổng lồ rồi làm giật tiếp khung sau. Nghĩa là advance() KHÔNG dùng để tua
## nhiều giây một lần — muốn tua thì gọi warm_up().
func advance(delta: float) -> int:
	var want := CHURN * cells * delta + _leftover
	var k := int(want)
	_leftover = want - k
	k = mini(k, cells * 2)
	step(k)
	return k


## Chạy trước vài giây trước khi giao đĩa cho người chơi, để sóng xoắn ốc kịp
## thành hình thay vì một bãi nhiễu lốm đốm. Chia nhỏ vì advance() có trần.
func warm_up(seconds: float) -> void:
	var total := int(CHURN * cells * seconds)
	while total > 0:
		var chunk := mini(total, cells)
		step(chunk)
		total -= chunk


## k tương tác cặp ô. Đây là vòng lặp nóng duy nhất của game.
##
## CẨN THẬN: mảng Packed trong GDScript là kiểu GIÁ TRỊ copy-on-write. Bốc
## `var g := grid` ra biến cục bộ cho nhanh là bẫy — nhát ghi đầu tiên tách bản sao
## và mọi thay đổi rơi hết vào bản sao đó, `grid` của lớp đứng im, mô phỏng chạy
## mà không có gì nhúc nhích. Nên các mảng BỊ GHI phải gọi thẳng qua thuộc tính;
## chỉ mảng chỉ-đọc mới được bốc ra biến cục bộ.
func step(k: int) -> void:
	var n := cells
	var l := size
	var dirs := _dirs
	var prey := PREY
	var maxhp := HP_TABLE
	var sw := _stir_swap if stirring else _swap
	var swr := _stir_swap_repro if stirring else _swap_repro
	var swrk := _stir_swap_repro_kill if stirring else _swap_repro_kill

	for _iter in k:
		var r := randi()
		var i := r % n
		var a := grid[i]
		if a == EMPTY or a == WALL:
			continue

		# Cùng một số ngẫu nhiên nuôi luôn việc chọn hướng: thương số và số dư của
		# một randi() đủ độc lập cho mô phỏng này, mà rẻ hơn gọi randi() lần nữa.
		var dir := dirs[(r / n) & 15]
		var x := i % l
		var y := i / l
		match dir:
			0: x = (x + 1) % l
			1: x = (x + l - 1) % l
			2: y = (y + 1) % l
			_: y = (y + l - 1) % l
		var j := y * l + x

		var b := grid[j]
		if b == WALL:
			continue

		var f := randf()
		if f < sw[a]:
			grid[i] = b
			grid[j] = a
			var t := hp[i]
			hp[i] = hp[j]
			hp[j] = t
		elif f < swr[a]:
			if b == EMPTY:
				grid[j] = a
				hp[j] = maxhp[a]
				counts[a] += 1
				counts[EMPTY] -= 1
		elif f < swrk[a] and b == prey[a]:
			var nh := hp[j] - 1
			if nh <= 0:
				grid[j] = EMPTY
				hp[j] = 0
				counts[b] -= 1
				counts[EMPTY] += 1
			else:
				hp[j] = nh


func recount() -> void:
	for s in 5:
		counts[s] = 0
	for i in cells:
		counts[grid[i]] += 1
	playable = cells - counts[WALL]


func ratio(species: int) -> float:
	return float(counts[species]) / maxf(1.0, float(playable))


func at(x: int, y: int) -> int:
	return grid[(y % size) * size + (x % size)]


func put(x: int, y: int, species: int) -> void:
	var i := ((y + size) % size) * size + ((x + size) % size)
	var old := grid[i]
	if old == WALL and species != WALL:
		playable += 1
	elif species == WALL and old != WALL:
		playable -= 1
	counts[old] -= 1
	counts[species] += 1
	grid[i] = species
	hp[i] = HP_TABLE[species]


## Cấy một cụm tròn. keep_walls để nhát cấy không đục thủng vách nhựa của màn chơi.
func seed_circle(cx: int, cy: int, radius: int, species: int, keep_walls := true) -> int:
	var planted := 0
	var rr := radius * radius
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy > rr:
				continue
			var gx := (cx + dx + size) % size
			var gy := (cy + dy + size) % size
			if keep_walls and grid[gy * size + gx] == WALL:
				continue
			put(gx, gy, species)
			planted += 1
	return planted


## Rắc lác đác — dùng cho nền khởi tạo, cho lưới tự nảy hoa văn thay vì ba cục tròn.
func scatter(species: int, amount: float, rng: RandomNumberGenerator) -> void:
	for i in cells:
		if grid[i] == WALL:
			continue
		if rng.randf() < amount:
			var old := grid[i]
			counts[old] -= 1
			counts[species] += 1
			grid[i] = species
			hp[i] = HP_TABLE[species]


## Ô này có đứng sát chủng khác không — tầng vẽ chỉ dựng sprite ở tiền tuyến.
func is_frontline(x: int, y: int) -> bool:
	var v := grid[y * size + x]
	if v == EMPTY or v == WALL:
		return false
	var l := size
	var n := grid[y * l + (x + 1) % l]
	if n != v and n != EMPTY and n != WALL:
		return true
	n = grid[y * l + (x + l - 1) % l]
	if n != v and n != EMPTY and n != WALL:
		return true
	n = grid[((y + 1) % l) * l + x]
	if n != v and n != EMPTY and n != WALL:
		return true
	n = grid[((y + l - 1) % l) * l + x]
	return n != v and n != EMPTY and n != WALL
