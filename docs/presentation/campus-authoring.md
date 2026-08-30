# Campus authoring

This specification owns HQ Site scene authoring in Godot.

## Authority

`docs/presentation/campus-authoring.md` owns authored HQ campus and laboratory scene rules.

`docs/presentation/world-map.md` owns campaign Worlds and World navigation.

`docs/product/game-contract.md` owns the product campus promise.

`docs/tools/editor-primitives.md` owns editor `PrimitiveMesh` types.

`docs/visual/color-palette.md` owns palette roles.

## Authoring form

A designer must author campus geometry in Godot scene files.

A campus scene must use `PrimitiveMesh` nodes on the 0.2 m voxel grid.

A campus scene must not load a GLB file.

A campus scene must not depend on a Blender export pipeline.

A designer must edit nodes in the Godot scene editor.

A campus scene must not generate its geometry at runtime.

## Laboratory stages

The laboratory is the HQ building where Research and Application work occur.

The laboratory must use authored PackedScene stages.

`game/scenes/lab_stage_1.tscn` owns the first built laboratory.

`game/scenes/lab_stage_2.tscn` owns the developed laboratory.

Month 1 must present HQ as an empty plot before the laboratory exists.

The campus blockout must instance one laboratory stage scene when the laboratory exists.

The campus blockout must not embed laboratory mesh nodes inline.

The campus blockout must not present an Application building.

Stage 2 must preserve the developed laboratory mass from the authored TSCN PoC.

Stage 1 must use the same visual language as Stage 2.

Stage 1 must use a shorter tower.

Stage 1 must omit the research wing and the right wing.

## Site composition

`game/scenes/campus_blockout.tscn` owns the HQ Site.

The production campaign must instance the campus blockout for the HQ World view.

The campus blockout must contain the site ground, roads, parking, paths, walls, landscape, lights, environment, and camera.

Repeated round-crown trees must instance `game/scenes/round_tree.tscn`.

Repeated fir trees must instance `game/scenes/fir_tree.tscn`.

The campus blockout must not duplicate round-crown or fir mesh nodes.

The `CampusBlockout` root must not have a script.

## Materials

Campus materials must live under `game/materials`.

Materials must use palette role colors.

A scene must not inline role colors.

## Concept art

`docs/concept-art/main-lab-site-context-v1.png` owns the developed campus site target.

`docs/concept-art/main-lab-concept-v1.png` owns the developed laboratory building target.

Stage 2 must match the developed laboratory building target.

Stage 1 must present an earlier form of that laboratory.

## Verification

From the repository root on macOS, run:

```bash
./scripts/render-campus-blockout.sh
```

From the repository root on Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\render-campus-blockout.ps1
```

Success requires `CAMPUS_BLOCKOUT_SCENE_LOADED`.

Success requires `CAMPUS_BLOCKOUT_CAPTURE_SUCCESS`.

Success requires `CAMPUS_BLOCKOUT_COMPARISON_SUCCESS`.

Success requires `CAMPUS_BLOCKOUT_COMMAND_SUCCESS`.
