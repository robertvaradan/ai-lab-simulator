# Competitor, Market, and Model position

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | market-position |
| Title | Competitor, Market, and Model position |
| Root Node | market-flow |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| market-flow | Market position flow | BRANCH | DERIVED | - | YES | docs/gameplay/progression.md | - | - | Competitor information and releases change technical and market position. |
| state-contracts | Market state contracts | LEAF | COMPLETE | - | YES | docs/gameplay/domain-model.md; docs/gameplay/progression.md | game/simulation/state/competitor_state.gd; game/simulation/state/market_state.gd; game/simulation/state/model_state.gd; game/simulation/state/application_state.gd | game/tests/simulation/game_state_test.gd | Typed Competitor, Market, Model, and Application state exist. |
| forecasts | Competitor forecasts | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | game/simulation/content/competitor_definition.gd; game/simulation/content/competitor_forecast.gd | game/tests/simulation/competitor_release_test.gd | Projected Evaluation Ranges exist as content and do not reveal actual evaluations. |
| competitor-release | Competitor release | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | game/simulation/rules/advance_competitors_rule.gd | game/tests/simulation/competitor_release_test.gd | The known Quarter Boundary release writes actual evaluations, frontier, and customer expectation. |
| technical-position | Technical competitiveness | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | game/simulation/rules/coding_agent_market.gd | game/tests/simulation/market_effects_test.gd | Technical competitiveness equals Model evaluation minus the current technical frontier. |
| market-relevance | Market relevance | LEAF | COMPLETE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | game/simulation/rules/coding_agent_market.gd; game/simulation/rules/post_application_revenue_rule.gd | game/tests/simulation/market_effects_test.gd | Relevance, demand, and Revenue derive from the supporting Model and customer expectation. |

## Edges

| From | To | Label |
| --- | --- | --- |
| market-flow | state-contracts | stores |
| state-contracts | forecasts | supports |
| forecasts | competitor-release | precedes |
| competitor-release | technical-position | changes |
| technical-position | market-relevance | contributes to |
