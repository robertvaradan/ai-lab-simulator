# Production presentation

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | production-presentation |
| Title | Production game presentation |
| Root Node | presentation-flow |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| presentation-flow | Production presentation flow | BRANCH | DERIVED | - | YES | docs/product/game-contract.md; docs/presentation/world-map.md; docs/marketing/marketing-slice.md | - | - | The production game presents simulation decisions through HQ, Data Center, and Government Worlds. |
| world-map | World map navigation | LEAF | COMPLETE | - | NO | docs/presentation/world-map.md; docs/presentation/panel-system.md | game/ui/campaign/panels/world_map_panel.gd; game/ui/campaign/campaign_panel_workspace.gd; game/host/campaign_host.gd | game/tests/host/production_bootstrap_test.gd; game/tests/host/panel_system_test.gd | The player opens the World map and enters HQ, Data Center, or Government. |
| camera | Isometric gameplay camera | LEAF | COMPLETE | - | YES | docs/presentation/isometric-camera.md | game/camera/isometric_camera.gd; game/scenes/campus_blockout.tscn | game/tests/camera/isometric_camera_test.gd | The canonical orthographic camera behavior exists for an entered World. |
| campus | Representative HQ campus | LEAF | COMPLETE | - | YES | docs/presentation/campus-authoring.md; docs/presentation/world-map.md; docs/marketing/marketing-slice.md; docs/gameplay/production-bootstrap.md | game/scenes/campus_blockout.tscn; game/host/campus_visual_presenter.gd; game/scenes/campaign.tscn | game/tests/host/campus_visual_presenter_test.gd; game/tests/host/production_bootstrap_test.gd | The production campaign and Marketing Slice present empty plot and laboratory stages from Simulation Core state. Competitor release data uses campaign event presentation. |
| sdf-campus | Authored compute SDF HQ campus | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md | game/host/sdf_campus_presenter.gd; game/renderer/sdf/campus_sdf.glsl; game/scenes/sdf_render_harness.tscn | scripts/render-test.sh | The SDF capture harness presents the authored GLSL HQ campus with empty, growth, overload, and scrutiny states. |
| simulation-connection | Connect production to Simulation Core | LEAF | COMPLETE | - | YES | docs/gameplay/core-loop.md; docs/marketing/marketing-slice.md | game/host/marketing_play_host.gd; game/host/marketing_play_overlay.gd; game/scenes/marketing_play.tscn | game/tests/host/marketing_play_host_test.gd | The production host loads the Marketing Scenario, runs Advance, and presents Attention Events and the Quarterly Report. |
| management-interface | Management interface | LEAF | COMPLETE | - | YES | docs/marketing/marketing-slice.md | game/host/marketing_play_overlay.gd | game/tests/host/marketing_play_management_test.gd | The overlay provides Project selection, Model identity input, Projected Evaluation Ranges, Attention Events, and the Quarterly Report. |
| end-to-end-play | Complete production Scenario | LEAF | COMPLETE | - | YES | docs/marketing/marketing-slice.md; docs/marketing/marketing-scenario.md | game/host/marketing_play_host.gd; game/host/marketing_play_overlay.gd; game/host/campus_visual_presenter.gd | game/tests/host/marketing_play_management_test.gd; game/tests/host/campus_visual_presenter_test.gd | A player can complete the Marketing Scenario first quarter through the production overlay. |
| visible-state | Authoritative visible world states | LEAF | COMPLETE | - | YES | docs/product/game-contract.md; docs/presentation/world-map.md; docs/marketing/marketing-slice.md | game/host/campus_visual_mapping.gd; game/host/campus_visual_presenter.gd | game/tests/host/campus_visual_presenter_test.gd | Laboratory stage visuals use Simulation Core state. Competitor release information uses campaign event presentation. Scale presentation uses the Data Center World. |
| bootstrap-entry | Production entry flow | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md | game/scenes/init.tscn; game/scenes/main_menu.tscn; game/app/bootstrap_init.gd; game/app/main_menu.gd; game/app/scene_router.gd | game/tests/host/production_bootstrap_test.gd | Init loads the Main Menu. Start loads the campaign host. |
| opening-path | Opening path select | LEAF | REMOVED | - | NO | docs/gameplay/production-bootstrap.md; docs/gameplay/playthrough-backlog.md | - | game/tests/host/production_bootstrap_test.gd | The opening-path gate is removed. The campaign HUD stages Projects directly. |
| campaign-shell | Campaign Panel Workspace and month loop | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md; docs/gameplay/core-loop.md; docs/presentation/panel-system.md | game/host/campaign_host.gd; game/ui/campaign/campaign_panel_workspace.gd; game/host/campus_visual_presenter.gd; game/scenes/campaign.tscn | game/tests/host/production_bootstrap_test.gd; game/tests/host/panel_system_test.gd | The Campaign Panel Workspace stages Projects, advances Month Steps, and presents the authored campus blockout. |
| skill-tree | Research-point skill tree | LEAF | COMPLETE | - | NO | docs/gameplay/skill-tree.md; docs/gameplay/production-bootstrap.md; docs/presentation/panel-system.md | game/ui/campaign/panels/plan_workbench.gd; game/host/campaign_catalog.gd | game/tests/host/skill_tree_test.gd; game/tests/host/production_bootstrap_test.gd | The player spends research points on one Research, Scale, and Application tree inside the Plan Workbench. |
| data-center-slot | Data Center World entry | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md; docs/presentation/world-map.md; docs/presentation/panel-system.md; docs/gameplay/domain-model.md | game/scenes/data_center_world.tscn; game/ui/campaign/worlds/campaign_world_selectable.gd | game/tests/host/production_bootstrap_test.gd; game/tests/host/panel_system_test.gd | The Data Center World presents compute contracts through a selectable marker and Context Card. |
| government-world | Government World entry | LEAF | COMPLETE | - | NO | docs/presentation/world-map.md; docs/presentation/panel-system.md | game/scenes/government_world.tscn; game/ui/campaign/worlds/campaign_world_selectable.gd | game/tests/host/panel_system_test.gd | The Government World presents active state and Trust through a selectable marker and Context Card. |
| panel-system | Campaign Panel Workspace | LEAF | COMPLETE | - | NO | docs/presentation/panel-system.md; docs/presentation/ui-theme.md | game/ui/campaign/campaign_panel_workspace.gd; game/ui/base_theme.tres | game/tests/host/panel_system_test.gd; game/tests/ui/base_theme_test.gd | The Campaign uses one Panel Workspace for chrome, Context Card, Workbench, Modal, and event presentation. |
| fail-state | Campaign fail-state view | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md; docs/gameplay/difficulty-and-loss.md; docs/presentation/panel-system.md | game/ui/campaign/panels/fail_state_panel.gd | game/tests/host/production_bootstrap_test.gd | The fail-state Modal covers abandonment and the bootstrap Cash fail condition. |
| ui-theme | Base canvas Theme | LEAF | COMPLETE | - | NO | docs/presentation/ui-theme.md; docs/presentation/panel-system.md | game/ui/base_theme.tres; game/ui/fonts/RopaSans-Regular.ttf; game/ui/fonts/RopaSans-Italic.ttf | game/tests/ui/base_theme_test.gd | The project Theme installs Ropa Sans Regular and Italic plus Campaign control variants. |

## Edges

| From | To | Label |
| --- | --- | --- |
| presentation-flow | bootstrap-entry | starts from |
| presentation-flow | world-map | navigates through |
| presentation-flow | camera | also frames |
| presentation-flow | sdf-campus | also captures |
| presentation-flow | ui-theme | styles canvas with |
| presentation-flow | panel-system | presents campaign through |
| bootstrap-entry | campaign-shell | loads scenario then |
| campaign-shell | panel-system | uses |
| campaign-shell | world-map | can open |
| campaign-shell | campus | presents HQ |
| world-map | campus | enters HQ |
| world-map | data-center-slot | enters Data Center |
| world-map | government-world | enters Government |
| panel-system | world-map | opens |
| panel-system | skill-tree | contains |
| panel-system | fail-state | can open |
| camera | campus | displays |
| campus | simulation-connection | must connect to |
| simulation-connection | management-interface | enables |
| management-interface | visible-state | controls |
| visible-state | end-to-end-play | completes |
| campaign-shell | skill-tree | presents |
| campaign-shell | data-center-slot | reserves |
| campaign-shell | fail-state | can end with |
