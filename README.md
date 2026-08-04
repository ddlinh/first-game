# Khuẩn lạc

Mô phỏng **city-builder cấp vi sinh** dựng bằng Godot 4: bạn không cầm từng con vi
khuẩn, mà **chăm một khuẩn lạc** — rải dinh dưỡng, đặt công trình biofilm — rồi *khuẩn
tự sống và làm việc*. Mỗi con là một **cá thể riêng có việc làm nhìn thấy được** (cảm
hứng từ Timberborn: ngắm từng "thợ" đang làm gì), và khi phage tấn công thì combat diễn
ra ngay trước mắt.

```bash
./play.sh          # chơi
./play.sh check    # test lõi mô phỏng, không cần cửa sổ
./play.sh shot     # chụp ảnh ra godot/proto2/_shot-agents-*.png
```

## Cách chơi

| | |
|---|---|
| Chuột trái | đặt công cụ đang chọn vào đĩa |
| 1 / 2 | đổi công cụ: ① rải dinh dưỡng · ② đặt công trình biofilm |
| P | thả phage (xem combat) |
| R | làm lại |
| di chuột vào một con | xem nó đang làm gì + năng lượng |

Vòng đời một con khuẩn: **kiếm ăn** (bơi về dinh dưỡng) → **ăn** → **phân đôi** (đẻ con
mới). Hết ăn thì **ngủ đông** thành bào tử. Phage gần thì **phòng thủ** (tiết độc). Đặt
công trình biofilm → khuẩn no kéo tới **xây**; xây xong thì mọi con trong vùng được
**che chở** khỏi phage.

## Bố cục mã

```
godot/proto2/
  agent_colony.gd   lõi mô phỏng — không biết gì tới màn hình, test headless được
  colony_view.gd    phần vẽ + nhập liệu, mỗi con là một cá thể
  Agents.tscn        scene chính
  check.gd           test headless (./play.sh check)
  shot.gd            chụp ảnh
```

Luồng dữ liệu một chiều: lõi là nguồn sự thật, phần vẽ chỉ đọc — nhờ vậy cân bằng đo
được headless.

## Tài liệu

- [thiet-ke-microbiome.md](thiet-ke-microbiome.md) — hướng thiết kế (đang tiến hoá).
- [CO-SO-KHOA-HOC.md](CO-SO-KHOA-HOC.md) — kiểm kê chi tiết nào có thật / sáng tạo, kèm
  nguồn khoa học (colicin, phage, biofilm, bào tử…).

> Ghi chú: dự án khởi đầu là một game khắc-chế-ba-chủng trên lưới (mô hình colicin
> E. coli). Đã chuyển hướng sang mô phỏng agent city-builder; bản lưới cũ còn trong
> lịch sử git.
