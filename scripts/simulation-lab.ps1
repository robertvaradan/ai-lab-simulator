[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$labTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'tools') 'simulation_lab_test.gd'
$labRunnerScript = Join-Path (Join-Path (Join-Path $gameRoot 'tools') 'simulation_lab') 'run_marketing_scenario.gd'

$godotVersion = Assert-CanonicalGodotExecutable -GodotPath $godotBin
foreach ($requiredFile in @($labTestScript, $labRunnerScript)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required Simulation Laboratory file is missing: $requiredFile"
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
if ($importOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
    throw 'Godot import reported a script error.'
}

function Invoke-LabScript {
    param(
        [string]$ScriptPath,
        [string]$SuccessMarker
    )

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
        throw "Simulation Laboratory script $ScriptPath failed with exit code $testExitCode."
    }
    if ($testOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
        throw "Simulation Laboratory script $ScriptPath reported a script error."
    }
    if (-not $testOutput.Contains($SuccessMarker)) {
        throw "Simulation Laboratory script $ScriptPath did not report success marker $SuccessMarker."
    }
}

Write-Output '[2/3] Running Simulation Laboratory tests'
Invoke-LabScript -ScriptPath 'res://tests/tools/simulation_lab_test.gd' -SuccessMarker 'SIMULATION_LAB_TEST_SUCCESS'

Write-Output '[3/3] Running the Marketing Scenario in the Simulation Laboratory'
Invoke-LabScript -ScriptPath 'res://tools/simulation_lab/run_marketing_scenario.gd' -SuccessMarker 'SIMULATION_LAB_RUN_SUCCESS'

Write-Output "SIMULATION_LAB_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet"
