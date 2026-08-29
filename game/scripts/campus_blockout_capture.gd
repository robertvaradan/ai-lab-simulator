extends Node

const CAMPUS_SCENE_PATH := "res://scenes/campus_blockout.tscn"
const OUTPUT_RESOLUTION := Vector2i(1920, 1080)
const REFERENCE_IMAGE_RELATIVE_PATH := "../docs/concept-art/main-lab-site-context-v1.png"

var _campus_root: Node3D
var _automated: bool = false
var _output_path: String = ""
var _fatal_triggered: bool = false


func _ready() -> void:
	_parse_arguments()
	if _fatal_triggered:
		return
	_validate_viewport()
	if _fatal_triggered:
		return
	if not _load_editable_campus():
		return
	if _automated:
		call_deferred("_capture_blockout")
	else:
		print("CAMPUS_BLOCKOUT_EDITABLE_READY scene=%s" % CAMPUS_SCENE_PATH)


func _parse_arguments() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var argument_index: int = 0
	while argument_index < arguments.size():
		var argument: String = arguments[argument_index]
		if argument == "--render-blockout":
			_automated = true
		elif argument == "--output-path":
			if argument_index + 1 >= arguments.size():
				_fail("--output-path requires an absolute PNG path.")
				return
			argument_index += 1
			_output_path = arguments[argument_index]
		else:
			_fail("Unknown campus capture argument: %s." % argument)
			return
		argument_index += 1
	if _automated:
		if _output_path.is_empty():
			_fail("Automated campus capture requires --output-path <absolute PNG path>.")
			return
		if not _output_path.is_absolute_path() or not _output_path.ends_with(".png"):
			_fail("--output-path must be an absolute PNG path: %s." % _output_path)


func _validate_viewport() -> void:
	var window: Window = get_window()
	window.mode = Window.MODE_WINDOWED
	window.size = OUTPUT_RESOLUTION
	get_viewport().msaa_3d = Viewport.MSAA_4X
	if window.size != OUTPUT_RESOLUTION:
		_fail("Campus blockout viewport must be %s, got %s." % [OUTPUT_RESOLUTION, window.size])


func _load_editable_campus() -> bool:
	var campus_resource: Resource = ResourceLoader.load(CAMPUS_SCENE_PATH)
	if campus_resource == null or not campus_resource is PackedScene:
		_fail("Editable campus scene is missing or invalid: %s." % CAMPUS_SCENE_PATH)
		return false
	var campus_scene: PackedScene = campus_resource as PackedScene
	var campus_instance: Node = campus_scene.instantiate()
	if campus_instance == null or not campus_instance is Node3D:
		_fail("Editable campus scene root must be Node3D: %s." % CAMPUS_SCENE_PATH)
		return false
	_campus_root = campus_instance as Node3D
	if _campus_root.get_script() != null:
		_campus_root.free()
		_fail("Editable campus scene root must not have a runtime generator script.")
		return false
	add_child(_campus_root)
	var mesh_count: int = _campus_root.find_children("*", "MeshInstance3D", true, false).size()
	var light_count: int = _campus_root.find_children("*", "Light3D", true, false).size()
	var cameras: Array[Node] = _campus_root.find_children("*", "Camera3D", true, false)
	var camera_count: int = cameras.size()
	var environment_count: int = _campus_root.find_children("*", "WorldEnvironment", true, false).size()
	if mesh_count == 0:
		_fail("Editable campus scene must contain MeshInstance3D nodes.")
		return false
	if camera_count != 1:
		_fail("Editable campus scene must contain exactly one Camera3D, got %d." % camera_count)
		return false
	if not cameras[0] is IsometricCamera:
		_fail("Editable campus scene camera must be an IsometricCamera.")
		return false
	var isometric_camera: IsometricCamera = cameras[0] as IsometricCamera
	isometric_camera.input_enabled = false
	isometric_camera.snap_to_targets()
	if environment_count != 1:
		_fail("Editable campus scene must contain exactly one WorldEnvironment, got %d." % environment_count)
		return false
	print(
		"CAMPUS_BLOCKOUT_SCENE_LOADED meshes=%d lights=%d cameras=%d environments=%d script_free=true"
		% [mesh_count, light_count, camera_count, environment_count]
	)
	return true


