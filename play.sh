#!/usr/bin/env bash
# Mở CHIẾN TRANH KHUẨN LẠC.
#   ./play.sh          chơi game
#   ./play.sh test     chạy test không cần cửa sổ (smoke + mọi mục tiêu)
#   ./play.sh balance  đo thế cân bằng của lưới trên mọi thế cờ
#   ./play.sh tune     các phép đo dùng để chọn số: tốc độ, hoa văn, mở màn
#   ./play.sh shot     chụp ảnh ra godot/_shot-*.png
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_godot() {
	# GODOT do người dùng đặt thì phải dùng đúng cái đó, sai thì báo lỗi chứ
	# không lặng lẽ chạy bản khác.
	if [ -n "${GODOT:-}" ]; then
		command -v "$GODOT" 2>/dev/null && return
		echo "GODOT=$GODOT không chạy được." >&2
		exit 1
	fi
	for c in "$HOME/.local/bin/godot" godot godot4; do
		command -v "$c" >/dev/null 2>&1 && { command -v "$c"; return; }
	done
	cat >&2 <<-'EOF'
	Không tìm thấy Godot. Cài bản 4.x rồi thử lại:

	  curl -sL -o /tmp/godot.zip \
	    https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_linux.x86_64.zip
	  unzip -o /tmp/godot.zip -d /tmp
	  mv /tmp/Godot_v4.7.1-stable_linux.x86_64 ~/.local/bin/godot
	  chmod +x ~/.local/bin/godot

	Hoặc trỏ thẳng vào file có sẵn:  GODOT=/duong/dan/godot ./play.sh
	EOF
	exit 1
}

run_headless() {
	local godot="$1"; shift
	for t in "$@"; do
		echo "════ tests/$t.gd ════"
		"$godot" --headless --path "$here/godot" --script "tests/$t.gd"
	done
}

case "${1:-game}" in
test)
	run_headless "$(find_godot)" smoke goals
	;;
balance)
	run_headless "$(find_godot)" balance
	;;
tune)
	# Ba phép đo đứng sau ba con số dễ chỉnh sai nhất: cạnh lưới (bench), độ linh
	# động cho ra hoa văn (diag_pattern), và đoạn quá độ 60 giây đầu (diag_opening).
	run_headless "$(find_godot)" bench diag_pattern diag_opening diag_stages
	;;
render)
	# Cần cửa sổ thật. Tự tắt vsync bên trong, xem chú thích đầu tests/diag_render.gd.
	"$(find_godot)" --path "$here/godot" --script tests/diag_render.gd
	;;
shot)
	"$(find_godot)" --path "$here/godot" --script tests/capture.gd
	echo "Ảnh nằm ở $here/godot/_shot-*.png"
	;;
game)
	exec "$(find_godot)" --path "$here/godot"
	;;
*)
	echo "Dùng: ./play.sh [game|test|balance|tune|render|shot]" >&2
	exit 2
	;;
esac
