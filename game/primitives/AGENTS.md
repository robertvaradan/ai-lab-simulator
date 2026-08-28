# Editor primitives contract

This directory owns editor `PrimitiveMesh` types.

- Follow `../../docs/tools/editor-primitives.md`.
- Keep `BoxOutlineMesh` on the 0.2 m voxel grid.
- Keep `CylinderOutlineMesh` on the 0.2 m voxel grid.
- Keep `BoxOutline` as the scene node for the box outline primitive.
- Keep `CylinderOutline` as the scene node for the cylinder outline primitive.
- Keep outline thickness inset from the outer size or outer radius.
- Keep `radial_segments` as an inspector option on `CylinderOutlineMesh`.
- Do not generate outline geometry from four authored box nodes.
- Do not generate outline geometry from a stack of authored cylinder nodes.
- Do not move editor handle code into this directory.
