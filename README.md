# Chiến tranh Khuẩn Lạc

Roguelite mô phỏng sinh thái 2.5D dựng bằng Godot 4, theo hai tài liệu trong repo:
`thiet-ke-game-khuan-lac.html` (thiết kế) và `gameplay-khuanlac.html` (bản web thử nghiệm).

Ba chủng vi khuẩn khắc chế nhau vòng tròn trên một đĩa thạch 180×180 ô. Người chơi
nuôi chủng **Tiết độc** nhưng **không điều khiển từng con** — chỉ có hai đòn can
thiệp là *cấy quân* và *khuấy đĩa*, còn lại lưới ô tự hành tự diễn.

```bash
./play.sh            # chơi
./play.sh test       # smoke + phủ cả năm mục tiêu, không cần cửa sổ
./play.sh balance    # đo thế cân bằng của lưới trên 15 thế cờ
./play.sh tune       # các phép đo đứng sau những con số dễ chỉnh sai nhất
./play.sh shot       # chụp ảnh ra godot/_shot-*.png
```

## Cách chơi

| | |
|---|---|
| Chuột trái lên đĩa | cấy một cụm Tiết độc (có thời gian hồi) |
| Giữ Space | khuấy đĩa — trộn tung quân, phá cấu trúc xoắn ốc |
| 1 / 2 / 3 | chọn thẻ nâng cấp |
| R | chơi lại |

Vòng khắc chế: Tiết độc **diệt** Nhạy cảm → Nhạy cảm **đè** Kháng độc → Kháng độc
**chặn** Tiết độc. Không ai mạnh nhất, nên muốn hạ Kháng độc thì phải *nuôi* Nhạy
cảm cho nó ăn hộ — đó là toàn bộ chiều sâu chiến thuật của game.

## Phần nào có thật

Cái lõi lấy từ vi sinh thật, không phải bịa:

- **Vòng khắc chế** là hệ colicin của *E. coli* — Kerr, Riley, Feldman & Bohannan,
  *Nature* 418:171–174 (2002). C tiết colicin diệt S; S nhanh hơn R vì đột biến kháng
  làm R vận chuyển dinh dưỡng kém; R nhanh hơn C vì không phải trả giá sản xuất độc tố.
- **Khuấy đĩa làm sập đa dạng** là kết quả trung tâm của đúng bài đó: nuôi trên mặt
  thạch thì cả ba chủng cùng sống, nuôi trong bình lắc thì chỉ còn một.
- **Sóng xoắn ốc và trần linh động** — Reichenbach, Mobilia & Frey, *Nature*
  448:1046–1049 (2007). `tests/diag_pattern.gd` đo lại được đúng hiện tượng: linh động
  vừa phải sinh hoa văn, quá ngưỡng thì một chủng chết.

