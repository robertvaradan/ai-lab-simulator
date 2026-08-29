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
| report-data | Produce report data | LEAF | NONE | - | YES | docs/simulation/time-model.md; docs/marketing/marketing-scenario.md | - | - | The Simulation Core does not produce Quarterly Report data. |
| report-presentation | Present the report | LEAF | NONE | - | YES | docs/gameplay/core-loop.md; docs/marketing/marketing-slice.md | - | - | The production game does not present a Quarterly Report. |
| report-history | Preserve report history | LEAF | NONE | - | NO | docs/simulation/time-model.md | - | - | Report history outside the Marketing Scenario does not exist. |

## Edges

| From | To | Label |
| --- | --- | --- |
| report-flow | report-contract | follows |
| report-contract | report-data | constrains |
| report-data | report-presentation | supplies |
| report-presentation | report-history | can retain |
