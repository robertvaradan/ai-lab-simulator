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
| presentation-flow | Production presentation flow | BRANCH | DERIVED | - | YES | docs/product/game-contract.md; docs/marketing/marketing-slice.md | - | - | The production game presents simulation decisions through the Company Campus. |
| camera | Isometric gameplay camera | LEAF | COMPLETE | - | YES | docs/presentation/isometric-camera.md | game/camera/isometric_camera.gd; game/scenes/campus_blockout.tscn | game/tests/camera/isometric_camera_test.gd | The canonical orthographic camera behavior exists and has automated verification. |
| campus | Representative Company Campus | LEAF | COMPLETE | - | YES | docs/presentation/campus-authoring.md; docs/marketing/marketing-slice.md | game/scenes/campus_blockout.tscn; game/host/campus_visual_presenter.gd | game/tests/host/campus_visual_presenter_test.gd | The Company Campus blockout presents laboratory stage, Third-Party Compute, and Competitor release from Simulation Core state. |
| simulation-connection | Connect production to Simulation Core | LEAF | COMPLETE | - | YES | docs/gameplay/core-loop.md; docs/marketing/marketing-slice.md | game/host/marketing_play_host.gd; game/host/marketing_play_overlay.gd; game/scenes/marketing_play.tscn | game/tests/host/marketing_play_host_test.gd | The production host loads the Marketing Scenario, runs Advance, and presents Attention Events and the Quarterly Report. |
| management-interface | Management interface | LEAF | COMPLETE | - | YES | docs/marketing/marketing-slice.md | game/host/marketing_play_overlay.gd | game/tests/host/marketing_play_management_test.gd | The overlay provides Project selection, Model identity input, Projected Evaluation Ranges, Attention Events, and the Quarterly Report. |
| end-to-end-play | Complete production Scenario | LEAF | COMPLETE | - | YES | docs/marketing/marketing-slice.md; docs/marketing/marketing-scenario.md | game/host/marketing_play_host.gd; game/host/marketing_play_overlay.gd; game/host/campus_visual_presenter.gd | game/tests/host/marketing_play_management_test.gd; game/tests/host/campus_visual_presenter_test.gd | A player can complete the Marketing Scenario first quarter through the production overlay, and the campus presents the resulting world states. |
| visible-state | Authoritative visible world states | LEAF | COMPLETE | - | YES | docs/product/game-contract.md; docs/marketing/marketing-slice.md | game/host/campus_visual_mapping.gd; game/host/campus_visual_presenter.gd | game/tests/host/campus_visual_presenter_test.gd | Laboratory stage, Third-Party Compute link, and Competitor release visuals use Simulation Core state. |

## Edges

| From | To | Label |
| --- | --- | --- |
| presentation-flow | camera | frames |
| camera | campus | displays |
| campus | simulation-connection | must connect to |
| simulation-connection | management-interface | enables |
| management-interface | visible-state | controls |
| visible-state | end-to-end-play | completes |
