# EMBERHOLD

Map vây isometric 2.5D làm bằng Godot 4. Trụ lại 22 giây trong hầm mộ khi quái ập
vào từ bốn phía. Sprite 2D đặt trong scene 3D có đèn thật — đuốc trên tay
nhân vật nhấp nháy và di chuyển theo bạn, bốn cột lửa soi vào tường đá.

## Chạy game

```bash
./play.sh           # chơi
./play.sh test      # chạy test, không cần cửa sổ
./play.sh balance   # đo độ khó (mất khoảng 2 phút)
./play.sh shot      # chụp ảnh ra godot/_shot-*.png
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
| **chuột trái** | chém — quét cả vòng sáng dưới chân, hồi chiêu bằng nhịp vũ khí |
| **Space** (hoặc Shift) | lăn né — miễn thương trong lúc lăn, hồi chiêu 1.1 giây |
| **Enter** | bắt đầu / chơi lại |

Giữ chuột thì chém liên tục theo nhịp vũ khí. Nhân vật quay mặt về phía con trỏ khi
chém (vùng sát thương vẫn là vòng quanh chân, không phải hình quạt).

Space làm phím lăn né nên màn chờ chỉ nhận Enter: nếu dùng chung một phím thì vừa
chết là bấm nhầm chơi lại ngay.

Quái bị hạ thì **NỔ**, sát thương lan ra trong 1.8 m; con chết theo lại nổ tiếp,
tối đa 3 đời và yếu đi 40% mỗi đời. Nhưng **vụ nổ cũng dội vào bạn** nếu bạn đứng
trong bán kính — trừ khi đang lăn né.

Lưỡi kiếm có **điện**: chém trúng một con **slime** thì sét nhảy sang các slime khác
trong vòng 2.7 m, tối đa 3 chặng, mỗi chặng yếu đi 30%. Dơi và chuột không dẫn điện —
chỉ slime, vì nó là sinh vật nhầy ướt. Xác slime vẫn dẫn tiếp được.

Bốn điều quyết định thắng thua:

1. **Chém rồi LĂN RA.** Đây là vòng chơi cốt lõi. Dồn quái lại, chém một nhát cho
   nổ dây, rồi lăn ra khỏi vụ nổ — lăn né có miễn thương nên nó cũng chặn luôn sát
   thương nổ dội lại.
2. **Đừng cắm chân giữa đám đông.** Số 🔧 trên HUD là độ bền vũ khí, nó hao theo
   *số quái đang kẹp quanh mình*. Tụt về 0 là lưỡi mẻ: sát thương sụp còn một phần
   ba **và mạch điện đứt**, từ đó bạn bị vùi.
3. **Sét không miễn phí.** Mỗi nhịp sét cũng ăn vào độ bền. Gom slime lại rồi chém
   một nhát ăn cả chuỗi thì lời, nhưng đứng mãi trong bể slime là tự cắt mạch kiếm.
4. **Chém đúng lúc.** Chém là chủ động nên bạn tự quyết lúc nào tiêu độ bền. Nhả đòn
   vào không khí là tự cắt ngắn tuổi vũ khí.

Đứng im spam chuột thì **luôn** thua — xem số liệu ở mục dưới.

## Ghi chú thiết kế

**Nhân vật là một rig, không phải ảnh tĩnh.** Ban đầu nhân vật là MỘT sprite duy
nhất, nên mọi "động tác" chỉ là nghiêng hay bóp cả khối — nhìn rất cứng. Giờ nó gồm
5 bộ phận rời (hai chân, thân, đầu, tay kiếm, tay đuốc), mỗi cái treo dưới một
`Node3D` làm khớp ở hông hoặc vai, nên quay khớp là chân tay đá quanh đúng điểm.

Không có frame vẽ sẵn nào: mọi tư thế tính bằng hàm liên tục trong `hero.gd::_anim()`,
chạy trong `_process` chứ không phải `_physics_process`. Nhờ vậy cử động mượt theo
tốc độ vẽ thật, và nhân vật vẫn thở ở màn chờ lúc physics đã tắt.

Ba tầng, tầng sau đè tầng trước:

1. **nền** — đứng thở hoặc đi. Hai tư thế này *nội suy* qua nhau bằng một biến
   `_gait` chạy từ 0 tới 1, chứ không nhảy trạng thái. Đây là thứ quyết định cảm
   giác mượt: dừng chân giữa bước thì người từ từ về thế đứng, không bị "cắn" một cái.
2. **chồng** — chém (chỉ chiếm tay kiếm), ăn đòn (ngửa người). Vì chỉ chồng lên nền
   nên vừa đi vừa chém vẫn thấy chân bước.
3. **đè** — lăn, chiếm toàn quyền cả rig.

Ba chi tiết phải sửa mới ra hình:

- **Gốc rig ở giữa người (y = 0.9), không phải bàn chân.** Cú lăn cuộn quanh gốc
  này; để ở chân thì thành lộn kiểu bánh xe.
- **Đầu phải thu vào thân khi lăn.** Đầu cách tâm rig 0.79 m nên khi cuộn nó vẽ một
  vòng rất rộng và trông như rụng khỏi cổ.
- **Hai chân gập cùng chiều khi lăn**, không xoè ngược nhau như lúc đi.

Lật hướng nhìn bằng `Rig.scale.x = -1`. Vì vậy góc cuộn của cú lăn **không** nhân
thêm hướng — phép lật đã tự đảo chiều vòng cuộn.

Soi rig bằng [`tests/diag_pose.gd`](godot/tests/diag_pose.gd): nó ép nhân vật vào
từng mốc của từng động tác rồi ghép hết vào một ảnh. Chụp giữa trận thì animation
trôi quá nhanh, không bắt được mốc nào.

**Nhân vật không nhận đèn, quái thì có.** Nhân vật tự mang đuốc nên đèn ở sát sprite
(0.55 m, energy 2.4) làm mọi màu bão hoà về màu đèn — giáp, da, mũ trụ đều thành một
khối cam. Đặt `shaded = false` cho các bộ phận nhân vật để giữ đúng màu đã vẽ và
luôn đọc được. Quái vẫn nhận đèn, nhờ vậy chúng còn hiện dần ra từ trong tối.

**Giật hình thì đã kiểm tra và KHÔNG phải vấn đề.**
[`tests/diag_smooth.gd`](godot/tests/diag_smooth.gd) cho nhân vật chạy đều rồi đếm
xem bao nhiêu frame vẽ lại đúng vị trí của frame trước. Đo được 0.8% — máy vẽ 0.98
lần nhịp physics nên gần như một frame một bước. Godot 4.7 có
`physics/common/physics_interpolation` và game đang để tắt; bật nó chỉ đáng nếu bạn
dùng màn hình trên 60 Hz.

**Billboard ăn mất animation.** Sprite của nhân vật và quái từng bật
`billboard = FIXED_Y`. Chế độ đó ghi đè hướng quay ngay trong vertex shader, nên
mọi tween lên `rotation` là **vô hình** — động tác nghiêng người khi chém không bao
giờ hiện ra, dù code vẫn chạy. Scale thì không bị ảnh hưởng, nên cú lăn vẫn thấy.
Camera ở đây cố định nên billboard chẳng đem lại gì: đã tắt nó và đặt cứng
`rotation.y = 45°` cho sprite hướng vào camera. Đo bằng
[`tests/diag_billboard.gd`](godot/tests/diag_billboard.gd) — nó ẩn hẳn sprite rồi so
từng pixel với ảnh gốc, ảnh y hệt nghĩa là thứ đó không vẽ ra gì.

Cẩn thận với `Transform3D(...)` 12 số trong file `.tscn`: nó nhận theo **hàng**, không
phải theo cột. Đặt sai thứ tự thì sprite quay 90° thành nằm đúng cạnh bên hướng
camera, mỏng bằng 0, và biến mất hoàn toàn.

**Nhân vật từng tối đen vì chính cây đuốc của mình.** Đuốc là `OmniLight3D` đặt ngay
trên đầu sprite, nên tia sáng đi gần như thẳng đứng còn pháp tuyến sprite nằm ngang:
`dot(normal, light) ≈ 0`, không nhận được ánh sáng nào. Đã dịch đuốc chếch về phía
camera. Cùng lúc đó sprite cao 2.55 m mà tâm để ở 0.95 nên bàn chân nằm *dưới* mặt
sàn và bị sàn che — tâm phải ở 1.13 để chân đúng mặt đất.

**Tường chỉ cao ở hai phía xa.** Camera isometric nhìn từ hướng +X+Z, nên tường ở
hai phía *gần* camera sẽ che mất nhân vật: đỉnh tường cao 3.6 m chiếu lên màn hình
nằm cao hơn chân nhân vật, mà sprite chỉ cao khoảng 1.4 đơn vị. Vì vậy hai phía gần
hạ thành bờ 0.4 m, và cột lửa ở góc gần cũng hạ thấp theo. Quái spawn ở khoảng 10.8
— ngoài vùng nhân vật đi được (9.2) nhưng vẫn trong mặt trong tường (11.25) để không
hiện ra xuyên qua đá.

**Nổ lan dùng hàng đợi, không đệ quy.** Một cú nổ có thể hạ nhiều con, mỗi con lại
nổ tiếp. Gọi đệ quy thì dồn 40 con vào một chỗ là tràn stack, và thứ tự đời cũng
không kiểm soát được. Ở đây `swarm.gd` xếp các vụ nổ vào một hàng đợi rồi giải quyết
tuần tự, mỗi vụ ghi rõ mình thuộc đời nào. Cũng vì thế `_on_mob_killed()` chỉ *xếp
hàng* chứ không nổ tại chỗ — nó bị gọi từ giữa vòng lặp đang quét danh sách quái, nổ
ngay là sửa danh sách đang duyệt.

**Vì sao vụ nổ phải làm đau cả người chơi.** Lúc mới thêm nổ lan, đo ra kiểu chơi
"đứng im spam chuột" thắng **16/16** còn 16/30 máu: cắm chân giữa sân thì quái tự dồn
thành đống rồi chuỗi nổ quét sạch hộ, vị trí lại thành vô nghĩa. Cho vụ nổ dội lại
người chơi (35% sát thương, chặn tổng 8 mỗi chuỗi) là sửa đúng gốc: giờ "spam" thắng
**0/16**, và vòng chơi thành *chém rồi lăn ra*. Chặn tổng là cần thiết — không có nó
thì một chuỗi 40 vụ nổ giết người chơi tức khắc mà họ chẳng hiểu vì sao.

**Cân bằng được đo, không đoán.** [`tests/balance.gd`](godot/tests/balance.gd) chạy
nhiều lượt liên tiếp không cần cửa sổ với hai kiểu người chơi:

```bash
./play.sh balance          # cả hai kiểu, 16 lượt mỗi kiểu
```

| kiểu chơi | thắng | trụ được | máu còn | hạ được |
|---|---|---|---|---|
| `im` — không bấm gì cả | 0/16 | 12.0 s | 0 | 0 |
| `spam` — đứng im, chém liên tục | **0/16** | 16.5 s | 0 | 36.4 |
| `bot` — di chuyển, lăn, chém đúng lúc | 12/16 | 21.2 s | 9/30 | **42.1** |

Từ khi chém phải bấm chuột, `im` không còn là phép đo hữu ích (không chém thì chắc
chắn chết). Phép đo thật là **`spam`** — nó đúng bằng hành vi auto-chém cũ. Dấu hiệu
cho thấy cân bằng đang đúng: `bot` hạ được *nhiều hơn* `spam` (42 so với 36), tức là
di chuyển đúng chỗ có lời chứ không chỉ để sống lâu hơn.

Đây là thước đo chính khi sửa độ khó: **kiểu "im" phải thua**, nếu không thì vũ khí
tự chém đã thắng hộ người chơi và cú lăn né thành vô nghĩa. Bot ở đây né rất thô
(chỉ chạy ra xa trọng tâm đám quái) nên người chơi biết kéo quái sẽ làm tốt hơn nó.
Số của bot dao động khá rộng giữa các lần chạy vì loại quái và chỗ spawn là ngẫu
nhiên — đừng đọc một lần chạy rồi kết luận, và đừng tinh chỉnh theo chênh lệch 1–2 lượt.

Hai lần phải siết: lần đầu kiểu "im" thắng 8/8 vì vũ khí tự chém quá khoẻ — sửa bằng
cách cho độ bền hao theo **số** quái đang kẹp quanh mình thay vì một mức cố định. Lần
hai là sau khi thêm sét lan, "im" lại sống được — sửa bằng cách cho mỗi nhịp sét cũng
ăn vào độ bền. Cả hai lần đều không phải spam thêm quái.

### Cái bẫy: đo nhanh bằng `time_scale` cho ra số liệu giả

Chạy 16 lượt × 22 giây ở tốc độ thật mất gần 6 phút, nên harness cần chạy nhanh hơn.
Cách làm **sai** — và đã từng làm sai ở đây — là chỉ đặt `Engine.time_scale`. Godot
không chạy thêm bước physics; nó **nhân delta của mỗi bước lên**. Ở `time_scale = 12`
mỗi bước tiến 0.2 giây game thay vì 1/60, quái nhảy từng đoạn to và va chạm bị lấy
mẫu quá thưa. Cùng một build cho ra:

| cách đo | kết luận về kiểu "đứng im" |
|---|---|
| `time_scale = 8` | thắng 4/8 |
| `time_scale = 12` | thắng **16/16** |
| đúng (dưới đây) | thắng **0/16** |

Cách đúng: tăng `physics_ticks_per_second` theo cùng hệ số, để
`delta = time_scale / ticks` vẫn đúng `1/60` như lúc chơi thật, chỉ là mỗi giây thật
chạy nhiều bước hơn. Kiểm chứng bằng cách chạy lại ở tốc độ thật:

```bash
godot --headless --path godot --script tests/balance.gd -- im speed=1 rounds=6
godot --headless --path godot --script tests/balance.gd -- im speed=10 rounds=6
```

Hai lệnh này phải ra kết quả như nhau. Nếu sửa harness thì chạy lại phép đối chiếu
đó trước khi tin bất cứ số nào.

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
  scripts/swarm.gd          vòng đời game, spawn, sét lan, HUD, kỷ lục
  scripts/hero.gd           di chuyển, lăn né, nhịp tự chém, động tác chém
  scripts/mob.gd            đuổi và lao vào người chơi
  scripts/weapon.gd         chỉ số và công thức vũ khí
  scripts/lightning.gd      tia sét gấp khúc dựng bằng ImmediateMesh
  scripts/boom.gd           cú nổ khi hạ quái
  art/hero-*.svg            5 bộ phận rời của nhân vật
  art/bat|slime|rat.svg     sprite quái
  audio/*.wav               âm thanh, sinh bằng tools/gen_audio.py
  tests/                    smoke, dash, balance, capture, hai script chẩn đoán
tools/gen_audio.py          sinh lại toàn bộ file WAV
```

