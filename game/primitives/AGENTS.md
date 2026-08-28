# Editor primitives contract

This directory owns editor `PrimitiveMesh` types.

- Follow `../../docs/tools/editor-primitives.md`.
- Keep `BoxOutlineMesh` on the 0.2 m voxel grid.
- Keep `BoxOutline` as the scene node for the outline primitive.
- Keep outline thickness inset from the outer size.
- Do not generate outline geometry from four authored box nodes.
- Do not move editor handle code into this directory.
