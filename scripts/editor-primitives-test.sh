#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Use scripts/editor-primitives-test.ps1 on Windows." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

REPO_ROOT="$(godot_standard_repo_root)"
GAME_ROOT="$REPO_ROOT/game"
GODOT_BIN="$(godot_standard_automation_path)"
GODOT_VERSION="$(godot_standard_require "$GODOT_BIN")"
BOX_TEST_SCRIPT="$GAME_ROOT/tests/primitives/box_outline_mesh_test.gd"
CYLINDER_TEST_SCRIPT="$GAME_ROOT/tests/primitives/cylinder_outline_mesh_test.gd"

if [[ ! -f "$BOX_TEST_SCRIPT" ]]; then
	echo "Required editor primitive test script is missing: $BOX_TEST_SCRIPT" >&2
	exit 1
fi
if [[ ! -f "$CYLINDER_TEST_SCRIPT" ]]; then
	echo "Required editor primitive test script is missing: $CYLINDER_TEST_SCRIPT" >&2
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

run_primitive_test() {
	local res_path="$1"
	local marker="$2"
	local label="$3"
	echo "Running ${label} contract tests"
	set +e
	local test_output
	local test_code
	test_output="$("$GODOT_BIN" --headless --path "$GAME_ROOT" --quit-after 30 --script "$res_path" 2>&1)"
	test_code=$?
	set -e
	printf '%s\n' "$test_output"
	if [[ "$test_code" -ne 0 ]]; then
		echo "The ${label} test failed with exit code ${test_code}." >&2
		exit "$test_code"
	fi
	report_if_script_error "$test_output" "The ${label} test"
	if ! echo "$test_output" | grep -F "$marker" >/dev/null; then
		echo "The ${label} test did not report the required success marker." >&2
		exit 1
	fi
}

echo '[1/3] Importing the Godot 4.7 project'
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

echo '[2/3] Running BoxOutlineMesh contract tests'
run_primitive_test 'res://tests/primitives/box_outline_mesh_test.gd' 'BOX_OUTLINE_MESH_TEST_SUCCESS' 'BoxOutlineMesh'

echo '[3/3] Running CylinderOutlineMesh contract tests'
run_primitive_test 'res://tests/primitives/cylinder_outline_mesh_test.gd' 'CYLINDER_OUTLINE_MESH_TEST_SUCCESS' 'CylinderOutlineMesh'

echo "EDITOR_PRIMITIVES_TEST_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet"
