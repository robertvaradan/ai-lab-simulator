# State and ledger

## Game State

The Game State must contain all authoritative simulation data.

Every stored entity must have a stable identifier.

The Game State must contain a content version.

The Game State must contain a Game State schema version.

The Game State must identify the pinned Rule Graph and its version.

The Game State must contain a scenario identifier.

The Game State must contain the calendar state.

The Game State must contain Company State.

The Game State must contain World State.

The Game State must contain the Cash Ledger.

The Game State must not contain a draft Plan.

The Game State can contain one Pending Command Batch.

A Pending Command Batch must contain the Commands from the last committed Plan.

A Pending Command Batch must not execute more than once.

The Game State must contain Attention Events and Notifications.

The Game State can contain Quarterly Reports.

A Quarterly Report must have a stable identifier.

A Quarterly Report must not change Company State.

A Quarterly Report must not change World State.

A Quarterly Report must not change the Cash Ledger.

Each Attention Event must have a stable identifier.

Each Attention Event must have a typed input requirement.

Attention Events from one Month Step must use a stable order.

Game State must not contain a Simulation Trace.

The Game State must contain random generator state when randomness is active.

## Company State

Company State must contain Sites and Site Plots.

Company State must contain staff.

Company State must contain Compute Capacity.

Company State must contain Projects.

Company State must contain Models.

Company State must contain Applications.

Company State must contain contracts.

Company State must contain Public Trust.

Company State must contain Government Trust.

## World State

World State must contain Competitors and their current Competitor Stages.

World State must contain World Models.

A Competitor Model must live in World State.

A Competitor Model must not live in Company State.

World State must contain Market Demand.

World State must contain the current technical frontier.

World State must contain active government conditions.

## Derived values

A derived value must have one owning calculation.

A Rule must not write a derived value directly.

A cached derived value must include its input version.

A cached derived value must equal a new calculation from authoritative state.

Model technical competitiveness must derive from Model capability and the current technical frontier.

Model market relevance must derive from Model capability, Market Demand, release state, and competing offers.

Model pricing power must derive from market relevance and competing offers.

Application customer demand must derive from Market Demand, the supporting Model, price, and applicable Company effects.

The Application customer-contract count is the resolved demand for the current Month Step.

The Application customer-contract count is not a cached derived value.

## Cash Ledger

The Cash Ledger must be append-only during a campaign.

An append operation must create a new Cash Ledger.

An append operation must not change the source Cash Ledger.

Each ledger transaction must have a stable identifier.

A ledger transaction must not change after append.

Each ledger transaction must have a Month Step index.

Ledger transactions must use nondecreasing Month Step index order.

Ledger transactions in one Month Step must keep append order.

Each ledger transaction must have a source Rule identifier.

Each ledger transaction must have a category.

Each ledger transaction must have a signed amount.

Each ledger transaction must reference its source entity when one exists.

The Cash balance must equal the opening balance plus all ledger transaction amounts.

A Rule must not change the Cash balance without a ledger transaction.

A replay must produce the same ledger transaction order.

## Save and snapshot data

A snapshot must contain the complete authoritative Game State.

A snapshot must contain the content version.

A snapshot must contain the Game State schema version.

A snapshot must identify the pinned Rule Graph and its version.

A snapshot must contain the random generator state.

A snapshot must not depend on a scene tree.

An incompatible snapshot must fail with a version error.

A snapshot with a different Rule Graph, content version, or Game State schema version must be incompatible.

The loader must not guess a missing migration.

A migration must identify one source version and one target version.

A migration must create and validate a new Game State.

The loader must validate the complete loaded Game State before publication.

A failed load must not replace the Simulation Host Game State.

A failed load must not emit a Game State change.

A snapshot must not contain `GameStateEcho`.

A snapshot must not contain a listener connection.

A Game State snapshot must not contain a Simulation Trace.
