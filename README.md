# EMBERHOLD

Map vây isometric 2.5D làm bằng Godot 4. Trụ lại 22 giây trong hầm mộ khi quái ập
vào từ bốn phía. Sprite 2D billboard đặt trong scene 3D có đèn thật — đuốc trên tay
nhân vật nhấp nháy và di chuyển theo bạn, bốn cột lửa soi vào tường đá.

## Chạy game

```bash
./play.sh          # chơi
./play.sh test     # chạy test, không cần cửa sổ
./play.sh shot     # chụp ảnh màn chờ + giữa trận ra godot/_shot-*.png
```

`play.sh` sẽ in hướng dẫn nếu không tìm thấy Godot. Ngắn gọn:

```bash
curl -sL -o /tmp/godot.zip \
  https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_linux.x86_64.zip
unzip -o /tmp/godot.zip -d /tmp
mv /tmp/Godot_v4.7.1-stable_linux.x86_64 ~/.local/bin/godot && chmod +x ~/.local/bin/godot
```

Đã có Godot ở nơi khác thì trỏ vào: `GODOT=/duong/dan/godot ./play.sh`

## Cách chơi

Mở lên là màn chờ — **nhấn Enter** để vào trận.

| phím | tác dụng |
|---|---|
| **WASD** / phím mũi tên | di chuyển |
| **Space** (hoặc Shift) | lăn né — miễn thương trong lúc lăn, hồi chiêu 1.1 giây |
| **Enter** | bắt đầu / chơi lại |
| — | vũ khí **tự chém** mọi quái trong vòng sáng dưới chân, không cần bấm |

Space làm phím lăn né nên màn chờ chỉ nhận Enter: nếu dùng chung một phím thì vừa
chết là bấm nhầm chơi lại ngay.

Hai điều quyết định thắng thua:

1. **Đừng cắm chân giữa đám đông.** Số 🔧 trên HUD là độ bền vũ khí, nó hao theo
   *số quái đang kẹp quanh mình*. Tụt về 0 là lưỡi mẻ, sát thương sụp còn một phần
   ba, và từ đó bạn bị vùi. Kéo quái ra chém lẻ thì vũ khí trụ được hết vòng đấu.
2. **Giữ cú lăn cho lúc cần.** Thanh xanh dưới màn hình là đồng hồ hồi chiêu.

Đứng im không bấm gì thì thua — xem số liệu ở mục dưới.

## Ghi chú thiết kế

**Tường chỉ cao ở hai phía xa.** Camera isometric nhìn từ hướng +X+Z, nên tường ở
hai phía *gần* camera sẽ che mất nhân vật: đỉnh tường cao 3.6 m chiếu lên màn hình
nằm cao hơn chân nhân vật, mà sprite chỉ cao khoảng 1.4 đơn vị. Vì vậy hai phía gần
hạ thành bờ 0.4 m, và cột lửa ở góc gần cũng hạ thấp theo. Quái spawn ở khoảng 10.8
— ngoài vùng nhân vật đi được (9.2) nhưng vẫn trong mặt trong tường (11.25) để không
hiện ra xuyên qua đá.

**Cân bằng được đo, không đoán.** [`tests/balance.gd`](godot/tests/balance.gd) chạy
8 lượt liên tiếp không cần cửa sổ với hai kiểu người chơi:

```bash
~/.local/bin/godot --headless --path godot --script tests/balance.gd -- im    # đứng im
~/.local/bin/godot --headless --path godot --script tests/balance.gd -- bot   # né + lăn tự động
```

| kiểu chơi | thắng | trụ được | máu còn |
|---|---|---|---|
| đứng im, không bấm gì | 1/8 | 19.9 s | 0 |
| di chuyển + lăn né | 8/8 | 22.1 s | 13/30 |

Đây là thước đo chính khi sửa độ khó: **kiểu "im" phải thua**, nếu không thì vũ khí
tự chém đã thắng hộ người chơi và cú lăn né thành vô nghĩa.

