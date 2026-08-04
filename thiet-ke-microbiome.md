# Thiết kế: Vi Sinh Kiến Tạo — city-builder theo màn

Game xây dựng cấp vi sinh: **bạn đặt công trình, vi khuẩn tự mọc quanh nó, bạn quản
tài nguyên** — rồi khi khuẩn lớn lên thì mối đe dọa kéo tới và bạn phải thủ. Chia màn,
mỗi màn cô lập một bài học vi sinh có thật.

Bản này thay cho bản "microbiome chiến trường" trước: giữ nguyên phần khoa học và vòng
"lớn-lên-thì-bị-vây", nhưng **đổi động từ lõi từ *chỉ huy trận đánh* sang *xây dựng***,
và **đóng khung theo màn kiểu city-builder** thay vì sandbox mở.

Tài liệu bám đúng engine đang có (`sim.gd` render, `board.gd`, shader). Kỷ luật
"có thật / sáng tạo" của [CO-SO-KHOA-HOC.md](CO-SO-KHOA-HOC.md) giữ nguyên.

---

## 1. Định vị một câu

> Bạn không cầm từng con vi khuẩn. Bạn là **người kiến tạo**: rải dinh dưỡng, dựng
> công sự, đặt ổ cấy — rồi *khuẩn tự lớn lên theo những gì bạn xây*. Lớn tới đâu thì
> kẻ thù (phage, miễn dịch, môi trường) tìm tới đó, và bạn phải xây để chống lại.

Khác Substrate (sandbox tiến hóa) và Pathogenic (một avatar đi bắn): đây là
**city-builder / build-and-hold** với một *quần thể sống* thay cho gạch và dân.

---

## 2. Thể loại & cảm giác

- **City-builder**: người chơi *đặt và quy hoạch*, không vi điều khiển. Growth là hệ
  quả của quy hoạch tốt (giống đặt đường/khu dân cư rồi thành phố tự phình).
- **Build-and-hold** (họ hàng They Are Billions, tower-defense, Bad North): xây trong
  lúc yên, rồi giữ khi sóng địch tới.
- **Theo màn, kiểu Opus Magnum**: cùng một động từ (xây cho khuẩn lớn), nhưng *chướng
  ngại đổi mỗi màn* — đó là nguồn đổi mới, không phải thêm cơ chế mới.

---

## 3. Vòng lặp lõi

```
        ┌─────────────────────────────────────────────┐
        │  RẢI dinh dưỡng / DỰNG công sự / ĐẶT ổ cấy    │  ← người chơi
        ▼                                               │
   khuẩn TỰ LỚN theo dinh dưỡng  ──►  colony to hơn      │
        │                               │               │
        │                               ▼               │
        │                    SINH KHỐI thu về nhiều hơn ─┘  (kinh tế cộng dồn)
        ▼
   footprint lớn  ──►  KẺ THÙ kéo tới (tỉ lệ với độ lớn)  ──►  THỦ / xây tiếp
```

Hai vòng lồng nhau: **vòng kinh tế** (khuẩn to → sinh khối nhiều → xây nhanh hơn → to
hơn, cảm giác cộng dồn kinh điển của city-builder) và **vòng áp lực** (to hơn → bị vây
nặng hơn, ép không được lớn ẩu). Bài học thật nằm ở vòng thứ hai: *nhiều hơn không phải
lúc nào cũng tốt hơn.*

---

## 4. Giải phẫu một màn — hai pha

**Pha 1 · Dựng (thong thả).** Có ngân sách sinh khối và bảng công cụ. Bạn đặt ổ cấy,
rải dinh dưỡng, dựng công sự — *quy hoạch* trước khi mọi thứ động.

**Pha 2 · Sống (động).** Colony lớn theo thời gian thật (engine CA lo). Sinh khối chảy
về theo độ lớn. Từ màn có threat trở đi: kẻ thù tới theo dòng thời gian, tỉ lệ với
footprint; bạn phản ứng bằng vài lượt xây có giới hạn.

