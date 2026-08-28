# Godot project contract

This folder is the Godot 4.7 game project.

The canonical product and simulation specifications are under `../docs`.

Implementation work must follow the owning specification.

Simulation code must follow `simulation/AGENTS.md`.

Developer simulation tools must follow their local `AGENTS.md` files.

## Runtime and project shape

- Use the standard, non-.NET Godot 4.7.2 build from the repository-root `AGENTS.md` contract and keep `project.godot` directly in this folder.
- `scenes/sdf_render_harness.tscn` is the normal runnable main scene and the automated capture harness.
- The primary render proof is a compute-shader SDF pipeline. Forward+ and the main `RenderingDevice` are required; missing compute support is fatal.
- Keep renderer implementation under `renderer/sdf`. Keep HUD, input, capture orchestration, and gameplay state outside that directory.
- The former mesh/GLB harness remains only as a comparison artifact. Do not silently invoke it when the SDF pipeline fails.
- `scenes/campus_blockout.tscn` is the native Godot blockout for the first Company Campus composition.
- The campus blockout must use `PrimitiveMesh` geometry. It must not load a Blender or GLB campus asset.
- Repeated round-crown trees must instance `scenes/round_tree.tscn`.
- Repeated fir trees must instance `scenes/fir_tree.tscn`.
- Do not duplicate round-crown or fir mesh nodes in `campus_blockout.tscn`.
- The campus blockout must use a 0.2 m voxel grid for `PrimitiveMesh` sizes and mesh node origins.
- A box, cylinder, or sphere extent must land on the 0.2 m grid. Do not keep off-grid sizes or origins for visual tuning.
- A rectangular frame must use `BoxOutlineMesh`. Do not author four box nodes for one outline.
- Follow `../docs/tools/editor-primitives.md` for editor primitive meshes and handles.
- `scenes/campus_blockout.tscn` must serialize its geometry, materials, lights, environment, and camera.
- The `CampusBlockout` root must not have a script.
- A designer must be able to select and edit each campus node in the Godot scene editor.
- `tools/snap_campus_blockout_voxel_grid.py` is a one-shot archive. It must not run in the editor scene or at runtime.
- `scenes/campus_blockout_capture.tscn` and `scripts/campus_blockout_capture.gd` own automated blockout capture.
- `tools/campus_blockout_bake_source.gd` is an unreferenced archive. It must not run in the editor scene or at runtime.
- The campus blockout is independent of the SDF render proof. A failure in one proof must not invoke the other proof.
- Keep automated capture deterministic: fixed state names, fixed viewport, fixed camera, fixed palette, bounded frame warm-up, explicit PNG paths, and a process exit code.
- Keep editor primitive meshes under `primitives`. Keep editor handles under `addons/editor_primitives`.

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

- Frame at exactly 1920×1080 (16:9). The SDF proof renders internally at 640×360 and scales once through a `Texture2DRD`; changing either resolution requires updating the shader, harness, script, documentation, and inspected evidence together.
- Keep a fixed orthographic isometric/three-quarter gameplay camera. Camera changes require regenerating and inspecting all evidence images.
- Preserve the palette-lit architectural-diorama direction: strong silhouettes, simplified/faceted masses, window rhythms, roof profiles, cooling shapes, fences, and controlled emissive/status accents.
- The world/map is the primary visual surface. UI in the harness is limited to title, renderer contract, state, description, and controls.
- Keep the HUD on `CanvasLayer` layer 100 so world/UI ordering is explicit. World SDF geometry must never be changed or hidden to repair HUD layout.
- Do not use painted textures in this proof. Shape, palette, normals, soft shadow, and ambient occlusion carry the look.
- Use `../docs/concept-art/main-lab-site-context-v1.png` as the visual target for the first Company Campus blockout.
- The blockout must preserve the central laboratory mass, teal glass facade, orange core, roof equipment, parking lot, perimeter roads, paths, walls, landscape, and site lights.

## Renderer and state contract

- `renderer/sdf/campus_sdf.glsl` owns analytic distance fields, state geometry, ray marching, normals, lighting, and material evaluation.
- `renderer/sdf/sdf_renderer.gd` owns the main RenderingDevice resources and render-on-change compute dispatch. It must remain independent of HUD and capture code.
- `scripts/sdf_render_harness.gd` owns presentation, keyboard input, deterministic capture, and output validation.
- The contract states are `growth=0`, `overload=1`, and `scrutiny=2`. Each must alter real SDF geometry and remain visually distinguishable on the common campus.
- The main output texture must be created by the main RenderingDevice and exposed through `Texture2DRD`. A local RenderingDevice cannot satisfy this contract because its resources are not shareable with the main renderer.
- This first renderer deliberately uses analytic CSG evaluated in the compute shader. Sparse brick caches, clipmaps, incremental dirty regions, physics meshes, and arbitrary runtime sculpting are later experiments, not implicit requirements.

## Mesh asset library

- `../model-pipeline/source/campus_modular_kit.blend` is the one authoring file. Open it with `scripts/open-campus-kit`. Publish it with `scripts/export-campus-kit`.
- `../model-pipeline/manifest/assets.json` lists the export collections and GLB paths.
- Files under `assets/generated` are owned by Blender export. Do not hand-edit them.
- The comparison harness loads `res://assets/generated/asset_catalog.json`. The SDF renderer does not load or fall back to those assets.
- The SDF render test does not regenerate Blender assets.

## Verification

From the repository root on Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\render-test.ps1
```

From the repository root on macOS, run:

```bash
./scripts/render-test.sh
```

Success requires the standard non-.NET Godot runtime, a clean Godot import, a real Forward+ RenderingDevice, `SDF_RENDERER_INITIALIZED`, three `SDF_DISPATCH_SUBMITTED` records, `SDF_RENDER_TEST_SUCCESS`, and non-empty 1920×1080 images under `game/evidence/sdf`. Windows must use D3D12. macOS must use Metal. Inspect every PNG after any visual, camera, material, shader, dispatch, texture, or presentation change.

Run the Company Campus blockout verification on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\render-campus-blockout.ps1
```

Run the Company Campus blockout verification on macOS:

```bash
./scripts/render-campus-blockout.sh
```

Success requires `CAMPUS_BLOCKOUT_SCENE_LOADED`, `CAMPUS_BLOCKOUT_CAPTURE_SUCCESS`, `CAMPUS_BLOCKOUT_COMPARISON_SUCCESS`, and `CAMPUS_BLOCKOUT_COMMAND_SUCCESS`.

Success requires a non-empty 1920×1080 image at `game/evidence/blockout/main_lab.png`.

Success requires a non-empty side-by-side comparison at `game/evidence/blockout/main_lab_comparison.png`.

Run the editor primitive tests on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\editor-primitives-test.ps1
```

Run the editor primitive tests on macOS:

```bash
./scripts/editor-primitives-test.sh
```

Success requires `BOX_OUTLINE_MESH_TEST_SUCCESS`.

Gameplay verification must also follow `../docs/simulation/invariants.md` after Simulation Core implementation starts.

## No fallbacks as fixes

Fix broken contracts at their source. Do not add alternate shader paths, permissive defaults, silent recovery, mesh or canvas substitutes, catch-all state names, or renderer substitutions that make missing compute support look successful. Fail clearly with the invalid state, resource, dimension, shader, or device.
