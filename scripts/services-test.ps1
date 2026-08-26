[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Join-Path $repoRoot '.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$testScript = Join-Path $gameRoot 'tests\services\services_test.gd'

if (-not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    throw "Required canonical Godot executable is missing: $godotBin. Run scripts\install-godot-standard.ps1."
}
if (-not (Test-Path -LiteralPath $testScript -PathType Leaf)) {
    throw "Required service test script is missing: $testScript"
}

$godotVersion = (& $godotBin --version | Select-Object -First 1).Trim()
if (-not $godotVersion.StartsWith('4.7.2.stable')) {
    throw "Godot 4.7.2 stable is required; executable reported '$godotVersion'."
}
if ($godotVersion -match '(?i)(mono|\.net)') {
    throw "The standard non-.NET Godot runtime is required; executable reported '$godotVersion'."
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

Write-Output '[2/3] Running the service lifecycle and injection test'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $positiveOutputLines = @(
        & $godotBin --headless --path $gameRoot --quit-after 30 --script 'res://tests/services/services_test.gd' -- --case positive 2>&1
    )
    $positiveExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$positiveOutput = $positiveOutputLines -join [Environment]::NewLine
Write-Output $positiveOutput
if ($positiveExitCode -ne 0) {
    throw "The positive service test failed with exit code $positiveExitCode."
}
if ($positiveOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
    throw 'The positive service test reported a script error.'
}
if (-not $positiveOutput.Contains('SERVICES_TEST_SUCCESS')) {
    throw 'The positive service test did not report the required success marker.'
}

Write-Output '[3/3] Running strict service-provider contract tests'
$negativeCases = @(
    'duplicate_registration',
    'missing_registration',
    'wrong_implementation_type',
    'wrong_service_context',
    'resolve_before_seal',
    'provide_after_seal'
)
foreach ($testCase in $negativeCases) {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $caseOutputLines = @(
            & $godotBin --headless --path $gameRoot --quit-after 30 --script 'res://tests/services/services_test.gd' -- --case $testCase 2>&1
        )
        $caseExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $caseOutput = $caseOutputLines -join [Environment]::NewLine
    Write-Output $caseOutput
    $expectedFailure = "SERVICE_CONTRACT_FAILURE code=$testCase"
    if (-not $caseOutput.Contains($expectedFailure)) {
        throw "The '$testCase' test did not report the expected contract failure."
    }
    if ($caseExitCode -eq 0) {
        throw "The invalid '$testCase' operation did not terminate the Godot process with a failure."
    }
    if ($caseOutput.Contains('SERVICES_TEST_NEGATIVE_CASE_ACCEPTED')) {
        throw "The service provider accepted the invalid '$testCase' operation."
    }
}

Write-Output "SERVICES_TEST_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet positive=1 negative=$($negativeCases.Count)"
