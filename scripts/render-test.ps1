[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot 'game'
$godotBin = Join-Path $repoRoot '.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$shaderPath = Join-Path $gameRoot 'renderer\sdf\campus_sdf.glsl'
$rendererPath = Join-Path $gameRoot 'renderer\sdf\sdf_renderer.gd'
$harnessPath = Join-Path $gameRoot 'scripts\sdf_render_harness.gd'
$evidenceRoot = Join-Path $gameRoot 'evidence\sdf'

if (-not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    throw "Required canonical Godot executable is missing: $godotBin. Run scripts\install-godot-standard.ps1."
}
foreach ($requiredPath in @($shaderPath, $rendererPath, $harnessPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required SDF pipeline source is missing: $requiredPath"
    }
}

$godotVersion = (& $godotBin --version | Select-Object -First 1).Trim()
if (-not $godotVersion.StartsWith('4.7.2.stable')) {
    throw "Godot 4.7.2 stable is required; executable reported '$godotVersion'."
}
if ($godotVersion -match '(?i)(mono|\.net)') {
    throw "The standard non-.NET Godot runtime is required; executable reported '$godotVersion'."
}

New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
$stateNames = @('growth', 'overload', 'scrutiny')
foreach ($state in $stateNames) {
    $outputPath = Join-Path $evidenceRoot "$state.png"
    foreach ($generatedPath in @($outputPath, "$outputPath.import")) {
        if (Test-Path -LiteralPath $generatedPath) {
            Remove-Item -LiteralPath $generatedPath -Force
        }
    }
}

Write-Output '[1/2] Importing the Godot 4.7 project and compute shader'
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

Write-Output '[2/2] Dispatching the compute-SDF renderer and capturing three 1280x720 states'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $renderOutputLines = @(
        & $godotBin --path $gameRoot --resolution 1280x720 --quit-after 900 -- --render-all --output-dir $evidenceRoot 2>&1
    )
    $renderExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$renderOutput = $renderOutputLines -join [Environment]::NewLine
Write-Output $renderOutput
if ($renderExitCode -ne 0) {
    throw "Godot SDF render test failed with exit code $renderExitCode."
}
if ($renderOutput -match '(?m)(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script)') {
    throw 'Godot SDF render test reported a script error.'
}
if (-not $renderOutput.Contains('SDF_RENDERER_INITIALIZED')) {
    throw 'Godot SDF render test did not initialize the compute renderer.'
}
if ([regex]::Matches($renderOutput, 'SDF_DISPATCH_SUBMITTED').Count -ne 3) {
    throw 'Godot SDF render test did not submit exactly three dispatches.'
}
if (-not $renderOutput.Contains('SDF_RENDER_TEST_SUCCESS')) {
    throw 'Godot SDF render test did not report the required success marker.'
}

foreach ($state in $stateNames) {
    $outputPath = Join-Path $evidenceRoot "$state.png"
    if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
        throw "SDF render test did not create expected evidence: $outputPath"
    }
    $length = (Get-Item -LiteralPath $outputPath).Length
    if ($length -lt 40000) {
        throw "SDF evidence PNG is implausibly small ($length bytes): $outputPath"
    }
    Write-Output "SDF_RENDER_EVIDENCE state=$state bytes=$length path=$outputPath"
}

$rendererBytes = (Get-Item -LiteralPath $rendererPath).Length
$shaderBytes = (Get-Item -LiteralPath $shaderPath).Length
Write-Output "SDF_RENDER_TEST_COMMAND_SUCCESS godot=$godotVersion runtime=standard_non_dotnet internal=640x360 output=1280x720 renderer_bytes=$rendererBytes shader_bytes=$shaderBytes evidence=$evidenceRoot"
