[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\godot-standard.ps1')

$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Get-CanonicalGodotAutomationExecutable -RepoRoot $repoRoot
$godotVersion = Assert-CanonicalGodotExecutable -GodotPath $godotBin
$scenePath = Join-Path (Join-Path $gameRoot 'scenes') 'campus_blockout.tscn'
$captureScenePath = Join-Path (Join-Path $gameRoot 'scenes') 'campus_blockout_capture.tscn'
$captureScriptPath = Join-Path (Join-Path $gameRoot 'scripts') 'campus_blockout_capture.gd'
$evidenceDirectory = Join-Path (Join-Path $gameRoot 'evidence') 'blockout'
$evidencePath = Join-Path $evidenceDirectory 'main_lab.png'
$comparisonPath = Join-Path $evidenceDirectory 'main_lab_comparison.png'

foreach ($requiredPath in @($scenePath, $captureScenePath, $captureScriptPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required campus blockout source is missing: $requiredPath"
    }
}

New-Item -ItemType Directory -Force -Path $evidenceDirectory | Out-Null
Remove-Item -LiteralPath $evidencePath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "$evidencePath.import" -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $comparisonPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "$comparisonPath.import" -Force -ErrorAction SilentlyContinue

Write-Output '[1/2] Importing the native Godot campus blockout'
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

Write-Output '[2/2] Rendering the fixed 1920x1080 campus blockout'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $renderOutputLines = @(
        & $godotBin `
            --path $gameRoot `
            --resolution 1920x1080 `
            --quit-after 900 `
            'res://scenes/campus_blockout_capture.tscn' `
            -- `
            --render-blockout `
            --output-path $evidencePath 2>&1
    )
    $renderExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$renderOutput = $renderOutputLines -join [Environment]::NewLine
Write-Output $renderOutput
if ($renderExitCode -ne 0) {
    throw "Campus blockout render failed with exit code $renderExitCode."
}
if ($renderOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
    throw 'Campus blockout render reported a script error.'
}
if (-not $renderOutput.Contains('CAMPUS_BLOCKOUT_SCENE_LOADED')) {
    throw 'Campus blockout render did not load the script-free editable scene.'
}
if (-not $renderOutput.Contains('CAMPUS_BLOCKOUT_CAPTURE_SUCCESS')) {
    throw 'Campus blockout render did not report the required success marker.'
}
if (-not $renderOutput.Contains('CAMPUS_BLOCKOUT_COMPARISON_SUCCESS')) {
    throw 'Campus blockout render did not report the required comparison marker.'
}
if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
    throw "Campus blockout render did not create expected evidence: $evidencePath"
}
$evidenceBytes = (Get-Item -LiteralPath $evidencePath).Length
if ($evidenceBytes -lt 40000) {
    throw "Campus blockout evidence PNG is implausibly small ($evidenceBytes bytes): $evidencePath"
}
if (-not (Test-Path -LiteralPath $comparisonPath -PathType Leaf)) {
    throw "Campus blockout render did not create expected comparison: $comparisonPath"
}
$comparisonBytes = (Get-Item -LiteralPath $comparisonPath).Length
if ($comparisonBytes -lt 40000) {
    throw "Campus comparison PNG is implausibly small ($comparisonBytes bytes): $comparisonPath"
}

Write-Output "CAMPUS_BLOCKOUT_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet size=1920x1080 bytes=$evidenceBytes evidence=$evidencePath comparison_bytes=$comparisonBytes comparison=$comparisonPath"
