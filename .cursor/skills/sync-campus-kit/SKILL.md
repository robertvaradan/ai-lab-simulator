---
name: sync-campus-kit
description: Syncs the Blender campus authoring file into Godot mesh assets. Rebuilds Geometry Nodes groups, exports GLBs, and writes asset_catalog.json. Use when the user finishes Blender campus design, or asks to sync Blender into the game, export the campus kit, update game/assets/generated, publish kit meshes, or open the campus kit for authoring.
---

# Sync campus kit

The user designs campus meshes in Blender. The agent publishes that file into the game. The user must not run Blender CLI, enable add-ons, or sync node groups.

## Publish into the game

1. If Blender is open, tell the user to save `model-pipeline/source/campus_modular_kit.blend` once.
2. From the repository root, run the host script. Blender must run outside the sandbox (`required_permissions: ["all"]`).

macOS:

```bash
./scripts/export-campus-kit.sh
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-campus-kit.ps1
```

3. Require `PIPELINE_EXPORT_SUCCESS` in the output.
4. Report `asset_id` and `glbs`.
5. Do not hand-edit files under `game/assets/generated`.
6. If the output contains `ASSET_PIPELINE_ERROR`, fix the pipeline, manifest, Blender version, or authoring file. Do not add a fallback path.

## Open for design

When the user asks to open the campus kit, run the host script. Do not tell the user to add a Scripts path or enable the add-on.

macOS:

```bash
./scripts/open-campus-kit.sh
```

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\open-campus-kit.ps1
```

The command registers ALS Campus Kit, syncs Geometry Nodes groups, and opens the authoring file. The user only places pieces and changes modifier inputs.
