#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
	Darwin|Linux)
		;;
	*)
		echo "Use scripts/services-test.ps1 on Windows." >&2
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
TEST_SCRIPT="$GAME_ROOT/tests/services/services_test.gd"

if [[ ! -f "$TEST_SCRIPT" ]]; then
	echo "Required service test script is missing: $TEST_SCRIPT" >&2
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

echo '[2/3] Running the service lifecycle and injection test'
set +e
POSITIVE_OUTPUT="$("$GODOT_BIN" --headless --path "$GAME_ROOT" --quit-after 30 --script 'res://tests/services/services_test.gd' -- --case positive 2>&1)"
POSITIVE_CODE=$?
set -e
printf '%s\n' "$POSITIVE_OUTPUT"
if [[ "$POSITIVE_CODE" -ne 0 ]]; then
	echo "The positive service test failed with exit code $POSITIVE_CODE." >&2
	exit "$POSITIVE_CODE"
fi
report_if_script_error "$POSITIVE_OUTPUT" 'The positive service test'
if ! echo "$POSITIVE_OUTPUT" | grep -F 'SERVICES_TEST_SUCCESS' >/dev/null; then
	echo 'The positive service test did not report the required success marker.' >&2
	exit 1
fi

echo '[3/3] Running strict service-provider contract tests'
NEGATIVE_CASES=(
	duplicate_registration
	missing_registration
	wrong_implementation_type
	wrong_service_context
	resolve_before_seal
	provide_after_seal
)
for test_case in "${NEGATIVE_CASES[@]}"; do
	set +e
	case_output="$("$GODOT_BIN" --headless --path "$GAME_ROOT" --quit-after 30 --script 'res://tests/services/services_test.gd' -- --case "$test_case" 2>&1)"
	case_code=$?
	set -e
	printf '%s\n' "$case_output"
	expected_failure="SERVICE_CONTRACT_FAILURE code=$test_case"
	if ! echo "$case_output" | grep -F "$expected_failure" >/dev/null; then
		echo "The '$test_case' test did not report the expected contract failure." >&2
		exit 1
	fi
	if [[ "$case_code" -eq 0 ]]; then
		echo "The invalid '$test_case' operation did not terminate the Godot process with a failure." >&2
		exit 1
	fi
	if echo "$case_output" | grep -F 'SERVICES_TEST_NEGATIVE_CASE_ACCEPTED' >/dev/null; then
		echo "The service provider accepted the invalid '$test_case' operation." >&2
		exit 1
	fi
done

echo "SERVICES_TEST_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet positive=1 negative=${#NEGATIVE_CASES[@]}"
