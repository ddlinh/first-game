# Chi tiết nào có thật, chi tiết nào là sáng tạo

Kiểm kê toàn bộ nội dung game, đối chiếu với tài liệu khoa học. Xếp thành bốn nhóm:
**CÓ THẬT** · **ĐƠN GIẢN HOÁ** (có thật nhưng game làm khác đi) · **SAI** (trái sự
thật, nên sửa) · **SÁNG TẠO** (thuần thiết kế, không đúng không sai).

Nguồn nằm ở cuối file. Chỗ nào chưa kiểm được thì ghi rõ là chưa kiểm, không suy đoán.

---

## 1. CÓ THẬT

### Vòng khắc chế ba chủng
Đây là hệ colicin của *E. coli*, có thật và nổi tiếng. Ba chủng thật là C
(colicinogenic — tiết colicin), S (sensitive — mẫn cảm), R (resistant — kháng), khớp
đúng Tiết độc / Nhạy cảm / Kháng độc trong game. Lý do khắc chế nhau cũng thật:

| Mũi | Cơ chế thật |
|---|---|
| C diệt S | colicin là độc tố protein, diệt tế bào mẫn cảm |
| S đè R | đột biến kháng làm hỏng protein vận chuyển (thụ thể BtuB, đường vitamin B12), R hấp thu dinh dưỡng kém hơn |
| R đè C | R không phải trả giá mang plasmid colicin và biểu hiện protein miễn nhiễm |

### Khuấy đĩa làm sập đa dạng sinh học
**Đây là kết quả trung tâm của bài Kerr 2002**, không phải một nút bấm nghĩ ra cho vui.
Nuôi ba chủng trên mặt thạch (phát tán cục bộ) thì cả ba cùng sống rất lâu; nuôi trong
bình lắc (trộn đều) thì hai chủng tuyệt chủng. Cơ chế "Khuấy đĩa" của game tái hiện
đúng phép so sánh đó.

### Sóng xoắn ốc và trần linh động
Reichenbach, Mobilia & Frey 2007: trên lưới, độ linh động vừa phải sinh sóng xoắn ốc;
vượt một ngưỡng thì xoáy nở to gần bằng hệ và một chủng chết. `tests/diag_pattern.gd`
đo lại được đúng hiện tượng đó mà lúc dò tôi chưa đọc bài nào — xem `Sim.mobility`.

### Địa hình chia ô và kênh hẹp
Chỗ này tôi từng nói sai là "thuần sáng tạo". Thực ra có kỹ thuật thật: người ta
**vi chế tạo (microfabrication) các mảng ô môi trường nối nhau bằng hành lang hẹp**
để mô phỏng môi trường sống vụn vặt của vi khuẩn, rồi đo ảnh hưởng lên quần thể. Tức
**Quần đảo** (đảo + cầu thạch) và **Thắt cổ chai** (khe hẹp) đều có tiền lệ thí nghiệm.

### Dòng chảy vi lưu
Có nghiên cứu thật về dòng chảy và dinh dưỡng định hình chính hệ ba chủng khắc chế này
(bioRxiv 2022). Tôi không dựng biến thể đó từ bài này — nó có sẵn trong tài liệu thiết
kế — nhưng nó không phải chuyện bịa.

### Hai kiểu cấy quân
**gieo đều** ≈ trải đều khắp mặt thạch (spread/lawn), **ba cứ điểm** ≈ nhỏ giọt thành
mấy cụm riêng (spot inoculation). Cả hai là kỹ thuật cấy chuẩn trong phòng thí nghiệm.

### "Kháng sinh phổ hẹp"
Tên thẻ này đúng thuật ngữ: colicin được gọi là *narrow-spectrum protein antibiotic*,
phổ hẹp vì chỉ diệt cùng loài/cùng chi. (Nói chặt thì colicin là **bacteriocin** và
bacteriocin chính thức không được xếp là antibiotic — nhưng cách gọi kia có trong y văn.)

---

## 2. ĐƠN GIẢN HOÁ — có thật nhưng game làm khác

### Diệt chỉ khi hai ô kề nhau
Game cho một ô diệt ô kề nó. Thật ra **colicin khuếch tán**: bán kính vùng ức chế quanh
một ổ tế bào sản xuất là **100–400 µm**, tức khoảng 100–400 lần chiều dài thân tế bào.
Loại "phải chạm mới giết" là hệ khác (CDI, T6SS), không phải colicin.

Hệ quả nhìn thấy được: game **không có halo** — vòng trong suốt quanh khuẩn lạc tiết
colicin, đường kính 1–15 mm, vốn là hình ảnh đặc trưng nhất của loại thí nghiệm này.
Nếu muốn game "trông giống đĩa thạch thật" hơn, đây là chi tiết đáng thêm nhất.

