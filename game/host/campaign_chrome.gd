class_name CampaignChrome
extends RefCounted

const VOID_BASE: Color = Color(0.050980393, 0.1254902, 0.15294118, 1.0)
const CREAM: Color = Color(0.76862746, 0.7058824, 0.5882353, 1.0)
const GLASS: Color = Color(0.09019608, 0.43529412, 0.47058824, 1.0)
const CHARCOAL: Color = Color(0.101960786, 0.15686275, 0.18039216, 0.94)
const PANEL_WIDTH_PX: float = 420.0


static func panel_style() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = CHARCOAL
	box.border_color = GLASS
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.set_content_margin_all(12)
	return box


static func apply_title(label: Label) -> void:
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_font_size_override("font_size", 28)


static func apply_heading(label: Label) -> void:
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_font_size_override("font_size", 18)


static func apply_body(label: Label) -> void:
	label.add_theme_color_override("font_color", CREAM)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func make_panel(node_name: String) -> Panel:
	var panel: Panel = Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", panel_style())
	return panel


static func make_column(node_name: String) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = node_name
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 12.0
	column.offset_top = 12.0
	column.offset_right = -12.0
	column.offset_bottom = -12.0
	column.add_theme_constant_override("separation", 10)
	return column
