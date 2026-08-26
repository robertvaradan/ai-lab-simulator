# ADR-0002: Typed Game State publication

## Status

Accepted.

## Context

The dwarfgame repository contains the ValEcho framework.

ValEcho provides value storage and synchronous change notification.

FuncEcho provides computed values through C# expression trees.

SyncedValEcho adds Steam authority and replication behavior.

AI Lab Simulator uses strictly typed GDScript.

GDScript does not provide the C# generic and expression-tree contracts that the current framework uses.

The Simulation Core also requires atomic state replacement and invariant validation.

Synchronous per-value propagation can expose an incomplete state during a Simulation Core operation.

## Decision

The project must reuse the observable state concept.

The project must not port the complete ValEcho framework.

The project must implement one concrete `GameStateEcho` type for the first simulation foundation.

Each Simulation Host must receive `GameStateService` through its `ServiceContext`.

`GameStateService` must own one `GameStateEcho`.

`GameStateEcho` must be a runtime `RefCounted` object.

`GameStateEcho` must publish only a complete and valid committed Game State.

Authoritative Game State must remain a typed `Resource` graph.

`GameStateEcho` must wrap the complete committed Game State root.

`GameStateEcho` must not replace fields in the Game State graph with Echo objects.

The project must not serialize `GameStateEcho` or its listeners.

The Simulation Core must not use Echo objects for authoritative fields.

The first implementation must not port ValueNotifier.

The first implementation must not port FuncEcho.

The Marketing Slice must not port SyncedValEcho.

The first implementation must not use a `Variant`-backed generic value API.

An initial presentation update must be explicit.

A successful Game State replacement must notify listeners exactly once.

An invalid result must not notify listeners.

## Consequences

The Simulation Core can complete and validate a state operation before presentation observes it.

The production game and Simulation Laboratory can observe the same committed Game State contract.

The saved `.tres` data remains independent of runtime listeners.

The first implementation does not provide automatic computed dependency discovery.

A presentation calculation must read the committed Game State directly.

The project can add concrete typed Echo classes when a demonstrated requirement exists.

A later computed Echo graph requires a new approved contract for explicit dependencies, stable order, cycle rejection, and batched evaluation.
