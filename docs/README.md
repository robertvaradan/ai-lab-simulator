# Canonical specification index

This directory contains the canonical project specifications.

## Authority

- Each subject must have one owning specification.
- A requirement change must update the owning specification.
- A new document must not duplicate an existing specification.
- An ADR can record a decision reason.
- An ADR must not override a canonical specification.
- An `AGENTS.md` file can define implementation guardrails.
- An `AGENTS.md` file must not define alternate game rules.
- Machine-readable content must include a reference to its owning specification.
- Automated tests must verify the canonical requirements.
- A test must not become the only description of a requirement.

## Product specifications

- [Game contract](product/game-contract.md) owns the product promise and product limits.
- [Core loop](gameplay/core-loop.md) owns the player loop and the time-control contract.
- [Domain model](gameplay/domain-model.md) owns approved game terms and relationships.
- [Progression](gameplay/progression.md) owns strategic domains, unlocks, trust activation, and competitor pressure.
- [Skill tree](gameplay/skill-tree.md) owns the simple research-point skill tree.
- [Model roster exploration](gameplay/model-roster-exploration.md) records the open Model-as-unit roster question.
- [Difficulty and loss](gameplay/difficulty-and-loss.md) owns difficulty profiles and campaign loss.
- [Production bootstrap](gameplay/production-bootstrap.md) owns the production entry flow and the first playable campaign shell.
- [Playthrough backlog](gameplay/playthrough-backlog.md) records defects found during production playthrough.

## Architecture specifications

- [Services and dependency injection](architecture/services-and-dependency-injection.md) owns the service lifetime, provider, and injection contracts.
- [Editor primitives](tools/editor-primitives.md) owns voxel-grid PrimitiveMesh types for scene authoring.

## Presentation specifications

- [Isometric camera](presentation/isometric-camera.md) owns the orthographic gameplay camera.
- [World map](presentation/world-map.md) owns campaign Worlds and World navigation.
- [UI scale](presentation/ui-scale.md) owns Window content scale for readable canvas UI.
- [UI theme](presentation/ui-theme.md) owns the project Theme and the production UI fontfaces.
- [Campus authoring](presentation/campus-authoring.md) owns HQ Site campus and laboratory scene rules.
- [Color palette](visual/color-palette.md) owns named world color roles and site-palette rules.

## Simulation specifications

- [Simulation architecture](simulation/README.md) owns the shared Simulation Core boundary.
- [Simulation module layout](simulation/module-layout.md) owns code placement and dependency boundaries.
- [Time model](simulation/time-model.md) owns Planning, Advance, Month Step, and Quarter Boundary behavior.
- [State and ledger](simulation/state-and-ledger.md) owns authoritative state and transaction behavior.
- [Rule contract](simulation/rule-contract.md) owns rule metadata, execution, and trace behavior.
- [Rule graph](simulation/rule-graph.md) owns graph compilation and visualization data.
- [Simulation laboratory](tools/simulation-laboratory.md) owns developer simulation tools.
- [Decision Host](tools/decision-host.md) owns the internal click-through Plan and Advance host.
- [Simulation invariants](simulation/invariants.md) owns requirements that must remain true in all runs.

## Delivery specifications

- [Marketing slice](marketing/marketing-slice.md) owns the first market-facing implementation scope.
- [Marketing Scenario](marketing/marketing-scenario.md) owns the authored Scenario content and expected results.
- [Marketing Slice backlog](implementation/marketing-slice-backlog.md) owns the implementation order and task status.
- [Game Flow Progress Compiler](tools/game-flow-progress-compiler.md) owns the source-map and generated-viewer contracts.
- [Open decisions](open-decisions.md) records decisions that do not yet have canonical behavior.

## Decision records

- [ADR-0001](decisions/ADR-0001-shared-deterministic-simulation.md) records the shared deterministic simulation decision.
- [ADR-0002](decisions/ADR-0002-gamestate-echo.md) records the typed Game State publication decision.

## Change procedure

1. Identify the owning specification.
2. Change the requirement in that specification.
3. Update all affected cross-references.
4. Update machine-readable definitions.
5. Update automated tests.
6. Update generated graph data.
7. Record a new ADR when the architecture reason changes.

An unresolved item must remain in [Open decisions](open-decisions.md).

The runtime must not invent behavior for an unresolved item.
