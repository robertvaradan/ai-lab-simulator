# SDF Renderer Contract

This directory owns the experimental signed-distance-field renderer and nothing else.

- Keep `sdf_renderer.gd` limited to RenderingDevice resource ownership, compute dispatch, renderer state input, and explicit failure reporting.
- Keep all scene distance functions, ray marching, normals, lighting, and material evaluation in `campus_sdf.glsl`.
- Do not put HUD, input handling, capture orchestration, gameplay rules, simulation state, or asset-generation code in this directory.
- The output is a `Texture2DRD` produced by the main RenderingDevice and sampled by Godot's presentation layer. A local RenderingDevice is not valid for this contract because its resources cannot be shared with the main renderer.
- Forward+ or Mobile compute support is required. Missing RenderingDevice, invalid shader/pipeline/texture RIDs, invalid output dimensions, or an unknown state must fail clearly; do not substitute a mesh, canvas shader, placeholder texture, or alternate renderer.
- The renderer default output size is 640x360 for the capture harness. The production campaign presenter must set `output_size` from the current Window size. Do not change the harness default without updating the shader contract, harness, documentation, and evidence together.
- Preserve the HQ renderer states and their numeric contract: `empty=0`, `growth=1`, `overload=2`, `scrutiny=3`.
- `empty` must show the HQ land shell without laboratory buildings.
- HQ must not present an Application building mass.

