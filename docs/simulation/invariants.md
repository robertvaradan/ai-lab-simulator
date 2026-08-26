# Simulation invariants

The Simulation Core must verify these invariants after each Month Step.

## Identity

- Each entity identifier must be unique in its entity type.
- Each entity reference must resolve.
- Each active Project must reference valid Company assets.
- Each Application must reference at least one compatible Model.

## Time

- The Month Step index must increase by exactly one after `step_month`.
- A Quarter Boundary must occur after each third Month Step.
- A Project must not complete before its declared completion month.
- A completed Project must not advance again.

## Cash

- The Cash balance must equal the Cash Ledger calculation.
- Each Cash change must have one ledger transaction.
- A ledger transaction identifier must be unique.
- Ledger transaction order must remain stable in a replay.

## Capacity

- A committed allocation must not exceed available capacity unless a Rule explicitly permits debt or overcommitment.
- One exclusive Site Plot must not contain more than one active Site Upgrade.
- A completed Site Upgrade must provide only its declared capacity.

## Rules and events

- Each state write must come from the declared Rule.
- Each required event must enter the Attention Event batch.
- The resolver must not start a later Month Step while required input is unresolved.
- A Pending Command Batch must not be consumed more than once.
- A Notification must not change state after the Month Step closes.

## Determinism

- A replay with the same inputs must produce the same Game State.
- A replay with the same inputs must produce the same Simulation Trace.
- A replay with the same inputs must produce the same Cash Ledger.

## Failure

An invariant failure must stop the run.

An invariant failure must identify the invariant.

An invariant failure must identify the Month Step.

An invariant failure must include the applicable Rule identifier when one exists.
