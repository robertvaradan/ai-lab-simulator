#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Use scripts/simulation-test.ps1 on Windows." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

REPO_ROOT="$(godot_standard_repo_root)"
GAME_ROOT="$REPO_ROOT/game"
GODOT_BIN="$(godot_standard_automation_path)"
GODOT_VERSION="$(godot_standard_require "$GODOT_BIN")"

STATE_TEST="$GAME_ROOT/tests/simulation/game_state_test.gd"
PUBLICATION_TEST="$GAME_ROOT/tests/simulation/game_state_publication_test.gd"
CASH_LEDGER_TEST="$GAME_ROOT/tests/simulation/cash_ledger_test.gd"
SIMULATION_CORE_TEST="$GAME_ROOT/tests/simulation/simulation_core_test.gd"
PLAN_COMMITMENT_TEST="$GAME_ROOT/tests/simulation/plan_commitment_test.gd"
MONTH_STEP_TEST="$GAME_ROOT/tests/simulation/month_step_test.gd"

for test_script in "$STATE_TEST" "$PUBLICATION_TEST" "$CASH_LEDGER_TEST" "$SIMULATION_CORE_TEST" "$PLAN_COMMITMENT_TEST" "$MONTH_STEP_TEST"; do
	if [[ ! -f "$test_script" ]]; then
		echo "Required Simulation Core test script is missing: $test_script" >&2
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

echo '[1/7] Importing the Godot 4.7 project'
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

invoke_simulation_test() {
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
		echo "Simulation Core test $script_path failed with exit code $test_code." >&2
		exit "$test_code"
	fi
	report_if_script_error "$test_output" "Simulation Core test $script_path"
	if ! echo "$test_output" | grep -F "$success_marker" >/dev/null; then
		echo "Simulation Core test $script_path did not report success marker $success_marker." >&2
		exit 1
	fi
}

echo '[2/7] Running Game State and snapshot tests'
invoke_simulation_test 'res://tests/simulation/game_state_test.gd' 'GAME_STATE_TEST_SUCCESS'

echo '[3/7] Running committed Game State publication tests'
invoke_simulation_test 'res://tests/simulation/game_state_publication_test.gd' 'GAME_STATE_PUBLICATION_TEST_SUCCESS'

echo '[4/7] Running Cash Ledger tests'
invoke_simulation_test 'res://tests/simulation/cash_ledger_test.gd' 'CASH_LEDGER_TEST_SUCCESS'

echo '[5/7] Running Rule registry, Simulation Context, and Simulation Core tests'
invoke_simulation_test 'res://tests/simulation/simulation_core_test.gd' 'SIMULATION_CORE_TEST_SUCCESS'

echo '[6/7] Running Plan validation and commitment tests'
invoke_simulation_test 'res://tests/simulation/plan_commitment_test.gd' 'PLAN_COMMITMENT_TEST_SUCCESS'

echo '[7/7] Running Month Step and Quarter Boundary tests'
invoke_simulation_test 'res://tests/simulation/month_step_test.gd' 'MONTH_STEP_TEST_SUCCESS'

echo "SIMULATION_TEST_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet"
