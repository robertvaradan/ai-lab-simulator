# Model pipeline

This pipeline owns one Blender 5.1 authoring file for the campus mesh kit.

Edit every asset in `source/campus_modular_kit.blend`. Place kit pieces and change Geometry Nodes inputs. Do not enable add-ons, sync node groups, or run Blender CLI.

The SDF main scene does not load these meshes.

Do not place trees in the campus source. Place trees later with scatter. Every export mesh must end with `ALS_ShadeContract`.

Viewport guide text sits in `Authoring__Labels`. Publish does not export that collection. Clear **Show Labels** in the ALS panel to hide the text.

## Design in Blender

Run from the repository root. The command registers ALS Campus Kit and syncs the tools.

macOS:

```bash
./scripts/open-campus-kit.sh
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\open-campus-kit.ps1
```

## Publish into the game

Save the authoring file if Blender is open. Then run this command, or tell the agent to sync the campus kit.

macOS:

```bash
./scripts/export-campus-kit.sh
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-campus-kit.ps1
```

The command syncs node groups, writes one GLB per collection under `game/assets/generated`, and writes `game/assets/generated/asset_catalog.json`. The command exits non-zero when Blender, the manifest, collections, names, materials, or outputs disagree.

## Create the file once

Run from the repository root. This command must fail when the `.blend` already exists.

macOS:

```bash
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python-exit-code 1 --python ./model-pipeline/scripts/export_assets.py -- --repo-root "$(pwd)" --mode bootstrap
```

Windows:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe' --background --factory-startup --python-exit-code 1 --python .\model-pipeline\scripts\export_assets.py -- --repo-root (Resolve-Path .) --mode bootstrap
```
