[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$boxTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'primitives') 'box_outline_mesh_test.gd'
$cylinderTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'primitives') 'cylinder_outline_mesh_test.gd'

$godotVersion = Assert-CanonicalGodotExecutable -GodotPath $godotBin
if (-not (Test-Path -LiteralPath $boxTestScript -PathType Leaf)) {
    throw "Required editor primitive test script is missing: $boxTestScript"
}
if (-not (Test-Path -LiteralPath $cylinderTestScript -PathType Leaf)) {
    throw "Required editor primitive test script is missing: $cylinderTestScript"
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

function Invoke-PrimitiveTest {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$Marker,
        [Parameter(Mandatory = $true)][string]$Label
    )
    Write-Output "Running ${Label} contract tests"
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $testOutputLines = @(
            & $godotBin --headless --path $gameRoot --quit-after 30 --script $ScriptPath 2>&1
        )
        $testExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $testOutput = $testOutputLines -join [Environment]::NewLine
    Write-Output $testOutput
    if ($testExitCode -ne 0) {
        throw "The ${Label} test failed with exit code $testExitCode."
    }
    Test-GodotScriptError -Output $testOutput -Context "The ${Label} test"
    if (-not $testOutput.Contains($Marker)) {
        throw "The ${Label} test did not report the required success marker."
    }
}

Write-Output '[1/3] Importing the Godot 4.7 project'
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

Write-Output '[2/3] Running BoxOutlineMesh contract tests'
Invoke-PrimitiveTest -ScriptPath 'res://tests/primitives/box_outline_mesh_test.gd' -Marker 'BOX_OUTLINE_MESH_TEST_SUCCESS' -Label 'BoxOutlineMesh'

Write-Output '[3/3] Running CylinderOutlineMesh contract tests'
Invoke-PrimitiveTest -ScriptPath 'res://tests/primitives/cylinder_outline_mesh_test.gd' -Marker 'CYLINDER_OUTLINE_MESH_TEST_SUCCESS' -Label 'CylinderOutlineMesh'

Write-Output "EDITOR_PRIMITIVES_TEST_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet"
