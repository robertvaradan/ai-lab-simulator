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
| state-contracts | Market state contracts | LEAF | PARTIAL | - | YES | docs/gameplay/domain-model.md; docs/gameplay/progression.md | game/simulation/state/competitor_state.gd; game/simulation/state/market_state.gd; game/simulation/state/model_state.gd | - | Typed state exists, but the causal Market rules do not exist. |
| forecasts | Competitor forecasts | LEAF | NONE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | - | - | Projected Evaluation Ranges do not exist in executable Scenario behavior. |
| competitor-release | Competitor release | LEAF | NONE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | - | - | The known Quarter Boundary release and deterministic results do not exist. |
| technical-position | Technical competitiveness | LEAF | NONE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | - | - | The technical frontier and technical competitiveness rules do not exist. |
| market-relevance | Market relevance | LEAF | NONE | - | YES | docs/gameplay/progression.md; docs/marketing/marketing-scenario.md | - | - | Market relevance, demand, and Revenue effects do not exist. |

## Edges

| From | To | Label |
| --- | --- | --- |
| market-flow | state-contracts | stores |
| state-contracts | forecasts | supports |
| forecasts | competitor-release | precedes |
| competitor-release | technical-position | changes |
| technical-position | market-relevance | contributes to |
