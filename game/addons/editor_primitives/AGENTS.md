# Editor primitives plugin contract

This directory owns Godot editor handles for editor primitives.

- Follow `../../../docs/tools/editor-primitives.md`.
- Register gizmos and the `BoxOutline` node type.
- Show size handles for the outer box.
- Show thickness handles for the inset outline.
- Snap every handle edit to the 0.2 m voxel grid.
- Keep the opposite outer face fixed during a size drag unless Alt is held.
- Keep the outer size fixed during a thickness drag.
