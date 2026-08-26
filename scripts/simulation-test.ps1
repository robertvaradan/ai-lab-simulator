[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Join-Path $repoRoot '.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$stateTestScript = Join-Path $gameRoot 'tests\simulation\game_state_test.gd'
$publicationTestScript = Join-Path $gameRoot 'tests\simulation\game_state_publication_test.gd'
$cashLedgerTestScript = Join-Path $gameRoot 'tests\simulation\cash_ledger_test.gd'
$simulationCoreTestScript = Join-Path $gameRoot 'tests\simulation\simulation_core_test.gd'

if (-not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    throw "Required canonical Godot executable is missing: $godotBin. Run scripts\install-godot-standard.ps1."
}
foreach ($testScript in @($stateTestScript, $publicationTestScript, $cashLedgerTestScript, $simulationCoreTestScript)) {
    if (-not (Test-Path -LiteralPath $testScript -PathType Leaf)) {
        throw "Required Simulation Core test script is missing: $testScript"
    }
}

$godotVersion = (& $godotBin --version | Select-Object -First 1).Trim()
if (-not $godotVersion.StartsWith('4.7.2.stable')) {
    throw "Godot 4.7.2 stable is required; executable reported '$godotVersion'."
}
if ($godotVersion -match '(?i)(mono|\.net)') {
    throw "The standard non-.NET Godot runtime is required; executable reported '$godotVersion'."
}

Write-Output '[1/5] Importing the Godot 4.7 project'
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

Write-Output '[2/5] Running Game State and snapshot tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/game_state_test.gd' -SuccessMarker 'GAME_STATE_TEST_SUCCESS'

Write-Output '[3/5] Running committed Game State publication tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/game_state_publication_test.gd' -SuccessMarker 'GAME_STATE_PUBLICATION_TEST_SUCCESS'

Write-Output '[4/5] Running Cash Ledger tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/cash_ledger_test.gd' -SuccessMarker 'CASH_LEDGER_TEST_SUCCESS'

Write-Output '[5/5] Running Rule registry, Simulation Context, and Simulation Core tests'
Invoke-SimulationTest -ScriptPath 'res://tests/simulation/simulation_core_test.gd' -SuccessMarker 'SIMULATION_CORE_TEST_SUCCESS'

Write-Output "SIMULATION_TEST_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet"
