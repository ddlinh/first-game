# Hướng dẫn cho Claude — dự án "Khuẩn lạc"

## Nguyên tắc quan trọng nhất: cân nhắc tính khoa học TRƯỚC khi thêm

Khi người dùng đề xuất một cơ chế/tính năng, **trước khi làm** hãy đánh giá tính đúng
đắn sinh học của nó và nói rõ:

- **CÓ THẬT** — đúng vi sinh học → làm, và tận dụng để dạy người chơi.
- **ĐƠN GIẢN HOÁ** — có thật nhưng game làm khác đi → làm, nhưng nói rõ chỗ khác.
- **SAI** — trái sự thật → **nói thẳng ngay**, giải thích vì sao, và gợi ý phương án
  đúng sinh học thay thế trước khi bắt tay.

Ưu tiên cơ chế đúng sinh học. Nếu một đề xuất trái sinh học nhưng vẫn muốn giữ vì lý
do game, phải ghi nhận nó là "sáng tạo" một cách minh bạch (xem CO-SO-KHOA-HOC.md làm
mẫu về cách phân loại và trích nguồn).

## Bối cảnh dự án

Game **city-builder cấp vi sinh** (Godot 4.7): người chơi chăm một khuẩn lạc — mỗi con
vi khuẩn là một cá thể có việc làm nhìn thấy được (cảm hứng Timberborn). Rải dinh dưỡng,
đặt công trình biofilm; môi trường quyết định ai tới (đông → phage hại; giàu → cộng
sinh lợi).

- Chạy: `./play.sh` · Test: `./play.sh check` · Ảnh: `./play.sh shot`
- Mã ở `godot/proto2/`:
  - `agent_colony.gd` — **lõi mô phỏng**, không biết gì tới màn hình, test headless được.
  - `colony_view.gd` — phần vẽ + nhập liệu + tutorial.
  - `Agents.tscn` (scene chính), `check.gd`, `shot.gd`.
- **Luôn giữ lõi tách khỏi phần vẽ** (luồng một chiều: lõi là nguồn sự thật, view chỉ
  đọc). Cơ chế mới cho vào lõi kèm một assert trong `check.gd`.

## Tài liệu
- `CO-SO-KHOA-HOC.md` — kiểm kê có thật / sáng tạo, kèm nguồn (mẫu để noi theo).
- `thiet-ke-microbiome.md` — hướng thiết kế.
