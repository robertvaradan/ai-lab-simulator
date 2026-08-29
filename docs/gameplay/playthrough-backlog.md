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

Current cause: `docs/gameplay/production-bootstrap.md` requires one opening path before Advance. Path Select stages one Project and unlocks the matching domain skill. Marketing Scenario Game State already loads before Path Select.

Owning specifications to update:

- `docs/gameplay/production-bootstrap.md`
- `docs/game-flow/production-presentation.md`

### CAMPUS-001 Start on empty plot and build the laboratory

Status: open

Observed: Month 1 already shows a built campus laboratory. The production campaign uses the SDF campus, not `lab_stage_1.tscn`.

Required: Month 1 must show an empty plot of land. The first player step must be to build the laboratory.

Current cause:

- The production campaign presents `SdfRenderer` and `campus_sdf.glsl`. It does not instance `lab_stage_1.tscn`.
- `lab_stage_1.tscn` and `lab_stage_2.tscn` serve the Marketing Slice mesh campus through `CampusVisualPresenter`.
- The Marketing Scenario starts `plot.campus.research` in `site_plot_state.compact_lab`.
- The SDF contract states are `growth`, `overload`, and `scrutiny`. No empty-plot state exists.

Owning specifications to update:

- `docs/marketing/marketing-scenario.md`
- `docs/gameplay/production-bootstrap.md`
- `docs/presentation/campus-authoring.md`
- SDF campus presentation contract in `docs/game-flow/production-presentation.md`
