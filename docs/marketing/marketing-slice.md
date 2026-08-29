# Marketing slice

## Purpose

The Marketing Slice must produce representative Steam page assets as soon as possible.

The Marketing Slice must validate the product promise before full production.

The Marketing Slice is not a complete vertical slice.

The Marketing Slice must use production simulation and presentation infrastructure.

The Marketing Slice must not show a result that the Simulation Core did not produce.

## Validation question

The slice must answer this question:

Can a viewer understand and want the fantasy of building an AI company, making a major investment, advancing time, and reacting to an aggressive Competitor?

## Player proof

The slice must let the player do these actions:

1. Inspect the Company Campus and current Company State.
2. Inspect the projected evaluations of a known Competitor release.
3. Compare available Research, Scale, and Application Projects.
4. Stage a Plan with limited Cash and capacity.
5. Select Advance.
6. See complete Month Steps resolve.
7. See one major Project change the Company Campus or management state.
8. See one aggressive Competitor release change the market.
9. See the causal effect on a player Model or Application.
10. Read the ending Quarterly Report.
11. Make a new Plan after the Quarter Boundary.

## Marketing Scenario

The slice must contain one authored Marketing Scenario.

The authored Marketing Scenario must follow `docs/marketing/marketing-scenario.md`.

The Marketing Scenario must use the Standard difficulty profile.

The Marketing Scenario must contain one HQ Site.

The HQ Site must contain predetermined laboratory Site Plots.

HQ, Data Center, and Government Worlds must follow `docs/presentation/world-map.md`.

The Marketing Scenario must start with at least one released player Model.

The Marketing Scenario must contain at least one available Project in each Strategic Domain.

The Marketing Scenario must contain one Application opportunity.

The Marketing Scenario must contain one aggressive Competitor.

The Research Project must create one new player Model version.

The Research Project start Command must define the Model display name, version label, and Release Strategy.

The opening Quarterly Report must identify the quarter of the next flagship Competitor Model release.

The opening Quarterly Report must show a Projected Evaluation Range for the Competitor Model.

The Competitor must release a stronger or better-positioned Model at the ending Quarter Boundary.

The Competitor release must change the technical frontier or customer expectations.

The actual evaluation results must become visible at the ending Quarter Boundary.

The Marketing Scenario must reach one Quarter Boundary.

The same initial state and Commands must produce the same result.

The Scale Project must buy or reserve Third-Party Compute.

Third-Party Compute presentation must use the Data Center World.

The Marketing Slice must not require construction of an owned Data Center.

The Coding Agent Project must create a Coding Agent.

The Coding Agent must use the released player Model that its Project start Command identifies.

## Required simulation infrastructure

The slice must implement the canonical Game State.

The slice must implement Plan validation and commitment.

The slice must implement `step_month`.

The slice must implement `advance_until_attention_required`.

The slice must implement the Cash Ledger.

The slice must implement Projects with whole-month duration.

The slice must implement one Competitor Stage transition.

The slice must implement derived Model technical competitiveness and market relevance calculations.

The slice must implement Attention Events and Notifications.

The slice must implement the Quarterly Report.

The slice must produce a Simulation Trace.

## Required developer infrastructure

The slice must include the Simulation Laboratory.

The laboratory must run the Marketing Scenario without the production presentation.

The laboratory must support one Month Step and one complete Quarter run.

The laboratory must support deterministic replay.

The slice must include the Rule Graph compiler.

The graph view must highlight the Marketing Scenario trace.

## Required presentation infrastructure

The slice must use the orthographic isometric HQ World view.

The player can pan and zoom that view.

The camera must not rotate.

The slice must show at least one laboratory Site Plot change.

The slice must show a visible Research, Scale, or Application state change.

An Application state change must not require an HQ Application building.

The slice must include a final visual system for the main management interface.

The slice must include a final visual system for Project selection.

The slice must include a final visual system for events and reports.

Later content can extend these visual systems.

Later content must not require a complete visual replacement.

The interface must show important Cash, Compute Capacity, trust, and Model information.

The interface must keep the Company Campus visible during normal planning.

## Steam screenshots

The slice must produce these distinct screenshot subjects:

1. Company Campus overview with the main management interface.
2. Research Project selection with a visible Company Campus response.
3. Third-Party Compute contract with cost and Compute Capacity.
4. Application and Model relationship with Revenue information.
5. Competitor release event with the causal market effect.
6. Quarterly Report with the changed strategic position.

Each screenshot must come from the running game.

Each screenshot must use the representative art direction.

Each screenshot must show a different player question.

Placeholder art must not appear in a Steam screenshot.

## Trailer sequence

The first trailer must show the primary loop.

The first trailer must use recorded runtime footage for gameplay claims.

The target sequence is:

1. Show the Company Campus and the AI company fantasy.
2. Show the Research, Scale, and Application alternatives.
3. Show the player commit a costly Plan.
4. Show Advance and visible Project progress.
5. Show the projected Competitor evaluations.
6. Show the aggressive Competitor release at the Quarter Boundary.
7. Show the player Model or Application lose competitive position.
8. Show the Quarterly Report and the next difficult decision.
9. Show the title and Steam call to action.

The trailer must not depend on a separate firing cinematic.

A catastrophic AI event is optional for this slice.

A catastrophic AI event must use the production event system if it appears.

A catastrophic AI event must not imply complete end-game behavior that does not exist.

## Completion gates

The Marketing Slice is complete only when all gates pass.

### Rule gate

- The Marketing Scenario must replay deterministically.
- All Simulation Invariants must pass.
- The Rule Graph compiler must pass.
- The Simulation Trace must identify the cause of the Competitor effect.

### Product gate

- A new player must be able to describe the Plan and Advance loop.
- A new player must be able to identify the effect of one investment.
- A new player must be able to identify the cause of the competitive setback.
- A new player must reach the Quarter Boundary without developer help.

### Marketing gate

- The screenshots must be visually representative of the planned game.
- The trailer must show real interaction and real state changes.
- The store assets must show Research, Scale, Applications, and competitive pressure.
- The store assets must not depend on content that is outside the slice.

## Excluded scope

The Marketing Slice must not include a complete technology tree.

The Marketing Slice must not include freeform building placement.

The Marketing Slice must not include a complete city simulation.

The Marketing Slice must not include a complete Competitor simulation.

The Marketing Slice must not include multiple difficulty profiles.

The Marketing Slice must not include procedural event generation.

The Marketing Slice must not include Robots.

The Marketing Slice must not include a complete campaign ending.

The Marketing Slice must not include a separate day-level resolver.

## Implementation order

The Marketing Slice backlog must own the implementation order and task status.

The implementation must follow `docs/implementation/marketing-slice-backlog.md`.

Full production must not start before the slice produces a clear validation result.
