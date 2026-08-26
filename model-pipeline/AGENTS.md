# Blender pipeline contract

This folder owns deterministic Blender generation and glTF export for the Godot render proof.

## Deterministic generation and export

- Run Blender 5.1 in background factory-startup mode through `scripts/generate_assets.py`.
- The script must begin from an empty factory scene and reconstruct the asset from versioned manifest/config inputs. No user preferences, startup scene, add-ons, network services, random values, or external fonts may influence output.
- `manifest/assets.json` is the source of truth. `schema/asset-manifest.schema.json` documents its serialized contract. Generator validation must fail before scene mutation when required fields, versions, state names, file paths, or budgets disagree.
- The generated source is `source/campus_modular_kit.blend`; the generated runtime export is `../game/assets/generated/campus_modular_kit.glb`. Those files are generator-owned and must not be edited by hand.
- Export real geometry and materials through Blender glTF. Do not reproduce the authored buildings as Godot primitive fallbacks.

## Geometry, material, and naming budgets

- Favor bold modular massing, simplified/faceted topology, two-segment bevels, roof silhouettes, rhythmic windows, service ducts, cooling shapes, terraces, fences, and readable state props.
- Keep the prototype within the manifest's material budget and use zero painted textures. Add identity with geometry, material IDs, palette, lighting, and emissive accents.
- Material families are architecture/concrete, dark metal, glass, vegetation, ground/water, and emissive/status. Any new material must map to a documented family and remain within budget.
- Every exported object must begin with exactly one layer prefix: `Base__`, `Growth__`, `Overload__`, or `Scrutiny__`. The remainder of the name must identify subject and part.
- `Base__` contains the persistent lab/core, compute, and research/talent kit. State layers are modular dressing on that one base asset, not separate replacement campuses.
- Preserve the manifest fields `asset_id`, `family`, `footprint`, `location_role`, `state_layers`, `lod_policy`, `collision_type`, `material_budget`, and `source_file`.

## State-layer semantics

- `growth`: expansion pods, vegetation/terraces, optimistic cool-green status lighting.
- `overload`: additional cooling/service geometry, hot pipes, warning beacons, orange/red status lighting.
- `scrutiny`: fences, checkpoint/security forms, scan arches, cool inspection lighting.
- Each layer must remain legible from the actual fixed Godot camera; detail that only reads in Blender close-up does not count.

## Validation

- Pin and validate Blender 5.1 before doing work.
- Validate manifest/schema version, exact state set, path ownership, object prefixes, required family subjects, material count, painted-texture count, and exported-file existence/size.
- The end-to-end authority is `..\scripts\render-test.ps1`, which regenerates assets, imports them with Godot, renders all states, and checks evidence.
- Inspect all evidence after geometry/material changes. A successful export alone is not visual verification.

## No fallbacks as fixes

Do not silently skip invalid objects, missing palette entries, export failures, version mismatches, or absent output directories. Do not look in alternate source/export paths and do not generate substitute geometry when a contract is broken. Raise a precise error and fix the manifest, config, toolchain, or generator responsible.

