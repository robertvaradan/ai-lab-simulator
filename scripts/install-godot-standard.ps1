[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

if ((Get-GodotHostPlatform) -ne 'windows') {
    throw 'Use scripts/install-godot-standard.sh on macOS.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$version = '4.7.2'
$releaseName = "Godot_v$version-stable_win64"
$installDirectory = Get-CanonicalGodotInstallDirectory -RepoRoot $repoRoot
$archivePath = Join-Path $installDirectory "$releaseName.exe.zip"
$editorPath = Get-CanonicalGodotEditorExecutable -RepoRoot $repoRoot
$consolePath = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$downloadUrl = "https://downloads.godotengine.org/?flavor=stable&platform=windows.64&slug=win64.exe.zip&version=$version"

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath
    Expand-Archive -LiteralPath $archivePath -DestinationPath $installDirectory -Force

    foreach ($requiredExecutable in @($editorPath, $consolePath)) {
        if (-not (Test-Path -LiteralPath $requiredExecutable -PathType Leaf)) {
            throw "Godot archive did not contain required executable: $requiredExecutable"
        }

        $signature = Get-AuthenticodeSignature -LiteralPath $requiredExecutable
        if ($signature.Status -ne 'Valid') {
            throw "Godot executable signature is not valid: $requiredExecutable status=$($signature.Status)"
        }

        Write-Output "GODOT_STANDARD_INSTALLED path=$requiredExecutable bytes=$((Get-Item -LiteralPath $requiredExecutable).Length) signer=$($signature.SignerCertificate.Subject)"
    }

    $reportedVersion = (& $consolePath --version | Select-Object -First 1).Trim()
    if (-not $reportedVersion.StartsWith("$version.stable")) {
        throw "Installed Godot executable reported '$reportedVersion'; expected $version.stable."
    }
    Write-Output "GODOT_STANDARD_INSTALL_SUCCESS version=$reportedVersion console=$consolePath"
}
finally {
    if (Test-Path -LiteralPath $archivePath -PathType Leaf) {
        Remove-Item -LiteralPath $archivePath -Force
    }
}
