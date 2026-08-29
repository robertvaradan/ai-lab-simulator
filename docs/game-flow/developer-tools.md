# Developer tools

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | developer-tools |
| Title | Developer simulation tools |
| Root Node | tool-flow |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| tool-flow | Developer tool flow | BRANCH | DERIVED | - | YES | docs/tools/simulation-laboratory.md; docs/simulation/rule-graph.md | - | - | Developer tools use the public Simulation Core and show exact simulation behavior. |
| trace-data | Produce Simulation Trace data | LEAF | COMPLETE | - | YES | docs/simulation/rule-contract.md; docs/tools/simulation-laboratory.md | game/simulation/trace/simulation_trace.gd; game/simulation/trace/rule_evaluation_trace_record.gd | game/tests/simulation/simulation_core_test.gd | Simulation operations record typed trace data. |
| laboratory | Simulation Laboratory | LEAF | COMPLETE | - | YES | docs/tools/simulation-laboratory.md | game/tools/simulation_lab/simulation_lab_session.gd | game/tests/tools/simulation_lab_test.gd | The laboratory session loads the Marketing Scenario and calls public Simulation Core operations. |
| replay-tool | Save and replay a run | LEAF | COMPLETE | - | YES | docs/tools/simulation-laboratory.md; docs/simulation/invariants.md | game/tools/simulation_lab/simulation_lab_session.gd | game/tests/tools/simulation_lab_test.gd | The laboratory exports Commands, saves snapshots, and fails when a replay result differs. |
| runtime-rule-graph | Validate the runtime Rule Graph | LEAF | COMPLETE | - | YES | docs/simulation/rule-graph.md; docs/simulation/rule-contract.md | game/simulation/rules/simulation_rule_graph_compiler.gd; game/simulation/rules/compiled_rule_graph.gd | game/tests/simulation/simulation_core_test.gd | Session construction compiles and validates the runtime Rule Graph. |
| graph-export | Export the Rule Graph artifact | LEAF | COMPLETE | - | YES | docs/simulation/rule-graph.md | game/tools/rule_graph/rule_graph_artifact_compiler.gd; game/tools/rule_graph/rule_graph_artifact.gd | game/tests/tools/rule_graph_artifact_test.gd | The compiler exports a versioned Rule Graph artifact without copied Rule bodies. |
| trace-view | View Rule Graph trace state | LEAF | COMPLETE | - | YES | docs/simulation/rule-graph.md | game/tools/rule_graph/rule_graph_trace_classifier.gd; game/tools/simulation_lab/simulation_lab_session.gd | game/tests/tools/rule_graph_trace_view_test.gd | The laboratory classifies fired, inactive, and failed Rules for a selected Month Step. |

## Edges

| From | To | Label |
| --- | --- | --- |
| tool-flow | trace-data | receives |
| trace-data | laboratory | supports |
| laboratory | replay-tool | provides |
| tool-flow | runtime-rule-graph | includes |
| runtime-rule-graph | graph-export | can export to |
| graph-export | trace-view | supplies |
