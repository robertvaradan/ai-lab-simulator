extends Node3D

const TARGET_SIZE := Vector2i(1920, 1080)
const CATALOG_PATH := "res://assets/generated/asset_catalog.json"
const HUD_CANVAS_LAYER := 100
const STATE_BADGE_SIZE := Vector2(230.0, 42.0)
const STATE_NAMES: Array[String] = ["growth", "overload", "scrutiny"]
const STATE_COLORS := {
	"growth": Color("62ffd1"),
	"overload": Color("ff6b3d"),
	"scrutiny": Color("7edbff"),
}

var _kit_root: Node3D
var _hud_canvas: CanvasLayer
var _state_panel: PanelContainer
var _state_label: Label
var _state_style: StyleBoxFlat
var _status_lights: Array[OmniLight3D] = []
var _current_state := "growth"
var _automated := false
var _fatal_triggered := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_automated = args.has("--render-all") or args.has("--render-state")
	_create_environment()
	_create_diorama_ground()
	_create_lighting()
	_create_camera()
	_create_minimal_ui()
	if not _load_authored_kit():
		return
	if not _validate_asset_layers():
		return

	var requested_state := _read_option(args, "--render-state", "growth")
	if not _set_state(requested_state):
		return
	if not _validate_ui_contract():
		return

	if _automated:
		call_deferred("_run_render_test", args)
	else:
		print("AI_LAB_PROTOTYPE_READY state=growth controls=1|2|3")


func _unhandled_key_input(event: InputEvent) -> void:
	if _automated or not event.is_pressed() or event.is_echo():
		return
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event
	if key_event.keycode == KEY_1:
		_set_state("growth")
	elif key_event.keycode == KEY_2:
		_set_state("overload")
	elif key_event.keycode == KEY_3:
		_set_state("scrutiny")


func _create_environment() -> void:
	RenderingServer.set_default_clear_color(Color("0b1821"))
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("102733")
	environment.background_energy_multiplier = 0.72
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("91b8bd")
	environment.ambient_light_energy = 0.58
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.18
	environment.ssao_enabled = true
	environment.ssao_radius = 2.3
	environment.ssao_intensity = 2.4
	environment.ssao_power = 1.25

	var world_environment := WorldEnvironment.new()
	world_environment.name = "PaletteEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


func _create_diorama_ground() -> void:
	_create_box("WaterPlinth", Vector3(0.0, -1.05, 0.0), Vector3(36.0, 0.7, 18.0), Color("163542"), 0.15, 0.42)
	_create_box("CampusIsland", Vector3(0.0, -0.48, 0.0), Vector3(32.0, 0.8, 12.8), Color("6f7772"), 0.0, 0.92)
	_create_box("CentralPromenade", Vector3(0.0, -0.02, 3.2), Vector3(29.0, 0.08, 1.45), Color("c4bca6"), 0.0, 0.88)
	var path_x_positions: Array[float] = [-9.0, 0.0, 9.0]
	for x_position: float in path_x_positions:
		_create_box("EntryPath_%s" % str(x_position), Vector3(x_position, -0.01, 1.0), Vector3(1.25, 0.09, 5.3), Color("a9a899"), 0.0, 0.9)
	_create_box("WestWaterStep", Vector3(-14.9, -0.16, 0.0), Vector3(1.0, 0.18, 9.5), Color("d87861"), 0.0, 0.72)
	_create_box("EastWaterStep", Vector3(14.9, -0.16, 0.0), Vector3(1.0, 0.18, 9.5), Color("3d8f98"), 0.1, 0.48)


func _create_box(name_value: String, position_value: Vector3, size_value: Vector3, color: Color, metallic: float, roughness: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = name_value
	instance.mesh = mesh
	instance.position = position_value
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instance)


