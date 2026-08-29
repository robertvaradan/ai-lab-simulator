extends Node

const CONTRACT_STATES: Array[StringName] = [&"growth", &"overload", &"scrutiny"]
const STATE_DESCRIPTIONS: Dictionary[StringName, String] = {
	&"growth": "Capacity online / hiring accelerating",
	&"overload": "Thermal debt / demand outrunning control",
	&"scrutiny": "External review / release access constrained",
}
const OUTPUT_RESOLUTION := Vector2i(1920, 1080)
const HUD_LAYER := 100

var _renderer: SdfRenderer
var _world_texture: TextureRect
var _state_label: Label
var _description_label: Label
var _accent_bar: ColorRect
var _automated := false
var _requested_state := StringName()
var _output_directory := ""
var _fatal := false


func _ready() -> void:
	_parse_arguments()
	if _fatal:
		return
	_validate_viewport_contract()
	if _fatal:
		return
	_build_presentation()
	if _fatal:
		return
	_renderer = SdfRenderer.new()
	_renderer.name = "SdfRenderer"
	_renderer.renderer_ready.connect(_on_renderer_ready)
	_renderer.renderer_failed.connect(_on_renderer_failed)
	add_child(_renderer)
	_set_presented_state(&"growth")


func _parse_arguments() -> void:
	var arguments := OS.get_cmdline_user_args()
	var argument_index := 0
	while argument_index < arguments.size():
		var argument := arguments[argument_index]
		if argument == "--render-all":
			_automated = true
		elif argument == "--render-state":
			if argument_index + 1 >= arguments.size():
				_fail("--render-state requires one of: %s." % CONTRACT_STATES)
				return
			argument_index += 1
			_requested_state = StringName(arguments[argument_index])
			if not _requested_state in CONTRACT_STATES:
				_fail("Unknown --render-state '%s'; expected one of %s." % [_requested_state, CONTRACT_STATES])
				return
			_automated = true
		elif argument == "--output-dir":
			if argument_index + 1 >= arguments.size():
				_fail("--output-dir requires an absolute directory path.")
				return
			argument_index += 1
			_output_directory = arguments[argument_index]
		else:
			_fail("Unknown render harness argument: %s." % argument)
			return
		argument_index += 1
	if _automated and _output_directory.is_empty():
		_fail("Automated SDF capture requires --output-dir <absolute-path>.")


func _validate_viewport_contract() -> void:
	var window: Window = get_window()
	window.mode = Window.MODE_WINDOWED
	if window.size != OUTPUT_RESOLUTION:
		window.size = OUTPUT_RESOLUTION
	if window.size == OUTPUT_RESOLUTION:
		return
	# Automated capture must write exact 1920x1080 evidence PNGs.
	if _automated:
		_fail(
			"SDF harness requires viewport %s for evidence capture; received %s."
			% [OUTPUT_RESOLUTION, window.size]
		)
		return
	# Interactive play can land one or two pixels off on macOS window chrome.
	print(
		"SDF_VIEWPORT_SIZE_DRIFT requested=%s received=%s interactive_play_continues"
		% [OUTPUT_RESOLUTION, window.size]
	)

