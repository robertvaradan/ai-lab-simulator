# Primary game flow

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | core-loop |
| Title | Inspect to Attention loop |
| Root Node | game-loop |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| game-loop | Complete game loop | BRANCH | DERIVED | - | NO | docs/gameplay/core-loop.md | - | - | The player inspects state, makes a plan, commits it, advances time, resolves results, and responds to attention. |
| inspect | Inspect authoritative state | LEAF | PARTIAL | - | YES | docs/gameplay/core-loop.md; docs/simulation/state-and-ledger.md | game/simulation/state/game_state.gd; game/simulation/host/game_state_echo.gd | - | Authoritative state exists, but the production game does not present it to the player. |
| plan | Create and validate a Plan | LEAF | COMPLETE | - | YES | docs/gameplay/core-loop.md; docs/simulation/README.md | game/simulation/state/plan.gd; game/simulation/validation/plan_validator.gd | game/tests/simulation/plan_commitment_test.gd | The simulation has typed Plans and complete structural validation. |
| commit | Commit the Plan | LEAF | COMPLETE | - | YES | docs/gameplay/core-loop.md; docs/simulation/time-model.md | game/simulation/core/simulation_core.gd; game/simulation/state/pending_command_batch_state.gd | game/tests/simulation/plan_commitment_test.gd | Commit revalidates the Plan and creates one pending command batch. |
| advance | Advance simulation time | LEAF | COMPLETE | - | YES | docs/gameplay/core-loop.md; docs/simulation/time-model.md | game/simulation/core/simulation_core.gd; game/simulation/host/simulation_advance_action.gd | game/tests/simulation/month_step_test.gd; game/tests/simulation/game_state_publication_test.gd | Advance runs canonical Month Steps and stops at an attention boundary. |
| resolve | Resolve simulation results | LEAF | PARTIAL | - | YES | docs/gameplay/core-loop.md; docs/simulation/time-model.md | game/simulation/rules/resolve_project_completions_rule.gd; game/simulation/rules/create_quarter_boundary_attention_rule.gd | - | Project completion and quarter attention exist, but market and report results do not exist. |
| attention | Respond to Attention Events | LEAF | PARTIAL | - | YES | docs/gameplay/core-loop.md; docs/simulation/time-model.md | game/simulation/state/attention_event_response.gd; game/simulation/validation/attention_event_response_validator.gd | - | The simulation accepts responses, but the production player interface does not exist. |
| projects | Projects and strategic domains | SUBGRAPH | DERIVED | projects | YES | docs/gameplay/progression.md | - | - | Open the Project and strategic-domain flow. |
| progression | Progression and unlocks | SUBGRAPH | DERIVED | progression | NO | docs/gameplay/progression.md | - | - | Open the progression and skill-tree flow. |
| market | Competitor, Market, and Model position | SUBGRAPH | DERIVED | market-position | YES | docs/gameplay/progression.md | - | - | Open the competitor and Market flow. |
| reports | Reports | SUBGRAPH | DERIVED | reports | YES | docs/simulation/time-model.md | - | - | Open the report flow. |
| tools | Developer tools | SUBGRAPH | DERIVED | developer-tools | YES | docs/tools/simulation-laboratory.md; docs/simulation/rule-graph.md | - | - | Open the developer-tools flow. |
| presentation | Production presentation | SUBGRAPH | DERIVED | production-presentation | YES | docs/product/game-contract.md; docs/marketing/marketing-slice.md | - | - | Open the production presentation flow. |
| marketing | Marketing delivery | SUBGRAPH | DERIVED | marketing-delivery | YES | docs/marketing/marketing-slice.md | - | - | Open the Marketing Slice delivery flow. |

## Edges

| From | To | Label |
| --- | --- | --- |
| game-loop | inspect | begins with |
| inspect | plan | informs |
| plan | commit | validates then |
| commit | advance | starts |
| advance | resolve | produces |
| resolve | attention | can require |
| attention | inspect | returns to |
| game-loop | projects | includes |
| game-loop | progression | includes |
| game-loop | market | includes |
| game-loop | reports | includes |
| game-loop | tools | supports |
| game-loop | presentation | presents through |
| game-loop | marketing | delivers through |