func _create_lighting() -> void:
	var key_light := DirectionalLight3D.new()
	key_light.name = "WarmKey"
	key_light.light_color = Color("ffd7a6")
	key_light.light_energy = 2.35
	key_light.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	key_light.shadow_enabled = true
	key_light.directional_shadow_max_distance = 70.0
	add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "CoolFill"
	fill_light.light_color = Color("77bcd0")
	fill_light.light_energy = 0.55
	fill_light.rotation_degrees = Vector3(-32.0, 142.0, 0.0)
	fill_light.shadow_enabled = false
	add_child(fill_light)

	var light_x_positions: Array[float] = [-9.0, 0.0, 9.0]
	for x_position: float in light_x_positions:
		var status_light := OmniLight3D.new()
		status_light.name = "StateLight_%s" % str(x_position)
		status_light.position = Vector3(x_position, 5.5, 1.0)
		status_light.light_color = STATE_COLORS["growth"]
		status_light.light_energy = 3.2
		status_light.omni_range = 7.5
		status_light.shadow_enabled = false
		add_child(status_light)
		_status_lights.append(status_light)


func _create_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "GameplayCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 21.5
	camera.near = 0.5
	camera.far = 100.0
	camera.position = Vector3(19.5, 16.5, 23.5)
	add_child(camera)
	camera.look_at(Vector3(0.0, 2.4, 0.0), Vector3.UP)
	camera.current = true

	var attributes := CameraAttributesPractical.new()
	attributes.dof_blur_amount = 0.025
	attributes.dof_blur_near_enabled = true
	attributes.dof_blur_near_distance = 8.0
	attributes.dof_blur_near_transition = 9.0
	attributes.dof_blur_far_enabled = true
	attributes.dof_blur_far_distance = 44.0
	attributes.dof_blur_far_transition = 14.0
	camera.attributes = attributes


func _create_minimal_ui() -> void:
	_hud_canvas = CanvasLayer.new()
	_hud_canvas.name = "MinimalGameUI"
	_hud_canvas.layer = HUD_CANVAS_LAYER
	add_child(_hud_canvas)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(28.0, 24.0)
	title.text = "AI LAB / CAMPUS PROTOTYPE\nLAB CORE  ·  COMPUTE  ·  RESEARCH"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("edf5ea"))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	_hud_canvas.add_child(title)

	_state_panel = PanelContainer.new()
	_state_panel.name = "StateBadge"
	_state_panel.position = Vector2(28.0, 88.0)
	_state_panel.custom_minimum_size = STATE_BADGE_SIZE
	_state_panel.size = STATE_BADGE_SIZE
	_state_style = StyleBoxFlat.new()
	_state_style.bg_color = Color(0.08, 0.16, 0.18, 0.92)
	_state_style.border_width_left = 4
	_state_style.border_color = STATE_COLORS["growth"]
	_state_style.corner_radius_top_left = 7
	_state_style.corner_radius_top_right = 7
	_state_style.corner_radius_bottom_left = 7
	_state_style.corner_radius_bottom_right = 7
	_state_style.content_margin_left = 13.0
	_state_style.content_margin_right = 13.0
	_state_style.content_margin_top = 8.0
	_state_style.content_margin_bottom = 8.0
	_state_panel.add_theme_stylebox_override("panel", _state_style)
	_hud_canvas.add_child(_state_panel)

	_state_label = Label.new()
	_state_label.name = "StateLabel"
	_state_label.text = "STATE / GROWTH"
	_state_label.clip_text = false
	_state_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_state_label.add_theme_font_size_override("font_size", 16)
	_state_label.add_theme_color_override("font_color", Color("edf5ea"))
	_state_panel.add_child(_state_label)

	var controls := Label.new()
	controls.name = "Controls"
	controls.position = Vector2(28.0, float(TARGET_SIZE.y) - 42.0)
	controls.text = "1 GROWTH   ·   2 OVERLOAD   ·   3 SCRUTINY"
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color(0.85, 0.9, 0.88, 0.72))
	_hud_canvas.add_child(controls)


