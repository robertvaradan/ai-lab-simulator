# Time model

## Calendar

The simulation calendar must use whole months.

The first month of a campaign must have index 1.

Month index 0 must mean that no Month Step has resolved.

A Quarter must contain three resolved Month Steps.

After a resolved Month Step N, `current_quarter_index` must equal the ceiling of N divided by 3.

The calendar must not use day-level game rules in the first implementation.

## Planning State

The production game must enter Planning State at campaign start.

The production game must enter Planning State after each Attention Boundary.

Time must not progress in Planning State.

Commands in Planning State must remain uncommitted until Advance starts.

The Simulation Host must keep the uncommitted draft Plan outside Game State.

## Advance Operation

The Advance Operation must validate the complete Plan.

The Advance Operation must create one Pending Command Batch from the complete Plan.

The Advance Operation must pass the committed Plan candidate directly to time advancement.

The Advance Operation must not publish the committed Plan candidate before time advancement.

The Advance Operation must resolve one or more Month Steps.

The Advance Operation must stop after the Month Step that creates an Attention Boundary.

The Advance Operation must stop at every Quarter Boundary in the first implementation.

The Advance Operation must return to Planning State after it stops.

The Advance Operation must publish one final candidate Game State.

The Advance Operation must emit one Game State change.

The Advance Operation must retain the Plan commitment trace before the Month Step traces.

The Advance Operation must discard its complete candidate Game State if one internal operation faults.

## Month Step

A Month Step must be atomic from the player perspective.

`step_month` and `advance_until_attention_required` must use the same Month Step pipeline.

A Month Step must use the canonical Rule phases.

The canonical Rule phases are:

1. Open the Month Step.
2. Consume the Pending Command Batch.
3. Post committed costs and reservations.
4. Advance active Projects.
5. Resolve Project completions.
6. Advance Competitors.
7. Resolve Market changes.
8. Resolve contracts, Revenue, and operating costs.
9. Resolve trust and government effects.
10. Evaluate loss conditions.
11. Create Attention Events and Notifications.
12. Close the Month Step.

The Open Month Step phase must increase `current_month_step_index` by one before later phases run.

The Open Month Step phase must set `current_quarter_index` from the new month index.

The Advance active Projects phase must reduce remaining Project duration by one Month Step in the start Month Step.

A Project with duration of one Month Step must complete in its start Month Step.

Close the Month Step must not change the month index.

Each Rule must execute in one declared phase.

The Rule registry must define the order inside each phase.

A Rule Graph compiler must order Rules by canonical phase, then by order inside the phase.

All events in one Month Step must resolve before the Month Step closes.

The first Month Step after Planning must consume the Pending Command Batch.

Later Month Steps in the same Advance Operation must not consume that batch again.

## Quarter Boundary

A Quarter Boundary must occur after each third Month Step.

A Quarter Boundary must create a blocking Attention Event.

The first marketing slice must create the Quarter Boundary Attention Event before it creates the Quarterly Report.

Until the Quarterly Report exists, the publishable Quarter Boundary Game State must contain the Attention Event.

Until the Quarterly Report exists, the publishable Quarter Boundary Game State must not contain a Quarterly Report.

A Quarter Boundary must create a Quarterly Report.

A Quarterly Report must summarize the three resolved Month Steps.

A Quarterly Report must include Cash changes.

A Quarterly Report must include Project changes.

A Quarterly Report must include Model and Application changes.

A Quarterly Report must include important Competitor and Market changes.

A Quarterly Report must include trust changes.

A Quarterly Report must list known flagship Competitor release quarters.

A Quarterly Report can show Projected Evaluation Ranges for known Competitor releases.

A flagship Competitor Model release must resolve during the Advance Competitors phase of the Month Step that ends the applicable Quarter.

The first marketing slice must release the Northstar flagship Model during Month Step 3.

The release Rule must not wait for the Create Attention Events phase.

## Required attention

An event definition must declare if it requires attention.

The resolver must not infer required attention from display text.

All required events for the current Month Step must enter one Attention Event batch.

Each required event must have a stable identifier.

Each required event must declare its typed input requirement.

The Attention Event batch must use a stable order.

The player must resolve the complete required batch before the next Advance Operation.

The player can resolve required events independently.

Time must not advance while one required event remains unresolved.

The publishable candidate Game State must contain the unresolved Attention Event batch.

## Tool time control

The Simulation Laboratory can call `step_month` directly.

The Simulation Laboratory can call `advance_until_attention_required` directly.

The Simulation Laboratory can run a specified number of Month Steps.

The Simulation Laboratory can run to a terminal state.

A long tool run must call the same `step_month` operation for each month.

A long tool run must not use a separate year resolver.

A long tool run must stop with `DECISION_REQUIRED` when its policy cannot supply required input.
