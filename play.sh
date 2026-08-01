#!/usr/bin/env bash
# Mở EMBERHOLD.
#   ./play.sh          chơi game
#   ./play.sh test     chạy toàn bộ test không cần cửa sổ
#   ./play.sh balance  đo độ khó với hai kiểu người chơi
#   ./play.sh shot     chụp ảnh màn chờ và giữa trận ra godot/_shot-*.png
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
test)
	godot="$(find_godot)"
	for t in smoke dash blast; do
		echo "════ tests/$t.gd ════"
		"$godot" --headless --path "$here/godot" --script "tests/$t.gd"
	done
	;;
balance)
	godot="$(find_godot)"
	for kind in im spam bot; do
		echo "════ độ khó với kiểu chơi: $kind ════"
		"$godot" --headless --path "$here/godot" \
			--script tests/balance.gd -- "$kind" speed=10 rounds=16
	done
	;;
shot)
	godot="$(find_godot)"
	"$godot" --path "$here/godot" --script tests/capture.gd
	echo "Ảnh nằm ở $here/godot/_shot-menu.png và _shot-game.png"
	;;
game)
	godot="$(find_godot)"
	exec "$godot" --path "$here/godot"
	;;
*)
	echo "Dùng: ./play.sh [game|test|balance|shot]" >&2
	exit 2
	;;
esac
