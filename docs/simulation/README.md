# Simulation architecture

## Purpose

The Simulation Core must contain all authoritative game rules.

The Simulation Core must support the production game and developer tools.

The Simulation Core must be independent of scenes, controls, animation, audio, and rendering.

## Core ownership

The Simulation Core must not own the committed Game State.

Each state-changing operation must receive an input Game State.

Each state-changing operation must not mutate its input Game State.

Each state-changing operation must create a candidate Game State.

`GameStateService` must be the only owner of the committed Game State.

The Simulation Core can keep references to the pinned Rule registry, content registry, and compiled Rule Graph.

The Simulation Core must not keep changing simulation state between operations.

The Simulation Core must execute synchronously.

The Simulation Core must not depend on the Scene Tree.

The Simulation Core must not use Godot signals, timers, or `await`.

A Simulation Host can run a synchronous Simulation Core operation on a worker thread.

## Session construction

A Simulation Host must construct the Rule registry and content registry explicitly.

Session construction must compile and validate the Rule Graph.

A Rule Graph compilation failure must prevent session construction.

A session must pin one Rule Graph identifier and version.

A session must pin one content version.

A runtime Simulation Core operation must not compile or replace the Rule Graph.

A runtime Simulation Core operation must not replace the content registry.

A created or loaded Game State must identify the pinned Rule Graph and content version.

Session construction must reject a Game State that identifies a different Rule Graph, content version, or Game State schema version.

The loader must not reinterpret an incompatible Game State.

A migration must be an explicit version-to-version operation.

A migration must produce and validate a new Game State.

## Inputs

A Simulation Core operation must receive a Game State.

A Simulation Core operation must receive explicit Commands when the operation uses player input.

A Simulation Core operation must receive an explicit random seed when a rule uses randomness.

A Simulation Core operation must not read wall-clock time.

A Simulation Core operation must not read presentation state.

## Operation result contract

`commit_plan`, `step_month`, and `advance_until_attention_required` must return one concrete `SimulationOperationResult`.

`SimulationOperationResult` must contain one typed outcome.

The permitted outcomes must be `COMPLETED`, `DECISION_REQUIRED`, `REJECTED`, and `FAULTED`.

`SimulationOperationResult` must contain a Simulation Trace.

`SimulationOperationResult` must contain typed diagnostics.

A `COMPLETED` result must contain a complete and valid candidate Game State.

A `DECISION_REQUIRED` result must contain a complete and valid candidate Game State.

A `REJECTED` result must not contain a candidate Game State.

A `FAULTED` result must not contain a candidate Game State.

A `REJECTED` result must identify an expected input or business-rule rejection.

A `FAULTED` result must identify a broken state, Rule, registry, or operation contract.

A `FAULTED` result can contain the partial Simulation Trace from discarded internal work.

A partial Simulation Trace from a `FAULTED` result must be diagnostic data only.

The Simulation Core must discard all candidate state from a `FAULTED` operation.

`validate_plan` must return a concrete `PlanValidationResult`.

`validate_plan` must not return a `SimulationOperationResult`.

## Plan contract

A Simulation Host must own the uncommitted draft Plan outside Game State.

`validate_plan` must validate the complete draft Plan without changing Game State.

A successful `validate_plan` call must not authorize a later commit.

`commit_plan` must validate the complete Plan against its exact input Game State.

`commit_plan` must reject the complete Plan when one Command is invalid.

`commit_plan` must apply the complete valid Plan atomically.

`commit_plan` must create one Pending Command Batch.

A Plan must identify each pending Attention Event that it satisfies.

An Attention Event identifier alone must not satisfy an Attention Event.

Each Attention Event type must validate its required Plan response.

An Attention Event type can define acknowledgment as its required Plan response.

`commit_plan` must clear each pending Attention Event that the committed Plan satisfies.

`commit_plan` must reject a Plan that does not satisfy each pending Attention Event.

The first marketing slice must not add a separate attention-resolution operation.

## Time advancement contract

`step_month` must resolve exactly one canonical Month Step.

`advance_until_attention_required` must repeat the same canonical Month Step pipeline that `step_month` uses.

`advance_until_attention_required` must not use a separate time-resolution path.

`advance_until_attention_required` must validate the candidate Game State after each internal Month Step.

`advance_until_attention_required` must stop after the Month Step that creates an Attention Boundary.

