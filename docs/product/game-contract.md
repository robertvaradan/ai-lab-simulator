# Game contract

## Product promise

The player must run an AI company during a competitive AI expansion.

The player must build Models.

The player must use Models in different Applications.

The player must invest in Research, Scale, and Applications.

The player must make trade-offs between growth, cash, trust, and competitive position.

The player must see important consequences in the isometric world and in the management interface.

## Strategic freedom

The game must not assign a permanent company class at campaign start.

The player must have access to all three Strategic Domains.

The player must form a playstyle through repeated investments.

The game can describe the resulting company as a Research Giant, a Hyperscaler, an Application Powerhouse, or a hybrid.

These descriptions must not lock later choices.

## Product form

The primary world view must use an orthographic isometric camera.

The camera must not rotate.

The player can pan the camera.

The player can zoom the camera.

Pan and zoom must use smoothing.

The isometric camera must follow `docs/presentation/isometric-camera.md`.

The campaign must follow `docs/presentation/world-map.md`.

The campaign Worlds must be HQ, Data Center, and Government.

HQ must use predetermined Site Plots for the laboratory Site.

The player must be able to customize and upgrade HQ.

The first HQ campus blockout must follow `docs/presentation/campus-authoring.md`.

The blockout must use native Godot primitive geometry.

Repeated round-crown trees must instance one shared scene.

Repeated fir trees must instance one shared scene.

The blockout must not load a GLB file.

The laboratory must use authored PackedScene stages.

The campus blockout must instance one laboratory stage scene.

The campus blockout must not embed laboratory mesh nodes inline.

The blockout scene must store its geometry as editable Godot scene nodes.

The blockout scene must not generate its geometry at runtime.

The blockout must place PrimitiveMesh sizes and node origins on a 0.2 m voxel grid.

A box extent must land on the 0.2 m grid.

A box outline must use `BoxOutlineMesh`.

A box outline must use one outer size and one inset thickness.

A box outline thickness must grow inward from the outer size.

A cylinder outline must use `CylinderOutlineMesh`.

A cylinder outline must use one outer radius, one height, one inset thickness, and a radial segment count.

A cylinder outline thickness must grow inward from the outer radius.

A cylinder radius, cylinder height, sphere radius, and sphere height must land on the 0.2 m grid.

A mesh node origin must keep each world-axis extent on the 0.2 m grid.

The HQ blockout must show the laboratory plot, parking lot, perimeter roads, paths, walls, landscape, and site lights.

HQ must not present an Application building.

Grass surfaces must use a soft, even putting-green vegetation shader.

Hedge and tree crown surfaces must share one foliage shader.

Hedge and tree crown shading must show deeper contrast when light catches the form.

Vegetation shaders must use triplanar procedural shading. They must not depend on mesh UVs.

The game must not require freeform road construction.

The game must not require unrestricted building placement.

The management interface can contain detailed tables, reports, and graphs.

The game must not add low-value actions only to avoid an information-heavy interface.

## World scope

HQ must represent a compact Silicon Valley headquarters territory.

Data Center and Government must appear as selectable Worlds on the World map.

The first implementation must not simulate a complete city.

The first implementation must not simulate the internal operation of each Data Center.

## Tone

The game must use satire to show the incentives and risks of the AI industry.

The game must let careful and reckless strategies use the same rules.

The game must not define reckless play as the only intended fantasy.

The game can include catastrophic outcomes when prior player actions cause them.

## Current product limits

The first release plan must not depend on a complete technology tree.

The first release plan must not depend on Robots.

The first release plan must not depend on a complete regulation system.

The first release plan must not depend on a final campaign victory condition.
