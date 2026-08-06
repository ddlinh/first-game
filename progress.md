# Tiến độ — "Khuẩn lạc"

Tóm tắt trạng thái phát triển hiện tại. Bản chơi nằm ở `godot/proto2/`.

## Game là gì

City-builder cấp vi sinh, **mô hình agent**: mỗi con vi khuẩn là một **cá thể** có việc
làm nhìn thấy được (cảm hứng Timberborn). Người chơi chỉ **rải thức ăn**; mọi thứ khác
(lan, phân đôi, kết biofilm, địch tới) tự diễn theo cơ chế sinh học thật. Mỗi màn là một
**chủng có thật** do game giới thiệu.

Đã chuyển hướng từ game gốc (khắc-chế-3-chủng trên lưới, mô hình colicin) sang mô hình
agent này; bản lưới cũ còn trong lịch sử git.

## Chạy

```bash
./play.sh          # chơi khuẩn lạc (main_scene = proto2/Agents.tscn)
./play.sh yogurt   # chơi MÀN YAOURT (proto2/Yogurt.tscn)
./play.sh check    # test lõi (cả khuẩn lạc lẫn yaourt), không cần cửa sổ
./play.sh shot     # chụp ảnh
```

Điều khiển: **chuột trái** rải thức ăn · **[N]** đổi chủng · **[B]** sổ tay · **[R]** chơi lại
· di chuột vào một con để xem nó đang làm gì.

## Bố cục mã

```
godot/proto2/
  agent_colony.gd   LÕI mô phỏng — không biết màn hình, test headless được
  colony_view.gd    vẽ + nhập liệu + tutorial + thẻ chủng/sổ tay + hiệu ứng + âm thanh
  strains.gd        danh sách chủng có thật (tham số + lời giới thiệu)
  Agents.tscn       scene chính
  yogurt_level.gd   LÕI màn YAOURT — hai loài cộng sinh hạ pH tới 4.6, test headless
  yogurt_view.gd    view màn yaourt — hũ + đồng hồ + nút hành động + biến cố
  Yogurt.tscn       scene màn yaourt
  check.gd          test headless (./play.sh check) — gồm cả yaourt
  shot.gd / shot_yogurt.gd   chụp ảnh dev
```

## Màn YAOURT (mô hình MỚI: chỉnh môi trường bằng HÀNH ĐỘNG, đích = trạng thái)

Hướng thiết kế đã chốt qua bàn luận + nguyên mẫu web: **cách chơi thống nhất** (chỉnh môi
trường rồi quan sát), mỗi màn đổi **chủng · chuyện · đích · biến cố**. Yaourt là màn mẫu đầu.

- **Đích = một TRẠNG THÁI sinh thái**, không phải "đơn hàng": dẫn vại sữa hạ **pH tới 4.6**
  (điểm đẳng điện casein → đông) rồi CHỐT; lố dưới 3.85 = tách whey (thua); mốc chiếm = thua.
- **Điều khiển bằng HÀNH ĐỘNG**, không slider: Ủ ấm · Làm mát · Quấn khăn · Thêm men ·
  Tiệt trùng · CHỐT. pH là ĐẦU RA (khuẩn tạo), không chỉnh thẳng.
- **Hai loài CỘNG SINH thật**: S. thermophilus (ưa pH cao) dẫn trước, **trao tay** cho
  L. bulgaricus (ưa axit) khi pH tụt — kiểm bằng assert (tỉ phần Lb tăng 0.23→0.39).
- **Biến cố ngoại cảnh** báo trước rồi đánh: gió lùa · phage tấn công men · nhiễm mốc.
- Assert trong `check.gd`: chăm đúng→thắng · bỏ mặc→mốc chiếm→thua · trao tay · biến cố chạy.

Nguyên tắc: **lõi tách khỏi phần vẽ** (luồng một chiều). Mỗi cơ chế mới trong lõi kèm
một assert trong `check.gd`.

## Cơ chế đã có

**Cá thể & vòng đời** — mỗi con có trạng thái: kiếm ăn · đang ăn · phân đôi · ngủ đông
(bào tử) · phòng thủ · nhiễm phage · xây biofilm. Nhân hoá: có mắt (nhìn theo hướng bơi)
và biểu cảm theo việc. Di chuột vào một con hiện việc + năng lượng.

**Lan theo sinh học thật** — dinh dưỡng là một TRƯỜNG khuếch tán bị ăn mòn cục bộ; khuẩn
đi bằng RUN-AND-TUMBLE (hoá hướng động E. coli), không nhắm đích ở xa; lớn bằng phân đôi
ở rìa (range expansion).

**RẢI THỨC ĂN LÀ MỘT NGHỀ (tâm điểm city-builder)** — người chơi VẼ bằng dinh dưỡng: nhấp
= một dấu, GIỮ-KÉO = vẽ vệt (cọ). Có NGÂN SÁCH dinh dưỡng hữu hạn, hồi theo giờ → rải ở
đâu mới đáng. Rải lên chỗ đã bão hoà (trường chạm trần) là PHÍ → kỹ năng là "đón đầu rìa
đang mọc". Khuẩn lạc lớn thành HÌNH mình gieo (nền cho agar-art). Lõi `deposit()` + ngân
sách, assert trong check.gd. Đây là hướng đã chốt để GIỮ chất city-builder: một động từ
nhưng có chiều sâu + biểu đạt; khuẩn lạc (cá thể làm việc, xây biofilm) vẫn là trái tim.

**Cross-feeding** — khuẩn ăn thì thải PHẾ PHẨM (trường riêng). Phế phẩm đọng lại tạo một
niche → một chủng CROSS-FEEDER trôi tới bén rễ (nhiễm tạp), ĂN phế phẩm và TÁI CHẾ thành
dinh dưỡng. Vòng khép kín, mutualism hai chiều.

