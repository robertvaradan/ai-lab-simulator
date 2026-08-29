# Progression and unlocks

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | progression |
| Title | Progression, unlocks, and skill tree |
| Root Node | progression-flow |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| progression-flow | Progression flow | BRANCH | DERIVED | - | NO | docs/gameplay/progression.md | - | - | Company actions unlock capabilities and long-term specialization. |
| prerequisites | Project prerequisites | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | game/simulation/validation/project_plan_validator.gd; game/simulation/content/marketing_scenario_definition.gd | game/tests/simulation/project_lifecycle_test.gd | The Marketing Scenario Project prerequisites are enforced. |
| unlock-system | Capability unlocks | LEAF | NONE | - | NO | docs/gameplay/progression.md | - | - | The general capability unlock system does not exist. |
| skill-tree | Company skill tree | LEAF | NONE | - | NO | docs/gameplay/progression.md | - | - | The long-term specialization tree does not exist. |
| campaign-progression | Campaign progression | LEAF | NONE | - | NO | docs/gameplay/progression.md; docs/gameplay/difficulty-and-loss.md | - | - | Campaign-level progression and difficulty integration do not exist. |

## Edges

| From | To | Label |
| --- | --- | --- |
| progression-flow | prerequisites | begins with |
| prerequisites | unlock-system | generalizes to |
| unlock-system | skill-tree | feeds |
| skill-tree | campaign-progression | shapes |
