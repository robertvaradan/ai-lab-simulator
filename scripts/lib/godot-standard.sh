#!/usr/bin/env bash

godot_standard_repo_root() {
	local source_path="${BASH_SOURCE[0]}"
	local lib_dir
	lib_dir="$(cd "$(dirname "$source_path")" && pwd)"
	(cd "$lib_dir/../.." && pwd)
}

godot_standard_install_dir() {
	printf '%s/.tools/godot/4.7.2\n' "$(godot_standard_repo_root)"
}

godot_standard_host_platform() {
	case "$(uname -s)" in
		Darwin)
			printf 'macos\n'
			;;
		Linux)
			printf 'linux\n'
			;;
		MINGW*|MSYS*|CYGWIN*|Windows_NT)
			printf 'windows\n'
			;;
		*)
			echo "This repository supports Windows, macOS, and Linux Godot hosts. This host is not supported: $(uname -s)." >&2
			return 1
			;;
	esac
}

godot_standard_install_command() {
	case "$(godot_standard_host_platform)" in
		macos|linux)
			printf 'scripts/install-godot-standard.sh\n'
			;;
		*)
			printf 'scripts/install-godot-standard.ps1\n'
			;;
	esac
}

godot_standard_editor_path() {
	local install_dir
	install_dir="$(godot_standard_install_dir)"
	case "$(godot_standard_host_platform)" in
		macos)
			printf '%s/Godot.app/Contents/MacOS/Godot\n' "$install_dir"
			;;
		linux)
			printf '%s/Godot_v4.7.2-stable_linux.x86_64\n' "$install_dir"
			;;
		*)
			printf '%s/Godot_v4.7.2-stable_win64.exe\n' "$install_dir"
			;;
	esac
}

godot_standard_automation_path() {
	local install_dir
	install_dir="$(godot_standard_install_dir)"
	case "$(godot_standard_host_platform)" in
		macos)
			printf '%s/Godot.app/Contents/MacOS/Godot\n' "$install_dir"
			;;
		linux)
			printf '%s/Godot_v4.7.2-stable_linux.x86_64\n' "$install_dir"
			;;
		*)
			printf '%s/Godot_v4.7.2-stable_win64_console.exe\n' "$install_dir"
			;;
	esac
}

# Run the canonical Godot with a real rendering context.
# A macOS host uses the active window server.
# A Linux host with an active display uses that display.
# A Linux host without a display uses an Xvfb virtual display so the
# Forward+ RenderingDevice and compute pipeline still run.
godot_standard_run_windowed() {
	local platform
	platform="$(godot_standard_host_platform)" || return 1
	if [[ "$platform" == "linux" && -z "${DISPLAY:-}" ]]; then
		if ! command -v xvfb-run >/dev/null 2>&1; then
			echo "A Linux host without an active display requires xvfb-run. Install the xvfb package." >&2
			return 1
		fi
		local runtime_dir="${XDG_RUNTIME_DIR:-/tmp/godot-xdg-runtime}"
		mkdir -p "$runtime_dir"
		chmod 700 "$runtime_dir" 2>/dev/null || true
		XDG_RUNTIME_DIR="$runtime_dir" xvfb-run -a -s "-screen 0 1920x1080x24" "$@"
		return $?
	fi
	"$@"
}

godot_standard_require() {
	local godot_path="$1"
	if [[ ! -f "$godot_path" ]]; then
		echo "Required canonical Godot executable is missing: $godot_path. Run $(godot_standard_install_command)." >&2
		return 1
	fi
	local godot_version
	godot_version="$("$godot_path" --version | head -n 1 | tr -d '\r')"
	if [[ "$godot_version" != 4.7.2.stable* ]]; then
		echo "Godot 4.7.2 stable is required; executable reported '$godot_version'." >&2
		return 1
	fi
	if echo "$godot_version" | grep -Ei '(mono|\.net)' >/dev/null; then
		echo "The standard non-.NET Godot runtime is required; executable reported '$godot_version'." >&2
		return 1
	fi
	printf '%s\n' "$godot_version"
}
