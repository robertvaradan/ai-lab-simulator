# Core loop

## Primary loop

The player must inspect the Company and World State.

The player must stage a Plan.

The Simulation Host must keep the draft Plan outside the authoritative Game State.

The player must select Advance to commit the Plan.

The Simulation Core must resolve complete Month Steps.

The Simulation Core must stop when input is required.

The player must inspect the new state and make the next Plan.

## Planning

Game time must not progress during Planning.

The player can inspect all known state during Planning.

The player can add, remove, or change uncommitted Commands during Planning.

The interface must show why an invalid Command cannot commit.

The game must not commit part of an invalid Plan.

## Advance

Advance must be the only normal production-game operation that progresses time.

Advance must commit the complete valid Plan.

Advance must pass the committed Plan candidate to the monthly resolver without an intermediate publication.

Advance must call the monthly resolver repeatedly.

Advance must stop at the first Attention Boundary.

Advance must not use a separate approximation path.

Advance must publish only the final candidate Game State.

Advance must emit one Game State change.

The player must not select an arbitrary future date in the production game.

The production game must not use pause, 1x, 2x, or 4x simulation controls.

## Attention Boundary

An Attention Boundary is a state that requires a new player decision.

A Quarter Boundary must be an Attention Boundary in the first implementation.

A completed training run that needs a Release Strategy must be an Attention Boundary.

A completed Research Project that needs a new selection must be an Attention Boundary.

A major Competitor release can be an Attention Boundary.

A government restriction can be an Attention Boundary.

A bankruptcy warning can be an Attention Boundary.

The Simulation Core must resolve all events in the current Month Step before it stops.

The player must not react between simultaneous events in one Month Step.

## Notifications

A Notification reports an event that does not require immediate input.

A minor Revenue change must not stop Advance by itself.

A minor project update must not stop Advance by itself.

An irrelevant Competitor action must not stop Advance by itself.

The game must batch Notifications for the resolved period.

## Player pacing

The player controls when Advance starts.

The player cannot bypass a required decision.

The player cannot skip unresolved Quarter Boundaries.

The player can submit a Plan with no new Project.

An empty Plan must still expose the player to costs, contracts, and Competitor actions.

The game must not apply automatic Model decay only because time passed.

## Presentation loop

Advance must produce a visible transition.

The transition can show calendar movement, construction progress, Cash changes, headlines, and Site changes.

The transition must use results from the Simulation Core.

The presentation layer must not create alternate results.
