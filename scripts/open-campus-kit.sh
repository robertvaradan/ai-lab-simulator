#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Use scripts/open-campus-kit.ps1 on Windows." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/blender-standard.sh
source "$SCRIPT_DIR/lib/blender-standard.sh"

REPO_ROOT="$(blender_standard_repo_root)"
BLENDER_BIN="$(blender_standard_executable)"
blender_standard_require "$BLENDER_BIN" >/dev/null

BLEND="$REPO_ROOT/model-pipeline/source/campus_modular_kit.blend"
OPEN_SCRIPT="$REPO_ROOT/model-pipeline/scripts/open_authoring.py"
if [[ ! -f "$BLEND" ]]; then
	echo "Authoring file is missing: $BLEND" >&2
	exit 1
fi
if [[ ! -f "$OPEN_SCRIPT" ]]; then
	echo "Required authoring script is missing: $OPEN_SCRIPT" >&2
	exit 1
fi

exec "$BLENDER_BIN" --python-exit-code 1 "$BLEND" --python "$OPEN_SCRIPT" -- --repo-root "$REPO_ROOT"
