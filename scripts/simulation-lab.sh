#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
	Darwin|Linux)
		;;
	*)
		echo "Use scripts/simulation-lab.ps1 on Windows." >&2
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

LAB_TEST="$GAME_ROOT/tests/tools/simulation_lab_test.gd"
LAB_RUNNER="$GAME_ROOT/tools/simulation_lab/run_marketing_scenario.gd"

for required_file in "$LAB_TEST" "$LAB_RUNNER"; do
	if [[ ! -f "$required_file" ]]; then
		echo "Required Simulation Laboratory file is missing: $required_file" >&2
		exit 1
	fi
done

report_if_script_error() {
	local output="$1"
	local context="$2"
	if echo "$output" | grep -E '(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)' >/dev/null; then
		echo "$context reported a script error." >&2
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

invoke_lab_script() {
	local script_path="$1"
	local success_marker="$2"
	set +e
	local test_output
	local test_code
	test_output="$("$GODOT_BIN" --headless --path "$GAME_ROOT" --quit-after 30 --script "$script_path" 2>&1)"
	test_code=$?
	set -e
	printf '%s\n' "$test_output"
	if [[ "$test_code" -ne 0 ]]; then
		echo "Simulation Laboratory script $script_path failed with exit code $test_code." >&2
		exit "$test_code"
	fi
	report_if_script_error "$test_output" "Simulation Laboratory script $script_path"
	if ! echo "$test_output" | grep -F "$success_marker" >/dev/null; then
		echo "Simulation Laboratory script $script_path did not report success marker $success_marker." >&2
		exit 1
	fi
}

echo '[2/3] Running Simulation Laboratory tests'
invoke_lab_script 'res://tests/tools/simulation_lab_test.gd' 'SIMULATION_LAB_TEST_SUCCESS'

echo '[3/3] Running the Marketing Scenario in the Simulation Laboratory'
invoke_lab_script 'res://tools/simulation_lab/run_marketing_scenario.gd' 'SIMULATION_LAB_RUN_SUCCESS'

echo "SIMULATION_LAB_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet"
