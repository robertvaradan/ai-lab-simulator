[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\blender-standard.ps1')

if ((Get-BlenderHostPlatform) -ne 'windows') {
    throw 'Use scripts/open-campus-kit.sh on macOS.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$blenderBin = Get-CanonicalBlenderExecutable
Assert-CanonicalBlenderExecutable -BlenderPath $blenderBin | Out-Null
$blend = Join-Path (Join-Path (Join-Path $repoRoot 'model-pipeline') 'source') 'campus_modular_kit.blend'
$openScript = Join-Path (Join-Path (Join-Path $repoRoot 'model-pipeline') 'scripts') 'open_authoring.py'
if (-not (Test-Path -LiteralPath $blend -PathType Leaf)) {
    throw "Authoring file is missing: $blend"
}
if (-not (Test-Path -LiteralPath $openScript -PathType Leaf)) {
    throw "Required authoring script is missing: $openScript"
}

& $blenderBin --python-exit-code 1 $blend --python $openScript -- --repo-root $repoRoot
if ($LASTEXITCODE -ne 0) {
    throw "Campus kit authoring launch failed with exit code $LASTEXITCODE."
}
