#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "Use scripts/install-godot-standard.ps1 on Windows." >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

VERSION="4.7.2"
INSTALL_DIR="$(godot_standard_install_dir)"
ARCHIVE_PATH="$INSTALL_DIR/Godot_v${VERSION}-stable_macos.universal.zip"
APP_PATH="$INSTALL_DIR/Godot.app"
EDITOR_PATH="$(godot_standard_editor_path)"
DOWNLOAD_URL="https://github.com/godotengine/godot-builds/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_macos.universal.zip"

mkdir -p "$INSTALL_DIR"
trap 'rm -f "$ARCHIVE_PATH"' EXIT

curl -L --fail -o "$ARCHIVE_PATH" "$DOWNLOAD_URL"
rm -rf "$APP_PATH"
unzip -q -o "$ARCHIVE_PATH" -d "$INSTALL_DIR"

if [[ ! -f "$EDITOR_PATH" ]]; then
	echo "Godot archive did not contain required executable: $EDITOR_PATH" >&2
	exit 1
fi

xattr -dr com.apple.quarantine "$APP_PATH" || true
chmod +x "$EDITOR_PATH"
codesign --verify --verbose=2 "$APP_PATH"

REPORTED_VERSION="$(godot_standard_require "$EDITOR_PATH")"
BYTES="$(wc -c < "$EDITOR_PATH" | tr -d ' ')"
echo "GODOT_STANDARD_INSTALLED path=$EDITOR_PATH bytes=$BYTES"
echo "GODOT_STANDARD_INSTALL_SUCCESS version=$REPORTED_VERSION editor=$EDITOR_PATH"
