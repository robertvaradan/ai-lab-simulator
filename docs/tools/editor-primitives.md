# Editor primitives

This document is the canonical editor primitive contract.

## Purpose

A designer must place geometry in the Godot scene editor.

A designer must use `PrimitiveMesh` types on the 0.2 m voxel grid.

A box outline must replace four separate box meshes for a rectangular frame.

A cylinder outline must replace a stack of cylinder meshes for a cylindrical frame.

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

## Cylinder outline

`CylinderOutlineMesh` is a `PrimitiveMesh`.

A cylinder outline must use one outer radius.

A cylinder outline must use one height.

A cylinder outline must use one inset thickness.

A cylinder outline must use a radial segment count.

The outer radius must land on the voxel grid.

The height must land on the voxel grid.

The inset thickness must land on the voxel grid.

The radial segment count must not land on the voxel grid.

The radial segment count must be at least 3.

A radial segment count of 6 must produce a hexagonal ring.

A radial segment count of 8 must produce an octagonal ring.

The outer radius must leave an inner hole of at least one voxel cell.

The inset thickness must be at least one voxel cell.

The outline wall must stay inside the outer radius.

An increase of thickness must move the inner wall inward.

An increase of thickness must not move the outer wall.

The height must not inset.

The mesh must contain one wall facet for each radial segment.

Each facet must include an outer face, an inner face, a top face, and a bottom face.

Face winding must match Godot `PrimitiveMesh` front faces.

Stored normals must point out of the wall.

## Editor handles

The Godot editor must show handles on a selected `BoxOutline` node.

The Godot editor must show handles on a selected `MeshInstance3D` that uses `BoxOutlineMesh`.

The Godot editor must show handles on a selected `CylinderOutline` node.

The Godot editor must show handles on a selected `MeshInstance3D` that uses `CylinderOutlineMesh`.

Size handles must edit the outer size of a box outline.

A box size handle must move one outer face.

A box size handle must keep the opposite outer face fixed unless the designer holds Alt.

Alt must scale a box outline from the mesh origin.

Height handles must edit the height of a cylinder outline.

A cylinder height handle must keep the opposite cap fixed unless the designer holds Alt.

Alt must scale cylinder height from the mesh origin.

Radius handles must edit the outer radius of a cylinder outline.

A radius handle must keep the mesh origin fixed.

Thickness handles must edit the inset thickness.

A thickness handle must keep the outer size or outer radius fixed.

A thickness handle must keep the mesh origin fixed.

Handle edits must snap to the voxel grid.

Handle edits must not change the radial segment count.

## Scene contract

A designer can add a `BoxOutline` node.

A designer can add a `CylinderOutline` node.

A scene can store a `BoxOutlineMesh` on a `MeshInstance3D`.

A scene can store a `CylinderOutlineMesh` on a `MeshInstance3D`.

The scene must not author four box nodes for one outline.

The scene must not author a stack of cylinder nodes for one outline.

A designer can set `radial_segments` on `CylinderOutlineMesh` in the inspector.

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

Success requires `CYLINDER_OUTLINE_MESH_TEST_SUCCESS`.
