# Simulation Laboratory contract

This directory owns developer simulation controls and reports.

- Follow `../../../docs/tools/simulation-laboratory.md`.
- Call the public Simulation Core operations.
- Do not implement game rules in this directory.
- Keep Policies explicit and selectable.
- Do not select a default Policy.
- Stop with `DECISION_REQUIRED` when a Policy cannot provide required input.
- Preserve seeds, Commands, traces, and snapshots for replay.
- Exclude this interface from production exports.
- Fail when a replay result differs.

Do not repair or replace an invalid Simulation Core result.
