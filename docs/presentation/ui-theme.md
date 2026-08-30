# UI theme

This document is the canonical production canvas Theme contract.

## Authority

This specification owns the project Theme and the production UI fontfaces.

`docs/presentation/ui-scale.md` owns Window content scale.

`docs/visual/color-palette.md` owns named world color roles.

`docs/gameplay/production-bootstrap.md` owns the production campaign shell.

## Purpose

Production canvas UI must use one Theme.

Production canvas UI must use one typeface family.

The Theme stub must install the fontfaces before later style work.

## Theme resource

The project Theme must be `game/ui/base_theme.tres`.

The Godot project must set `gui/theme/custom` to `res://ui/base_theme.tres`.

The Godot project must set `gui/theme/custom_font` to `res://ui/fonts/RopaSans-Regular.ttf`.

A production Control must inherit fontfaces from the project Theme.

A production Control must not replace the Theme default font with a second typeface.

A developer tool can set local colors and sizes.

A developer tool must not install a second typeface.

## Fontfaces

The typeface family must be Ropa Sans.

The Regular fontface must be `game/ui/fonts/RopaSans-Regular.ttf`.

The Italic fontface must be `game/ui/fonts/RopaSans-Italic.ttf`.

The Theme default font must be Ropa Sans Regular.

The Theme default font size must be 16.

The Theme must store Regular under type `Fonts` and name `regular`.

The Theme must store Italic under type `Fonts` and name `italic`.

These Control types must use Ropa Sans Regular:

- Label
- Button
- CheckBox
- LineEdit
- ItemList

`RichTextLabel` must use Ropa Sans Regular as `normal_font`.

`RichTextLabel` must use Ropa Sans Italic as `italics_font`.

The Theme must not assign a Bold fontface.

The Theme must not substitute Regular for Bold.

Each fontface import must set `allow_system_fallback` to false.

Do not add a second typeface family.

## License

The SIL Open Font License text must stay at `game/ui/fonts/OFL.txt`.

Do not redistribute the font files without that license text.

## World colors

World materials must keep palette roles from `docs/visual/color-palette.md`.

The Theme stub must not move world color roles into the Theme.

Later Theme color work must not invent a second accent family.

## Verification

From the repository root on Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ui-theme-test.ps1
```

From the repository root on macOS, run:

```bash
./scripts/ui-theme-test.sh
```

Success requires `UI_THEME_TEST_SUCCESS`.
