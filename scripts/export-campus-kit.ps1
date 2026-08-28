[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\blender-standard.ps1')

if ((Get-BlenderHostPlatform) -ne 'windows') {
    throw 'Use scripts/export-campus-kit.sh on macOS.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$blenderBin = Get-CanonicalBlenderExecutable
Assert-CanonicalBlenderExecutable -BlenderPath $blenderBin | Out-Null
$pipelineScript = Join-Path (Join-Path (Join-Path $repoRoot 'model-pipeline') 'scripts') 'export_assets.py'
if (-not (Test-Path -LiteralPath $pipelineScript -PathType Leaf)) {
    throw "Required pipeline script is missing: $pipelineScript"
}

& $blenderBin --background --factory-startup --python-exit-code 1 --python $pipelineScript -- --repo-root $repoRoot --mode export
if ($LASTEXITCODE -ne 0) {
    throw "Campus kit export failed with exit code $LASTEXITCODE."
}
