#!/usr/bin/env bash
#
# Rekindled — launcher.
#
#   ./play.sh              play the game
#   ./play.sh editor       open the Godot editor on the project
#   ./play.sh sheet        bake every sprite onto godot/_shot_sheet.png and quit
#   ./play.sh shots        drive the game through its states -> godot/_shot_*.png
#   ./play.sh import       rebuild the import cache / class registry only
#   ./play.sh check        parse-check every script, no window (CI-friendly)
#
# Anything after the command is passed straight through to Godot, e.g.
#   ./play.sh play --verbose
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT/godot"

die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[2m%s\033[0m\n' "$*" >&2; }

[ -f "$PROJECT/project.godot" ] || die "no Godot project at $PROJECT"

# --- Locate a Godot 4 binary ------------------------------------------------
# $GODOT wins, then the PATH, then the usual places a manual install lands.
find_godot() {
	if [ -n "${GODOT:-}" ]; then
		command -v "$GODOT" >/dev/null 2>&1 && { command -v "$GODOT"; return; }
		[ -x "$GODOT" ] && { printf '%s' "$GODOT"; return; }
		die "GODOT is set to '$GODOT' but that is not an executable"
	fi
	local c
	for c in godot godot4 Godot; do
		command -v "$c" >/dev/null 2>&1 && { command -v "$c"; return; }
	done
	for c in "$HOME"/.local/bin/godot* "$HOME"/Downloads/Godot_v4*_linux.x86_64 \
			/usr/local/bin/godot* /opt/godot*/godot*; do
		[ -x "$c" ] && { printf '%s' "$c"; return; }
	done
	die "Godot 4 not found. Install it, put it on your PATH, or run: GODOT=/path/to/godot $0"
}

GODOT_BIN="$(find_godot)"
GODOT_VER="$("$GODOT_BIN" --version 2>/dev/null | head -1)"
case "$GODOT_VER" in
	4.*) ;;
	*) die "need Godot 4.x, found '${GODOT_VER:-unknown}' at $GODOT_BIN" ;;
esac

# --- First run: build the import cache --------------------------------------
# Every entity is found through `class_name`, and that registry lives in
# .godot/global_script_class_cache.cfg — which is gitignored. Without it the
# autoloads fail to compile and the game boots to a black screen, so build it
# once here rather than making that a thing you have to know.
ensure_imported() {
	[ -f "$PROJECT/.godot/global_script_class_cache.cfg" ] && return
	info "first run: importing assets and registering script classes..."
	"$GODOT_BIN" --headless --path "$PROJECT" --import >/dev/null 2>&1 || true
}

CMD="${1:-play}"
[ $# -gt 0 ] && shift || true

case "$CMD" in
	play|run|"")
		ensure_imported
		exec "$GODOT_BIN" --path "$PROJECT" "$@"
		;;
	editor|edit)
		ensure_imported
		exec "$GODOT_BIN" --editor --path "$PROJECT" "$@"
		;;
	sheet)
		ensure_imported
		info "baking the sprite catalogue -> godot/_shot_sheet.png"
		exec "$GODOT_BIN" --path "$PROJECT" res://tools/sheet.tscn "$@"
		;;
	shots|capture)
		ensure_imported
		info "capturing gameplay states -> godot/_shot_*.png"
		exec "$GODOT_BIN" --path "$PROJECT" res://tools/capture.tscn "$@"
		;;
	import)
		exec "$GODOT_BIN" --headless --path "$PROJECT" --import "$@"
		;;
	check)
		# Parse every script without opening a window. Autoload singletons
		# (Assets/GameState/Juice) are not resolvable in --check-only, so those
		# specific "Identifier not found" lines are filtered out; anything else
		# is a real syntax or type error.
		ensure_imported
		rc=0
		for f in "$PROJECT"/scripts/*.gd "$PROJECT"/tools/*.gd; do
			[ -e "$f" ] || continue
			rel="res://${f#"$PROJECT"/}"
			out="$("$GODOT_BIN" --headless --path "$PROJECT" --check-only --script "$rel" 2>&1 \
				| grep -E "SCRIPT ERROR|Parse Error|Compile Error" \
				| grep -vE "Identifier not found: (Assets|GameState|Juice|Palette)" || true)"
			if [ -n "$out" ]; then
				printf '\033[31mFAIL\033[0m %s\n%s\n' "$(basename "$f")" "$out"
				rc=1
			else
				printf '\033[32m ok \033[0m %s\n' "$(basename "$f")"
			fi
		done
		exit $rc
		;;
	-h|--help|help)
		# Echo the header block: every comment line from line 3 up to the first
		# line of actual code, so the usage text can never drift out of sync.
		awk 'NR>2 && /^#/ { sub(/^# ?/, ""); print; next } NR>2 { exit }' \
			"${BASH_SOURCE[0]}"
		;;
	*)
		die "unknown command '$CMD' (try: $0 --help)"
		;;
esac
