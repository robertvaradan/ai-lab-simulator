#!/usr/bin/env python3
"""Generate game/ui/base_theme.tres with Campaign type variants."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game" / "ui" / "base_theme.tres"

VOID = "Color(0.050980393, 0.1254902, 0.15294118, 1)"
CHARCOAL = "Color(0.101960786, 0.15686275, 0.18039216, 0.94)"
CHARCOAL_SOLID = "Color(0.101960786, 0.15686275, 0.18039216, 1)"
GLASS = "Color(0.09019608, 0.43529412, 0.47058824, 1)"
CYAN = "Color(0.24313726, 0.78431374, 0.7529412, 1)"
CYAN_EMISSION = "Color(0.3529412, 0.9411765, 0.89411765, 1)"
CREAM = "Color(0.76862746, 0.7058824, 0.5882353, 1)"
KEY_LIGHT = "Color(0.9490196, 0.8392157, 0.6901961, 1)"
ORANGE = "Color(0.8784314, 0.3529412, 0.19607843, 1)"
ORANGE_DARK = "Color(0.627451, 0.2509804, 0.15686275, 1)"
DISABLED_BG = "Color(0.101960786, 0.15686275, 0.18039216, 0.55)"
DISABLED_TEXT = "Color(0.76862746, 0.7058824, 0.5882353, 0.45)"


def style(
    rid: int,
    bg: str,
    border: str,
    border_w: int = 1,
    radius: int = 8,
    margin: int = 12,
    expand: int = 0,
) -> str:
    return f"""[sub_resource type="StyleBoxFlat" id="{rid}"]
