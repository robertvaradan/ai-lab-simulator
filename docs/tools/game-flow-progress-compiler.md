# Game Flow Progress Compiler

## Purpose

The Game Flow Progress Compiler must show implementation progress for the complete game flow.

The compiler must read structured Markdown maps from `docs/game-flow`.

The compiler must write one self-contained HTML file.

The generated viewer must work from a `file://` URL.

## Command

Run this command from the repository root:

```text
python scripts/compile-game-flow.py --input docs/game-flow --output .artifacts/game-flow/index.html
```

The compiler must use only the Python standard library.

The compiler must produce deterministic output for unchanged inputs.

## Map document contract

Each map document must contain these level-two headings in this order:

1. `Metadata`
2. `Nodes`
3. `Edges`

The `Metadata` table must have the columns `Key` and `Value`.

The table must contain `Graph ID`, `Title`, and `Root Node`.

An ID must start with a lowercase letter.

An ID can contain lowercase letters, numbers, and hyphens.

The `Nodes` table must have these columns in this order:

```text
ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description
```

`Kind` must be `LEAF`, `BRANCH`, or `SUBGRAPH`.

A `LEAF` status must be `NONE`, `PARTIAL`, or `COMPLETE`.

A `BRANCH` status must be `DERIVED`.

A `SUBGRAPH` status must be `DERIVED`.

A `SUBGRAPH` node must identify one graph in the `Subgraph` cell.

Other node kinds must use `-` in the `Subgraph` cell.

`Marketing Slice` must be `YES` or `NO`.

Each node must have one or more specification references.

Separate multiple paths with a semicolon.

Use `-` for an empty evidence cell.

A `PARTIAL` or `COMPLETE` leaf must have implementation evidence.

A `COMPLETE` leaf must have verification evidence.

A `NONE` leaf must not have implementation evidence or verification evidence.

A `PARTIAL` leaf must not have verification evidence.

A derived node must not have implementation evidence or verification evidence.

Each local specification path and evidence path must exist.

The `Edges` table must have the columns `From`, `To`, and `Label`.

Each edge endpoint must identify a node in the same map.

Each node must be reachable from the root node.

A flow edge can close a gameplay loop.

Subgraph references must not contain a cycle.

## Status derivation

The compiler must derive a container status from all reachable leaf descendants.

The compiler must include the referenced graph descendants for a `SUBGRAPH` node.

The derived status must be `NONE` when all descendants are `NONE`.

The derived status must be `COMPLETE` when all descendants are `COMPLETE`.

The derived status must be `PARTIAL` for all other combinations.

`NONE` must render in grey.

`PARTIAL` and `COMPLETE` must render in green.

Each status must have a distinct text badge.

## Viewer contract

The viewer must include all styles, scripts, and graph data.

The viewer must support graph selection and subgraph navigation.

The viewer must show breadcrumbs.

The viewer must show node details and evidence.

The viewer must provide a fit-to-view control.

The viewer must provide a remaining-work filter.

The viewer must provide a Marketing Slice highlight control and filter.

The viewer must show implemented and complete leaf metrics for each graph.

An implemented leaf is a `PARTIAL` or `COMPLETE` leaf.

The viewer must parse and show Marketing Slice backlog progress separately.

The backlog progress source must be `docs/implementation/marketing-slice-backlog.md`.

## Failure contract

The compiler must fail before it writes output when an input contract is invalid.

The error must identify the invalid file, graph, node, edge, status, reference, or evidence path.

The compiler must not infer missing data.
