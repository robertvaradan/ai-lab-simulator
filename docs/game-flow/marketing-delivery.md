# Marketing delivery

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | marketing-delivery |
| Title | Marketing Slice delivery |
| Root Node | delivery-flow |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| delivery-flow | Marketing delivery flow | BRANCH | DERIVED | - | YES | docs/marketing/marketing-slice.md; docs/implementation/marketing-slice-backlog.md | - | - | The Marketing Slice moves from an executable Scenario to market assets and validation. |
| scenario-contract | Define Marketing Scenario | LEAF | COMPLETE | - | YES | docs/marketing/marketing-scenario.md; docs/marketing/marketing-slice.md | docs/marketing/marketing-scenario.md | docs/implementation/marketing-slice-backlog.md | The canonical executable Scenario contract is complete. |
| simulation-skeleton | Build simulation walking skeleton | LEAF | COMPLETE | - | YES | docs/simulation/README.md; docs/implementation/marketing-slice-backlog.md | game/simulation/core/simulation_core.gd; game/simulation/validation/simulation_invariant_checker.gd | game/tests/simulation/invariants_replay_test.gd | Milestone 1 is complete through Simulation Invariants and replay tests. |
| developer-inspection | Build developer inspection tools | LEAF | PARTIAL | - | YES | docs/tools/simulation-laboratory.md; docs/simulation/rule-graph.md | game/tools/simulation_lab/simulation_lab_session.gd | game/tests/tools/simulation_lab_test.gd | The minimal Simulation Laboratory exists. The Rule Graph artifact and trace view do not exist. |
| production-slice | Build production presentation | LEAF | NONE | - | YES | docs/marketing/marketing-slice.md | - | - | The production game does not provide the representative management experience. |
| screenshots | Capture Steam screenshots | LEAF | NONE | - | YES | docs/marketing/marketing-slice.md | - | - | Approved screenshots from the running game do not exist. |
| trailer | Record first trailer | LEAF | NONE | - | YES | docs/marketing/marketing-slice.md | - | - | Source footage and the first trailer do not exist. |
| validation | Run Marketing Slice validation | LEAF | NONE | - | YES | docs/marketing/marketing-slice.md | - | - | The Rule, Product, and Marketing gate result does not exist. |

## Edges

| From | To | Label |
| --- | --- | --- |
| delivery-flow | scenario-contract | begins with |
| scenario-contract | simulation-skeleton | constrains |
| simulation-skeleton | developer-inspection | enables |
| developer-inspection | production-slice | supports |
| production-slice | screenshots | supplies |
| screenshots | trailer | precedes |
| trailer | validation | enables |
