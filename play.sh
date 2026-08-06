#!/usr/bin/env bash
# Khuẩn lạc — mô phỏng agent (mỗi con khuẩn là một cá thể có việc làm).
#   ./play.sh          chơi game
#   ./play.sh check    test lõi mô phỏng, không cần cửa sổ
#   ./play.sh shot     chụp ảnh ra godot/proto2/_shot-agents-*.png
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

case "${1:-game}" in
game)
	# Bản chính (main_scene = proto2/Agents.tscn).
	exec "$(find_godot)" --path "$here/godot"
	;;
yogurt)
	# Màn YAOURT (city-builder cấp vi sinh, đích pH 4.6).
	exec "$(find_godot)" --path "$here/godot" res://proto2/Yogurt.tscn
	;;
check)
	# Test headless cho lõi mô phỏng agent, không cần cửa sổ.
	"$(find_godot)" --headless --path "$here/godot" --script proto2/check.gd
	;;
shot)
	# Cần cửa sổ thật. Chụp ảnh ra godot/proto2/_shot-agents-*.png.
	"$(find_godot)" --path "$here/godot" --script proto2/shot.gd
	;;
*)
	echo "Dùng: ./play.sh [game|yogurt|check|shot]" >&2
	exit 2
	;;
esac