### Máu (2 / 1 / 5)
Colicin tuân theo **động học một-cú-chết (single-hit kinetics)**: về nguyên tắc một phân
tử colicin đủ giết một tế bào, và tỉ lệ sống là `S/S₀ = e^(−m)` với `m` là số phân tử
độc trung bình trên mỗi tế bào. Không có tài liệu nào mô tả tế bào tích lũy sát thương
rồi chết dần.

Nghĩa là thanh máu **không có gốc sinh học**. Biến đúng sinh học để thay nó là
`m` (liều tích lũy làm tăng *xác suất* chết), chứ không phải số phát chịu được. Trong
game, máu là thứ tài liệu thiết kế thêm vào cho Kháng độc "dày dặn" — và nó đã hai lần
làm lệch cân bằng, xem `Sim.HP_COMPENSATION`.

### Tiết độc ra đòn mà không mất gì
Trong game, ô Tiết độc diệt ô Nhạy cảm và vẫn nguyên vẹn. Thật ra colicin được phóng ra
bằng cách **tế bào sản xuất tự ly giải** — khoảng **3%** dân số tự sát để giải phóng độc
tố. Sản xuất vũ khí là hành vi tự huỷ vì tập thể. Đây là một cơ chế hay mà game bỏ mất.

### Nhịp sinh quân 1.0 : 3.0 : 1.6
**Không tìm thấy cơ sở nào cho tỉ lệ này.** Trong bài Kerr 2002, hai mũi "đè" là chênh
lệch *có ý nghĩa thống kê* nhưng không hề gấp mấy lần:

- R bị S đè: `t₅ = −5.78, P = 0.0022`
- C bị R đè: `t₅ = −3.62, P = 0.015`

Còn mũi thứ ba mới là cái tuyệt đối: S trộn với C thì **bị diệt sạch, độ thích nghi
tương đối bằng 0 ở cả năm lần lặp**.

Tức tài liệu thiết kế làm **ngược hình dạng của sự thật**: nó phóng đại chênh lệch sinh
sản lên gấp ba, rồi làm mềm cú giết bằng thanh máu — trong khi thực tế chênh lệch sinh
trưởng là nhỏ và cú giết là tuyệt đối.

Điều bất ngờ: lúc cân bằng game tôi phải **nén** tỉ lệ sinh sản từ `1 : 3.0 : 1.6` xuống
`1 : 1.45 : 1.13` vì bản gốc không giữ nổi thế cân bằng. Việc nén đó vô tình đẩy mô hình
**về gần sinh học hơn**, dù lý do lúc làm chỉ là cân bằng game.

### Tốc độ 0.62 / 1.16 / 0.55
**Chưa kiểm được.** Câu hỏi "ba chủng này có khác nhau về khả năng di động không" nằm ở
nhóm tra cứu bị ngắt giữa đường. Chưa có cơ sở để nói là thật hay bịa. Game dùng tỉ lệ
đã nén là `1 : 1.26 : 0.97`, tức gần như không phân biệt.

---

## 3. SAI — trái sự thật, nên sửa

### Thẻ "Bào tử dày"
***E. coli* không tạo bào tử.** Đây là vi khuẩn non-spore-forming, và đó là đặc điểm
phân loại chuẩn của loài. Bào tử là của *Bacillus* (B. subtilis, B. anthracis) và
*Clostridium* (C. difficile, C. tetani) — hầu hết là Gram dương.

Tên thay được mà vẫn giữ đúng ý "nhát cấy phủ rộng hơn": **"Cấy dày"**, **"Ống cấy
loe"**, hoặc **"Sinh khối đặc"**.

### "Vi khuẩn Chúa"
Vi khuẩn **không có cá thể chúa**. Chúa là khái niệm của côn trùng xã hội (ong, mối,
kiến). Mục tiêu Hộ tống mượn hình ảnh đó cho dễ hiểu, nhưng nó sai về sinh học.

Thay được bằng thứ có thật mà vẫn giữ nguyên cơ chế "một cụm ở tâm phải sống":
**"khuẩn lạc gốc"**, **"ổ cấy gốc"**, hoặc **"dòng thuần"** (pure culture) — đều là
khái niệm thật và đều đáng bảo vệ.

### (Trong tài liệu thiết kế, chưa vào game) "Tách đôi (mít-tơ-xít)"
Mục 2 tài liệu tả Nhạy cảm *"Tách đôi (mít-tơ-xít) nhân bản cực nhanh"*. Vi khuẩn
**không phân bào bằng mitosis** — chúng **phân đôi (binary fission)** nhờ vòng protein
FtsZ, không có nhân thật, không có thoi phân bào, không có các pha prophase/metaphase.
Từ đúng là **phân đôi**. E. coli phân đôi khoảng 20 phút một lần ở 37 °C.

