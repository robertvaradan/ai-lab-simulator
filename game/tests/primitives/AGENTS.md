# Editor primitive test contract

This directory owns editor primitive tests.

- Follow `../../../docs/tools/editor-primitives.md`.
- Verify voxel-grid snapping for outer size, outer radius, height, and inset thickness.
- Verify that thickness grows inward.
- Verify that top faces and bottom faces exist.
- Verify that face winding matches Godot `PrimitiveMesh` front faces.
- Verify that the four box bars do not overlap.
- Verify that `radial_segments` can produce a hexagonal ring and an octagonal ring.
- Test invalid sizes as rejected or snapped contract values.
- Do not use a presentation scene as the only primitive test.
