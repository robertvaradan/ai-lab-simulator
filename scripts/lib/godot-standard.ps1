function Get-CanonicalGodotInstallDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    return Join-Path (Join-Path (Join-Path $RepoRoot '.tools') 'godot') '4.7.2'
}

function Get-GodotHostPlatform {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return 'windows'
    }
    if ($IsWindows) {
        return 'windows'
    }
    if ($IsMacOS) {
        return 'macos'
    }
    throw 'This repository supports Windows and macOS Godot hosts. This host is not supported.'
}

function Get-CanonicalGodotInstallCommand {
    if ((Get-GodotHostPlatform) -eq 'macos') {
        return 'scripts/install-godot-standard.sh'
    }
    return 'scripts\install-godot-standard.ps1'
}

function Get-CanonicalGodotEditorExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $installDirectory = Get-CanonicalGodotInstallDirectory -RepoRoot $RepoRoot
    if ((Get-GodotHostPlatform) -eq 'macos') {
        return Join-Path $installDirectory 'Godot.app/Contents/MacOS/Godot'
    }
    return Join-Path $installDirectory 'Godot_v4.7.2-stable_win64.exe'
}

function Get-CanonicalGodotAutomationExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    $installDirectory = Get-CanonicalGodotInstallDirectory -RepoRoot $RepoRoot
    if ((Get-GodotHostPlatform) -eq 'macos') {
        return Join-Path $installDirectory 'Godot.app/Contents/MacOS/Godot'
    }
    return Join-Path $installDirectory 'Godot_v4.7.2-stable_win64_console.exe'
}

function Assert-CanonicalGodotExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GodotPath
    )

    if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
        throw "Required canonical Godot executable is missing: $GodotPath. Run $(Get-CanonicalGodotInstallCommand)."
    }
    $godotVersion = (& $GodotPath --version | Select-Object -First 1).Trim()
    if (-not $godotVersion.StartsWith('4.7.2.stable')) {
        throw "Godot 4.7.2 stable is required; executable reported '$godotVersion'."
    }
    if ($godotVersion -match '(?i)(mono|\.net)') {
        throw "The standard non-.NET Godot runtime is required; executable reported '$godotVersion'."
    }
    return $godotVersion
}
