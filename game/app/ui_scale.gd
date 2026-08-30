class_name UiScale
extends RefCounted

const BASE_WIDTH_SETTING: String = "display/window/size/viewport_width"
const BASE_HEIGHT_SETTING: String = "display/window/size/viewport_height"


static func apply_to_window(window: Window) -> void:
	if window == null:
		return
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_factor = readable_content_scale_factor(window.size, design_size())


static func design_size() -> Vector2i:
	return Vector2i(
		_setting_as_int(BASE_WIDTH_SETTING, 1920),
		_setting_as_int(BASE_HEIGHT_SETTING, 1080)
	)


static func _setting_as_int(setting_path: String, fallback: int) -> int:
	var value: Variant = ProjectSettings.get_setting(setting_path, fallback)
	if value is int:
		return value
	if value is float:
		var float_value: float = value
		return int(float_value)
	return fallback


static func readable_content_scale_factor(window_size: Vector2i, design: Vector2i) -> float:
	if window_size.x <= 0 or window_size.y <= 0:
		return 1.0
	if design.x <= 0 or design.y <= 0:
		return 1.0
	var fit: float = minf(
		float(window_size.x) / float(design.x),
		float(window_size.y) / float(design.y)
	)
	if fit <= 0.0:
		return 1.0
	if fit < 1.0:
		return 1.0 / fit
	return 1.0


static func presentation_size(window: Window) -> Vector2i:
	if window == null:
		return Vector2i()
	var content: Vector2i = window.content_scale_size
	if content.x <= 0 or content.y <= 0:
		return window.size
	return content
