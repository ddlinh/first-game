# THỬ LỬA

Game rèn vũ khí và chiến đấu. Repo có **hai bản** dựng độc lập từ cùng một ý tưởng:

| | bản web | bản Godot |
|---|---|---|
| file | [`thu-lua-roguelite.html`](thu-lua-roguelite.html) | [`godot/`](godot/) |
| nội dung | roguelite đầy đủ: rèn thẻ → 1 map vây + 5 trận boss → sự kiện | **một map vây trọn vẹn**, 2.5D isometric |
| hình ảnh | SVG phẳng | sprite billboard trong scene 3D, đèn đuốc thật, đổ bóng |
| cần gì để chạy | chỉ cần browser | cần Godot 4.x |

Bản web là bản đủ nội dung. Bản Godot là bản dựng lại phần chiến đấu cho đẹp và
đúng cảm giác hơn — hiện làm trọn map vây, chưa có phần rèn và boss.

## Chạy game

```bash
./play.sh          # bản Godot
./play.sh web      # bản web, mở bằng browser mặc định
./play.sh test     # chạy test, không cần cửa sổ
./play.sh shot     # chụp ảnh màn chờ + giữa trận ra godot/_shot-*.png
```

Bản web cũng chỉ cần double-click vào file HTML — nó tự chứa hoàn toàn, không cần
mạng, không cần server.

### Cài Godot

`play.sh` sẽ in hướng dẫn nếu không tìm thấy Godot. Ngắn gọn:

```bash
curl -sL -o /tmp/godot.zip \
  https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_linux.x86_64.zip
unzip -o /tmp/godot.zip -d /tmp
mv /tmp/Godot_v4.7.1-stable_linux.x86_64 ~/.local/bin/godot && chmod +x ~/.local/bin/godot
```

Đã có Godot ở nơi khác thì trỏ vào: `GODOT=/duong/dan/godot ./play.sh`

## Cách chơi map vây

Sống sót 22 giây trong hầm mộ. Quái ập vào từ bốn phía, càng lâu càng dày.

- **WASD** hoặc **phím mũi tên** — di chuyển
- **Space** hoặc **Shift** — lăn né: lao nhanh một quãng, **miễn thương** trong lúc lăn
- **Enter** — bắt đầu / chơi lại
- Vũ khí **tự chém** mọi quái trong vòng sáng dưới chân, không cần bấm

Hai điều quyết định thắng thua:

1. **Đừng cắm chân giữa đám đông.** Độ bền vũ khí (🔧 trên HUD) hao theo *số quái
   đang kẹp quanh mình*. Lưỡi mẻ thì sát thương sụp còn một phần ba, và từ đó bị vùi.
   Kéo quái ra chém lẻ thì vũ khí trụ được hết vòng đấu.
2. **Giữ cú lăn cho lúc cần.** Hồi chiêu 1.1 giây, thanh xanh dưới màn hình là đồng hồ đó.

Đứng im không bấm gì thì thua — con số ở mục dưới.

## Ghi chú thiết kế

**Vì sao bản Godot khác bản web.** Bản web tính mọi thứ trên sân ảo 100×100 đơn vị
phần trăm; bản Godot quy đổi sang mét bằng hằng số `PCT = 0.2` (1% = 0.2 m, sân 20×20 m)
và giữ nguyên công thức vũ khí trong [`weapon.gd`](godot/scripts/weapon.gd) để hai bản
đối chiếu được. Riêng phần cân bằng map vây thì đã lệch hẳn khỏi bản web, vì bản Godot
có thêm cú lăn né.

**Tường chỉ cao ở hai phía xa.** Camera isometric nhìn từ hướng +X+Z, nên tường ở
hai phía *gần* camera sẽ che mất nhân vật: đỉnh tường cao 3.6 m chiếu lên màn hình
nằm cao hơn chân nhân vật, mà sprite chỉ cao ~1.4 đơn vị. Vì vậy hai phía gần hạ
thành bờ 0.4 m, và cột lửa ở góc gần cũng hạ thấp theo.

**Cân bằng được đo, không đoán.** [`tests/balance.gd`](godot/tests/balance.gd) chạy
8 lượt liên tiếp không cần cửa sổ với hai kiểu người chơi:

```bash
~/.local/bin/godot --headless --path godot --script tests/balance.gd -- im    # đứng im
~/.local/bin/godot --headless --path godot --script tests/balance.gd -- bot   # né + lăn tự động
```

Số hiện tại:

| kiểu chơi | thắng | trụ được | máu còn |
|---|---|---|---|
| đứng im, không bấm gì | 1/8 | 19.9 s | 0 |
| di chuyển + lăn né | 8/8 | 22.1 s | 13/30 |

Đây là thước đo chính khi sửa độ khó: **kiểu "im" phải thua**, nếu không thì vũ khí
tự chém đã thắng hộ người chơi và cú lăn né thành vô nghĩa. Trước khi siết, kiểu "im"
thắng 8/8 — và bot né còn hạ được *ít* quái hơn cả đứng im.

**Âm thanh sinh bằng code.** Không có file asset tải về: toàn bộ WAV trong
[`godot/audio/`](godot/audio/) do một script Python dựng từ hàm sin và ồn trắng
(bộ lọc thông thấp để nặn tiếng gió, bao biên độ hàm mũ). Tiếng nền hầm mộ chọn tần số
là bội số nguyên của độ dài file nên vòng lại không nghe tiếng cộp.

## Cấu trúc

```
thu-lua-roguelite.html      bản web, một file tự chứa
play.sh                     mở game / chạy test
godot/
  project.godot             scene chính: scenes/Swarm.tscn
  scenes/Swarm.tscn         đấu trường, HUD, âm thanh
  scenes/Hero.tscn          nhân vật, đuốc, vòng sáng bán kính chém
  scenes/Mob.tscn           quái (texture gán lúc chạy theo loại)
  scripts/swarm.gd          vòng đời game, spawn, HUD, kỷ lục
  scripts/hero.gd           di chuyển, lăn né, nhịp tự chém
  scripts/mob.gd            đuổi và lao vào người chơi
  scripts/weapon.gd         chỉ số và công thức vũ khí (giữ nguyên từ bản web)
  art/*.svg                 sprite
  audio/*.wav              âm thanh sinh bằng script
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

Kỷ lục lưu ở `user://ky-luc.cfg`
(`~/.local/share/godot/app_userdata/Thử Lửa — Isometric/`). Xoá file đó là reset kỷ lục.