Lúc đầu đo ra kiểu "im" thắng **8/8** còn 19.8/30 máu, và bot biết né lại hạ được
*ít* quái hơn cả đứng im (14.9 so với 20.1). Cách sửa không phải spam thêm quái, mà
dùng đúng cơ chế game đã có: cho độ bền vũ khí hao theo **số** quái đang kẹp quanh
mình (`0.35 + 0.1` mỗi con) thay vì một mức cố định. Giờ đứng im chết ở giây 19.9 —
sát đích, nên thua rất căng chứ không thua sớm.

**Âm thanh sinh bằng code.** Không có asset tải về: toàn bộ WAV trong
[`godot/audio/`](godot/audio/) do một script Python dựng từ hàm sin và ồn trắng
(bộ lọc thông thấp để nặn tiếng gió, bao biên độ hàm mũ). Tiếng nền hầm mộ chọn tần
số là bội số nguyên của độ dài file nên vòng lại không nghe tiếng cộp.

**Đơn vị lấy từ bản web.** Game này khởi đầu là bản dựng lại phần chiến đấu của một
roguelite web (`thu-lua-roguelite.html`, xem commit `cb5e5d9` — bản web đã bỏ khỏi
repo). Công thức vũ khí trong [`weapon.gd`](godot/scripts/weapon.gd) vẫn giữ đơn vị
%/giây trên sân ảo 100×100 của bản đó, quy đổi sang mét bằng `PCT = 0.2` (1% = 0.2 m,
sân 20×20 m). Bản web còn có màn **rèn vũ khí bằng thẻ** và **5 trận boss** đánh theo
lượt — chưa port sang đây; muốn tham khảo thì lấy file ở commit trên.

## Cấu trúc

```
play.sh                     chơi game / chạy test / chụp ảnh
godot/
  project.godot             scene chính: scenes/Swarm.tscn
  scenes/Swarm.tscn         đấu trường, HUD, âm thanh
  scenes/Hero.tscn          nhân vật, đuốc, vòng sáng bán kính chém
  scenes/Mob.tscn           quái (texture gán lúc chạy theo loại)
  scripts/swarm.gd          vòng đời game, spawn, HUD, kỷ lục
  scripts/hero.gd           di chuyển, lăn né, nhịp tự chém
  scripts/mob.gd            đuổi và lao vào người chơi
  scripts/weapon.gd         chỉ số và công thức vũ khí
  art/*.svg                 sprite
  audio/*.wav               âm thanh sinh bằng script
  tests/                    smoke, dash, balance, capture
```

Lưu ý: các file `*.import` và `*.uid` **phải** được commit — chúng giữ thiết lập
import và ID tài nguyên, thiếu là project hỏng tham chiếu.

## Test

```bash
./play.sh test
```

- `smoke.gd` — chạy trọn một vòng đấu, in trạng thái mỗi 5 giây
- `dash.gd` — 21 mục kiểm chứng: miễn thương lúc lăn, quái trượt đòn, luồng chơi lại
- `balance.gd` — đo độ khó (xem trên)
- `capture.gd` — chụp ảnh màn chờ và giữa trận

`dash.gd` bơm phím thật vào `Input` rồi **chờ** điều kiện đúng thay vì soi ngay frame
sau. Cần vậy vì `_process` chạy theo tốc độ vẽ còn game chạy theo nhịp physics — kiểm
tra tức thì sau khi bấm phím là hên xui.

Test không ghi vào file kỷ lục của người chơi (`record_enabled = false`). Không có cờ
đó thì bot chạy 8 lượt liền sẽ đặt kỷ lục của máy vào save và không ai đuổi nổi.

Kỷ lục lưu ở `user://ky-luc.cfg`
(`~/.local/share/godot/app_userdata/Emberhold/`). Xoá file đó là reset kỷ lục.
