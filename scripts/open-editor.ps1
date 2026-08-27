[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

if ((Get-GodotHostPlatform) -ne 'windows') {
    throw 'Use scripts/open-editor.sh on macOS.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotEditorExecutable -RepoRoot $repoRoot
Assert-CanonicalGodotExecutable -GodotPath $godotBin | Out-Null
& $godotBin --editor --path $gameRoot
