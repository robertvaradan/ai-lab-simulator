# AI Lab Simulator

This repository contains the canonical product specifications and an early compute-SDF render proof.

The [canonical specification index](docs/README.md) defines the game loop, domain model, progression, deterministic simulation, Rule Graph, Simulation Laboratory, and Marketing Slice.

The current runtime implementation still answers one narrow production question: can a solo-friendly, fixed-camera AI-campus management game use a lightweight signed-distance-field renderer to create a distinctive, geometry-first look inside Godot?

The working answer is **yes, at prototype scale**. The production campaign presents the authored compute SDF campus at 1920×1080. A GLSL compute shader ray-marches an analytic SDF campus into a GPU texture, and `Texture2DRD` exposes that texture to Godot. The SDF capture harness remains a separate proof. It renders internally at 640×360 and scales to a 1920×1080 viewport.

This is intentionally not a reimplementation of a complete dynamic sparse-SDF engine. The first proof includes:

- analytic CSG buildings and campus infrastructure;
- a fixed orthographic isometric camera in the SDF proof;
- palette materials, derived normals, soft shadows, ambient occlusion, and fog;
- geometry-changing `growth`, `overload`, and `scrutiny` states;
- render-on-change compute dispatch (campaign 1920×1080, harness 640×360 scaled to 1920×1080);
- strict errors when compute, shader, state, dimensions, or GPU resources violate the contract.

Sparse brick caches, geometry clipmaps, incremental dirty-region updates, arbitrary sculpting, physics mesh extraction, and full-resolution continuous animation are explicitly deferred until this look and interaction model earn that complexity.

## Verified toolchain

- Godot standard/non-.NET `4.7.2.stable.official.ed1daf0bf`
- Windows: D3D12 Forward+ compute
- macOS: Metal Forward+ compute
- Linux: Vulkan Forward+ compute. Mesa lavapipe provides a software Vulkan device on a headless host.
- PowerShell 7 or Windows PowerShell 5.1 on Windows
- bash on macOS
- bash on Linux

The canonical Windows executables are `.tools\godot\4.7.2\Godot_v4.7.2-stable_win64.exe` and `.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`. The canonical macOS executable is `.tools/godot/4.7.2/Godot.app/Contents/MacOS/Godot`. The canonical Linux executable is `.tools/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64`. Each automation script resolves this location from the repository root for the current host. The scripts reject a missing binary, other versions, and Mono/.NET builds. The scripts do not search `PATH`, Downloads, Program Files, or `/Applications`. Campus and laboratory geometry are authored Godot scenes. The project does not use a Blender export pipeline or GLB campus assets.

Install the standard Godot build without administrator access.

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-godot-standard.ps1
```

macOS:

```bash
./scripts/install-godot-standard.sh
```

Linux:

```bash
./scripts/install-godot-standard.sh
```

A Linux host needs a Vulkan device and a display for the windowed render test. On a Cloud Agent or other headless Linux host, run the one-command Cloud Agent setup first. It installs the system libraries, Mesa lavapipe, and Xvfb, and then installs Godot.

```bash
bash scripts/cloud-agent-setup.sh
```

## One-command full render test

From the repository root on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\render-test.ps1
```

From the repository root on macOS:

```bash
./scripts/render-test.sh
```

From the repository root on Linux:

```bash
./scripts/render-test.sh
```

A headless Linux host runs the windowed render step through an Xvfb virtual display automatically.

The command verifies Godot 4.7, imports the compute shader, launches the real Forward+ renderer, dispatches all three states, captures 1920×1080 PNGs under `game/evidence/sdf`, validates the outputs, and exits nonzero on a broken contract.

Open the editor with the canonical executable.

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\open-editor.ps1
```

macOS:

```bash
./scripts/open-editor.sh
```

`game/project.godot` is the Godot project. Press Run for the interactive proof. Keys `1`, `2`, and `3` switch the three renderer states. The renderer dispatches only when state or camera input changes.

## Simulation State test

The Marketing Scenario has a typed Game State foundation.

The Scenario is authored in `game/simulation/content/marketing_scenario.tres`.

The snapshot loader uses `CACHE_MODE_IGNORE_DEEP`.

The loader validates the schema version, content version, required state, stable identifiers, and content references before it returns a Game State.

Run the state and snapshot test from the repository root.

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\simulation-test.ps1
```

macOS:

```bash
./scripts/simulation-test.sh
```

The command must use the canonical standard Godot 4.7.2 automation executable.

## Code ownership

- `game/renderer/sdf/campus_sdf.glsl`: distance functions, ray marching, lighting, and state geometry.
- `game/renderer/sdf/sdf_renderer.gd`: lightweight GPU resource and compute-dispatch adapter.
- `game/host/sdf_campus_presenter.gd`: production campaign SDF presenter at 1920×1080.
- `game/scripts/sdf_render_harness.gd`: capture-harness HUD, input, deterministic state capture, and test exit behavior.
- `game/scenes/sdf_render_harness.tscn`: capture-harness scene. Capture scripts must load this scene. Do not use the editor Run scene.
- `scripts/render-test.ps1`: exact end-to-end verification command.
- `game/scenes/campus_blockout.tscn`: authored Company Campus site.
- `game/scenes/lab_stage_1.tscn`: starting laboratory PackedScene.
- `game/scenes/lab_stage_2.tscn`: developed laboratory PackedScene.

The renderer has no gameplay rules, HUD logic, asset generator, or mesh fallback. That boundary is deliberate so the visual experiment can be replaced or expanded without entangling the simulation.
