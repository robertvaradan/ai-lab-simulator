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

The primary world view must use a fixed isometric or three-quarter camera.

The Company Campus must use predetermined Site Plots.

The player must be able to customize and upgrade the Company Campus.

The first Company Campus blockout must match the composition in `docs/concept-art/main-lab-site-context-v1.png`.

The blockout must use native Godot primitive geometry.

Repeated round-crown trees must instance one shared scene.

Repeated fir trees must instance one shared scene.

The blockout must not depend on a Blender or GLB campus asset.

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

The blockout must show the main laboratory, parking lot, perimeter roads, paths, walls, landscape, and site lights.

The game must not require freeform road construction.

The game must not require unrestricted building placement.

The management interface can contain detailed tables, reports, and graphs.

The game must not add low-value actions only to avoid an information-heavy interface.

## World scope

The initial Company Campus must represent a compact Silicon Valley territory.

Remote Sites and Institutions can appear as selectable locations.

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