func _validate_ui_contract() -> bool:
	if _hud_canvas.layer != HUD_CANVAS_LAYER:
		_fatal("HUD CanvasLayer must render at layer %d, got %d" % [HUD_CANVAS_LAYER, _hud_canvas.layer])
		return false
	var original_text := _state_label.text
	var largest_required_width := 0.0
	for state_name in STATE_NAMES:
		_state_label.text = "STATE / %s" % state_name.to_upper()
		largest_required_width = maxf(largest_required_width, _state_label.get_minimum_size().x + _state_style.get_minimum_size().x)
	_state_label.text = original_text
	if _state_panel.size.x + 0.5 < largest_required_width:
		_fatal("state badge width %.1f cannot contain the longest required label width %.1f" % [_state_panel.size.x, largest_required_width])
		return false
	print("UI_LAYER_VALIDATION canvas_layer=%d badge_width=%.1f required_width=%.1f" % [HUD_CANVAS_LAYER, _state_panel.size.x, largest_required_width])
	return true


func _load_authored_kit() -> bool:
	if not FileAccess.file_exists(CATALOG_PATH):
		_fatal("required Blender asset catalog is missing: %s" % CATALOG_PATH)
		return false
	var catalog_file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if catalog_file == null:
		_fatal("could not read Blender asset catalog: %s" % CATALOG_PATH)
		return false
	var files := _catalog_glb_paths(catalog_file.get_as_text())
	if files.is_empty():
		return false

	_kit_root = Node3D.new()
	_kit_root.name = "BlenderAuthoredCampusKit"
	add_child(_kit_root)

	for glb_path: String in files:
		var resource := ResourceLoader.load(glb_path)
		if resource == null or not resource is PackedScene:
			_fatal("required Blender-exported PackedScene is missing or invalid: %s" % glb_path)
			return false
		var instance := (resource as PackedScene).instantiate()
		if instance == null or not instance is Node3D:
			_fatal("Blender-exported asset root must instantiate as Node3D: %s" % glb_path)
			return false
		_kit_root.add_child(instance as Node3D)
	return true


func _catalog_glb_paths(catalog_text: String) -> PackedStringArray:
	var files := PackedStringArray()
	var lines: PackedStringArray = catalog_text.split("\n", false)
	for line: String in lines:
		var trimmed := line.strip_edges()
		if not trimmed.begins_with('"file"'):
			continue
		var colon := trimmed.find(":")
		var quote_open := trimmed.find('"', colon)
		var quote_close := trimmed.rfind('"')
		if colon < 0 or quote_open < 0 or quote_close <= quote_open:
			_fatal("asset catalog file field is malformed: %s" % trimmed)
			return PackedStringArray()
		var glb_path := trimmed.substr(quote_open + 1, quote_close - quote_open - 1)
		if not glb_path.begins_with("res://assets/generated/") or not glb_path.ends_with(".glb"):
			_fatal("asset catalog file path is not a generated GLB: %s" % glb_path)
			return PackedStringArray()
		files.append(glb_path)
	if files.is_empty():
		_fatal("Blender asset catalog has no assets: %s" % CATALOG_PATH)
	return files


func _validate_asset_layers() -> bool:
	var counts := {"base": 0, "growth": 0, "overload": 0, "scrutiny": 0}
	for found_node: Node in _kit_root.find_children("*", "Node3D", true, false):
		var node_name := String(found_node.name)
		if node_name.begins_with("Base__"):
			counts["base"] += 1
		elif node_name.begins_with("Growth__"):
			counts["growth"] += 1
		elif node_name.begins_with("Overload__"):
			counts["overload"] += 1
		elif node_name.begins_with("Scrutiny__"):
			counts["scrutiny"] += 1
	if counts["base"] < 3:
		_fatal("imported kit must contain Base__ nodes for all subjects; counts=%s" % str(counts))
		return false
	for state_name in STATE_NAMES:
		if counts[state_name] < 1:
			_fatal("imported kit state layer is empty: %s; counts=%s" % [state_name, str(counts)])
			return false
	print("ASSET_LAYER_VALIDATION base=%d growth=%d overload=%d scrutiny=%d" % [counts["base"], counts["growth"], counts["overload"], counts["scrutiny"]])
	return true


