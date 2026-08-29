[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

if ((Get-GodotHostPlatform) -ne 'windows') {
    throw 'Use scripts/decision-host.sh on macOS or Linux.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$scenePath = Join-Path (Join-Path (Join-Path $gameRoot 'tools') 'decision_host') 'decision_host.tscn'
$godotBin = Get-CanonicalGodotEditorExecutable -RepoRoot $repoRoot
Assert-CanonicalGodotExecutable -GodotPath $godotBin | Out-Null

if (-not (Test-Path -LiteralPath $scenePath -PathType Leaf)) {
    throw "Required Decision Host scene is missing: $scenePath"
}

& $godotBin --path $gameRoot --scene 'res://tools/decision_host/decision_host.tscn'
