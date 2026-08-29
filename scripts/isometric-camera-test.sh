#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Use scripts/isometric-camera-test.ps1 on Windows." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

REPO_ROOT="$(godot_standard_repo_root)"
GAME_ROOT="$REPO_ROOT/game"
GODOT_BIN="$(godot_standard_automation_path)"
GODOT_VERSION="$(godot_standard_require "$GODOT_BIN")"
CAMERA_TEST_SCRIPT="$GAME_ROOT/tests/camera/isometric_camera_test.gd"

if [[ ! -f "$CAMERA_TEST_SCRIPT" ]]; then
	echo "Required isometric camera test script is missing: $CAMERA_TEST_SCRIPT" >&2
	exit 1
fi

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

echo '[2/2] Running IsometricCamera contract tests'
set +e
TEST_OUTPUT="$("$GODOT_BIN" --headless --path "$GAME_ROOT" --quit-after 30 --script "res://tests/camera/isometric_camera_test.gd" 2>&1)"
TEST_CODE=$?
set -e
printf '%s\n' "$TEST_OUTPUT"
if [[ "$TEST_CODE" -ne 0 ]]; then
	echo "The isometric camera test failed with exit code ${TEST_CODE}." >&2
	exit "$TEST_CODE"
fi
report_if_script_error "$TEST_OUTPUT" 'The isometric camera test'
if ! echo "$TEST_OUTPUT" | grep -F 'ISOMETRIC_CAMERA_TEST_SUCCESS' >/dev/null; then
	echo "The isometric camera test did not report the required success marker." >&2
	exit 1
fi

echo "ISOMETRIC_CAMERA_TEST_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet"
