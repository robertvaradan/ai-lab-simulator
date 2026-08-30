# Production bootstrap

## Authority

This specification owns the production entry flow and the first playable campaign shell.

This specification does not replace the Marketing Slice.

This specification does not close open progression-content decisions.

`docs/presentation/panel-system.md` owns the Campaign Panel Workspace and event presentation.

## Purpose

The player must start the production game from the editor Run action.

The player must reach the Marketing Scenario through a Main Menu.

The campaign host must present the Campaign Panel Workspace after the Marketing Scenario loads.

The host must not require an opening-path select gate.

The player must inspect Company State, stage a Plan, and Advance Month Steps.

The shell must present Company Overview, Plan with Skill Tree, event timeline, Data Center World, Government World, Pause, and campaign failure through the Panel Workspace.

World navigation must follow `docs/presentation/world-map.md`.

## Scene flow

The default editor Run scene must be `game/scenes/init.tscn`.

The init scene must load `game/scenes/main_menu.tscn`.

The Main Menu must present a Start control.

The Start control must load `game/scenes/campaign.tscn`.

The campaign host must load the Marketing Scenario before it presents the campaign HUD.

The HQ World view must instance `game/scenes/campus_blockout.tscn`.

The campaign host must use `CampusVisualPresenter` to select the laboratory stage.

The campaign host must not use `SdfRenderer` for the HQ World view.

The campaign must keep Window content scale enabled for canvas UI.

Window content scale must follow `docs/presentation/ui-scale.md`.

The campaign canvas Theme must follow `docs/presentation/ui-theme.md`.

The Campaign Panel Workspace must follow `docs/presentation/panel-system.md`.

The host must not set `CONTENT_SCALE_MODE_DISABLED`.

`game/scenes/sdf_render_harness.tscn` must remain the SDF capture harness.

`game/scenes/marketing_play.tscn` must remain the Marketing Slice play scene.

The campaign host must not reuse `MarketingPlayOverlay`.

## Planning

The Panel Workspace must accept Advance without an opening-path choice.

The player must stage Project start Commands through `CampaignDraftPlanState`.

`CampaignHost.validate_draft_plan()` must build the candidate Plan and call Simulation Core validation.

The first HQ construction Project must be `project.campus.build_laboratory`.

Research, Scale, and Application Project starts must require completed `project.campus.build_laboratory`.

The player can stage more than one available Project when validation allows it.

The Plan must still pass Simulation Core validation.

An empty Plan must remain valid when no Attention Event requires a response.

Advance must stay disabled while the draft Plan is invalid.

## HQ laboratory

The HQ Context Card must show the project-team count as laboratory capacity.

Laboratory capacity level must equal the project-team count.

The visible HQ World must be the authored campus blockout.

Month 1 must present HQ as an empty plot.

The host must hide the campus blockout when the active World is not HQ.

The host must disable the campus camera when the campus blockout is hidden.

The HQ Context Card must show empty-plot, compact, or developed laboratory text from `CampusVisualMapping`.

HQ must expose the research Site Plot or Laboratory as one selectable World object.

`project.campus.build_laboratory` completion must show laboratory stage 1.

Frontier-model Research completion must show laboratory stage 2.

The Research Project must reserve one project team while it is active.

The Panel Workspace must not write Site Plot state.

HQ must not present an Application building.

## Month progression

Advance must be the only campaign control that progresses time.

Advance must call `SimulationAdvanceAction`.

Advance must commit the staged Plan.

Advance must stop at the first Attention Boundary.

The Company status panel must present Month Step, Quarter, and Cash.

Company Overview must present research points, project teams, capacity, Projects, Models, contracts, and active Trust values.

The event timeline must stage Attention Event acknowledgments when event detail receives focus.

## Skill tree

The campaign skill tree must follow `docs/gameplay/skill-tree.md`.

The Skill Tree must appear as a Plan Workbench tab.

The campaign must not present a separate tech tree.

## Data Center World entry

The Data Center World must present a minimal authored 3D scene.

The Data Center Context Card must list active compute contracts from Game State.

The Data Center Context Card must show Compute Capacity and monthly compute-contract cost.

The Data Center Context Card must state that the Marketing Scenario does not construct an owned Data Center.

The Data Center World must not simulate internal Data Center operation.

The Data Center World must not appear as an HQ Site Plot.

## Fail state

The player can abandon the campaign from Pause.

Abandonment must require explicit confirmation.

The campaign host must end the campaign when Cash is 0 or less after a published Advance.

That Cash condition is the bootstrap fail condition.

The bootstrap fail condition must not replace the canonical bankruptcy rule.

The fail-state Modal must show the fail reason, Month Step, and Cash.

The fail-state Modal must provide a control that returns to the Main Menu.

The fail-state Modal must block further Advance.

## Content catalog

The bootstrap catalog must live in production host code.

The catalog must not add a Command type to the Marketing Scenario registry.

The catalog must not add a Project to the Marketing Scenario.

## Verification

Automated tests must load the init, Main Menu, and campaign scenes.

Automated tests must verify the campaign instances the campus blockout.

Automated tests must verify Month 1 hides the laboratory stage.

Automated tests must verify Build Laboratory completion shows laboratory stage 1.

Automated tests must stage a Plan and Advance to the first Attention Boundary.

Automated tests must verify skill-tree research-point gating.

Automated tests must verify the Data Center contract list.

Automated tests must verify the fail-state view.
