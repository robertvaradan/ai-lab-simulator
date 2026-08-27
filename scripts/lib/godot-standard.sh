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
		MINGW*|MSYS*|CYGWIN*|Windows_NT)
			printf 'windows\n'
			;;
		*)
			echo "This repository supports Windows and macOS Godot hosts. This host is not supported: $(uname -s)." >&2
			return 1
			;;
	esac
}

godot_standard_install_command() {
	if [[ "$(godot_standard_host_platform)" == "macos" ]]; then
		printf 'scripts/install-godot-standard.sh\n'
	else
		printf 'scripts/install-godot-standard.ps1\n'
	fi
}

godot_standard_editor_path() {
	local install_dir
	install_dir="$(godot_standard_install_dir)"
	if [[ "$(godot_standard_host_platform)" == "macos" ]]; then
		printf '%s/Godot.app/Contents/MacOS/Godot\n' "$install_dir"
	else
		printf '%s/Godot_v4.7.2-stable_win64.exe\n' "$install_dir"
	fi
}

godot_standard_automation_path() {
	local install_dir
	install_dir="$(godot_standard_install_dir)"
	if [[ "$(godot_standard_host_platform)" == "macos" ]]; then
		printf '%s/Godot.app/Contents/MacOS/Godot\n' "$install_dir"
	else
		printf '%s/Godot_v4.7.2-stable_win64_console.exe\n' "$install_dir"
	fi
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
