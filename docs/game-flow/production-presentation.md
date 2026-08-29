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
| world-map | World map navigation | LEAF | OPEN | - | NO | docs/presentation/world-map.md | - | - | The player zooms out to HQ, Data Center, and Government, then enters one World. |
| camera | Isometric gameplay camera | LEAF | COMPLETE | - | YES | docs/presentation/isometric-camera.md | game/camera/isometric_camera.gd; game/scenes/campus_blockout.tscn | game/tests/camera/isometric_camera_test.gd | The canonical orthographic camera behavior exists for an entered World. |
| campus | Representative HQ campus | LEAF | PARTIAL | - | YES | docs/presentation/campus-authoring.md; docs/presentation/world-map.md; docs/marketing/marketing-slice.md | game/scenes/campus_blockout.tscn; game/host/campus_visual_presenter.gd | game/tests/host/campus_visual_presenter_test.gd | The Marketing Slice HQ blockout still presents transitional Scale and Application campus masses that the World map model forbids. |
| sdf-campus | Authored compute SDF HQ campus | LEAF | PARTIAL | - | NO | docs/gameplay/production-bootstrap.md; docs/presentation/world-map.md | game/host/sdf_campus_presenter.gd; game/renderer/sdf/campus_sdf.glsl | game/tests/host/production_bootstrap_test.gd | The campaign presents the authored GLSL HQ campus. Empty-plot state and Application-free HQ mass remain open. |
| simulation-connection | Connect production to Simulation Core | LEAF | COMPLETE | - | YES | docs/gameplay/core-loop.md; docs/marketing/marketing-slice.md | game/host/marketing_play_host.gd; game/host/marketing_play_overlay.gd; game/scenes/marketing_play.tscn | game/tests/host/marketing_play_host_test.gd | The production host loads the Marketing Scenario, runs Advance, and presents Attention Events and the Quarterly Report. |
| management-interface | Management interface | LEAF | COMPLETE | - | YES | docs/marketing/marketing-slice.md | game/host/marketing_play_overlay.gd | game/tests/host/marketing_play_management_test.gd | The overlay provides Project selection, Model identity input, Projected Evaluation Ranges, Attention Events, and the Quarterly Report. |
| end-to-end-play | Complete production Scenario | LEAF | PARTIAL | - | YES | docs/marketing/marketing-slice.md; docs/marketing/marketing-scenario.md | game/host/marketing_play_host.gd; game/host/marketing_play_overlay.gd; game/host/campus_visual_presenter.gd | game/tests/host/marketing_play_management_test.gd; game/tests/host/campus_visual_presenter_test.gd | A player can complete the Marketing Scenario first quarter. HQ empty-plot start and World map navigation remain open. |
| visible-state | Authoritative visible world states | LEAF | PARTIAL | - | YES | docs/product/game-contract.md; docs/presentation/world-map.md; docs/marketing/marketing-slice.md | game/host/campus_visual_mapping.gd; game/host/campus_visual_presenter.gd | game/tests/host/campus_visual_presenter_test.gd | Laboratory stage and Competitor release visuals use Simulation Core state. Scale presentation must move to the Data Center World. |
| bootstrap-entry | Production entry flow | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md | game/scenes/init.tscn; game/scenes/main_menu.tscn; game/app/bootstrap_init.gd; game/app/main_menu.gd; game/app/scene_router.gd | game/tests/host/production_bootstrap_test.gd | Init loads the Main Menu. Start loads the campaign host. |
| opening-path | Opening path select | LEAF | OPEN | - | NO | docs/gameplay/production-bootstrap.md; docs/gameplay/playthrough-backlog.md | game/host/path_select_view.gd; game/host/campaign_catalog.gd | game/tests/host/production_bootstrap_test.gd | Spec forbids the opening-path gate. Implementation still presents Path Select. |
| campaign-shell | Campaign HUD and month loop | LEAF | PARTIAL | - | NO | docs/gameplay/production-bootstrap.md; docs/gameplay/core-loop.md | game/host/campaign_host.gd; game/host/campaign_hud.gd; game/host/sdf_campus_presenter.gd; game/scenes/campaign.tscn | game/tests/host/production_bootstrap_test.gd | The campaign HUD advances Month Steps and presents the authored SDF HQ campus. Path Select removal remains open. |
| skill-tree-stub | Bootstrap skill tree | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md | game/host/skill_tree_view.gd; game/host/campaign_catalog.gd | game/tests/host/production_bootstrap_test.gd | The skill tree is a proof catalog with one unlock for each Month Step. |
| tech-tree-stub | Bootstrap tech tree | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md | game/host/tech_tree_view.gd; game/host/campaign_catalog.gd | game/tests/host/production_bootstrap_test.gd | The tech tree is a proof catalog with Cash-gated items. |
| data-center-slot | Data Center World entry | LEAF | PARTIAL | - | NO | docs/gameplay/production-bootstrap.md; docs/presentation/world-map.md; docs/gameplay/domain-model.md | game/host/data_center_view.gd | game/tests/host/production_bootstrap_test.gd | The reserved Data Center entry lists compute contracts. Full Data Center World navigation remains open. |
| fail-state | Campaign fail-state view | LEAF | COMPLETE | - | NO | docs/gameplay/production-bootstrap.md; docs/gameplay/difficulty-and-loss.md | game/host/fail_state_view.gd | game/tests/host/production_bootstrap_test.gd | The fail-state view covers abandonment and the bootstrap Cash fail condition. |

## Edges

| From | To | Label |
| --- | --- | --- |
| presentation-flow | bootstrap-entry | starts from |
| presentation-flow | world-map | navigates through |
| presentation-flow | camera | also frames |
| bootstrap-entry | campaign-shell | loads scenario then |
| campaign-shell | opening-path | must remove |
| campaign-shell | sdf-campus | presents HQ |
| world-map | campus | enters HQ |
| world-map | data-center-slot | enters Data Center |
| camera | campus | displays |
| campus | simulation-connection | must connect to |
| simulation-connection | management-interface | enables |
| management-interface | visible-state | controls |
| visible-state | end-to-end-play | completes |
| campaign-shell | skill-tree-stub | presents |
| campaign-shell | tech-tree-stub | presents |
| campaign-shell | data-center-slot | reserves |
| campaign-shell | fail-state | can end with |