func _build_presentation() -> void:
	_world_texture = TextureRect.new()
	_world_texture.name = "SdfOutput"
	_world_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_world_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_world_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_world_texture)

	var hud_layer := CanvasLayer.new()
	hud_layer.name = "HudLayer"
	hud_layer.layer = HUD_LAYER
	add_child(hud_layer)

	var output_width := float(OUTPUT_RESOLUTION.x)
	var output_height := float(OUTPUT_RESOLUTION.y)
	var panel_width := 262.0
	var panel_height := 50.0
	var right_margin := 28.0
	var footer_margin := 24.0
	var footer_height := 42.0
	var panel_x := output_width - right_margin - panel_width
	var footer_y := output_height - footer_margin - footer_height

	var header_scrim := ColorRect.new()
	header_scrim.position = Vector2(0, 0)
	header_scrim.size = Vector2(output_width, 88)
	header_scrim.color = Color(0.025, 0.045, 0.055, 0.88)
	hud_layer.add_child(header_scrim)

	var title := Label.new()
	title.position = Vector2(28, 17)
	title.text = "FRONTIER SYSTEMS / CAMPUS CONTROL"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("d7e6df"))
	hud_layer.add_child(title)

	var subtitle := Label.new()
	subtitle.position = Vector2(29, 49)
	subtitle.text = "COMPUTE-SDF RENDER PROOF  •  INTERNAL 640×360  •  OUTPUT 1920×1080"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("7fa8a2"))
	hud_layer.add_child(subtitle)

	var state_panel := ColorRect.new()
	state_panel.position = Vector2(panel_x, 17)
	state_panel.size = Vector2(panel_width, panel_height)
	state_panel.color = Color(0.055, 0.085, 0.09, 0.95)
	hud_layer.add_child(state_panel)

	_accent_bar = ColorRect.new()
	_accent_bar.position = Vector2(panel_x, 17)
	_accent_bar.size = Vector2(5, panel_height)
	hud_layer.add_child(_accent_bar)

	_state_label = Label.new()
	_state_label.position = Vector2(panel_x + 20.0, 29)
	_state_label.size = Vector2(226, 27)
	_state_label.clip_text = false
	_state_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_state_label.add_theme_font_size_override("font_size", 18)
	_state_label.add_theme_color_override("font_color", Color("e7f3ed"))
	hud_layer.add_child(_state_label)

	var footer_scrim := ColorRect.new()
	footer_scrim.position = Vector2(footer_margin, footer_y)
	footer_scrim.size = Vector2(output_width - footer_margin * 2.0, footer_height)
	footer_scrim.color = Color(0.025, 0.045, 0.055, 0.9)
	hud_layer.add_child(footer_scrim)

	_description_label = Label.new()
	_description_label.position = Vector2(42, footer_y + 11.0)
	_description_label.size = Vector2(760, 22)
	_description_label.add_theme_font_size_override("font_size", 14)
	_description_label.add_theme_color_override("font_color", Color("c3d6cf"))
	hud_layer.add_child(_description_label)

	var controls := Label.new()
	controls.position = Vector2(panel_x, footer_y + 11.0)
	controls.size = Vector2(238, 22)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.text = "STATE  1 / 2 / 3"
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override("font_color", Color("7fa8a2"))
	hud_layer.add_child(controls)

	if hud_layer.layer != HUD_LAYER:
		_fail("HUD CanvasLayer contract changed: expected %d, received %d." % [HUD_LAYER, hud_layer.layer])


func _on_renderer_ready(output_texture: Texture2DRD) -> void:
	if _fatal:
		return
	_world_texture.texture = output_texture
	if _automated:
		call_deferred("_run_automated_capture")
	else:
		_renderer.request_render()
		call_deferred("_announce_interactive_ready")


func _announce_interactive_ready() -> void:
	await _renderer.dispatch_submitted
	print("AI_LAB_SDF_READY state=growth controls=1|2|3 renderer=compute texture=Texture2DRD")


func _run_automated_capture() -> void:
	var directory_error := DirAccess.make_dir_recursive_absolute(_output_directory)
	if directory_error != OK:
		_fail("Could not create SDF evidence directory '%s': error %d." % [_output_directory, directory_error])
		return
	var capture_states: Array[StringName] = []
	for contract_state: StringName in CONTRACT_STATES:
		capture_states.append(contract_state)
	if not _requested_state.is_empty():
		capture_states = [_requested_state]
	for state in capture_states:
		if _fatal:
			return
		_set_presented_state(state)
		_renderer.set_state(state)
		await _renderer.dispatch_submitted
		for frame_index in range(4):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		if image.get_size() != OUTPUT_RESOLUTION:
			_fail("Viewport capture for '%s' was %s, expected %s." % [state, image.get_size(), OUTPUT_RESOLUTION])
			return
		var output_path := _output_directory.path_join("%s.png" % state)
		var save_error := image.save_png(output_path)
		if save_error != OK:
			_fail("Could not save SDF evidence '%s': error %d." % [output_path, save_error])
			return
		print("SDF_CAPTURE_WRITTEN state=%s size=%dx%d path=%s" % [
			state,
			image.get_width(),
			image.get_height(),
			output_path,
		])
	print("SDF_RENDER_TEST_SUCCESS states=%d renderer=compute output=%s" % [capture_states.size(), _output_directory])
	get_tree().quit(0)


func _set_presented_state(state: StringName) -> void:
	if not state in CONTRACT_STATES:
		_fail("Presentation received unknown state '%s'." % state)
		return
	_state_label.text = "STATE / %s" % String(state).to_upper()
	_description_label.text = STATE_DESCRIPTIONS[state]
	match state:
		&"growth":
			_accent_bar.color = Color("30b884")
		&"overload":
			_accent_bar.color = Color("f2632f")
		&"scrutiny":
			_accent_bar.color = Color("df2730")


func _unhandled_key_input(event: InputEvent) -> void:
	if _automated or not event.is_pressed() or event.is_echo():
		return
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event
	var requested_state := StringName()
	match key_event.keycode:
		KEY_1:
			requested_state = &"growth"
		KEY_2:
			requested_state = &"overload"
		KEY_3:
			requested_state = &"scrutiny"
	if not requested_state.is_empty():
		_set_presented_state(requested_state)
		_renderer.set_state(requested_state)


func _on_renderer_failed(message: String) -> void:
	_fail(message)


func _fail(message: String) -> void:
	if _fatal:
		return
	_fatal = true
	push_error(message)
	if is_inside_tree():
		get_tree().quit(1)
