# Godot project contract

This folder is the Godot 4.7 game project.

The canonical product and simulation specifications are under `../docs`.

Implementation work must follow the owning specification.

Simulation code must follow `simulation/AGENTS.md`.

Developer simulation tools must follow their local `AGENTS.md` files.

## Runtime and project shape

- Use the standard, non-.NET Godot 4.7.2 build from the repository-root `AGENTS.md` contract and keep `project.godot` directly in this folder.
- `scenes/sdf_render_harness.tscn` is the normal runnable main scene and the automated capture harness.
- `scenes/marketing_play.tscn` is the Marketing Slice production play scene. It instances the campus blockout as a sibling of the management overlay. Do not attach a script to the `CampusBlockout` root.
- The management overlay stages Research, Scale, and Coding Agent start Commands from player selection. It does not start a Project that already exists.
- The primary render proof is a compute-shader SDF pipeline. Forward+ and the main `RenderingDevice` are required; missing compute support is fatal.
- Keep renderer implementation under `renderer/sdf`. Keep HUD, input, capture orchestration, and gameplay state outside that directory.
- Keep the gameplay isometric camera under `camera`.
- Do not load a GLB campus asset. Do not add a Blender export pipeline.
- `scenes/campus_blockout.tscn` is the native Godot blockout for the first Company Campus composition.
- Follow `../docs/presentation/campus-authoring.md` for campus and laboratory scene authoring.
- The campus blockout must use `PrimitiveMesh` geometry.
- The campus blockout must instance one laboratory stage scene. Do not embed laboratory mesh nodes inline.
- `scenes/lab_stage_1.tscn` owns the starting laboratory. `scenes/lab_stage_2.tscn` owns the developed laboratory.
- Repeated round-crown trees must instance `scenes/round_tree.tscn`.
- Repeated fir trees must instance `scenes/fir_tree.tscn`.
- Do not duplicate round-crown or fir mesh nodes in `campus_blockout.tscn`.
- The campus blockout must use a 0.2 m voxel grid for `PrimitiveMesh` sizes and mesh node origins.
- A box, cylinder, or sphere extent must land on the 0.2 m grid. Do not keep off-grid sizes or origins for visual tuning.
- A rectangular frame must use `BoxOutlineMesh`. Do not author four box nodes for one outline.
- A cylindrical frame must use `CylinderOutlineMesh`. Do not author a stack of cylinder nodes for one outline.
- Follow `../docs/tools/editor-primitives.md` for editor primitive meshes and handles.
- Named campus colors must live in `visual/campus_palette.tres` as a `VisualPalette` Resource. Follow `../docs/visual/color-palette.md`.
- Campus materials must live under `materials` and must use palette role colors. Do not inline role colors in `campus_blockout.tscn`.
- Keep campus vegetation shaders under `shaders`.
- Grass meshes must use `materials/grass.tres` or `materials/grass_cut.tres`.
- Hedge meshes must use `materials/hedge.tres`.
- Tree crown meshes must use `materials/tree_foliage_a.tres` or `materials/tree_foliage_b.tres`.
- Tree trunks must use `materials/trunk.tres`.
- A vegetation material must use one albedo color from one palette role.
- A vegetation material must not interpolate albedo colors and must not add noise into albedo.
- Vegetation depth must come from lighting and procedural triplanar normals. Do not depend on mesh UVs for vegetation.
- Hedge and tree crowns must share `shaders/foliage.gdshader`.
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
- Keep an orthographic isometric gameplay camera. The camera must not rotate. The player can pan and zoom. Follow `../docs/presentation/isometric-camera.md`.
- Keep camera implementation under `camera`. Automated campus capture must disable camera input and snap to the authored pose.
- Keep the SDF proof camera fixed. A pose, material, shader, dispatch, texture, or presentation change requires regenerating and inspecting all evidence images.
- Preserve the palette-lit architectural-diorama direction: strong silhouettes, simplified/faceted masses, window rhythms, roof profiles, cooling shapes, fences, and controlled emissive/status accents.
- The world/map is the primary visual surface. UI in the harness is limited to title, renderer contract, state, description, and controls.
- Keep the HUD on `CanvasLayer` layer 100 so world/UI ordering is explicit. World SDF geometry must never be changed or hidden to repair HUD layout.
- Do not use painted textures in this proof. Shape, palette, normals, soft shadow, and ambient occlusion carry the look.
- Campus grass must look soft, even, and velvety. Campus hedges and tree crowns must share foliage shading with deeper lit contrast from normals and lighting.
- Vegetation shading must use one palette albedo and procedural triplanar normals. Do not require authored mesh UVs for grass, hedges, or tree crowns.
- Use `../docs/concept-art/main-lab-site-context-v1.png` as the visual target for the developed Company Campus site.
- Use `../docs/concept-art/main-lab-concept-v1.png` as the visual target for laboratory stage 2.
- The blockout must preserve parking, perimeter roads, paths, walls, landscape, and site lights around the instanced laboratory stage.

## Renderer and state contract

- `renderer/sdf/campus_sdf.glsl` owns analytic distance fields, state geometry, ray marching, normals, lighting, and material evaluation.
- `renderer/sdf/sdf_renderer.gd` owns the main RenderingDevice resources and render-on-change compute dispatch. It must remain independent of HUD and capture code.
- `scripts/sdf_render_harness.gd` owns presentation, keyboard input, deterministic capture, and output validation.
- The contract states are `growth=0`, `overload=1`, and `scrutiny=2`. Each must alter real SDF geometry and remain visually distinguishable on the common campus.
- The main output texture must be created by the main RenderingDevice and exposed through `Texture2DRD`. A local RenderingDevice cannot satisfy this contract because its resources are not shareable with the main renderer.
- This first renderer deliberately uses analytic CSG evaluated in the compute shader. Sparse brick caches, clipmaps, incremental dirty regions, physics meshes, and arbitrary runtime sculpting are later experiments, not implicit requirements.

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

Success requires `CYLINDER_OUTLINE_MESH_TEST_SUCCESS`.

Run the isometric camera tests on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\isometric-camera-test.ps1
```

Run the isometric camera tests on macOS:

```bash
./scripts/isometric-camera-test.sh
```

Success requires `ISOMETRIC_CAMERA_TEST_SUCCESS`.

Gameplay verification must also follow `../docs/simulation/invariants.md` after Simulation Core implementation starts.

## No fallbacks as fixes

Fix broken contracts at their source. Do not add alternate shader paths, permissive defaults, silent recovery, mesh or canvas substitutes, catch-all state names, or renderer substitutions that make missing compute support look successful. Fail clearly with the invalid state, resource, dimension, shader, or device.
