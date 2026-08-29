# Playthrough backlog

## Authority

This file records product and presentation defects found during production playthrough.

This file does not define runtime behavior.

An open item must update the owning specification before implementation closes it.

## Process

Add one item when a playthrough defect appears.

Keep each item open until the owning specification and implementation match the required behavior.

## Open items

### PATH-001 Remove forced opening-path select

Status: open

Observed: The campaign presents Path Select before the HUD accepts Advance.

Required: The player must land on the campaign HUD with Marketing Scenario initial conditions. The player must stage Projects through normal Plan controls. The host must not force an opening-path gate.

Specification status: `docs/gameplay/production-bootstrap.md` now forbids the opening-path gate.

Implementation remains open.

### CAMPUS-001 Start on empty HQ plot and build the laboratory

Status: open

Observed: Month 1 already shows a built campus laboratory. The production campaign uses the SDF campus, not `lab_stage_1.tscn`.

Required:

- Month 1 must show HQ as an empty plot of land.
- The first player step must start `project.campus.build_laboratory`.
- Research and Application Projects must run at HQ after the laboratory exists.
- HQ must not present an Application building.
- Scale presentation must use the Data Center World.

Specification status: owning specs now define the World map, empty HQ start, and build-laboratory Project.

Implementation remains open.

### MAP-001 World map navigation

Status: open

Observed: The campaign presents one SDF campus and a Data Center panel. The player cannot zoom out to a World map.

Required:

- The player must zoom out to see HQ, Data Center, and Government.
- The layout must be Data Center above HQ, with Government to the right of HQ.
- The player must enter one World by selecting it.

Owning specification: `docs/presentation/world-map.md`.

Implementation remains open.

## Closed items

None.
