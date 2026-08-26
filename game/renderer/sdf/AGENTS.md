# SDF Renderer Contract

This directory owns the experimental signed-distance-field renderer and nothing else.

- Keep `sdf_renderer.gd` limited to RenderingDevice resource ownership, compute dispatch, renderer state input, and explicit failure reporting.
- Keep all scene distance functions, ray marching, normals, lighting, and material evaluation in `campus_sdf.glsl`.
- Do not put HUD, input handling, capture orchestration, gameplay rules, simulation state, or asset-generation code in this directory.
- The output is a `Texture2DRD` produced by the main RenderingDevice and sampled by Godot's presentation layer. A local RenderingDevice is not valid for this contract because its resources cannot be shared with the main renderer.
- Forward+ or Mobile compute support is required. Missing RenderingDevice, invalid shader/pipeline/texture RIDs, invalid output dimensions, or an unknown state must fail clearly; do not substitute a mesh, canvas shader, placeholder texture, or alternate renderer.
- The renderer is intentionally render-on-change at 640x360 for the first validation slice. Increase resolution or add continuous animation only after measured evidence justifies the cost.
- Preserve the three renderer states and their numeric contract: `growth=0`, `overload=1`, `scrutiny=2`.