bg_color = {bg}
border_width_left = {border_w}
border_width_top = {border_w}
border_width_right = {border_w}
border_width_bottom = {border_w}
border_color = {border}
corner_radius_top_left = {radius}
corner_radius_top_right = {radius}
corner_radius_bottom_right = {radius}
corner_radius_bottom_left = {radius}
content_margin_left = {margin}.0
content_margin_top = {margin}.0
content_margin_right = {margin}.0
content_margin_bottom = {margin}.0
expand_margin_left = {expand}.0
expand_margin_top = {expand}.0
expand_margin_right = {expand}.0
expand_margin_bottom = {expand}.0
"""


styles: list[str] = []
next_id = 1


def add_style(**kwargs) -> str:
    global next_id
    rid = f"{next_id}_sb"
    styles.append(style(rid, **kwargs))
    next_id += 1
    return rid


# Shared styles
primary_normal = add_style(bg=ORANGE, border=ORANGE, radius=8, margin=12)
primary_hover = add_style(bg=ORANGE, border=CYAN_EMISSION, radius=8, margin=12)
primary_pressed = add_style(bg=ORANGE_DARK, border=ORANGE_DARK, radius=8, margin=12)
primary_disabled = add_style(bg=DISABLED_BG, border=GLASS, radius=8, margin=12)
primary_focus = add_style(bg=ORANGE, border=CYAN_EMISSION, border_w=2, radius=8, margin=12)

secondary_normal = add_style(bg=CHARCOAL, border=GLASS, radius=8, margin=12)
secondary_hover = add_style(bg=CHARCOAL_SOLID, border=CYAN, radius=8, margin=12)
secondary_pressed = add_style(bg=VOID, border=GLASS, radius=8, margin=12)
secondary_disabled = add_style(bg=DISABLED_BG, border=GLASS, radius=8, margin=12)
secondary_focus = add_style(bg=CHARCOAL, border=CYAN_EMISSION, border_w=2, radius=8, margin=12)

destructive_normal = add_style(bg=ORANGE_DARK, border=ORANGE_DARK, radius=8, margin=12)
destructive_hover = add_style(bg=ORANGE_DARK, border=CYAN_EMISSION, radius=8, margin=12)
destructive_pressed = add_style(bg=VOID, border=ORANGE_DARK, radius=8, margin=12)
destructive_disabled = add_style(bg=DISABLED_BG, border=GLASS, radius=8, margin=12)
destructive_focus = add_style(bg=ORANGE_DARK, border=CYAN_EMISSION, border_w=2, radius=8, margin=12)

segment_normal = add_style(bg=CHARCOAL, border=GLASS, radius=0, margin=10)
segment_hover = add_style(bg=CHARCOAL_SOLID, border=CYAN, radius=0, margin=10)
segment_pressed = add_style(bg=VOID, border=CYAN, radius=0, margin=10)
segment_disabled = add_style(bg=DISABLED_BG, border=GLASS, radius=0, margin=10)
segment_focus = add_style(bg=CHARCOAL, border=CYAN_EMISSION, border_w=2, radius=0, margin=10)

icon_normal = add_style(bg=CHARCOAL, border=GLASS, radius=10, margin=8)
icon_hover = add_style(bg=CHARCOAL_SOLID, border=CYAN, radius=10, margin=8)
icon_pressed = add_style(bg=VOID, border=GLASS, radius=10, margin=8)
icon_disabled = add_style(bg=DISABLED_BG, border=GLASS, radius=10, margin=8)
icon_focus = add_style(bg=CHARCOAL, border=CYAN_EMISSION, border_w=2, radius=10, margin=8)

close_normal = add_style(bg=CHARCOAL, border=GLASS, radius=6, margin=6)
close_hover = add_style(bg=CHARCOAL_SOLID, border=CYAN, radius=6, margin=6)
close_pressed = add_style(bg=VOID, border=GLASS, radius=6, margin=6)
close_disabled = add_style(bg=DISABLED_BG, border=GLASS, radius=6, margin=6)
close_focus = add_style(bg=CHARCOAL, border=CYAN_EMISSION, border_w=2, radius=6, margin=6)

status_panel = add_style(bg=CHARCOAL, border=GLASS, radius=20, margin=10)
context_panel = add_style(bg=CHARCOAL, border=GLASS, radius=10, margin=14)
workbench_panel = add_style(bg=CHARCOAL, border=GLASS, radius=12, margin=16)
modal_panel = add_style(bg=CHARCOAL, border=GLASS, radius=12, margin=20)
disabled_panel = add_style(bg=DISABLED_BG, border=GLASS, radius=10, margin=12)
focused_panel = add_style(bg=CHARCOAL, border=CYAN_EMISSION, border_w=2, radius=10, margin=14)

parts = [
    '[gd_resource type="Theme" load_steps=%d format=3]\n' % (next_id + 2),
    "",
    '[ext_resource type="FontFile" path="res://ui/fonts/RopaSans-Regular.ttf" id="1_52fkg"]',
    '[ext_resource type="FontFile" path="res://ui/fonts/RopaSans-Italic.ttf" id="2_2b18n"]',
    "",
]
parts.extend(styles)
parts.append("")
parts.append("[resource]")
parts.append("default_font = ExtResource(\"1_52fkg\")")
parts.append("default_font_size = 16")
parts.append("Button/fonts/font = ExtResource(\"1_52fkg\")")
parts.append("CheckBox/fonts/font = ExtResource(\"1_52fkg\")")
parts.append("Fonts/fonts/italic = ExtResource(\"2_2b18n\")")
parts.append("Fonts/fonts/regular = ExtResource(\"1_52fkg\")")
parts.append("ItemList/fonts/font = ExtResource(\"1_52fkg\")")
parts.append("Label/fonts/font = ExtResource(\"1_52fkg\")")
parts.append("LineEdit/fonts/font = ExtResource(\"1_52fkg\")")
parts.append("RichTextLabel/fonts/italics_font = ExtResource(\"2_2b18n\")")
parts.append("RichTextLabel/fonts/normal_font = ExtResource(\"1_52fkg\")")

# Campaign named colors
for name, color in [
    ("void_base", VOID),
    ("charcoal", CHARCOAL_SOLID),
    ("glass", GLASS),
    ("cyan", CYAN),
    ("cyan_emission", CYAN_EMISSION),
    ("cream", CREAM),
    ("key_light", KEY_LIGHT),
    ("orange", ORANGE),
    ("orange_dark", ORANGE_DARK),
]:
    parts.append(f"CampaignColors/colors/{name} = {color}")

variants = [
    (
        "PrimaryAction",
        "Button",
        primary_normal,
        primary_hover,
        primary_pressed,
        primary_disabled,
        primary_focus,
        KEY_LIGHT,
        ORANGE_DARK,
    ),
    (
        "SecondaryAction",
        "Button",
        secondary_normal,
        secondary_hover,
        secondary_pressed,
        secondary_disabled,
        secondary_focus,
        CREAM,
        DISABLED_TEXT,
    ),
    (
        "DestructiveAction",
        "Button",
        destructive_normal,
        destructive_hover,
        destructive_pressed,
        destructive_disabled,
        destructive_focus,
        KEY_LIGHT,
        DISABLED_TEXT,
    ),
    (
        "SegmentedNav",
        "Button",
        segment_normal,
        segment_hover,
        segment_pressed,
        segment_disabled,
        segment_focus,
        CREAM,
        DISABLED_TEXT,
    ),
    (
        "SquareIconAction",
        "Button",
        icon_normal,
        icon_hover,
        icon_pressed,
        icon_disabled,
        icon_focus,
        CYAN,
        DISABLED_TEXT,
    ),
    (
        "CloseAction",
        "Button",
        close_normal,
        close_hover,
        close_pressed,
        close_disabled,
        close_focus,
        CREAM,
        DISABLED_TEXT,
    ),
]

for (
    name,
    base,
    normal,
    hover,
    pressed,
    disabled,
    focus,
    font_color,
    disabled_color,
) in variants:
    parts.append(f'{name}/base_type = "{base}"')
    parts.append(f"{name}/styles/normal = SubResource(\"{normal}\")")
    parts.append(f"{name}/styles/hover = SubResource(\"{hover}\")")
    parts.append(f"{name}/styles/pressed = SubResource(\"{pressed}\")")
    parts.append(f"{name}/styles/disabled = SubResource(\"{disabled}\")")
    parts.append(f"{name}/styles/focus = SubResource(\"{focus}\")")
    parts.append(f"{name}/fonts/font = ExtResource(\"1_52fkg\")")
    parts.append(f"{name}/font_sizes/font_size = 18")
    parts.append(f"{name}/colors/font_color = {font_color}")
    parts.append(f"{name}/colors/font_hover_color = {KEY_LIGHT}")
    parts.append(f"{name}/colors/font_pressed_color = {KEY_LIGHT}")
    parts.append(f"{name}/colors/font_disabled_color = {disabled_color}")
    parts.append(f"{name}/colors/font_focus_color = {KEY_LIGHT}")
    parts.append(f"{name}/constants/h_separation = 8")

panel_variants = [
    ("StatusPanel", status_panel),
    ("ContextCard", context_panel),
    ("Workbench", workbench_panel),
    ("Modal", modal_panel),
    ("DisabledState", disabled_panel),
    ("FocusedState", focused_panel),
]
for name, style_id in panel_variants:
    parts.append(f'{name}/base_type = "PanelContainer"')
    parts.append(f"{name}/styles/panel = SubResource(\"{style_id}\")")

OUT.write_text("\n".join(parts) + "\n", encoding="utf-8")
print(f"Wrote {OUT}")
