# Panel system

## Authority

This specification owns the Campaign Panel Workspace.

This specification owns the final Campaign UI visual system.

This specification owns the final Campaign event presentation format.

`docs/presentation/ui-theme.md` owns the project Theme and fontfaces.

`docs/visual/color-palette.md` owns named palette roles.

`docs/presentation/ui-scale.md` owns Window content scale.

`docs/presentation/world-map.md` owns World navigation.

`docs/presentation/isometric-camera.md` owns camera pan and zoom.

`docs/gameplay/production-bootstrap.md` owns Campaign entry and shell scope.

`docs/gameplay/core-loop.md` owns Planning and Advance rules.

## Purpose

The Campaign must present one reusable Panel Workspace.

The World must remain the primary surface.

The Panel Workspace must keep fixed chrome around the World.

The Panel Workspace must present one Context Card, one Workbench, and one Modal.

The Panel Workspace must not migrate the Main Menu, Marketing Slice, render harnesses, or developer tools.

## Concept art

`docs/concept-art/panel-system-v1.png` owns the Campaign visual organization and component style.

An implementation must match that concept art for chrome placement, component style, and palette use.

Canonical simulation terms and values must control displayed content.

## Surfaces

The Panel Workspace must support these surfaces:

1. World
2. Fixed chrome
3. Context Card
4. Workbench
5. Modal

Fixed chrome must include:

- Company status at the top left
- Bell and Menu at the top right
- World Map, current World, Plan, and Advance in the bottom action bar

The workspace must show one selected World object at a time.

The workspace must show one Context Card for that selection.

The workspace must show one bounded central Workbench.

The Workbench must leave World margins and fixed chrome visible.

The Modal must render above all other surfaces.

## Back order

Back must close surfaces in this order:

1. Modal
2. Workbench
3. Context Card
4. World

Context Card and Workbench can collapse.

Workbench tabs can change.

The player must not resize, move, or reorder panels.

## Persistence

`CampaignUiSessionState` must store:

- active Workbench
- active tab
- per-World selection
- read timeline identifiers
- panel collapse state
- focus restoration state

That state must stay outside authoritative Game State.

The host must persist that state for the active campaign only.

A new campaign must reset that state.

## Public interfaces

### CampaignPanelWorkspace

`CampaignPanelWorkspace` must own fixed chrome, Context Card, Workbench, Modal, focus restoration, input context, and transition layers.

It must expose:

- `open_workbench()`
- `show_context()`
- `open_modal()`
- `back()`
- `present()`

The workspace must live under Campaign `CanvasLayer` layer 100.

Empty full-screen roots must ignore pointer input.

Only visible control bounds must stop pointer input.

### CampaignPanelDefinition

`CampaignPanelDefinition` must define:

- stable panel identifier
- scene
- surface type
- initial focus target
- permitted tabs
- permitted Worlds

A duplicate identifier must fail.

An unknown identifier must fail.

### CampaignDraftPlanState

`CampaignDraftPlanState` must store:

- staged Project identifiers
- typed Project inputs
- staged Attention Event acknowledgments

UI controls must edit `CampaignDraftPlanState`.

UI controls must not build the committed `Plan` directly.

`CampaignHost.validate_draft_plan()` must build the candidate `Plan`.

That method must call `SimulationCore.validate_plan()`.

The Plan Workbench must show all diagnostics.

The bottom action bar must show the first blocking reason.

Advance must stay disabled while the Plan is invalid.

A valid Advance must commit immediately.

An empty Plan must remain valid when no Attention Event requires a response.

### CampaignPresentationDefinition

`CampaignPresentationDefinition` must store:

- Company display name `Aperture Labs`
- Company mark path
- Campaign presentation metadata

Authoritative Game State must not store the Company display name.

### CampaignWorldSelectable

`CampaignWorldSelectable` must extend `Area3D`.

It must define:

- stable entity identifier
- Context Card type
- selection order
- framing target
- framing size
- authored selection outline

### CampaignAdvanceTransitionModel

`CampaignAdvanceTransitionModel` must describe:

- resolved Month Steps
- Cash changes
- Project changes
- new events
- visible World changes

It must derive all values from the previous state, the published state, and the Simulation Trace.

## Theme and typography

The Campaign must extend `game/ui/base_theme.tres`.

The Campaign must not add a second Theme.

The Campaign must use Ropa Sans Regular and Italic only.

Campaign body text must use 18 px.

Interactive controls must keep a 48 px minimum height.

Structural borders must use 1 px.

Focus indicators must use 2 px.

## Palette roles

Surfaces must use `void_base` and `charcoal`.

Structural borders must use `glass`.

Selection, focus, and status must use `cyan` and `cyan_emission`.

Text must use `cream` and `key_light`.

Primary action and attention must use `orange`.

Pressed and destructive states must use `orange_dark`.

The Campaign must not add red, green, or another accent family.

Each state color must pair with text, shape, or an icon.

## Theme variants

The Theme must define variants for:

- Primary action
- Secondary action
- Destructive action
- Segmented navigation
- Square icon action
- Close action
- Status panel
- Context Card
- Workbench
- Modal
- Disabled state
- Focused state

## Icons and mark

Pinned Tabler Icons must use version 3.45.0.

Pinned icons must include outline and filled variants where the Campaign uses both.

The Tabler MIT license text must remain with the pinned SVG files.

Tabler icons use a 24×24 grid and a 2 px stroke.

