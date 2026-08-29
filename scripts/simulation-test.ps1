[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$stateTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'simulation') 'game_state_test.gd'
$publicationTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'simulation') 'game_state_publication_test.gd'
$cashLedgerTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'simulation') 'cash_ledger_test.gd'
$simulationCoreTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'simulation') 'simulation_core_test.gd'
$planCommitmentTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'simulation') 'plan_commitment_test.gd'
$monthStepTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'simulation') 'month_step_test.gd'
$projectTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'simulation') 'project_lifecycle_test.gd'
$competitorTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'simulation') 'competitor_release_test.gd'

$godotVersion = Assert-CanonicalGodotExecutable -GodotPath $godotBin
foreach ($testScript in @($stateTestScript, $publicationTestScript, $cashLedgerTestScript, $simulationCoreTestScript, $planCommitmentTestScript, $monthStepTestScript, $projectTestScript, $competitorTestScript)) {
    if (-not (Test-Path -LiteralPath $testScript -PathType Leaf)) {
        throw "Required Simulation Core test script is missing: $testScript"
    }
}

Write-Output '[1/9] Importing the Godot 4.7 project'
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

function Invoke-SimulationTest {
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
        throw "Simulation Core test $ScriptPath failed with exit code $testExitCode."
    }
    if ($testOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
        throw "Simulation Core test $ScriptPath reported a script error."
    }
    if (-not $testOutput.Contains($SuccessMarker)) {
        throw "Simulation Core test $ScriptPath did not report success marker $SuccessMarker."
    }
}

Write-Output '[2/9] Running Game State and snapshot tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/game_state_test.gd' -SuccessMarker 'GAME_STATE_TEST_SUCCESS'

Write-Output '[3/9] Running committed Game State publication tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/game_state_publication_test.gd' -SuccessMarker 'GAME_STATE_PUBLICATION_TEST_SUCCESS'

Write-Output '[4/9] Running Cash Ledger tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/cash_ledger_test.gd' -SuccessMarker 'CASH_LEDGER_TEST_SUCCESS'

Write-Output '[5/9] Running Rule registry, Simulation Context, and Simulation Core tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/simulation_core_test.gd' -SuccessMarker 'SIMULATION_CORE_TEST_SUCCESS'

Write-Output '[6/9] Running Plan validation and commitment tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/plan_commitment_test.gd' -SuccessMarker 'PLAN_COMMITMENT_TEST_SUCCESS'

Write-Output '[7/9] Running Month Step and Quarter Boundary tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/month_step_test.gd' -SuccessMarker 'MONTH_STEP_TEST_SUCCESS'

Write-Output '[8/9] Running Marketing Scenario Project tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/project_lifecycle_test.gd' -SuccessMarker 'PROJECT_LIFECYCLE_TEST_SUCCESS'

Write-Output '[9/9] Running Competitor forecast and release tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/competitor_release_test.gd' -SuccessMarker 'COMPETITOR_RELEASE_TEST_SUCCESS'

Write-Output "SIMULATION_TEST_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet"
