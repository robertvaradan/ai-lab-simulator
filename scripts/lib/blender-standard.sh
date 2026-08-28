#!/usr/bin/env bash

blender_standard_repo_root() {
	local source_path="${BASH_SOURCE[0]}"
	local lib_dir
	lib_dir="$(cd "$(dirname "$source_path")" && pwd)"
	(cd "$lib_dir/../.." && pwd)
}

blender_standard_host_platform() {
	case "$(uname -s)" in
		Darwin)
			printf 'macos\n'
			;;
		MINGW*|MSYS*|CYGWIN*|Windows_NT)
			printf 'windows\n'
			;;
		*)
			echo "This repository supports Windows and macOS Blender hosts. This host is not supported: $(uname -s)." >&2
			return 1
			;;
	esac
}

blender_standard_executable() {
	if [[ "$(blender_standard_host_platform)" == "macos" ]]; then
		printf '/Applications/Blender.app/Contents/MacOS/Blender\n'
	else
		echo "Use scripts/export-campus-kit.ps1 or scripts/open-campus-kit.ps1 on Windows." >&2
		return 1
	fi
}

blender_standard_require() {
	local blender_path="$1"
	if [[ ! -f "$blender_path" ]]; then
		echo "Required canonical Blender 5.1 executable is missing: $blender_path" >&2
		return 1
	fi
	local blender_version
	blender_version="$("$blender_path" --version 2>/dev/null | grep -E '^Blender ' | head -n 1 | tr -d '\r')"
	if [[ "$blender_version" != Blender\ 5.1* ]]; then
		echo "Blender 5.1 is required; executable reported '$blender_version'." >&2
		return 1
	fi
	printf '%s\n' "$blender_version"
}