`advance_until_attention_required` must return one result for the complete operation.

`advance_until_attention_required` must not expose an intermediate candidate Game State.

If one internal Month Step faults, `advance_until_attention_required` must discard the complete candidate Game State.

If one internal Month Step faults, the result can retain the partial Simulation Trace for diagnosis.

A `DECISION_REQUIRED` result must be a successful publishable result.

The candidate Game State in a `DECISION_REQUIRED` result must contain the complete ordered Attention Event batch.

## Host operation composition

The production Advance action must call `commit_plan` before time advancement.

The production Advance action must pass the candidate Game State from `commit_plan` to `advance_until_attention_required`.

The production Advance action must not publish the intermediate candidate Game State from `commit_plan`.

The production Advance action must publish only the final candidate Game State.

The production Advance action must emit one Game State change.

The production Advance action must retain the `commit_plan` trace before the advancement trace.

A developer tool can publish a successful `commit_plan` result as an explicit tool operation.

## Simulation Trace ownership

Game State must not contain a Simulation Trace.

Each Simulation Core operation must return its Simulation Trace separately.

A Simulation Host can retain Simulation Traces in an append-only session history.

A save system can store the session history beside the Game State when audit history is required.

## Hosts

The production game is a Simulation Host.

The Simulation Laboratory is a Simulation Host.

The Decision Host is a Simulation Host.

Editor debug controls are a Simulation Host.

Each Simulation Host must call the same public Simulation Core operations.

A Simulation Host must not duplicate a game rule.

A Simulation Host must not repair an invalid result.

## Game State publication

A Simulation Host must own one `GameStateService` through its `ServiceContext`.

`GameStateService` must own one `GameStateEcho` instance.

`GameStateEcho` must extend `RefCounted`.

`GameStateEcho` must not extend `Node` or `Resource`.

`GameStateEcho` must hold the current committed Game State.

The current committed Game State must remain a typed `Resource` graph.

An authoritative Game State field must not be an Echo object.

`GameStateEcho` must keep the previous committed Game State after the first replacement.

`GameStateEcho` must identify when no previous committed Game State exists.

A Simulation Host must publish a Simulation Core candidate Game State only from a `COMPLETED` or `DECISION_REQUIRED` result.

A Simulation Host must publish a candidate Game State only after all applicable Simulation Invariants pass.

A `REJECTED` or `FAULTED` result must not replace the current committed Game State.

A `REJECTED` or `FAULTED` result must not emit a state change.

A successful replacement must emit exactly one state change.

A listener must receive the state change after the complete Game State replacement.

A listener must see a complete and valid Game State.

Listener connection must not cause an implicit initial state change.

A Simulation Host must request its initial presentation update explicitly.

The Simulation Core must not depend on `GameStateEcho`.

The Simulation Core must not store an Echo object in authoritative Game State.

The first implementation must not add a computed Echo dependency graph.

A derived presentation value must calculate directly from the committed Game State.

If a computed Echo graph is added later, each dependency must be explicit.

The graph must reject a dependency cycle.

The graph must use a stable evaluation order.

The graph must evaluate one derived value at most once for one committed Game State replacement.

## Determinism

The same initial Game State, Commands, pinned Rule Graph, content version, and random seed must produce the same result.

The Simulation Core must use a stable rule order.

The Simulation Core must use a stable collection order.

All random draws must use the Simulation Context.

The Simulation Trace must record each random draw.

The first marketing slice must not use random outcomes unless its owning specification defines them.

## Public operations

`validate_plan(state, plan)` must validate a complete Plan.

`commit_plan(state, plan)` must validate and commit a complete Plan.

`step_month(state)` must resolve exactly one Month Step.

`advance_until_attention_required(state)` must resolve Month Steps until an Attention Boundary exists.

Rule Graph compilation must not be a public runtime Simulation Core operation.

## Error behavior

The Simulation Core must return `REJECTED` for an unknown Command.

The Simulation Core must return `REJECTED` when time progression starts while required input is unresolved.

The Simulation Core must return `FAULTED` for invalid Game State.

The Simulation Core must return `FAULTED` for invalid Rule metadata.

The Simulation Core must not select a default action when player input is required.

The Simulation Core must return `DECISION_REQUIRED` after it creates a blocking Attention Event batch.

The Simulation Core must not continue from `DECISION_REQUIRED`.
