# Simulation module layout

## Runtime modules

`game/simulation/core` must own the public Simulation Core operations.

`game/simulation/core` must own `SimulationOperationResult` and its outcome type.

`game/simulation/state` must own Game State types and serialization.

`game/simulation/rules` must own Rule evaluators and Rule metadata.

`game/simulation/content` must own Scenarios, Projects, Upgrades, Competitor Stages, and other content definitions.

`game/simulation/trace` must own Simulation Trace types.

`game/simulation/validation` must own registry validation and Simulation Invariants.

`game/simulation/host` must own shared Simulation Host runtime helpers.

`game/simulation/host` must own `GameStateEcho`.

`game/simulation/host` must own `GameStateService`.

`game/simulation/host` must own the production Advance action.

Runtime simulation modules must be included in production exports.

## Developer modules

`game/tools/simulation_lab` must own the Simulation Laboratory interface and Policies.

`game/tools/decision_host` must own the Decision Host.

`game/tools/rule_graph` must own graph compilation output and graph visualization.

`game/tests/simulation` must own automated simulation tests and test Scenarios.

Developer modules must not be included in production exports.

## Godot type contract

Authoritative simulation types must not extend `Node`.

Authoritative simulation types can extend `RefCounted` or `Resource`.

The Simulation Core must execute synchronously.

The Simulation Core must not retain changing simulation state between operations.

The Simulation Core must not use an Autoload as mutable authoritative state.

A Simulation Host must own one `GameStateService` through its `ServiceContext`.

`GameStateService` must own its Game State instance through `GameStateEcho`.

A Simulation Host can use `GameStateEcho` to publish a committed Game State.

`GameStateEcho` must use a concrete `GameState` type.

`GameStateEcho` must not use `Variant` as its value type.

`GameStateEcho` and its listeners must not be serialized with Game State.

The Simulation Context must exist for one Simulation Core operation.

The Simulation Context must not use mutable static state.

A Simulation Core operation must not mutate its input Game State.

## Registry contract

The project must create one canonical Rule registry.

The project must create one canonical content registry.

Registry construction must use explicit registration.

Registry construction must not scan alternate directories after a missing registration.

The production game, tools, tests, and graph compiler must receive the registries through explicit construction.

Session construction must compile and validate the Rule Graph from the canonical registries.

Session construction must pin the Rule Graph and content versions.

A runtime operation must not replace a pinned registry.

## Content contract

A content definition must have a stable identifier.

A content definition must contain its specification reference.

A content definition must contain its schema version.

Content definitions must contain data.

Content definitions must not contain alternate Rule implementations.

The Rule registry must own behavior.

## Generated data

Rule Graph output must go to a developer output directory.

Simulation reports must go to a developer output directory.

Generated developer output must not become authoritative input.

Generated developer output must not be included in production exports.

## Verification entry points

One headless command must run Simulation Core tests.

One headless command must compile the Rule Graph.

One headless command must run the Marketing Scenario in the Simulation Laboratory.

One headless command must run the Decision Host tests.

Each command must return a nonzero process status after a contract failure.

Each command must use the canonical Godot automation executable.
