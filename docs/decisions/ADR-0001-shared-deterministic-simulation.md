# ADR-0001: Shared deterministic Simulation Core

## Status

Accepted.

## Context

The project needs fast tests of progression and pacing.

The project also needs a production game in Godot.

A separate balance simulator can become inconsistent with production rules.

Editor cheats can test presentation but cannot efficiently test many complete campaigns.

## Decision

The project must use one deterministic Simulation Core.

The production game, Simulation Laboratory, and editor debug tools must call this core.

The project must store Rule metadata in one Rule registry.

The runtime evaluator and Rule Graph compiler must use this registry.

The Simulation Laboratory must remain outside production exports.

The project must add editor debug controls as a separate Simulation Host.

## Consequences

The project can test the simulation without final art or UI.

The project can reproduce a balance failure from a seed and Command history.

The project can generate the Rule Graph from runtime contracts.

Each gameplay change requires metadata, trace data, graph data, tests, and a specification update.

This additional work is an accepted cost.

The project must not maintain a second simplified rules engine.
