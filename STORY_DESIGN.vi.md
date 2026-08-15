<!--
  Bible câu chuyện / kịch bản / thiết kế lối chơi cho REKINDLED.
  Được tạo ra qua một quy trình thiết kế đa lăng kính (nhóm thiết kế nền tảng -> các
  người viết kịch bản đầu/giữa/cuối game -> một cuộc audit đặt khoa học lên trên hết
  và tính nhất quán thiết kế -> tổng hợp), bám sát bản build đang chạy và đối chiếu
  với từng phát hiện của cuộc audit.
  Xem VISION.md (pitch & pillars), GAME.md (nội dung đã ship), DESIGN.md
  (kiến trúc), PROGRESSION_DESIGN.md (EMBERGROWTH), VILLAGE_DESIGN.md, CRITIQUE.md.
-->

# REKINDLED — Câu Chuyện, Kịch Bản & Lịch Sử Phân Nhánh
### Một bible tường thuật & thiết kế lối chơi — đầu / giữa / cuối game, các lối chơi, những lịch sử mà người chơi viết nên, và co-op

*Được viết **trước** khi triển khai, để định hướng cho việc triển khai đó. Trong khi `VISION.md` bán ý tưởng,
`GAME.md` liệt kê những gì đã ship, và `PROGRESSION_DESIGN.md` đặc tả các hệ thống, **tài liệu này mô tả
một lượt chơi thực sự có cảm giác thế nào** — hình hài mà một phiên chơi mang lấy, những lựa chọn khiến thế giới
của người chơi này rẽ hướng khác với người chơi kia, và cách chơi solo lẫn co-op trải ra suốt toàn bộ vòng cung câu chuyện.*

*Last updated: 2026-08-14.*

---

## Cách đọc tài liệu này

REKINDLED đã chạy trọn vẹn từ đầu đến cuối; song phần lớn những gì nó *hứa hẹn* mới chỉ được ghi thành tài liệu chứ chưa được dựng.
Bible này mô tả **điểm đến** — nên nó cẩn trọng phân định rạch ròi phần nào bạn chơi được
hôm nay và phần nào thuộc lớp tầm nhìn. Ba ký hiệu mang theo sự trung thực đó trên mọi trang:

- **SHIPPED** — chơi được trong bản build hiện tại (EMBERGROWTH Phase 0, vòng đời của làng, một
  Warden, các rescue-attunement, cơ chế bank-or-forfeit).
- **⟢ VISION** — đã được ghi trong tài liệu thiết kế nhưng **chưa được dựng**. Được mô tả ở đây như mục tiêu,
  không bao giờ như thể nó đã có mặt. Phụ lục B là con đường đi từ cái nọ
  đến cái kia.
- **⚑** — một sự **phóng túng** khoa học hoặc lịch sử có chủ đích, được nêu công khai theo Pillar 2.
  Game dạy lịch sử thật và vật lý thật một cách trung thực, hoặc nó không nói gì cả.

Ngoài vòng cung đầu/giữa/cuối game, phiên bản này còn phác họa ba lớp ở quy mô thế giới: **Worldlines**
(§4 — cách một phát minh đầu tiên duy nhất lan tỏa thành cả một thế giới), các **Run Environment / biome**
mà bạn thực sự đi xuống (§5), và lớp **Bản Đồ Thế Giới & Bành Trướng** khâu chúng lại với nhau (§6).

Mọi đề xuất ở đây đều đã đi qua một **cuộc audit độ chính xác đặt khoa học lên trên hết** (quy tắc sắt của dự án)
và một **cuộc audit tính nhất quán thiết kế / khả năng dựng được**; những chỉnh sửa của chúng đã được nhào nặn vào bên trong, không phải chắp thêm.

## Luận đề mà toàn bộ tài liệu này phục vụ

> **Nền văn minh sống trong con người và tri thức, không phải trong chiến lợi phẩm.**

Một thanh tiến trình duy nhất — **GWI**, Global Warmth Index — cùng lúc gánh sức mạnh người chơi, sự lớn lên của làng,
sự tan băng trực quan, và cả thang phát minh (Pillar 3: *tiến trình = nhóm lại đốm lửa*). Mọi kịch bản,
lối chơi, kết thúc và luật co-op bên dưới đều uốn quay về câu ấy, và về hai người bạn đồng hành của nó:
**hoành tráng *đi cùng* thực chất** — một cơ chế cần tới tooltip mới đọc được trên màn hình thì chưa
xong (Pillar 1) — và **tri thức thật, dùng một cách trung thực** (Pillar 2). Cộng thêm ba điều giữ cho
vòng lặp sống: vòng lặp phải có **rủi ro thực** (đánh cược đi sâu hơn so với bank ngay bây giờ), **con người là
phần thưởng**, và **mỗi nhịp một lần ăn mừng**.

## Mục lục

1. Triết Lý Phân Nhánh — Cách Lựa Chọn Trở Thành Lịch Sử
2. Các Nguyên Mẫu Lối Chơi
3. Bóng Tối Trường Kỳ — Kẻ Phản Diện, Thế Giới & Cái Giá
4. Worldlines — Lựa Chọn Đầu Tiên Lan Tỏa Ra Sao
5. Môi Trường Của Run — Cái Lạnh Chiếm Mọi Hướng
6. Bản Đồ Thế Giới & Bành Trướng — RECLAIM, FEDERATE, hay ANNEX
7. Đầu Game — Đêm Ấm Đầu Tiên
8. Giữa Game — Vòng Lặp Trưởng Thành
9. Cuối Game — Tinh Thông & Lò Lửa Sâu Nhất
10. Các Kết Thúc & Thế Giới Được Nhóm Lại
11. Co-op — Hai Đốm Lửa, Một Lò Sưởi
- Phụ Lục A — Sổ Cái Khoa Học Trên Hết
- Phụ Lục B — Lộ Trình SHIPPED → VISION
- Phụ Lục C — Đặc Tả Hình Ảnh & Khả Năng Đọc Hiểu
- Phụ Lục D — Trợ Năng, Các Núm Tinh Chỉnh Mở & Bản Đồ Code

---


## 1. Triết Lý Phân Nhánh — Cách Lựa Chọn Trở Thành Lịch Sử

Hai người chơi khởi đầu với cùng một con mèo, cùng một Ember, cùng một khoảng rừng thưa lạnh giá — vậy mà mười giờ sau lại đứng trước hai khu định cư không thể nào lẫn vào nhau. Sự rẽ hướng đó không phải là kịch bản dựng sẵn. Nó rơi ra từ năm lựa chọn lặp đi lặp lại, mỗi lựa chọn để lại một **dấu ấn nhìn thấy được** lên thế giới: một đường chân trời khác, một trạng thái Codex khác, một hạt giống độ khó khác, một giọng nói Ember khác. Không có gì ở đây là ghi chép sổ sách trừu tượng — nhánh mà người chơi khắc ra được thiết kế để đọc thẳng khỏi màn hình mà không cần tooltip, trung thành với luận đề rằng **nền văn minh sống trong con người và tri thức, không phải trong chiến lợi phẩm.**

### Năm trục lựa chọn

