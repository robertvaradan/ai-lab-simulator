# Reports

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | reports |
| Title | Quarterly reports |
| Root Node | report-flow |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| report-flow | Report flow | BRANCH | DERIVED | - | YES | docs/simulation/time-model.md; docs/marketing/marketing-scenario.md | - | - | A Quarterly Report explains authoritative changes at a Quarter Boundary. |
| report-contract | Report content contract | LEAF | COMPLETE | - | YES | docs/marketing/marketing-scenario.md; docs/simulation/time-model.md | docs/marketing/marketing-scenario.md | docs/implementation/marketing-slice-backlog.md | The Marketing Scenario specifies required opening and ending report data. |
| report-data | Produce report data | LEAF | COMPLETE | - | YES | docs/simulation/time-model.md; docs/marketing/marketing-scenario.md | game/simulation/rules/quarterly_report_compiler.gd; game/simulation/rules/create_quarterly_report_rule.gd | game/tests/simulation/quarterly_report_test.gd | The Simulation Core compiles opening and ending Quarterly Report data from authoritative Game State. |
| report-presentation | Present the report | LEAF | COMPLETE | - | YES | docs/gameplay/core-loop.md; docs/marketing/marketing-slice.md; docs/presentation/panel-system.md | game/host/marketing_play_overlay.gd; game/ui/campaign/panels/timeline_panel.gd | game/tests/host/marketing_play_host_test.gd; game/tests/host/panel_system_test.gd | The Marketing Slice overlay presents Quarterly Report kind, Month Step, and Cash. The Campaign event timeline presents Quarterly Reports with Notifications and Attention Events. |
| report-history | Preserve report history | LEAF | PARTIAL | - | NO | docs/simulation/time-model.md; docs/presentation/panel-system.md | game/ui/campaign/panels/timeline_panel.gd | game/tests/host/panel_system_test.gd | The Campaign event timeline presents report history for the active campaign. Persistent save history remains open. |

## Edges

| From | To | Label |
| --- | --- | --- |
| report-flow | report-contract | follows |
| report-contract | report-data | constrains |
| report-data | report-presentation | supplies |
| report-presentation | report-history | can retain |
