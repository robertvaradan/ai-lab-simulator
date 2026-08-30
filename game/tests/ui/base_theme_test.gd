extends SceneTree

const TEST_SUCCESS: String = "UI_THEME_TEST_SUCCESS"
const CASE_COUNT: int = 8
const THEME_PATH: String = "res://ui/base_theme.tres"
const REGULAR_PATH: String = "res://ui/fonts/RopaSans-Regular.ttf"
const ITALIC_PATH: String = "res://ui/fonts/RopaSans-Italic.ttf"
const LICENSE_PATH: String = "res://ui/fonts/OFL.txt"
const FAMILY_NAME: String = "Ropa Sans"
const FONTS_TYPE: String = "Fonts"
const CONTROL_TYPES: PackedStringArray = [
	"Label",
	"Button",
	"CheckBox",
	"LineEdit",
	"ItemList",
]

var _failure_count: int = 0


func _initialize() -> void:
	_verify_files()
	_verify_font_files()
	_verify_theme_resource()
	_verify_named_faces()
	_verify_control_fonts()
	_verify_rich_text_fonts()
	_verify_project_settings()
	_verify_inherited_label_font()
	_finish()


func _verify_files() -> void:
	_expect(FileAccess.file_exists(REGULAR_PATH), "The Regular fontface file is missing.")
	_expect(FileAccess.file_exists(ITALIC_PATH), "The Italic fontface file is missing.")
	_expect(FileAccess.file_exists(LICENSE_PATH), "The Ropa Sans license file is missing.")
	_expect(FileAccess.file_exists(THEME_PATH), "The project Theme resource is missing.")


func _verify_font_files() -> void:
	var regular: FontFile = load(REGULAR_PATH) as FontFile
	var italic: FontFile = load(ITALIC_PATH) as FontFile
	_expect(regular != null, "The Regular fontface did not load as FontFile.")
	_expect(italic != null, "The Italic fontface did not load as FontFile.")
	if regular == null or italic == null:
		return
	_expect(regular.get_font_name() == FAMILY_NAME, "The Regular file is not Ropa Sans.")
	_expect(italic.get_font_name() == FAMILY_NAME, "The Italic file is not Ropa Sans.")
	_expect(regular.get_font_style_name() == "Regular", "The Regular file is not the Regular face.")
	_expect(italic.get_font_style_name() == "Italic", "The Italic file is not the Italic face.")
	_expect(not regular.allow_system_fallback, "The Regular fontface allows a system fallback.")
	_expect(not italic.allow_system_fallback, "The Italic fontface allows a system fallback.")


func _verify_theme_resource() -> void:
	var theme: Theme = load(THEME_PATH) as Theme
	_expect(theme != null, "The project Theme did not load.")
	if theme == null:
		return
	_expect(theme.default_font != null, "The Theme has no default font.")
	_expect(theme.default_font_size == 16, "The Theme default font size is not 16.")
	_expect(_is_face(theme.default_font, "Regular"), "The Theme default font is not Ropa Sans Regular.")
	_expect(
		not theme.get_font_list("RichTextLabel").has("bold_font"),
		"The Theme assigned a Bold fontface."
	)


func _verify_named_faces() -> void:
	var theme: Theme = load(THEME_PATH) as Theme
	if theme == null:
		_expect(false, "The project Theme did not load for named faces.")
		return
	_expect(theme.has_font("regular", FONTS_TYPE), "The Theme does not store the Regular face.")
	_expect(theme.has_font("italic", FONTS_TYPE), "The Theme does not store the Italic face.")
	_expect(_is_face(theme.get_font("regular", FONTS_TYPE), "Regular"), "Fonts/regular is not Ropa Sans Regular.")
	_expect(_is_face(theme.get_font("italic", FONTS_TYPE), "Italic"), "Fonts/italic is not Ropa Sans Italic.")


func _verify_control_fonts() -> void:
	var theme: Theme = load(THEME_PATH) as Theme
	if theme == null:
		_expect(false, "The project Theme did not load for Control fonts.")
		return
	for control_type: String in CONTROL_TYPES:
		_expect(theme.has_font("font", control_type), "The Theme does not set the font for %s." % control_type)
		_expect(
			_is_face(theme.get_font("font", control_type), "Regular"),
			"%s does not use Ropa Sans Regular." % control_type
		)


func _verify_rich_text_fonts() -> void:
	var theme: Theme = load(THEME_PATH) as Theme
	if theme == null:
		_expect(false, "The project Theme did not load for RichTextLabel fonts.")
		return
	_expect(theme.has_font("normal_font", "RichTextLabel"), "RichTextLabel has no normal font.")
	_expect(theme.has_font("italics_font", "RichTextLabel"), "RichTextLabel has no italics font.")
	_expect(
		_is_face(theme.get_font("normal_font", "RichTextLabel"), "Regular"),
		"RichTextLabel normal_font is not Ropa Sans Regular."
	)
	_expect(
		_is_face(theme.get_font("italics_font", "RichTextLabel"), "Italic"),
		"RichTextLabel italics_font is not Ropa Sans Italic."
	)


func _verify_project_settings() -> void:
	var custom_theme: String = str(ProjectSettings.get_setting("gui/theme/custom"))
	var custom_font: String = str(ProjectSettings.get_setting("gui/theme/custom_font"))
	_expect(custom_theme == THEME_PATH, "The project custom Theme path is incorrect.")
	_expect(custom_font == REGULAR_PATH, "The project custom font path is incorrect.")
	var project_theme: Theme = ThemeDB.get_project_theme()
	_expect(project_theme != null, "ThemeDB has no project Theme.")
	if project_theme == null:
		return
	_expect(_is_face(project_theme.default_font, "Regular"), "ThemeDB project Theme is not Ropa Sans Regular.")


func _verify_inherited_label_font() -> void:
	var label: Label = Label.new()
	label.name = "ThemeProbeLabel"
	root.add_child(label)
	var font: Font = label.get_theme_font("font")
	_expect(font != null, "A Label did not inherit a Theme font.")
	_expect(_is_face(font, "Regular"), "A Label did not inherit Ropa Sans Regular.")
	label.queue_free()


func _is_face(font: Font, style_name: String) -> bool:
	if font == null:
		return false
	return font.get_font_name() == FAMILY_NAME and font.get_font_style_name() == style_name


func _finish() -> void:
	if _failure_count > 0:
		printerr("UI_THEME_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=%d" % [TEST_SUCCESS, CASE_COUNT])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
