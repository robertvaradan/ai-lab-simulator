# Isometric camera

This document is the canonical isometric camera contract.

## Purpose

The player must inspect one entered World from an orthographic isometric view.

World selection must follow `docs/presentation/world-map.md`.

The player can pan the view.

The player can zoom the view.

The camera must not rotate.

## Projection

The gameplay camera must use orthogonal projection.

The camera must keep a three-quarter isometric look direction.

The look direction must not be vertical.

The look direction must not be horizontal.

The look ray must hit the ground plane `y = 0`.

## Focus and offset

The camera must keep one focus point on the ground plane `y = 0`.

The camera must keep one world-space offset from the focus point to the camera origin.

Pan must move the focus point on the ground plane.

Pan must not change the offset.

Zoom must change the orthogonal size.

Zoom must not change the focus point.

Zoom must not change the offset.

The camera origin must equal the focus point plus the offset.

## Rotation

The camera must lock its basis after it captures the authored pose.

Pan must not change the basis.

Zoom must not change the basis.

The camera must restore the locked basis after every update.

## Pan

The player can pan with `W`, `A`, `S`, `D`.

The player can pan with the arrow keys.

The player can pan with middle-mouse drag.

`A` and Left must move the focus against the ground projection of the camera right axis.

`D` and Right must move the focus along the ground projection of the camera right axis.

`W` and Up must move the focus along the ground projection of the look direction.

`S` and Down must move the focus against the ground projection of the look direction.

Pointer pan must use the same ground axes as keyboard pan.

Pointer pan to the right must match keyboard pan to the right.

Pointer pan up must match keyboard pan forward.

Pan speed must be in meters per second at the authored orthogonal size.

Pan speed must scale with the current target orthogonal size.

The focus point must stay inside the pan bounds rectangle.

The pan bounds rectangle must use ground `x` as rectangle `x`.

The pan bounds rectangle must use ground `z` as rectangle `y`.

The pan bounds size must be greater than zero on both axes.

## Zoom

The player can zoom with the mouse wheel.

The player can zoom with `-` and `=`.

Zoom in must decrease the orthogonal size.

Zoom out must increase the orthogonal size.

The orthogonal size must stay at or above the minimum size.

The orthogonal size must stay at or below the maximum size.

The minimum size must be greater than zero.

The maximum size must be greater than the minimum size.

The authored orthogonal size must lie in the allowed size range.

## Smoothing

Pan must smooth the displayed focus toward the target focus.

Zoom must smooth the displayed size toward the target size.

Pan smoothing must be greater than zero.

Zoom smoothing must be greater than zero.

Smoothing must use exponential decay.

A negative delta must not change the camera.

The camera must snap to the target when the remaining error is below `0.0001`.

## Input control

Gameplay must enable camera input in the World Input Context.

UI and Modal Input Contexts must disable camera input.

The left stick must pan the World camera.

Triggers must zoom the World camera.

Text entry must not move the camera.

Automated campus capture must disable camera input.

Automated campus capture must snap the camera to its targets.

Automated campus capture must keep the authored camera pose.

## Selection reframe

World-object selection must reframe the camera over 300 ms.

Context Card close must restore the prior camera framing.

Reframe must change focus and orthogonal size only.

Reframe must not rotate the camera.

## Invalid configuration

The camera must report a contract error when a requirement fails.

The camera must not capture a rig when a contract error exists.

The camera must not process pan or zoom when a contract error exists.

## Verification

From the repository root on Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\isometric-camera-test.ps1
```

From the repository root on macOS, run:

```bash
./scripts/isometric-camera-test.sh
```

Success requires `ISOMETRIC_CAMERA_TEST_SUCCESS`.
