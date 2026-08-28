# Editor primitives

This document is the canonical editor primitive contract.

## Purpose

A designer must place geometry in the Godot scene editor.

A designer must use `PrimitiveMesh` types on the 0.2 m voxel grid.

A box outline must replace four separate box meshes for a rectangular frame.

A scene in any context can use these primitives.

## Voxel grid

The voxel cell size is 0.2 m.

A length value must land on the voxel grid.

A mesh node origin must keep each world-axis extent on the voxel grid.

## Box outline

`BoxOutlineMesh` is a `PrimitiveMesh`.

A box outline must use one outer size.

A box outline must use one inset thickness.

The outer size must land on the voxel grid.

The inset thickness must land on the voxel grid.

The outer size on X and on Z must leave an inner hole of at least one voxel cell.

The inset thickness must be at least one voxel cell.

The outline bars must stay inside the outer size.

An increase of thickness must move the inner faces inward.

An increase of thickness must not move the outer faces.

The mesh must contain four axis-aligned bars:

- one bar on the positive Z face
- one bar on the negative Z face
- one bar on the negative X face
- one bar on the positive X face

The four bars must not overlap.

Each bar must include a top face and a bottom face.

Face winding must match Godot `PrimitiveMesh` front faces.

Stored normals must point outward.

The Y size is the bar height.

The Y size must not inset.

## Editor handles

The Godot editor must show handles on a `MeshInstance3D` that uses `BoxOutlineMesh`.

Size handles must edit the outer size.

A size handle must move one outer face.

A size handle must keep the opposite outer face fixed unless the designer holds Alt.

Alt must scale the outer size from the mesh origin.

Thickness handles must edit the inset thickness.

A thickness handle must keep the outer size fixed.

A thickness handle must keep the mesh origin fixed.

Handle edits must snap to the voxel grid.

## Scene contract

A scene can store a `BoxOutlineMesh` on a `MeshInstance3D`.

The scene must not author four box nodes for one outline.

## Ownership

Runtime mesh code must live under `game/primitives`.

Editor handle code must live under `game/addons/editor_primitives`.

Tests must live under `game/tests/primitives`.

## Verification

From the repository root on macOS, run:

```bash
./scripts/editor-primitives-test.sh
```

From the repository root on Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\editor-primitives-test.ps1
```

Success requires `BOX_OUTLINE_MESH_TEST_SUCCESS`.
