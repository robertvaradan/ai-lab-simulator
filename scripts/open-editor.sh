#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
	Darwin|Linux)
		;;
	*)
		echo "Use scripts/open-editor.ps1 on Windows." >&2
		exit 1
		;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

REPO_ROOT="$(godot_standard_repo_root)"
GAME_ROOT="$REPO_ROOT/game"
EDITOR_PATH="$(godot_standard_editor_path)"
godot_standard_require "$EDITOR_PATH" >/dev/null
godot_standard_run_windowed "$EDITOR_PATH" --editor --path "$GAME_ROOT"
