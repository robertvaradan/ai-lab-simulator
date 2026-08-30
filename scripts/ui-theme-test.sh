#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
	Darwin|Linux)
		;;
	*)
		echo "Use scripts/ui-theme-test.ps1 on Windows." >&2
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
THEME_TEST_SCRIPT="$GAME_ROOT/tests/ui/base_theme_test.gd"

if [[ ! -f "$THEME_TEST_SCRIPT" ]]; then
	echo "Required UI theme test script is missing: $THEME_TEST_SCRIPT" >&2
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

echo '[2/2] Running UI theme contract tests'
set +e
TEST_OUTPUT="$("$GODOT_BIN" --headless --path "$GAME_ROOT" --quit-after 30 --script "res://tests/ui/base_theme_test.gd" 2>&1)"
TEST_CODE=$?
set -e
printf '%s\n' "$TEST_OUTPUT"
if [[ "$TEST_CODE" -ne 0 ]]; then
	echo "The UI theme test failed with exit code ${TEST_CODE}." >&2
	exit "$TEST_CODE"
fi
report_if_script_error "$TEST_OUTPUT" 'The UI theme test'
if ! echo "$TEST_OUTPUT" | grep -F 'UI_THEME_TEST_SUCCESS' >/dev/null; then
	echo "The UI theme test did not report the required success marker." >&2
	exit 1
fi

echo "UI_THEME_TEST_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet"