**Nguồn địch/bạn = nhiễm tạp + chiếm niche** — khuẩn lạc ĐÔNG → phage bén vào (cần mật độ
vật chủ cao mới lây); phế phẩm đọng → cross-feeder tới. Kèm toast giải thích.

**Biofilm theo quorum sensing** — KHÔNG do người chơi đặt. Chỗ nào khuẩn quây đủ đông
(≥8 con trong bán kính) thì chúng TỰ tiết chất nền kết biofilm, kèm popup giải thích.
Biofilm che chở con bên trong khỏi phage.

**Combat + phòng thủ** — phage săn từng con; con gần phage chuyển sang phòng thủ, tiết độc
diệt phage; con bị nhiễm chết rồi phóng phage mới (phage lớn theo dân số).

**Cạnh tranh liên khuẩn + T6SS** — khuẩn lạc thịnh → một CHỦNG ĐỐI THỦ (rival) trôi vào
tranh niche dinh dưỡng. Khuẩn nhà diệt nó bằng T6SS: vũ khí ĐÂM-CHẠM (contact-dependent,
state `STAB`), tách bạch với colicin khuếch tán tầm xa (`DEFEND`, diệt phage). Con trong
biofilm được che chở khỏi bị đâm. Đối thủ cũng có T6SS nên đâm lại → giao chiến hai chiều.

**Đồ hoạ PIXEL-ART (hướng đã chốt = sprite)** — `bake_sprites.gd` bake art (lưới ký tự +
bảng màu) ra `sprites/*.png`; view nạp nearest-neighbor 1:1. Thân khuẩn tint theo VIỆC,
giữ mắt/biểu cảm. Vũ khí bám cấu trúc thật: giáo T6SS, phage (đầu icosahedral + đuôi tiêm),
đối thủ gai. Mỗi CHỦNG một hình thái thật: E. coli que thon · Staph cầu khuẩn quây cụm
(ánh vàng aureus) · Proteus swarmer dài · Bacillus que + BÀO TỬ sáng khi đói.

**Đặc tính CHỦNG × MÔI TRƯỜNG** — `set_environment(motility, agar_hardness, richness)` cho
bốn kiểu mọc: giữ-hình (định cư + thạch cứng) · lan (bơi) · bầy đàn (thạch mềm) · nhánh
(nghèo + cứng). Đo được: định cư bán kính lan 79 vs bơi 203.

**Thẻ chủng + sổ tay** — mỗi màn là một chủng thật ([strains.gd](godot/proto2/strains.gd):
E. coli, Staphylococcus, Proteus, Bacillus). Vào màn hiện thẻ giới thiệu + tự áp đặc
tính; [B] mở sổ tay (Pokédex) điền dần.

**Juice combat** — hiệu ứng: nổ độc (vòng lan + tia), trúng đòn (loé đỏ), tế bào vỡ (bung
mảnh + phage văng), rung màn khi vỡ/sóng phage. Hệ âm thanh tổng hợp bằng mã cho từng sự
kiện.

## Có thật / sáng tạo (xem CO-SO-KHOA-HOC.md)

**CÓ THẬT**: run-and-tumble chemotaxis; range expansion; cross-feeding/syntrophy; quorum
sensing → biofilm; biofilm che chở phage; phage cần mật độ vật chủ; nhiễm tạp/chiếm niche;
đặc tính chủng×môi trường (motility, độ cứng thạch, độ giàu) quyết kiểu mọc; bào tử
(Bacillus); **T6SS đâm-chạm cạnh tranh liên khuẩn** (đồng nguồn đuôi phage), tách bạch với
colicin khuếch tán; **hình thái cầu khuẩn vs trực khuẩn** đúng từng chi. Bốn chủng thật.

**SÁNG TẠO / ĐƠN GIẢN HOÁ**: nhân hoá (mắt, biểu cảm — khuẩn không có mắt); pixel-art &
màu mã hoá VIỆC (không phải chủng); mọi chủng đều có T6SS (thật thì chỉ một số loài);
cross-feeder "tái chế thẳng thành dinh dưỡng"; các con số ngưỡng; hiệu ứng & âm thanh.

## Còn dang dở / cần chốt

- **Âm thanh** đang là PLACEHOLDER tổng hợp bằng mã, chưa nghe/kiểm; cần chỉnh hoặc thay
  bằng file `.ogg` thật.
- **Mức độ "chất chiến"** của đồ hoạ ĐÃ CHỐT: pixel-art "chiến binh VI SINH" (sprite) —
  giữ thân khuẩn dễ thương, đổi động tác combat sang vũ khí thật có nhãn (giáo T6SS, phage
  tiêm). KHÔNG reskin thành người (phản khoa học). Sprite riêng từng chủng đã làm.
  Còn có thể nâng: chuỗi Bacillus, khung đòn nhiều frame, sắc tố chủng rõ hơn.
- **Chưa có mục tiêu thắng/thua** mỗi màn — hiện là sandbox; bước tiếp để thành campaign.
- Fractal nhánh / agar-art sắc nét cần nhiều cá thể hơn (đánh đổi với "ngắm từng con").

## Nguyên tắc làm việc

Xem [CLAUDE.md](CLAUDE.md): mọi đề xuất tính năng được cân nhắc TÍNH KHOA HỌC trước khi
thêm (phân loại CÓ THẬT / ĐƠN GIẢN HOÁ / SAI, nói thẳng nếu sai). Tài liệu:
[thiet-ke-microbiome.md](thiet-ke-microbiome.md), [CO-SO-KHOA-HOC.md](CO-SO-KHOA-HOC.md).