func _set_state(state_name: String) -> bool:
	if not STATE_NAMES.has(state_name):
		_fatal("state must be one of %s, got '%s'" % [str(STATE_NAMES), state_name])
		return false
	var active_prefix := "%s__" % state_name.capitalize()
	var active_count := 0
	for found_node: Node in _kit_root.find_children("*", "Node3D", true, false):
		var node: Node3D = found_node as Node3D
		if node == null:
			_fatal("imported kit Node3D query returned a non-Node3D node: %s" % found_node.name)
			return false
		var node_name := String(node.name)
		if node_name.begins_with("Base__"):
			node.visible = true
		elif node_name.begins_with("Growth__") or node_name.begins_with("Overload__") or node_name.begins_with("Scrutiny__"):
			node.visible = node_name.begins_with(active_prefix)
			if node.visible:
				active_count += 1
	if active_count == 0:
		_fatal("active imported state layer has no visible nodes: %s" % state_name)
		return false

	_current_state = state_name
	var state_color: Color = STATE_COLORS[state_name]
	_state_label.text = "STATE / %s" % state_name.to_upper()
	_state_style.border_color = state_color
	for status_light in _status_lights:
		status_light.light_color = state_color
		status_light.light_energy = 4.2 if state_name == "overload" else 3.2
	print("STATE_APPLIED state=%s active_nodes=%d" % [state_name, active_count])
	return true


func _run_render_test(args: PackedStringArray) -> void:
	var output_dir := _read_option(args, "--output-dir", ProjectSettings.globalize_path("res://evidence"))
	if not output_dir.is_absolute_path():
		_fatal("--output-dir must be an absolute path, got: %s" % output_dir)
		return
	var make_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if make_error != OK:
		_fatal("could not create evidence directory '%s': error %d" % [output_dir, make_error])
		return

	var states_to_render: Array[String] = STATE_NAMES.duplicate()
	if args.has("--render-state"):
		states_to_render = [_read_option(args, "--render-state", "")]

	for state_name in states_to_render:
		if not _set_state(state_name):
			return
		for frame_index in range(12):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		if image == null or image.is_empty():
			_fatal("viewport returned an empty image for state '%s'" % state_name)
			return
		if image.get_size() != TARGET_SIZE:
			_fatal("viewport size must be %s, got %s" % [str(TARGET_SIZE), str(image.get_size())])
			return
		var output_path := output_dir.path_join("%s.png" % state_name)
		var save_error := image.save_png(output_path)
		if save_error != OK:
			_fatal("save_png failed for '%s': error %d" % [output_path, save_error])
			return
		var output_file := FileAccess.open(output_path, FileAccess.READ)
		if output_file == null or output_file.get_length() < 10000:
			_fatal("render evidence is missing or implausibly small: %s" % output_path)
			return
		print("RENDER_TEST_CAPTURE state=%s size=%s bytes=%d path=%s" % [state_name, str(image.get_size()), output_file.get_length(), output_path])

	print("RENDER_TEST_SUCCESS states=%s size=%s" % [str(states_to_render), str(TARGET_SIZE)])
	get_tree().quit(0)


func _read_option(args: PackedStringArray, option_name: String, default_value: String) -> String:
	var index := args.find(option_name)
	if index < 0:
		return default_value
	if index + 1 >= args.size():
		_fatal("command-line option requires a value: %s" % option_name)
		return ""
	return args[index + 1]


func _fatal(message: String) -> void:
	if _fatal_triggered:
		return
	_fatal_triggered = true
	push_error("RENDER_TEST_ERROR: %s" % message)
	printerr("RENDER_TEST_ERROR: %s" % message)
	get_tree().quit(2)
