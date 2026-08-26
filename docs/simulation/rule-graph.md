# Rule graph

## Purpose

The Rule Graph must show the complete registered rule system.

The Rule Graph must use the same registry as the Simulation Core.

The Rule Graph must not contain hand-maintained copies of Rule behavior.

## Graph compiler

`compile_rule_graph(registry)` must validate the Rule registry.

Session construction must call the Rule Graph compiler before it accepts a Game State.

Rule Graph compilation must not be a public runtime Simulation Core operation.

The Simulation Laboratory and automated tools can call the same compiler explicitly.

The compiler must fail on a duplicate Rule identifier.

The compiler must fail on an unknown state path.

The compiler must fail on an unknown event type.

The compiler must fail on a missing order dependency.

The compiler must fail on a same-step dependency cycle.

The compiler must fail when two Rules write the same state path without explicit order.

The compiler must fail on an orphan Upgrade or unlock node.

The compiler must fail on a missing specification reference.

## Graph data

The compiled graph must contain Rule nodes.

The compiled graph must contain state-path nodes.

The compiled graph must contain event nodes.

The compiled graph must contain Project, Upgrade, and unlock nodes when registered.

The compiled graph must identify read edges.

The compiled graph must identify write edges.

The compiled graph must identify event edges.

The compiled graph must identify order edges.

The compiled graph must identify unlock edges.

The compiled graph must identify temporal edges.

A temporal edge must show that a later Month Step consumes an earlier result.

A temporal cycle can exist when each cycle edge is marked as temporal.

## Hierarchy

The graph must group Rules by Rule phase.

The graph can group Rules by Strategic Domain.

The graph can group Rules by Quarter behavior.

The graph can group Rules by progression content.

The graph view must allow a user to expand and collapse groups.

## Runtime state view

The graph view must load a Simulation Trace.

The graph view must highlight fired Rules.

The graph view must identify Rules that did not fire.

The graph view must identify failed Rules.

The graph view must show condition results for a selected Rule.

The graph view must show before and after values for a selected write edge.

The graph view must show the selected Month Step.

## Output

The compiler must create a versioned graph artifact.

The graph artifact must include the content version.

The graph artifact must include the Rule Graph identifier and version.

The graph artifact must include source specification references.

The graph artifact is generated data.

The graph artifact must not be edited by hand.
