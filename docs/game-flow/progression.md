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
| unlock-system | Capability unlocks | LEAF | PARTIAL | - | NO | docs/gameplay/progression.md; docs/gameplay/skill-tree.md | game/host/campaign_host.gd; game/host/campaign_catalog.gd | game/tests/host/skill_tree_test.gd | The simple skill tree spends research points. The complete capability catalog does not exist. |
| skill-tree | Company skill tree | LEAF | PARTIAL | - | NO | docs/gameplay/skill-tree.md; docs/gameplay/progression.md | game/host/skill_tree_view.gd; game/host/campaign_catalog.gd | game/tests/host/skill_tree_test.gd | The campaign presents one research-point tree with fake branch skills. The complete specialization tree does not exist. |
| trust-activation | Trust activation thresholds | LEAF | COMPLETE | - | NO | docs/gameplay/progression.md; docs/gameplay/domain-model.md | game/host/trust_threshold.gd | game/tests/host/skill_tree_test.gd | Public Trust activates at peak evaluation 80. Government activates at peak evaluation 90. |
| campaign-progression | Campaign progression | LEAF | NONE | - | NO | docs/gameplay/progression.md; docs/gameplay/difficulty-and-loss.md | - | - | Campaign-level progression and difficulty integration do not exist. |

## Edges

| From | To | Label |
| --- | --- | --- |
| progression-flow | prerequisites | begins with |
| prerequisites | unlock-system | generalizes to |
| unlock-system | skill-tree | feeds |
| skill-tree | campaign-progression | shapes |
| progression-flow | trust-activation | also gates |
