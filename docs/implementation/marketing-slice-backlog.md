# Marketing Slice implementation backlog

## Purpose

This backlog defines the implementation order for the Marketing Slice.

This backlog does not replace a canonical specification.

Each task must follow its referenced specifications.

The team must complete a task only after its verification passes.

## Status terms

`OPEN` means that work can start after all dependencies are complete.

`BLOCKED` means that a required decision or dependency is not complete.

`ACTIVE` means that implementation is in progress.

`DONE` means that all verification requirements pass.

## Milestone 0: Executable Scenario contract

### MS0-01: Define the Marketing Scenario

Status: `DONE`

Dependencies: None.

References:

- `docs/marketing/marketing-slice.md`
- `docs/gameplay/domain-model.md`
- `docs/gameplay/progression.md`
- `docs/simulation/time-model.md`

Required output:

- Add `docs/marketing/marketing-scenario.md`.
- Define the Scenario units and Model evaluation dimensions.
- Define the starting Company State.
- Define the starting World State.
- Define the Research Project.
- Define the Scale Project.
- Define the Coding Agent Project.
- Define the projected Competitor evaluations.
- Define the actual Competitor release evaluations.
- Define the Market effects.
- Define the required ending Quarterly Report data for each scenario run.
- Define baseline Research-first, Scale-first, Application-first, and hybrid scenario runs.

Verification:

- Each value must have one approved unit.
- Each effect must identify its causal input.
- Each baseline scenario run must have an expected result.
- No requirement can depend on an unresolved system.

## Milestone 1: Simulation walking skeleton

### MS1-01: Implement stable identifiers and Game State

Status: `DONE`

Dependencies: `MS0-01`.

References:

- `docs/marketing/marketing-scenario.md`
- `docs/simulation/state-and-ledger.md`
- `docs/simulation/module-layout.md`

Required output:

- Implement the Marketing Scenario state types.
- Implement stable entity identifiers.
- Implement player Model display names and version labels.
- Implement state serialization.
- Implement cache-independent state loading.
- Implement complete load validation.
- Implement `GameStateService` and `GameStateEcho` after the first state save and load verification passes.
- Publish only complete and valid Game State replacements.

Verification:

- A save and load operation must preserve the complete authoritative state.
- A display-name change must not change a stable identifier.
- A failed load must not replace the current Game State.
- A failed load must not notify a listener.
- A successful Game State replacement must notify a listener exactly once.
- A listener must see the complete replacement Game State.

### MS1-02: Implement the Cash Ledger

Status: `DONE`

Dependencies: `MS1-01`.

References:

- `docs/simulation/state-and-ledger.md`
- `docs/simulation/invariants.md`

Required output:

- Implement immutable ledger transactions.
- Implement the derived Cash balance.
- Implement transaction ordering.

Verification:

- The Cash invariant must pass.
- Replay must produce the same ledger.

### MS1-03: Implement the Rule registry and Simulation Context

Status: `DONE`

Dependencies: `MS1-01`.

References:

- `docs/simulation/README.md`
- `docs/simulation/rule-contract.md`
- `docs/simulation/module-layout.md`

Required output:

- Implement explicit Rule registration.
- Implement Rule Graph compilation during session construction.
- Pin the Rule Graph and content versions for the session.
- Implement the synchronous and stateless Simulation Core skeleton.
- Implement `SimulationOperationResult` and its typed outcomes.
- Implement declared state reads and writes.
- Implement event emission.
- Implement Simulation Trace records.

Verification:

- Undeclared state access must fail.
- Duplicate Rule identifiers must fail.
- Invalid Rule Graph compilation must prevent session construction.
- A Game State with a different pinned version must fail validation.
- A Simulation Core operation must not mutate its input Game State.
- A fixed Rule input must produce a fixed result.

### MS1-04: Implement Plan validation and commitment

Status: `DONE`

Dependencies: `MS1-01`, `MS1-02`, and `MS1-03`.

References:

- `docs/gameplay/core-loop.md`
- `docs/simulation/README.md`

Required output:

