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
./play.sh          # chơi (main_scene = proto2/Agents.tscn)
./play.sh check    # test lõi, không cần cửa sổ
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
  check.gd          test headless (./play.sh check)
  shot.gd           chụp ảnh dev
```

Nguyên tắc: **lõi tách khỏi phần vẽ** (luồng một chiều). Mỗi cơ chế mới trong lõi kèm
một assert trong `check.gd`.

## Cơ chế đã có

**Cá thể & vòng đời** — mỗi con có trạng thái: kiếm ăn · đang ăn · phân đôi · ngủ đông
(bào tử) · phòng thủ · nhiễm phage · xây biofilm. Nhân hoá: có mắt (nhìn theo hướng bơi)
và biểu cảm theo việc. Di chuột vào một con hiện việc + năng lượng.

**Lan theo sinh học thật** — dinh dưỡng là một TRƯỜNG khuếch tán bị ăn mòn cục bộ; khuẩn
đi bằng RUN-AND-TUMBLE (hoá hướng động E. coli), không nhắm đích ở xa; lớn bằng phân đôi
ở rìa (range expansion).

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
(Bacillus). Bốn chủng và đặc trưng của chúng đều thật.

**SÁNG TẠO / ĐƠN GIẢN HOÁ**: nhân hoá (mắt, biểu cảm — khuẩn không có mắt); cross-feeder
"tái chế thẳng thành dinh dưỡng" (thật thì phức tạp hơn); các con số ngưỡng; hiệu ứng &
âm thanh.

## Còn dang dở / cần chốt

- **Âm thanh** đang là PLACEHOLDER tổng hợp bằng mã, chưa nghe/kiểm; cần chỉnh hoặc thay
  bằng file `.ogg` thật.
- **Mức độ "chất chiến"** của đồ hoạ chưa chốt: A) giữ khuẩn dễ thương + VFX vũ khí thật
  (hiện tại) · B) "chiến binh vi sinh" (đâm giáo T6SS, phage thành mũi tên, chữ nổi) ·
  C) reskin lính/kiếm khách (phản khoa học). Nghiêng về B.
- **Chưa có mục tiêu thắng/thua** mỗi màn — hiện là sandbox; bước tiếp để thành campaign.
- Fractal nhánh / agar-art sắc nét cần nhiều cá thể hơn (đánh đổi với "ngắm từng con").

## Nguyên tắc làm việc

Xem [CLAUDE.md](CLAUDE.md): mọi đề xuất tính năng được cân nhắc TÍNH KHOA HỌC trước khi
thêm (phân loại CÓ THẬT / ĐƠN GIẢN HOÁ / SAI, nói thẳng nếu sai). Tài liệu:
[thiet-ke-microbiome.md](thiet-ke-microbiome.md), [CO-SO-KHOA-HOC.md](CO-SO-KHOA-HOC.md).
