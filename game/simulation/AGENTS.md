# Simulation Core contract

This directory owns authoritative simulation code.

- Follow the canonical specifications in `../../docs/simulation`.
- Follow the module paths in `../../docs/simulation/module-layout.md`.
- Keep simulation code independent of Godot scenes, Nodes, controls, animation, audio, and rendering.
- Receive state, Commands, content version, and random seed as explicit inputs.
- Return state and a Simulation Trace as explicit outputs.
- Use one registered Rule implementation for production, tools, tests, and graph metadata.
- Route all state reads, state writes, event emission, ledger transactions, and random draws through the Simulation Context.
- Use stable iteration order.
- Do not read wall-clock time.
- Do not read presentation state.
- Do not add a simplified resolver for long tool runs.
- Fail on unknown identifiers, missing state, undeclared state access, invalid Rule metadata, and invariant violations.
- Do not add a default decision when input is required.
- Add the owning specification reference to each Rule definition.

Do not add fallback behavior for an invalid simulation contract.