- Implement the generic Plan, Command, and Pending Command Batch contracts.
- Keep the uncommitted draft Plan outside Game State.
- Implement complete structural Plan validation.
- Implement `PlanValidationResult`.
- Implement one Pending Command Batch.
- Revalidate the complete Plan during `commit_plan`.
- Resolve satisfied Attention Event identifiers during `commit_plan`.
- Do not implement Project-specific validation in this ticket.

Verification:

- An invalid Plan must not commit.
- A prior successful validation must not bypass commit validation.
- An Attention Event identifier without its required Plan response must not resolve the Attention Event.
- A Plan that leaves one pending Attention Event unresolved must not commit.
- A Pending Command Batch must not execute more than once.

### MS1-05: Implement Month Step and Quarter Boundary

Status: `DONE`

Dependencies: `MS1-03` and `MS1-04`.

References:

- `docs/simulation/time-model.md`
- `docs/gameplay/core-loop.md`

Required output:

- Implement the canonical Rule phases.
- Implement `step_month`.
- Implement `advance_until_attention_required`.
- Implement the Quarter Boundary.
- Implement the ordered Attention Event batch.
- Chain the production `commit_plan` result into advancement without an intermediate publication.

Verification:

- One Month Step must increase the month index by one.
- Advance must stop at the Quarter Boundary.
- Advance must stop when required input exists.
- Advance must use the same Month Step pipeline as `step_month`.
- A production Advance action must emit one Game State change.
- A faulted Advance operation must not return or publish a candidate Game State.

### MS1-06: Implement the three Marketing Scenario Projects

Status: `DONE`

Dependencies: `MS1-05`.

References:

- `docs/marketing/marketing-scenario.md`
- `docs/gameplay/progression.md`
- `docs/simulation/time-model.md`

Required output:

- Implement typed Project definitions for the Research Project, the Scale Project, and the Coding Agent Project.
- Implement Project Command payload validation.
- Implement Project cost, free project-team, free Compute Capacity, prerequisite, and duplicate-start Plan validation.
- Implement Month Step Rules for committed costs and reservations, active Project advancement, and Project completions.
- Reduce remaining Project duration in the start Month Step.

Verification:

- Each Project must use its declared cost, duration, prerequisites, and effects.
- Each Project must produce a different strategic result.
- Valid hybrid Plans must remain available.
- The project-team limit must reject a Plan that starts all three Projects.

### MS1-07: Implement Competitor forecasts and release

Status: `DONE`

Dependencies: `MS1-05` and `MS1-06`.

References:

- `docs/gameplay/progression.md`
- `docs/marketing/marketing-scenario.md`
- `docs/simulation/time-model.md`

Required output:

- Implement the known Competitor release quarter.
- Implement the Projected Evaluation Ranges.
- Implement the Quarter Boundary release.
- Implement the actual evaluation results.
- Write the technical frontier and the Coding Agent customer expectation from the release event.

Verification:

- The release must occur only at the specified Quarter Boundary.
- The projection must not reveal the exact result.
- Replay must produce the same actual evaluations.

### MS1-08: Implement Market effects and Model position

Status: `DONE`

Dependencies: `MS1-06` and `MS1-07`.

References:

- `docs/gameplay/progression.md`
- `docs/simulation/state-and-ledger.md`
- `docs/marketing/marketing-scenario.md`
- `docs/simulation/time-model.md`

Required output:

- Derive Model technical competitiveness from the current technical frontier.
- Implement Model market relevance.
- Implement Application customer demand and Revenue effects.
- Post Company operating cost, compute-contract cost, and Application Revenue in the Revenue phase.

Verification:

- Each technical competitiveness or market relevance change must identify its causal event.
- Model age alone must not change technical competitiveness or market relevance.
- Each baseline scenario run must produce its specified result.

### MS1-09: Implement the Quarterly Report

Status: `DONE`

Dependencies: `MS1-02`, `MS1-07`, and `MS1-08`.

References:

- `docs/simulation/time-model.md`
- `docs/marketing/marketing-scenario.md`

Required output:

- Implement the opening Quarterly Report data.
- Implement the ending Quarterly Report data for each scenario run.
- Include financial, Project, Model, Application, Competitor, Market, and trust information.

Verification:

- Report values must equal authoritative state.
- Report text must not create simulation state.

### MS1-10: Implement Simulation Invariants and replay tests

Status: `DONE`

Dependencies: `MS1-02` through `MS1-09`.