func _capture_blockout() -> void:
	var output_directory: String = _output_path.get_base_dir()
	var make_error: Error = DirAccess.make_dir_recursive_absolute(output_directory)
	if make_error != OK:
		_fail("Could not create campus evidence directory '%s': error %d." % [output_directory, make_error])
		return
	for frame_index: int in range(18):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Campus blockout viewport returned an empty image.")
		return
	if image.get_size() != OUTPUT_RESOLUTION:
		_fail("Campus blockout capture must be %s, got %s." % [OUTPUT_RESOLUTION, image.get_size()])
		return
	var save_error: Error = image.save_png(_output_path)
	if save_error != OK:
		_fail("Could not save campus blockout PNG '%s': error %d." % [_output_path, save_error])
		return
	var output_file := FileAccess.open(_output_path, FileAccess.READ)
	if output_file == null or output_file.get_length() < 40000:
		_fail("Campus blockout PNG is missing or implausibly small: %s." % _output_path)
		return
	if not _save_reference_comparison(image):
		return
	print(
		"CAMPUS_BLOCKOUT_CAPTURE_SUCCESS size=%s bytes=%d path=%s"
		% [image.get_size(), output_file.get_length(), _output_path]
	)
	get_tree().quit(0)


func _save_reference_comparison(render_image: Image) -> bool:
	var project_root: String = ProjectSettings.globalize_path("res://")
	var reference_path: String = project_root.path_join(REFERENCE_IMAGE_RELATIVE_PATH).simplify_path()
	if not FileAccess.file_exists(reference_path):
		_fail("Campus blockout reference image is missing: %s." % reference_path)
		return false
	var reference_image: Image = Image.load_from_file(reference_path)
	if reference_image == null or reference_image.is_empty():
		_fail("Campus blockout reference image could not be loaded: %s." % reference_path)
		return false
	var reference_half: Image = reference_image.duplicate()
	var render_half: Image = render_image.duplicate()
	reference_half.convert(Image.FORMAT_RGBA8)
	render_half.convert(Image.FORMAT_RGBA8)
	reference_half.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	render_half.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	var comparison_image := Image.create_empty(1920, 540, false, Image.FORMAT_RGBA8)
	comparison_image.fill(Color("0d2027"))
	var half_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 540))
	comparison_image.blit_rect(reference_half, half_rect, Vector2i.ZERO)
	comparison_image.blit_rect(render_half, half_rect, Vector2i(960, 0))
	var comparison_path: String = "%s_comparison.png" % _output_path.get_basename()
	var comparison_error: Error = comparison_image.save_png(comparison_path)
	if comparison_error != OK:
		_fail("Could not save campus comparison PNG '%s': error %d." % [comparison_path, comparison_error])
		return false
	var comparison_file := FileAccess.open(comparison_path, FileAccess.READ)
	if comparison_file == null or comparison_file.get_length() < 40000:
		_fail("Campus comparison PNG is missing or implausibly small: %s." % comparison_path)
		return false
	print(
		"CAMPUS_BLOCKOUT_COMPARISON_SUCCESS size=%s bytes=%d path=%s"
		% [comparison_image.get_size(), comparison_file.get_length(), comparison_path]
	)
	return true


func _fail(message: String) -> void:
	if _fatal_triggered:
		return
	_fatal_triggered = true
	push_error("CAMPUS_BLOCKOUT_ERROR: %s" % message)
	printerr("CAMPUS_BLOCKOUT_ERROR: %s" % message)
	get_tree().quit(2)
