#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Use scripts/render-campus-blockout.ps1 on Windows." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

REPO_ROOT="$(godot_standard_repo_root)"
GAME_ROOT="$REPO_ROOT/game"
GODOT_BIN="$(godot_standard_automation_path)"
GODOT_VERSION="$(godot_standard_require "$GODOT_BIN")"
SCENE_PATH="$GAME_ROOT/scenes/campus_blockout.tscn"
CAPTURE_SCENE_PATH="$GAME_ROOT/scenes/campus_blockout_capture.tscn"
CAPTURE_SCRIPT_PATH="$GAME_ROOT/scripts/campus_blockout_capture.gd"
EVIDENCE_PATH="$GAME_ROOT/evidence/blockout/main_lab.png"
COMPARISON_PATH="$GAME_ROOT/evidence/blockout/main_lab_comparison.png"

for required_path in "$SCENE_PATH" "$CAPTURE_SCENE_PATH" "$CAPTURE_SCRIPT_PATH"; do
	if [[ ! -f "$required_path" ]]; then
		echo "Required campus blockout source is missing: $required_path" >&2
		exit 1
	fi
done

mkdir -p "$(dirname "$EVIDENCE_PATH")"
rm -f "$EVIDENCE_PATH" "$EVIDENCE_PATH.import" "$COMPARISON_PATH" "$COMPARISON_PATH.import"

report_if_script_error() {
	local output="$1"
	local context="$2"
	if echo "$output" | grep -E '(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)' >/dev/null; then
		echo "$context reported a script error." >&2
		exit 1
	fi
}

echo '[1/2] Importing the native Godot campus blockout'
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

echo '[2/2] Rendering the fixed 1920x1080 campus blockout'
set +e
RENDER_OUTPUT="$(
	"$GODOT_BIN" \
		--path "$GAME_ROOT" \
		--resolution 1920x1080 \
		--quit-after 900 \
		res://scenes/campus_blockout_capture.tscn \
		-- \
		--render-blockout \
		--output-path "$EVIDENCE_PATH" 2>&1
)"
RENDER_CODE=$?
set -e
printf '%s\n' "$RENDER_OUTPUT"
if [[ "$RENDER_CODE" -ne 0 ]]; then
	echo "Campus blockout render failed with exit code $RENDER_CODE." >&2
	exit "$RENDER_CODE"
fi
report_if_script_error "$RENDER_OUTPUT" 'Campus blockout render'
if ! echo "$RENDER_OUTPUT" | grep -F 'CAMPUS_BLOCKOUT_SCENE_LOADED' >/dev/null; then
	echo 'Campus blockout render did not load the script-free editable scene.' >&2
	exit 1
fi
if ! echo "$RENDER_OUTPUT" | grep -F 'CAMPUS_BLOCKOUT_CAPTURE_SUCCESS' >/dev/null; then
	echo 'Campus blockout render did not report the required success marker.' >&2
	exit 1
fi
if ! echo "$RENDER_OUTPUT" | grep -F 'CAMPUS_BLOCKOUT_COMPARISON_SUCCESS' >/dev/null; then
	echo 'Campus blockout render did not report the required comparison marker.' >&2
	exit 1
fi
if [[ ! -f "$EVIDENCE_PATH" ]]; then
	echo "Campus blockout render did not create expected evidence: $EVIDENCE_PATH" >&2
	exit 1
fi
EVIDENCE_BYTES="$(wc -c < "$EVIDENCE_PATH" | tr -d ' ')"
if [[ "$EVIDENCE_BYTES" -lt 40000 ]]; then
	echo "Campus blockout evidence PNG is implausibly small ($EVIDENCE_BYTES bytes): $EVIDENCE_PATH" >&2
	exit 1
fi
if [[ ! -f "$COMPARISON_PATH" ]]; then
	echo "Campus blockout render did not create expected comparison: $COMPARISON_PATH" >&2
	exit 1
fi
COMPARISON_BYTES="$(wc -c < "$COMPARISON_PATH" | tr -d ' ')"
if [[ "$COMPARISON_BYTES" -lt 40000 ]]; then
	echo "Campus comparison PNG is implausibly small ($COMPARISON_BYTES bytes): $COMPARISON_PATH" >&2
	exit 1
fi

echo "CAMPUS_BLOCKOUT_COMMAND_SUCCESS godot=$GODOT_VERSION runtime=standard_non_dotnet size=1920x1080 bytes=$EVIDENCE_BYTES evidence=$EVIDENCE_PATH comparison_bytes=$COMPARISON_BYTES comparison=$COMPARISON_PATH"
