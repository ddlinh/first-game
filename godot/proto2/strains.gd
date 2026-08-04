extends RefCounted

## Danh sách các chủng CÓ THẬT, mỗi chủng gắn một tổ hợp tham số (chủng × môi trường)
## cho set_environment() + lời giới thiệu để hiện "thẻ chủng" và điền "sổ tay".
## Không class_name — nạp bằng preload.
##
## Đặc trưng bám sinh học thật; các số mot/hard/rich là quy đổi để ra đúng KIỂU mọc.

const LIST := [
	{
		"name": "E. coli",
		"latin": "Escherichia coli",
		"trait": "Bơi khoẻ, tìm ăn giỏi — lan nhanh nhưng làm NHOÈ hình.",
		"note": "Mô hình vi sinh kinh điển. Có tiên mao, bơi theo hoá hướng động (run-and-tumble). Thạch thường.",
		"mot": 1.0, "hard": 0.4, "rich": 1.0,
	},
	{
		"name": "Staphylococcus",
		"latin": "Staphylococcus aureus",
		"trait": "KHÔNG di động — mọc tại chỗ, GIỮ HÌNH sắc, dễ kết biofilm.",
		"note": "Cầu khuẩn không tiên mao. Biofilm trên ống thông/thiết bị y tế là vấn đề lâm sàng lớn.",
		"mot": 0.0, "hard": 1.0, "rich": 1.0,
	},
	{
		"name": "Proteus",
		"latin": "Proteus mirabilis",
		"trait": "BẦY ĐÀN — cả đàn trườn thành vòng đồng tâm, tràn khắp đĩa.",
		"note": "Swarming nổi tiếng (hiện tượng Dienes): trên thạch ẩm nó lan thành vòng bull's-eye.",
		"mot": 1.0, "hard": 0.0, "rich": 1.2,
	},
	{
		"name": "Bacillus",
		"latin": "Bacillus subtilis",
		"trait": "Thạch NGHÈO thì mọc thành NHÁNH cây (fractal). Là loài tạo BÀO TỬ.",
		"note": "Khuẩn lạc dendritic khi đói + thạch cứng (giới hạn khuếch tán). Bào tử giúp sống sót khô hạn.",
		"mot": 0.3, "hard": 1.0, "rich": 0.35,
	},
]
