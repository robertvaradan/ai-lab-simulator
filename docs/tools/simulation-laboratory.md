# Simulation Laboratory

## Purpose

The Simulation Laboratory must let developers test the Simulation Core without the production presentation.

The Simulation Laboratory must help developers test progression, pacing, balance, and failure states.

The Simulation Laboratory must not contain alternate game rules.

## Build boundary

The Simulation Laboratory must exist outside production runtime code.

Production exports must exclude the Simulation Laboratory interface.

Production exports must include the same Simulation Core and content registry that the laboratory uses.

## Interactive operation

The laboratory must load a Scenario.

The laboratory must load a specified random seed.

The laboratory must show the current Game State.

The laboratory must let a developer stage Commands.

The laboratory must validate the Plan.

The laboratory must run one Month Step.

The laboratory must run until the next Attention Boundary.

The laboratory must run a specified number of Month Steps.

The laboratory must run to a terminal state.

The laboratory must stop with `DECISION_REQUIRED` when no policy supplies required input.

## Policy operation

A Policy is a developer-only Command provider.

A Policy must have a stable identifier.

A Policy must receive only the state that a player can know unless the test declares full-state access.

A Policy must return explicit Commands.

A Policy must not change Game State directly.

The laboratory must not select a default Policy.

## Batch operation

The laboratory must run multiple campaigns with specified Scenarios, seeds, and Policies.

The laboratory must record completion month.

The laboratory must record terminal state.

The laboratory must record Cash history.

The laboratory must record Strategic Domain investment history.

The laboratory must record Model releases.

The laboratory must record competitor-caused Model technical competitiveness and market relevance changes.

The laboratory must record invariant failures.

## Inspection

The laboratory must show the Simulation Trace for a selected Month Step.

The laboratory must show the Cash Ledger.

The laboratory must show active Projects and completion months.

The laboratory must show Attention Events and Notifications.

The laboratory must open the compiled Rule Graph.

The laboratory must highlight the selected Simulation Trace on the Rule Graph.

## Snapshot and replay

The laboratory must save a state snapshot.

The laboratory must load a compatible state snapshot.

The laboratory must export Commands for a run.

The laboratory must replay exported Commands.

The laboratory must compare replay results with the original results.

The laboratory must fail when the replay differs.
