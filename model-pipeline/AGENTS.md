# Blender pipeline contract

This folder owns one Blender authoring file, Geometry Nodes tools, a Blender add-on, and glTF export for mesh assets.

The SDF renderer does not load these assets. Do not use this kit as a fallback for the compute renderer.

## Authoring source

- `source/campus_modular_kit.blend` is the one authoring file. Edit every campus asset in that file.
- Each `Export__*` collection is one exported asset. Duplicate an object, change Geometry Nodes parameters, and keep the object in the correct collection.
- Object names in `Export__Compute`, `Export__Research`, and state collections must begin with exactly one layer prefix: `Base__`, `Growth__`, `Overload__`, or `Scrutiny__`.
- `Export__LabStage1` uses plain lab mesh names such as `LabBuildingMain`. Do not prefix those meshes with `Base__` or a state layer.
- `Base__` contains the persistent compute and research kit. `Export__LabStage1` is the starting lab mass. State layers are dressing on that one campus.
- Do not place tree objects in the campus source. Place trees later with a scatter tool.
- `Authoring__Labels` holds viewport guide text. Those objects must not enter `Export__*` collections. Publish must not write them into GLBs.

## Designer work

The designer must only place kit pieces and change Geometry Nodes modifier inputs.

The designer must not enable add-ons, set a Scripts path, rebuild node groups, or run Blender CLI.

Open the kit with `scripts/open-campus-kit`. That command registers ALS Campus Kit and syncs node groups.

## Publish into the game

The agent must publish the authoring file with `scripts/export-campus-kit`.

That command syncs node groups, removes tree objects, exports one GLB per collection, and writes `asset_catalog.json`.

The agent must require `PIPELINE_EXPORT_SUCCESS`. The agent must not ask the designer to run Blender CLI.

## Geometry Nodes tools

- Bootstrap and publish install reusable modifier node groups. The ALS sidebar uses the same groups.
- Exposed group inputs are the authoring parameters. Change them on the Geometry Nodes modifier. Do not rebuild meshes as one-off `bpy` primitives.
- Every export mesh must end with `ALS_ShadeContract`. That group sets smooth shading and keeps edges sharp above 30 degrees.
- `ALS_Tree` exists for later scatter. Campus export collections must not contain it.
- Keep the prototype within the manifest material budget and use zero painted textures.
- Material families are architecture/concrete, dark metal, glass, vegetation, ground/water, and emissive/status.

## Authoring add-on

- `addons/als_campus_kit` is the Blender authoring add-on.
- `scripts/open-campus-kit` must register the add-on from this repository path. Do not install a copied add-on into the user add-on folder.
- The ALS sidebar places kit pieces at the 3D cursor.

## Commands

Pin Blender 5.1.

`scripts/open-campus-kit` opens the authoring file, registers the add-on, and syncs node groups. It must fail when the `.blend` or Blender 5.1 is missing.

`bootstrap` creates the authoring file, node groups, materials, collections, and a starter campus. `bootstrap` must fail when the `.blend` already exists. Do not overwrite artist work.

`sync-tools` opens the existing `.blend`, rebuilds node groups, removes tree objects, restores modifier values by socket name, and writes `ALS_ShadeContract` as the last modifier. `sync-tools` must fail when the `.blend` is missing. `sync-tools` must not delete artist objects except tree objects.

`export` runs `sync-tools`, then writes one GLB per `Export__*` collection and writes `asset_catalog.json`. `scripts/export-campus-kit` is the publish command. `export` must fail when the `.blend` is missing. `export` must not delete artist objects except tree objects.

Interactive authoring uses the normal Blender UI through `scripts/open-campus-kit`. Publish uses `--background --factory-startup --python-exit-code 1` so user add-ons cannot change output and a Python error exits non-zero.

## Validation

- Validate Blender 5.1, manifest schema version, export collections, object prefixes, required base subjects, material count, painted-texture count, node groups, shade contract, absence of tree objects, and exported-file existence/size.
- The SDF render test does not regenerate Blender assets.
- Inspect the comparison harness after geometry or material changes. A successful export alone is not visual verification.

## No fallbacks as fixes

Do not skip invalid objects, missing palette entries, export failures, version mismatches, or absent output directories. Do not look in alternate source or export paths. Do not generate substitute geometry when a contract is broken. Raise a precise error and fix the manifest, config, toolchain, or authoring file.
