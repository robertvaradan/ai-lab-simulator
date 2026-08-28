# Editor primitives plugin contract

This directory owns Godot editor handles for editor primitives.

- Follow `../../../docs/tools/editor-primitives.md`.
- Register gizmos and the `BoxOutline` and `CylinderOutline` node types.
- Show size handles for the outer box.
- Show height handles and radius handles for the outer cylinder.
- Show thickness handles for the inset outline.
- Snap every handle edit to the 0.2 m voxel grid.
- Keep the opposite outer face or cap fixed during a size or height drag unless Alt is held.
- Keep the outer size or outer radius fixed during a thickness drag.
- Do not change `radial_segments` from a handle.
