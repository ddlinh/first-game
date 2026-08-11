#!/usr/bin/env bash
# Launch REKINDLED. Runs the Godot project in ./godot with a real display.
#
#   ./play.sh            play the game
#   ./play.sh --import   just (re)scan assets/classes, then exit
#   ./play.sh capture    run the screenshot harness (tools/capture.tscn)
set -euo pipefail

# Project lives in the godot/ subfolder next to this script.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT/godot"

# Find a Godot 4 binary (PATH, then the usual local spot).
GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
	for c in godot godot4 "$HOME/.local/bin/godot"; do
		if command -v "$c" >/dev/null 2>&1; then GODOT="$c"; break; fi
	done
fi
if [[ -z "$GODOT" ]]; then
	echo "Godot 4 not found. Install it or set GODOT=/path/to/godot." >&2
	exit 1
fi

# A display is required to render; default to :0 if the session didn't export one.
export DISPLAY="${DISPLAY:-:0}"

case "${1:-play}" in
	--import|import)
		exec "$GODOT" --headless --path "$PROJECT" --import
		;;
	capture)
		exec "$GODOT" --path "$PROJECT" res://tools/capture.tscn --rendering-driver opengl3
		;;
	autoplay|demo)
		# Hands-off bot that plays a full loop so you can watch the game's progress.
		# Speed it up with e.g. `./play.sh autoplay --fast=4` (default 3x).
		exec "$GODOT" --path "$PROJECT" res://tools/autoplay.tscn --rendering-driver opengl3 -- "${@:2}"
		;;
	*)
		exec "$GODOT" --path "$PROJECT" --rendering-driver opengl3 "$@"
		;;
esac
