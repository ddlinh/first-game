class_name Loc
extends RefCounted
## Lightweight localization (code-first, like Vfx / Iso / Lore). `Loc.t(en)` returns
## the Vietnamese string for an English SOURCE string when `GameState.lang == "vi"`,
## else the source unchanged. A missing key falls back to the English source, so a
## partial table never blanks or crashes — the gap just shows English.
##
## Format strings are keyed by their TEMPLATE ("Đã dựng %s!") and interpolated AFTER
## translation at the call site: `Loc.t("%s raised!") % Loc.t(label)`. Dynamic nouns
## (pillars / materials / building names) are in the table too, so they translate
## when interpolated in.

# English source → Vietnamese. Grouped by area for maintenance; lookup is flat.
const VI := {
	# --- Nouns interpolated into other strings (pillars, materials, buildings) ---
	"farmer": "nông dân", "smith": "thợ rèn", "builder": "thợ xây",
	"Farmer": "Nông dân", "Smith": "Thợ rèn", "Builder": "Thợ xây",
	"wood": "gỗ", "stone": "đá", "iron": "sắt", "food": "lương thực", "seeds": "hạt giống",
	"Cabin": "Lều Gỗ", "Forge": "Lò Rèn", "Crop Bed": "Luống Rau", "Expand Clearing": "Mở Rộng Khoảng Trống",
	"a captive": "một tù nhân",

	# --- The Ember & scripted intros ---
	"The Ember": "Tàn Lửa",
	"You carried me through the long dark. I am nearly spent… but not yet.":
		"Ngươi đã mang ta qua đêm trường tăm tối. Ta gần lụi tàn… nhưng chưa hẳn.",
	"This was a village once. Rebuild it, and my light returns — warmth, and hope with it.":
		"Nơi đây từng là một ngôi làng. Dựng lại nó, ánh sáng của ta sẽ trở về — hơi ấm, và hy vọng theo cùng.",
	"Let me see you move — walk with W, A, S, D.":
		"Để ta xem ngươi di chuyển — đi bằng W, A, S, D.",
	"Good. You remember. Hold Right-Mouse to raise a guard; tap Space to dash.":
		"Tốt. Ngươi còn nhớ. Giữ Chuột-Phải để giơ khiên đỡ; nhấn Space để lướt.",
	"Try a dash — press Space.": "Thử lướt xem — nhấn Space.",
	"Beneath us sleeps the ruin, thick with husks and the things they hoard.":
		"Bên dưới là tàn tích say ngủ, dày đặc lũ vỏ rỗng và những gì chúng cất giấu.",
	"Descend at the Supply Gate below. Bring home survivors and materials — then build.":
		"Xuống bằng Cổng Tiếp Tế phía dưới. Mang người sống sót và vật liệu về nhà — rồi xây dựng.",
	"Husks. Hollow things I left behind when the world went cold. They feel nothing.":
		"Lũ vỏ rỗng. Những thứ trống hoác ta bỏ lại khi thế giới hóa lạnh. Chúng chẳng cảm thấy gì.",
	"Left-Mouse swings. Right-Mouse guards a blow. Space dashes you clean THROUGH them.":
		"Chuột-Trái vung chém. Chuột-Phải đỡ đòn. Space lướt xuyên THẲNG qua chúng.",
	"Clear every husk and the sealed gates open — then choose: deeper for spoils, or home to build.":
		"Dọn sạch lũ vỏ rỗng thì cổng phong ấn sẽ mở — rồi chọn: xuống sâu tìm chiến lợi phẩm, hay về nhà xây dựng.",

	# --- Objectives ---
	"Descend at the Supply Gate  (walk to it, press E)": "Xuống ở Cổng Tiếp Tế  (đi tới, nhấn E)",
	"The exits are sealed — clear every husk": "Lối ra đã phong ấn — dọn sạch lũ vỏ rỗng",
	"Raise a building — press B, place a Cabin, then hammer it up (E)":
		"Dựng một công trình — nhấn B, đặt một Lều Gỗ, rồi đóng nó lên (E)",
	"Plant a seed on the Crop Bed — stand on it and press E":
		"Gieo một hạt trên Luống Rau — đứng lên đó và nhấn E",
	"Warm the village, then Descend at the Supply Gate": "Sưởi ấm ngôi làng, rồi Xuống ở Cổng Tiếp Tế",
	"Choose a path — Tab shows the map": "Chọn một lối đi — Tab để xem bản đồ",
	"The ruin is conquered — take the gate home": "Tàn tích đã bị chinh phục — vào cổng để về nhà",

	# --- Contextual tips ---
	"A captive! Stand close and press E to free them — they'll follow you home to join the village.":
		"Một tù nhân! Đứng sát và nhấn E để giải cứu — họ sẽ theo ngươi về làng.",
	"Loot goes in your satchel (bottom-left). Bank it at a HOME gate — die in the dark and you lose most of it.":
		"Chiến lợi phẩm vào túi đồ (góc dưới-trái). Ký gửi ở cổng VỀ NHÀ — chết trong bóng tối là mất gần hết.",
	"Pick a building, then place it on a tended (bright) tile. The closer to the hearth, the more warmth it gives. 'Expand Clearing' tends more land.":
		"Chọn một công trình, rồi đặt nó lên ô đất đã khai hoang (sáng). Càng gần lò sưởi, càng nhiều hơi ấm. 'Mở Rộng Khoảng Trống' khai hoang thêm đất.",
	"That's a frame. Stand beside it and tap E a few times to hammer it up.":
		"Đó là cái khung. Đứng cạnh và nhấn E vài lần để đóng nó lên.",
	"Empty soil. Press E to plant a seed, then come back when it's ripe.":
		"Đất trống. Nhấn E để gieo hạt, rồi quay lại khi chín.",
	"Ripe! Press E to harvest — food to live on, and a seed to replant.":
		"Đã chín! Nhấn E để thu hoạch — lương thực để sống, và một hạt để gieo lại.",
	"Warmth rises with every building — watch the gauge, top-right. A warm village is the whole goal.":
		"Hơi ấm tăng theo mỗi công trình — nhìn thanh đo, góc trên-phải. Ngôi làng ấm áp chính là mục tiêu.",
	"The gates are open. Press Tab to see the ruin map, then walk into a glowing gate to choose your path.":
		"Các cổng đã mở. Nhấn Tab để xem bản đồ tàn tích, rồi bước vào một cổng phát sáng để chọn lối đi.",
	"The clearing grew. Keep expanding to reclaim the wild and raise a real settlement.":
		"Khoảng trống đã rộng ra. Tiếp tục mở rộng để giành lại vùng hoang và dựng một khu định cư thực thụ.",

	# --- Toasts ---
	"%s raised!": "Đã dựng %s!",
	"+%d%% warmth": "+%d%% hơi ấm",
	"Recovered: %s  —  press K for the Codex": "Đã thu hồi: %s  —  nhấn K để mở Sách Tri Thức",

	# --- Construction management: upgrade / relocate / demolish (CRITIQUE V1/V4) ---
	"MANAGE": "QUẢN LÝ",
	"Esc to cancel": "Esc để hủy",
	"Relocate": "Di dời", "Demolish": "Phá dỡ",
	"Deepen its boon and warmth; the structure grows taller.":
		"Tăng sức mạnh và hơi ấm; công trình vươn cao hơn.",
	"Pick it up and set it on a new tile — no materials lost.":
		"Nhấc lên và đặt vào ô mới — không mất vật liệu.",
	"Salvage %s — half the materials; the rest is lost to the teardown.":
		"Tận thu %s — nửa số vật liệu; phần còn lại mất khi phá dỡ.",
	"Manage %s  (Lv %d)  [E]": "Quản lý %s  (Cấp %d)  [E]",
	"Manage %s  [E]": "Quản lý %s  [E]",
	"%s demolished — salvaged %s": "Đã phá dỡ %s — tận thu %s",
	"%s relocated": "Đã di dời %s",
	"Placing %s — pick a tended tile   ·   arrows/mouse, Enter/click, Esc":
		"Đang đặt %s — chọn ô đã khai hoang   ·   mũi tên/chuột, Enter/nhấp, Esc",
	"Relocating %s — pick a tended tile   ·   arrows/mouse, Enter/click, Esc":
		"Đang di dời %s — chọn ô đã khai hoang   ·   mũi tên/chuột, Enter/nhấp, Esc",
	"Warmth here: +%d%%   ·   closer to the hearth is warmer   ·   R turns it   ·   Esc to cancel":
		"Hơi ấm tại đây: +%d%%   ·   càng gần lò sưởi càng ấm   ·   R để xoay   ·   Esc để hủy",
	"Relocating — pick a tended tile   ·   R turns it   ·   Esc to cancel":
		"Đang di dời — chọn ô đã khai hoang   ·   R để xoay   ·   Esc để hủy",
	"Blocked tile — pick a bright, empty one   ·   Esc to cancel":
		"Ô bị chặn — chọn ô sáng, trống   ·   Esc để hủy",

	# --- M8: player expression (rotation / paths / decorations) ---
	"Lay Paths": "Lát Đường", "Turn": "Xoay", "%s turned": "Đã xoay %s",
	"Face it the other way — looks only, no change to its warmth.":
		"Quay nó về hướng khác — chỉ để nhìn, không đổi hơi ấm.",
	"Paint dirt paths between your buildings — purely for looks, no warmth.":
		"Vẽ những lối đất giữa các công trình — thuần để nhìn, không có hơi ấm.",
	"Decoration — dresses the town, adds no warmth.":
		"Trang trí — tô điểm ngôi làng, không thêm hơi ấm.",
	"Paint paths — click or drag tended tiles   ·   Esc when done":
		"Vẽ lối đi — nhấp hoặc kéo trên ô đã khai hoang   ·   Esc khi xong",
	"Click to pick this decoration back up   ·   Esc when done":
		"Nhấp để nhặt lại vật trang trí này   ·   Esc khi xong",
	"Place a decoration — looks only   ·   R turns it   ·   Esc when done":
		"Đặt một vật trang trí — chỉ để nhìn   ·   R để xoay   ·   Esc khi xong",
	"Can't decorate here — pick a tended, empty tile   ·   Esc when done":
		"Không trang trí được ở đây — chọn ô đã khai hoang, còn trống   ·   Esc khi xong",
	# Decoration names
	"Flower Bed": "Luống Hoa", "Kitchen Garden": "Vườn Rau", "Drying Rack": "Giàn Phơi",
	"Carved Posts": "Cột Chạm", "Lantern Stand": "Giá Đèn", "Banner": "Cờ Phướn",
	"Coopered Barrels": "Thùng Gỗ Đóng Đai",
	# The one-time build-menu hint + each decoration's unlock flavour
	("Press R to turn a building or decoration as you place it. 'Lay Paths' and the craft "
		+ "decorations are pure looks — they make the town yours without changing its warmth."):
		"Nhấn R để xoay một công trình hoặc vật trang trí khi đang đặt. 'Lát Đường' và các vật "
		+ "trang trí theo nghề thuần để nhìn — chúng khiến ngôi làng là của riêng ngươi mà không đổi hơi ấm.",
	"Rowan scatters seed along the path — the first colour this ground has held in a long age.":
		"Rowan rắc hạt dọc lối đi — sắc màu đầu tiên mảnh đất này giữ được sau bao thời đại dài.",
	"A kitchen garden by the hearth. Rowan plants what a village eats between the harvests.":
		"Một vườn rau bên lò sưởi. Rowan trồng thứ cả làng ăn giữa những mùa gặt.",
	"Cut reeds racked to dry — thatch, mats, winter fodder. Nothing a tended field grows is wasted.":
		"Lau sậy cắt về phơi trên giàn — lợp mái, đan chiếu, cỏ khô mùa đông. Chẳng gì từ ruộng được chăm bón bị phí.",
	"Malin shows the others how to raise a carved post — a boundary you chose, not one the cold drew.":
		"Malin chỉ mọi người dựng một cột chạm — ranh giới do ngươi chọn, chẳng phải do cái lạnh vạch ra.",
	"Bex sets an iron stand for a lantern. Light you can carry, and light you can leave standing.":
		"Bex dựng một giá sắt để treo đèn. Ánh sáng ngươi mang theo được, và ánh sáng ngươi để lại đứng đó.",
	"Someone hangs a banner over the square. A place worth marking is a place worth staying.":
		"Ai đó treo một lá cờ trên quảng trường. Nơi đáng để đánh dấu là nơi đáng để ở lại.",
	"Barrels lined up by the commons — the kind of thing a village bothers to make once there are hands enough to spare for it.":
		"Những thùng xếp hàng bên khu chung — thứ mà một ngôi làng mới chịu bỏ công làm khi đã có đủ người rảnh tay lo cho nó.",

	# --- Living settlement: population (VILLAGE_DESIGN P4/P5) ---
	"settler": "người định cư",
	"Residents  %d / %d": "Cư dân  %d / %d",
	"Greet the settler  [E]": "Chào người định cư  [E]",
	"A wanderer, drawn by the warmth, settles in.  (%d residents)":
		"Một lữ khách, bị hơi ấm thu hút, đến định cư.  (%d cư dân)",
	"I followed the light through the frost. It's warm here… I'll stay.":
		"Tôi lần theo ánh sáng qua giá băng. Nơi này ấm áp… tôi sẽ ở lại.",
	"Give me a task and I'll earn my place by the fire.":
		"Giao cho tôi việc gì đó, tôi sẽ xứng đáng có chỗ bên bếp lửa.",
	"They said the ember-bearer walks again. I had to feel the warmth myself.":
		"Người ta bảo người-giữ-lửa lại xuất hiện. Tôi phải tự mình cảm nhận hơi ấm.",
	"A roof, a hearth, a full larder — I'd near forgotten what a home was.":
		"Một mái nhà, một lò sưởi, một kho đầy — tôi gần như đã quên mái ấm là gì.",

	# --- Reactive Ember lines at milestones (CRITIQUE A5) + Codex read-reward (A6) ---
	"new": "mới",
	"You dwell on the memory — the knowing warms the world.  +%d%%":
		"Ngươi ngẫm về ký ức — sự thấu hiểu sưởi ấm thế giới.  +%d%%",
	"One roof raised against the dark. The cold has somewhere to lose to now.":
		"Một mái nhà dựng lên chống lại bóng tối. Giờ cái lạnh đã có nơi để lùi bước.",
	"The frost draws back a step. You feel it too — the world exhaling.":
		"Sương giá lùi một bước. Ngươi cũng cảm nhận được — thế giới đang thở ra.",
	"Halfway to the old warmth. The world is remembering how to be alive.":
		"Đã nửa đường về hơi ấm xưa. Thế giới đang nhớ lại cách sống.",
	"So close now. My light strains upward, toward the surface and the sun.":
		"Gần lắm rồi. Ánh sáng của ta vươn lên, hướng về mặt đất và mặt trời.",

	# --- Ruins story fragments (CRITIQUE A3) ---
	"Examine  [E]": "Xem xét  [E]", "You find…": "Ngươi tìm thấy…",
	"a child's mitten frozen to a doorstep. Whoever knocked never got an answer.":
		"một chiếc găng trẻ con đóng băng nơi bậc cửa. Người gõ cửa chẳng bao giờ được đáp lời.",
	"charcoal tally-marks on a wall — days without sun. They stop at forty-one.":
		"những vạch than trên tường — số ngày không mặt trời. Chúng dừng ở bốn mươi mốt.",
	"a hearth swept clean and laid with kindling, waiting for a spark that never came.":
		"một lò sưởi quét sạch, xếp sẵn củi mồi, chờ một tia lửa chẳng bao giờ đến.",
	"a courier frozen mid-stride, satchel still full of letters no one will read.":
		"một người đưa tin đóng băng giữa bước chân, túi vẫn đầy thư chẳng ai đọc.",
	"a loom with the shuttle still in it, the thread snapped where a hand let go.":
		"một khung cửi thoi còn nguyên, sợi chỉ đứt nơi một bàn tay buông ra.",
	"seed jars labelled in a careful hand, scraped empty to the last grain.":
		"những hũ hạt giống ghi nhãn nắn nót, vét sạch đến hạt cuối cùng.",
	"a mural of the sun, painted over and over — each layer dimmer than the last.":
		"một bức bích họa mặt trời, vẽ đi vẽ lại — mỗi lớp mờ hơn lớp trước.",
	"a ledger: pages of grain, then of firewood, then only of names.":
		"một cuốn sổ: trang ghi lương thực, rồi củi, rồi chỉ còn những cái tên.",
	"two chairs drawn close to a cold grate. Whoever sat there stayed to the end.":
		"hai chiếc ghế kéo sát bên vỉ lò lạnh. Ai ngồi đó đã ở lại đến phút cuối.",
	"a workshop of half-made tools — someone still believed in a tomorrow to finish them.":
		"một xưởng đầy dụng cụ dở dang — ai đó vẫn tin có ngày mai để hoàn thành.",
	"a cradle rocked to a stop, a lullaby scratched into the headboard.":
		"một chiếc nôi đã ngừng đưa, một khúc ru khắc vội trên thành giường.",
	"boot-prints in old ash, all leading one way: toward the deep, away from the cold.":
		"những dấu giày trên tro cũ, đều hướng một phía: xuống sâu, tránh xa cái lạnh.",
	"Chamber cleared!": "Đã dọn sạch phòng!",
	"The hearth warms you  (+3)": "Lò sưởi sưởi ấm ngươi  (+3)",
	"The ruin is conquered!": "Tàn tích đã bị chinh phục!",
	"Clearing expanded — more land to build on!": "Đã mở rộng khoảng trống — thêm đất để xây!",
	"The clearing is already vast": "Khoảng trống đã rộng lắm rồi",
	"Not enough materials to expand": "Không đủ vật liệu để mở rộng",
	"Not enough materials": "Không đủ vật liệu",
	"You fell in the dark...": "Ngươi đã gục ngã trong bóng tối...",
	"No active run — descend first": "Chưa có lượt khám phá — hãy xuống hầm trước",
	"The village provides:  ": "Ngôi làng ban tặng:  ",
	"DESCENT  %d": "LƯỢT XUỐNG  %d", "CHAMBER  %d": "PHÒNG  %d",
	"Metallurgy +%d%% dmg": "Luyện kim +%d%% ST", "Shelter +%d HP": "Mái ấm +%d HP",
	"%d Provisions": "%d khẩu phần",
	"Quest done!": "Xong nhiệm vụ!", "Quest complete: %s": "Hoàn thành nhiệm vụ: %s",

	# --- Banners ---
	"Attunement: %s": "Cộng hưởng: %s", "Supplies recovered": "Đã thu hồi tiếp tế",
	"+2 iron  ·  +2 stone": "+2 sắt  ·  +2 đá",

	# --- Interaction prompts ---
	"Hammer  [E]  (%d%%)": "Đóng  [E]  (%d%%)",
	"Plant seed  [E]": "Gieo hạt  [E]", "Harvest  [E]": "Thu hoạch  [E]", "Growing...": "Đang lớn...",
	"Descend into the ruins  [E]": "Xuống tàn tích  [E]",
	"Free %s  [E]": "Giải cứu %s  [E]",
	"Speak to the %s  [E]": "Nói chuyện với %s  [E]",
	"Turn in “%s”  [E]": "Nộp “%s”  [E]",
	"Thank the %s  [E]": "Cảm ơn %s  [E]",
	"%s: “%s”": "%s: “%s”",

	# --- Exit-gate previews (label / hint) ---
	"Treasure": "Kho báu", "a loot hoard": "một kho chiến lợi phẩm",
	"Rescue": "Giải cứu", "%s waits": "%s đang chờ",
	"Hearth": "Lò sưởi", "rest & recover": "nghỉ & hồi phục",
	"The Warden": "Kẻ Canh Giữ", "the deep's guardian — it does not bleed": "kẻ canh giữ vực sâu — nó chẳng chảy máu",
	"Combat": "Chiến đấu", "husks & loot": "vỏ rỗng & chiến lợi phẩm",
	"Return home": "Về nhà", "bank & rebuild": "ký gửi & xây dựng",

	# --- Quests (villager) ---
	"Fill the larder": "Chất đầy kho lương",
	"Grow us a store of food — bring the larder to 6.": "Trồng cho chúng ta một kho lương — đưa kho lên 6.",
	"The larder's full. We'll not go hungry now.": "Kho lương đã đầy. Giờ ta sẽ không đói nữa.",
	"Stoke the forge": "Nhóm lò rèn",
	"Haul me 5 iron from the ruins and I'll get the forge roaring.":
		"Mang cho ta 5 sắt từ tàn tích, ta sẽ nhóm lò rèn cháy rực.",
	"Iron enough — the forge breathes fire again.": "Đủ sắt rồi — lò rèn lại thở ra lửa.",
	"Raise the roofs": "Dựng những mái nhà",
	"A village needs walls. Raise 3 buildings and I'll frame the rest.":
		"Một ngôi làng cần tường vách. Dựng 3 công trình rồi ta lo phần còn lại.",
	"Three roofs stand. This is a home again.": "Ba mái nhà đã đứng vững. Đây lại là mái nhà.",

	# --- Build-menu card blurbs + placement banner ---
	"Shelter for a survivor. Toughens you (+Max HP) on your next descent.":
		"Chỗ trú cho một người sống sót. Ngươi bền hơn (+HP tối đa) ở lần xuống hang tới.",
	"Work iron into blades. Sharpens your strikes (+Damage) below.":
		"Rèn sắt thành đao. Đòn đánh sắc hơn (+Sát thương) khi xuống hang.",
	"Tilled soil to grow food — seeds become Provisions that heal mid-run.":
		"Đất đã cày để trồng lương — hạt giống thành Khẩu phần hồi máu giữa chừng.",
	"Workshop": "Xưởng Mộc",
	"The Carpenter's craft. Sharpens your eye (+Crit) below, and speeds every build.":
		"Nghề của Thợ Mộc. Mắt ngươi tinh hơn (+Chí mạng) khi xuống hang, và xây nhanh hơn.",
	"Carpentry +%d%% crit": "Nghề mộc +%d%% chí mạng",
	"Tend one more ring of wild land so you can build farther out.":
		"Khai hoang thêm một vòng đất hoang để xây rộng ra ngoài.",
	"Placing %s — left-click a tended tile to build   ·   Esc to cancel":
		"Đang đặt %s — nhấn chuột trái lên ô đã khai hoang để xây   ·   Esc để huỷ",

	# --- Villager commissions (repeatable errand once the quest is done) ---
	"Commission": "Uỷ thác",
	"Commission: give %d %s  [E]": "Uỷ thác: giao %d %s  [E]",
	"Commission met!": "Đã hoàn uỷ thác!",
	"Commission met — the village grows warmer.": "Đã hoàn uỷ thác — ngôi làng ấm hơn.",
	"Keep the larder full — 4 food sees us through the cold.":
		"Giữ kho lương đầy — 4 lương thực giúp ta qua mùa lạnh.",
	"The forge is always hungry — 3 iron keeps it roaring.":
		"Lò rèn luôn đói — 3 sắt giữ nó cháy rực.",
	"There's always a roof to mend — 4 wood for the repairs.":
		"Luôn có mái cần sửa — 4 gỗ để tu bổ.",

	# --- Farmer → Farm chain (VILLAGE_DESIGN P1) ---
	"Bring the Farmer %d wood & %d seeds — break the fallow ground (press E on it)":
		"Mang cho Nông Dân %d gỗ & %d hạt giống — khai phá đất hoang (nhấn E lên nó)",
	"Plant a seed on the farm — stand on it and press E":
		"Gieo một hạt xuống nông trại — đứng lên nó và nhấn E",
	"The Farmer breaks the fallow ground — the farm lives!":
		"Nông Dân khai phá đất hoang — nông trại đã sống!",
	"Break the fallow ground  (%d wood, %d seeds)  [E]":
		"Khai phá đất hoang  (%d gỗ, %d hạt giống)  [E]",
	"Fallow ground — needs %d wood, %d seeds  (you have %d, %d)":
		"Đất hoang — cần %d gỗ, %d hạt giống  (ngươi có %d, %d)",
	"The Farmer needs %d wood and %d seeds first.":
		"Nông Dân cần %d gỗ và %d hạt giống trước đã.",
	"Dig irrigation  (%d stone, %d wood)  [E]":
		"Đào kênh tưới  (%d đá, %d gỗ)  [E]",
	"Irrigation — needs %d stone, %d wood  (you have %d, %d)":
		"Kênh tưới — cần %d đá, %d gỗ  (ngươi có %d, %d)",
	"The Farmer needs %d stone and %d wood.":
		"Nông Dân cần %d đá và %d gỗ.",
	"Irrigation dug — the farm thrives, and feeds your descents.":
		"Kênh tưới đã đào — nông trại tươi tốt, và tiếp lương cho những chuyến xuống hang.",

	# --- Storage economy + village stakes (VILLAGE_DESIGN P5/P6) ---
	"Granary": "Kho Lương", "Watchtower": "Tháp Canh",
	"A storehouse. Raises how much wood, stone, iron & food you can stockpile before surplus is lost.":
		"Một nhà kho. Tăng lượng gỗ, đá, sắt & lương thực ngươi có thể tích trữ trước khi phần dư bị mất.",
	"A brazier-topped tower. Wards the village against the cold's return — blunts the cold snaps that sap its warmth.":
		"Một tháp có chậu lửa trên đỉnh. Che chắn ngôi làng khỏi cái lạnh quay lại — làm dịu những đợt rét cắt bớt hơi ấm.",
	"Your stores are brimming — surplus is being lost. Raise a Granary to stockpile more.":
		"Kho của ngươi đã đầy ắp — phần dư đang mất đi. Dựng một Kho Lương để tích trữ nhiều hơn.",
	"The watchtowers held the cold at bay.": "Những tháp canh đã chặn được cái lạnh.",
	"A cold snap struck — the watchtowers softened it to −%d%% warmth.":
		"Một đợt rét ập tới — các tháp canh làm dịu chỉ còn −%d%% hơi ấm.",
	"A cold snap struck the village — warmth −%d%%.":
		"Một đợt rét ập vào ngôi làng — hơi ấm −%d%%.",

	# --- Win screen (CRITIQUE B4/A1) ---
	"THE WORLD IS REKINDLED": "THẾ GIỚI ĐÃ HỒI SINH",
	"The long dark breaks. Warmth climbs back into the world — and it was you who carried it.":
		"Đêm dài tan vỡ. Hơi ấm trở lại thế gian — và chính ngươi đã mang nó về.",
	"Rest now, ember-bearer. What you remembered, and rebuilt, will outlast us both.":
		"Hãy nghỉ ngơi, kẻ giữ lửa. Những gì ngươi nhớ và dựng lại sẽ trường tồn hơn cả hai ta.",
	"Runs survived": "Lượt sống sót", "Rescued": "Đã cứu", "Buildings": "Công trình",
	"Warmth": "Hơi ấm",
	"Keep tending your village  ▸": "Tiếp tục chăm lo ngôi làng  ▸",
	# Post-win destination (CRITIQUE N4): endless deep ruins + re-readable epilogue + title seal.
	"The deep ruins lie open — descend to see how far the dark still goes.":
		"Tàn tích sâu đã mở — hãy xuống để xem bóng tối còn kéo dài đến đâu.",
	"Deepest reached: %d chambers.": "Sâu nhất đã tới: %d phòng.",
	"The Ember's Epilogue": "Lời Kết Của Tàn Lửa",
	"The world you rekindled": "Thế giới ngươi đã hồi sinh",
	"Deepest ruin: %d chambers": "Tàn tích sâu nhất: %d phòng",

	# --- Save legibility (CRITIQUE N5): autosave cue + Continue context ---
	"Progress saved": "Đã lưu tiến trình",
	"Not yet descended": "Chưa xuống hầm", "Descent %d": "Lượt xuống %d",
	"%d rescued": "đã cứu %d", "%d%% warm": "ấm %d%%",
	"saved just now": "vừa mới lưu",
	"saved %d min ago": "đã lưu %d phút trước",
	"saved %d hr ago": "đã lưu %d giờ trước",
	"saved %d days ago": "đã lưu %d ngày trước",

	# --- Title screen + pause menu (CRITIQUE B1) ---
	"Carry the last ember home.": "Mang tàn lửa cuối cùng trở về.",
	"New Game": "Chơi Mới", "Continue": "Tiếp Tục", "Quit": "Thoát",
	"PAUSED": "TẠM DỪNG", "Resume": "Tiếp tục", "Save Game": "Lưu Game",
	"Quit to Title": "Về Màn Hình Chính", "Game saved.": "Đã lưu game.",

	# --- Confirmation dialogs (CRITIQUE N1/N2) + player-paced summary (B7) ---
	"Cancel": "Hủy", "Continue  ▸": "Tiếp tục  ▸",
	"Start a new game?": "Bắt đầu game mới?",
	"This erases your saved village, survivors, and warmth — it cannot be undone.":
		"Việc này xóa ngôi làng, người sống sót và hơi ấm đã lưu — không thể hoàn tác.",
	"Erase & start": "Xóa & bắt đầu",
	"Abandon this run?": "Bỏ dở lượt này?",
	"You are still in the ruins. Quitting now forfeits this descent and every material you haven't banked.":
		"Ngươi vẫn còn trong tàn tích. Thoát bây giờ sẽ mất lượt xuống này và mọi vật liệu chưa ký gửi.",
	"Abandon run": "Bỏ dở lượt",

	# --- Settings screen (CRITIQUE B6) ---
	"Settings": "Thiết Lập", "SETTINGS": "THIẾT LẬP", "Volume": "Âm lượng",
	"Mute": "Tắt tiếng", "High-contrast telegraphs": "Báo đòn tương phản cao",
	"Colorblind cues": "Màu cho người mù màu", "On": "Bật", "Off": "Tắt",
	"Language": "Ngôn ngữ", "Back": "Quay lại",

	# --- Building upgrades (VILLAGE_DESIGN P2) ---
	"Upgrade %s  Lv %d→%d  (%s)  [E]": "Nâng cấp %s  Cấp %d→%d  (%s)  [E]",
	"%s upgraded to Lv %d!": "%s đã nâng lên Cấp %d!",

	# --- Named survivors (CRITIQUE A2) ---
	"Free %s the %s  [E]": "Giải cứu %s — %s  [E]",
	"%s the %s joins you": "%s — %s gia nhập cùng ngươi",
	"I know soil and season — give me ground, and I'll feed us all.":
		"Ta hiểu đất và mùa vụ — cho ta mảnh đất, ta sẽ nuôi sống tất cả.",
	"Iron sings if you know the heat. And I know the heat.":
		"Sắt sẽ hát nếu ngươi hiểu lửa. Và ta thì hiểu lửa.",
	"Show me a ruin, and I'll show you where the walls belong.":
		"Chỉ ta một phế tích, ta sẽ chỉ ngươi nơi những bức tường thuộc về.",

	# --- Attunements (name / desc / element) ---
	"Bramble Ward": "Hộ Thân Gai", "Ember Fang": "Nanh Than Hồng", "Gale Step": "Bước Gió",
	"+2 Max HP": "+2 HP tối đa", "+25% Damage": "+25% Sát thương", "+25% Speed": "+25% Tốc độ",
	"Flora": "Thực Vật", "Thermal": "Nhiệt", "Wind": "Gió",

	# --- Boons (name / desc) ---
	"Fleetfoot": "Chân Nhanh", "Bramble Heart": "Tim Gai", "Keen Eye": "Mắt Tinh",
	"Second Wind": "Hơi Sức Thứ Hai", "Hearth's Gift": "Quà Của Lò Sưởi",
	"+20% damage": "+20% sát thương", "+12% move speed": "+12% tốc độ",
	"+2 Max HP, mend 2": "+2 HP tối đa, hồi 2", "+7% crit chance": "+7% tỉ lệ chí mạng",
	"Mend 3 HP now": "Hồi 3 HP ngay", "+1 Max HP, +8% dmg": "+1 HP tối đa, +8% ST",

	# --- Codex (Lore) — titles / eras / one paragraph each ---
	"Civilisation is Carried": "Văn Minh Được Truyền Lại",
	"Agriculture": "Nông Nghiệp", "Metallurgy": "Luyện Kim", "Durable Construction": "Kiến Trúc Bền Vững",
	"the premise": "tiền đề", "~10,000 BCE": "~10.000 TCN", "~5,000 BCE": "~5.000 TCN", "~9,000 BCE": "~9.000 TCN",
	"Agriculture. Store a surplus and a village can feed those who don't farm — the first free hands that ever built anything else.":
		"Nông nghiệp. Tích trữ phần dư thì một ngôi làng có thể nuôi cả những người không làm nông — những đôi tay rảnh rỗi đầu tiên từng dựng nên mọi thứ khác.",
	"Metallurgy. Out-heat the stone and it gives up its metal. It is the same fire I carry — knowledge is only heat, aimed.":
		"Luyện kim. Nung đá đủ nóng thì nó nhả ra kim loại. Vẫn là ngọn lửa ta mang — tri thức chỉ là hơi nóng, được nhắm đúng chỗ.",
	"Construction. A roof that outlasts its builder is stored labour. Raise one, and people can stop merely surviving.":
		"Kiến trúc. Một mái nhà sống lâu hơn kẻ dựng nên nó là công sức được cất giữ. Dựng một cái, người ta thôi chỉ còn tồn tại cho qua ngày.",
	# The four long Codex facts:
	("Civilisation is not stone or steel — it is knowledge, remembered and "
		+ "handed on. Every survivor you carry home remembers how something was "
		+ "made; every building re-enacts why it mattered. To rekindle a dead world "
		+ "is to remember it."):
		"Văn minh không phải đá hay thép — nó là tri thức, được ghi nhớ và truyền lại. "
		+ "Mỗi người sống sót ngươi mang về nhớ cách một thứ được tạo ra; mỗi công trình "
		+ "tái hiện vì sao nó quan trọng. Nhóm lại một thế giới đã chết là nhớ lại nó.",
	("As the last Ice Age ended, people in at least seven regions — the "
		+ "Fertile Crescent, China, Mesoamerica, the Andes, New Guinea among them — "
		+ "independently began domesticating plants and animals. A stored surplus "
		+ "meant a village could feed people who did not farm: potters, smiths, "
		+ "scribes. Cities, writing, states, even new diseases all rest on that "
		+ "grain. (Liberty: one tended plot stands in for a millennia-long, "
		+ "many-crop revolution.)"):
		"Khi Kỷ Băng Hà cuối cùng kết thúc, con người ở ít nhất bảy vùng — Lưỡi Liềm Phì "
		+ "Nhiêu, Trung Hoa, Trung Mỹ, dãy Andes, New Guinea trong số đó — độc lập bắt đầu "
		+ "thuần hóa cây trồng và vật nuôi. Phần dư tích trữ nghĩa là một ngôi làng có thể "
		+ "nuôi những người không làm nông: thợ gốm, thợ rèn, người chép sử. Thành thị, chữ "
		+ "viết, nhà nước, cả những dịch bệnh mới đều dựa trên hạt lương ấy. (Phóng tác: một "
		+ "luống đất tượng trưng cho cuộc cách mạng nhiều loài cây kéo dài hàng thiên niên kỷ.)",
	("To win metal from stone you must out-heat the rock. Smelting copper "
		+ "from ore appeared ~7,000 years ago; a tenth part tin gave bronze, harder "
		+ "than either parent. Iron came later — a poorer metal at first, but its "
		+ "ore is everywhere, so ploughs and tools reached ordinary hands. The trick "
		+ "was always the fire: charcoal and forced air (bellows) reach the "
		+ "~1,150 °C that frees copper, hotter still for iron. Metallurgy is applied "
		+ "thermodynamics — the same heat you carry."):
		"Muốn lấy kim loại từ đá, ngươi phải nung đá nóng hơn chính nó. Nấu đồng từ quặng "
		+ "xuất hiện ~7.000 năm trước; một phần mười thiếc cho ra đồng thau, cứng hơn cả hai "
		+ "kim loại gốc. Sắt đến sau — thoạt đầu là kim loại kém hơn, nhưng quặng của nó có "
		+ "ở khắp nơi, nên cày và công cụ đến được tay người thường. Bí quyết luôn là lửa: "
		+ "than củi và không khí thổi cưỡng bức (bễ) đạt tới ~1.150 °C giải phóng đồng, còn "
		+ "nóng hơn nữa cho sắt. Luyện kim là nhiệt động lực học ứng dụng — cùng hơi nóng ngươi mang.",
	("Durable building is what let people stop moving. Mudbrick and rammed "
		+ "earth are ~10,000 years old; the load-bearing arch — which turns a roof's "
		+ "downward weight into a sideways thrust its supports can hold — was "
		+ "mastered by the Romans and spanned aqueducts and domes that still stand. "
		+ "A permanent roof stores labour the way a granary stores grain: build "
		+ "once, shelter for generations. (Liberty: a timber cabin stands in for the "
		+ "whole art of durable construction.)"):
		"Xây dựng bền vững là thứ cho phép con người thôi di cư. Gạch bùn và đất nện có tuổi "
		+ "~10.000 năm; vòm chịu lực — thứ biến sức nặng dồn xuống của mái thành lực đẩy ngang "
		+ "mà các trụ đỡ chịu được — được người La Mã làm chủ, bắc qua những cầu dẫn nước và "
		+ "mái vòm còn đứng đến nay. Một mái nhà vĩnh cửu cất giữ công sức như kho thóc cất giữ "
		+ "hạt: xây một lần, che chở nhiều đời. (Phóng tác: một lều gỗ tượng trưng cho cả nghệ "
		+ "thuật xây dựng bền vững.)",
	"Undiscovered — rescue this craft's survivor, or raise their building.":
		"Chưa khám phá — giải cứu người mang nghề này, hoặc dựng công trình của họ.",

	# --- The antagonist: the cold's cause + the Warden's face (CRITIQUE A-antag) ---
	"The dark was no curse — only everything the living stopped remembering. Warmth is carried, hand to hand, or it is lost.":
		"Bóng tối chẳng phải lời nguyền — chỉ là tất cả những gì người sống thôi ghi nhớ. Hơi ấm được truyền tay, người này sang người khác, hoặc mất đi.",
	"The Long Dark": "Đêm Trường Tăm Tối",
	"the cold": "cái lạnh", "the deep": "vực sâu",
	# The Ember's coda the first time the Warden gutters out (dungeon.gd, once ever).
	("It doesn't fall — it gutters, and goes out. No beast: only the cold wearing a shape, "
		+ "holding a place it feared you'd warm. It has no more reason to stand."):
		"Nó không gục xuống — nó leo lét, rồi tắt ngấm. Chẳng phải quái vật: chỉ là cái lạnh khoác lấy "
		+ "một hình hài, giữ một nơi mà nó sợ ngươi sẽ sưởi ấm. Nó chẳng còn lý do gì để đứng canh nữa.",
	("No comet fell; no god turned away. The world went cold the way any "
		+ "fire goes cold — one untended moment at a time. A craft left untaught. A "
		+ "hearth left unlit. Warmth is never kept by wishing it; it is carried, hand "
		+ "to hand, or it is lost. The Long Dark is only the sum of everything the "
		+ "living stopped remembering — which is why it is the one enemy that "
		+ "remembering can undo."):
		"Không sao chổi nào rơi; chẳng vị thần nào ngoảnh mặt. Thế giới hóa lạnh theo cách "
		+ "bất kỳ ngọn lửa nào tàn đi — từng khoảnh khắc không ai chăm nom. Một nghề không "
		+ "được truyền dạy. Một lò sưởi không ai nhóm lại. Hơi ấm chẳng bao giờ được giữ bằng "
		+ "ước muốn; nó được truyền tay, người này sang người khác, hoặc mất đi. Đêm Trường "
		+ "Tăm Tối chỉ là tổng của tất cả những gì người sống thôi ghi nhớ — và cũng vì thế, "
		+ "nó là kẻ thù duy nhất mà sự ghi nhớ có thể xóa bỏ.",
	("At the oldest ruin, where the first hearth was let die, the cold learned "
		+ "a shape and set it to guard the place. The Warden is no beast — strike it "
		+ "and it does not bleed; it gutters and goes out, like a flame starved of "
		+ "air. It stands watch over the deep because the dark still fears what was "
		+ "kindled there once, and might be kindled again."):
		"Nơi phế tích cổ xưa nhất, chỗ lò sưởi đầu tiên bị bỏ cho lụi tắt, cái lạnh học lấy "
		+ "một hình hài và đặt nó canh giữ nơi ấy. Kẻ Canh Giữ không phải quái vật — đâm nó, "
		+ "nó chẳng chảy máu; nó leo lét rồi tắt ngấm, như ngọn lửa thiếu dưỡng khí. Nó canh "
		+ "gác vực sâu bởi bóng tối vẫn sợ thứ từng được nhóm lên nơi đó, và có thể được nhóm "
		+ "lại lần nữa.",

	# --- The Ember's per-succession-stage voice (STORY_DESIGN §3): one line per seral stage ---
	("Bare mineral rock, scoured to nothing. Nothing has grown here — not yet, not ever. "
		+ "But nothing grows anywhere until something dares to be first."):
		"Đá trơ, bị bào mòn đến không còn gì. Nơi đây chưa từng có gì mọc lên — chưa bao giờ. "
		+ "Nhưng chẳng nơi nào có sự sống cho tới khi một thứ dám làm kẻ đầu tiên.",
	"There — lichen on the stone, the boldest life there is. It asks for almost nothing, and it begins everything.":
		"Kìa — địa y trên đá, sự sống gan dạ nhất trên đời. Nó cần gần như chẳng gì, mà lại khởi đầu mọi thứ.",
	"Green, and soft enough to bruise. Fragile things are how a world tells you it has stopped dying.":
		"Xanh mướt, và mềm đến độ chạm là bầm. Những thứ mong manh là cách một thế giới báo rằng nó đã thôi lụi tàn.",
	"It tangles now, reaches, competes. Crowding is a kind of confidence. Let it fight for the light.":
		"Giờ nó đan xen, vươn ra, tranh giành. Chen chúc cũng là một dạng tự tin. Cứ để nó giành lấy ánh sáng.",
	("Look up. It closes over us like a held breath let go. This is what patience becomes: "
		+ "shade for something that comes after."):
		"Ngước lên xem. Nó khép lại trên đầu ta như một hơi thở nén được buông ra. Đây là thành quả của "
		+ "sự kiên nhẫn: bóng mát cho những gì đến sau.",

	# --- The rescued, as people (VISION): the character sheet's roster of who they are ---
	"The Rescued": "Những Người Được Cứu",
	"%s the %s": "%s — %s",
	("Rowan kept the seed-vault through the long winters. He planted the last handful "
		+ "rather than eat it — that is the whole of him."):
		"Rowan giữ kho hạt giống qua những mùa đông dài. Nắm hạt cuối cùng, anh đem gieo chứ "
		+ "không ăn — con người anh chỉ có vậy.",
	("Bex learned the forge from her mother, who learned it from hers. She reads a fire's "
		+ "colour the way you read a face."):
		"Bex học nghề rèn từ mẹ, người học lại từ bà. Cô đọc màu ngọn lửa như cách ta đọc một gương mặt.",
	("Malin raised half this village the first time. She still walks the old foundations "
		+ "at night, naming rooms that aren't there yet."):
		"Malin từng dựng nửa ngôi làng này lần đầu tiên. Đêm đêm cô vẫn đi dọc những nền móng cũ, "
		+ "gọi tên những căn phòng chưa hề có.",

	# --- HUD: headers & static labels ---
	"WARMTH": "HƠI ẤM", "SOIL": "ĐẤT MÙN", "CONTROLS": "ĐIỀU KHIỂN",
	"THE KINDLED": "KẺ NHÓM LỬA", "Attunements": "Cộng Hưởng", "Boons": "Phúc Lành",
	"—  none yet": "—  chưa có",
	"CHOOSE A BLOOM": "CHỌN MỘT NHÁNH NỞ", "Pick one — click a card": "Chọn một — nhấp vào một lá bài",
	"THE EMBER'S MEMORIES": "KÝ ỨC CỦA TÀN LỬA",
	"RUN BANKED": "ĐÃ KÝ GỬI LƯỢT", "YOU FELL IN THE DARK": "NGƯƠI ĐÃ GỤC TRONG BÓNG TỐI",
	"BUILD   (Esc to cancel)": "XÂY DỰNG   (Esc để huỷ)",
	"CLEARED": "ĐÃ DỌN", "nothing": "không có gì",
	"[C] close    ·    [K] Codex": "[C] đóng    ·    [K] Sách Tri Thức", "[K] close": "[K] đóng",

	# --- HUD: controls card ---
	"WASD  —  move": "WASD  —  di chuyển", "Left mouse  —  attack": "Chuột trái  —  tấn công",
	"Right mouse  —  guard": "Chuột phải  —  đỡ", "Space  —  dash": "Space  —  lướt",
	"E  —  interact    B  —  build": "E  —  tương tác    B  —  xây",
	"Tab  —  run map    C  —  character": "Tab  —  bản đồ    C  —  nhân vật",
	"K  —  codex (recovered knowledge)": "K  —  sách tri thức", "L  —  language (English / Tiếng Việt)": "L  —  ngôn ngữ (English / Tiếng Việt)",

	# --- HUD: format templates (interpolated after translation) ---
	"RUIN  ·  DEPTH %d": "TÀN TÍCH  ·  TẦNG %d", "RUIN  MAP": "BẢN ĐỒ TÀN TÍCH",
	"loot: empty": "túi đồ: trống", "loot: %s": "túi đồ: %s",
	"Succession   %s  (stage %d)": "Diễn thế   %s  (bậc %d)",
	"Soil head-start   stage %d": "Khởi đầu từ đất mùn   bậc %d",
	"Max HP        %d": "HP tối đa      %d",
	"Damage        %d  (x%.2f)": "Sát thương    %d  (x%.2f)",
	"Move Speed    %d%%": "Tốc độ        %d%%",
	"Crit Chance   %d%%": "Chí mạng      %d%%",
	"Provisions   x%d  (auto-heal when hurt)": "Khẩu phần   x%d  (tự hồi khi bị thương)",
	"• %s  (%s) — %s": "• %s  (%s) — %s",
	"Recovered knowledge   %d / %d": "Tri thức đã thu hồi   %d / %d",
	"Chambers cleared     %d": "Số phòng đã dọn      %d",
	"Husks felled         %d": "Số vỏ rỗng hạ được   %d",
	"Rescued: ": "Đã cứu: ",
	"Kindle gathered     +%d": "Nhóm lửa thu được   +%d",
	"Blooms              %d": "Số nhánh nở         %d",
	"Loot banked: ": "Đã ký gửi: ", "Salvaged: ": "Cứu vớt được: ", "Lost to the dark: ": "Mất vào bóng tối: ",
	"%d %s": "%d %s",

	# --- Stage names (succession) ---
	"ASH": "TRO", "PIONEER": "TIÊN PHONG", "HERB": "THẢO", "THICKET": "BỤI RẬM", "CANOPY": "TÁN RỪNG",

	# --- Language toggle feedback ---
	"Language: English": "Ngôn ngữ: English", "Ngôn ngữ: Tiếng Việt": "Ngôn ngữ: Tiếng Việt",
}

# Translate a source string (English) for the active language. Empty / unknown
# strings pass through unchanged.
static func t(s: String) -> String:
	if s == "" or GameState.lang != "vi":
		return s
	return String(VI.get(s, s))
