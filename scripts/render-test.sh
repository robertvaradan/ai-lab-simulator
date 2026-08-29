#!/usr/bin/env bash
set -euo pipefail

case "$(uname -s)" in
	Darwin|Linux)
		;;
	*)
		echo "Use scripts/render-test.ps1 on Windows." >&2
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
SHADER_PATH="$GAME_ROOT/renderer/sdf/campus_sdf.glsl"
RENDERER_PATH="$GAME_ROOT/renderer/sdf/sdf_renderer.gd"
HARNESS_PATH="$GAME_ROOT/scripts/sdf_render_harness.gd"
EVIDENCE_ROOT="$GAME_ROOT/evidence/sdf"

for required_path in "$SHADER_PATH" "$RENDERER_PATH" "$HARNESS_PATH"; do
	if [[ ! -f "$required_path" ]]; then
		echo "Required SDF pipeline source is missing: $required_path" >&2
		exit 1
	fi
done

mkdir -p "$EVIDENCE_ROOT"
for state in growth overload scrutiny; do
	output_path="$EVIDENCE_ROOT/$state.png"
	rm -f "$output_path" "$output_path.import"
done

report_if_script_error() {
	local output="$1"
	local context="$2"
	if echo "$output" | grep -E '(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)' >/dev/null; then
		echo "$context reported a script error." >&2
		exit 1
	fi
}

echo '[1/2] Importing the Godot 4.7 project and compute shader'
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

echo '[2/2] Dispatching the compute-SDF renderer and capturing three 1920x1080 states'
set +e
RENDER_OUTPUT="$(godot_standard_run_windowed "$GODOT_BIN" --path "$GAME_ROOT" --resolution 1920x1080 --quit-after 900 -- --render-all --output-dir "$EVIDENCE_ROOT" 2>&1)"
RENDER_CODE=$?
set -e
printf '%s\n' "$RENDER_OUTPUT"
if [[ "$RENDER_CODE" -ne 0 ]]; then
	echo "Godot SDF render test failed with exit code $RENDER_CODE." >&2
	exit "$RENDER_CODE"
fi
report_if_script_error "$RENDER_OUTPUT" 'Godot SDF render test'
if ! echo "$RENDER_OUTPUT" | grep -F 'SDF_RENDERER_INITIALIZED' >/dev/null; then
	echo 'Godot SDF render test did not initialize the compute renderer.' >&2
	exit 1
fi
dispatch_count="$(echo "$RENDER_OUTPUT" | grep -c 'SDF_DISPATCH_SUBMITTED' || true)"
if [[ "$dispatch_count" -ne 3 ]]; then
	echo 'Godot SDF render test did not submit exactly three dispatches.' >&2
	exit 1
fi
if ! echo "$RENDER_OUTPUT" | grep -F 'SDF_RENDER_TEST_SUCCESS' >/dev/null; then
	echo 'Godot SDF render test did not report the required success marker.' >&2
	exit 1
fi

for state in growth overload scrutiny; do
	output_path="$EVIDENCE_ROOT/$state.png"
	if [[ ! -f "$output_path" ]]; then
		echo "SDF render test did not create expected evidence: $output_path" >&2
		exit 1
	fi
	length="$(wc -c < "$output_path" | tr -d ' ')"
	if [[ "$length" -lt 40000 ]]; then
		echo "SDF evidence PNG is implausibly small ($length bytes): $output_path" >&2
		exit 1
	fi
	echo "SDF_RENDER_EVIDENCE state=$state bytes=$length path=$output_path"
done

renderer_bytes="$(wc -c < "$RENDERER_PATH" | tr -d ' ')"
shader_bytes="$(wc -c < "$SHADER_PATH" | tr -d ' ')"
echo "SDF_RENDER_TEST_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet internal=640x360 output=1920x1080 renderer_bytes=$renderer_bytes shader_bytes=$shader_bytes evidence=$EVIDENCE_ROOT"
