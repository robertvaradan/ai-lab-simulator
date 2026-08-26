# Godot project contract

This folder is the Godot 4.7 game project.

The canonical product and simulation specifications are under `../docs`.

Implementation work must follow the owning specification.

Simulation code must follow `simulation/AGENTS.md`.

Developer simulation tools must follow their local `AGENTS.md` files.

## Runtime and project shape

- Use the standard, non-.NET Godot 4.7.2 build at `<repository-root>\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64.exe` and keep `project.godot` directly in this folder. The repository-root `AGENTS.md` owns the executable contract.
- `scenes/sdf_render_harness.tscn` is the normal runnable main scene and the automated capture harness.
- The primary render proof is a compute-shader SDF pipeline. Forward+ and the main `RenderingDevice` are required; missing compute support is fatal.
- Keep renderer implementation under `renderer/sdf`. Keep HUD, input, capture orchestration, and gameplay state outside that directory.
- The former mesh/GLB harness remains only as a comparison artifact. Do not silently invoke it when the SDF pipeline fails.
- Keep automated capture deterministic: fixed state names, fixed viewport, fixed camera, fixed palette, bounded frame warm-up, explicit PNG paths, and a process exit code.

## GDScript typing

- All GDScript declarations must use static types.
- Public state fields, function parameters, and return values must use explicit type annotations.
- A local declaration can use type inference only when the compiler resolves a non-Variant static type.
- Project settings must treat untyped declarations and unsafe type operations as errors.
- Do not suppress a type warning to bypass an invalid contract.

## Custom Resource construction

- A custom state `Resource` must have a parameterless `_init()` method.
- A factory or loader can populate a temporarily incomplete custom state `Resource`.
- The custom state `Resource` must pass explicit validation before it enters a Game State or Simulation Host.
- A Simulation Host must reject unvalidated state.
- A default property value must not make missing required data valid.
- Construction and hydration must remain separate from validated runtime admission.
- Do not add fallback recovery for invalid state.

## Visual contract

- Frame at exactly 1280×720 (16:9). The SDF proof renders internally at 640×360 and scales once through a `Texture2DRD`; changing either resolution requires updating the shader, harness, script, documentation, and inspected evidence together.
- Keep a fixed orthographic isometric/three-quarter gameplay camera. Camera changes require regenerating and inspecting all evidence images.
- Preserve the palette-lit architectural-diorama direction: strong silhouettes, simplified/faceted masses, window rhythms, roof profiles, cooling shapes, fences, and controlled emissive/status accents.
- The world/map is the primary visual surface. UI in the harness is limited to title, renderer contract, state, description, and controls.
- Keep the HUD on `CanvasLayer` layer 100 so world/UI ordering is explicit. World SDF geometry must never be changed or hidden to repair HUD layout.
- Do not use painted textures in this proof. Shape, palette, normals, soft shadow, and ambient occlusion carry the look.

## Renderer and state contract

- `renderer/sdf/campus_sdf.glsl` owns analytic distance fields, state geometry, ray marching, normals, lighting, and material evaluation.
- `renderer/sdf/sdf_renderer.gd` owns the main RenderingDevice resources and render-on-change compute dispatch. It must remain independent of HUD and capture code.
- `scripts/sdf_render_harness.gd` owns presentation, keyboard input, deterministic capture, and output validation.
- The contract states are `growth=0`, `overload=1`, and `scrutiny=2`. Each must alter real SDF geometry and remain visually distinguishable on the common campus.
- The main output texture must be created by the main RenderingDevice and exposed through `Texture2DRD`. A local RenderingDevice cannot satisfy this contract because its resources are not shareable with the main renderer.
- This first renderer deliberately uses analytic CSG evaluated in the compute shader. Sparse brick caches, clipmaps, incremental dirty regions, physics meshes, and arbitrary runtime sculpting are later experiments, not implicit requirements.

## Legacy mesh assets

- `../model-pipeline/manifest/assets.json` remains the source of truth for the Blender/GLB comparison kit.
- Generated files under `assets/generated` are owned by the Blender generator and must not be hand-edited.
- The SDF renderer does not load or fall back to those assets.

## Verification

From the repository root, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\render-test.ps1
```

Success requires the standard non-.NET Godot runtime, a clean Godot import, a real D3D12 Forward+ device, `SDF_RENDERER_INITIALIZED`, three `SDF_DISPATCH_SUBMITTED` records, `SDF_RENDER_TEST_SUCCESS`, and non-empty 1280×720 images under `game/evidence/sdf`. Inspect every PNG after any visual, camera, material, shader, dispatch, texture, or presentation change.

Gameplay verification must also follow `../docs/simulation/invariants.md` after Simulation Core implementation starts.

## No fallbacks as fixes

Fix broken contracts at their source. Do not add alternate shader paths, permissive defaults, silent recovery, mesh or canvas substitutes, catch-all state names, or renderer substitutions that make missing compute support look successful. Fail clearly with the invalid state, resource, dimension, shader, or device.