| Trục | Lựa chọn | Cách thế giới rẽ hướng nhìn thấy được |
|---|---|---|
| **Người sống sót đầu tiên** | Nghề nào bạn giải phóng trước: Smith → **Forge / Metallurgy**; Farmer → **Crop Bed / Agriculture**; Builder → **Cabin / Construction** (và Carpenter's / Builder) | Bóng dáng công trình đầu tiên mọc lên, attunement đầu tiên được áp lại mỗi lần đi xuống, và đoạn độc thoại "hồi phục" đầu tiên của Ember. *(Thiên hướng ⟢ Heat-Mode + Kingdom của việc giải cứu thuộc lớp tầm nhìn — xem §2.)* |
| **Thứ tự phát minh** | Agriculture-first so với Metallurgy-first so với Construction-first | **Hình hài** của khu định cư — ruộng đồng, lò rèn, hay đại sảnh mọc trước — và những mục Codex nào lật từ khóa sang mở khóa, mỗi mục đóng dấu run đã hồi phục được nó |
| **Hung hãn so với bền vững** | Đẩy cổng **DEEPER** và tích trữ đầy túi so với bank sớm và bank thường xuyên | Bạn thực sự giữ lại được bao nhiêu chiến lợi phẩm so với **forfeit** trong bóng tối, và do đó thang phát minh của bạn tiến nhanh cỡ nào — lòng tham bank được lớn hoặc bank chẳng được gì |
| **Hình hài của làng** | Spam độc canh so với một đường chân trời đa dạng; lao vào tích ấm so với các chuỗi sản xuất | Đường chân trời theo đúng nghĩa đen: một trại một-nốt tua tủa so với một thị trấn đa dạng. Độ ấm leo *nhanh hơn khi đa dạng*, bởi run-effect **cap ở mức 3** và các công trình trùng lặp cho độ ấm giảm dần |
| **Khoan dung so với cướp bóc** | Giải cứu-hoàn thành so với dọn map nhanh lấy loot | **Dân số** trên màn hình (dân làng đi lại và làm việc) và các lần đi xuống của bạn bắt đầu ở đâu trên chuỗi diễn thế |

**Phát minh đầu tiên giờ đây gieo mầm còn hơn cả một đường chân trời — nó gieo cả một *worldline*,** một chuỗi lan tỏa của biome, biên cương, Warden và lực hấp dẫn kết thúc mà §4 lần theo từ đầu đến cuối. Mục này sở hữu phần *lựa chọn*; §4 sở hữu phần *lan tỏa*.

### Mô hình Soil — nơi lịch sử của bạn cho bạn được bắt đầu

Soil là giá trị meta bền vững gieo mầm cho *việc một lần đi xuống bắt đầu ở giai đoạn diễn thế nào* — Ash → Pioneer → Herb → Thicket → Canopy. Bởi kỳ băng giá kéo dài đã bào mòn bề mặt xuống tận nền khoáng chất trơ trọi, đây là **diễn thế nguyên sinh**: "Ash" đặt tên cho chính bề mặt khoáng chất bị cái lạnh bào mòn (các loài tiên phong cỡ địa y, không phải chất hữu cơ còn sót lại). ⚑ Diễn thế nguyên sinh thật kéo dài hàng thế kỷ; nén nó vào một lần đi xuống duy nhất là một sự phóng túng có chủ đích.

**Đã ship hôm nay:** `soil = clamp(gwi*0.6 + rescued*0.05, 0, 1)`. Vấn đề rất trung thực và đáng nêu ra: GWI và Soil trở thành gần như **cùng một số hạng**, nên Soil hầu như không thể tách biệt khoan dung khỏi cướp bóc, và nó không bao giờ tạo ra được trường hợp thú vị — một thế giới mà lựa chọn của nó lẽ ra phải đọc khác với độ ấm của nó.

**Đề xuất (một thay đổi được nêu cờ so với bản đã ship):** cân lại trọng số Soil để nó bị chi phối bởi **số lượng được giải cứu và độ đa dạng của làng**, với GWI chỉ là một số hạng phụ. Trọng số chính xác còn để ngỏ. Điểm mấu chốt là hai thứ mà luận đề quan tâm — con người và tri thức — dẫn dắt nơi bạn bắt đầu, để rằng:

- Một thế giới **khoan dung, đa dạng** thực sự bắt đầu *muộn hơn dọc theo chuỗi diễn thế* (một giai đoạn seral cao hơn), lịch sử của nó theo đúng nghĩa đen dễ bước vào lại hơn.
- Một thế giới **lạnh giá, bị cướp bóc** thực sự bắt đầu **thô sơ** ở Ash/Pioneer — và đường chân trời của nó cũng thực sự lạnh. Không có trạng thái "đường chân trời ấm nhưng Soil thô": tích trữ chiến lợi phẩm không làm tan băng thế giới, nên một thế giới tham lam vốn là thế giới độ ấm thấp theo cấu tạo, chứ không phải một tai nạn sổ sách.

Gieo một run tới giai đoạn N không bao giờ là hình phạt cho việc bỏ qua chặng leo: bạn nhận **các bước chỉ số phẳng của giai đoạn 1..N và một lượt bốc boon đầu run** cho những Bloom mà bạn đã nhảy vượt qua — khởi đầu ấm là một lợi thế đi trước, không bao giờ là một khoản thiếu hụt boon.

### Các kênh dễ đọc — cho người chơi thấy lịch sử mà họ đang viết

Theo Pillar 1 (hoành tráng *đi cùng* thực chất), mọi nhánh đều được hiển thị trên những kênh luôn-bật mà mỗi kênh đều đọc được trên màn hình:

- **Cấp độ ấm (GWI, thanh chủ).** Tín hiệu vang dội nhất. Khi nó dâng lên, ánh sáng môi trường ấm dần về sắc giờ vàng, đống lửa lớn lên, những cây chết đâm chồi. Bạn *thấy* lịch sử tổng gộp của mình trên bầu trời trước khi đọc một con số — và spam độc canh làm nó khựng lại một cách nhìn thấy được (cap-ở-3, độ ấm giảm dần), nên chính đường chân trời dạy cho bạn "đa dạng thắng spam."
- **Bóng dáng của làng.** Vòng đời công trình (Dormant → Blueprint → Operational → Upgraded) cộng với khoảng rừng thưa có thể mở rộng biến khu định cư thành một **bản lý lịch đọc được** — lò rèn so với ruộng đồng so với đại sảnh, dân số đông đúc so với thưa thớt, một vòng so với ba vòng. Forge-Lit Warren và Green Terrace được phân biệt chỉ trong một cái liếc từ lò sưởi. ⟢ **VISION — lớp cá nhân hoá.** Một lớp *thể hiện bản thân* của người chơi qua quy hoạch-và-trang-trí (quy hoạch: xoay công trình, đường đi, adjacency mềm; cộng một catalog **trang trí GWI-trung-tính, mở khoá theo craft**) được thiết kế để nằm *bên trên* bóng dáng này mà không làm méo nó: bản lý lịch chức năng vẫn đọc được trong một cái liếc, người chơi chỉ đơn giản làm cho thị trấn *rõ ràng là của họ*, và vì trang trí được kiếm từ các craft đã thắp lại nên ngay cả phần "dặm vá" cũng vẫn là một ghi chép trung thực. Đặc tả đầy đủ: `VILLAGE_DESIGN.md` §6.
- **Codex (bấm K, "ký ức của Ember").** Codex được **hiển thị xếp theo mức độ tác động** — cùng một trật tự cố định, trung thực cho mọi người chơi, phát minh làm thay đổi thế giới nhiều nhất đứng trước, mỗi sự phóng túng đều được nêu cờ. Lịch sử hồi phục là một **kênh riêng**: trạng thái khóa/mở khóa của một mục cộng với dấu "hồi phục ở run N." Cái rẽ hướng giữa các thế giới do đó là *những mục nào được thắp sáng và chúng được kiếm về khi nào* — không bao giờ là vị trí trong danh sách. Độ hoàn chỉnh của Codex là lịch sử tri thức mà số đếm chiến lợi phẩm không bao giờ nắm bắt được.
- **Giọng nói cột mốc của Ember.** Một câu phản ứng mỗi nhịp — lần đầu giải cứu một nghề, lần đầu Bloom vào một giai đoạn seral mới, vượt qua một ngưỡng độ ấm — ăn mừng đúng **một điều mỗi nhịp** và luôn tôn vinh "được mang theo, không phải cướp về." Nhánh được nói lên, chứ không chỉ được đếm.

*(Các bổ sung được đề xuất theo cùng tinh thần: một câu tiêu-đề-giai-đoạn của Ember khi đi xuống — ví dụ "Bạn tỉnh dậy đã ở trong thicket; làng của bạn đã mua mảnh đất này cho bạn" — để hạt giống Soil đọc ra như lịch sử được kiếm về thay vì một buff câm lặng; và một danh-hiệu-thế-giới tự sinh được đóng dấu lên màn hình tiêu đề/tạm dừng, một cái tên duy nhất đọc được cho lịch sử mà người chơi đã viết.)*

### Ba thế giới điển hình, nhìn thoáng qua

Mười giờ vào cuộc, các trục lựa chọn ở trên phân giải thành những thế giới có thể nhận ra được. Mỗi thế giới được kịch bản hóa đầy đủ — đường chân trời, trạng thái Codex, hạt giống độ khó, giọng Ember — như một cảnh nhỏ trong **§8 (Giữa Game)**, mái nhà tường thuật duy nhất của chúng; ở đây chúng chỉ là một chú giải để đọc một hearth-view thoáng qua:

| Thế giới | Nguyên mẫu / lực hấp dẫn | Dấu hiệu đường chân trời nhìn-thoáng |
|---|---|---|
| **The Forge-Lit Warren** | Bright Predator / cướp bóc | Lò rèn và khói chen chúc một khoảng rừng thưa — nhưng bầu trời vẫn **lạnh**, Soil vẫn thô, các lần đi xuống cứ bắt đầu ở Ash/Pioneer |
| **The Green Terrace** | Slow Bloom / khoan dung | Ruộng bậc thang, một vựa lúa, cây đâm chồi và cả chục dân làng đang làm việc — sáng sủa, tan băng nửa chừng, đồng quê |
| **The Hearth-Keep** | Hearthkeeper / người canh giữ | Những căn cabin vòm cao vây quanh một đống lửa quá khổ, khoảng rừng thưa mở rộng ra ngoài hai vòng — độ ấm cao và *ổn định* |

Cùng một game, ba đường chân trời, ba trạng thái Codex, ba hạt giống độ khó, ba giọng Ember — mỗi thứ là một bản ghi trung thực về điều mà người chơi của nó đã chọn để ghi nhớ. Xem §8 để có bản kịch bản hóa đầy đủ và §4 để biết mỗi phát minh đầu tiên lan tỏa thành worldline của nó ra sao.
## 2. Các Nguyên Mẫu Lối Chơi

Sáu viễn tưởng lối chơi **nảy sinh từ chính các hệ thống**, chứ không phải từ lớp vỏ hình thức. Mỗi nguyên mẫu là một trọng tâm thực sự nằm dọc theo cùng những cặp căng thẳng mà các trục phân nhánh đã mô tả: tham lam↔bền vững, chiến đấu↔xây dựng, đơn độc↔bảo hộ, độc canh↔đa năng, nhân từ↔cướp bóc.

> **⟢ Dấu VISION.** Heat **Modes** (Blaze / Sear / Draft), **Kingdoms** (Flora / Fauna / Fungi), **Husk Families** (Bramble / Beast / Slag + trạng thái độ sâu Frost-Encased), và ma trận **Mode × Family** là *lớp vision đã được ghi chép* — đã thiết kế, chưa dựng. Cái **đã ship hôm nay** là bộ kỹ năng chiến đấu Kindled Claws, bản draft kế thừa Bloom/boon, ba **attunements** cứu hộ (Bramble Ward +2 HP / Flora; Ember Fang +25% dmg / Thermal; Gale Step +25% spd / Wind), các công trình trong làng, Soil, GWI, và Codex. Mỗi nguyên mẫu bên dưới được tách theo đúng ranh giới đó.

**Ba quy tắc chi phối mọi nguyên mẫu bên dưới. Chúng cư ngụ ở đây như ngôi nhà chính thức của mình; các nguyên mẫu chỉ trỏ ngược về chúng.**

- **Quy tắc tách rời (decouple).** Heat **Modes hoán đổi giữa chừng run và tại Rest-Hearths**, trong khi một **Kingdom là một bản sắc boon-pool cố định suốt run**, chỉ đơn thuần *thiên lệch* về phía người sống sót mà bạn đã cứu. Sau các cuộc cứu hộ tương ứng, Mode và Kingdom **tách rời**, nên những cặp chéo như **Sear+Fauna** hay **Draft+Flora** là những build hoàn toàn hợp lệ, có chủ đích — không phải tai nạn.
- **Quy tắc attunement không chồng chất.** Attunements **không** chồng chất vô hạn — mỗi nguyên tố chỉ một attunement có ý nghĩa với hiệu suất giảm dần mạnh (hoặc một mức trần nhỏ), phản chiếu kỷ luật cap-of-3 của các công trình. Vì vậy độ bền đến từ **Cabin → Construction các tier +MaxHP**, *chứ không* từ việc spam +2 HP Bramble Wards. Điều này bảo toàn cái giá **glass-cat 6-HP**: Construction nâng lượng máu qua vài tier có chủ đích; không bao giờ có một con mèo 20-HP.
- **Quy tắc cap-of-3 / đa dạng.** Các hiệu ứng theo run **trần ở mức 3** và công trình trùng lặp cho warmth giảm dần, nên một đường chân trời đa dạng thực sự thắng lối spam độc canh. Toán học về làng của mọi nguyên mẫu đều tuân theo quy tắc này.

| Nguyên mẫu | Viễn tưởng một dòng | ⟢ Heat Mode | ⟢ Kingdom | Xương sống làng (đã ship) | Căng thẳng |
|---|---|---|---|---|---|
| **The Bright Predator** | Cháy nóng nhất, ký gửi cuối cùng | Sear | Fauna | Forge (Metallurgy) | Tham lam / sâu |
| **The Slow Bloom** | Không bao giờ hẳn chết | Draft | Flora | Crop Bed (Agriculture) | Bền vững |
| **The Hearthkeeper** | Đưa tất cả về nhà | Sear | Flora | Cabin (Construction) | Thận trọng / nhân từ |
| **The Kindler** | Đúng lửa, đúng địch | *hoán tất* | *thiên lệch, hoán* | Carpenter's (Builder) | Thích ứng |
| **The Rot-Reaper** | Nuôi đất, nuôi run | Draft | Fungi | hỗn hợp, nuôi bằng Soil | Tốc độ / cướp bóc |
| **The Archivist** | Sưởi ấm thế giới bằng cách hiểu nó | *bất kỳ* | Flora | rộng nhất, đa dạng | Ký gửi sớm |

### The Bright Predator — *pháo thủ giòn tham lam*

**Đã ship hôm nay:** cách chơi hung hãn của bộ kỹ năng Kindled Claws — combo 3 đòn dẫn vào đòn kết "Can Quet" 360, ~22% crit, dash lăn i-frame xuyên qua husks, pounce. Dựa vào **một** attunement Ember Fang (+25% dmg / Thermal) và một ngôi làng nặng về Forge để có **+damage** cố định, đẩy Blooms lấy các bước tăng chỉ số và boon tấn công, luôn chọn cổng **DEEPER**, tích trữ đầy túi, ký gửi tại hearth cuối cùng có thể. Đây là **tham-lam-chiến-đấu**: bạn *đấu tay đôi với đám đông* để giành cái túi ký gửi lớn nhất — nơi Rot-Reaper cướp bóc một nền kinh tế và không bao giờ đấu tay đôi, thì toàn bộ điểm số của Predator chính là trận đấu. Đám đông tan chảy *nếu* bạn cứ vung đòn, và một pha đọc sai **red-danger-zone** khi còn 6 HP nghĩa là bạn gục trong bóng tối và **mất trắng** cái túi.

**⟢ Vision:** các stack crit-và-hào-quang-bức-xạ của Sear kết hợp với bonus-damage-vs-low-HP, hút máu, và tốc-độ-khi-hạ-gục theo đà bầy đàn của Fauna — Sear (một Radiation Mode) chồng lên Fauna (Kingdom của Smith) là một **cặp chéo**, hợp lệ một khi Mode và Kingdom tách rời sau cuộc cứu hộ (quy tắc tách rời, §2 ở trên). ⚑ "đà bầy đàn" là một lớp diễn giải hành vi dựa trên sinh thái động vật săn mồi.

**Về Wardens:** Predator **không** cày Wardens để lấy GWI — một Warden lụi tàn rồi tắt, nó không bao giờ là chiến lợi phẩm hay XP tái tạo được (quy tắc nằm ở §3). Warmth của Predator đến từ **lợi tức đã ký gửi** trên những run nhanh, sâu; viễn tưởng là ký gửi cái túi lớn nhất của run sâu nhất, đối mặt với mối đe dọa thường trực mất trắng tất cả.

### The Slow Bloom — *người sinh tồn tiêu hao*

**Đã ship hôm nay:** lối chơi không-bao-giờ-hẳn-chết — dòng **Crop Bed → Agriculture** cho phép bạn mang một **Provision heal-charge** vào run; bạn ký gửi sớm và thường xuyên, gặm dần bằng combo, và lấy các boon Bloom phòng thủ. **Một** attunement Bramble Ward (+2 HP / Flora) đi theo mỗi lần xuống sâu — có trần, không spam (quy tắc không chồng chất, §2). Trần sát thương bùng nổ thấp, gần như không chết.

**⟢ Vision:** khả năng hồi phục trong ánh sáng của Ember của Flora cộng với rễ quấn và gai, kết hôn với đòn kết luồng-khí-bốc-lên của Draft kéo các husk nhẹ vào để AoE an toàn — Draft chồng lên Flora (Kingdom của Builder) là một **cặp chéo**, hợp lệ qua tách rời. Sức mạnh thực sự mang tính hệ thống: một lịch sử nhân từ, đa dạng nuôi Soil, nên mỗi lần xuống sâu **bắt đầu từ vị trí xa hơn trong chuỗi kế tiếp sinh thái** ngay từ đầu — điểm mạnh của Slow Bloom là *khởi đầu ấm áp*, chứ không phải bất kỳ run anh hùng đơn lẻ nào.

### The Hearthkeeper — *người bảo hộ / kẻ hoàn thành cứu hộ*

**Đã ship hôm nay:** **bản sắc sinh tồn** — phòng thủ thiên về parry trên khung **Cabin → Construction (tier +Max HP)**, nên một lượng máu đo lường được, giành qua từng tier, và một thanh guard khỏe mạnh cho phép bạn **đứng ở tiền tuyến và lấy thân chắn đòn** cho một người sống sót phía sau. Đòn choáng perfect-parry và đòn phản công crit-đảm-bảo tồn tại để *giữ đất*, không phải để đấu tay đôi giành chiến lợi phẩm. Ưu tiên các phòng **Rescue**; mỗi người sống sót được giải thoát sẽ ký gửi ngay khoảnh khắc bạn giải thoát họ và trao **một** attunement vĩnh viễn. Bạn dọn theo nhịp của người sống sót, không phải nhịp của bạn — ở đây **nhân từ là bảo hộ**, một tấm khiên ném lên che chở những người bạn cưu mang. Độ bền của nó là các **tier +MaxHP Construction** trong quy tắc không chồng chất của §2, không bao giờ là các ward chồng chất: một lượng máu đo lường được, vẫn là một con mèo giòn ở mức nền.

**⟢ Vision:** Sear+Flora — cặp Radiation+Flora *bản địa* của Builder (không cần tách rời), với gai trừng phạt bất cứ thứ gì chạm tới người phía sau bạn. Mode vẫn hoán đổi tại Rest-Hearths nếu một phòng đòi hỏi.

### The Kindler — *người phối hợp thích ứng*

**Đã ship hôm nay:** kẻ đọc trận — dash i-frame, perfect parry, pounce, và một bản draft boon được hoạch định lại mỗi Bloom cho hợp với phòng ngay trước mặt bạn. Một ngôi làng **Carpenter's → Builder** tăng tốc các mở khóa công trình mà cả bộ kỹ năng đầy đủ phụ thuộc vào. Ngay cả khi không có lớp Mode, Kindler là người chơi coi *mọi* telegraph là một câu đố.

**⟢ Vision:** nguyên mẫu duy nhất sống trong **ma trận Mode × Family**, hoán đổi Heat Modes giữa chừng run và tại Rest-Hearths để khắc chế thứ mà một husk *được cấu tạo từ* (family) một cách độc lập với cách nó *tấn công* (hành vi — những cái này ghép hợp với nhau):

- **Blaze** để thắp cháy nhiên liệu khô của một husk **Bramble** — một Bramble Charger telegraph cú lao của nó và bắt lửa khi tiếp xúc.
- **Draft** để đun bay hơi độ ẩm của một husk **Beast** vượt qua ngưỡng ẩm của nó, rồi **Firestorm** (Draft cấp oxy) để tự lan.
- Các husk **Slag** gần như là đá trơ (~0 kindle): bạn *tiêu tốn* nhiệt để làm nứt chúng — một Slag Bomber phải được **làm nứt trước khi có thể cho nổ**.
- **Sear** để **tăng tốc** giai đoạn làm ấm sensible-heat của một husk **Frost-Encased** (có cơ sở: băng và nước hấp thụ hồng ngoại rất mạnh) — một Frost-Encased Lobber phải được rã đông trước khi cú ném vòng cung của nó đáp xuống. Sear **không** bỏ qua bình nguyên latent-heat cố định của quá trình tan chảy; đối với Slag và giáp, lợi thế của nó là *truyền nhiệt mà không phải sống sót qua tiếp xúc cận chiến* (⚑ một phép ẩn dụ, không phải "xuyên giáp").

Bởi vì Sear chỉ tăng tốc chứ không bao giờ vượt qua bình nguyên tan chảy, Kindler giữ được một lợi thế Frost-Encased thực sự qua các **chuỗi Thermal-Shock đa-mode**. Thermal Shock ở đây là một **vết nứt do gia nhiệt nhanh chỉ bằng lửa**: một gradient nhiệt dốc đứng dồn vào một khối rắn lạnh, giòn → giãn nở chênh lệch → nứt. ⚑ Điều này là thật, nhưng thermal shock cổ điển thường cần một pha **làm nguội/tôi nhanh** mà bộ kỹ năng chỉ-lửa không có; điểm neo lịch sử trung thực là **fire-setting** — nung đá, rồi tôi nó bằng nước để tách đá (từ Đồ Đá Cũ đến khai mỏ La Mã). Không bao giờ "nung rồi làm nguội" cho bộ kỹ năng lửa. ⚑ Ba mode truyền nhiệt là vật lý thật; coi chúng như các *loadout* hoán đổi được là quyền tự do sáng tạo của game.

### The Rot-Reaper — *nhà kinh tế cướp bóc*

**Đã ship hôm nay:** **nền kinh tế** nhanh — dọn phòng chóng vánh (dựa vào **một** attunement Gale Step +25% spd / Wind, có trần theo §2), biến việc hạ gục thành nguyên liệu, chuyển nguyên liệu về nhà, ngắm Soil leo lên, khởi đầu lần xuống sâu tiếp theo ở vị trí cao hơn. Bạn đang cày một nền kinh tế, **không đấu tay đôi** — nơi điểm số của Bright Predator là trận đấu, thì điểm số của Rot-Reaper là thông lượng: dọn nhanh, hạ gục → nguyên liệu/Soil, run tiếp cao hơn.

**⟢ Vision:** một nền độc canh Fungi — các husk bị nhiễm **rơi nhiều nguyên liệu hơn và nuôi Soil**, và chuỗi **rhizomorph** Armillaria lan sự thối rữa từ husk sang husk. Draft+Fungi là cặp Convection+Fungi **bản địa** của Farmer, nên không cần tách rời, dù Mode vẫn hoán đổi để đối phó một family cứng đầu. ⚑ Sinh vật phân hủy trả dưỡng chất về đất là sinh thái thật; nén nó thành một loại tiền tệ là quyền tự do sáng tạo. Luận điểm là áp lực phản kháng cài sẵn: dưới mô hình Soil được đề xuất, warmth tưởng thưởng cho **người được cứu và sự đa dạng của làng**, chứ không phải chiến lợi phẩm thô, nên thế giới của một kẻ cướp bóc thuần túy vẫn **lạnh và Soil của nó chững lại** cho tới khi họ cũng giải thoát người sống sót — vòng lặp từ chối để riêng cướp bóc chiến thắng.

### The Archivist — *kiến trúc sư của nền văn minh*

**Đã ship hôm nay:** **bản sắc hoàn thành** — ngôi làng *chính là* build. Bạn **ký gửi sớm** để tiếp tục đẩy tiến bậc thang phát minh, xây **rộng** (kỷ luật cap-of-3, §2), phục hồi các phát minh một cách có chủ đích, và đọc **GWI** — sự tan băng mờ ảo, ngọn lửa trại lớn dần, cây cối đâm chồi nảy lá — như điểm số. **Chiến đấu là bảo trì**, một việc vặt giữa các phòng chứ không phải mục đích; ở đây **nhân từ là Codex** — mỗi người sống sót là một mục nữa được thắp sáng, và bạn theo dõi tiến độ của chính mình qua các **dấu recovered-on-run** của Codex trong khi danh sách vẫn được xếp hạng theo impact cho mọi người. Archivist **kết thúc gần GWI 1.0 nhất** trong mọi lối chơi.

**⟢ Vision:** **bất kỳ Heat Mode nào như một lựa chọn mặc định an toàn** — Archivist không có nguyên tố đặc trưng và cũng không cần một cái; bất cứ thứ gì phòng đòi hỏi, vì trận đấu là bảo trì, không phải bản sắc. Kết thúc gần **GWI 1.0 và phần kết** nhất, với Codex đầy đặn nhất và ngôi làng dễ đọc, tựa truyện tranh nhất trong mọi lối chơi — bằng chứng rõ ràng nhất rằng warmth là một bản ghi những gì bạn chọn để nhớ, không phải những gì bạn mang ra được.


---

## 3. Bóng Tối Trường Kỳ — Kẻ Phản Diện, Thế Giới & Cái Giá

*Kẻ thù là entropy — sự mất mát chậm rãi, hợp quy luật của mọi gradient mà kẻ sống từng duy trì — và sự quên lãng là hình thức của entropy trong một tâm trí. Không có gì ở đây trao cho cái lạnh một kế hoạch. Nó chỉ trao cho cái lạnh một khuôn mặt ở nơi hư cấu đã tự mình xứng đáng có một cái: tại những lò sưởi mà người ta để tắt.*

### Cung Bậc Kẻ Phản Diện — Entropy Học Được Một Hình Dạng

Bóng Tối Trường Kỳ không thể leo thang theo cách một kẻ ác leo thang, vì nó chẳng muốn gì cả. Thứ leo thang thay vào đó là **khả năng đọc hiểu nó của bạn** — game dạy bạn nhìn thấy cùng một quá trình lãnh đạm ấy ở ba độ sâu của tính dễ đọc.

**Sớm — cái lạnh là bối cảnh và câm lặng.** Ở những lần xuống sâu đầu tiên hoàn toàn không có kẻ phản diện nào trên màn hình, và đó chính là điểm mấu chốt. Husks lao tới không hằn học; chúng rỗng, không thù địch — thứ thừa lại của lửa, đang lụi tàn theo cách mọi thứ không được sưởi ấm đều lụi tàn. Mối đe dọa là *điều kiện*: ánh sáng xanh lạnh, sàn nhà phủ sương giá, Ember lụi tàn nếu con mèo đứng quá lâu trong bóng tối. "Tiếng nói" duy nhất của cái lạnh là sự vắng mặt — những căn phòng từng là tổ ấm, nay lặng câm. *Đọc trên màn hình:* không thanh máu, không telegraph — chỉ một thanh sáng đang tụt và hơi thở đọng sương trong không khí tĩnh lặng. Đây là entropy như hầu hết người ta gặp nó: không phải một cuộc tấn công, chỉ là một nhiệt độ.

**Giữa — những phế tích bắt đầu nhớ lại chúng từng là ai, và cái lạnh cũng vậy.** Khi run phân nhánh xuống sâu hơn, những mảnh vụn môi trường ngừng là phông nền và bắt đầu là *lời chứng* — những vạch đếm dừng lại ở bốn mươi mốt, khung cửi với con thoi vẫn còn trong đó, quyển sổ cái đi từ lúa → củi → chỉ còn những cái tên. Husks ở đây khoác *hình dạng của nghề nghiệp mình*: một husk-đưa-thư vẫn đi tuyến của nó, một husk-thợ-dệt vẫn làm việc trên khung cửi trống cho tới khi bạn quấy rối nó. Cái lạnh không sáng tác ra điều này. Nó chỉ đơn thuần bảo tồn một rãnh mòn được tạo bởi sự lặp lại — một khuôn mẫu sống lâu hơn ý nghĩa của mình. **Đây là cốt lõi trung thực của "cái lạnh học được một hình dạng":** một Warden không phải một tâm trí mà bóng tối nuôi lớn. Nó là một **trạng thái phân rã siêu bền, tự duy trì — một cấu hình bị giữ khỏi việc tái sắp xếp bởi sự vắng mặt của dòng năng-lượng-tự-do đi qua** — một vòng lặp hành vi mòn rãnh sâu đến mức nó vẫn tiếp tục quay sau khi con người bên trong nó đã tắt. ⚑ *Entropy thật không có ký ức; ta mượn ý tưởng đúng rằng một số trạng thái phân rã là tự duy trì và khó đảo ngược do thiếu dòng năng lượng, rồi kịch tính hóa nó thành "cái lạnh học được cách giữ tư thế này" (vật lý đầy đủ → App A).*

**Cuối — lò sưởi đầu tiên từng bị để tắt.** Phế tích sâu nhất là phế tích *cổ nhất*: nơi mà, trước khi có một ngôi làng để mà quên, ngọn lửa được chăm sóc đầu tiên đã nguội lạnh trong một đêm không người trông. Mọi thứ ở trên đều là tiếng vọng của lần sơ sẩy đầu tiên ấy. Chạm tới nó là lúc game thừa nhận kẻ phản diện xưa nay luôn là gì — không phải một con boss ở đáy hầm ngục, mà là **cội nguồn của sự bỏ mặc**, bàn tay đầu tiên đã không truyền được ngọn lửa.

### Các Warden — Một Khuôn Mặt Lụi Tàn, Không Bao Giờ Chảy Máu

Một Warden là cái lạnh được trao cho *bóng dáng của một nghề đã mất*. Nó nhất quyết không phải một con thú: **đánh nó và nó không chảy máu — nó lụi tàn, mờ đi, và tắt như một ngọn lửa thiếu không khí.** Thanh của nó không phải máu; đó là *bao nhiêu cái lạnh đang giữ cho hình dạng đứng vững*. Bạn không giết nó; bạn **thắp lại thứ nó đang canh giữ**, và cái hình dạng ấy không còn lý do gì để đứng nữa. *Đọc trên màn hình:* mỗi cú đánh làm nó mờ đi một sắc thay vì đỏ lên; ở mức không, nó sụp thành một quầng sáng ấm áp, lắng lại, chứ không phải một cái xác.

**Hành vi × family cũng ghép hợp ở đây (⟢ VISION).** Một Warden là một *hành vi* (tư thế boss trong danh sách: Husk / Charger / Lobber / Bomber / Warden) và — trong lớp vật liệu VISION — cũng được làm từ *một thứ gì đó* (Bramble / Beast / Slag, với Frost-Encased là một trạng thái độ sâu). Các trục vuông góc và chồng chất: một **Bramble Charger** *bắt lửa* khi tiếp xúc Blaze/Conduction; một **Slag Bomber** phải được **làm nứt** bằng nhiệt trước khi vòng cảm tử của nó có thể cho nổ; một **Frost-Encased Lobber** phải được **rã đông** trước khi cú nổ vòng cung của nó đáp xuống. Một Warden-nghề thừa hưởng cùng ngữ pháp đó — một smith-Warden thân Slag phải được làm nứt bằng nhiệt trước khi hình dạng của nó chịu khuất phục — nên các trận boss đọc ra như ngữ pháp kẻ thù được đưa lên tầm cỡ lớn, không bao giờ là một bộ luật mới.

> **Cái gì ship vs. cái gì là VISION.** Game **SHIPPED** có **một Warden chung** — một phòng-Warden trong **Buried Warren** (lần xuống sâu Construction, §5) tái diễn như cấu trúc roguelite thông thường; bản sắc VISION của nó là **The Unfinished Arch**. **Bốn craft-Wardens** và **First Warden** bên dưới, cùng với Husk Families và các biome sâu, là lớp ⟢ **VISION** đã được ghi chép, không có trong build.

**Các craft-Warden một-lần (⟢ VISION).** Lớp vision đặt một Warden mỗi biên cương, mỗi con là kẻ canh giữ một nghề bị lãng quên cụ thể — một khuôn mặt cho kẻ phản diện mà không có cá tính, và bậc thang phát minh được làm cho dễ đọc *dưới dạng chiến đấu*. Danh sách tăng lên bốn craft-Wardens cộng điểm cuối sâu nhất:

| Warden (⟢ VISION) | Biên cương / biome (§5) | Nghề nó canh giữ (Codex) | Mảnh vụn trung thực dưới chân nó |
|---|---|---|---|
| **The Unfinished Arch** | **Buried Warren** — DOWN *(lần xuống sâu đã ship)* | Construction | Một chiếc nôi đung đưa dừng lại dưới một viên đá đỉnh vòm đang oằn xuống |
| **The Cold-Struck Smith** | **Glaciated Spire** — UP, lò rèn trên đỉnh | Metallurgy | Một xưởng đầy công cụ làm dở |
| **The Keeper of the Empty Rows** | **Frostmarch Tundra** — OUT, những cánh đồng bị vùi | Agriculture | Những hũ hạt giống vét sạch; một kho lẫm phủ sương giá |
| **The Last Wright** | **Ashen Wald** — ACROSS | Woodcraft *(gộp vào nghề Carpenter's/Builder — không phải một dòng phát minh độc lập)* | Một khung nhà dựng dở, các mối nối chưa bao giờ đóng chốt |
| **The First Warden** | **First Hearth** — điểm cuối sâu nhất mà mọi worldline hội tụ về | *bản thân việc gìn giữ lửa* | Một lò sưởi đã xếp mồi, chờ một tia lửa không bao giờ đến |

**Drowned Coast** (biển đóng băng) **không** có craft-Warden nào — nó là con đường mở rộng chung (§6); một Salt-Keeper→Preservation tùy chọn ở đó là ⟢ VISION.

Các craft-Warden này là **những lần thắp lại một-lần**, không phải con mồi tái tạo được. **Bạn không bao giờ cày một Warden để lấy chiến lợi phẩm hay XP** — khi nó gục, nó tắt vĩnh viễn, và không có con thứ hai đằng sau nó. First Warden không canh giữ nghề của người khác; nó canh giữ *chính hành động ghi nhớ*, chiến đấu mờ nhạt như tất cả những con kia gộp lại cùng lúc, và khi nó gục nó không chết — nó **cuối cùng cũng ấm lên** và ngừng cần đứng canh. **GWI dâng lên từ những lợi tức đã ký gửi — cứu hộ, nghề phục hồi, những vòng được sưởi ấm — không bao giờ từ việc làm chảy máu một con boss.**

Điều này giữ mọi Warden luôn khoa-học-trước-tiên: mỗi con là một trạng thái phân rã tự duy trì, và cách khắc chế mỗi con là **năng lượng cộng thông tin được phục hồi** — nhiệt cộng nghề đã phục hồi, câu trả lời thực-tế cho entropy cục bộ. Không kẻ ác. Không kế hoạch.

### Cái Giá Của Thế Giới — Được Dàn Dựng, Một Cách Trung Thực

Warmth ngày nay chỉ có tăng, nên nhà không bao giờ bị đe dọa. Cách sửa phải bám sát luận đề: cái lạnh không thể *mưu tính một cuộc đột kích*, nhưng entropy chắc chắn đòi lại bất kỳ gradient nào bạn ngừng duy trì. Vì vậy cái giá đến trong **hai build tách bạch rõ ràng**, và khoảng cách giữa chúng được nói thẳng, chứ không giấu giếm.

**v1 — Cold Snap (một mối đe dọa thuần KINH TẾ, dựng được ngay bây giờ).** Một khoảng đất mở rộng là warmth được giữ ngược lại một gradient; giữ nó cẩu thả và gradient sẽ giành lại một vòng. Nếu GWI ở một vòng ngoài rơi xuống dưới ngưỡng của nó — do bành trướng quá mức, để một lò sưởi không được tiếp nhiên liệu, hoặc dành quá nhiều ngày dưới sâu mà không chăm nom nhà — thì vòng ngoài cùng **đóng băng và ngủ đông**: các công trình của nó nằm không, cây trồng của nó bất động, các attunement của nó xám xịt cho tới khi bạn sưởi ấm lại. **Không husk nào vào làng; không có chiến đấu trong làng.** Không gì bị phá hủy — nó bị *lãng quên*, và có thể được nhớ lại. Cái này chạy hoàn toàn trên các ngưỡng warmth hiện có và warmth theo khoảng cách từ đợt đại tu xây dựng, thứ khiến **các lò sưởi/lò than được giữ** trở thành hạ tầng chịu tải thực sự. *Đọc trên màn hình:* vòng ngoài phủ sương giá rõ rệt, màu sắc rút cạn về xám-xanh, và các biểu tượng công trình của nó mờ đi thành ngủ đông. ⚑ *Sự đòi-lại này nén phân rã nhiệt động và xã hội chậm chạp thành một sự kiện giữa-các-run; hướng (trật tự không được chăm nom sẽ phân rã) là trung thực, tốc độ thì mang tính kịch.* (Các ngưỡng Cold-Snap chính xác **TBD**.)

**Giai đoạn sau — Incursions + Long Night (một CÚ PIVOT phòng thủ căn cứ; hãy nêu rõ chi phí dựng).** Husk Incursions, chiến đấu tháp canh/dân làng, và Long Night là một **giai đoạn sau đáng kể**, không phải một núm tinh chỉnh trên v1. Chúng đưa vào **chiến đấu trong làng** — một thể loại mà màn hình builder/farm hiện tại *hoàn toàn không có*: kẻ thù tìm đường vào khoảng đất, hàng rào gỗ dồn hướng, tháp canh cảnh báo sớm, dân làng chiến binh và AI của họ, một UI vòng-phòng-thủ. **Đó là một chi phí dựng thực sự và nó được nêu rõ ở đây, không chôn giấu.** Khi nó tồn tại:

- **Husk Incursions.** "Độ sâu chưa đóng" tích lũy thỉnh thoảng cho phép một toán husk nhỏ trồi lên các vòng ngoài lạnh giá giữa các run. Hàng rào gỗ (làm chậm/dồn hướng) và tháp canh (cảnh báo sớm + một dân làng đẩy lùi chúng *nếu bạn đã xây một ngôi làng đủ đa dạng để cắt cử ra được một người*) xứng đáng với công của mình. Incursions đe dọa **ngủ đông, không phải cái chết** — một cuộc incursion không được kiểm soát sẽ đóng băng một vòng, nó không san bằng vòng đó. **Con người là phần thưởng, không bao giờ là tiền đặt cược:** mất người sống sót không bao giờ nằm trên bàn này.
- **Long Night.** Một trụ cột hiếm hoi, được telegraph, có-thể-chọn-tham-gia: thế giới nghiêng xa nhất khỏi warmth của nó và trong một đêm dài *mọi thứ* tốn nhiều nhiệt hơn để giữ cho sáng — bài kiểm tra định kỳ của game về sự đa dạng. Sống sót qua nó và thế giới bật lại ấm hơn; thất bại và bạn mất đất mà bạn có thể sưởi ấm lại. *Đọc trên màn hình:* bầu trời tối sâu hơn cả đêm bình thường, quầng sáng của mọi vòng được thắp co lại, và đồng hồ hao-nhiệt tích tắc nhanh hơn thấy rõ. **Cơ chế (có cơ sở):** một sự đào sâu gradient lạnh theo mùa, theo độ nghiêng trục — đêm dài nhất theo nghĩa đen. ⚑ *Chu kỳ thiên văn được nén thành một nhịp dễ đọc cho game; vật lý (độ nghiêng → một đêm dài nhất → một gradient lạnh sâu hơn) là thật.* (Nhịp Incursion và nhịp Long Night **TBD**.)

Tất cả đều là entropy được dàn dựng một cách trung thực: bỏ mặc, vươn quá tầm, và sự đào sâu định kỳ của gradient — không cái nào đòi hỏi cái lạnh phải *muốn* bất cứ điều gì.

### Những Lò Sưởi Khác — Được Truyền Tay Này Sang Tay Kia

Luận đề là *warmth được truyền tay này sang tay kia, hoặc nó mất đi.* Một thế giới chỉ có một lò sưởi lặng lẽ mâu thuẫn với điều đó. Vì vậy lớp những-lò-sưởi-khác nên tồn tại — như **những tín hiệu mờ nhạt và những ngọn lửa lụi tàn, không phải các phe phái đối địch.** Nhịp này là hạt giống mà cả lớp mở rộng mọc lên từ đó (§6).

**Nơi chúng xuất hiện (và chi phí dựng).** Hai bề mặt, cả hai đều là **công spawn mới cần nêu rõ**: (1) một **kiểu-node "lò sưởi lụi tàn" trên bản đồ run** riêng — một node mới mà bản đồ xuống sâu phân nhánh có thể tung ra, nằm cạnh Combat/Treasure/Rescue/Rest-Hearth/Boss, với nội dung phòng và các móc kết quả riêng của nó; và (2) những **tín hiệu giữa-các-run** mờ nhạt trên bầu trời làng — một quầng-than xa xăm nơi chân trời gợi ý rằng một lò sưởi đang tàn lụi ngoài kia, gieo *cảm giác* rằng bạn không phải tia lửa duy nhất mà không phá vỡ hư cấu Ember-đơn-độc. Cả hai đều là các pipeline nội dung mới (kiểu node + các phòng được sáng tác của nó; hệ thống tín hiệu giữa-các-run và phần art của nó), không phải các bản reskin miễn phí. *Đọc trên màn hình:* một biểu tượng node đặc biệt nhấp nháy yếu ớt trên bản đồ, và, trong làng, một nhịp cam thấp xa tít trong bóng tối.

**Thắp lại vs ăn thịt — phán quyết.** Chạm tới một lò sưởi lụi tàn là một trục nhân-từ-vs-thực-dụng sạch sẽ không có đáp án đúng:

- **Thắp lại nó** — tiêu nhiệt và nguyên liệu của chính bạn để nhen lại lửa của một người lạ. Ít chiến lợi phẩm; bạn có được *một hai người sống sót nhớ một nghề mà bạn không biết*, và tổng warmth (GWI) dâng nhanh hơn vì giờ có hai bàn tay truyền lửa thay vì một. Đây là sự lan lửa thật — trung thực, bám luận đề, không nợ một lời xin lỗi nào.
- **Ăn thịt nó** — lấy nguyên liệu đã ký gửi của nó cho một khoản lãi lớn, tức thì và để lửa tắt. Điều này **tước đi cuộc cứu hộ những người sống sót ấy**: họ **không bao giờ bị giết trên màn hình — con người không phải tiền đặt cược** — nhưng con người và tri thức của họ bị **loại bỏ vĩnh viễn khỏi thế giới**, và GWI chịu một vết lõm lâu dài. Ember lặng lẽ ghi nhận rằng đây chính xác là cách Bóng Tối Trường Kỳ lan rộng: warmth của một lò sưởi bị lấy đi để nuôi lò sưởi khác, cho tới khi không nơi nào được chăm nom cùng một lúc nữa. Sức nặng của lựa chọn là **thứ bạn đã chọn không mang theo.**

Hãy giữ nó đơn-lò-sưởi trong *cảm giác* — bạn vẫn là Ember còn sống cuối cùng — nhưng để bản đồ chứng minh rằng cả công việc của Ember cuối cùng là làm cho chính mình **không còn là kẻ cuối cùng.** (Lựa chọn này nuôi trục nhân từ của các ending — xem §10.)

### Tiếng Nói Của Ember — Từ Dỗ Dành Một Con Mèo Đến Một Thế Giới Được Nhớ

Ember là nhân vật liên tục duy nhất, và giọng điệu của nó là một **sự tan băng chậm rãi của chính mình.**

- **Sớm (Ash / những lần xuống sâu đầu tiên):** *dỗ dành một con vật đang sợ hãi* — ngắn, ấm, che chở, hơi lo âu, giải thích quá kỹ vì nó đang dạy dỗ. *"Nhẹ nhàng thôi. Ở gần ta. Bóng tối chỉ là cái lạnh — mà cái lạnh, ta có thể đáp lại."*
- **Giữa:** *trìu mến và hóm hỉnh*, một người thầy ngắm học trò vượt qua bài học, bắt đầu nhờ *bạn* ghi nhớ. *"Con biết cái này rồi. Cho ta xem đi."*
- **Cuối:** nó nói *như một ký ức mà thế giới đang gìn giữ* thay vì một tiếng nói gìn giữ thế giới — bình thản, đa giọng, gần như tắt lịm theo cách đẹp nhất, vì nó không còn mang ngọn lửa một mình nữa. *"Ta gần cạn rồi. Điều đó không buồn. Nó nghĩa là ngọn lửa giờ ở nơi khác — trong họ, trong con. Nơi nó vốn luôn được định sẵn để ở."*

**Những lời thoại theo từng giai đoạn kế tiếp.** Đợt băng giá dài đã cào mòn bề mặt xuống tận **nền khoáng chất trơ trụi**, nên đây là **kế tiếp sơ cấp (primary succession)** — "Ash" đặt tên cho chính lớp đá khoáng bị cái lạnh cào sạch, không phải chất hữu cơ còn sót, đó là lý do địa y tiên phong đến *đầu tiên*. Một lời thoại mỗi khi một Bloom bước sang một giai đoạn seral muộn hơn — Ember thuật lại thế giới đang tự đọc mình trở lại sự sống, và đọc *sự trưởng thành của bạn* trong cùng một hơi thở:

- **Ash** — *"Đá khoáng trơ trụi, bị cào tới hư không. Chưa gì mọc ở đây — chưa từng, chưa bao giờ. Nhưng không gì mọc ở đâu cả cho tới khi có thứ gì dám làm kẻ đầu tiên."*
- **Pioneer** — *"Kìa — địa y trên đá, sự sống táo bạo nhất trên đời. Nó đòi hỏi gần như chẳng gì, và nó khởi đầu mọi thứ."*
- **Herb** — *"Xanh, và mềm đến mức có thể bầm dập. Những thứ mong manh là cách một thế giới báo cho bạn biết nó đã ngừng chết."*
- **Thicket** — *"Giờ nó rối rắm, vươn ra, tranh giành. Sự chen chúc là một dạng của tự tin. Cứ để nó chiến đấu vì ánh sáng."*
- **Canopy** — *"Ngẩng lên đi. Nó khép lại trên chúng ta như một hơi thở nín được thả ra. Đây là điều mà sự kiên nhẫn trở thành: bóng mát cho thứ đến sau."*

⚑ *Kế tiếp sơ cấp trên đá trơ — bề mặt khoáng bị cái lạnh cào sạch → địa y tiên phong → thảo mộc → bụi rậm thicket → tán rừng khép kín — là sinh thái thật được nén vào cung của một run duy nhất như một phép ẩn dụ có chủ đích cho việc warmth trở lại nhanh đến mức nào một khi có ai đó chăm nom (sinh thái đầy đủ → App A).*


---

## 4. Worldlines — Lựa Chọn Đầu Tiên Lan Tỏa Ra Sao

> ⟢ **VISION.** Mọi thứ ở đây là lớp đích đến, chưa ship. Cái đang ship hôm nay là một frontier duy nhất — hành trình lặn xuống **Buried Warren** và Warden duy nhất của nó (the Unfinished Arch) — cộng với lớp *reskin* danh tính-phát minh mà tài liệu đã gắn cờ là quá thiên về trang trí. Phần này chính là bản vá: nó nâng **phát minh đầu tiên** từ một trục trang trí lên thành một **hạt giống worldline** — một lựa chọn sớm duy nhất làm nghiêng *frontier bạn chơi trong đó*, *công nghệ bạn chạm tới sớm nhất*, *chính trị của cách hơi ấm lan tỏa*, và *mục tiêu bạn trôi dần về*. Lưới ending (§10) vẫn chọn *gia đình* ending; worldline tô màu cho *thế giới, con đường, và mục tiêu rẻ nhất* nằm dưới lớp danh xưng, để hai save "Rekindled Commons" là hai ván game khác nhau về bản chất, không phải một cutscene với hai con dấu. ⚑ Nén lịch sử công nghệ và định cư của một nền văn minh vào một run ~10 giờ là một sự phóng khoáng có chủ đích; ⚑ chuyện hư cấu rằng phục hồi *một* nghề thủ công "mở" một frontier là logic game, không phải thuyết định mệnh công nghệ.

### The Worldline Seed — một lựa chọn, bốn tầng lan tỏa

Nghề thủ công đầu tiên bạn phục hồi không phải một cú khởi đầu trước trên một cây chung — mà là một **ngã rẽ về việc cây nào sẽ mọc.** Mỗi hạt giống nghiêng, cùng một lúc, về: **frontier nào rẻ nhất để mở** (danh sách biome do §5 sở hữu; worldline chọn *cánh cửa gần nhất*), **xương sống công nghệ nào mọc sớm nhất**, **kiểu bành trướng nào rẻ nhất** (phổ reclaim→federate→annex→cannibalise do §6 sở hữu; worldline chọn đầu nào mà công cụ của bạn *ưu ái tự nhiên*), và **gia đình ending nào bạn trôi về** nếu không bao giờ chống lại trọng lực của mình. Tất cả chỉ là một *sự nghiêng* — không bao giờ là khóa cứng. (Mô hình Soil, "warm start = khởi đầu trước, không phải thâm hụt boon," và các trục lựa chọn đầu vào → §1.)

| Phát minh đầu tiên (seed) | Frontier nó mở đầu tiên ⟢ | Xương sống công nghệ mọc sớm nhất | Bành trướng nó ưu ái | Gia đình ending nó trôi về | Nguyên mẫu |
|---|---|---|---|---|---|
| **Agriculture** (Farmer → Crop Bed) | **OUT — the Frostmarch Tundra**: cánh đồng đóng băng & những luống chôn vùi | seed-vault → granary → irrigation → thặng dư | **Federate** — nuôi một lò sưởi leo lét, nó liên minh như một kẻ ngang hàng | **The Slow Dawn** (III) · Diverse × Mercy × Starved | Slow Bloom |
| **Metallurgy** (Smith → Forge) | **UP — the Glaciated Spire**: lò rèn đỉnh núi / lò rèn sâu | quặng → thép → tấm-vỏ → công cụ khoan sâu | **Ngân hàng nhanh & giữ hẹp** — một đế chế ấm, độc canh | **The Long Watch** (II) · Monoculture × Plunder × Confronted | Bright Predator |
| **Construction** (Builder → Cabin) — **SHIPPED baseline** | **DOWN — the Buried Warren**: những hầm sập *(đã ship)* | chống đỡ → vòm chịu tải → rào chắn / tháp canh | **Reclaim & giữ** — một chuỗi vòng thắp lại phòng thủ được | **Rekindled Commons — Hearth-Keep** (I) · Diverse × Mercy × Confronted | Hearthkeeper |
| **Builder / Carpenter** (Carpenter's) | **ACROSS — nhà = the Ashen Wald**; đi vòng phần còn lại rẻ nhất | woodcraft → mở khóa xương-chéo nhanh | **Linh hoạt** — bất kỳ lớp vỏ nào, chuyến đi rẻ nhất | **The Kept Flame** (V) · Codex 100% | Kindler |

Sự lan tỏa mang tính *hữu cơ*, không tùy tiện: agriculture đọc đất, nên cánh cửa rẻ nhất của nó là **ra ngoài** đến the Frostmarch Tundra nơi có cánh đồng và seed-vault; metallurgy rèn tấm-vỏ và công cụ cắt, nên nó **leo lên** the Glaciated Spire đến lò rèn sâu trên đỉnh; construction dựng chống đỡ và vòm, nên nó **lặn xuống** the Buried Warren (con đường đã ship); woodcraft đóng khung và ghép nối, nên nhà của nó là **the Ashen Wald**, từ đó nó đi vòng mọi frontier khác với chi phí thấp nhất. **The Drowned Coast** — biển đóng băng — không thuộc về seed nào; nó là xa lộ bành trướng chung mà ai cũng băng qua (§6). Và craft-Warden nào bạn thắp lại **đầu tiên** rơi ra từ seed của bạn: **the Keeper of the Empty Rows** (agriculture), **the Cold-Struck Smith** (metallurgy), **the Unfinished Arch** (construction, *đã ship*), **the Last Wright** (Ashen Wald / Woodcraft) — số còn lại đi vòng theo thứ tự mà bản đồ phân nhánh cho phép. Mọi worldline cuối cùng đều hội tụ về cùng một điểm cuối sâu nhất, **the First Hearth / the First Warden** (⟢ VISION đỉnh cao).

### Chi phí xây dựng, nói thật

Mỗi seed mới không phải một asset — nó là một **cấp số nhân nội dung.** Một worldline duy nhất được viết đến độ sâu đầy đủ đại khái bằng *nghệ thuật frontier + xương sống công nghệ + bộ năng lực cuối + đoạn kết ending* ≈ **nội dung gốc được viết ×4.** ⚑ Đó là lý do thật khiến đây là VISION, không phải một cú reskin cuối tuần. Nơi duy nhất mà cấp số nhân đã được trả một phần là xương sống Construction: bậc **rào chắn / tháp canh** của nó *chính là* điểm xoay phòng-thủ-cứ-điểm đã gắn cờ (xem §3 stakes, §5 frontier, App B lộ trình) — nó thừa hưởng toàn bộ chi phí của điểm xoay đó và **không phải một mở khóa rẻ.** Việc dàn trải ba seed còn lại được hoãn sang các phase PROGRESSION trong App B, mỗi lần một frontier phía sau Warren đã ship.

### Vì sao đến giữa run chúng chơi như những game khác nhau

Đến giờ thứ tư các worldline không còn chung một màn hình. Một save **agriculture** đang chạy một vòng lặp *bề mặt* — bão trắng vùng tundra và những luống đóng băng, nuôi các cộng đồng nông trại leo lét, ngắm dân số tăng — trên một nền kinh tế granary mà smith không bao giờ thấy. Một save **metallurgy** đang *leo the Spire*, tích trữ độ sâu phía sau những công cụ nó rèn để khoan cao hơn vào lò rèn đỉnh. Một save **construction** đang *lặn xuống the Buried Warren*, dựng một chuỗi vòng có chống đỡ và giữ nó chống lại cái lạnh. Khác biome, khác hỗn hợp kẻ thù, khác di chuyển, khác kinh tế — và khác những năng lực *rẻ nhất*: construction-first **tự nhiên** dựng hạ tầng rào chắn/tháp canh mà phase phòng-thủ-cứ-điểm cuối cần; metallurgy-first rèn công cụ khoan sâu **sớm nhất**; agriculture-first chạm thặng dư dân số **rẻ nhất**, build duy nhất có thể ấm hơn cả tầng sâu mà không bao giờ phải đánh nó. Nhưng seed chỉ làm nghiêng cái late game nào là *rẻ nhất* — **mọi năng lực và mọi ending vẫn có thể chạm tới bằng cách trả giá của một ngã rẽ.** Sự nghiêng, không phải đường ray.

### Ba ngã rẽ giữa game

Một seed là **trọng lực, không phải đường ray.** Ba ngã rẽ cho phép bạn hoàn thành mặc định của worldline — hoặc trả giá để bẻ cong nó — và mỗi cái là một ngã rẽ *nội dung* thật, không phải một thanh trượt:

- **Fork A — Confront vs Starve the Deep.** *Confront:* bạn lao đến điểm cuối và thắp lại các Warden như những trận boss — các đấu trường biome-sâu *chính là* nội dung cuối của bạn. *Starve:* bạn không bao giờ lặn xuống để đánh; bạn dồn các run vào liên bang bề mặt và thặng dư cho đến khi tàn tích sâu nhất được **tìm thấy đã ấm sẵn và trống rỗng** (con đường bỏ-đói-tầng-sâu, phán quyết đầy đủ của nó → §9). Các bộ nội dung khác nhau — đấu trường boss vs một vòng lặp ngoại giao-và-thặng-dư — không phải hai độ khó của cùng một trận đánh. Agriculture bỏ đói một cách tự nhiên; metallurgy hầu như không kham nổi; construction thường đối đầu để thắp-lại-và-giữ.
- **Fork B — Federate vs Annex vs Cannibalise** (ngã rẽ chính trị; §6 sở hữu cơ chế của phổ này). *Federate:* các lò sưởi được thắp lại vẫn là **những kẻ ngang hàng độc lập** — một mạng lưới lan tỏa gồm nhiều điểm ấm (**lớp vỏ federate của Commons**). *Annex:* bạn kéo chúng vào một ngọn lửa trung tâm duy nhất, **The One Great Hearth** — trục-và-nan, một hồ GWI dày đặc duy nhất, **vẫn khoan dung và đông dân** (**lớp vỏ tập trung của Commons**, không bao giờ là chinh phục, không bao giờ là cướp bóc). *Cannibalise:* bạn **lột** một lò sưởi leo lét để lấy một khoản lời trời cho và để nó tắt — không bao giờ là PvP, **con người không bao giờ là tiền đặt cược và không bao giờ bị giết trên màn hình**, nhưng tri thức của họ rời khỏi thế giới và GWI sứt mẻ; đây là khúc rẽ tối của trục khoan-dung về phía The Hollow Warmth (IV). Ngã rẽ này quyết định **hình học chính trị của bản đồ cuối** — cái chất mà các ending "reskin" cũ thiếu.
- **Fork C — Specialise vs Diversify.** *Specialise:* thành thạo một nghề duy nhất chạm cổng sâu nhất nhanh nhất, nhưng một đường chân trời độc canh bị Cold-Snap trước tiên. *Diversify:* một ngôi làng đa dạng leo chậm hơn tới bất kỳ độ sâu nào nhưng chạm một trần hơi ấm cao hơn và sống sót qua bài thi world-stakes. (Đây là kỷ luật cap-of-3 / đa dạng của §2, được đưa lên thành một trục ending.)

### The Branch Table — phát minh đầu tiên × ngã rẽ chính → một đích đến riêng biệt

Mỗi hàng là một thế giới khác nhau, một *mục tiêu cuối* khác nhau (tất cả đều rút từ **một** thanh GWI chủ — không bao giờ là một tiền tệ song song), và một đoạn kết worldline khác nhau. Các nhịp Ending & Ember sống ở nhà của chúng trong **§10**; bên dưới, chỉ có đoạn kết worldline thực sự mới.

| Worldline + ngã rẽ | Thế giới late-game (đọc trên màn hình) | **Mục tiêu cuối** (cách bạn thắng) | Ending → §10 · đoạn kết worldline |
|---|---|---|---|
| **Agriculture** · Federate · **Starve** | một liên bang lan tỏa gồm những lò sưởi xanh trải khắp the Frostmarch Tundra; những luống chôn vùi ấm áp và không cần canh giữ | **Đua bề rộng tới 1.0** — liên bang và nuôi dưỡng cho đến khi thặng dư ấm hơn tầng sâu; điểm cuối **leo lét không được gặp, ngoài màn hình** | **The Slow Dawn (III)** · *đoạn kết:* những cánh đồng đã ấm trước khi trận đánh từng đến. |
| **Metallurgy** · Monoculture · Bank-fast · **Confront** | một đế chế-lò-rèn ấm, hẹp leo lên the Glaciated Spire; bầy đàn rình rập tường thành của nó | **Chạm & ép** — rèn công cụ khoan sâu, leo lên, thắp lại the First Warden **bằng vũ khí** | **The Long Watch (II)** · *đoạn kết:* một ngọn lửa của một thanh củi — coi chừng đêm thứ hai. |
| **Construction** · Reclaim/Federate · **Confront** | một chuỗi vòng kiên cố lặn xuống the Buried Warren, những tháp canh được thắp sáng, giữ vững qua một Long Night | **Giữ & thắp lại** — dựng mạng lưới, sống sót qua world-stakes, thắp lại the First Hearth mặt đối mặt | **Rekindled Commons — Hearth-Keep (I)** · *đoạn kết:* đá còn nhớ hình dáng của nơi trú ẩn. |
| **Any** · **Cannibalise** · Starve | một điểm rực cháy duy nhất trong một hoang địa mép lạnh; những vòng ngoài đóng băng vì các Cold-Snap không được chăm; một Codex đầy khoảng trống | **Cạo cho ra 1.0 rỗng tuếch** — cannibalise những lò sưởi leo lét lấy lời, không chăm sóc gì cả | **The Hollow Warmth (IV)** · *đoạn kết:* bóng tối chỉ dời sang một nơi bạn không thể thấy nó. |
| **Builder/Carpenter** · Diversify · đi-vòng-tất-cả | mọi frontier được ghé thăm từ the Ashen Wald ra ngoài, tri thức của mọi craft-Warden được thắp lại; thị trấn đa dạng trong truyện tranh | **Hoàn thành bản ghi** — phục hồi **mọi** nghề thủ công qua mọi frontier (Codex 100%) | **The Kept Flame (V)** · *đoạn kết:* danh sách những gì một tâm trí học được cách làm, và nhọc lòng truyền dạy. |

**Trọng lực metallurgy — một con đường, không phải hình phạt.** Mặc định của Predator *cố tình* bẻ về hướng cảnh tỉnh: monoculture + bank-fast + confront là thớ rẻ của một seed metallurgy, và nó đổ vào **The Long Watch (II)** — một đế chế ấm, hẹp, chiến thắng mà Ember của nó gọi to **cái giá đêm-thứ-hai đã biết** của nó (→ §10), không bao giờ mắng mỏ. The Long Watch được chạm tới bằng con đường monoculture-cướp-bóc-đối-đầu đó, **không phải bằng annex** — annex vẫn là một lớp vỏ khoan dung, tập trung của Commons. *Sự lật đổ có tính toán* là lối thoát: một save metallurgy **đa dạng hóa + tỏ lòng khoan dung + liên bang** trả để thoát khỏi trọng lực của nó vào Commons.

**Sự nghiêng, không phải đường ray (một sự lật đổ có tính toán).** Một seed **agriculture** thay vào đó lại **chuyên môn hóa lúa + tích trữ nhanh + đối đầu** trở thành một *đế chế-nông-dân* — những granary nuôi một thị trấn hành quân xuống sâu để đánh — và hạ cánh vào **The Long Watch** bằng một con đường không smith nào từng đi, gieo bằng lúa chứ không phải sắt. Seed đặt con đường rẻ; các ngã rẽ cho phép bạn trả giá để thách thức nó. Lựa chọn đầu tiên tạo ra một game *mặc định*; sự thành thạo là bẻ cong nó.

### Cách nó vẫn dễ đọc — và trung thực với luận đề

Mọi worldline **đọc được trên màn hình** mà không cần tooltip (Pillar 1): **nghệ thuật frontier** (tundra trắng vs glaciated spire vs những hầm của Warren vs the Ashen Wald) gọi tên seed; **đường chân trời** gọi tên xương sống công nghệ (granary vs chồng-lò-rèn vs vòm có chống đỡ); một **bản đồ hơi ấm** giữa các run cho thấy chính trị của bạn dưới dạng *hình dáng* — một mạng lưới những ánh sáng ngang hàng (federate), một trục sáng duy nhất (annex / The One Great Hearth), hoặc một điểm duy nhất trong một cánh đồng lạnh (cannibalise). Một dòng **Ember** sớm gọi to seed, và con dấu-thế-giới §10 gấp nó vào danh xưng. **Codex** phát minh **vẫn cố định, xếp hạng theo tác động, và trung thực** (App A/D) — bành trướng không bao giờ thêm mục có thể xóa hay phương ngữ bịa ra; khác biệt federate/annex/cannibalise chỉ sống trong hình học bản đồ, dân số, và những mục thật nào mà một thế giới đã thắp lại.

Mô hình này dựa vào việc tái-cân-đo Soil (→ §1) và việc tách rời Mode/Kingdom (→ §2), và chiến thắng bỏ-đói-tầng-sâu của nó dựa trên §9. Và nó vẫn đúng luận đề: entropy là kẻ thù **duy nhất** — mọi worldline chỉ chiến đấu với cái lạnh và husk, không bao giờ với con người; **annex không phải chinh phục** (một cộng đồng gia nhập cộng đồng của bạn, nghề của nó được lưu vào ngân hàng); hình dạng tối đúng-luận-đề là **cannibalise**, hơi ấm lấy từ một lò sưởi để nuôi một lò khác *đúng như cách Long Dark lan ra* — và ngay cả ở đó con người cũng không bao giờ bị giết, chỉ bị *lãng-quên*. Warden leo lét tắt dần, không bao giờ chảy máu. Dù bạn gieo worldline nào, màn hình cuối đều đền đáp một câu trong một thế giới khác: **văn minh sống trong con người và tri thức, không phải chiến lợi phẩm — và hơi ấm được trao đi, tay này qua tay khác, hoặc nó mất đi.**


---

## 5. Môi Trường Của Run — Cái Lạnh Chiếm Mọi Hướng

> **SHIPPED vs ⟢ VISION — đọc một lần.** Mọi thứ bạn có thể chơi hôm nay chạy trong **một** môi trường: **Buried Warren**, một hành trình lặn xuống qua một tàn tích chìm tại Supply Gate (bản-đồ-nút phân nhánh, các đấu trường bị khóa, đá xanh phủ băng). Hướng duy nhất đó — *luôn xuống* — là sự đơn điệu mà phần này vá. **Warren là baseline SHIPPED**; bốn frontier sau nó, các **Family** vật liệu (Bramble/Beast/Slag) tô màu cho hỗn hợp kẻ thù của chúng, và *depth status* **Frost-Encased** phủ lên trên chúng, đều là **⟢ VISION** — thiết kế ở đây, chưa xây. Không có gì bên dưới đang live cả.

Thế giới đóng băng không phải một trục thẳng đứng duy nhất. Entropy không đi một con đường duy nhất; nó chiếm **mọi độ dốc cùng một lúc** — thành phố chìm, biển đóng băng giữa cơn sóng, ngọn núi biến mất dưới lớp băng tiến tới, khu rừng chết đứng, đồng bằng khóa thành băng vĩnh cửu. Vậy nên một run nên có thể đi **xuống, ra, hoặc lên**, và mỗi đích đến nên *chơi* khác nhau, không chỉ đơn thuần reskin. Quy tắc thống nhất giữ cho mọi thứ trung thực: **cái lạnh là điều kiện môi trường và hơi ấm là món quà khan hiếm của người chơi.** Đó là lý do một "màn dung nham" hay cõi-lửa bị bác bỏ thẳng thừng ⚑ — hơi ấm môi trường như một hiểm họa đảo ngược toàn bộ xương sống; một **biển đóng băng, một đỉnh núi băng hà, một thảo nguyên băng vĩnh cửu, một khu rừng ash-killed** đều là *những trạng thái mà một thế giới lạnh, hay quên thực sự tạo ra*, nên chúng nằm trong luật chơi và sự phóng khoáng của chúng chỉ luôn là về **thang thời gian được nén**, không bao giờ về một thế giới ấm giả vờ lạnh.

### Danh sách frontier tóm lược

| Frontier | Hướng | Đọc trên màn hình | Cơ chế đặc trưng | Family chủ đạo + depth status | Craft-Warden → Codex | Worldline (mở đầu tiên) | Trạng thái |
|---|---|---|---|---|---|---|---|
| **The Buried Warren** | **xuống** — thành phố chìm | đá nứt phủ băng, bóng tối chật hẹp thắp bởi ember | sập hầm định hình lại các vùng nguy hiểm; Ember *chính là* bán kính tầm nhìn của bạn | **Slag** (nề, gạch vụn) + **Frost-Encased** tầng sâu — ⟢ *phân loại family là VISION; kẻ thù đã ship chỉ theo hành vi* | **The Unfinished Arch** → Construction | **Construction-first** | **SHIPPED** |
| **The Frostmarch Tundra** | **ra** — cánh đồng chôn vùi | thảo nguyên trắng phẳng, tuyết bay ngang, một ngọn hải đăng lạc | **bão trắng** cắt tầm nhìn & rút ngắn telegraph; **đào băng vĩnh cửu** để chạm tới các kho | **Beast** (siêu thú đóng băng) + **Bramble** (cói) | **The Keeper of the Empty Rows** → Agriculture | **Agriculture-first** | ⟢ VISION |
| **The Glaciated Spire** | **lên** — đỉnh núi bị vùi | tường serac xanh, trời nhạt mỏng, đấu trường thẳng đứng | **rút-lạnh theo độ cao** (leo từ điểm-ấm tới điểm-ấm — thắp lại lò than cũ / đặt lò của riêng bạn — hoặc leo lét tắt); **icefall** như hiểm họa di động | **Slag** (quặng/đá) + **Frost-Encased** status (sông băng) | **The Cold-Struck Smith** → Metallurgy | **Metallurgy-first** | ⟢ VISION |
| **The Ashen Wald** | **ngang** — rừng chết | thân cây đen trơ xương, tro bay, vỉa than chưa cháy | **địa hình lan lửa** — đám cháy lan khắp cả biome (con dao hai lưỡi) | **Bramble** (gỗ chết đứng) | **The Last Wright** → Woodcraft (Carpenter's/Builder) | chung (nghiêng Builder) | ⟢ VISION |
| **The Drowned Coast** | **ra** — biển đóng băng | một tấm băng đang nứt vỡ, những con sóng đóng băng, những ánh lò sưởi xa | **băng mỏng — cứ di chuyển**; **nứt thủy triều / khe nước mở** làm uốn tấm băng, mở/đóng các lối đi | **Beast** (biển) + **Frost-Encased** status (băng biển) | *(không có craft-Warden — hành lang bành trướng)* | chung (xa lộ bành trướng) | ⟢ VISION |

### 1. The Buried Warren — xuống vào thành phố chìm *(baseline SHIPPED)*

**Hư cấu.** Thành phố không đổ vì một kẻ thù; nó **chìm dưới sức nặng nứt-vỡ-vì-lạnh của chính nó** — dầm gãy, hầm chất đầy tro và băng, và một mê cung những con phố nửa sập ép xuống bóng tối, từng mùa đông không được chăm một. **Hướng:** xuống. **Nhìn:** bảng màu đã ship — đá nứt nghiêng về phía camera, mọi thứ phủ băng xanh, một điểm ấm trong khung hình.

**Cơ chế.** *Sập cấu trúc:* trần nhà bất ổn, nên các husk **Bomber** và vết nứt-ứng-suất làm rơi gạch vụn **vẽ vùng nguy hiểm mới giữa trận** — đấu trường tự viết lại chính nó, và bạn định tuyến vòng quanh mảnh vụn thay vì xuyên qua. *Bóng tối vô sáng:* Ember là **bán kính tầm nhìn** của bạn; đi lạc quá xa nó thì tầm đọc co lại, và đứng yên trong bóng tối để cái lạnh thấm nhanh hơn. **Hỗn hợp kẻ thù (hành vi × family):** **Slag** chiếm ưu thế — nề, đá-băng-vĩnh-cửu, gần như bất động (~0 Kindle) — nên một **Slag Bomber phải bị nứt trước khi vòng cảm-tử của nó nổ** và một **Slag Charger** tự choáng vào tường. Những con phố sâu nhất thêm depth status **Frost-Encased**. *(Lớp **family** ở đây — phân loại Slag/Frost-Encased — là ⟢ VISION; kẻ thù Warren **đã ship** chỉ theo **hành vi**, family của chúng đến cùng ma trận Mode×Family.)* **Giải cứu → Codex:** **Builder/thợ nề**, được canh giữ bởi **The Unfinished Arch** (một chiếc nôi lắc dừng lại dưới một tảng đá đỉnh vòm chùng xuống) — dạy **Construction** (vòm chịu tải, lao động được lưu trữ). **Worldline & bành trướng:** **Construction-first** mở Warren sâu nhất và sớm nhất; những người sống sót rải rác của nó là **cư dân hầm** co ro trong những căn phòng lành lặn cuối cùng — dân số *reclaim → federate* tự nhiên cho một worldline Hearth-Keep. ⚑ *Một thành phố nén hàng thế kỷ lún sụt vào một tàn tích đi bộ được là mang tính sân khấu; hướng đi (cấu trúc không được chăm thì mục rã) là trung thực.*

### 2. The Frostmarch Tundra — ra ngang qua những cánh đồng chôn vùi *(⟢ VISION)*

**Hư cấu.** Những vùng đất trồng mà cái lạnh chiếm lấy: lớp đất mặt đóng băng thành sắt, những vò hạt giống bị cạo sạch, một granary đầy băng. **Hướng:** ra, ngang qua thảo nguyên trống. **Nhìn:** một chân trời trắng phẳng, **tuyết bay ngang**, ngọn hải đăng chỉ đường bị rút thành một sợi chỉ mảnh mà bạn *buộc* phải theo vì vùng đất không cho mốc nào khác.

**Cơ chế.** *Bão trắng:* những cơn bão tuyết cuộn qua theo vòng lặp và **làm sụp tầm nhìn**, nên telegraph vùng nguy hiểm đọc được muộn và ngọn hải đăng trở thành đồ nghề sinh tồn — ánh sáng của Ember là một chiếc đèn lồng trong bức tường trắng. *Đào băng vĩnh cửu:* các kho, seed-vault, và một số người sống sót bị **khóa dưới lớp băng bạn dọn**, một cuộc đua phơi mình ngắn ngủi với cái lạnh khi bạn đứng yên. **Hỗn hợp kẻ thù:** **Beast** — tundra *bảo quản* xác ẩm (mammoth-husk là trung thực: siêu thú thực sự trồi lên từ băng vĩnh cửu), nên một **Beast Charger** bị **khóa-độ-ẩm**, bạn **đun cạn nước của nó trước khi nó chịu bốc cháy** (Draft, hoặc hai nguồn nhiệt). Những **thảm cói** đóng băng gieo ra các **Bramble Lobber** nhẹ. **Giải cứu → Codex:** **Farmer**, được canh giữ bởi **The Keeper of the Empty Rows** tại một granary băng — dạy **Agriculture** (thặng dư, seed-vault). ⚑ *Một seed-vault băng vĩnh cửu là có thật (Svalbard); tái tạo động vật đóng băng thành husk là phần hư cấu; nhịp bão tuyết được nén.* ⚑ *Siêu thú **bề mặt** tundra đọc là **ẩm-chứ-không-đóng-băng-sâu** — tan ở bề mặt và ngậm nước, nên chúng phân giải thành **Beast khóa-độ-ẩm** thông thường (đun cạn nước). Một cái xác thực sự bị khóa trong băng vĩnh cửu sẽ **Frost-Encased trước tiên**, qua một lần tan hợp-lý-cộng-tiềm-ẩn trước khi cổng độ ẩm Beast từng áp dụng (nhiệt lượng, App A).* **Worldline & bành trướng:** **Agriculture-first** mở Frostmarch đầu tiên; người của nó là **dân du mục chăn thả** mà bạn có thể **federate** các nhóm của họ thành một commons Green-Terrace — những cộng đồng di động, trung thực với một đồng bằng.

### 3. The Glaciated Spire — lên vào đỉnh núi bị vùi *(⟢ VISION)*

**Hư cấu.** Một thị trấn khai mỏ trên núi **bị vùi bởi một sông băng tiến tới** — quặng vẫn còn trong mạch, lò luyện cao bị nghẹt băng. (Điều này hiện thực hóa "lò rèn sâu bị nghẹt" của tài liệu thành một **lò rèn đỉnh đóng băng**, để con đường metallurgy leo lên thay vì chỉ lặn xuống.) **Hướng:** lên. **Nhìn:** tường serac xanh, băng rơi, một bầu trời nhạt mỏng — frontier duy nhất nơi bạn có thể nhìn *xuống* mây và nhìn *lên* thấy không gì ấm.

**Cơ chế.** *Rút-lạnh theo độ cao:* càng lên cao, **Ember càng nguội nhanh hơn** (⚑ trung thực: không khí trên cao lạnh hơn và loãng hơn, ít oxy nuôi lửa hơn), nên bạn **leo từ điểm-ấm tới điểm-ấm — những lò than cũ bạn thắp lại và những ngọn lửa Ember tự đặt, mọi điểm ấm trên vách là hơi ấm bạn cung cấp** — nấn ná giữa chúng làm hỏng run, cho Spire một nhịp lên không ngừng nghỉ mà không frontier nào khác có. *Di chuyển icefall:* các đấu trường thẳng đứng với **serac rơi như vùng nguy hiểm di động**. **Hỗn hợp kẻ thù:** **Slag** (quặng, đá — tốn nhiệt để nứt nó) cộng husk **Frost-Encased** sông băng; một **Slag Lobber** trút đá từ trên xuống, một **Frost-Encased Charger** phải bị **rã đông trước khi cú lao của nó chạm tới**. **Giải cứu → Codex:** **Smith**, được canh giữ bởi **The Cold-Struck Smith** — một **Warden thân-Slag mà bạn nứt-bằng-nhiệt** — dạy **Metallurgy**. Spire là nhà của điểm neo **đốt-lửa** (nung đá tại vách để làm nó vỡ — khai mỏ từ thời Đồ Đá Cũ đến La Mã), nên các chuỗi **Thermal-Shock** đọc tự nhiên nhất ở đây. **Worldline & bành trướng:** **Metallurgy-first** mở Spire; những người sống sót của nó là **kẻ cố thủ pháo đài** trong các tháp canh — một dân số làm nghiêng về worldline nghiêng-*annex* khó hơn, lạnh hơn (một cú vươn Forge-Lit).

### 4. The Ashen Wald — ngang qua khu rừng chết *(⟢ VISION)*

**Hư cấu.** Một khu rừng **chết đứng** — bị giết bởi cái lạnh kéo dài và chôn trong tro cũ, giờ là một cánh đồng những bộ xương đen khô không bao giờ mục vì không còn gì ấm để làm chúng mục. **Hướng:** ra/ngang. **Nhìn:** những thân đen trơ xương, **tro bay**, **vỉa than tối / những mạch chưa cháy dưới chân** — nhiên liệu lộ ra bất động, không gì cháy cho đến khi bạn đốt nó.

**Cơ chế.** *Địa hình lan lửa:* cả biome là **nhiên liệu Bramble**, nên các đám cháy Blaze của bạn **lan từ husk-này-sang-husk-khác *và khắp cảnh vật*** — sân khấu nơi **Firestorm** thực sự ca hát, và mọi ngọn lửa ở đây rõ ràng là **của riêng bạn**, thắp bởi Blaze, không bao giờ là lửa-mạch môi trường. Nó là một **con dao hai lưỡi**: lửa dọn một bầy, rồi cứ chạy tới lối đi của chính bạn hoặc một **người sống sót đi sau**, buộc bạn vừa đánh *vừa quản lý đám cháy* (không bao giờ như sát thương lên người sống sót — **con người không bao giờ là tiền đặt cược** — mà như một làn đường bạn phải giữ mở cho họ). *Tro-bay tầm-nhìn-thấp* thêm một cơn bão trắng dịu hơn. **Hỗn hợp kẻ thù:** gần như thuần **Bramble** — một **Bramble Charger** bốc cháy khi chạm và mang lửa vào bất cứ thứ gì nó lao qua; một **Bramble Bomber** nổ nhiên-liệu-khí. **Giải cứu → Codex:** **thợ mộc/thợ đốt than**, được canh giữ bởi **The Last Wright** — dạy **Woodcraft** (khung gỗ, than củi), nuôi dòng **Carpenter's/Builder** (liên kết tác động trung thực: than củi là nhiên liệu mà một lò rèn cần). ⚑ *Gỗ chết đứng khô và than lộ thiên thực sự dễ cháy; tro và những mạch than là cũ, có từ trước-đóng-băng, và bất động — không gì cháy cho đến khi Ember thắp nó, vì một khu rừng đang cháy chủ động sẽ mâu thuẫn với một thế giới lạnh.* **Worldline & bành trướng:** một frontier **chung** nghiêng Builder; người của nó là **trại-than** — nhỏ, cơ động, dễ dàng bị **federate hoặc cannibalise** (Wald là nơi cám dỗ cannibalise cắn, vì nhiên liệu của nó *ngay ở đó*).

### 5. The Drowned Coast — ra ngoài biển đóng băng *(⟢ VISION)*

**Hư cấu.** Biển đóng băng giữa cơn sóng trên một bờ chìm; **những lò sưởi khác lấp lánh khắp mặt băng**, đó là lý do đây là **xa lộ bành trướng** của game chứ không phải một craft-vault. **Hướng:** ra. **Nhìn:** một **tấm băng đang nứt dưới chân bạn**, một chân trời những con sóng đóng băng, một hai nhịp cam xa trong bóng tối — bằng chứng rằng bạn không phải tia lửa cuối cùng.

**Cơ chế.** *Băng mỏng — cứ di chuyển:* đứng yên thì tảng băng **nứt**; cú lao của một Charger hoặc một Bomber **làm vỡ tấm băng và thả bạn xuống nước đóng băng** (sát thương lạnh nặng và nguy cơ mất túi đồ — ⚑ ngâm nước lạnh thật chết chóc hơn nhiều so với mức chúng tôi cho phép; làm dịu đi để chơi được). *Uốn thủy triều — nứt và khe nước:* thủy triều vẫn dâng dưới tấm băng theo bộ đếm, nên các tảng băng **uốn, nứt mở thành khe nước, và nghiến đóng lại**, **mở và đóng các lối đi** thay vì làm ngập chúng, nên bạn đọc mặt băng cẩn thận như đọc kẻ thù (⚑ băng biển thực sự mở ra **khe nước** dưới ứng suất thủy triều — không cần ngập bề mặt; chỉ có bộ đếm được nén). **Hỗn hợp kẻ thù:** **Beast** (husk biển ngậm nước, khóa-độ-ẩm) và husk **Frost-Encased** băng-biển; một **Beast Lobber** ném từ vùng nước mở. **Giải cứu → Codex:** bờ biển **không có craft-Warden** — nhịp của nó là **nút cộng đồng lò-sưởi-leo-lét** bên kia mặt băng (thắp lại → federate → annex → cannibalise), bề mặt **bành trướng** giàu nhất trong game. (Một người sống sót **Salt-Keeper** có thể dạy **Preservation** ở đây — ⟢ VISION, đã gắn cờ — vì lương thực bảo quản là thứ khiến việc băng qua biển tới các cộng đồng khác trở nên khả thi.) **Worldline & bành trướng:** **chung**, và là xương sống của trục chính trị — một **Rekindled Commons** liên bang hóa các lò sưởi ven biển, một **Hollow Warmth** cannibalise chúng.

### The First Hearth — nơi mọi con đường kết thúc

Mọi frontier cuối cùng đều chỉ về **tàn tích lâu đời nhất, lò sưởi sâu nhất** — ngọn lửa được chăm đầu tiên từng bị để nguội. Nó không hẳn là một biome thứ sáu mà là **điểm cuối mà mọi worldline hội tụ về** (**First Warden** của tài liệu, người canh giữ *chính việc ghi nhớ*). ⟢ VISION, hạng đỉnh cao; sở hữu chung với các phần end-game và worldline. Ghi chú môi trường duy nhất của nó ở đây: nó **bất-khả-tri về hướng** — những bậc thang cuối xuống được *chạm tới từ bất kỳ frontier nào worldline của bạn đã leo*, nên con đường tới đó đọc được như lịch sử của bạn.

### Vì sao là những cái này, không phải những cái khác

Mỗi frontier là một **trạng thái nhiệt động mà một thế giới lạnh thực sự chạm tới** — lún sụt, băng biển, băng hà, chết-đứng, băng vĩnh cửu — nên phần hư cấu vẫn khoa-học-trước với sự phóng khoáng chỉ ở *thang thời gian*. Những sự bác bỏ rõ ràng giữ cho xương sống nguyên vẹn: **không biome núi lửa/dung nham** (hơi ấm môi trường đảo ngược luận đề ⚑), **không cõi "bị nhiễm độc"/ma thuật** (kẻ thù là entropy, không phải một thế lực bóng tối), và **không biome mà "boss" là một đội quân đối địch** — mọi kẻ thù là cái lạnh mang hình dáng một husk, và **con người không bao giờ là tiền đặt cược**. Sự đa dạng đến từ *cách cái lạnh chiếm lấy nơi đó* và *cái đó tốn gì cho một ngọn lửa*, không bao giờ từ việc nhập khẩu một thế giới ấm hơn.

### Thứ tự dàn trải có thể xây

1. **Bây giờ (SHIPPED):** hành trình lặn Buried Warren — baseline, nguyên vẹn.
2. **Stage 1 — tham số biome + Frostmarch Tundra.** Dạy bản-đồ-nút một trường `biome`; ship cơ chế mới rẻ nhất trước — **bão trắng** (một shader tầm nhìn + vector gió tái dùng các phòng hiện có). Chi phí kỹ thuật thấp nhất, phần thưởng "không chỉ là đi xuống" lớn nhất.
3. **Stage 2 — Glaciated Spire.** **Rút-lạnh theo độ cao** tái dùng khái niệm đồng hồ Ember-nguội; thêm bố cục đấu trường thẳng đứng.
4. **Stage 3 — Ashen Wald.** **Địa hình lan lửa** phụ thuộc vào **Heat Modes/Blaze** (PROGRESSION Phase 1–2), nên gác nó ở đó; nó là phần thưởng khiến Blaze cảm thấy thiết yếu.
5. **Stage 4 — Drowned Coast.** Nặng-hệ-thống nhất (trạng thái sàn động, bộ đếm thủy triều) và là hành lang **bành trướng**, nên hạ cánh nó cùng với trục bành trướng (Phase 4).
6. **Điểm cuối — the First Hearth** với đỉnh cao Phase 5.

Mỗi stage là cộng thêm, mỗi frontier đọc được cái lạnh của nó trên màn hình trong một cái liếc, và — cái cốt lõi — **không có hai run nào phải đi cùng một hướng vào bóng tối lần nữa.**
---

## 6. Bản Đồ Thế Giới & Bành Trướng — RECLAIM, FEDERATE, hay ANNEX

*Chủ quản thiết kế: bành trướng/chinh phục. Phần này trả lời câu hỏi thứ hai của khách hàng — có chinh phục không, và nó tốn gì — rồi dung hòa nó với luận đề cốt lõi trước khi thiết kế bất cứ thứ gì. Mọi thứ ở đây đều là **⟢ VISION**: nó phát triển hạt giống "Other Hearths" của §3 (nút lò sưởi đang lụi + tín hiệu bầu trời giữa các run) thành nguyên một lớp bản đồ, và không phần nào trong đó ship hôm nay. Nó **không** thêm ending mới: §10 sở hữu năm cuộc rekindling, còn bành trướng chỉ khoác một lớp áo cho một trong số đó.*

### Câu trả lời thành thật trước đã — chinh phục theo nghĩa đen sẽ phản bội xương sống

Hãy để tôi làm nhà phê bình trước khi làm nhà thiết kế. Kẻ phản diện của REKINDLED là **entropy**; tín điều của nó là **con người và tri thức, không phải chiến lợi phẩm**; các boss của nó **lụi tàn, chúng không chảy máu**; và luật sắt của nó là **con người không bao giờ là vật đặt cược.** Ghép chinh phục quân sự 4X kinh điển lên trên đó — tiến đánh một thị trấn survivor đối thủ, giết lính phòng thủ, chiếm kho và lãnh thổ của nó — thì mọi cam kết chịu lực đó gãy tan cùng một lúc. Bạn sẽ đã lén đưa vào một kẻ phản diện *thứ hai* (con người đối thủ) mà cả câu chuyện đã dành nhiều chương khẳng định là không tồn tại; bạn sẽ đã biến con người thành thứ có thể cướp bóc; và bạn sẽ chĩa toàn bộ kho vũ khí của người chơi vào chính cái thứ mà game nói mới là mấu chốt. **Nên là không: không có chinh phục quân sự PvP nhắm vào các survivor khác trong REKINDLED, và cũng không nên có.** Ai muốn game đó là muốn một game khác, và ghép nó vào sẽ moi ruột game này.

Nhưng "không có quân đội" không phải là "không có bành trướng." Một thế giới chỉ có đúng một lò sưởi âm thầm mâu thuẫn với luận đề *hơi ấm được truyền tay từ người này sang người kia.* Câu hỏi thật sự không phải là *liệu* bạn có chiếm các vùng đất khác, mà là *hơi ấm lan ra khắp chúng như thế nào* — và ẩn trong câu hỏi đó là một trục sắc bén, đầy hệ quả, nơi giấc mơ hiếu chiến, tập quyền, xây-đế-chế được thể hiện trọn vẹn, mà kẻ thù của nó vẫn mãi chỉ là cái lạnh.

### Bản Đồ Thế Giới — hơi ấm như một vệt loang trải trên nền trắng (⟢ VISION)

Bên trên khoảng đất trống của làng là một bàn cờ thứ hai, thu nhỏ toàn cảnh: **Bản Đồ Thế Giới**, lục địa băng giá mà cái lạnh đã chiếm về mọi hướng. Lò sưởi của bạn là một bông hoa vàng đơn độc giữa cánh đồng trắng. Rải rác trên danh sách tiền tuyến của §5 — the Buried Warren, the Drowned Coast, the Glaciated Spire, the Ashen Wald, the Frostmarch Tundra — là **những lò sưởi khác**, mỗi cái được vẽ theo trạng thái hơi ấm của nó và đọc được chỉ trong một cái liếc:

- một phế tích **tối** — một cộng đồng đã tắt (mục tiêu thắp lại/giải cứu thuần túy);
- một tàn than **đang lụi** — một cộng đồng đang tàn *ngay lúc này* (nhịp lòng-thương-vs-thực-dụng của §3);
- một ngọn lửa độc lập **vững** — một cộng đồng vẫn sống và ấm bằng chính sức mình (thứ bạn không thể đơn giản "giải cứu").

Chạm tới bất kỳ cái nào trong số chúng đều là một **run vào tiền tuyến đó** (cơ chế do §5 sở hữu). Bản Đồ Thế Giới là *lớp chiến lược giữa các run* nơi bạn chọn tiền tuyến nào để dấn tới, rồi ngắm hơi ấm đáp lại: khi bạn thành công, GWI lan ra ngoài từ lò sưởi của bạn như một **vệt tan băng** hữu hình gặm dần nền trắng — tuyết xám lại thành đất ẩm, một hành lang tan băng nối lửa của bạn tới cái tiếp theo. *(Đọc trên màn hình: bản đồ phần lớn là trắng; mọi hơi ấm bạn giữ đều là màu, và hình hài nền văn minh của bạn chính là hình hài của vệt loang.)* Tiền tuyến nào mở ra *đầu tiên* bị thiên lệch bởi phát minh đầu tiên bạn phục hồi — chuỗi worldline của §4 — nên câu chuyện bành trướng của bạn khởi đầu ngay tại nơi câu chuyện tri thức của bạn bắt đầu.

### Phổ Bành Trướng — một trục, bốn động từ thành thật (⟢ VISION)

Khi bạn chạm tới một cộng đồng, bạn chọn cách hơi ấm của nó gia nhập thế giới. Một trục lựa chọn, không có đáp án đúng, chạy từ hào phóng nhất tới tối tăm nhất:

| Động từ | Nó là gì | Bạn được | Nó tốn gì | Đọc trên màn hình | Đẩy ending về phía |
|---|---|---|---|---|---|
| **RECLAIM** / thắp lại | Rekindle một lò sưởi **đã chết hoặc đang lụi**; giải cứu người của nó | Survivor biết một nghề bạn có thể chưa có; GWI tăng nhanh hơn (hai bàn tay chuyền ngọn lửa) | Hơi ấm + vật liệu của chính bạn để thắp lại; ít chiến lợi phẩm | Một phế tích tối bùng lên vàng; các dân làng mới có tên bước vào | Lòng thương → **The Rekindled Commons** (§10) |
| **FEDERATE** / liên minh | Liên minh với một lò sưởi **đang sống, độc lập**; họ vẫn là của riêng họ | Trao đổi tri thức; các mục Codex thật được thắp lại ở *cả hai* nơi; **tiền tuyến của họ mở ra** cho các run của bạn; thêm một giọng nói sống trên bản đồ | Bạn không thu nạp người hay dân số của họ; tập quyền chậm hơn | Hai ngọn lửa nối bằng một hành lang ấm, cả hai vẫn cháy | Đa nguyên → **lớp áo FEDERATE** của Commons I (§10) |
| **ANNEX** / thu nạp | Áp đảo họ bằng hơi ấm cho tới khi hòa nhập thành lựa chọn hợp lý của chính người họ; lấy cả người **lẫn** lãnh thổ về dưới một lò sưởi vĩ đại | Hơi ấm hiệu quả, tập quyền; dân số + lãnh thổ của họ tính là *của bạn*; một thanh đơn lớn hơn | Ít cộng đồng sống hơn trên bản đồ — một trung tâm nơi từng có nhiều; không có ai bị sát hại | Lửa của họ bị hòa vào ngọn lửa trung tâm đang lớn dần của bạn; một lò sưởi nơi từng có hai | Tập quyền → **lớp áo ANNEX** của Commons I (§10) |
| **CANNIBALISE** | Rút cạn hơi ấm + vật liệu của họ; để lửa tắt | Một khoản lợi tức tức thời lớn | **Từ bỏ việc giải cứu họ**; ít mục được thắp lại hơn; một vết lõm GWI dai dẳng; lan rộng Long Dark | Tàn than xa xôi bạn rút cạn tối lại rồi tắt; vệt loang *rút lui* ở đó | Trục lòng thương → **The Hollow Warmth** (IV) (§10) |

Hai trong số này đã sẵn sống trong DNA của tài liệu (RECLAIM = "thắp lại" của §3; CANNIBALISE = "rút cạn" của §3). Hai động từ giữa mới mẻ là nơi trò chơi chính trị ngự trị — và sắc bén nhất trong số đó là **ANNEX**, bởi nó là cái cuối cùng cho khách hàng có được "chinh phục" của họ, một cách thành thật.

**FEDERATE với ANNEX là một lựa chọn về tính đa nguyên của các cộng đồng sống, không phải một con số thương vong và không bao giờ là một thứ thuế tri thức.** Một đồng minh liên bang giữ lò sưởi riêng, người riêng, ánh sáng vững của riêng họ trên bản đồ — thêm một giọng nói chăm ngọn lửa bên cạnh bạn. Sáp nhập hòa họ vào một lò sưởi vĩ đại của bạn: bạn được dân số và lãnh thổ của họ như hơi ấm thô, hiệu quả, nhưng bản đồ giờ chỉ còn một trung tâm nơi từng có một mạng lưới các ngọn lửa độc lập. Điều then chốt là, **tri thức tự thân không bao giờ bị đặt cược theo cách nào cả.** Codex phát minh là cố định, xếp hạng theo tác động, và thành thật (App A/D); không cộng đồng nào sở hữu một "phương ngữ" riêng của nó và không ai có thể xóa một mục khỏi nó. Cái mà lựa chọn dịch chuyển là *bao nhiêu cộng đồng sống mang ngọn lửa* và *kênh phục hồi đọc ra sao*: một mạng lưới các ngọn lửa đồng minh thắp lại các mục thật ở nhiều nơi cùng lúc; một lò sưởi vĩ đại thắp lại vang dội từ một điểm duy nhất. Nếu bạn muốn kết cấu riêng theo từng cộng đồng, nó sống trên một **bề mặt lore-cộng-đồng riêng biệt, được gắn cờ rõ ràng** — không bao giờ trên sổ ghi phát minh. Một bản đồ nhiều ngọn lửa đồng minh sống trong nhiều giọng; một Lò Sưởi vĩ đại sống vang dội trong một giọng. Cả hai đều ấm. Chúng không phải cùng một nền văn minh, và màn hình cuối sẽ nói vậy.

### Một play-style chinh phục, mà không ai bị sát hại (⟢ VISION)

Giấc mơ bành-trướng-hiếu-chiến, được làm cho thể hiện được mà không một survivor nào bị giết:

- **Bạn chiến với cái lạnh để *chạm tới* họ.** Chiến dịch nhắm vào một cộng đồng kiêu hãnh, vẫn còn ấm là cái run tàn khốc băng qua tiền tuyến thù địch của nó để tới được cổng nó — bạn luôn chiến với husk và gradient, không bao giờ với người của nó.
- **Bạn gây áp lực lên họ về chính trị và kinh tế, không phải quân sự.** Đòn bẩy của bạn là **lưới-hơi-ấm** của bạn: thặng dư, mức hoàn thiện Codex, tầm với của vệt tan băng của bạn. Một cộng đồng đang lụi liên bang dễ dàng. Một cộng đồng kiêu hãnh, tự cung tự cấp thì kháng cự — và **sáp nhập nó đòi hỏi áp đảo nó bằng hơi ấm** triệt để tới mức hòa vào lò sưởi của bạn trở thành lựa chọn hợp lý của chính người họ để sống sót. Bạn thắng "cuộc chiến" bằng cách khiến lửa của mình là cái hiển nhiên để tụ quanh, chứ không phải bằng cách phá vỡ lửa của họ.
- **Sáp nhập là một động từ chính trị/kinh tế — tập quyền, không bao giờ là cướp phá.** **Con người không bao giờ là vật đặt cược** — ngay cả CANNIBALISE cũng không bao giờ cho thấy một survivor bị giết trên màn hình; nó cho thấy một *ngọn lửa* tắt và một cuộc giải cứu *không được thực hiện.* Sức nặng của những lựa chọn tối tăm luôn là **điều bạn đã chọn không mang theo**, không bao giờ là một cái xác.

Vậy nên kẻ xây-đế-chế có được một giấc mơ quyền lực thật sự — một đế chế Lò Sưởi tập quyền, hiệu quả trải ngọn lửa vĩ đại đơn nhất của nó khắp bản đồ — và trả giá bằng tính đa nguyên của các cộng đồng sống, một trung tâm thay vì một mạng lưới, chứ không phải bằng máu và không phải bằng tri thức mất mát. Kẻ phản diện vẫn là entropy suốt cả chặng đường xuống đáy.

### Bành trướng khoác áo cho ending như thế nào — một hình hài chính trị, không phải một thế giới mới (⟢ VISION)

Bành trướng thêm **không có ending thứ sáu và không có trục thứ sáu.** Nó khoác lại áo cho ending mà §10 đã sở hữu: **The Rekindled Commons (I)** — ấm, nhân từ, đông đúc — luôn là điểm đến của con đường lòng thương, và Phổ chỉ đơn giản cho thế giới đó **hình hài chính trị** của nó, hiện lên trên con dấu thế giới:

- **Federate-chủ đạo + lòng thương → lớp áo FEDERATE của Commons I.** Ending I đọc ở dạng đa nguyên nhất của nó: một **vòng các lò sưởi đồng minh độc lập** ở chân trời, một mạng lưới nhiều ánh sáng, đa nguyên chính bởi các thành viên của nó chưa bao giờ bị thu nạp. Con dấu đặt tên cho liên minh; đoạn kết đặt tên cho các mục mà một mạng lưới các bàn tay đã thắp lại.
- **Annex-chủ đạo + lòng thương → lớp áo ANNEX của Commons I: "The One Great Hearth."** Vẫn Commons đó, nhưng **tập quyền** — một ngọn lửa nhân từ khổng lồ nơi một liên bang cho thấy nhiều, vẫn ấm và vẫn đông đúc, chỉ là được tụ về một điểm duy nhất. Cách đọc của Ember là mập mờ, không phải kết tội: *"Ngươi đã gom mọi ngọn lửa vào một. Nó ấm. Nó cũng là cách duy nhất còn lại để được ấm ở đây."* Đây là một độ nghiêng tập quyền của Commons I, **không bao giờ** là "Cướp phá"; ending độc canh hiếu chiến, **The Long Watch (II)**, là một con đường hoàn toàn khác (độc canh × ngân-hàng-nhanh × đối đầu — §10), không thể chạm tới bằng việc sáp nhập bất kỳ ai.
- **Cannibalise-chủ đạo → trục lòng thương uốn về The Hollow Warmth (IV)** (§10), sắc bén hơn. Vệt loang mỏng và đang rút ở các rìa; những lò sưởi bạn rút cạn là những lỗ tối trên bản đồ — chiến thắng cảnh tỉnh với một tấm bản đồ làm bằng chứng: *bạn đã dời cái tối tới nơi bạn không thể thấy nó.*

Như mọi trục của §10, phần này **rọi đèn** vào một hình hài chính trị của một thế giới có thể chạm tới từ bất kỳ save nào; nó không bao giờ đóng cổng những ending nào tồn tại. Nó chỉ có nghĩa là hai người chơi cùng chạm GWI 1.0 với các thị trấn đầy đủ có thể đứng trước một **liên bang đa nguyên** và một **lò sưởi vĩ đại đơn nhất** rồi đọc ra sự khác biệt mà không cần một tooltip.

### Các mối liên hệ — worldline, tiền tuyến, co-op (⟢ VISION)

- **Worldline (§4).** Phát minh đầu tiên của bạn thiên lệch tiền tuyến nào mở ra trước, nên **cuộc gặp cộng đồng đầu tiên — và lựa chọn Phổ đầu tiên bạn thực hiện trên nó** — định giọng bành trướng của bạn từ sớm và gieo lớp áo chính trị cho ending của bạn, đúng như chuỗi §4 gieo phần còn lại.
- **Tiền tuyến (§5).** Các cộng đồng ngồi đại khái một-mỗi-tiền-tuyến trên danh sách của §5; **FEDERATE theo đúng nghĩa đen là cách một tiền tuyến bị khóa mở ra** cho các run của bạn — bành trướng được đấu dây vào việc bạn có thể chạm tới nội dung nào.
- **Co-op (§11).** Các lựa chọn Phổ là **nhịp đạo đức chung**, được giải quyết bởi luật đồng thuận sẵn có của §11: RECLAIM ghi vào toàn đội ngay khoảnh khắc lò sưởi được thắp lại; **FEDERATE / ANNEX / CANNIBALISE cần đồng thuận** (như cổng DEEPER và cuộc bỏ phiếu lò-sưởi-đang-lụi), nên hai người chơi tranh luận về hình hài chính trị của thế giới họ chia sẻ. Thế giới vẫn thuộc quyền host, con dấu chính trị được chia sẻ, và **cả hai cái tên đều lên con dấu di sản** dưới bất kỳ hình hài nào họ cùng xây.

### Chi phí xây dựng, một cách thành thật

Đây là một **lớp ⟢ VISION đáng kể, không phải một núm tinh chỉnh** — và lớn hơn cái hạt giống §3 mà nó lớn lên từ đó. Nó cần: một **màn hình Bản-Đồ-Thế-Giới** (bàn cờ thu nhỏ mới + trạng thái của nó) đặt chồng lên làng; một **thực thể cộng đồng** với các trạng thái hơi ấm và nội dung được viết riêng theo từng tiền tuyến; **bốn kết cục Phổ** đấu dây vào GWI, dân số, và **trạng-thái-cháy / kênh phục hồi** (mục Codex thật nào được thắp lại, và ở bao nhiêu nơi) — cộng với hình học chính trị của bản đồ, một mạng lưới nhiều ánh sáng đối lại một trung tâm; và một cách đọc **con-dấu-chính-trị** trên màn hình ending khoác áo cho Commons I. Nó chạm vào Codex phát minh **chỉ** để thắp lại các mục cố định — không bao giờ để thêm, thu hẹp, hay xóa chúng; bất kỳ hương vị riêng theo cộng đồng nào cũng sống trên một bề mặt lore gắn cờ riêng. Cannibalise và reclaim tái dùng các móc kết cục của §3; **federate và annex là các hệ thống mới.** ⚑ *Tự do sáng tạo: hơi ấm "lan như một vệt loang" và các cộng đồng "hòa vào" nén sự khuếch tán xã hội và nhiệt động chậm chạp thành một nhịp bản đồ dễ đọc — hướng (hơi ấm được chăm sóc lan ra, hơi ấm bị bỏ mặc rút lui) là thành thật; tốc độ là kịch nghệ.* Không phần nào trong đó ship hôm nay; nó là điểm đến mà thế giới Ember-đơn-độc được viết hướng tới — công việc trọn vẹn của Ember cuối cùng là khiến chính nó **không còn là cái cuối cùng nữa.**


---

## 7. Đầu Game — Đêm Ấm Đầu Tiên

> **⟢ SHIPPED vs VISION — đọc phần này một lần, nó áp dụng cho cả mục.** Mọi thứ mà đêm ấm đầu tiên được *xây dựng trên* đều ship hôm nay: **Kindle → Bloom** (năm giai đoạn diễn thế, một bước chỉ số phẳng + **chọn-1-trong-3 boon** mỗi lần) → boon/Bloom reset mỗi lần descent; **Soil**, **GWI-dưới-dạng-thời-tiết**; combo 3 đòn + i-frame của dash + guard/perfect-parry; các cảnh báo **vùng nguy hiểm đỏ**; **một rescue-attunement** được ghi khi chạm; căn phòng boss **Warden**; và **bank-hoặc-mất** ở cổng. Hai thứ mà chương này chỉ *báo trước* là **⟢ VISION** — được ghi lại, không có trong build, không bao giờ hiển thị như đang chạy: **HEAT MODE** đầu tiên mà một cuộc giải cứu nghề nào đó một ngày kia sẽ trao cho bạn, và các **HUSK FAMILIES** vật chất (Bramble/Beast/Slag + Frost-Encased) sẽ phủ lên trên danh sách hành vi. Bất cứ đâu chúng hiện ra dưới đây chúng đều mang dấu ⟢; không gì dưới nó chơi được lúc này.

Một tới hai giờ đầu tiên. Từ một tàn than đang lụi đơn độc trong một phế tích lạnh đến một lò sưởi lớn hơn hẳn so với buổi sáng, với thêm một gương mặt bên cạnh.

### Giờ Đầu Tiên, Như Nó Ship

**Mở màn lạnh lẽo.** Đen, rồi một âm thanh trước một hình ảnh: một tiếng *tách tách tách* khô khốc, một ngọn lửa cố bén và thất bại. Một ánh sáng nhạt hiện ra — màu của một hòn than ở phút cuối cùng của nó — và GIỌNG NÓI cất lên sát bên và hơi sợ hãi, theo kiểu bạn dỗ dành thứ gì đó nhỏ bé:

> *"…đấy. Ngươi đã trụ được. Tốt. Ta tưởng — không. Kệ ta đã tưởng gì. Ngươi tỉnh rồi, và ta vẫn cháy, và đó là hai thứ cái tối không lấy được tối nay."*

Khung hình mở rộng: một con MÈO lông vàng trên nền đá nứt nẻ, hơi thở bốc khói, mọi thứ phủ băng xanh — ánh sáng, sàn nhà, những cây chết trơ lá ở rìa phế tích. Đây là tín hiệu chủ đạo mà bạn dành cả game để học cách đọc: **nhiệt độ của thế giới chính là màu sắc của nó**, và ngay lúc này nó gần như đã tắt. Một điểm xa xôi lóe cam mờ ở đỉnh khung hình — **BONFIRE HEARTH** của khu định cư đổ nát của bạn — và Ember, ấm áp áp vào ngực bạn, kéo bạn về phía nó. Quãng đi ngắn đó *chính là* câu đầu tiên của phần hướng dẫn: lạnh khắp nơi, một điểm ấm, đi về phía nó.

**Supply Gate.** Ember dạy bằng cách khao khát điều gì đó. *"Ta cảm thấy họ ở dưới đó. Người mà ngọn lửa đã bỏ lại, và những thứ ta có thể mang về nhà. Ta không lấy được. Ngươi thì có thể."* Một ngọn hải đăng dẫn đường — một sợi chỉ mảnh ánh sáng ấm, thứ ấm duy nhất trên màn hình — kéo xuống về phía **Supply Gate**. Bạn DESCEND.

**Máu đầu tiên, được làm cho dễ đọc.** Căn phòng đầu tiên là một đấu trường nhỏ kín, sàn nghiêng về phía máy quay. Một HUSK duy nhất bung ra từ một đống vật chất chết — rỗng, không thù địch. *"Nó không giận đâu. Nó chỉ lạnh, đang cạn dần. Đáp lại nó đi."* Nó lấy đà cho một cú lao và sàn dọc theo đường đi của nó nở ra một **VÙNG NGUY HIỂM ĐỎ** — lời hứa cốt lõi của game được làm cho hữu hình: *mọi đòn đều được tô vẽ trước khi giáng xuống.* Bạn DASH (cú lăn phased xuyên sạch qua husk, một nhịp tim i-frame) rồi ra đòn với combo 3 đòn — vòng cung phải, tát ngược trái, đòn kết **CAN QUET** 360° hất husk văng khỏi mặt đất. Những hạt **KINDLE** đầu tiên bay lên và đọng vào Ember, nó sáng lên một chút xíu. Sáu HP, một mối đe dọa cam kết mỗi lần: nó *đọc được*, và việc đọc được chính là cả cảm giác — cái tối có thể đáp lại.

**Bloom đầu tiên.** Sau vài kill, một ngưỡng được kích và con mèo **BLOOM** — một xung động và một chuyển dịch trong ember-aura quanh chân — bước một giai đoạn lên bậc thang diễn thế (**Ash → Pioneer → Herb → Thicket → Canopy**; khung diễn thế nguyên sinh ở §3, vật lý ở App A). Mỗi Bloom là một bước chỉ số phẳng **cộng một lượt draft BOON chọn-1-trong-3** mà tất cả **reset ở lần descent tiếp theo** (mô hình Soil/Bloom → §1).

**Cuộc giải cứu đầu tiên — nhịp mà cả game được xây quanh nó.** Hai phòng sau, một survivor co ro lờ mờ trong một bong bóng băng. Bạn phá nó; họ đứng dậy, chớp mắt, và **theo sau bạn, lê từ phòng này sang phòng khác.** Giọng Ember dịu lại: *"Đấy. Đó mới là phần thưởng. Không phải kim loại — mà là họ."* Khoảnh khắc bạn giải phóng họ nó **BANK**: một **ATTUNEMENT** vĩnh viễn khóa vào — chẳng hạn **Bramble Ward (+2 HP, Flora)**, được áp dụng lại ở đầu mỗi lần descent tương lai — và nó không thể mất trong bóng tối. Attunement không-cộng-dồn và con mèo vẫn là một **kẻ săn mồi thủy tinh 6-HP** — phán quyết đó, và nơi độ dày thực sự đến từ đâu, sống ở §2. Con người an toàn khoảnh khắc họ được mang đi; chiến lợi phẩm thì không.

**Warden đầu tiên.** Đỉnh điểm của một lần descent sớm là căn phòng **Warden** — cái lạnh "đã học một hình hài." Đánh nó và nó không chảy máu; nó **lụi tàn và tắt**, như một ngọn lửa thiếu khí — một lần thắp lại, không bao giờ là một trại nuôi (§3).

**Lần bank đầu tiên.** Một căn phòng đã dọn sạch mở ra hai CỔNG — **DEEPER** (giàu hơn, khó hơn) hoặc **HOME** (bank) — và Ember phơi bày mức đặt cược rõ ràng, không cần menu: *"Túi đầy, và ánh sáng sau lưng ta đã mỏng. Dấn tới, và ta có thể mang gấp đôi — hoặc ngã trong bóng tối và chẳng mang được gì. Nhà thì ấm. Tùy ngươi."* Bạn chọn HOME và nổi lên với chiếc túi còn nguyên.

**Cuộc tan băng đầu tiên bạn có thể THẤY.** Ở lò sưởi bạn tiêu những gì đã mang về. Một công trình NGỦ ĐÔNG — the Cabin — có một survivor *biết* nó, nên nó thành một **BLUEPRINT**; giao nhiệm vụ tài nguyên của nó và nó thành **VẬN HÀNH**. Thế giới đáp lại *trên màn hình*: ngọn bonfire phồng lên một nấc, ánh sáng môi trường xoay vài độ khỏi xanh về phía vàng, và — phần thưởng bạn cảm thấy trong lồng ngực — **một cây chết ở rìa khoảng trống nảy ra một chiếc lá đơn độc.** Đó là GWI nhích lên, được kết xuất dưới dạng thời tiết, không phải một con số. Đêm ấm đầu tiên chính xác là thế này: một ngọn lửa lớn hơn hẳn buổi sáng nay, thêm một gương mặt bên cạnh, ánh sáng không còn hẳn xanh như trước.

### ⟢ Những Gì Đêm Này Báo Trước (Lớp Vision)

Hai cánh cửa mà đầu game *chỉ tay tới* nhưng không mở — được gắn cờ để không ai nhầm chúng là đang chạy:

**⟢ HEAT MODE đầu tiên của bạn.** Survivor bạn giải phóng *biết một nghề*, và câu chuyện mồi cho bạn kỳ vọng rằng tri thức đó một ngày sẽ dạy ngọn lửa một cách vận động mới: giải cứu **Smith → CONDUCTION / "Blaze"** (bỏng-chạm DoT rớt lại từ những husk bị choáng); **Builder → RADIATION / "Sear"** (aura bức xạ + crit nóng hơn); **Farmer → CONVECTION / "Draft"** (một đòn kết luồng khí bốc lên kéo các husk nhẹ vào trong). Các Mode sẽ đổi giữa run và tại các Rest-Hearth, và sau các cuộc giải cứu của chúng **Mode và Kingdom tách rời** nên các cặp chéo là hợp lệ (→§2). **Không phần nào trong đó có trong build** — hôm nay ngọn lửa là một động từ; đây là lớp mà đầu game *được viết hướng tới*, không phải được ship bên trong.

**⟢ Husk FAMILIES phủ lên danh sách hành vi.** Mọi thứ bạn chiến trong giờ đầu đều là **hành vi** thuần túy — Husk / Charger / Lobber / Bomber / Warden (cách nó tấn công). Lớp vision thêm một **họ vật chất** trực giao — Bramble (khô, bắt lửa) / Beast (ẩm, gated bởi độ ẩm) / Slag (vô cơ, ~0 kindle) cộng với **Frost-Encased** như một trạng thái theo độ sâu (nó *làm bằng gì*) — và hai thứ **kết hợp**: một **Bramble Charger** báo hiệu cú lao của nó và, dưới ⟢ Blaze, bắt lửa giữa chừng cú lao; một **Slag Bomber** phải bị *nứt vỡ* trước khi vòng cảm-tử của nó có thể bị kích nổ; một **Frost-Encased Lobber** phải bị *rã băng* trước khi cú ném vòng cung của nó chạm đích. Hành vi = cách nó xông tới bạn; họ = cái giá để dập tắt nó. Ship hôm nay: chỉ hành vi.

### Sự Phân Nhánh Play-Style Bắt Đầu Từ Đây (Không Có Đường Ấm-Nhưng-Thô)

Không gì trong giờ đầu tiên là trung tính. Survivor đầu tiên, phát minh đầu tiên, công trình đầu tiên, và lựa chọn HOME-vs-DEEPER đầu tiên của bạn đã và đang khắc nên một lịch sử — ba nhánh sớm cụ thể:

| | **Kẻ hiếu chiến Smith-trước** | **Người định cư Farmer-trước** | **Kẻ dấn sâu tham lam** |
|---|---|---|---|
| Cuộc giải cứu đầu | Smith *(→ ⟢ Blaze về sau)* | Farmer *(→ ⟢ Draft về sau)* | ai sâu nhất |
| Hạt giống nguyên mẫu | **The Bright Predator** | **The Slow Bloom** | Bright Predator nghiêng-tham-lam |
| Công trình đầu | **Forge** (Metallurgy, +dmg) | **Crop Bed** (Agriculture, mang một Provision) | bank ít, xây muộn |
| Khẩu vị rủi ro | dấn tới, nhưng bank cú kill | bank sớm, bank thường xuyên | luôn chọn DEEPER |
| Cách đọc sớm của Ember | *"Ngươi áp nhiệt lên mọi thứ ngươi chạm vào."* | *"Ngươi không bao giờ đứng ở mép vực."* | *"Ngươi giữ chiếc túi quá lâu."* |

Ba đường chỉ là những nhánh mà giờ đầu tiên làm cho *hiển hiện*; la bàn sáu-cực đầy đủ (**Bright Predator / Slow Bloom / Hearthkeeper / Archivist**, cộng **Kindler / Rot-Reaper** một khi ⟢ VISION cập bến) sống ở §2, và ở đây các bản dạng được *thể hiện*, không phải được tìm thấy (→§9). Phát minh đầu tiên bạn thắp gieo một **worldline** (→§4), và các run về sau có thể lao ra về phía các **tiền tuyến** khác nhau (→§5).

### Học Vòng Lặp (Không Có Bức Tường Chữ)

Vòng lặp — **descend → chiến → giải cứu → bank → xây → ấm** — được dạy bởi ba kênh lặng lẽ, không bao giờ là một cuốn cẩm nang:

- **Giọng nói phản ứng của Ember** — một ý mỗi nhịp, kể lại điều đang ở trước mặt bạn ngay khoảnh khắc nó quan trọng.
- **Mẹo điều khiển đúng lúc ở lần chạm đầu tiên** — tấn công, dash, và guard/perfect-parry mỗi thứ được dạy ở cảnh báo liên quan đầu tiên của nó, rồi không bao giờ nhắc lại nữa.
- **Ngọn hải đăng dẫn đường** — sợi chỉ ấm duy nhất luôn chỉ tới thứ ý nghĩa tiếp theo; nơi *ấm = quan trọng*, đi theo ánh sáng *chính là* bản năng đúng đắn.

### Solo và Co-op Trong Giờ Đầu Tiên

**Solo** là cung bậc phía trên — một con mèo, một giọng nói lo âu, 6 HP, không có revive mặc định; van trợ năng (độ khó assist/story, mở-rộng-cảnh-báo, co giãn UI, một token solo revive *tùy chọn*) là một thiết lập được chọn, không phải mức nền (các núm → App D). **Co-op** đóng khung lại các nhịp đó thành cho-mượn-tia-lửa, và hai thứ mới mẻ với giờ đầu: **cuộc chuyền-tia-lửa đầu tiên** — một người chơi phá bong bóng băng và đứng mũi chịu sào trong khi survivor được giải phóng nép sau người *kia*, và cuộc giải cứu **bank toàn đội** ngay khoảnh khắc nó được giải phóng, dù chiến lợi phẩm không bao giờ gộp chung (mỗi người mang giữ một **túi RIÊNG**); và **cú gutter đầu tiên** — một Sparkbearer ở 0 HP không chết, nó **gutter**, và một đồng đội giữ **Rekindle** để hồi sinh ở HP thấp. *Bạn có thể mất một người mang mà không bao giờ mất ngọn lửa.* Toàn bộ tia-lửa fiction, kinh tế revive, co giãn theo đội, và bỏ-phiếu-cổng → §11.

### Mức Đặt Cược Đầu Tiên — và Mất Mát Đầu Tiên

Canh bạc thật đầu tiên đến vào khoảng run hai hoặc ba: túi phình, hải đăng về nhà đã mỏng đi. DEEPER cho có lẽ gấp đôi, hay HOME để giữ những gì là của bạn. Đây là trái tim của game thu nhỏ — **thứ tiền tệ duy nhất có thể mất là chiến lợi phẩm; con người và attunement được bank tức thì.**

**Mất mát đầu tiên** là một người thầy, và gần như mọi người chơi đều gặp nó ở đây. Bạn dấn DEEPER khi còn 6 HP, đọc sai một vùng đỏ trong một căn phòng bận rộn hơn, và ngã trong bóng tối. Màn hình lạnh đi, chiếc túi đổ ra, bạn nổi lên với **phần lớn chiến lợi phẩm bị mất.** Hai bộ giảm-chấn chịu lực giữ cho nó là một bài học, không phải một cú đấm vào bụng:

- **Điều bạn giữ được.** Survivor bạn giải phóng trên đường xuống *vẫn ở nhà*; attunement của họ *vẫn bật*. Ember nói to điều đó: *"Ta mất kim loại. Ta không mất họ. Đó là cái đánh đổi ta luôn có thể chấp nhận."* Sự mất mát định giá lòng tham đồng thời chứng minh luận đề — *cái sống sót là con người và tri thức, không phải chiến lợi phẩm.*
- **Cái gì reset đối lại cái gì bền vững.** Bloom và boon dẫu sao cũng luôn reset ở lần descent tiếp theo, nên mất chiếc túi tốn vật liệu của *run này*, không phải tiến độ của bạn: **Soil, GWI, các cuộc giải cứu, và Codex đều không bị đụng tới.** Bạn lại đi tiếp ấm hơn một chút, và lần sau khi túi phình và ánh sáng mỏng, bạn chọn HOME — bài học trung tâm cập bến mà không cần một dòng chữ hướng dẫn.

Trong co-op mất mát đầu tiên lạ lùng hơn — một **cú gutter toàn đội** kết thúc run và làm mất mọi túi riêng chưa bank, trong khi một cú gutter *đơn lẻ* thường được Rekindle; toàn bộ kinh tế revive sống ở §11.

### Điều Kiện Thoát Đầu-Game

Đầu game kết thúc vào khoảng đêm thật sự **ấm** đầu tiên, chừng hai giờ đầu: vòng lặp cốt lõi đã được nội hóa (combo, dash, ít nhất một cú parry có chủ đích), **một rescue-attunement** được bank với mức đặt cược mèo-thủy-tinh còn nguyên, một công trình VẬN HÀNH đầu tiên nuôi run tiếp theo, **Soil** đang bắt đầu gieo một giai đoạn diễn thế khởi đầu cao hơn, và GWI đã lên khỏi đáy thấy rõ — bầu trời ấm hơn, bonfire lớn hơn, những chiếc lá đầu tiên nảy ra. Cái kéo họ vào giữa-game (§8): một Cổng cuối cùng cũng đề nghị đi *xuống dưới* lớp tro nông tới một biome sâu riêng biệt (→§5), các lời hứa **⟢ VISION** đến hạn (HEAT MODE đầu tiên, KINGDOM đầu tiên, husk **FAMILIES** như một trục thứ hai), một Codex với những khoảng trống hiển nhiên thách họ phục hồi thêm phát minh, và — cái móc lặng lẽ dưới tất cả — sự hiểu biết rằng một ngôi làng ấm hơn, đông đúc hơn, *đa dạng* hơn khiến lần descent *tiếp theo* bắt đầu xa hơn trên chuỗi diễn thế. Người chơi rời đầu game nắm giữ một thứ mà màn mở đầu không có: **một ngọn lửa giờ là của họ để giữ, và mọi lý do để mang nó xuống sâu hơn.**
---

## 8. Giữa Game — Vòng Lặp Trưởng Thành

*Ngọn lửa tập huấn đã ở lại phía sau. Đủ người đã trở về nhà để Ember không còn phải tự giải thích mình nữa. Giờ toàn bộ cỗ máy quay một lượt — cuộc hạ giới thôi còn là "vung combo ba đòn vào bất cứ thứ gì lao tới" mà bắt đầu hỏi bạn là ai bên trong vòng lặp. Đây là nơi REKINDLED ngừng dạy bạn vòng lặp và bắt đầu đọc ngược lựa chọn của bạn lại thành một đường chân trời.*

> **Điều gì là thật ở đây, và điều gì là lời hứa.** Giữa-game mà bạn có thể chơi **ngay hôm nay** được dựng từ các phần **SHIPPED**: giết→**Kindle**, ngưỡng→**Bloom** leo qua năm giai đoạn diễn thế, mỗi Bloom là một bước chỉ số phẳng cộng thêm một **boon chọn-1-trong-3** (Bloom/boon reset lại mỗi lần hạ giới); **Soil** gieo giai đoạn khởi đầu của bạn; **Attunements** từ các cuộc giải cứu; thang phát minh **Cabin/Forge/Crop Bed/Carpenter's** với vòng đời Dormant→Blueprint→Operational→Upgraded; mức cược gửi-hay-mất của con mèo-thủy-tinh 6-HP; và một **Cold Snap kinh tế v1**.
> Mọi thứ tạo nên *kết cấu bề sâu* cho giữa-game — **Heat Modes, Kingdoms, Husk Families, ma trận Mode × Family, các biome sâu, craft-Warden, Husk Incursion và Long Night** — là lớp **⟢ VISION**: đã thiết kế và ghi chép, **chưa xây**. Bất cứ chỗ nào phần này tựa vào chúng, nó đều được gắn thẻ ⟢ VISION và không bao giờ được đọc như thể đã ship.

---

### Trông và Cảm Nhận Ra Sao

**Đã ship, hôm nay.** Hai hoặc ba survivor về nhà nghĩa là các cuộc hạ giới của bạn mở ra **xa hơn dọc theo chuỗi diễn thế** — Soil gieo bạn vượt qua **Ash** (bề mặt khoáng lạnh bị cào trơ) vào **Pioneer/Herb** với các bước chỉ số phẳng của mọi giai đoạn bị bỏ qua *cùng* một đợt boon draft đầu run để thay cho những Bloom bạn đã nhảy vọt qua, nên một khởi đầu ấm không bao giờ là một thâm hụt boon. Các **Attunements** của bạn tái áp dụng khi vào (Bramble Ward, Ember Fang, Gale Step), kho lẫm trao bạn một **Provision**, và cái túi giờ đáng giá cả một bậc công trình — đó chính là điều khiến chặng đường về Supply Gate thành một canh bạc thật sự. ⚑ Đợt băng giá dài đã cào bề mặt trơ tới nền khoáng chất trần, nên đây là diễn thế **nguyên sinh** (giữ lại lichen tiên phong, "Ash" = bề mặt khoáng, không phải chất hữu cơ sót lại); ⚑ chúng ta nén toàn bộ chuỗi Ash→Pioneer→Herb→Thicket→Canopy vào một cuộc hạ giới duy nhất.

**Các run giữa-game giờ khác nhau theo biên cương** — Gate mở ra biên cương nào (Buried Warren đi xuống đã ship; ⟢ VISION Glaciated Spire, Frostmarch Tundra và Ashen Wald) tái tạo kết cấu cho cả cuộc hạ giới; danh sách biên cương/biome đặt tại **§5**.

**⟢ VISION — kết cấu mà giữa-game hướng tới.** Một khi Modes và Kingdoms xuất hiện, combo tự thay da ngay dưới tay bạn. Bạn mang **một Heat Mode** vào phế tích và **đổi nó giữa run tại bất kỳ Rest-Hearth nào**; **Kingdom** của bạn là một bản sắc pool-boon **cố định cho cả run**, nghiêng theo survivor mà bạn đã cứu. Điều then chốt là, sau các cuộc giải cứu tương ứng **Mode và Kingdom tách rời** — các cặp chéo là hợp lệ (→ **§2**).

| Mode (đều là lửa) | Dấu hiệu trên màn hình | Động từ |
|---|---|---|
| **Conduction / Blaze** | husk bốc khói với DoT bỏng do tiếp xúc | lửa lan husk-sang-husk |
| **Radiation / Sear** | một hào quang bức xạ thụ động, tỉ lệ crit tăng | nhiệt truyền *từ xa*, không cần cận chiến |
| **Convection / Draft** | đòn kết liễu CAN QUET thành một luồng khí bốc lên; một vệt nóng cuộn theo cú dash | kéo các husk nhẹ vào trong, tiếp oxy cho một đám cháy |

Lý do bạn *đổi* là vì phế tích ⟢ VISION đánh trả bằng **vật liệu, chứ không chỉ hung hãn** — và hành vi với vật liệu là **hai trục trực giao ghép lại với nhau.** **Danh sách hành vi** (Husk / Charger / Lobber / Bomber / Warden) nói *một thứ tấn công thế nào*; **family** (Bramble / Beast / Slag, thêm **Frost-Encased** như một *trạng thái* theo độ sâu) nói *nó được làm bằng gì*. Chúng nhân lên:

- một **Bramble Charger** báo trước cú lao bằng một vùng đỏ nguy hiểm và *bốc cháy* ngay khoảnh khắc Blaze chạm vào nó, rồi mang lửa vào bất cứ thứ gì nó lao ngang qua;
- một **Slag Bomber** phải bị **nứt vỡ** trước khi vòng cảm tử của nó nổ được — hãy nung đá trước, không thì nó phát nổ nguyên vẹn;
- một **Frost-Encased Lobber** phải được **rã đông** trước khi cú ném vòng cung của nó kịp đáp, nên bạn chạy đua telegraph của nó với chính đà tan của nó.

| Family | Nó là gì | Cửa ải | Câu trả lời thành thật |
|---|---|---|---|
| **Bramble** | thực vật chết khô, nhiều nhiên liệu | không có — nó *muốn* cháy | Blaze; bốc cháy và lan |
| **Beast** | khối hữu cơ ẩm | **độ ẩm** — luộc bay nước trước | Draft đẩy nhanh bốc hơi (hoặc hai nguồn nhiệt cùng lúc) |
| **Slag** | đá/băng vĩnh cửu vô cơ, ~0 Kindle | **giáp** — bạn *tiêu tốn* nhiệt để nứt nó | Mode nào cũng gặm được; trả gần như không Kindle |
| **Frost-Encased** *(trạng thái theo độ sâu)* | bất kỳ husk nào, lạnh sâu | **hai pha**: một giai đoạn hâm nóng nhiệt-hiện tỉ lệ theo độ sâu, rồi một **plateau tan bằng nhiệt-ẩn cố định** | Sear *tăng tốc pha hâm nóng* (không bao giờ bỏ qua plateau); nhiệt thô và chờ nó tan |

**Sear không "phớt lờ" cửa ải.** Nó truyền nhiệt mà không cần sống sót qua tiếp xúc cận chiến, nhưng Slag vẫn ngốn nhiệt của bạn và trả ít Kindle, còn với Frost-Encased nó chỉ *tăng tốc* pha hâm nóng — không bao giờ bỏ qua plateau tan — nên kẻ đa năng vẫn giữ một lợi thế Frost-Encased thực thụ qua các **chuỗi Thermal-Shock đa-mode** (vật lý + neo về kỹ thuật đốt lửa: App A).

**Nhà đã thành một khu định cư, không còn là một trại** (đã ship). Các công trình đã leo hết vòng đời của chúng và thang phát minh cao lên thấy rõ — **Metallurgy** của Forge đẩy tới **thép**, **Construction** của Cabin phục hồi lại **vòm chịu lực**, **Agriculture** của Crop Bed đã lớn thành **thủy lợi và một kho lẫm**. Villager đi lại và *làm việc*. Vì các hiệu ứng-run **giới hạn ở 3** và công trình trùng lặp cho **hơi ấm giảm dần**, một ngôi làng trưởng thành là ngôi làng đã bắt đầu **đa dạng hóa một cách có chủ ý** — spam thì thua.

---

### Play-Style Ở Toàn Lực — Hai Thế Giới Không Còn Giống Nhau

Giữa-game là nơi phân nhánh thôi còn là tiềm năng mà trở thành **đường chân trời bạn đọc được từ lò sưởi.** Sắc màu mode/kingdom/family bên dưới là **⟢ VISION**; nền tảng mà mọi vignette tựa lên — Kindle→Bloom→boon, Soil, Attunements, gửi-vốn, công trình — đều đã ship.

> **Soil tái phân trọng số** — mô hình chuẩn tắc, các trọng số đề xuất, và quy tắc *khởi đầu ấm = lợi thế đầu, không phải thâm hụt boon* nằm ở **§1**; hệ quả mà các vignette bên dưới thực thi: **một thế giới tham lam là một thế giới thực sự lạnh, ít hơi ấm — không bao giờ ấm-mà-thô.**

#### Vignette — The Bright Predator, "The Forge-Cold Warren" (World A)

Rin cứu **Smith** trước và không bao giờ ngoái lại: metallurgy-first, thép gần như đã phục hồi — nhưng cô ấy **cướp bóc**, gửi vốn muộn, và giải phóng gần như không một ai. Nên đường chân trời của cô ấy **thực sự lạnh**: một dúm forge tua tủa đen kịt trên một chân trời đóng băng, thiếu ấm, GWI thấp vì cô ấy chẳng bao giờ gửi vào những lợi tức làm nó dâng lên. Và vì số-đã-cứu cùng sự đa dạng mới là thứ nuôi Soil tái-phân-trọng-số, các cuộc hạ giới của cô ấy cũng khởi đầu **thô, gần Ash** — phục hồi *thép* không mua được cho cô ấy một giai đoạn diễn thế muộn hơn; **lòng tham giữ cho cả đường chân trời lẫn Soil lạnh cùng một lúc.** ⟢ VISION Cô ấy chạy **Sear + Fauna** và sống nhờ cửa **DEEPER**: dash *xuyên qua* một Charger (i-frame; nó tự-choáng vào tường), Sear-crit các Bramble máu thấp để đòn hành quyết của Fauna hoàn HP và **tốc-độ đà-bầy** — cuối trận nhanh hơn đầu trận. Rồi một khối **Slag** neo giữ phòng kế: Sear truyền nhiệt an toàn nhưng cú giết trả gần như không Kindle, Bloom của cô ấy khựng lại, và một **vùng đỏ nguy hiểm** bỏ lỡ kết thúc cả run trong bóng tối với cả cái túi mất trắng. Cô ấy gửi vốn ở lò sưởi cuối cùng, tim đập thình thịch. Ember tán thưởng nhưng dè chừng: *"Cô vượt-nhiệt tảng đá đẹp lắm. Nhưng đá chưa bao giờ là bộ mặt thật của cái lạnh."*

#### Vignette — The Slow Bloom, "The Green Terrace" (World B)

Sol cứu **Farmer** trước: agriculture-first, cả chuỗi nông trại đã phục hồi, các ruộng bậc thang lúa đổ xuống về phía một đống lửa mừng lớn khổng lồ. Anh ấy **gửi vốn sớm và giải phóng mọi người**, nên dưới Soil tái-phân-trọng-số **nhiều cuộc giải cứu và ngôi làng rộng, đa dạng** của anh ấy — chứ không phải một sự trùng hợp về hơi ấm — khởi đầu các cuộc hạ giới của anh ấy ở **Thicket, một giai đoạn diễn thế muộn hơn**, với các bước chỉ số chồng lên của giai đoạn 1..N và một **boon draft cho các Bloom bị bỏ qua** đang chờ khi vào. Hơi ấm của anh ấy cao và đang tăng nhờ **sự đa dạng**, không phải nhờ những đợt loot vọt lên. ⟢ VISION Anh ấy chạy **Convection + Flora**: một phòng Beast lẽ ra sẽ chặn đứng một build Blaze, **Draft** của anh ấy luộc khô trong vài giây, luồng khí bốc lên thắt nút đám husk, rễ Flora giữ chúng lại, và anh ấy nhấp một **Provision** mang theo trong khi gai làm việc — gần-như-không burst, gần-như-không cái chết. Ember nghe như đang ở nhà: *"Một sự dư dả. Sự tự do đầu tiên — đôi tay được rảnh khỏi đất để làm mọi thứ khác."*

#### Vignette — The Kindler, chuyên gia của việc không chuyên hóa

Mara đọc **family trước, telegraph sau**. ⟢ VISION Trên một làn **Frost-Encased**, cô ấy **Sear-ngâm** để tăng tốc pha hâm nóng nhiệt-hiện, rồi tống một burst **Blaze** để giáng **Thermal Shock** — con husk lạnh giòn rạn trắng và vỡ tan trên màn hình. Phòng kế là Bramble; cô ấy đổi sang **Draft** và để **Firestorm** ăn cả bầy. Ngôi làng của cô ấy nặng về **Carpenter's / Builder**, vì chỉ có mở khóa nhanh mới giữ cả ba Mode trong túi cô ấy. Cô ấy vượt-scale các chuyên gia đúng ngay trên những deep husk vốn trừng phạt một build cố định — và, điều quan trọng, cô ấy làm điều đó **một mình**, sắp trình tự các Mode qua các Rest-Hearth.

> **Thermal Shock, nói thật.** Bộ kỹ năng thuần-lửa làm nứt một con husk lạnh, giòn chỉ bằng gradient hâm nóng nhanh — nó **không bao giờ** "nung rồi làm nguội" (vật lý + neo về kỹ thuật đốt lửa: App A).

**Các nguyên mẫu còn lại ở giữa-game — không cái nào biến mất.** **The Hearthkeeper** là bản sắc HP phòng thủ — HP đến từ các bậc **Cabin/Construction +MaxHP** chồng lên, không phải từ chồng attunement, nên con mèo vẫn là một **kẻ săn thủy-tinh 6-HP**, không bao giờ là một tank 20-HP (attunement không-chồng + nguồn HP: → **§2**). **The Rot-Reaper** chạy **Fungi**: các husk bị nhiễm rơi thêm Materials và Soil và một rhizomorph kiểu Armillaria **lan chuyền** sự nhiễm bệnh khắp một bầy — hơi ấm từ *phân hủy*, không phải từ giết. **The Archivist** đuổi theo một **Codex hoàn chỉnh**, giải phóng mọi survivor vì bản thân tri thức; Codex được **hiển thị xếp-hạng-theo-tác-động (canon)**, trong khi một con dấu riêng "phục hồi ở run N" là ghi chép *duy nhất* về lịch sử của Archivist — thứ tự không bao giờ mã hóa nó.

**Cùng một game, mười giờ sau:** một forge-cold warren so với một green terrace, một kẻ cướp Soil-thô so với một người trồng khởi-đầu-Thicket, hơi-ấm-loot gai góc so với hơi-ấm-đa-dạng rộng khắp. Không ai đụng vào một thanh trượt độ khó. Họ đã chọn *nhớ điều gì trước*, và thế giới trở thành bản ghi chép của điều đó.

---

### Kẻ Phản Diện Có Một Khuôn Mặt — ⟢ VISION

Ban đầu, cái lạnh câm lặng — là điều kiện, không phải kẻ thù. Vượt qua lớp tro nông bạn rơi vào các **biome sâu riêng biệt** nơi các mảnh vỡ trở thành **lời chứng**: những vạch đếm dừng ở bốn mươi mốt, khung cửi với con thoi vẫn còn trong đó, cuốn sổ cái chạy từ *lúa → củi → chỉ còn tên người*. Các husk mang **hình dáng nghề của chúng**. Cái lạnh không viết ra điều này; nó bảo tồn một vệt mòn sâu đến mức vẫn còn quay tiếp sau khi con người đã tắt đi.

Ở đáy mỗi biome sâu đứng một **craft-Warden** — cái lạnh được ban cho bóng dáng của một nghề đã mất. Đánh nó và **nó không chảy máu; nó chập chờn rồi lịm đi như một ngọn lửa thiếu khí** — thanh của nó là *bao nhiêu cái lạnh còn giữ được hình dáng lại với nhau*, không phải máu.

| Warden | Biome | Nghề nó canh giữ |
|---|---|---|
| **The Keeper of the Empty Rows** | những cánh đồng bị vùi | Agriculture |
| **The Cold-Struck Smith** | lò rèn-sâu bị nghẹt | Metallurgy |
| **The Unfinished Arch** | những hầm vòm sụp đổ | Construction |

Bạn không hẳn là giết chúng mà là **thắp lại điều chúng canh giữ** (nhiệt + nghề đã phục hồi), gấp phát minh vào **Codex** — kẻ phản diện và thang phát minh trở thành cùng một thanh, đọc như combat. Các craft-Warden này là **những lần thắp-lại một-lần**, gặp theo bất kỳ thứ tự nào bản đồ phân nhánh cho phép; **phòng-Warden phổ thông** vẫn tái diễn như cấu trúc roguelite thông thường. **Bạn không bao giờ cày một Warden để lấy loot hay XP tái tạo** — GWI đến từ **lợi tức đã gửi**, không bao giờ từ việc rút máu một boss.

#### Sự kiện World-Stakes đầu tiên — nhà thôi còn là bối cảnh an toàn

**Đã ship, v1 = một Cold Snap thuần kinh tế.** Mở rộng khoảng đất quá mức, hoặc tiêu quá nhiều ngày dưới sâu mà không chăm nom, và GWI ở **vòng ngoài của bạn tụt xuống dưới ngưỡng**. Vòng đó **đóng băng và ngủ đông** (các công trình của nó ngừng chạy, mùa màng đứng im, attunement xám lại) — dấu hiệu trên màn hình là một lớp sương giá thấy được đang bò lan đường chân trời. **Không có gì bị phá hủy; nó bị *lãng quên*,** và ấm lại khi bạn tiếp lửa cho các lò sưởi trở lại. **Không có husk nào vào làng; không có combat trong làng.** Đột nhiên các lò than và hơi ấm-theo-khoảng-cách của bạn thành **hạ tầng**, và người chơi độc canh học được một cách thấm thía rằng một cái trại một-nốt-nhạc không thể giữ cho mọi vòng đều sáng lửa. (Các ngưỡng Cold-Snap là **TBD**; khung world-stakes/phản diện chuẩn tắc nằm ở **§3**.)

> **⟢ VISION / pha muộn đáng kể — chi phí xây dựng được đánh cờ.** **Husk Incursions**, **watchtower/combat của villager**, và **Long Night** *không* nằm trong v1. Chúng đưa vào **combat trong làng — một cú xoay trục phòng thủ căn cứ mà màn hình builder/farm hiện tại không có hệ thống nào để đỡ** (đường đi của kẻ thù vào làng, các công trình phòng thủ được, AI combat của villager). Đó là một khối xây dựng lớn, riêng biệt, không phải một đợt đánh bóng giữa-game, và được nêu rõ như vậy. ⚑ Long Night là một sự đào sâu theo mùa/độ nghiêng-trục của gradient lạnh (đêm dài nhất), được nén lại để chơi. Nhịp độ Incursion và nhịp độ Long Night là **TBD**.

---

### Các Quyết Định và Căng Thẳng Mới

- **Xuống-sâu-hay-gửi-vốn, với mức cược thật.** Cái túi đáng giá một bậc công trình; bóng tối vẫn tịch thu mọi thứ chưa gửi; **các cuộc giải cứu và attunement được gửi vốn ngay khoảnh khắc bạn giải phóng chúng.** Ở 4 HP với thép cách một phòng — *cái vòm có đáng để ngã không?*
- **Chuyên hóa hay đa năng (⟢ VISION).** Một diver Sear+Fauna cố định xé nát các phòng nông nhưng khựng lại ở một hầm Slag; the Kindler trả lời được mọi family nhưng không thành thạo cái nào. **Thứ tự giải cứu** lặng lẽ chốt điều này lại — mỗi survivor là một Mode và một Kingdom bạn có thể hoặc không thể chạm tới.
- **Độc canh hay đa dạng, giờ khi trùng lặp gây hại.** Giới-hạn-3 và hơi ấm giảm dần khiến một forge thứ tư gần như là hơi ấm chết; Cold Snap khiến các vòng thiếu đa dạng là những vòng *đầu tiên* ngủ đông. Đa dạng thôi còn là lời khuyên mà thành sự sinh tồn.
- **Lòng thương hay cướp bóc — những lò sưởi chập chờn.** Ngoài kia trong cái lạnh Ember của bạn bắt được một **tín hiệu yếu ớt**, một ngọn lửa khác sắp tắt. **Thắp lại nó** (tiêu nhiệt/vật liệu; nhận survivor biết một nghề bạn không biết, và GWI nhanh hơn) hoặc **ăn thịt nó.** Ăn thịt **tịch thu cuộc giải cứu những survivor đó** — họ **không bị giết trên màn hình; con người không bao giờ là vật thế chân** — nhưng người và tri thức của họ bị **loại bỏ vĩnh viễn khỏi thế giới và nó làm móp GWI.** Sức nặng nằm ở *điều bạn đã chọn không mang theo*. Ember lặng lẽ ghi chú rằng lấy hơi ấm của một lò sưởi để nuôi lò khác *chính xác là cách the Long Dark lan ra.* Trục này đang lặng lẽ chọn cái kết của bạn.
- **Những lựa chọn mở rộng đầu tiên, trên các lò sưởi khác.** Giữa-game là nơi bạn lần đầu vươn *ra ngoài* khoảng đất của chính mình tới các lò sưởi lân cận và đưa ra những nước đi **liên minh / thôn tính / ăn thịt** đầu tiên — những nét vẽ đầu tiên của hình dáng chính trị cho thế giới của bạn. Toàn bộ phổ mở rộng và hình học bản đồ của nó đặt tại **§6**.

**Van trợ năng.** Vì sự tịch thu là thật, con mèo 6-HP ship kèm các tùy chọn trợ giúp — **độ khó trợ giúp/kể chuyện, một token hồi sinh solo tùy chọn, nới rộng nhịp telegraph, tỉ lệ UI** — để mức cược có một cái van, và co-op không bao giờ trở thành cách *duy nhất* an toàn hơn để chơi.

---

### Solo và Co-op Ở Toàn Lực

**Solo** vẫn là một cuộc đấu-giải-đố — mang một Mode, đổi nó tại Rest-Hearth, đọc family cẩn thận như đọc telegraph, và *sắp trình tự* để đạt tới **Firestorm** và **Thermal Shock** một mình. Firestorm/Thermal-Shock là **có-thể-đạt-được-solo** và **không có độ sâu nào bị khóa sau co-op** (hồi sinh, túi riêng, N-scaling, vai trò, và toàn bộ phán quyết: → **§11**).

**Phần chênh-lệch-pha của giữa-game là sự chồng lấp.** ⟢ VISION Vì Modes và Kingdoms là theo-từng-người-chơi và **tách rời** sau các cuộc giải cứu, hai build cố định chạy các cặp chéo hợp lệ *đồng thời* — và tính đồng thời mở khóa điều duy nhất mà một tay solo chỉ có thể xấp xỉ qua các lò sưởi: **combo hai-nguồn thực sự đồng thời** (**Boil-Off Brigade**, hai nguồn nhiệt cùng lúc dọn sạch độ ẩm của một Beast trong nửa thời gian). Điểm cộng của co-op là **hồi sinh + combo đồng đội + chia sẻ người, không phải giảm áp lực** — luật đầy đủ ở **§11**.

---

### Điều Kiện Thoát Giữa-Game

Bạn biết giữa-game đang khép lại khi ba điều hội tụ. **Thang phát minh đạt trần** — thép đã rèn, vòm đã dựng, thủy lợi và kho lẫm đang chạy — và Codex chỉ còn những khoảng trống sâu nhất, xưa nhất. **Các craft-Warden ngã xuống** (⟢ VISION), mỗi biome sâu một cái, mỗi hình dáng được thắp lại để lại bản đồ lặng hơn và phế tích lạnh-sâu-hơn bất cứ nơi nào bạn đã đi qua. Và **thế giới của bạn đã cam kết với hình dáng của nó** — một Forge-Cold Warren, một Green Terrace, một Hearth-Keep — đọc được trong đường chân trời, trong thứ tự tác động của Codex, trong giai đoạn khởi đầu do Soil dẫn dắt, và trong giọng nói đã đổi khác của Ember.

Tại điểm đó bản đồ chỉ *xuống và vào trong.* Những dấu chân trong các mảnh vỡ đều chạy về phía sâu, và Ember bắt đầu nói về **phế tích xưa nhất, lò sưởi đầu tiên từng bị bỏ mặc cho tắt,** nơi **the First Warden** đứng — không phải người canh giữ một nghề mà là người canh giữ *chính việc ghi nhớ.* Bạn có thể tiếp tục vượt-ấm bóng tối cho tới khi các hình dáng của nó chập chờn tắt lịm mà chẳng ai gặp, hoặc đi xuống và **thắp tia lửa chưa bao giờ được đánh ra.** Dù thế nào, chương kế tiếp thôi còn là về việc nuôi lớn ngọn lửa. Nó trở thành về việc ngọn lửa của bạn là *để làm gì.*
---

## 9. Cuối Game — Tinh Thông & Lò Lửa Sâu Nhất

> **SHIPPED so với ⟢ VISION.** *Vòng lặp* tinh thông đã **shipped (EMBERGROWTH Phase 0)**: giết → Kindle, chạm ngưỡng → Bloom leo lên chuỗi diễn thế (Ash → Pioneer → Herb → Thicket → Canopy), mỗi lần Bloom là một bậc chỉ số phẳng cộng thêm một boon chọn-1-trong-3, Attunement được áp lại mỗi lần xuống hầm, Soil gieo sẵn giai đoạn diễn thế khởi đầu của bạn, và những khoản gửi về nâng GWI lên. **Lớp ⟢ VISION đã được ghi lại, nhưng chưa xây**: Heat Modes, Kingdoms, Husk Families và ma trận Mode×Family, các biome sâu, các craft-Warden cùng First Warden, và các sự kiện thế giới (Cold Snaps, Long Night). Mọi bản sắc build và mọi nhịp xuống-sâu bên dưới mà dựa vào lớp vision đều được gắn nhãn **⟢ VISION** và tuyệt đối không được đọc như thể đã chơi được.

### Một Thế Giới Gần Như Đã Ấm

Đến lúc người chơi bước vào cuối game, vòng lặp đã âm thầm làm xong việc của nó, và bằng chứng nằm ngay trên mặt đất trước cả khi bạn xuống hầm lần nữa. **Lò bonfire giờ đúng nghĩa một bonfire theo lối cũ — một đám lửa của xương và xà nhà, hắt ánh vàng khắp một khoảng trống đã nới rộng ra ngoài thành ba vòng.** GWI treo đâu đó qua mốc 0.85; ánh sáng môi trường không còn đọc là "ban ngày" nữa, nó đọc là *giờ vàng được giữ lại*, đúng cái giờ vàng mà cả trò chơi đã hướng tới. Cây chết mang lá. Sương giá chỉ còn sót ở vòng ngoài cùng, và chỉ khi bạn lơ là nó (Cold Snap kiểu kinh tế — chưa có husk nào trong làng).

**Đường chân trời của làng là một bản lý lịch bạn đọc được trong một cái liếc.** Một save tinh thông tất yếu phải *đa dạng* — hiệu ứng theo run cap ở mức 3 và công trình trùng lặp cho warmth giảm dần, nên ngôi làng của kẻ về đích có Cabin, Forge, Crop Bed và Carpenter's đều Operational hoặc Upgraded, mỗi thứ với huy hiệu vòng đời (Dormant → Blueprint → Operational → **Upgraded**) đang nằm ở bậc cao nhất. Dân làng thuộc mọi nghề đi lại và làm việc: Farmer vận hành hệ tưới, Smith bên đe, Builder rảo bước quanh một nền móng vừa dựng, cả tá survivor có tên mà bạn đã cõng về từng người một. Đây là trạng thái *thị trấn đang vận hành* — không phải một sandbox max cấp. Cái *dáng* mà thị trấn vận hành ấy khoác lên — phát minh nào đạt đỉnh, run này xuống về biên giới nào, Warden nào chờ bên dưới — được định bởi **worldline** của nó (→ §4).

**Codex (nhấn K)** gần như đã trọn. *ember, the_long_dark, agriculture, metallurgy, construction, the_warden* đều đã được phục hồi — mỗi mục là một đoạn văn trung thực, **xếp hạng theo tác động**, với những chỗ hư cấu được đánh dấu — và những khoảng trống còn lại duy nhất là các mục craft sâu mà những Warden sâu nhất vẫn canh giữ. (Codex được *hiển thị* theo xếp hạng tác động; thứ tự phục hồi của bạn nằm ở một kênh riêng — trạng thái khoá/mở cùng dấu "recovered on run N" — không bao giờ được truyền tải qua vị trí trong danh sách.)

Và build đã ở **mức tinh thông trọn vẹn.** Người chơi không còn *tìm ra* một bản sắc mỗi run — họ *thể hiện* một bản sắc. Kindle chảy nhanh và Bloom leo lên tận đỉnh chuỗi diễn thế (Thicket, Canopy) chỉ trong một lần xuống hầm bởi **Soil** dày đã gieo sẵn một giai đoạn diễn thế muộn hơn — một khởi đầu ấm không bao giờ là một sự thiếu hụt boon (mô hình Soil đầy đủ → §1). Attunement áp lại mỗi lần xuống hầm nhưng vẫn giữ cap, và con mèo vẫn là **glass cat 6-HP**, không bao giờ là một tank 20-HP (→ §2).

> **⚑ Tái cân trọng số Soil.** Đề xuất tái cân trọng số — do số người được cứu và độ đa dạng của làng chi phối còn GWI chỉ là một số hạng phụ, để một thế giới lạnh, đã bị vơ vét thực sự khởi đầu **RAW** dưới bất kỳ bầu trời nào — được nêu đầy đủ ở **§1**.

#### Các run đặc trưng ở mức tinh thông ⟢ VISION

Ở mức tinh thông trọn vẹn, sáu nguyên mẫu (→ §2) thôi không còn là những bảng chỉ số mà trở thành những ngữ pháp trọn vẹn mà kẻ về đích *thể hiện* chứ không *tìm ra*. Sổ đăng ký của chúng — tên, Modes, Kingdoms, và những ảo tưởng một-nước-đi — thuộc về §2; §9 chỉ nhấn mạnh rằng đến cuối, bản sắc phải được *khoác lên người*, không phải khám phá ra, và đọc được ngay từ cái nhìn đầu tiên mà không cần tooltip.

Sau khi lần lượt được giải cứu, **Mode và Kingdom tách rời nhau**, nên các cặp chéo là hợp lệ — một predator **Sear + Fauna** hay một kẻ mục rữa **Draft + Fungi** đều là những cách thể hiện chính đáng, không lệch chính-sử. Trên màn hình bạn *đọc* được nguyên mẫu mà không cần tooltip: Predator để lại vệt heat-shimmer rực và những pop crit đỏ; Slow Bloom để lại một mạng lưới gai xanh; những đòn giết của Rot-Reaper nở ra sợi nấm nhợt nhạt giữa các xác; Hearthkeeper thì đơn giản là *không chết* khi lẽ ra phải chết.

**Nhiệt chống lại cái lạnh, ở mức tinh thông ⟢ VISION.** Chống lại husk **Frost-Encased** — cái *status* của độ sâu, không phải một family — **Sear/Radiation tăng tốc pha làm ấm nhiệt-cảm-nhận-được** (có căn cứ: băng và nước hút hồng ngoại rất mạnh) nhưng **không bao giờ bỏ qua plateau nóng chảy nhiệt-ẩn cố định**; plateau ấy là một cổng cứng bạn phải chờ hết, không phải một bức tường bạn đấm thủng. Vậy nên lợi thế Frost thật sự của Kindler là **chuỗi Thermal-Shock**: một vết nứt *gia nhiệt nhanh* thuần lửa — dồn một gradient nhiệt dốc vào một lớp vỏ lạnh, giòn để nó nứt ra do giãn nở vi sai. ⚑ *Thermal shock cổ điển thường cần một pha **làm nguội**/tôi nhanh mà bộ kit thuần lửa không có; điểm neo trung thực là **fire-setting** — nung đá, rồi tôi nó để làm nứt, từ thời Đồ Đá Cũ đến La Mã trong khai mỏ. Không bao giờ "nung rồi làm nguội" cho bộ kit lửa.* Chống lại **Slag** (vô cơ, kindle ~gần bằng không) lợi thế của Sear là **truyền được nhiệt mà không cần sống sót qua tiếp xúc cận chiến** (⚑ ẩn dụ, không phải "xuyên giáp"). Những combo chủ lực — **Firestorm** (Draft nuôi một Blaze cho tới khi nó tự lan khắp Bramble khô) và **Thermal Shock** — đều **làm được solo** bằng cách đổi Mode giữa run và tại Rest-Hearth; không kỷ lục độ sâu nào bị chặn sau một người chơi thứ hai.

**Các family trở thành một vốn từ vựng ⟢ VISION.** Hành vi (Husk / Charger / Lobber / Bomber / Warden) và family vật liệu (Bramble / Beast / Slag, với Frost-Encased là một status độ sâu) là **trực giao và kết hợp được**: một **Bramble Charger** báo trước cú lao và bắt lửa khi dính Blaze; một **Slag Bomber** phải bị *nứt vỡ* trước khi cái vòng cảm tử của nó có thể bị kích nổ; một **Frost-Encased Lobber** phải bị *rã đông* trước khi đường vòng cung của nó chạm đất. Ở mức tinh thông bạn thôi sợ Slag và bắt đầu **cố ý tiêu nhiệt lên nó.**

### Cuộc Đối Đầu — "Đánh Bại" Entropy Thực Sự Nghĩa Là Gì Một Cách Trung Thực ⟢ VISION

Lần xuống sâu nhất không phải một cú tăng độ khó; nó là một **cú tăng độ minh bạch.** Tàn tích cổ nhất cũng là tàn tích *đầu tiên* — nơi mà, trước khi bất kỳ ngôi làng nào tồn tại để mà quên, ngọn lửa được chăm đầu tiên đã tắt lịm trong một đêm không ai trông. Chạm đến nó, trò chơi cuối cùng nói thẳng ra kẻ phản diện luôn luôn là gì: **nguồn gốc của sự lơ là, không phải một con boss dưới đáy hầm ngục.**

Trên đường xuống bạn thắp lại các **craft-Warden** có tên — mỗi con là một **lần thắp lại duy nhất**, không phải một chỗ để farm, trao lại nghề của nó và không bao giờ hồi sinh thành loot hay XP; GWI đến từ những khoản gửi về, không bao giờ từ việc rút máu một con boss (→ §3).

**Cốt lõi trung thực: bạn không giết First Warden. Nó không chảy máu.** Thanh của nó không phải máu — nó là *bao nhiêu cái lạnh đang giữ cho cái hình khối ấy chưa tan.* Bạn đánh vào nó và nó **chập chờn, mờ đi, rồi tắt như một ngọn lửa bị bỏ đói khí.** Đánh bại nó không phải một cuộc giết chóc; Ember vươn qua cái bóng hợp thể — mọi tư thế mà cái lạnh từng khoác lên, tất cả mờ nhạt cùng một lúc — tới lớp mồi lửa chưa được thắp phía sau nó, và **thắp lên tia lửa chưa từng được đánh.** Warden không ngã xuống. Nó *cuối cùng cũng ấm lên*, và không còn cần đứng canh nữa. **⚑** *Điều này kịch tính hoá attractor-dynamics: một trạng thái suy tàn tự-duy-trì bị tháo gỡ bởi năng lượng + thông tin được khôi phục — nhiệt cộng với nghề đã tìm lại. Không có kẻ ác, không có mưu đồ.*

> **Vignette — đấu trường sâu nhất.**
> Sàn là đá phủ băng xếp thành một vòng quanh một vỉ lò lạnh. Giọng Ember hạ xuống gần như không còn gì: *"Đây là cái đầu tiên. Trước khi có làng. Trước cả ta. Ai đó đã đặt đám lửa này mà chẳng bao giờ đánh nó lên."* Đấu trường niêm phong lại — kiểu Hades, không lối ra cho tới khi ngã ngũ. First Warden trỗi dậy: không phải một con thú, mà là một *cái bóng của mọi nghề đã mất cùng một lúc* — dáng cúi của thợ rèn, dáng chồm của người đưa tin, và cái oằn của một vòm cung dang dở. Nó báo trước một cú lao nặng nề; vùng nguy hiểm đỏ vẽ ra rộng và chậm. Bạn dash — i-frame, *xuyên qua* — và vồ lấy nó lúc nó xoay người. Thanh của nó tụt xuống, và chỗ bạn đánh vào cái hình khối ấy hoá *trong suốt*, cái lạnh rỉ ra thành hơi nhợt nhạt. Nó không bị thương. Nó đang bị *lãng quên bởi chính cái thứ đã níu giữ nó.*

**Những lối chơi khác nhau đến căn phòng này bằng những con đường khác nhau — và một con đường hợp lệ thì không bao giờ bước vào đó cả.** Chuyện một run *đua* xuống sâu bằng vơ vét (sớm, chưa đủ ấm, đi trên lưỡi dao), *cứu tất cả mọi người* và đến muộn nhưng có giáp, hay *bỏ đói* vực sâu và không hề đánh nhau, chính là cái đọc **Starved↔Confronted** và **Mercy↔Plunder** mà các trục kết thúc của §10 chính thức hoá.

Con đường thứ ba ấy là nước đi chính-sử táo bạo nhất trong game: **bạn có thể thắng mà không hề đánh nhau.** Nhóm đủ nhiều ngọn lửa đa dạng, được chăm sóc, và các Warden tự chập chờn tắt; tàn tích sâu nhất *đã ấm và trống rỗng* khi rốt cuộc bạn xuống tới. Trò chơi vinh danh nó như một chiến thắng thật sự, không phải một chiến thắng bị bỏ qua.

### Cái Kết Bạn Giành Được — xem §10

Chạm GWI 1.0 *luôn luôn* nhóm lại thế giới; **bạn nhận được kiểu nhóm-lại nào chính là dáng hình của những gì bạn đã mang theo**, đọc ra từ ba trục — **Diverse↔Monoculture, Mercy↔Plunder, Starved↔Confronted** — với **phát minh chủ đạo** của bạn (nghề đầu tiên / bản sắc theo bậc-thang-phát-minh) và **Mode/Kingdom chủ đạo** của bạn được gấp vào cái world-seal epithet cùng ít nhất một dòng epilogue, để 10 giờ thể hiện build đọc được trên màn hình cuối. *Hình thái chính trị* của cái kết — một vòng các lò lửa độc lập liên bang so với một đám lửa trung tâm duy nhất — là một **lớp da mà tầng mở rộng cung cấp (→ §6)**, không phải một kiểu nhóm-lại riêng. Toàn bộ danh sách các kiểu nhóm-lại, world-seal, epilogue đọc-lại-được, và mọi điểm đến hậu-chiến-thắng (**Endless Deep**, cái **Legacy / NG+** duy nhất mang Codex + Soil về phía trước, bảo tàng Codex) đều nằm ở **§10**. Tất cả chúng đều với tới được từ **bất kỳ** save nào đã hoàn thành; cái kết bạn đạt được chỉ *rọi đèn* vào một cái — nó không bao giờ chặn việc cái nào tồn tại. Thị trấn ấm đang sống cũng vẫn *được chăm*, không trơ ì: những Cold Snap phải đáp lại, những lò lửa chập chờn khác vẫn gọi được thắp lại, và **Long Night** giai đoạn muộn như bài thi định kỳ của kẻ về đích (⚑ một sự sâu-thêm theo mùa/độ-nghiêng-trục của gradient lạnh, được nén lại) — bằng chứng rằng thế giới vẫn còn có thể mất, và thắng lại.

### Cuối Game Solo và Co-op

**Solo** cuối game là cuộc đối đầu ở trên — một con mèo 6-HP, một Ember, một build được thể hiện đến mức tinh thông, một epilogue khớp với các trục của bạn.

**Co-op** giành được một nhịp cuối game mà game solo về mặt cấu trúc không thể có — **cái kết tại vỉ lò lạnh**: khi hình khối của Warden hoá trong suốt, trò chơi đòi **cả hai** con mèo có mặt tại vỉ lò cùng lúc, và Ember thật của Người chơi 1 cùng tia lửa được mượn của Người chơi 2 thắp ngọn lửa đầu tiên cùng nhau, một lò lửa được thắp lại bởi hai bàn tay. Mọi luật co-op khác — hư cấu tia lửa, hồi sinh chập-chờn/**Rekindle**, túi đồ riêng, tỉ lệ 2P→4 / 3P→6 ghim áp lực mỗi-người-chơi vào mức baseline solo, các combo chỉ-đồng-thời, và *không độ sâu nào bị chặn sau một người chơi thứ hai* — nằm ở **§11**.

### Suy Ngẫm — Màn Hình Cuối Cùng Là Luận Đề

Pillar 3 nói rằng chỉ luôn có **một thanh tiến độ** duy nhất: hơi ấm trở lại một thế giới đã chết, với sức mạnh người chơi, sự lớn lên của làng, cấp độ hình ảnh, và bậc thang phát minh tất cả là *cùng một* thanh — GWI, Ember. Cuối game là nơi lời hứa ấy cuối cùng được thanh toán. Bạn không "thắng" REKINDLED bằng cách đánh vượt sát thương một vũng máu — kẻ địch sâu nhất **không chảy máu; nó chập chờn rồi tắt**, bị tháo gỡ bởi cái thứ duy nhất nó không thể đáp lại: một ai đó vẫn nhớ, và đã dạy ngọn lửa được gìn giữ. Epilogue không thưởng bạn bằng loot. Nó cho bạn thấy thế giới giờ-vàng, những survivor có tên, cái Codex gần đầy — **những con người và tri thức bạn đã mang theo, và không gì khác** — và nói với bạn, bằng giọng gần-như-tắt-lịm cuối cùng của Ember, rằng ngọn lửa giờ đã ở một nơi khác: *trong họ, trong bạn.* Màn hình cuối cùng không phải một bảng đếm chiến thắng. Nó là luận đề, được trả bằng vàng: **văn minh sống trong con người và tri thức, không phải trong loot — và hơi ấm được truyền đi, tay này qua tay kia, hoặc là nó mất.**


---

## 10. Các Kết Thúc & Thế Giới Được Nhóm Lại

Chạm GWI 1.0 *luôn luôn* nhóm lại thế giới. **Kiểu** nhóm-lại bạn nhận được không bao giờ được quyết định bởi việc bạn có thắng hay không — nó được quyết định bởi dáng hình của những gì bạn đã mang xuống rồi mang trở lên: bạn đã nuôi lớn một nền văn minh rộng đến đâu, bạn cứu được bao nhiêu người, bạn thắp lại lò lửa đầu tiên mặt-đối-mặt hay chỉ đơn giản ủ ấm hơn bóng tối cho tới khi nó chẳng còn gì để mà níu giữ, bạn dám xuống sâu đến mức nào, và thị trấn của bạn được dựng quanh phát minh nào. Màn hình cuối cùng không phải một bảng đếm chiến thắng. Nó là luận đề được trả bằng vàng — *văn minh sống trong con người và tri thức, không phải trong loot* — và thế giới giờ-vàng nó cho bạn thấy là một bản lý lịch về những lựa chọn của bạn mà bạn đọc được không cần tooltip. (Toàn bộ chuỗi seed→cascade mang dáng hình của một run vào cái seal của nó nằm ở **§4**; chương này là nơi ở của các *trục* kết thúc và của chính năm kiểu nhóm-lại.)

> ⟢ **VISION.** Cái nhân đã ship thì nhỏ và trung thực: GWI 1.0 → một **epilogue Ember đọc-lại-được**, với **Codex (K)** và **bản sắc phát minh/công trình** đã có sẵn trên đĩa. Hệ năm-thế-giới được khai triển bên dưới — và mọi chỗ nó gấp một **Heat Mode** hay một **Kingdom** vào một seal — là **lớp vision đã ghi lại**, không phải một tính năng đã ship. Trục bản-sắc-phát-minh dựa trên các công trình đã ship; việc gấp Mode/Kingdom thì chưa tồn tại.

### Các Trục Chọn Kiểu Nhóm-Lại Của Bạn

Năm trục đọc run của bạn và chọn epilogue. Bốn trục đầu quyết định *thế giới nào*; trục thứ năm quyết định *thế giới ấy được gọi tên và trông ra sao*.

| Trục | Hai cực | Quyết định bởi | Đọc trên màn hình thành |
|---|---|---|---|
| **Đa dạng** | Diverse ↔ Monoculture | số nghề riêng biệt Operational/Upgraded (hiệu ứng theo run cap ở 3; công trình trùng lặp cho warmth giảm dần) | sự phong phú của đường chân trời |
| **Nhân từ** | Mercy ↔ Plunder | số survivor cõng về, độ hoàn chỉnh Codex, các lò lửa khác **được thắp lại vs bị cannibalise** (cannibalise đẩy về phía Plunder) | có bao nhiêu dân làng có tên đi lại trong khoảng trống |
| **Đối đầu** | Confronted ↔ Starved | bạn có **thắp lại First Hearth mặt-đối-mặt** hay không, hay ủ ấm hơn nó cho tới khi Warden chập chờn tắt lịm mà chẳng ai gặp, ngoài màn hình | một cái bóng tại vỉ lò sâu nhất — hay một bình minh không có ai trong đó |
| **Sâu-Đến-Đâu** | Homestead ↔ Delver | tàn tích sâu nhất chạm tới / **kỷ lục độ sâu** đã gửi | dấu độ sâu trên world-seal của bạn |
| **Bản-Sắc-Phát-Minh** ⟢ | Construction / Metallurgy / Agriculture / Builder dẫn đầu **+ Mode/Kingdom chủ đạo** | nghề đầu tiên và nghề dẫn đầu bậc-thang-phát-minh của bạn, cộng với Mode/Kingdom của run | lớp reskin của seal và cái bóng thị trấn của bạn |

**Mode và Kingdom tách rời sau khi được giải cứu,** nên một epithet có thể ghép *bất kỳ* Mode với *bất kỳ* Kingdom — một seal **Sear-Fauna** "Searing Pack" hay một seal **Draft-Fungi** "Gale-Rot" đều là những cách đọc hợp lệ, không phải lỗi. ⟢ VISION.

**Hình thái Chính trị của tầng mở rộng (federate ↔ annex) *không* phải trục thứ sáu.** Nó chỉ là một **lớp da của Rekindled Commons (I)** — nó reskin *hình học* của riêng cái thế giới nhân-từ, đông-dân ấy, không bao giờ chọn một thế giới khác. Xem ending I bên dưới.

### Năm Kiểu Nhóm-Lại

Mỗi **epithet** của seal gấp **phát minh** chủ đạo (một bản sắc đã ship) cùng với **Mode/Kingdom** chủ đạo (⟢ vision), và ít nhất một dòng epilogue mang chính cái gấp ấy, để mười giờ thể hiện build đọc được trên màn hình cuối cùng.

> **I — The Rekindled Commons** *(Diverse × Mercy × Confronted — cái kết "thật".)*
> **Trông như:** sự tan băng trọn vẹn nhất — giờ vàng được giữ lại, một bonfire của xương và xà nhà hắt vàng khắp ba vòng, cây chết trong **Canopy** khép tán, và *những survivor có tên thuộc mọi nghề làm việc sát cánh bên nhau.*
> **Hình thái Chính trị (một LỚP DA của Commons — không phải trục thứ sáu hay một thế giới mới):** cùng một cái kết nhân-từ, đông-dân khoác lên một trong hai hình học. **Federate** — một vòng đầy đủ các lò lửa độc lập được thắp trên đường chân trời, hơi ấm được giữ như một mạng lưới của những kẻ ngang hàng. **Annex — "The One Great Hearth":** một đám lửa trung tâm duy nhất mà mọi vòng quây quanh, tập trung hoá nhưng *vẫn nhân từ và đông dân.* Annex là một **thiên hướng tập trung, không bao giờ là "Plunder"** — nó là một dáng vẻ của chính cái thế giới nhân-từ này, còn con đường vơ vét của Long Watch (II) là một thế giới hoàn toàn khác.
> **World-seal (khuôn mẫu):** *"The [Craft]-Commons of the [Mode/Kingdom]."* Những cách đọc đã dựng: một chiến thắng Hearthkeeper dẫn dắt bởi Construction, Draft/Flora đóng dấu thành **"The Hearth-Keep Commons, Green Under the Gale"**; một chiến thắng Kindler dẫn dắt bởi Metallurgy, Sear/Fauna đóng dấu thành **"The Forge-Lit Commons of the Searing Pack."** Trục **bản-sắc-phát-minh reskin cùng một cái kết** — *Hearth-Keep* (Construction) / *Forge-Lit* (Metallurgy) / *Terrace* (Agriculture) / *Wright's* (Builder) Commons.
> **Ember:** *"Ngươi đã không giữ ngọn lửa. Ngươi đã dạy nó cách được giữ mà không cần ngươi. Đó là cách duy nhất nó từng được giữ."* — và, gấp cả cái build vào: *"Họ sẽ rèn sắt dưới ánh sáng của ngươi suốt một trăm mùa đông, mà chẳng bao giờ biết đến cái Pack đã giữ lũ sói ngoài cửa."*

> **II — The Long Watch** *(Monoculture × Plunder × Confronted — ấm, nhưng mỏng.)*
> **Trông như:** ấm nhưng *phẳng lì* — một kiểu công trình trải khắp mọi đường chân trời, một lò lửa lớn cháy đơn độc, cái Pack vẫn rảo bước những bức tường canh một thị trấn chật hẹp. Ánh sáng ấm và đơn điệu.
> **Đạt được theo lối metallurgy:** đơn canh, gửi-vốn-nhanh, và **đối đầu** First Warden bằng vũ lực — lực hấp dẫn mặc định của nó — *không bao giờ bằng annex.* Bạn đã ủ ấm vượt nó; lần thắp lại là duy nhất và không bao giờ bị farm (xem §3).
> **World-seal:** **"The Forge-Lit Warren of the Searing Pack — One Log, Blazing."** (Metallurgy + Sear/Radiation + Fauna.)
> **Ember:** *"Ngươi đã đánh thắng bóng tối. Nhưng một đám lửa một khúc củi thì cháy nhanh. Coi chừng cái đêm thứ hai."*

> **III — The Slow Dawn** *(Diverse × Mercy × Starved — bạn chưa bao giờ đánh Warden.)*
> **Trông như:** một **bình minh không có cái bóng nào trong đó.** Những ruộng bậc thang xanh trụ vững trước cơn gió; khi rốt cuộc bạn đi xuống tàn tích cổ nhất, vỉ lò đã ấm và đấu trường trống rỗng — First Warden từ lâu đã **rã mềm rồi biến mất**, chập chờn tắt mà không ai gặp bởi thế giới đã nhớ vượt qua nó (phán quyết Warden: §3).
> **World-seal:** **"The Terrace That Out-Warmed the Dark, Green Under the Gale."** (Agriculture + Draft/Convection + Flora.)
> **Ember:** *"Ngươi chưa bao giờ phải đánh nó. Ngươi chỉ cần nhớ nhanh hơn cái tốc độ nó có thể quên. Đó, cũng vậy, là một chiến thắng — kiểu chiến thắng dịu dàng nhất."*
> Chiến thắng "bỏ đói vực sâu" này **hoàn toàn hợp lệ và được vinh danh** — không phải một cái kết bị bỏ qua, mà là một cái kết *khác*: nhóm đủ nhiều ngọn lửa đa dạng, được chăm, và những rãnh khuôn của cái lạnh chẳng còn gradient nào để mà níu giữ. (Attractor-dynamics được kịch tính hoá — App A.)

> **IV — The Hollow Warmth** *(Monoculture × Plunder × Starved — chiến thắng cảnh tỉnh.)*
> **Cannibalise nuôi cho cái này:** những lò lửa bị *lấy* để lấy hơi ấm thay vì được thắp lại đẩy trục **Mercy** về phía Plunder, và đây là một con đường dẫn vào thế giới này.
> **Trông như:** một bầu trời ấm trên một *cánh đồng phần lớn trống trải* — và, nói thật, một **đường chân trời lạnh ở rìa**: nửa số vòng ngoài vẫn phủ giá và ngủ đông từ những Cold Snap bạn chưa bao giờ chăm, ít dân làng, một Codex đầy lỗ hổng. Hơi ấm chỉ là danh nghĩa và giòn dễ vỡ; một thế giới tham lam vừa vặn cào tới 1.0 và bóng tối cào lại các vòng ngay khoảnh khắc bạn ngoảnh đi. (Một thế giới bị vơ vét đọc là thực sự *lạnh ở rìa của nó* — không bao giờ là "ấm nhưng rỗng-lòng mà bí mật vẫn ổn.")
> **World-seal:** **"The Warm and Empty Field — the Mycelium Fed, the Hearths Few."** (Nhịp Fungi + sự trống rỗng của vơ vét.)
> **Ember, ở lúc lạnh giá nhất:** *"Ấm không giống với được nhớ. Ngươi có một ngọn lửa. Ngươi gần như chẳng còn ai để giữ nó. Coi chừng ngươi chỉ đơn giản đã dời bóng tối tới một nơi ngươi không nhìn thấy được."*

> **V — The Kept Flame** *(bất kỳ trục nào × **Codex 100%** ghi đè — cái kết tri thức.)*
> **Trông như:** thế giới tan băng trong khi các **phát minh cuộn lên trong ánh vàng** — nông nghiệp, luyện kim, xây dựng, sự gìn giữ lửa — mọi chỗ hư cấu được đọc, tri thức của mọi craft-Warden được thắp lại. Nhịp cuối thuộc về chính cái danh sách ấy.
> **World-seal:** **"The Kept Flame — Every Craft Remembered."**
> **Ember:** *"Văn minh chưa bao giờ là loot, hay thậm chí là hơi ấm. Nó là điều này — cái danh sách những gì một trí óc học được cách làm, và chịu khó truyền dạy. Mang theo điều đó, và ngươi mang theo tất cả."*

### Mỗi Con Đường Nghiêng Về Cái Kết Nào

Mỗi nguyên mẫu có một chỗ ở, và mỗi thiên hướng là một **xu hướng, không phải một đường ray** — bất kỳ nguyên mẫu nào cũng có thể mang bất kỳ thế giới nào, bởi các trục đọc *những lựa chọn* của bạn, không phải class của bạn. Toàn bộ chuỗi seed→cascade (worldline mặc định của nguyên mẫu nào trôi về seal nào, và vì sao) nằm ở **§4**; nó không được suy lại ở đây.

### Sau Ember Cuối Cùng — Các Điểm Đến Hậu-Chiến-Thắng

**Mọi điểm đến bên dưới đều với tới được từ *bất kỳ* save nào đã hoàn thành.** Cái kết bạn đạt được chỉ **rọi đèn** vào một cái — nó không bao giờ chặn việc cái nào trong số chúng tồn tại. Hoàn thành một lần, và tất cả những thứ này đều mở.

| Điểm đến | Nó là gì | Ghi chú |
|---|---|---|
| **Endless Deep** | qua vỉ lò giờ-đã-ấm của First Warden, tàn tích cứ tiếp tục đi xuống; các phòng-Warden **thông thường** tái diễn như cấu trúc roguelite bình thường; các cổng Frost-Encased sâu dần (vật lý: App A) | nơi ở của trục **Sâu-Đến-Đâu** — một **kỷ lục độ sâu** đã gửi, không bao giờ là một vòi warmth hay loot (GWI đã là 1.0). Bạn không bao giờ giết lại First Warden — một lần thắp lại duy nhất (§3) |
| **Legacy / New Game+** *(hợp nhất)* | **một** hệ thống: bắt đầu lại với **Codex nguyên vẹn và Soil đã gieo**, một thế giới đã thành hình truyền nghề xuống; khung cảnh **thẩm mỹ** theo từng cái kết khoác cho thị trấn khởi đầu của bạn tính cách của cái kết bạn đạt được | gộp "Legacy" và "Soil-carry" thành một chế độ duy nhất. Gieo tới giai đoạn N trao các bậc phẳng của giai đoạn 1..N **và** một lượt draft boon đầu-run cho những lần Bloom bị bỏ qua — một khởi đầu ấm không bao giờ là một sự thiếu hụt boon (§1) |
| **World-Seal + epilogue đọc-lại-được** | **epithet** và seal tự-sinh của bạn trên màn hình title/pause (gấp phát minh chủ đạo + Mode/Kingdom ⟢ + dấu độ sâu, và — với một chiến thắng Commons — lớp da federate/annex của nó), với **epilogue chỉ cách một cú nhấp**, đọc-lại-được bất cứ lúc nào | cái kết bạn đạt được đưa một seal ra tiền cảnh; bạn có thể xem lại bất kỳ seal nào bạn đã giành được |
| **Bảo tàng Codex** | một căn phòng đọc-được vĩnh viễn — mọi phát minh và chỗ hư cấu được đánh dấu, **hiển thị theo xếp hạng tác động**; lịch sử phục hồi của bạn (khoá/mở + dấu "recovered on run N") là một **kênh riêng**, không bao giờ truyền tải qua vị trí danh sách | nơi ở của Kept Flame, nhưng mở từ *bất kỳ* save nào, không bị chặn riêng cho cái kết ấy. Codex cố định và trung thực — các thế giới federate/annex không thêm mục nào xoá-được (App A/D) |
| **Ngôi Làng Đang Sống** | Cold Snaps, Husk Incursions, và **Long Night** tuỳ chọn giữ cho thị trấn ấm là một thứ *được chăm*; những **lò lửa chập chờn** khác vẫn gọi được thắp lại vì survivor mới và chiều sâu Codex | mái nhà vẫn đặt cược — hơi ấm được giữ là hơi ấm được mang theo. Incursion **phủ giá một vòng, không bao giờ san bằng nó**; con người không bao giờ là tiền đặt cược. Long Night làm sâu thêm gradient lạnh (App A) |

Toàn bộ kiến trúc thanh toán cái thanh duy nhất của Pillar 3: bạn không "thắng" REKINDLED bằng cách đánh vượt sát thương một vũng máu — kẻ địch sâu nhất **không chảy máu; nó chập chờn rồi tắt**, bị tháo gỡ bởi cái thứ duy nhất nó không thể đáp lại, một ai đó vẫn nhớ. Dù seal của bạn gọi tên cái nào trong năm thế giới, epilogue thưởng bạn không loot gì cả — chỉ có thế giới giờ-vàng, những survivor có tên, và cái Codex: *những con người và tri thức bạn đã mang theo, và không gì khác.*
---

## 11. Co-op — Hai Đốm Lửa, Một Lò Sưởi

Co-op là mảnh đất trống hoàn toàn. Lớp thiết kế này được tạo ra để củng cố luận đề thiêng liêng — *văn minh sống trong con người và tri thức, không phải trong chiến lợi phẩm* — chứ không làm loãng nó. Nguyên tắc dẫn đường: co-op không phải "thêm nhiều mèo," mà là ẩn dụ trung tâm của game được hiện thực hoá theo nghĩa đen. Hơi ấm được truyền **từ tay này sang tay khác**, hoặc nó sẽ mất đi.

> **Thực tế xây dựng (cờ):** Engine chưa có netcode và chỉ có một bản lưu ConfigFile cho meta của làng; trạng thái RUN cố tình không được lưu. Mọi thứ bên dưới đều được giới hạn phạm vi **ưu tiên chơi chung ghế (chung màn hình, hai gamepad)**, với chơi online là một bước nâng cấp về sau. Không có gì ở đây giả định phải viết lại mô hình lưu — làng dùng chung vẫn là một `hearth-save` do host sở hữu, đúng như hiện tại.

> **⟢ VISION.** Heat Modes, Kingdoms, các Husk Families và ma trận Mode × Family mà phần này dựng nên là **lớp vision đã lên kế hoạch**, chưa ship. Co-op kế thừa toàn bộ chúng; chưa có gì đã xây trong game hôm nay có thêm người chơi thứ hai cả.

### Số lượng người chơi & hư cấu về nhiều Ember

**Khuyến nghị: 2 người chơi là lõi đã tinh chỉnh; 3 là trần hoàn hảo theo canon; không có 4.**

Lý do là science-first, không hề tuỳ tiện. Một hệ thống sống cần ba vai trò: **Producers (Flora), Consumers (Fauna), Decomposers (Fungi)** — vốn đã là ba Kingdoms, vốn đã ánh xạ tới ba nghề có thể cứu (Builder, Smith, Farmer). Vậy nên một nhóm ba người không phải "thêm một cái xác," mà là một **bộ ba diễn thế hoàn chỉnh**: hai người chơi chọn hai trong ba và cảm nhận một khoảng trống có chủ ý; ba người chơi khép kín vòng lặp. Người thứ tư phá vỡ cả ẩn dụ dinh dưỡng *lẫn* ngân sách khả đọc (xem phần scaling bên dưới).

**LITHO tạm thời đứng ngoài nhóm.** Vai trò sinh thái thứ 4 được để dành — bể chứa chemolithotroph — là một **mở khoá solo late-meta**, không phải một slot co-op; ba lần cứu = bộ ba hoàn chỉnh là **cơ sở** của co-op. Liệu LITHO có bao giờ trở thành slot co-op thứ 4 hay không là **TBD (đã cắm cờ)**.

#### Hư cấu — Ember cho mượn một spark

Xưa nay chỉ từng có **một** Ember cuối cùng. Hai điểm hơi ấm có thể băng qua đống đổ nát, nhưng ngọn lửa không bao giờ bị chia đôi — làm vậy sẽ hạ thấp mức cược và mâu thuẫn với vật lý. Thay vào đó, Ember **cho mượn một spark**: con mèo nhóm *nhiên liệu của chính* một người bạn đồng hành từ một Ember duy nhất, và người bạn ấy mang ánh sáng vay mượn với tư cách một **Sparkbearer** (một con cùng lứa, hoặc một người sống sót mà con mèo đã nhóm lại).

Cho mượn một spark là **lan lửa trung thực** — sự cháy lan sang nhiên liệu mới chính xác là điều lửa vẫn làm, và đó là ẩn dụ của cả game được hiện thực theo nghĩa đen, nên nó chẳng cần biện minh. Cái gian lận được kịch tính hoá duy nhất nằm ở chỗ khác: khi một spark leo lét và *chảy ngược về* Ember để được rekindle (đã cắm cờ ở phần hồi sinh, bên dưới).

| Phương án hư cấu | Giữ "một ember cuối cùng" thiêng liêng? | Phục vụ "được mang, từ tay sang tay"? | Phán quyết |
|---|---|---|---|
| Chia Ember thành các phần bằng nhau cho các con cùng lứa | Không — lửa chia được = mức cược rẻ đi | Yếu ớt | Bác bỏ |
| Mỗi người chơi là một người mang Ember độc lập | Không — giờ có nhiều Ember "cuối cùng" | Không | Bác bỏ |
| **Con mèo nhóm một SPARK cho mượn trong người bạn; Ember thật vẫn nguyên vẹn** | **Có — ngọn lửa không bao giờ bị chia, chỉ được lan** | **Có, theo đúng nghĩa đen** | **Khuyến nghị** |

Người chơi 1 là con mèo hung mang một Ember duy nhất; mỗi người đồng hành là một **Sparkbearer** mang ánh sáng đã nhóm, vay mượn. Bạn có thể mất một *bearer* mà không bao giờ mất *ngọn lửa*, vì ngọn lửa xưa nay luôn là thứ được mang giữa người với người.

### Vai trò & tổ hợp đội — dựng nên một nhóm

Heat Modes và Kingdoms là **theo từng người chơi**, nên một nhóm *dựng nên* những tương tác mà không tay solo nào chạm tới cùng lúc được. Ba bản sắc rõ ràng rơi thẳng ra từ ba nghề cứu; hai người chơi chọn hai nửa bổ sung nhau, ba người lấp đầy vòng lặp.

#### Ai làm gì

| Vai trò trong nhóm (Kingdom / dinh dưỡng) | Nguồn cứu | Heat Mode mặc định (thiên lệch) | Nhiệm vụ trong trận |
|---|---|---|---|
| **The Slow Bloom** — Flora / Producer | Builder | Radiation ("Sear") | Giữ trận địa; hào quang bức xạ + hồi máu trong ánh sáng; rễ và gai lột husk khỏi đồng đội đang lao vào |
| **The Bright Predator** — Fauna / Consumer | Smith | Conduction ("Blaze") | Pháo thuỷ tinh; burn-DoT + hút máu + đà bầy đàn khi hạ gục; lao vào các husk máu thấp mà Bloom phơi bày ra |
| **The Rot-Reaper** — Fungi / Decomposer | Farmer | Convection ("Draft") | Đòn kết liễu bằng luồng bốc lên + vệt hot-draft; husk bị nhiễm rơi nhiều Materials hơn và nuôi Soil; oxy cho ngọn lửa của Predator |

**Mode và Kingdom tách rời nhau sau các lần cứu.** Một Kingdom là bản sắc pool boon **cố định trong suốt run** (thiên lệch bởi lần cứu đã mở khoá nó); một Heat Mode **hoán đổi giữa run và tại Rest-Hearths** — với người chơi co-op y hệt như với tay solo. Vậy nên Mode "mặc định" ở trên là một xu hướng nghiêng, không phải một khoá cứng: các cặp chéo như **Sear + Fauna** hay **Draft + Fungi** hoàn toàn hợp lệ một khi cả hai lần cứu đã có.

**Một ghi chú về Sear và các cổng:** Sear **tăng tốc** giai đoạn khởi động của một cổng nhưng không bao giờ **bỏ qua** nó, nên lợi thế Frost-Encased được giữ bằng **các chuỗi Thermal-Shock đa mode**, không phải một tia nóng đơn lẻ (phần vật lý — hấp thụ IR, cao nguyên nhiệt ẩn cố định, tầm-với-chứ-không-xuyên-thấu, tất cả đều gắn ⚑ — nằm ở App A).

**Ba nguyên mẫu còn lại vẫn có đất thể hiện** — chúng là các lớp phủ Mode/meta/làng, tách rời khỏi slot Kingdom, nên bất kỳ thành viên nhóm nào cũng có thể nghiêng về một cái:

- **The Hearthkeeper** — mỏ neo tuyến đầu. Bản sắc HP của nó đến từ **các tier +MaxHP của Cabin / Construction**, *chứ không* từ việc spam attunement +2HP; mức cược mèo thuỷ tinh 6-HP được giữ nguyên (không bao giờ là một con mèo 20-HP).
- **The Kindler** — chuyên gia Radiation/Sear phá **các cổng độ sâu Slag và Frost-Encased** qua các chuỗi Thermal-Shock đa mode.
- **The Archivist** — người mang tri thức, chuyển các đoạn Codex giữa các thế giới (tiến trình mang theo được, bên dưới).

Mặc định hai người chơi = **Slow Bloom + Bright Predator** (đe + búa). Thêm Rot-Reaper vào và nhóm tự duy trì: Decomposer nuôi Soil và các món rơi ra, Producer hồi máu, Consumer chuyển hoá nó thành sức ép.

#### Tổ hợp đội — và lợi thế co-op thực sự nằm ở đâu

Ma trận Mode × Family trung thực với vật lý trở thành lối chơi *đội*. Nhưng phần lớn nó **đã chạm tới được khi chơi solo** bằng cách hoán đổi Mode tuần tự giữa run hoặc tại một Rest-Hearth — co-op chỉ đơn giản cho phép hai build *cố định* chồng lấn nhau trong **thời gian thực**. Bốn tổ hợp nhiệt nằm chung trong một danh sách bên dưới cùng với các nước đi mà *bản chất* chỉ có ở co-op — chuỗi tiếp sức cứu, hồi sinh spark-relay, và trận thủ làng.

| Nước đi co-op | Nguồn | Hiệu ứng | Khắc chế tốt nhất | Chỉ co-op? |
|---|---|---|---|---|
| **Firestorm** | Conduction burn + Convection draft | Draft cấp oxy cho ngọn cháy → lửa mạnh lên và tự lan khắp phòng | **Bramble** (khô, nhiều nhiên liệu — dẫn lửa) | **Không** — có thể solo bằng hoán đổi Mode tuần tự |
| **Thermal Shock** | Radiation sear + Conduction burst | Nung nóng cục bộ làm nứt vỡ một khối rắn lạnh, giòn (App A) | **Slag / Frost-Encased** | **Không** — có thể solo qua các chuỗi đa mode |
| **Nutrient Bloom** | Fungi kill + Flora field | Đòn hạ gục của Decomposer làm rơi một bloom hồi máu/gai mà ánh sáng của Producer khuếch đại | Tiêu hao **Beast**, các trận kéo dài | Chỉ chồng lấn — không phải cổng cứng |
| **Boil-Off Brigade** | **Hai nguồn nhiệt lên một mục tiêu cùng lúc** | Nhiệt song song xoá cổng độ ẩm của Beast trong nửa thời gian | **Beast** (ẩm — đun sôi nước trước) | **Có** — thực sự đồng thời |
| **Rescue-carry chain** | Hai người chơi tiếp sức một người sống sót đang lẽo đẽo theo sau | Trao một người sống sót từ người này sang người kia, một người yểm trợ trong khi người kia mang — luận đề như một *động từ chơi* | các phòng hộ tống / phục kích | **Có** |
| **Spark-relay revive** | Một con mèo còn sống khum lấy spark leo lét của bạn đồng hành | Nhóm lại một Sparkbearer đã gục (xem *Gục / hồi sinh*, bên dưới) — khoảnh khắc đúng chủ đề nhất trong cả game | bất kỳ đồng đội nào đã gục | **Có** — solo không giữ lại hồi sinh |
| **Defend the village together** | Cả hai người chơi, trong ngôi nhà bạn đã dựng | Giữ ngôi làng ấm áp dùng chung theo cặp khi vực sâu phản công — móc nối co-op của chế độ endless hậu-thắng | Husk Incursions / Long Night | **Có** |

**Quy tắc, nói thẳng ra:** chỉ các tổ hợp **hai-nguồn đồng thời** thực sự (*Boil-Off Brigade*) mới là lợi thế chỉ-có-ở-co-op. **Firestorm** và **Thermal Shock** đạt được khi **solo** qua hoán đổi Mode tuần tự giữa run / tại Rest-Hearth, và **không có kỷ lục độ sâu nào bị khoá sau các tổ hợp chỉ-co-op** — một tay solo có thể chạm tới độ sâu tối đa. Co-op *nhanh hơn và hào nhoáng hơn* ở những cái này, chứ không *bắt buộc* để có chúng.

**⚑ Thermal Shock:** một sự nứt vỡ do nung nhanh chỉ-bằng-lửa (mỏ neo trung thực: đốt phá đá; toàn bộ khung diễn giải và quyền tự do ⚑ của nó nằm ở App A). Phiên bản co-op không thay đổi gì về mặt vật lý — nó chỉ đơn giản đưa bước nung nóng từ hai Mode cùng một lúc.

Ví dụ dựng nên (hành vi × family kết hợp trực giao với nhau): một **Frost-Encased Lobber** phải được rã đông trước khi cú ném vòng cung của nó đáp xuống, và một **Slag Bomber** phải được làm nứt trước khi nó có thể nổ ra — cả hai đều là nhịp "một người dựng cổng, người kia thu tiền" gọn gàng.

### Đường xuống trong co-op

**Di chuyển trên bản đồ:** cả nhóm là **một token dùng chung** trên đồ thị nút phân nhánh (giữ mọi người ở cùng nhau và bản đồ dễ đọc). Bên trong một đấu trường bị khoá họ di chuyển và chiến đấu **độc lập**. Giữa các phòng, quay về một token.

**Túi đeo — mang riêng, ngân hàng chung.** Mỗi người chơi lấp đầy túi run **của riêng mình** và gánh rủi ro mất trắng **của riêng mình**: nếu *bạn* ngã trong bóng tối, *bạn* mất chiến lợi phẩm *của bạn* — rủi ro/phần thưởng mèo thuỷ tinh vẫn cá nhân và nguyên vẹn, phản chiếu y hệt cơ chế mất trắng của solo. **Các lần cứu và attunement**, ngược lại, **vào ngân hàng tức thì và toàn nhóm** ngay khoảnh khắc một người sống sót được giải cứu. Chiến lợi phẩm thì riêng tư và có thể đánh cược; *con người và tri thức* thì cộng đồng và an toàn — luận đề, được thực thi bằng cấu trúc phần thưởng.

**Các phán quyết ngoại lệ về túi đeo:**

| Trường hợp ngoại lệ | Phán quyết |
|---|---|
| Một người chơi hết giờ (spark chảy ngược), rồi cả nhóm tới một cổng **HOME** | Túi **chưa đổ** của họ **vẫn vào ngân hàng** — hết giờ không tự động là mất trắng toàn bộ |
| Các ember đã đổ bị bỏ lại không nhặt | **Mất trắng ở lần chuyển phòng kế tiếp** (chỉ hồi phục được trong phạm vi phòng) |
| **Cả nhóm cùng leo lét gục** | **Mọi túi chưa vào ngân hàng đều mất trắng** (ngang bằng với cú ngã bóng tối của solo); Ember sống sót, bạn khập khiễng về nhà với những gì đã vào ngân hàng |
| Các lần cứu / attunement | **Vào ngân hàng ngay khoảnh khắc một người sống sót được giải cứu** — không bao giờ bị rủi ro |

**Bỏ phiếu cổng (DEEPER hay HOME).** Đẩy sâu hơn là cam kết mạo hiểm, nên nó cần đồng thuận: **DEEPER cần đa số** (ở 2P, phải nhất trí). **Bất kỳ một người chơi nào cũng có thể gọi HOME** — vào ngân hàng luôn là lối thoát an toàn, và không ai bị lôi vào bóng tối trái với gan dạ của mình. Khi 2P chia rẽ, Ember mời một nhịp Rest-Hearth để cân nhắc lại, rồi mặc định về **HOME**. Căng thẳng đẩy-hay-gửi-ngân-hàng trở thành một lớp *xã hội* mà không làm đình trệ bản đồ.

**Mở rộng cũng là một cuộc bỏ phiếu chung.** Các lựa chọn World-Map Spectrum — reclaim, federate, annex, cannibalise — là những nhịp đồng thuận chung được giải quyết y hệt cuộc bỏ phiếu cổng DEEPER: một cam kết lâu dài cần sự đồng thuận của cả nhóm (chi tiết ở §6).

**Gục / hồi sinh — spark-relay.** Ở 0 HP một Sparkbearer không chết — nó **leo lét**: mất khả năng chiến đấu, spark cho mượn của nó chập chờn trên mặt đất. Một người bạn có thể **Rekindle** nó (đứng sát bên, giữ — "khum lấy spark") để hồi sinh ở mức HP thấp. Nếu không ai tới kịp, spark **chảy ngược về Ember**: người chơi đó ngồi ngoài cho tới phòng / Rest-Hearth kế tiếp và **làm đổ một phần túi của mình** thành "ember đã đổ" có thể hồi phục mà đồng đội có thể nhặt.

> **⚑ Quyền tự do (cắm cờ Ở ĐÂY, không phải ở việc cho mượn):** một spark leo lét *chảy ngược về* nguồn của nó để được rekindle là cái gian lận vật lý duy nhất — sự cháy không có lan-ngược về nguồn của nó. Việc *cho mượn* một spark là lan lửa trung thực và chẳng cần biện minh; chỉ có việc *quay về* này là được kịch tính hoá.

**Đọc trên màn hình:** con mèo gục đổ sập xuống thành một đốm-ember mờ, leo lét trên sàn; các chân của người hồi sinh khum quanh nó và một sợi ánh sáng thấy được bắc cầu giữa hai bên, đốm nhỏ phồng trở lại thành một ngọn lửa đầy đủ trên một hợp âm ấm dâng lên — dễ đọc xuyên một đấu trường đông đúc mà không cần tooltip. **Solo không giữ lại hồi sinh** (hậu quả cái chết solo không đổi), nên co-op *khác biệt*, chứ không *miễn phí-dễ hơn*: hồi sinh đã tốn chiến lợi phẩm rơi mất và nhịp độ.

**Cân bằng độ khó — sức ép theo từng người chơi giữ ở mức cơ sở của solo.** Sức ép solo là **~2 kẻ tấn công cam kết cho một người chơi** (trụ cột khả đọc: chỉ ~2 husk cam kết cùng lúc) = **2.0 mỗi người chơi**. Co-op **không** hạ thấp con số này. Số kẻ tấn công cam kết **co giãn theo quy mô nhóm để giữ 2.0 mỗi người**: **2P → 4 cam kết, 3P → 6 cam kết.** *Quần thể* husk cũng phình ra để các phòng cảm thấy đầy hơn, nhưng mỗi người chơi vẫn đối mặt với ~2 vùng nguy hiểm báo trước, nên đám đông vẫn dễ đọc. **Điểm cộng của co-op là hồi sinh + tổ hợp đội + con người dùng chung — không bao giờ là sức ép thấp hơn**; solo không bao giờ là một bản co-op bị cắt xén. Warden nhận thêm HP và **một làn báo đòn phụ cho mỗi người chơi thêm vào**, đặt sao cho các vùng nguy hiểm không bao giờ chồng lấn thành một vệt bôi không đọc nổi.

**Các lò sưởi leo lét — thắp lại hoặc ăn thịt, cùng nhau.** Các phòng sâu hơn giữ lò sưởi đang tàn của *những* người sống sót khác. Cả nhóm có thể **thắp lại** một cái (một lần cứu — vào ngân hàng toàn nhóm, tức thì) hoặc **ăn thịt** nó lấy hơi ấm và vật liệu còn sót lại. Ăn thịt sẽ **mất đi lần cứu đó**: người sống sót **không bao giờ được cho thấy đang chết** — *con người không bao giờ là tiền cược* — nhưng con người và tri thức của họ rời khỏi thế giới vĩnh viễn và **GWI sứt mẻ**. Trong co-op điều này trở thành một nhịp đạo đức chung (đồng thuận, như cuộc bỏ phiếu cổng); sức nặng mà cả hai người chơi mang ra ngoài là *thứ bạn đã chọn không mang theo.*

| Câu hỏi về đường xuống | Phán quyết |
|---|---|
| Di chuyển bản đồ | **Một token dùng chung**; độc lập bên trong các đấu trường |
| Lựa chọn cổng | DEEPER = đa số (2P nhất trí); **HOME = bất kỳ một người chơi nào** |
| Mô hình gục | **Leo lét → Rekindle** hồi sinh; hết giờ = spark quay về + món ember-đổ rơi ra |
| Sức ép cam kết | **~2.0 mỗi người chơi** luôn luôn (2P→4, 3P→6 kẻ tấn công cam kết) |
| Blooms / boons | **Cá nhân** — Kindle riêng, Blooms riêng, chọn-1-trong-3 riêng (tính công hỗ trợ khi hạ gục để chặn ăn bám) |
| Sát thương đồng đội | **Không có ở sát thương.** Các trường burn/draft/fungi của đồng minh là có lợi/trung tính; một luồng bốc lên Convection có thể *đổi vị trí* (không sát thương) một đồng đội |

Blooms cá nhân là thiết yếu: chúng bảo tồn bản sắc build của mỗi người chơi (mộng tưởng của tay solo) *đồng thời* chúng chính là thứ khiến các tổ hợp ở trên trở nên khả thi.

### Ngôi làng trong co-op

**Làng của ai? Một khu định cư dùng chung, bền vững, do host sở hữu.** Khách cư ngụ trong thế giới của host; không có ngôi làng "phiên bản riêng" nào phải hoà giải — điều này khớp với bản lưu ConfigFile đơn lẻ hiện có mà không cần công sức lưu trữ mới nào.

Cả hai người chơi **xây, làm nông, và làm nhiệm vụ đồng thời** từ một **kho chung**, biến giai đoạn chuẩn bị thành một nhịp "gian bếp" co-op: một người đặt móng và chạy vòng Carpenter/Builder trong khi người kia chăm chuỗi Farm và khuân vác. Đặt công trình theo thứ tự tới trước với một điểm nhấn "claim" nhẹ để hai cây búa không va nhau.

**"Cứu tri thức, cung ứng lao động" với hai lao động:** nửa *tri thức* (cứu người sống sót biết nghề) vẫn là một sự kiện đơn lẻ, toàn nhóm — không nhúng hai lần. Nửa *lao động* (nhiệm vụ giao tài nguyên) **song song hoá được**: hai người chơi hoàn thành nhiệm vụ của một công trình nhanh hơn, hoặc một người giao trong khi người kia chuẩn bị móng kế tiếp. Mở rộng khoảng đất trống là một cái hố chung, nên **ngôi làng ấm áp lớn lên thấy rõ là nhanh hơn trong co-op** — mộng tưởng "cùng nhau xây dựng nó," và một lý do thực sự để mời một người bạn. **Trần 3-hiệu-ứng mỗi run và các quy tắc giảm dần hơi-ấm-trùng-lặp không bị đụng tới**, nên co-op vẫn thưởng cho một ngôi làng *đa dạng*, không phải spam.

### Drop-in / drop-out & tiến trình mang theo được

- **Giai đoạn làng:** tự do drop-in/out. Spark của một người khách gia nhập được nhóm tại đống lửa; khi rời đi, spark quay về Ember và con mèo-khách cuộn mình bên lò sưởi. Không phạt.
- **Rời giữa run:** spark rời đi quay về Ember (một cú hết-giờ-leo-lét bắt buộc), túi chưa vào ngân hàng đổ ra thành ember hồi phục được cho host, và run **tinh chỉnh lại xuống còn N người còn lại ở ranh giới phòng kế tiếp** (không bao giờ giữa đấu trường — làm vậy sẽ bất công).
- **Host rời = phiên kết thúc.** Chiến lợi phẩm và hơi ấm ở lại với thế giới của host, nên một người khách không thể vét sạch GWI của bạn bè.

**Tiến trình mang theo được — quy tắc giữ cho các bản lưu trung thực:**

- **Tri thức Codex mang theo được.** Cốt truyện là thứ ít sức mạnh, nên một người khách mang các đoạn văn đã phục hồi về nhà vào Codex **của riêng mình**; *tri thức là mục đích*, và đó là thứ duy nhất họ có quyền chính đáng mang đi.
- **Attunement thì KHÔNG tự do mang theo được.** Một attunement bị ràng buộc với một lần cứu được thực hiện trong thế giới **của riêng** một người chơi. Các lần cứu thực hiện bên trong thế giới co-op của host vào ngân hàng cho GWI **của host**, toàn nhóm, nhưng không cấp cho người khách buff **vĩnh viễn** nào trên bản lưu solo (nhiều nhất là một **carry phân số/tạm thời — quy tắc chính xác TBD**). Đối xứng lại, **gia nhập một phiên không bao giờ nạp trước các attunement vĩnh viễn của bản lưu solo của bạn** ở sức mạnh đầy đủ — một run co-op không thể là một cú nhập-buff. Điều này bảo tồn kỷ luật attunement trần-của-3 (một attunement ý nghĩa mỗi element/Kingdom, hiệu suất giảm dần mạnh) và chặn co-op khỏi việc vét sạch hoặc tầm thường hoá bất kỳ thế giới nào.
- **Sự vắng mặt trong ngôi làng bền vững:** các đóng góp đơn giản là tồn tại tiếp. Ngôi làng không theo dõi ai đã vung búa, nên một người bạn quay lại chỉ việc nhóm lại tại lò sưởi — không cần sổ sách bóng ma.

### Co-op thay đổi game như thế nào — nhìn thoáng qua

| Giai đoạn | Solo | Với co-op |
|---|---|---|
| **Early** | Học các tổ hợp trên Bramble; việc vặt làng chậm rãi | **Chuẩn bị song song hoá**; những chuỗi tiếp sức rescue-carry đầu tiên; học Rekindle một người bạn đang leo lét |
| **Mid** | Hoán đổi Mode để đáp lại các cổng một mình | **Các đội hình đội bền vững** chạy Firestorm / Thermal Shock *đồng thời* (solo được nếu làm tuần tự, ở đây nhanh hơn); *Boil-Off Brigade* là lợi thế chỉ-co-op thực sự trên các cổng Beast; bỏ phiếu cổng trở nên xã hội |
| **End** | Đẩy solo tới GWI 1.0; endless-sâu một mình | **Đẩy co-op tới việc rekindle**; endless-sâu theo cặp; **cả hai cái tên trên con dấu legacy của một-thế-giới-được-rekindle**, với biệt hiệu gói gọn phát minh chủ đạo và Mode/Kingdom của mỗi người chơi |

Mọi phán quyết ở trên đều được chọn sao cho **solo không mất gì** (túi riêng, rủi ro riêng, build riêng, độ sâu chạm tới được riêng, không có nạng hồi sinh) trong khi **co-op có ý nghĩa gì đó mới mẻ** (căng thẳng token-dùng-chung, dựng bộ ba dinh dưỡng, hồi sinh từ tay sang tay, dựng làng song song) — và để cả lớp thiết kế nói, một lần nữa, điều duy nhất mà REKINDLED luôn nói: *hơi ấm được mang, từ tay sang tay, hoặc nó sẽ mất đi.*
---

## Phụ Lục A — Sổ Cái Khoa Học Trên Hết

Mọi cơ chế trong bible này đều được neo vào một quá trình vật lý, sinh thái hoặc lịch sử có thật, với mỗi chỗ "phóng túng" được đánh dấu ⚑ và nêu rõ ràng. Đây là Pillar 2 dưới dạng một cuộc kiểm toán: một tiến bộ có thật, câu chuyện nhân quả *đúng*, các chỗ phóng túng được gắn cờ, tác động vượt trên niên đại. Các dòng gắn thẻ ⟢ VISION mô tả lớp đích đến và chưa được ship.

| Cơ chế | Điểm neo thực tế (câu chuyện nhân quả trung thực) | Phóng túng ⚑ | Trạng thái |
|---|---|---|---|
| **Heat Modes** | Ba phương thức truyền nhiệt đích thực. **Conduction/Blaze** = truyền qua tiếp xúc (đòn cháy DoT rơi đúng chỗ vuốt chạm tới). **Radiation/Sear** = bức xạ hồng ngoại qua khoảng cách (quầng bức xạ không cần chạm). **Convection/Draft** = nhiệt được mang đi bởi chất lỏng/không khí chuyển động (đòn kết liễu bằng luồng khí bốc lên cưỡi theo cột nhiệt đang dâng). | ⚑ Một Ember chuyển đổi gọn gàng giữa cả ba phương thức "tùy ý" là một sự trừu tượng hóa gameplay; nguồn nhiệt thật rỉ cả ba phương thức cùng lúc. | ⟢ VISION |
| **Kindle = nhiệt cháy** | Giết một husk giải phóng năng lượng hóa học tích trữ của nó thành nhiệt — một enthalpy of combustion (nhiệt cháy) theo đúng nghĩa đen. Lượng thu được thay đổi theo **họ** vì nhiên liệu khô giàu lignin (Bramble) giải phóng nhiều nhiệt dễ khai thác hơn mô ẩm (Beast) hay khoáng chất gần trơ (Slag, ~0 kindle). | ⚑ Những "điểm kindle" tức thời, lượng tử hóa trừu tượng hóa một phản ứng tỏa nhiệt liên tục thành một con số. | SHIPPED (dưới dạng kill→Kindle) |
| **Cổng Frost (sensible → latent heat cố định)** | Rã đông một khối rắn Frost-Encased tuân theo phép đo nhiệt lượng thật: đầu tiên **sensible heat** (nhiệt cảm) nâng nhiệt độ tới điểm nóng chảy (phần này tỉ lệ với việc bạn gia nhiệt mạnh đến đâu), rồi tới một **cao nguyên latent-heat cố định** (nhiệt ẩn) nơi năng lượng đi vào chuyển pha ở nhiệt độ không đổi. Cao nguyên này là một chi phí cố định — không thể rút ngắn. | — (đây là vật lý thuần túy; không cần phóng túng) | ⟢ VISION (trạng thái theo độ sâu) |
| **Cổng độ ẩm Beast (latent heat of vaporisation)** | Mô Beast ẩm ướt trước hết phải làm bay hết nước của nó — **latent heat of vaporisation** (nhiệt ẩn hóa hơi) — trước khi có thể bốc cháy. Nước là một hố hút cháy đích thực, đó là lý do nhiên liệu ướt kháng lửa. | — (thật; nhiên liệu ướt quả thực bị chặn bởi điều này) | ⟢ VISION (cổng theo họ) |
| **Thermal Shock** | Vết nứt do **gia nhiệt nhanh**, chỉ dùng lửa: dồn một gradient nhiệt dốc vào một khối rắn lạnh, giòn gây ra giãn nở chênh lệch giữa bề mặt nóng và lõi lạnh, và khối rắn nứt vỡ. Điểm neo lịch sử trung thực là **fire-setting** (nung đá bằng lửa) — thợ mỏ từ thời Đồ Đá Cũ đến La Mã nung đá ngay tại gương lò để làm nó vỡ. | ⚑ Thermal shock kinh điển trong sách giáo khoa thường cần một bước **làm lạnh/tôi** nhanh mà bộ kỹ năng chỉ-lửa không có; fire-setting trong lịch sử *tôi bằng nước* để làm nứt đá. Bộ kỹ năng giữ lại vết nứt nhưng không bao giờ viết "nung rồi làm lạnh." | ⟢ VISION |
| **Sear đấu Frost (băng hấp thụ IR)** | Sear/Radiation **tăng tốc giai đoạn làm nóng sensible-heat** vì băng và nước hấp thụ hồng ngoại mạnh — một đặc tính có thật, có cơ sở. Nó rút ngắn đoạn dốc lên; nó **không** bỏ qua cao nguyên nóng chảy latent-heat cố định. | — (hấp thụ IR là thật; cao nguyên được giữ lại một cách trung thực) | ⟢ VISION |
| **Sear đấu Slag / giáp** | Đối đầu Slag gần trơ, lợi thế thật của Sear là **truyền nhiệt mà không phải sống sót qua đánh cận chiến** — truyền bức xạ qua khoảng cách giữ con mèo-thủy-tinh khỏi một cuộc đổi đòn nguy hiểm. | ⚑ "Cắt xuyên giáp" là *ẩn dụ cho tầm với*, không phải xuyên thấu theo nghĩa đen; nhiệt bức xạ không đi vòng qua một khối rắn. Vì Sear chỉ *tăng tốc* mà không bao giờ đi vòng, **The Kindler** giữ được lợi thế Frost thật thông qua các chuỗi Thermal-Shock đa phương thức, chứ không nhờ một cú bỏ-qua-giáp phép thuật. | ⟢ VISION |
| **Diễn thế (bậc thang Bloom)** | Nở từ Ash → Pioneer → Herb → Thicket → Canopy là **diễn thế nguyên sinh** trên **nền khoáng trần trụi**: đợt đóng băng dài đã bào mòn bề mặt, nên "Ash" đặt tên cho bề mặt khoáng bị bào lạnh, không phải chất hữu cơ còn sót, và địa y/loài tiên phong đến trước. Đây là một **chuỗi diễn thế / giai đoạn seral về sau**, dứt khoát **không** phải "leo cao hơn trên chuỗi thức ăn." | ⚑ Diễn thế nguyên sinh thật mất hàng thập kỷ đến hàng thế kỷ; nén nó vào một lần xuống hang là một sự nén-một-lần-xuống có chủ ý. | SHIPPED (5 giai đoạn) |
| **Giới Fungi** | Các sinh vật phân hủy khép kín vòng: nấm trả lại dưỡng chất bị khóa cho nền, và *Armillaria* mọc **rhizomorph** — những sợi dây giống rễ có thật lan qua đất và nối chuỗi giữa các vật chủ (cơ sở trung thực cho chuỗi rhizomorph Armillaria và "husk nhiễm bệnh rơi nhiều vật liệu/Soil hơn"). | ⚑ Lan-chuỗi vũ khí hóa và tiền thưởng tỉ lệ rơi đồ là kinh tế game phủ lên sinh thái phân hủy có thật. | ⟢ VISION |
| **Hồi phục Flora** | Hồi phục của Flora là **do ánh sáng thúc đẩy, không phải do hơi ấm** — nó mô phỏng quang hợp, vốn được cấp năng lượng bởi ánh sáng, nên con mèo hồi máu "trong ánh sáng," không phải "khi ấm." | ⚑ Hồi phục tức thời theo thang thời gian chiến đấu trừu tượng hóa một quá trình trao đổi chất chậm. | ⟢ VISION |
| **The Long Dark (nguyên nhân)** | **Entropy / mất-gradient** được làm dễ hiểu: "thế giới lạnh đi theo cách mọi ngọn lửa lạnh đi — từng khoảnh khắc không ai trông một." Nó là tổng của những gì kẻ sống thôi không nhớ, đó là lý do việc nhớ lại có thể hóa giải nó. **Không** có phản diện-có-mưu-đồ. | ⚑ Không phải một kẻ đối kháng đầy toan tính, và cố tình **không** đóng khung như một "cực tiểu địa phương" cần tối ưu hóa để loại bỏ — nó là sự lãng quên nhiệt động lực học, chỉ được trao một khuôn mặt nơi Warden. | SHIPPED (xương sống lore) |
| **Long Night (mức đặt cược thế giới)** | Một sự **sâu thêm theo mùa / theo độ nghiêng trục** của gradient lạnh — đêm dài nhất, khi độ nghiêng đưa cái vòng xa nhất khỏi hơi ấm của nó và gradient nhiệt độ dốc hơn. | ⚑ Nhịp và mức độ nghiêm trọng được nén lại để chơi; tính mùa theo trục thật thì diễn ra từ từ. | ⟢ VISION (giai đoạn về sau) |
| **The Warden (khuôn mặt)** | "Cái lạnh học được một hình hài… đánh nó thì nó không chảy máu; nó lụi dần rồi tắt, như ngọn lửa đói khí." Một thiếu hụt cục bộ của nhiệt/năng lượng, bị đánh bại bằng cách **phục hồi** nhiệt, chứ không phải bằng cách làm bị thương một cơ thể. | ⚑ Một trạng thái nhiệt động lực học phân tán được trao một bóng dáng đơn nhất có thể đánh được. | SHIPPED (một Warden) |
| **Attunements (buff giải cứu)** | Mỗi sống sót được giải phóng dạy một thích nghi bền vững (Bramble Ward, Ember Fang, Gale Step). Được mô hình hóa thành **một buff có ý nghĩa mỗi nguyên tố/Kingdom với suy giảm mạnh** — phản chiếu kỷ luật giới-hạn-3 của các công trình, nên con mèo-thủy-tinh 6-HP không bao giờ bị thổi phồng thành một xe tăng 20-HP. Bản sắc HP của **The Hearthkeeper** đến từ các tier +MaxHP của Cabin/Construction, không phải từ chồng các attunement +2HP. | ⚑ Buff "được nhớ" vĩnh viễn tái áp mỗi lần xuống hang trừu tượng hóa kỹ năng học được thành một chỉ số. | SHIPPED (một attunement) |
| **Rút nhiệt theo độ cao** (Glaciated Spire, UP) | Leo lò rèn đỉnh của Metallurgy, không khí trên cao quả thực **lạnh hơn, loãng hơn, và ít oxy hơn** — lapse-rate (suất giảm nhiệt) thật và áp suất riêng phần giảm — nên hơi ấm rỉ đi nhanh hơn khi bạn đẩy càng cao và lửa phải thở khó hơn để giữ mình. | ⚑ Mức rút mỗi mét và thuế "lửa cần khí trên cao" được tinh chỉnh theo nhịp của một run, không theo trắc lượng độ cao thật. | ⟢ VISION |
| **Ngâm trong nước lạnh** (Drowned Coast) | Rơi qua mặt biển đóng băng, việc đột ngột ngâm trong nước gần đóng băng tước nhiệt lõi **nhanh gấp nhiều bậc so với không khí lạnh** — cold-shock (sốc lạnh) thật và làm nguội lõi nhanh. | ⚑ Làm nhẹ đi để chơi — một cú lao thật khiến bất tỉnh trong vài phút; run cấp một đồng hồ rút-hơi-ấm có thể sống sót thay vào đó. | ⟢ VISION |
| **Megafauna trong băng vĩnh cửu (hai cổng frost-rồi-độ-ẩm)** | Một xác đông cứng sâu bị khóa trong băng vĩnh cửu là một **cuộc rã đông hai cổng**: trước hết phải **tan chảy** (sensible heat + latent heat of fusion — nhiệt ẩn nóng chảy) và chỉ *khi đó* độ ẩm được giải phóng của nó mới có thể **bay hơi** (latent heat of vaporisation) trước khi mô bắt lửa — cổng Frost và cổng độ ẩm Beast chồng lên nhau trong một cơ thể, nối tiếp. | — (đo nhiệt lượng thuần túy: hai cao nguyên thật nối đuôi nhau) | ⟢ VISION |
| **Nứt băng biển theo thủy triều / lead mở ra** (Drowned Coast) | Biển đóng băng **uốn theo thủy triều** và nứt thành **lead mở ra** — sự uốn và nứt thật của băng biển — nên con đường cái chung dịch chuyển và há hốc dưới chân. | ⚑ Nhịp nứt và độ rộng lead được đặt bởi một bộ đếm thủy triều tinh chỉnh để chơi, không theo chu kỳ thủy triều thật. | ⟢ VISION |
| **Khuếch tán hơi ấm như vết loang** (World Map) | Hơi ấm được chăm sóc **lan ra ngoài và hơi ấm bị bỏ mặc rút lại** khắp bản đồ như một vết loang — hướng trung thực của một gradient nhiệt / khuếch tán thật (hơi ấm chảy xuống theo gradient, và một nguồn thôi được nuôi sẽ nguội trở lại về phía cái lạnh). | ⚑ Hướng thì trung thực; *tốc độ* vết loang gặm màu trắng (hoặc rút lại) là kịch tính, nén lại để có một bản đồ dễ đọc. | ⟢ VISION |
| **Lan lửa Ashen-Wald** (Woodcraft, ACROSS) | Lửa lan qua **gỗ chết đứng khô** — lan lửa mặt/tán thật qua nhiên liệu đã sấy khô, khu Wald là một rừng bị đợt đóng băng giết chết và làm khô. | ⚑ Tro là **cũ, có trước đợt đóng băng**, và các đám cháy **chỉ do người chơi gây ra** (không có cháy rừng tự phát); tốc độ lan được tinh chỉnh cho lối chơi đấu trường. | ⟢ VISION |
| **Woodcraft / than củi** (the Last Wright) | Đốt gỗ trong điều kiện thiếu oxy đẩy các chất bay hơi ra ngoài, để lại **than củi — nhiên liệu nóng hơn, sạch hơn mà một lò rèn thực sự cần** để đạt nhiệt luyện kim: liên kết nhân quả trung thực từ Woodcraft ACROSS tới lò-rèn-sâu của Metallurgy. | ⚑ Một bước "làm than củi" tức thời trừu tượng hóa một cuộc đốt nhiệt phân chậm. | ⟢ VISION |
| **Codex phát minh (cố định, xếp theo tác động)** | Tri thức **không bao giờ xóa được**. Codex là một sổ cái **cố định, xếp theo tác động, trung thực** về các tiến bộ có thật (App D), sắp xếp theo hệ quả — không theo niên đại, không theo lượt chơi. Lớp mở rộng **KHÔNG khiến các mục Codex trở nên xóa được hay thêm "phương ngữ" theo từng cộng đồng**: federate / annex / cannibalise thay đổi **hình học chính trị của bản đồ, dân số, và những mục có thật nào mà một thế giới nhất định đã thắp lại**, chứ không bao giờ thay đổi bản thân sổ cái cố định. | — (chính sự trung thực *là* thiết kế; mọi màu sắc theo từng cộng đồng sống trên một bề mặt lore-cộng-đồng tách bạch rõ ràng, ngoài sổ cái phát minh) | SHIPPED (xếp-theo-tác-động) + ⟢ VISION (kênh mở rộng) |

## Phụ Lục B — Lộ Trình SHIPPED → VISION

Các chương của bible này mô tả **đích đến**. Phụ lục này là **con đường**. Mọi thứ gắn thẻ ⟢ VISION ở trên bật lên theo từng giai đoạn; không có gì ở đây được trình bày như thể đã đang chạy.

### Một phiên chơi TRÔNG như thế nào HÔM NAY (đã ship)

Một run là một bản sắc nhiệt duy nhất, không phải một ma trận. Bạn **DESCEND** tại Supply Gate vào một bản đồ nút phân nhánh gồm các đấu trường bị khóa. Bạn chiến đấu bằng Kindled Claws (mèo 6-HP, combo 3 đòn, dash i-frame, guard/perfect parry) chống lại một dàn quái dễ đọc nơi chỉ ~2 husk lao vào cùng lúc. Giết chóc tạo **Kindle**; các ngưỡng cho bạn **Bloom** lên qua năm giai đoạn diễn thế, mỗi Bloom là một bước chỉ số phẳng cộng một **boon chọn-1-trong-3** — và Blooms/boon **reset mỗi lần xuống hang**. Bạn có thể **giải cứu một sống sót** để rồi họ đi theo bạn; giải phóng họ **ký gửi tức thì** và cấp một **attunement vĩnh viễn duy nhất** tái áp mỗi lần xuống hang. Các phòng đã dọn mở cổng **DEEPER hoặc HOME**. Trở về trong ánh sáng để **ký gửi**; ngã trong bóng tối và **mất** phần lớn túi đồ. Về lại **VILLAGE**, bạn xây/trồng/mở rộng khoảng đất trống, vận hành vòng đời công trình (Dormant → Blueprint → Operational → Upgraded qua nhiệm vụ giải cứu + tài nguyên), và **GWI** nhích lên khi hơi ấm được ký gửi. Một Warden đứng làm boss; **Soil** gieo mầm cho giai đoạn khởi đầu của bạn. Đó là toàn bộ vòng lặp đã ship, và nó trọn vẹn theo cách của riêng nó.

### Cú bật-lên theo giai đoạn (ánh xạ tới PROGRESSION_DESIGN Phases 1–5)

| Giai đoạn | Lớp vision bật lên | Điều người chơi mới cảm nhận |
|---|---|---|
| **Phase 1 — Một Mode** | **Heat Mode** đầu tiên đi vào hoạt động như một công cụ thật, đổi được (bắt đầu với Conduction/Blaze). Các con số tô-màu-theo-mode xuất hiện. | "Lửa của tôi có một *cá tính* mà tôi có thể mang theo và đổi tại các Rest-Hearth." |
| **Phase 2 — Ma Trận Đầy Đủ** | Cả ba Mode + các **Family** vật liệu (Bramble/Beast/Slag) và trạng thái độ-sâu **Frost-Encased**, kết hợp trực giao với dàn hành vi thành ma trận **Mode × Family** đầy đủ. | "*Cách* nó tấn công và *nó làm bằng gì* là hai câu hỏi khác nhau — một Bramble Charger bốc cháy khi Blaze; một Slag Bomber phải bị nứt vỡ trước khi nổ; một Frost-Encased Lobber phải được rã đông trước khi vòng cung của nó rơi tới." |
| **Phase 3 — Kingdoms + panel** | **Kingdoms** (Flora/Fauna/Fungi) như các bản sắc pool-boon, lệch theo lần giải cứu tương ứng, với UI panel bản sắc. Sau các lần giải cứu tương ứng, **Mode và Kingdom tách rời** — các cặp chéo như **Sear + Fauna** hay **Draft + Fungi** trở nên hợp lệ. | "Tôi chọn một *bản sắc* run, không chỉ một dòng chỉ số, và tôi có thể trộn một Mode với một Kingdom khác-nguyên-tố." |
| **Phase 4 — Meta / persistence + World-Stakes v1** | Persistence sâu hơn và đề xuất **Soil tái-cân-nặng** (chi phối bởi số-lượng-giải-cứu + đa dạng làng, GWI là số hạng phụ), cộng với **World-Stakes v1 = một Cold Snap thuần kinh tế** (một vòng ngoài bị bỏ mặc chuyển sang dormant / mất hơi ấm; **không husk vào làng, không giao chiến trong làng**). | "Một thế giới nhân từ, đa dạng khởi đầu *xa hơn dọc chuỗi diễn thế*; một thế giới bị cướp phá khởi đầu thực sự **thô sơ và chân-trời-lạnh**." |
| **Phase 5 — Capstone** | **Chiến thắng** (GWI 1.0 → đoạn kết đọc-lại-được) và các đích đến hậu-thắng, các kết cục đền đáp cho công cuộc xây dựng, và vai trò meta-muộn solo thứ 4 **LITHO** đã được dành sẵn. | "10 giờ biểu đạt xây dựng hiện rõ trên màn hình cuối cùng." |

### Cú bật-lên biên cương & world-map (mở rộng bảng giai đoạn)

Các worldline (§4), các môi trường run (§5), và World Map & mở rộng (§6) bật lên qua cùng những giai đoạn đó, phủ lên trên các dòng ở trên. Chỉ lần xuống hang Buried Warren + Warden đơn nhất của nó ship hôm nay; mọi biên cương và craft-Warden khác đều là ⟢ VISION.

| Giai đoạn | Lớp biên cương / thế giới bật lên | Điều người chơi mới cảm nhận |
|---|---|---|
| **Phase 2** | Một **tham số biome** trên bản đồ run, và biên cương thay thế đầu tiên — **Frostmarch Tundra** (những cánh đồng bị chôn vùi của Agriculture, OUT) — đứng cạnh nền tảng Buried Warren. **Glaciated Spire** (lò rèn đỉnh của Metallurgy, UP) bắt đầu cuộc leo của nó ở đây. | "Cuộc xuống hang không phải cánh cửa duy nhất — cùng một run có thể tiến *ra ngoài* vào những cánh đồng đóng băng hoặc bắt đầu *leo lên* Spire." |
| **Phase 2–3** | **Glaciated Spire** hoàn tất (rút nhiệt theo độ cao, đỉnh lò-rèn-sâu và Cold-Struck Smith của nó), và **Ashen Wald** (Woodcraft, ACROSS — the Last Wright) bật lên, **bị chặn bởi việc Blaze / Heat Modes** tồn tại vì nó sống nhờ lan lửa do người chơi gây ra. | "Mỗi phát minh giờ có một *nơi chốn* — tôi leo lên lò rèn, tiến quân qua những cánh đồng, hay đốt một con đường xuyên khu Wald chết." |
| **Phase 4** | **World Map**, **phổ mở rộng** (federate ↔ annex ↔ cannibalise), và con đường cái chung **Drowned Coast** (biển đóng băng, lead thủy triều, không có craft-Warden) bật lên bên trên World-Stakes và Soil tái-cân-nặng. | "Làng tôi là một *điểm trên bản đồ* có thể vươn ra và thắp lại các láng giềng — như một mạng lưới các lò sưởi, một trung tâm duy nhất, hay bằng cách ăn thịt chúng." |
| **Phase 5** | **Các kết cục bị chi phối bởi worldline** (con đường của mỗi biên cương nghiêng về việc bạn đạt tới cái nào trong năm sự thắp-lại) và capstone **First Hearth / First Warden** mà mọi worldline hội tụ về. | "Nơi tôi đã đi định hình cách thế giới trở lại — và điểm tận cùng sâu nhất luôn là cùng một First Hearth ngay từ đầu." |

**Các chi phí xây dựng được gắn cờ, KHÔNG bị giấu:** cú xoay trục phòng-thủ-căn-cứ **Husk Incursion / tháp canh / Long Night** là một *giai đoạn về sau đáng kể* vượt ra ngoài World-Stakes v1 — nó giới thiệu giao chiến trong làng mà màn hình xây/trồng hiện tại hoàn toàn không có, nên nó là một chi phí kỹ thuật thật, không phải một cú lật ngưỡng. Co-op là **greenfield** (chưa hề tồn tại). Và chỗ ⚑ phóng túng của hư cấu co-op sống cụ thể trên **cú revive** (một tia sáng lụi "chảy ngược về" để được thắp lại — sự cháy không có lan-truyền-ngược), chứ không trên việc cho mượn tia sáng, vốn là lan lửa trung thực.

**Hai chi phí gắn cờ nữa mà lớp biên cương thêm vào:** các worldline là một **bội số nội dung**, không phải một cú lật ngưỡng — mỗi biên cương thêm vào là một biome đầy đủ về nghệ thuật, dàn quái, và craft-Warden riêng của nó, nên phân nhánh *nhân* chi phí xây dựng lên chứ không tái dùng Warren. Và **lớp World-Map / mở rộng thừa hưởng cú xoay trục phòng-thủ-căn-cứ** đã gắn cờ ở trên: vươn ra để giữ, sáp nhập, hay bảo vệ một láng giềng đã thắp lại được xây trên cùng công trình kỹ thuật giao-chiến-trong-làng đáng kể đó, không bao giờ miễn phí trên đầu nó.

## Phụ Lục C — Đặc Tả Hình Ảnh & Khả Năng Đọc Hiểu

Pillar 1: một hệ thống cần một tooltip là một hệ thống chưa hoàn thiện. Mỗi hệ thống mới cam kết một **dấu hiệu nhìn/nghe được** đọc được trên màn hình mà không cần giải thích.

| Hệ thống mới | Cách nó ĐỌC ĐƯỢC TRÊN MÀN HÌNH (dấu hiệu) |
|---|---|
| **Dormancy Cold-Snap** (World-Stakes v1) | Vòng ngoài bị bỏ mặc **rõ ràng nhạt màu và phủ băng** — màu sắc rút về phía xám-xanh, ánh-lò-sưởi thu nhỏ, đồng hồ hơi ấm của quận đó tối đi — nên "vòng này đã dormant" là một cái nhìn, không phải một con số. |
| **Revive tiếp-sức-tia-sáng** (co-op ⟢ VISION) | Một bạn đồng hành đã lụi tối lại thành một ember-husk; một **vòng cung tia sáng nhìn thấy được** tiếp sức từ một con mèo còn sống và bạn đồng hành **bùng cháy lại với một lóe** — dòng-chảy-ngược đọc như một sự kiện sáng, có chủ đích, một-nhịp. |
| **Firestorm** (combo đồng thời co-op) | Hai nguồn nhiệt chồng lên nhau và đấu trường **nở thành một tấm lửa gầm rú chung** với một đợt trầm dâng lên — rõ ràng là một cảnh tượng *hai-nguồn*, khác biệt với bất kỳ đòn solo nào. |
| **Thermal Shock** (đạt được solo qua các cú đổi Mode tuần tự) | Khối rắn Frost/Slag bị đánh trúng **rạn thành mạng nhện với các đường-nứt phát sáng** và vỡ tan trên một tiếng *rắc* sắc — vết nứt, chứ không phải một thanh máu, cho bạn biết nó có hiệu quả. |
| **Nutrient-Bloom** (Fungi ⟢ VISION) | Cái chết của một husk nhiễm bệnh gửi đi một **đợt bùng rhizomorph xanh-vàng đang lan** khắp mặt đất, rõ ràng gieo mầm thêm vật liệu/Soil — sự phân hủy mà bạn có thể xem nó hồi trở lại. |
| **Warden lụi tắt** | Warden không chảy máu — bị đánh trúng, nó **lụi và tối đi như một ngọn lửa đói khí**, bóng dáng chập chờn tắt dần về than hồng rồi tắt hẳn. Dập tắt, chứ không bao giờ là một cái xác. |
| **Con số tô-màu-theo-mode + glyph họ** | Con số sát thương được **nhuộm theo Mode đang hoạt động** (Blaze/ Sear/ Draft mỗi cái sở hữu một sắc) và mỗi kẻ địch mang một **glyph họ nhỏ** (Bramble/Beast/Slag) cộng một lớp phủ rime-băng khi Frost-Encased — nên cách đọc Mode × Family là tức thì. |
| **Hé lộ trục-kết-cục** | Con dấu-thế-giới cuối cùng **đóng một biệt danh dựng từ phát minh và Mode/Kingdom chi phối của bạn**, tạo diện mạo lại cho "Rekindled Commons" thành một dáng vẻ **Forge-town / Terrace / Hearth-Keep** với ít nhất một câu đoạn-kết gọi tên công cuộc của bạn — màn hình cuối cho thấy bạn đã dựng lại *ngọn lửa nào*. |
| **World map vết-loang-hơi-ấm** (mở rộng ⟢ VISION) | Hơi ấm đọc như **màu sắc gặm màu trắng** — một thế giới được chăm sóc lan một vết loang sống động khắp lớp băng — và *hình dạng chính trị* dễ đọc trong nháy mắt: một **mạng lưới nhiều ánh sáng nhỏ** (diện mạo federate), **một trung tâm sáng** cấp năng cho các nan hoa (diện mạo annex), hay một **điểm sáng duy nhất** với phần còn lại vẫn trắng (diện mạo cannibalise). |
| **Lò sưởi được thắp lại / sáp nhập / ăn thịt** (world map ⟢ VISION) | Trên bản đồ một lò sưởi láng giềng **bùng lại đầy màu sắc** khi được thắp lại, **buộc vào trung tâm của bạn bằng một nan hoa ấm** khi bị sáp nhập, hay **tối đi và rót ánh sáng của nó vào của bạn** khi bị ăn thịt — lựa chọn chính trị là một hoạt ảnh một-nhịp, không phải một dòng menu. |
| **Cách đọc biên cương: whiteout / rút-nhiệt-độ-cao / băng-mỏng** (biome ⟢ VISION) | Mỗi biên cương kể mối nguy của nó ngay khi nhìn — **whiteout** của Frostmarch Tundra nuốt các mép màn hình, **rút-nhiệt-độ-cao** của Glaciated Spire vắt máu đồng hồ hơi ấm nhanh hơn khi bạn leo càng cao, và **băng mỏng** của Drowned Coast rạn thành các vết-nứt-ứng-suất và lead mở ra dưới chân. |
| **Craft-Warden lụi tắt** (theo từng biên cương ⟢ VISION) | Craft-Warden của mỗi biên cương chết theo cách của Warden — **lụi dần về than hồng, không bao giờ là một cái xác** — nhưng mang nghề của mình khi tắt: Cold-Struck Smith tối đi như một **lò rèn đang nguội**, Keeper of the Empty Rows như **những luống đồng trắng dần**, Last Wright như một **ngọn lửa cháy tàn thành tro**, Unfinished Arch như một **lò sưởi bị dập giữa lúc đang xây** — nên "Warden của biên cương này đã tắt" là một cái nhìn, không phải một số-lần-giết. |

## Phụ Lục D — Trợ Năng, Các Núm Tinh Chỉnh Mở & Bản Đồ Code

### Tùy chọn hỗ trợ cho con mèo-thủy-tinh 6-HP

Cú mất-đồ với mức đặt cược thật cần một van trợ năng — điều này cũng bù cho mọi cảm nhận "co-op an toàn hơn," vì người chơi solo nhận được cùng sự nhẹ nhõm.

- **Độ khó Assist / Story** — sát thương nhận vào nhẹ hơn và khoan dung ở cú đổ đồ ký-gửi-hay-mất, mà không phá hình dạng của vòng lặp.
- **Token tự-giải-cứu solo tùy chọn** — một lần tự-cứu duy nhất mỗi run để một cú ngã trong bóng tối không phải lúc nào cũng là mất trọn (phản chiếu lòng khoan dung của cú revive co-op cho người chơi solo).
- **Nới rộng thời điểm telegraph** — kéo dài đoạn lấy đà của vùng-nguy-hiểm-đỏ để dấu hiệu đọc được ở tốc độ phản ứng chậm hơn; cửa sổ parry/dodge co giãn theo nó.
- **Co giãn UI** — chỉnh kích thước HUD, con số, và glyph họ để dễ đọc.
- Mức đặt cược mèo-thủy-tinh 6-HP vẫn là **mặc định**; các trợ giúp là tùy chọn bật-vào và không bao giờ là chuẩn cân bằng.

### Các núm tinh chỉnh mở (rõ ràng TBD — chưa giải quyết)

- **Ngưỡng Cold-Snap** — mức hơi ấm mà tại đó một vòng ngoài lật sang dormant.
- **Nhịp Incursion** — tần suất/mức độ nghiêm trọng của Husk Incursion (giai đoạn về sau).
- **Cửa sổ hồi phục ember-đổ** — túi đồ co-op bị đổ có thể nhặt trong bao lâu trước khi chuyển phòng.
- **Nhịp Long Night** — độ nghiêng trục sâu thêm dao động thường xuyên đến mức nào / sâu đến mức nào.
- **Trọng số Soil chính xác** — các hệ số số-lượng-giải-cứu / đa-dạng / GWI-phụ của công thức tái-cân-nặng (công thức đã ship `soil = gwi*0.6 + rescued*0.05` đã được gắn cờ để thay thế).
- **Đường cong / giới hạn suy-giảm của attunement** — mức suy giảm chính xác theo từng nguyên tố giữ vững bản sắc mèo-thủy-tinh.
- **Co giãn kẻ-tấn-công-cam-kết co-op** — xác nhận 2P→4, 3P→6 giữ ~2.0 áp lực mỗi người chơi.
- **Nhịp đồng thuận mở rộng** — bao lâu thì cuộc đồng thuận/bỏ phiếu trên world-map để vươn ra, federate, hay annex một láng giềng được giải quyết.
- **Ngưỡng trạng-thái-hơi-ấm cộng đồng** — mức hơi ấm mà tại đó một cộng đồng láng giềng đọc là sáng / lụi / tối (và do đó trở nên đủ điều kiện thắp-lại hoặc annex).
- **Tham số biome** — tinh chỉnh theo từng biên cương: mức rút whiteout của Frostmarch, đường cong rút-nhiệt-độ-cao của Glaciated Spire, và tốc độ lan lửa của Ashen Wald.
- **Bội số nội dung worldline** — bao nhiêu biên cương ship mỗi giai đoạn, vì mỗi cái là một biome đầy đủ + craft-Warden (cần gạt chi-phí-phân-nhánh).
- **Bộ đếm thủy triều Drowned-Coast** — nhịp nứt-thủy-triều / lead-mở-ra trên con đường cái biển-đóng-băng.

### Bản đồ code & doc (định hướng, tên file chuẩn tắc)

| Hệ thống doc | (Các) file chính |
|---|---|
| Chiến đấu mèo: HP, combo, dash i-frame, pounce, guard/perfect parry | `godot/scripts/player.gd` |
| Dàn hành vi kẻ địch (Husk/Charger/Lobber/Bomber/Warden), telegraph, quy tắc đám-đông ~2-cam-kết | `godot/scripts/enemy.gd` |
| Cấu trúc run: bản đồ nút, kiểu phòng, cổng, túi đồ, ký-gửi-hay-mất | `godot/scripts/dungeon.gd`, `godot/scripts/run_map.gd` |
| **Trường biome** biên cương trên bản đồ run (chọn Warren / Spire / Tundra / Wald và các tham số của nó) | `godot/scripts/run_map.gd`, `godot/scripts/dungeon.gd` |
| Làng: khoảng đất trống, lò sưởi, vòng đời công trình, nông trại, nhiệm vụ, hơi ấm | `godot/scripts/village.gd` |
| World map: các quận, khuếch tán vết-loang-hơi-ấm, phổ mở rộng (federate/annex/cannibalise) | `godot/scripts/world_map.gd`, `godot/scripts/expansion.gd` |
| **Cộng đồng** láng giềng như một thực thể (trạng-thái-hơi-ấm sáng/lụi/tối, thắp-lại / annex / cannibalise) | `godot/scripts/community.gd` |
| Trạng thái meta: GWI, Kindle/Bloom, boon, attunement, Soil, save/load | `godot/scripts/game_state.gd` |
| Sống sót được giải cứu đi theo người chơi | `godot/scripts/survivor.gd` |
| Văn bản Codex, xếp-theo-tác-động, lore (Long Dark / Warden) | `godot/scripts/lore.gd` |
| HUD, menu, panel, UI chung, bản địa hóa, âm thanh | `godot/scripts/hud.gd`, `hud_menus.gd`, `hud_panels.gd`, `ui_kit.gd`, `loc.gd`, `sfx.gd` |
| Lớp vision (Heat Modes, Kingdoms, Families, ma trận, biome sâu) | `VISION.md` |
| Thiết kế của-hồ-sơ cho build hiện tại | `GAME.md`, `DESIGN.md` |
| Kế hoạch bật-lên Phase 1–5 | `PROGRESSION_DESIGN.md` |
| Thiết kế vòng đời làng / công trình | `VILLAGE_DESIGN.md` |
| Phê bình thường trực + phát hiện QA dẫn dắt lộ trình | `CRITIQUE.md`, `QA_REPORT.md` |

Ghi chú: Codex được **hiển thị xếp-theo-tác-động** (canon) trong `lore.gd`; **lịch sử khôi phục** của người chơi — trạng thái khóa/mở khóa cộng một dấu "khôi phục ở run N" — là một **kênh tách bạch** mang trong `game_state.gd`, không bao giờ được truyền tải bởi vị trí trong danh sách. Các khác biệt federate / annex / cannibalise của lớp mở rộng cưỡi trên cùng kênh khôi phục/trạng-thái-sáng này và hình học chính trị của world-map (`world_map.gd`, `expansion.gd`), cộng với dân số — **không bao giờ** bằng cách thêm các mục xóa-được hay phương ngữ theo-từng-cộng-đồng vào sổ cái phát minh cố định, xếp-theo-tác-động.
