[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$godotVersion = Assert-CanonicalGodotExecutable -GodotPath $godotBin
$captureScene = Join-Path (Join-Path $gameRoot 'scenes') 'panel_system_capture.tscn'
$evidenceRoot = Join-Path (Join-Path $gameRoot 'evidence') 'panel_system'

if (-not (Test-Path -LiteralPath $captureScene -PathType Leaf)) {
    throw "Required panel system capture scene is missing: $captureScene"
}

New-Item -ItemType Directory -Force -Path $evidenceRoot | Out-Null
Get-ChildItem -LiteralPath $evidenceRoot -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

Write-Output '[1/2] Importing the Godot 4.7 project'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $importOutputLines = @(& $godotBin --headless --editor --path $gameRoot --import --quit 2>&1)
    $importExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$importOutput = $importOutputLines -join [Environment]::NewLine
Write-Output $importOutput
if ($importExitCode -ne 0) {
    throw "Godot import failed with exit code $importExitCode."
}
if ($importOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
    throw 'Godot import reported a script error.'
}

Write-Output '[2/2] Capturing Campaign Panel System views'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $captureOutputLines = @(
        & $godotBin `
            --path $gameRoot `
            --resolution 1920x1080 `
            --quit-after 1200 `
            'res://scenes/panel_system_capture.tscn' `
            -- `
            --render-panel-system `
            --output-root $evidenceRoot 2>&1
    )
    $captureExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$captureOutput = $captureOutputLines -join [Environment]::NewLine
Write-Output $captureOutput
if ($captureExitCode -ne 0) {
    throw "Panel system capture failed with exit code $captureExitCode."
}
if ($captureOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
    throw 'Panel system capture reported a script error.'
}
if (-not $captureOutput.Contains('PANEL_SYSTEM_CAPTURE_SUCCESS')) {
    throw 'Panel system capture did not report success.'
}

Write-Output "PANEL_SYSTEM_CAPTURE_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet"
