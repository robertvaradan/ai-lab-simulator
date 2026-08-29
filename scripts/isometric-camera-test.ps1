[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$cameraTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'camera') 'isometric_camera_test.gd'

$godotVersion = Assert-CanonicalGodotExecutable -GodotPath $godotBin
if (-not (Test-Path -LiteralPath $cameraTestScript -PathType Leaf)) {
    throw "Required isometric camera test script is missing: $cameraTestScript"
}

function Test-GodotScriptError {
    param(
        [Parameter(Mandatory = $true)][string]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )
    if ($Output -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
        throw "$Context reported a script error."
    }
}

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
Test-GodotScriptError -Output $importOutput -Context 'Godot import'

Write-Output '[2/2] Running IsometricCamera contract tests'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $testOutputLines = @(
        & $godotBin --headless --path $gameRoot --quit-after 30 --script 'res://tests/camera/isometric_camera_test.gd' 2>&1
    )
    $testExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$testOutput = $testOutputLines -join [Environment]::NewLine
Write-Output $testOutput
if ($testExitCode -ne 0) {
    throw "The isometric camera test failed with exit code $testExitCode."
}
Test-GodotScriptError -Output $testOutput -Context 'The isometric camera test'
if (-not $testOutput.Contains('ISOMETRIC_CAMERA_TEST_SUCCESS')) {
    throw 'The isometric camera test did not report the required success marker.'
}

Write-Output "ISOMETRIC_CAMERA_TEST_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet"