References:

- `docs/simulation/invariants.md`
- `docs/simulation/rule-contract.md`

Required output:

- Implement all applicable Simulation Invariants.
- Implement deterministic Marketing Scenario replays.
- Implement the three baseline scenario run tests.
- Implement the hybrid scenario run test.

Verification:

- All invariant tests must pass.
- All replay comparisons must pass.

## Milestone 2: Developer inspection tools

### MS2-01: Implement the minimal Simulation Laboratory

Status: `DONE`

Dependencies: `MS1-10`.

References:

- `docs/tools/simulation-laboratory.md`

Required output:

- Load the Marketing Scenario.
- Stage explicit Commands.
- Run one Month Step.
- Run to the next Attention Boundary.
- Inspect Game State, Cash Ledger, and Simulation Trace.
- Save and replay a run.

Verification:

- The laboratory must use the public Simulation Core operations.
- The laboratory must contain no game rules.

### MS2-02: Implement the Rule Graph compiler

Status: `DONE`

Dependencies: `MS1-03` and `MS1-10`.

References:

- `docs/simulation/rule-graph.md`

Required output:

- Compile the Marketing Scenario Rule Graph.
- Validate Rule nodes and edges.
- Export a versioned graph artifact.

Verification:

- Invalid graph contracts must fail compilation.
- Generated graph data must not contain copied Rule behavior.

### MS2-03: Implement the Rule Graph trace view

Status: `DONE`

Dependencies: `MS2-01` and `MS2-02`.

References:

- `docs/simulation/rule-graph.md`

Required output:

- Load a Simulation Trace.
- Highlight fired, inactive, and failed Rules.
- Show condition results and state changes.

Verification:

- The selected Month Step must match the displayed trace data.

## Milestone 3: Production presentation

### MS3-01: Connect the production game to the Simulation Core

Status: `DONE`

Dependencies: `MS1-10`.

References:

- `docs/gameplay/core-loop.md`
- `docs/marketing/marketing-slice.md`

Required output:

- Load the Marketing Scenario in the production game.
- Stage a Plan through the production interface.
- Run Advance through the Simulation Core.
- Present Attention Events and the Quarterly Report.

Verification:

- The production game and laboratory must produce equal results for equal inputs.

### MS3-02: Implement the representative management interface

Status: `DONE`

Dependencies: `MS3-01`.

References:

- `docs/marketing/marketing-slice.md`

Required output:

- Implement the main Company Campus interface.
- Implement Project selection.
- Implement Model naming and version input.
- Implement Projected Evaluation Ranges.
- Implement event and report presentation.

Verification:

- A player must complete the Marketing Scenario without developer controls.

### MS3-03: Implement representative world states

Status: `OPEN`

Dependencies: `MS3-01`.

References:

- `docs/product/game-contract.md`
- `docs/marketing/marketing-slice.md`

Required output:

- Implement the representative Company Campus state.
- Implement one visible Project state change.
- Implement a visible Third-Party Compute connection.
- Implement the Quarter Boundary Competitor presentation.

Verification:

- Each visual state must use authoritative simulation state.
- Each visual state must remain legible from the production camera.

## Milestone 4: Market assets and validation

### MS4-01: Capture Steam screenshots

Status: `BLOCKED`

Dependencies: `MS3-02` and `MS3-03`.

References:

- `docs/marketing/marketing-slice.md`

Required output:

- Capture all specified screenshot subjects.
- Store the source state for each screenshot.

Verification:

- Each screenshot must come from the running game.
- Placeholder art must not appear.

### MS4-02: Record the first trailer

Status: `BLOCKED`

Dependencies: `MS4-01`.

References:

- `docs/marketing/marketing-slice.md`

Required output:

- Record the specified trailer sequence.
- Preserve the source run and source footage.

Verification:

- Each gameplay claim must match Simulation Core output.

### MS4-03: Run Marketing Slice validation

Status: `BLOCKED`

Dependencies: `MS4-01` and `MS4-02`.

References:

- `docs/marketing/marketing-slice.md`

Required output:

- Run the Rule gate.
- Run the Product gate.
- Run the Marketing gate.
- Record the validation result.

Verification:

- Full production must not start before the result is recorded.