**Thắng màn** = đạt *mục tiêu tăng trưởng* dưới *ràng buộc* (phủ X% / nuôi cụm tới đích
xa / trụ qua N đợt sóng / hồi sinh sau thảm họa). Thắng → **mở công cụ xây mới**
(roguelite = cây công nghệ).

---

## 5. Người chơi làm gì — bảng công cụ xây

Điểm mấu chốt của "city-builder cho vi sinh": **bạn xây *điều kiện và bộ khung*, khuẩn
tự lấp vào.** Không đặt từng con.

| Công cụ | Chức năng | Gốc sinh học |
|---|---|---|
| **Ổ cấy** | gieo một cụm khuẩn để nó lan ra | cấy giống (spot inoculation) |
| **Dinh dưỡng** | rải một vùng thức ăn; khuẩn lan *rất nhanh* vào đó | agar giàu dưỡng chất |
| **Tường biofilm** | công sự chắn phage / kháng sinh | matrix biofilm — *dung nạp*, không kháng |
| **Trụ độc (colicin)** | "trụ súng" tầm xa diệt chủng địch | tiết colicin khuếch tán |
| **Hầm bào tử** | ô ngủ đông sống qua thảm họa | tạo bào tử (*Bacillus*, KHÔNG phải E. coli) |

Roster này mở dần bằng thẻ → mỗi lượt chơi là một *lối xây* khác nhau.

---

## 6. Kinh tế — sinh khối cộng dồn

Một con số: **Sinh khối**. Thu về = nền cố định + (số ô khuẩn × hệ số). Càng nhiều
khuẩn thu càng nhanh → xây càng nhanh → khuẩn càng nhiều: đúng đường cong gây nghiện
của city-builder. Từ màn có threat, thu-chi này phải cân với chi phí phòng thủ.

---

## 7. Đa dạng nằm ở *chướng ngại* — 6 màn ví dụ

Cùng động từ, khác chướng ngại và khác điều kiện thắng (tránh "màn nào cũng lớn hơn"):

1. **Mảnh đất đầu** *(dạy: khuẩn lan từ ổ, dinh dưỡng = tăng trưởng)* — đất trống, không
   địch. Đặt ổ cấy, rải dinh dưỡng, phủ X%. **← đây là lát cắt đã dựng (mục 11).**
2. **Con suối cạn** *(dạy: giới hạn khuếch tán)* — thức ăn một góc, đích góc kia; phải
   dựng *đường dinh dưỡng* dẫn tới.
3. **Thủy triều phage** *(dạy: phage săn mồi, biofilm dung nạp)* — sóng phage dội theo
   chu kỳ, càng đông càng nặng; đừng dồn cục, dựng tường biofilm, chừa vùng trú.
4. **Mùa khô** *(dạy: bào tử, ngủ đông)* — môi trường khô kiệt giữa màn, chỉ hầm bào tử
   sống; rồi ẩm lại, mọc lại từ đó.
5. **Kẻ tranh đất** *(dạy: loại trừ cạnh tranh, chiến tranh colicin)* — chủng địch cũng
   lớn; dùng trụ độc + vị trí giành đất. Đây là chỗ vòng khắc chế 3 chủng vào cuộc.
6. **Ruột người** *(biome đặc biệt — dạy: viêm, kháng vs dung nạp)* — kẻ địch là miễn
   dịch + liều kháng sinh. Chủ đề kháng-thuốc thành một *vùng đất* mở khóa, không phải
   cái hộp nhốt cả game.

---

## 8. Mối đe dọa & phe (từ màn 3 trở đi)

- **Phage = "biter" tuyệt vời**: nhân lên *tỉ lệ với số khuẩn của bạn* → footprint chính
  là nhiên liệu của kẻ tấn công (cơ chế "pollution" của Factorio, nhưng có thật). Kháng
  phage được nhưng *trả giá* (chậm lại) → mở cây công nghệ.
- **Miễn dịch** (biome ruột): phe thứ ba tự hành, đánh cả bạn nếu Viêm cao — vòng phản
  đòn "viêm → oxy → nuôi địch".
