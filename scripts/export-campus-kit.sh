#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Use scripts/export-campus-kit.ps1 on Windows." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/blender-standard.sh
source "$SCRIPT_DIR/lib/blender-standard.sh"

REPO_ROOT="$(blender_standard_repo_root)"
BLENDER_BIN="$(blender_standard_executable)"
blender_standard_require "$BLENDER_BIN" >/dev/null

PIPELINE_SCRIPT="$REPO_ROOT/model-pipeline/scripts/export_assets.py"
if [[ ! -f "$PIPELINE_SCRIPT" ]]; then
	echo "Required pipeline script is missing: $PIPELINE_SCRIPT" >&2
	exit 1
fi

exec "$BLENDER_BIN" --background --factory-startup --python-exit-code 1 --python "$PIPELINE_SCRIPT" -- --repo-root "$REPO_ROOT" --mode export
