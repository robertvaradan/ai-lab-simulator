# World map

## Authority

This specification owns the campaign World map and World navigation.

`docs/product/game-contract.md` owns the product promise.

`docs/presentation/campus-authoring.md` owns HQ Site scene authoring.

`docs/presentation/isometric-camera.md` owns the orthographic camera inside one World.

`docs/gameplay/domain-model.md` owns Site and Site Plot terms.

## Purpose

The player must navigate campaign locations through one World map.

The World map must present selectable Worlds.

The player must zoom out to see every available World.

The player must enter one World by selecting it on the World map.

## Worlds

The campaign must use these Worlds:

1. HQ
2. Data Center
3. Government

The World layout must use this adjacency:

```
Data Center
 |
HQ -- Government
```

HQ must be the Company headquarters Site.

Data Center must be a separate World.

Government must be a separate World.

A World must not live inside another World as a Site Plot.

## HQ World

HQ must host Research Projects.

HQ must host Application Projects.

HQ must present the Company laboratory Site.

The HQ World view must present `game/scenes/campus_blockout.tscn`.

The World map must not represent Competitor Models as selectable World objects.

An entered World must not show a Competitor Model marker.

The laboratory is the HQ building where Research and Application work occur.

Month 1 must present HQ as an empty plot of land.

The first HQ construction step must build the laboratory.

HQ Site Plots must control laboratory stage only.

HQ must not present an Application building.

An Application Project must not create a physical mass on HQ.

An Application state change must use the management interface or other non-building presentation.

## Data Center World

Data Center must host Scale presentation.

Third-Party Compute presentation must use the Data Center World.

Owned Data Center presentation must use the Data Center World when that content exists.

Data Center must not appear as an HQ Site Plot.

Data Center must not simulate internal Data Center operation in the first implementation.

The Marketing Scenario must not require construction of an owned Data Center.

Data Center must use a minimal authored PrimitiveMesh World scene.

Data Center must use an orthographic isometric camera.

Data Center must contain one selectable marker and one Context Card.

The Data Center Context Card must show Compute Capacity, contracts, and monthly contract cost.

## Government World

Government must host government and regulation presentation when that content exists.

Government must not appear as an HQ Site Plot.

Full Government regulation content remains open until the regulation system closes.

Government must use a minimal authored PrimitiveMesh World scene.

Government must use an orthographic isometric camera.

Government must contain one selectable marker and one Context Card.

The Government Context Card must show the active state and applicable Trust information.

## Camera and navigation

Each entered World must use the orthographic isometric camera.

The World map zoom-out view must show every available World.

The World map must let the player select one World.

Entering a World must present that World view.

Leaving a World must return to the World map or to another selected World.

World-object selection must follow `docs/presentation/panel-system.md`.

## Relationship to other specifications

`docs/presentation/campus-authoring.md` owns HQ geometry only.

`docs/gameplay/production-bootstrap.md` owns the first playable shell that presents HQ, Data Center, and Government Worlds.

`docs/presentation/panel-system.md` owns Context Cards and World-object selection.

`docs/marketing/marketing-scenario.md` owns Marketing Scenario Site content.

Marketing Scenario content must not require an HQ Application Site Plot.

Marketing Scenario content must not require an HQ compute-link Site Plot for Scale presentation.
