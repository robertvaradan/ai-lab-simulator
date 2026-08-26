# Model pipeline

The pipeline deterministically authors a compact campus kit in Blender 5.1 and exports it as one glTF scene for Godot. The one scene contains persistent `Base__` objects and three independently toggleable dressing layers: `Growth__`, `Overload__`, and `Scrutiny__`.

Run from the repository root:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe' --background --factory-startup --python .\model-pipeline\scripts\generate_assets.py -- --repo-root (Resolve-Path .)
```

The command rewrites the generator-owned `.blend` and `.glb` outputs. It performs contract validation and exits non-zero if Blender, metadata, materials, layers, or outputs disagree.

