function Get-BlenderHostPlatform {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return 'windows'
    }
    if ($IsWindows) {
        return 'windows'
    }
    if ($IsMacOS) {
        return 'macos'
    }
    throw 'This repository supports Windows and macOS Blender hosts. This host is not supported.'
}

function Get-CanonicalBlenderExecutable {
    if ((Get-BlenderHostPlatform) -ne 'windows') {
        throw 'Use scripts/export-campus-kit.sh or scripts/open-campus-kit.sh on macOS.'
    }
    return 'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe'
}

function Assert-CanonicalBlenderExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BlenderPath
    )

    if (-not (Test-Path -LiteralPath $BlenderPath -PathType Leaf)) {
        throw "Required canonical Blender 5.1 executable is missing: $BlenderPath"
    }
    $blenderVersion = (& $BlenderPath --version 2>$null | Select-String -Pattern '^Blender ' | Select-Object -First 1).ToString().Trim()
    if (-not $blenderVersion.StartsWith('Blender 5.1')) {
        throw "Blender 5.1 is required; executable reported '$blenderVersion'."
    }
    return $blenderVersion
}
