#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
	Darwin|Linux)
		;;
	*)
		echo "Use scripts/simulation-test.ps1 on Windows." >&2
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

STATE_TEST="$GAME_ROOT/tests/simulation/game_state_test.gd"
PUBLICATION_TEST="$GAME_ROOT/tests/simulation/game_state_publication_test.gd"
CASH_LEDGER_TEST="$GAME_ROOT/tests/simulation/cash_ledger_test.gd"
SIMULATION_CORE_TEST="$GAME_ROOT/tests/simulation/simulation_core_test.gd"
PLAN_COMMITMENT_TEST="$GAME_ROOT/tests/simulation/plan_commitment_test.gd"
MONTH_STEP_TEST="$GAME_ROOT/tests/simulation/month_step_test.gd"
PROJECT_TEST="$GAME_ROOT/tests/simulation/project_lifecycle_test.gd"
COMPETITOR_TEST="$GAME_ROOT/tests/simulation/competitor_release_test.gd"
MARKET_EFFECTS_TEST="$GAME_ROOT/tests/simulation/market_effects_test.gd"
QUARTERLY_REPORT_TEST="$GAME_ROOT/tests/simulation/quarterly_report_test.gd"
INVARIANTS_REPLAY_TEST="$GAME_ROOT/tests/simulation/invariants_replay_test.gd"
LAB_TEST="$GAME_ROOT/tests/tools/simulation_lab_test.gd"
RULE_GRAPH_ARTIFACT_TEST="$GAME_ROOT/tests/tools/rule_graph_artifact_test.gd"
RULE_GRAPH_TRACE_VIEW_TEST="$GAME_ROOT/tests/tools/rule_graph_trace_view_test.gd"
MARKETING_PLAY_HOST_TEST="$GAME_ROOT/tests/host/marketing_play_host_test.gd"
MARKETING_PLAY_MANAGEMENT_TEST="$GAME_ROOT/tests/host/marketing_play_management_test.gd"
CAMPUS_VISUAL_PRESENTER_TEST="$GAME_ROOT/tests/host/campus_visual_presenter_test.gd"
DECISION_HOST_TEST="$GAME_ROOT/tests/tools/decision_host_test.gd"
PRODUCTION_BOOTSTRAP_TEST="$GAME_ROOT/tests/host/production_bootstrap_test.gd"

for test_script in "$STATE_TEST" "$PUBLICATION_TEST" "$CASH_LEDGER_TEST" "$SIMULATION_CORE_TEST" "$PLAN_COMMITMENT_TEST" "$MONTH_STEP_TEST" "$PROJECT_TEST" "$COMPETITOR_TEST" "$MARKET_EFFECTS_TEST" "$QUARTERLY_REPORT_TEST" "$INVARIANTS_REPLAY_TEST" "$LAB_TEST" "$RULE_GRAPH_ARTIFACT_TEST" "$RULE_GRAPH_TRACE_VIEW_TEST" "$MARKETING_PLAY_HOST_TEST" "$MARKETING_PLAY_MANAGEMENT_TEST" "$CAMPUS_VISUAL_PRESENTER_TEST" "$DECISION_HOST_TEST" "$PRODUCTION_BOOTSTRAP_TEST"; do
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

echo '[1/20] Importing the Godot 4.7 project'
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

echo '[2/20] Running Game State and snapshot tests'
invoke_simulation_test 'res://tests/simulation/game_state_test.gd' 'GAME_STATE_TEST_SUCCESS'

echo '[3/20] Running committed Game State publication tests'
invoke_simulation_test 'res://tests/simulation/game_state_publication_test.gd' 'GAME_STATE_PUBLICATION_TEST_SUCCESS'

echo '[4/20] Running Cash Ledger tests'
invoke_simulation_test 'res://tests/simulation/cash_ledger_test.gd' 'CASH_LEDGER_TEST_SUCCESS'

echo '[5/20] Running Rule registry, Simulation Context, and Simulation Core tests'
invoke_simulation_test 'res://tests/simulation/simulation_core_test.gd' 'SIMULATION_CORE_TEST_SUCCESS'

echo '[6/20] Running Plan validation and commitment tests'
invoke_simulation_test 'res://tests/simulation/plan_commitment_test.gd' 'PLAN_COMMITMENT_TEST_SUCCESS'

echo '[7/20] Running Month Step and Quarter Boundary tests'
invoke_simulation_test 'res://tests/simulation/month_step_test.gd' 'MONTH_STEP_TEST_SUCCESS'

echo '[8/20] Running Marketing Scenario Project tests'
invoke_simulation_test 'res://tests/simulation/project_lifecycle_test.gd' 'PROJECT_LIFECYCLE_TEST_SUCCESS'

echo '[9/20] Running Competitor forecast and release tests'
invoke_simulation_test 'res://tests/simulation/competitor_release_test.gd' 'COMPETITOR_RELEASE_TEST_SUCCESS'

echo '[10/20] Running Market effects and Model position tests'
invoke_simulation_test 'res://tests/simulation/market_effects_test.gd' 'MARKET_EFFECTS_TEST_SUCCESS'

echo '[11/20] Running Quarterly Report tests'
invoke_simulation_test 'res://tests/simulation/quarterly_report_test.gd' 'QUARTERLY_REPORT_TEST_SUCCESS'

echo '[12/20] Running Simulation Invariant and replay tests'
invoke_simulation_test 'res://tests/simulation/invariants_replay_test.gd' 'INVARIANTS_REPLAY_TEST_SUCCESS'

echo '[13/20] Running Simulation Laboratory tests'
invoke_simulation_test 'res://tests/tools/simulation_lab_test.gd' 'SIMULATION_LAB_TEST_SUCCESS'

echo '[14/20] Running Rule Graph artifact tests'
invoke_simulation_test 'res://tests/tools/rule_graph_artifact_test.gd' 'RULE_GRAPH_ARTIFACT_TEST_SUCCESS'

echo '[15/20] Running Rule Graph trace view tests'
invoke_simulation_test 'res://tests/tools/rule_graph_trace_view_test.gd' 'RULE_GRAPH_TRACE_VIEW_TEST_SUCCESS'

echo '[16/20] Running production Marketing play host tests'
invoke_simulation_test 'res://tests/host/marketing_play_host_test.gd' 'MARKETING_PLAY_HOST_TEST_SUCCESS'

echo '[17/20] Running production Marketing play management tests'
invoke_simulation_test 'res://tests/host/marketing_play_management_test.gd' 'MARKETING_PLAY_MANAGEMENT_TEST_SUCCESS'

echo '[18/20] Running campus visual presenter tests'
invoke_simulation_test 'res://tests/host/campus_visual_presenter_test.gd' 'CAMPUS_VISUAL_PRESENTER_TEST_SUCCESS'

echo '[19/20] Running Decision Host tests'
invoke_simulation_test 'res://tests/tools/decision_host_test.gd' 'DECISION_HOST_TEST_SUCCESS'

echo '[20/20] Running production bootstrap tests'
invoke_simulation_test 'res://tests/host/production_bootstrap_test.gd' 'PRODUCTION_BOOTSTRAP_TEST_SUCCESS'

echo "SIMULATION_TEST_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet"