Còn lại là thiết kế game, không có gốc sinh học: **máu** (colicin diệt theo động học
một-cú-chết, không có thanh máu), năm loại mục tiêu, thẻ nâng cấp, và toàn bộ phép đếm
69 tổ hợp màn. Hai chỗ **sai sự thật** cần biết: *E. coli* không tạo bào tử (thẻ "Bào tử
dày") và vi khuẩn không có cá thể chúa ("Vi khuẩn Chúa").

Kiểm kê đầy đủ từng chi tiết — có thật / đơn giản hoá / sai / sáng tạo, kèm nguồn —
nằm ở [CO-SO-KHOA-HOC.md](CO-SO-KHOA-HOC.md).

Một lượt đi qua 6–8 đĩa, mỗi đĩa ghép [địa hình] × [thế cờ] × [mục tiêu]. Thắng đĩa
nào thì chọn 1 trong 3 thẻ nâng cấp; thua một đĩa là hết lượt.

## Bố cục mã

```
godot/scripts/
  sim.gd        lưới ô tự hành — không một dòng nào biết tới màn hình
  stages.gd     sinh màn: 4 địa hình × 4 thế cờ × 5 mục tiêu
  run.gd        một lượt roguelite: danh sách đĩa + thẻ nâng cấp
  colony.gd     trọng tài: chấm mục tiêu, nhận thao tác, điều phối lớp phủ
  board.gd      chiếu isometric, đẩy lưới lên GPU
  dish.gdshader tô màu mặt đĩa
  palette.gd    bảng màu của cả game, một chỗ duy nhất
  agents.gd     lính chibi ở tiền tuyến + mây độc
  hud.gd        toàn bộ giao diện, dựng bằng mã
```

Luồng dữ liệu một chiều đúng như mục 3 tài liệu thiết kế: `Sim` là nguồn sự thật duy
nhất, tầng vẽ chỉ đọc. Nhờ vậy mọi thứ về cân bằng đều đo được headless.

## Vài chỗ đáng lưu ý

**Lưới đi thẳng lên GPU.** `Sim.grid` là `PackedByteArray`, tức đã đúng định dạng
`Image.FORMAT_R8`. Mỗi khung chỉ việc bọc lại mảng đó thành texture, không tô một
điểm ảnh nào ở phía CPU. Vẽ 32.400 ô rẻ gần bằng vẽ một hình chữ nhật.

**Mảng Packed là kiểu giá trị copy-on-write.** Trong vòng lặp nóng, bốc
`var g := grid` ra biến cục bộ cho nhanh là bẫy chết người: nhát ghi đầu tiên tách
bản sao, mọi thay đổi rơi vào bản sao đó, và mô phỏng chạy mà không có gì nhúc nhích
— không hề có lỗi nào nổ ra. `tests/balance.gd` có một phép kiểm riêng cho chuyện này.

**Nhánh tấn công không được là phần dư.** Bản web tính "đổi chỗ / sinh sản / còn lại
thì đánh nhau". Chia tỉ lệ sinh sản theo chủng thì Nhạy cảm (sinh sản gấp ba) có phần
dư tụt về 0 — Kháng độc thành bất khả xâm phạm, vòng khắc chế đứt, ván nào người chơi
cũng bị nghiền trong bảy giây. Ba nhánh giờ đều có xác suất riêng, phần dư là *đứng yên*.

**Xác suất ra đòn tỉ lệ thuận với máu con mồi.** Nếu không, chủng nào có con mồi 1 máu
sẽ dọn nhanh gấp đôi hai chủng kia và tự thắng: đo được chủng người chơi tự leo lên
65% trong 60 giây mà không cần đụng chuột.

**Độ linh động quyết định kích thước hoa văn.** Bê nguyên con số của bản web (lưới
100) sang lưới 180 thì mặt đĩa ra một bãi nhiễu hạt mịn, mất đúng thứ mà tên game dựa
vào. `tests/diag_pattern.gd` quét dải này và cho thấy trần vật lý của mô hình: ×1.8 cho
mảng 26 px và sống sót 8/8 ván, ×2.2 được 29 px nhưng đã hỏng 1/8. Lưới to hơn *không*
cứu được — 220 và 260 ô đều tệ hơn 180.

**Test phải chạy đúng cấu hình của bản chơi, và phải gieo hạt.** Hai lỗi này từng che
nhau: `balance.gd` chạy lưới 160 (dễ tuyệt chủng hơn 180) trong khi `diag_pattern.gd`
không gieo hạt nên mỗi lần chạy ra một kết quả. Cái thứ hai báo ×2.2 an toàn 4/4, cái
thứ nhất báo hỏng 3/4 — và cả hai đều không nói đúng về cái đĩa người chơi thật sự cầm.

**Màu nằm ở đúng một file.** `palette.gd` giữ toàn bộ bảng màu; shader, chibi và HUD
đều đọc từ đó. Trước đây ba tầng này mỗi tầng khai màu riêng, nên đổi tone là ba lần
sửa và chỉ cần sót một chỗ là chấm trong HUD lệch màu với quân trên đĩa. Mỗi chủng có
hai màu tách bạch: `field` để tô mặt đĩa (phải trầm vì chiếm nhiều diện tích) và
`sprite` cho chibi với chấm HUD (phải sáng hơn nền mới nổi). Có ba tone dựng sẵn, đổi
bằng `Palette.tone`; xem tone khác mà không phải sửa mã:

```bash
godot --path godot --script tests/capture.gd -- ink   # dim_lab | microscope | ink
```

**Tầng lính là núm hiệu năng chính.** Mỗi con chibi là sáu lệnh `draw_circle` không
gộp lô được, tốn ~0.12 ms. 120 con ăn hết 16 trong 17 ms mỗi khung; 64 con chỉ tốn
6.5 ms mà tiền tuyến vẫn kín người. `./play.sh render` in lại bảng đo này.

## Đo đạc

Số liệu trên máy Intel iGPU, lưới 180×180:

| | |
|---|---|
| Mô phỏng | 2.4 ms/khung (8.910 nhịp) |
| Vẽ, 64 chibi | ~7 ms/khung |
| Cân bằng không can thiệp | cả ba chủng sống qua 90s ở 15/15 thế cờ |
| Tỉ lệ thắng của bot | khoảng 1/2 ở cả năm mục tiêu |

Nếu game chạy đúng 1 fps trong phiên chạy tự động thì đó là **vsync** — trình quản lý
cửa sổ giữ mỗi khung tròn một giây khi cửa sổ không được hợp thành thật. Các test cần
render đều tự tắt vsync; bản chơi thật giữ nguyên vsync.

## Khác với tài liệu thiết kế

Ba chỗ lệch, đều vì đo rồi mới sửa — chi tiết nằm ở chú thích ngay tại chỗ:

- **Bảng số liệu ba chủng** bị nén lại quanh mốc 1.0 thay vì dùng thẳng làm hệ số
  nhân. Chênh lệch gốc (Nhạy cảm sinh sản gấp ba Tiết độc) quá gắt, không mô hình nào
  giữ nổi thế cân bằng.
- **Mục tiêu Hoả tốc** đổi từ "diệt sạch Kháng độc" thành "truy kích tàn quân xuống
  dưới 3%". Người chơi chỉ nuôi được Tiết độc, mà Tiết độc *ăn* Nhạy cảm — đúng chủng
  đang gặm Kháng độc hộ mình; đòi họ tự tay xoá sổ Kháng độc là đòi một việc bộ công
  cụ không làm được.
- **Hoa văn** là các mảng sóng lan và xoáy cục bộ cỡ ~26 px, không phải xoắn ốc nhiều
  cánh trải khắp đĩa như hình minh hoạ. Muốn xoắn to cỡ đó thì phải đẩy độ linh động
  qua ngưỡng, và qua ngưỡng là bắt đầu có ván mất hẳn một chủng.
