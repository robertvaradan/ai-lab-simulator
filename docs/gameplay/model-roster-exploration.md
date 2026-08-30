# Model roster exploration

## Authority

This file records an open product exploration.

This file does not define runtime behavior.

An implementation must not invent an answer from this file.

The owning TODO lives in `docs/open-decisions.md`.

## Question

A base Research result must produce a Model.

The Company cannot make money without a Model.

The current Marketing Scenario starts with released Model Aperture 1.0.

That starting Model lets the Coding Agent create Revenue before new Research.

The desired loop requires a first Research result before the Company can sell anything.

## RTS comparison

A real-time strategy game trains units.

A player spends resources to produce a unit.

That unit has a role in the current fight.

A later building or technology unlocks a stronger unit.

The player then trains the stronger unit.

The older unit stays on the field until it dies, the player stops making it, or the player replaces it.

A Model can use the same shape:

- Research is the training action.
- A Model is the trained unit.
- An Application is the fight that needs a unit.
- A later Research result produces a stronger Model.
- The player then uses the stronger Model in Applications.

The written Model obsolescence rule already matches part of this idea.

A Model must not lose value only because its age increases.

A Competitor release, a Market event, or a customer-expectation change can reduce Model value.

That is closer to a counter-unit or a tech-switch than to a timer.

## Useful matches

Research produces the thing the Company sells.

A first Model is a weak starting unit.

A later Model is an upgraded unit.

The player can keep an old Model.

The player can stop using an old Model.

The player can assign a new Model to an Application.

## Differences from a unit roster

A Model is not consumed when it works.

One Model can support more than one Application.

A retired Model does not need a death animation or a lost-unit count.

The game already forbids freeform unit placement.

The game already uses Projects with whole-month duration.

## Open questions

- Must the campaign start with no player Model?
- Does the first Research Project always produce a sellable Model?
- Can more than one Model create Revenue in the same Month Step?
- Does the player retire a Model with an explicit Command?
- Does an Application switch Models through a new Project?
- Does a retired Model stay in Company State?
- What happens to active contracts when the supporting Model retires?

## Next work

Close this exploration with a specification change before any implementation.

The specification change must state the starting Model rule.

The specification change must state the retirement or replacement rule.

The specification change must keep Competitor pressure as a first-class beat.
