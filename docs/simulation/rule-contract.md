# Rule contract

## Rule identity

Each Rule must have a stable Rule identifier.

A Rule identifier must not change when display text changes.

A retired Rule identifier must not be reused.

Each Rule must reference its owning specification.

## Rule metadata

Each Rule must declare the following metadata:

- Rule identifier.
- Display name.
- Rule phase.
- Execution order or explicit order dependencies.
- State paths that the Rule reads.
- State paths that the Rule writes.
- Events that the Rule consumes.
- Events that the Rule emits.
- Conditions that enable the Rule.
- Graph group.
- Owning specification references.

The metadata must be machine-readable.

The runtime evaluator and graph compiler must use the same Rule registry.

Session construction must compile and validate the Rule Graph.

A session must pin the compiled Rule Graph identifier and version.

A runtime operation must not compile or replace the Rule Graph.

## Simulation Context

A Rule must read state through the Simulation Context.

A Rule must write state through the Simulation Context.

A Rule must emit events through the Simulation Context.

A Rule must request random values through the Simulation Context.

The Simulation Context must record actual reads.

The Simulation Context must record actual writes.

The Simulation Context must record emitted events.

The Simulation Context must record random draws.

The Simulation Context must fail when a Rule reads an undeclared state path.

The Simulation Context must fail when a Rule writes an undeclared state path.

## Execution

A Rule must be a deterministic state transformation for fixed inputs.

A Rule must not access a scene.

A Rule must not access controls.

A Rule must not access wall-clock time.

A Rule must not select an alternate state path when a required path is missing.

A Rule must fail with the Rule identifier and invalid path when its contract is broken.

## Simulation Trace

The Simulation Trace must record each evaluated Rule.

The Simulation Trace must record if the Rule fired, did not fire, or failed.

The Simulation Trace must record each condition result.

The Simulation Trace must record each changed value before and after the change.

The Simulation Trace must record each emitted event.

The Simulation Trace must record each ledger transaction.

The Simulation Trace must record each random draw.

The Simulation Trace must keep the stable order of execution.

The Simulation Trace must remain separate from Game State.

A faulted operation can return a partial Simulation Trace for diagnosis.

A partial Simulation Trace from a faulted operation must not represent committed history.

## Rule completion requirements

A new Rule is complete only when all these items exist:

1. A canonical specification requirement.
2. A stable Rule identifier.
3. Machine-readable metadata.
4. A deterministic evaluator.
5. A deterministic automated test.
6. Simulation Trace output.
7. A graph node and graph edges.
8. Applicable invariant checks.
9. A runnable Simulation Laboratory scenario.
