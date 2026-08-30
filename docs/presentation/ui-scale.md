# UI scale

## Authority

This specification owns Window content scale for canvas UI.

`docs/gameplay/production-bootstrap.md` owns the campaign SDF presenter size contract.

`docs/product/game-contract.md` owns the product presentation promise.

## Purpose

Canvas UI must stay readable on displays with different scale factors.

Mac Retina and other high-density displays must not present tiny UI.

## Window content scale

The project Window must use `CONTENT_SCALE_MODE_CANVAS_ITEMS`.

The project Window must use `CONTENT_SCALE_ASPECT_EXPAND`.

The runtime must apply the readable content-scale factor when the Window size changes.

The readable content-scale factor must keep the effective canvas scale at or above 1.0 relative to the design viewport.

The design viewport size must come from the project Window viewport width and height settings.

A host must not set `CONTENT_SCALE_MODE_DISABLED` to present campaign UI.

## SDF world presentation

The campaign SDF world texture must fill the canvas presentation area.

The campaign SDF output size must match the current content presentation size.

The SDF output size must reduce to a multiple of the compute workgroup size.

The SDF world must not require disabling Window content scale.

## Verification

Automated tests must verify the readable content-scale factor for a Window smaller than the design viewport.

Automated tests must verify the campaign presenter leaves Window content scale enabled.