Chỗ này chưa lọt vào game vì tôi không dựng phần lồng tiếng/mô tả trong trận, nhưng nếu
sau này viết chữ trong game thì đừng bê nguyên từ đó.

---

## 4. SÁNG TẠO — thuần thiết kế game

Không đúng không sai, chỉ là không có gốc thực tế:

- **Năm loại mục tiêu** (Chiếm đất, Sinh tồn, Cân bằng, Hoả tốc, Hộ tống) và mọi ngưỡng
  45% / 10% / 15% / 3%.
- **Toàn bộ 69 tổ hợp màn** — số học của mấy cái trục do người thiết kế chọn.
- **Thẻ nâng cấp**, cấu trúc roguelite 6–8 đĩa, chọn 1 trong 3.
- **Thế cờ Bao vây** và **Xoáy tử thần dựng sẵn** — hoa văn xoắn ốc thì có thật, nhưng
  "dựng sẵn hai xoáy ổn định ngay từ đầu" là dàn cảnh.
- **Hình họa chibi**: mắt to, mũ bảo hiểm, khiên, túi độc phập phồng. Vi khuẩn không có
  mắt, không đội mũ.
- **Mây độc khi cấy** — trong game mây bung ra lúc người chơi cấy quân; tài liệu định
  cho nó bung khi ô Tiết độc diệt ô địch ("áp sát nổ BỤP").
- **Lưới toroidal**, `CHURN 16.5` nhịp/ô/giây, cạnh lưới 180 — quy ước mô hình hoá.
- **Nhật ký chiến sự** và bốn hướng bắc/đông/nam/tây trên đĩa.

---

## 5. Không khớp nội bộ (không liên quan khoa học)

Thẻ **"Độc tố cô đặc"** ghi *"Chủng Tiết độc sinh sản nhanh hơn 30%"* — tên nói về độc
tính, tác dụng lại là tốc độ sinh sản. Nên đổi tên thành "Sinh sôi mạnh" hoặc đổi tác
dụng sang tăng xác suất ra đòn.

---

## Nguồn

- Kerr B, Riley MA, Feldman MW, Bohannan BJM. *Local dispersal promotes biodiversity in
  a real-life game of rock–paper–scissors.* **Nature** 418:171–174 (2002).
  <https://www.nature.com/articles/nature00823>
- Kerr B. *Evolution of Restraint in a Structured Rock–Paper–Scissors Community.*
  In the Light of Evolution, NCBI Bookshelf — số liệu `t₅` và "relative fitness = 0".
  <https://www.ncbi.nlm.nih.gov/books/NBK424869/>
- Reichenbach T, Mobilia M, Frey E. *Mobility promotes and jeopardizes biodiversity in
  rock–paper–scissors games.* **Nature** 448:1046–1049 (2007).
- Weber MF, Poxleitner G, Hebisch E, Frey E, Opitz M. *Chemical warfare and survival
  strategies in bacterial range expansions.* J R Soc Interface 11:20140172 (2014) —
  vùng ức chế 100–400 µm. <https://doi.org/10.1098/rsif.2014.0172>
- Cascales E, et al. *Colicin Biology.* Microbiol Mol Biol Rev (2007) — single-hit
  kinetics, ~3% tế bào ly giải, định nghĩa bacteriocin.
  <https://pmc.ncbi.nlm.nih.gov/articles/PMC1847374/>
- Mazurek-Popczyk J, et al. *Antibiotics* 9(7):411 (2020) — halo 1–15 mm.
  <https://pmc.ncbi.nlm.nih.gov/articles/PMC7400030/>
- *Bacterial Spores*, StatPearls/NCBI — *E. coli* không tạo bào tử.
  <https://www.ncbi.nlm.nih.gov/books/NBK556071/>
- *Prokaryotic Cell Division*, LibreTexts/OpenStax — binary fission, vòng FtsZ.
  <https://bio.libretexts.org/Bookshelves/Introductory_and_General_Biology/Concepts_in_Biology_(OpenStax)/06%3A_Reproduction_at_the_Cellular_Level/6.04%3A_Prokaryotic_Cell_Division>
- *Bacterial metapopulations in nanofabricated landscapes.* PNAS (2006) — mảng ô môi
  trường nối bằng hành lang. <https://www.pnas.org/doi/10.1073/pnas.0607971103>
- *Nutrients and flow shape the cyclic dominance games between Escherichia coli
  strains.* bioRxiv (2022).
  <https://www.biorxiv.org/content/10.1101/2022.08.15.504033.full.pdf>
