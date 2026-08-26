# Simulation test contract

This directory owns Simulation Core tests.

- Follow `../../../docs/simulation/invariants.md`.
- Use explicit Scenarios, Commands, content versions, and seeds.
- Verify state, Simulation Trace, Cash Ledger, and Attention Events.
- Verify replay equality.
- Verify each causal Model competitiveness change.
- Test invalid contracts as failures.
- Do not update expected results without reviewing the owning specification.
- Do not use a presentation scene as the only gameplay test.

Tests must not add fallback state or default Commands.
