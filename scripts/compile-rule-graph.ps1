[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$artifactTestScript = Join-Path (Join-Path (Join-Path $gameRoot 'tests') 'tools') 'rule_graph_artifact_test.gd'
$compilerScript = Join-Path (Join-Path (Join-Path $gameRoot 'tools') 'rule_graph') 'compile_marketing_rule_graph.gd'

$godotVersion = Assert-CanonicalGodotExecutable -GodotPath $godotBin
foreach ($requiredFile in @($artifactTestScript, $compilerScript)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required Rule Graph file is missing: $requiredFile"
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

function Invoke-GraphScript {
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
        throw "Rule Graph script $ScriptPath failed with exit code $testExitCode."
    }
    if ($testOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
        throw "Rule Graph script $ScriptPath reported a script error."
    }
    if (-not $testOutput.Contains($SuccessMarker)) {
        throw "Rule Graph script $ScriptPath did not report success marker $SuccessMarker."
    }
}

Write-Output '[2/3] Running Rule Graph artifact tests'
Invoke-GraphScript -ScriptPath 'res://tests/tools/rule_graph_artifact_test.gd' -SuccessMarker 'RULE_GRAPH_ARTIFACT_TEST_SUCCESS'

Write-Output '[3/3] Exporting the Marketing Scenario Rule Graph artifact'
Invoke-GraphScript -ScriptPath 'res://tools/rule_graph/compile_marketing_rule_graph.gd' -SuccessMarker 'RULE_GRAPH_COMPILE_SUCCESS'

Write-Output "RULE_GRAPH_COMPILE_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet"
