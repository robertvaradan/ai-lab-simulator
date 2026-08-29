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
| campus | Representative Company Campus | LEAF | PARTIAL | - | YES | docs/presentation/campus-authoring.md; docs/marketing/marketing-slice.md | game/scenes/campus_blockout.tscn; game/renderer/sdf/campus_sdf.glsl | - | A campus render harness exists, but it is not connected to authoritative simulation state. |
| simulation-connection | Connect production to Simulation Core | LEAF | COMPLETE | - | YES | docs/gameplay/core-loop.md; docs/marketing/marketing-slice.md | game/host/marketing_play_host.gd; game/host/marketing_play_overlay.gd; game/scenes/marketing_play.tscn | game/tests/host/marketing_play_host_test.gd | The production host loads the Marketing Scenario, runs Advance, and presents Attention Events and the Quarterly Report. |
| management-interface | Management interface | LEAF | NONE | - | YES | docs/marketing/marketing-slice.md | - | - | Project selection, Model input, forecast, event, and report controls do not exist. |
| visible-state | Authoritative visible world states | LEAF | NONE | - | YES | docs/product/game-contract.md; docs/marketing/marketing-slice.md | - | - | Campus, Project, Compute, and Competitor visuals do not use Simulation Core state. |
| end-to-end-play | Complete production Scenario | LEAF | NONE | - | YES | docs/marketing/marketing-slice.md; docs/marketing/marketing-scenario.md | - | - | A player cannot complete the Marketing Scenario without developer controls. |

## Edges

| From | To | Label |
| --- | --- | --- |
| presentation-flow | camera | frames |
| camera | campus | displays |
| campus | simulation-connection | must connect to |
| simulation-connection | management-interface | enables |
| management-interface | visible-state | controls |
| visible-state | end-to-end-play | completes |
