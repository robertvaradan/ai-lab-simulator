# Production bootstrap

## Authority

This specification owns the production entry flow and the first playable campaign shell.

This specification does not replace the Marketing Slice.

This specification does not close open progression-content decisions.

## Purpose

The player must start the production game from the editor Run action.

The player must reach the Marketing Scenario through a Main Menu.

The player must choose one opening path before the first Advance.

The player must inspect Company State, stage a Plan, and Advance Month Steps.

The shell must present reserved surfaces for the skill tree, the tech tree, the Data Center view, and campaign failure.

## Scene flow

The default editor Run scene must be `game/scenes/init.tscn`.

The init scene must load `game/scenes/main_menu.tscn`.

The Main Menu must present a Start control.

The Start control must load `game/scenes/campaign.tscn`.

The campaign host must load the Marketing Scenario before it presents Path Select.

The campaign world view must use `SdfRenderer` and `campus_sdf.glsl`.

The campaign SDF output size must match the current Window size.

The output size must be the Window size reduced to a multiple of the compute workgroup size.

The presenter must rebuild the SDF output when the Window size changes.

The presenter must disable Window content scale while the campaign is active.

The presenter must restore the previous content-scale mode when the campaign exits.

The campaign host must not instance `campus_blockout.tscn`.

The campaign host must not use the 640 by 360 harness resolution.

Missing Forward+ compute support must fail. The host must not substitute a mesh or canvas world view.

`game/scenes/sdf_render_harness.tscn` must remain the SDF capture harness.

`game/scenes/marketing_play.tscn` must remain the Marketing Slice play scene.

The campaign host must not reuse `MarketingPlayOverlay`.

## Opening path

The campaign host must present Path Select after the Marketing Scenario loads.

The player must select one opening path before the campaign HUD accepts Advance.

The opening paths must be Research, Scale, and Applications.

Each opening path must stage exactly one Marketing Scenario Project start Command.

Research must stage `project.research.frontier_model`.

Scale must stage `project.scale.burst_compute`.

Applications must stage `project.application.coding_agent`.

The player can add a second available Project during later Planning.

The Plan must still pass Simulation Core validation.

## Laboratory

The HUD must show the project-team count as laboratory capacity.

Laboratory capacity level must equal the project-team count.

The visible campus must be the authored compute SDF campus.

The renderer state must follow Game State.

The host must select one state in this order:

1. `scrutiny` when the Northstar flagship Model is released
2. `overload` when the burst compute contract is active
3. `growth` in every other campaign state

The HUD must still show compact or developed laboratory text from `CampusVisualMapping`.

The Research Project start cost is the Cash cost that upgrades the visible laboratory.

The Research Project must reserve one project team while it is active.

The HUD must not write Site Plot state.

## Month progression

Advance must be the only campaign control that progresses time.

Advance must call `SimulationAdvanceAction`.

Advance must commit the staged Plan.

Advance must stop at the first Attention Boundary.

The HUD must present Month Step, Quarter, Cash, project teams, and laboratory capacity.

The HUD must acknowledge open Attention Events in the next Plan.

## Skill tree

The skill tree is a bootstrap presentation catalog.

The player can unlock one skill during Planning in each Month Step.

A skill unlock must require its Cash cost and its prerequisite skills.

A domain skill unlock must stage the matching opening-path Project when that Project is not already present.

A non-domain skill unlock must not write Game State.

A non-domain skill unlock must not change Cash.

The skill tree must disable a control when its requirements fail.

## Tech tree

The tech tree is a bootstrap presentation catalog of proof items.

The player can unlock a tech item during Planning when Cash meets the item cost.

A tech unlock must require its prerequisite tech items.

A tech unlock must not write Game State.

A tech unlock must not change Cash.

The tech tree must disable a control when Cash is below the item cost.

The complete production technology tree remains an open decision.

## Data Center view

The Data Center view is a reserved Scale slot.

The view must list active compute contracts from Game State.

The view must show Compute Capacity and monthly compute-contract cost.

The view must state that the Marketing Scenario does not construct an owned Data Center.

The view must not simulate internal Data Center operation.

## Fail state

The player can abandon the campaign.

Abandonment must require explicit confirmation.

The campaign host must end the campaign when Cash is 0 or less after a published Advance.

That Cash condition is the bootstrap fail condition.

The bootstrap fail condition must not replace the canonical bankruptcy rule.

The fail-state view must show the fail reason, Month Step, and Cash.

The fail-state view must provide a control that returns to the Main Menu.

The fail-state view must block further Advance.

## Content catalog

The bootstrap catalog must live in production host code.

The catalog must not add a Command type to the Marketing Scenario registry.

The catalog must not add a Project to the Marketing Scenario.

## Verification

Automated tests must load the init, Main Menu, and campaign scenes.

Automated tests must choose an opening path and Advance to the first Attention Boundary.

Automated tests must verify skill-tree Month Step gating.

Automated tests must verify tech-tree Cash gating.

Automated tests must verify the Data Center contract list.

Automated tests must verify the fail-state view.