Âm thanh không phải asset tải về: chạy `python3 tools/gen_audio.py` là sinh lại đúng
từng byte các file đã commit (mọi hàm random đều có seed cố định).

Lưu ý: các file `*.import` và `*.uid` **phải** được commit — chúng giữ thiết lập
import và ID tài nguyên, thiếu là project hỏng tham chiếu.

## Test

```bash
./play.sh test
```

- `smoke.gd` — chạy trọn một vòng đấu, in trạng thái mỗi 5 giây
- `dash.gd` — 21 mục kiểm chứng: miễn thương lúc lăn, quái trượt đòn, luồng chơi lại
- `blast.gd` — nổ lan: chuỗi có lan, có dừng, dội lại người chơi, không dội khi đang
  lăn né, và 40 con nổ dây không làm sập game
- `balance.gd` — đo độ khó (xem trên)
- `capture.gd` — chụp ảnh màn chờ và giữa trận
- `diag_billboard.gd` — sprite có vẽ ra pixel không, rotation có tác dụng không
- `diag_fx.gd` — dựng hẳn một dãy slime trong tầm sét rồi chém, chụp bằng chứng cho
  vòng chém, tia sét và cú nổ. Có đếm cả số mặt của mesh tia sét, vì hiệu ứng chỉ
  sống 0.2 giây nên không thể trông vào ảnh chụp ngẫu nhiên giữa trận.
- `diag_pose.gd` — bảng 10 tư thế của nhân vật ghép vào một ảnh, để soi rig
- `diag_smooth.gd` — đếm tỷ lệ frame bị vẽ lặp, tức mức giật hình

`dash.gd` bơm phím thật vào `Input` rồi **chờ** điều kiện đúng thay vì soi ngay frame
sau. Cần vậy vì `_process` chạy theo tốc độ vẽ còn game chạy theo nhịp physics — kiểm
tra tức thì sau khi bấm phím là hên xui.

Test không ghi vào file kỷ lục của người chơi (`record_enabled = false`). Không có cờ
đó thì bot chạy 8 lượt liền sẽ đặt kỷ lục của máy vào save và không ai đuổi nổi.

Kỷ lục lưu ở `user://ky-luc.cfg`
(`~/.local/share/godot/app_userdata/Emberhold/`). Xoá file đó là reset kỷ lục.
