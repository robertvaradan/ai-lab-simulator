#!/usr/bin/env bash
set -euo pipefail

# Cloud Agent Linux bootstrap for the AI Lab Simulator.
# This script is idempotent.
# It installs the system libraries the standard Godot 4.7.2 Linux build needs.
# It installs Mesa lavapipe as the software Vulkan device for the Forward+ compute renderer.
# It installs Xvfb for the windowed capture commands on a headless host.
# It installs the canonical Godot Linux executable.
# It imports the Godot project one time to warm the import cache.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/godot-standard.sh
source "$SCRIPT_DIR/lib/godot-standard.sh"

REPO_ROOT="$(godot_standard_repo_root)"

if [[ "$(godot_standard_host_platform)" != "linux" ]]; then
	echo "scripts/cloud-agent-setup.sh supports the Linux Cloud Agent host only." >&2
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends \
	unzip curl ca-certificates \
	xvfb \
	mesa-vulkan-drivers vulkan-tools libvulkan1 \
	libgl1 libglu1-mesa \
	libx11-6 libxcursor1 libxinerama1 libxi6 libxrandr2 libxrender1 \
	libasound2t64 libpulse0 fontconfig libfontconfig1

bash "$SCRIPT_DIR/install-godot-standard.sh"

GODOT_BIN="$(godot_standard_automation_path)"
"$GODOT_BIN" --headless --editor --path "$REPO_ROOT/game" --import --quit

echo "CLOUD_AGENT_SETUP_SUCCESS godot=$(godot_standard_require "$GODOT_BIN")"
