[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$testScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'primitives') 'box_outline_mesh_test.gd'

$godotVersion = Assert-CanonicalGodotExecutable -GodotPath $godotBin
if (-not (Test-Path -LiteralPath $testScript -PathType Leaf)) {
    throw "Required editor primitive test script is missing: $testScript"
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

Write-Output '[2/2] Running BoxOutlineMesh contract tests'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $testOutputLines = @(
        & $godotBin --headless --path $gameRoot --quit-after 30 --script 'res://tests/primitives/box_outline_mesh_test.gd' 2>&1
    )
    $testExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$testOutput = $testOutputLines -join [Environment]::NewLine
Write-Output $testOutput
if ($testExitCode -ne 0) {
    throw "The editor primitive test failed with exit code $testExitCode."
}
Test-GodotScriptError -Output $testOutput -Context 'The editor primitive test'
if (-not $testOutput.Contains('BOX_OUTLINE_MESH_TEST_SUCCESS')) {
    throw 'The editor primitive test did not report the required success marker.'
}

Write-Output "EDITOR_PRIMITIVES_TEST_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet"
