#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
	Darwin|Linux)
		;;
	*)
		echo "Use scripts/panel-system-capture.ps1 on Windows." >&2
		exit 1
		;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

REPO_ROOT="$(godot_standard_repo_root)"
GAME_ROOT="$REPO_ROOT/game"
GODOT_BIN="$(godot_standard_automation_path)"
GODOT_VERSION="$(godot_standard_require "$GODOT_BIN")"
CAPTURE_SCENE="$GAME_ROOT/scenes/panel_system_capture.tscn"
EVIDENCE_ROOT="$GAME_ROOT/evidence/panel_system"

if [[ ! -f "$CAPTURE_SCENE" ]]; then
	echo "Required panel system capture scene is missing: $CAPTURE_SCENE" >&2
	exit 1
fi

mkdir -p "$EVIDENCE_ROOT"
rm -rf "$EVIDENCE_ROOT"/*

report_if_script_error() {
	local output="$1"
	local context="$2"
	if echo "$output" | grep -E '(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)' >/dev/null; then
		echo "$context reported a script error." >&2
		exit 1
	fi
}

echo '[1/2] Importing the Godot 4.7 project'
set +e
IMPORT_OUTPUT="$("$GODOT_BIN" --headless --editor --path "$GAME_ROOT" --import --quit 2>&1)"
IMPORT_CODE=$?
set -e
printf '%s\n' "$IMPORT_OUTPUT"
if [[ "$IMPORT_CODE" -ne 0 ]]; then
	echo "Godot import failed with exit code $IMPORT_CODE." >&2
	exit "$IMPORT_CODE"
fi
report_if_script_error "$IMPORT_OUTPUT" 'Godot import'

echo '[2/2] Capturing Campaign Panel System views'
set +e
CAPTURE_OUTPUT="$(
	godot_standard_run_windowed "$GODOT_BIN" \
		--path "$GAME_ROOT" \
		--resolution 1920x1080 \
		--quit-after 1200 \
		res://scenes/panel_system_capture.tscn \
		-- \
		--render-panel-system \
		--output-root "$EVIDENCE_ROOT" 2>&1
)"
CAPTURE_CODE=$?
set -e
printf '%s\n' "$CAPTURE_OUTPUT"
if [[ "$CAPTURE_CODE" -ne 0 ]]; then
	echo "Panel system capture failed with exit code ${CAPTURE_CODE}." >&2
	exit "$CAPTURE_CODE"
fi
report_if_script_error "$CAPTURE_OUTPUT" 'Panel system capture'
if ! echo "$CAPTURE_OUTPUT" | grep -F 'PANEL_SYSTEM_CAPTURE_SUCCESS' >/dev/null; then
	echo 'Panel system capture did not report success.' >&2
	exit 1
fi

echo "PANEL_SYSTEM_CAPTURE_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet"
