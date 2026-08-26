# Rule Graph tool contract

This directory owns Rule Graph compilation and visualization.

- Follow `../../../docs/simulation/rule-graph.md`.
- Read Rule metadata from the canonical Rule registry.
- Read runtime activity from Simulation Trace data.
- Do not copy Rule conditions or effects into graph code.
- Treat graph output as generated data.
- Fail on invalid identifiers, paths, dependencies, cycles, write order, unlocks, or specification references.
- Do not hide an invalid graph node or edge.

Do not add alternate graph data when compilation fails.