- **Môi trường** (lớp `env`): khô/kháng sinh/pH đổi theo dòng thời gian màn.

---

## 9. Meta roguelite

Thắng màn → chọn 1 trong 3 thẻ **mở công cụ xây** (tường biofilm, trụ độc, hầm bào tử,
đường dinh dưỡng, kháng phage…). Cũng là dịp vá hai lỗi SAI khoa học của bản cũ: bỏ
"Bào tử dày" cho E. coli (chỉ dùng bào tử ở màn có chủng *Bacillus*), bỏ "Vi khuẩn Chúa"
→ "ổ cấy gốc".

---

## 10. Móc vào engine

Tái dùng gần như toàn bộ tầng vẽ; chỉ thay tầng *luật*.

- **Tái dùng nguyên**: `board.gd`, `dish.gdshader`, phép chiếu iso, `palette.gd`, và
  chính lớp `Sim` làm **kho lưới** (grid/hp `PackedByteArray`, `put`, `seed_circle`,
  `counts`, `ratio`). Board vẽ được bất kỳ Sim nào.
- **Thay tầng luật**: bỏ vòng RPS `Sim.step()`; viết **`GrowSim`** — luật lan theo dinh
  dưỡng + kinh tế sinh khối. Tách khỏi phần vẽ để test headless được (đúng kỷ luật
  Sim/Colony của game gốc).
- **Ánh xạ màu miễn phí**: mã ô `1` = khuẩn (mượn màu tím TOXIC), `2` = dinh dưỡng (màu
  vàng SENSITIVE), `4` = vách. Không cần shader mới cho prototype.
- **Về sau**: lớp `env` (mảng byte song song) cho môi trường; species mới cho phage
  (`PREDATOR`) và miễn dịch (`IMMUNE`).

---

## 11. Lộ trình — Màn 1 đã dựng

`godot/proto/` chứa lát cắt chơi được đầu tiên:

- `grow_sim.gd` — lõi luật (khuẩn lan theo dinh dưỡng, kinh tế sinh khối). Headless-test.
- `grow.gd` + `Grow.tscn` — nhập liệu + HUD + ráp Board.
- `check.gd` — test headless: khuẩn phải lan, phủ phải tăng.

Chạy: `./play.sh proto` (chơi) · `./play.sh proto-check` (test không cửa sổ).

**Việc của Màn 1 là trả lời đúng MỘT câu:** đặt ổ cấy + rải dinh dưỡng rồi *nhìn khuẩn
mọc lan có kiểm soát* — có "phê" không? Nếu có, đi tiếp cột mốc 2 (threat + phòng thủ).
Nếu nhạt, sửa cảm giác growth trước khi xây thêm bất cứ gì.

Cột mốc sau: 2) phage + tường biofilm (build-and-hold thật) · 3) kinh tế + cây công
nghệ · 4) đủ 6 màn + biome ruột.

---

## 12. Có thật / sáng tạo

| Chi tiết | Loại |
|---|---|
| Khuẩn lan theo dinh dưỡng (range expansion) | **CÓ THẬT** |
| Dinh dưỡng cục bộ quyết định tốc độ mọc | **CÓ THẬT** |
| Biofilm dung nạp kháng sinh (khác kháng thuốc) | **CÓ THẬT** |
| Phage nhân theo mật độ vật chủ | **CÓ THẬT** |
| Bào tử sống qua khô hạn (Bacillus) | **CÓ THẬT** |
| Colicin, vòng khắc chế 3 chủng | **CÓ THẬT** |
| "Sinh khối" một con số làm tiền tệ | **SÁNG TẠO** (tiện game) |
| Đặt công trình rời rạc như city-builder | **SÁNG TẠO** |

---

## 13. Còn mở

1. Palette "ruột/hoang dã" riêng hay giữ ba tone đĩa thạch?
2. Sau khi cảm Màn 1: threat đầu tiên là **phage** (hoang dã) hay **khô hạn** (dễ làm hơn)?
3. Có muốn preview bóng mờ chỗ sắp đặt (ghost cursor) không — hiện Màn 1 đặt thẳng.
</content>