The Company mark must be a separate Aperture shutter mark.

The Company mark must not use a Tabler icon.

The top-right gear icon means Menu.

The Campaign must not present a Settings panel.

## Motion

World-object selection must reframe the camera over 300 ms.

Context Card close must restore the prior camera framing.

The authored selection outline must render on the selected 3D World object.

The connector must start at the projected edge of the authored selection outline.

The Campaign must not render a second 2D selection rectangle.

The selection outline and connector must draw before the Context Card appears.

The Context Card must open over 240 ms.

Workbench and Modal must open over 280 ms.

Context Card rows must stagger by 35 ms.

Each resolved Month Step in the Advance timeline must use 450 ms.

The final Advance result reveal must use 500 ms.

The Campaign must not add UI audio.

The Campaign must not add a reduced-motion mode.

## Company status and overview

The Company status panel must show:

- `Aperture Labs`
- Quarter
- Month Step
- Cash

Activating Company status must open Company Overview.

Company Overview must show:

- teams
- capacity
- active Projects
- Models
- contracts
- active Trust values

## Menu and Pause

The Menu button must open Pause.

Escape at the base World layer must open Pause.

Controller Start must open Pause.

Pause must contain Resume and Abandon campaign.

Abandon must keep the existing confirmation and fail-state behavior.

## Event presentation

The Bell must open one event timeline.

The timeline must include:

- Attention Events
- Notifications
- Quarterly Reports
- major Competitor releases

The timeline must pin unresolved Attention Events first.

Other items must use reverse chronological order.

A stable identifier must break remaining ties.

An item becomes read when its detail receives focus.

An Attention Event acknowledgment stages when its detail receives focus.

Every Attention Event in the batch must receive focus before Advance becomes valid.

The Bell must show the unread count.

## Plan Workbench

The Plan Workbench must contain Projects and Skill Tree tabs.

Projects must use Research, Scale, and Applications groups.

Each Project card must show:

- cost
- duration
- capacity use
- prerequisites
- availability

Required Model inputs must appear inside the selected Project card.

The draft summary must show all staged Commands.

Opening Plan from a World Context Card must select the related Project.

That open action must not stage the Project automatically.

## World selection

Selecting a World object must reframe the camera.

Selecting a World object must enter UI Input Context.

HQ must expose the research Site Plot or Laboratory as one selectable object.

The HQ Context Card must show stage, capacity, and Research readiness.

The HQ primary action must open Plan.

A major Competitor release must add a timeline item.

A major Competitor release must not add a selectable World marker.

A major Competitor release must not open a World Context Card automatically.

## Data Center and Government Worlds

Data Center and Government must use minimal authored 3D World scenes.

Each new World must use PrimitiveMesh geometry.

Each new World must use an orthographic isometric camera.

Each new World must contain one selectable marker and one Context Card.

Data Center must show Compute Capacity, contracts, and monthly contract cost.

Government must show its active state and applicable Trust information.

These Worlds must not add new simulation behavior.

## Advance transition

The Advance transition must animate each resolved Month Step.

The transition must summarize authoritative Cash, Project, event, and World changes.

At an Attention Boundary, the transition must open the timeline.

That open must focus the first required event.

## Input

The Campaign must support mouse, keyboard, and controller.

The Campaign must not add touch support.

Left stick must pan the World camera.

Triggers must zoom the World camera.

D-pad direction must cycle eligible World objects.

Controller A must select or activate.

Controller B must unwind one UI layer.

Shoulder buttons must change Workbench tabs or focus regions.

Controller Start must open Pause.

Keyboard and controller must use spatial focus inside UI.

UI and Modal Input Contexts must disable camera input.

Text entry must not move the camera.

A Modal must trap focus.

Closing a surface must restore focus to the control that opened it.

## Layout

The Campaign must support an effective minimum of 1280×720.

The Campaign must support 16:9 and wider aspect ratios.

Fixed chrome must stay inside controller-safe margins.

The Context Card and connector must clamp to the safe rectangle.

The Campaign must not add a 4:3 reflow mode.

## Scene authoring

Panels must use authored `.tscn` scenes.

The migrated Campaign UI tree must not come from one monolithic GDScript builder.

Service ownership must stay local to `CampaignHost`.

The Campaign must not add an Autoload or global service registry for the Panel Workspace.

`MarketingPlayOverlay` and developer tools must remain unchanged.

## Verification

Automated tests must verify:

- panel registration, exclusivity, and unknown identifier failures
- Back order and focus restoration
- mouse routing through empty overlay areas
- controller focus, World selection, Pause, and tab navigation
- camera disable in UI Input Context
- session persistence and new-campaign reset
- Plan staging and live Simulation Core validation
- disabled Advance and visible validation reasons
- Attention Event acknowledgment on detail focus
- required-first timeline ordering, read state, and Bell badge counts
- Company Overview, Trust thresholds, Project cards, and Skill Tree gating
- HQ, Data Center, and Government Context Cards
- orthographic cameras and selectable anchors on both new Worlds
- Advance transition values from previous state, published state, and trace data
- layout bounds at 1920×1080, 1280×720, and 2560×1080

Deterministic visual captures must cover:

- base HQ view
- Laboratory Context Card
- Plan
- Skill Tree
- timeline
- World Map
- Data Center World
- Government World
- Pause
- fail state
- Advance transition

Captures must run at 1920×1080 and 1280×720.

Every capture must match the concept-art contract.
