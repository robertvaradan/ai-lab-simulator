#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
	Darwin|Linux)
		;;
	*)
		echo "Use scripts/decision-host.ps1 on Windows." >&2
		exit 1
		;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

REPO_ROOT="$(godot_standard_repo_root)"
GAME_ROOT="$REPO_ROOT/game"
SCENE_PATH="$GAME_ROOT/tools/decision_host/decision_host.tscn"
GODOT_BIN="$(godot_standard_editor_path)"
godot_standard_require "$GODOT_BIN" >/dev/null

if [[ ! -f "$SCENE_PATH" ]]; then
	echo "Required Decision Host scene is missing: $SCENE_PATH" >&2
	exit 1
fi

if [[ "$(godot_standard_host_platform)" == "linux" && -z "${DISPLAY:-}" ]]; then
	echo "The Decision Host launch requires a display. DISPLAY is empty." >&2
	exit 1
fi

exec "$GODOT_BIN" --path "$GAME_ROOT" --scene res://tools/decision_host/decision_host.tscn
