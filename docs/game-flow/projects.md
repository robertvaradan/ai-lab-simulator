# Projects and strategic domains

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | projects |
| Title | Projects and strategic domains |
| Root Node | project-flow |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| project-flow | Project flow | BRANCH | DERIVED | - | YES | docs/gameplay/progression.md | - | - | Projects convert Plans and resources into strategic effects. |
| select-project | Select a Project | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | game/simulation/content/project_definition.gd; game/simulation/content/marketing_scenario_definition.gd | game/tests/simulation/project_lifecycle_test.gd | The Marketing Scenario defines Research, Scale, and Coding Agent Projects. |
| validate-capacity | Validate Project capacity | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/simulation/time-model.md | game/simulation/validation/project_plan_validator.gd; game/simulation/content/project_capacity.gd | game/tests/simulation/project_lifecycle_test.gd | Validation checks cost, teams, Compute Capacity, prerequisites, and duplicate starts. |
| run-project | Advance active Projects | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/simulation/time-model.md | game/simulation/rules/advance_active_projects_rule.gd; game/simulation/rules/post_committed_project_costs_rule.gd | game/tests/simulation/project_lifecycle_test.gd | Month Steps reserve resources, post costs, and reduce duration. |
| complete-project | Apply Project completion | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | game/simulation/rules/resolve_project_completions_rule.gd; game/simulation/rules/create_project_completion_notification_rule.gd | game/tests/simulation/project_lifecycle_test.gd | Completion applies the declared Marketing Scenario Project effects. |
| hybrid-plan | Preserve hybrid strategy | LEAF | COMPLETE | - | YES | docs/marketing/marketing-scenario.md; docs/gameplay/progression.md | game/simulation/validation/project_plan_validator.gd | game/tests/simulation/project_lifecycle_test.gd | Valid hybrid Plans remain available while the three-Project start is rejected. |
| full-domain-catalog | Implement all strategic domains | LEAF | NONE | - | NO | docs/gameplay/progression.md | - | - | The complete Research, Scale, Product, Finance, Operations, and Trust Project catalog does not exist. |

## Edges

| From | To | Label |
| --- | --- | --- |
| project-flow | select-project | starts with |
| select-project | validate-capacity | requires |
| validate-capacity | run-project | permits |
| run-project | complete-project | ends in |
| project-flow | hybrid-plan | allows |
| project-flow | full-domain-catalog | expands to |
