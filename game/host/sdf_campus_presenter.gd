class_name SdfCampusPresenter
extends Node

var _renderer: SdfRenderer
var _world_texture: TextureRect
var _last_state_name: StringName = &""
var _ready_texture: Texture2DRD
var _previous_scale_mode: Window.ContentScaleMode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
var _did_override_scale: bool = false


func _ready() -> void:
	var window: Window = get_window()
	if window == null:
		ServiceContract.fail("missing_campaign_window", "The campaign SDF presenter requires a Window.")
		return
	_previous_scale_mode = window.content_scale_mode
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_did_override_scale = true
	if not window.size_changed.is_connected(_on_window_size_changed):
		window.size_changed.connect(_on_window_size_changed)
	_world_texture = TextureRect.new()
	_world_texture.name = "SdfOutput"
	_world_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_world_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_world_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_world_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_world_texture)
	_renderer = SdfRenderer.new()
	_renderer.name = "SdfRenderer"
	_renderer.output_size = aligned_window_size(window)
	_renderer.renderer_ready.connect(_on_renderer_ready)
	_renderer.renderer_failed.connect(_on_renderer_failed)
	add_child(_renderer)


func _exit_tree() -> void:
	var window: Window = get_window()
	if window != null and window.size_changed.is_connected(_on_window_size_changed):
		window.size_changed.disconnect(_on_window_size_changed)
	if _did_override_scale and window != null:
		window.content_scale_mode = _previous_scale_mode
		_did_override_scale = false


func present_state(state: GameState) -> void:
	var state_name: StringName = state_name_from_game_state(state)
	if state_name == _last_state_name and _ready_texture != null:
		return
	_last_state_name = state_name
	if _renderer != null:
		_renderer.set_state(state_name)


func get_renderer() -> SdfRenderer:
	return _renderer


func get_output_size() -> Vector2i:
	if _renderer != null:
		return _renderer.output_size
	var window: Window = get_window()
	if window == null:
		return Vector2i()
	return aligned_window_size(window)


func get_presented_state_name() -> StringName:
	return _last_state_name


func get_world_texture() -> TextureRect:
	return _world_texture


static func align_output_size(size: Vector2i) -> Vector2i:
	var aligned: Vector2i = Vector2i(
		size.x - (size.x % SdfRenderer.WORKGROUP_SIZE.x),
		size.y - (size.y % SdfRenderer.WORKGROUP_SIZE.y)
	)
	if aligned.x <= 0 or aligned.y <= 0:
		ServiceContract.fail(
			"invalid_campaign_sdf_size",
			"The campaign SDF output size %s is invalid for workgroup %s." % [size, SdfRenderer.WORKGROUP_SIZE]
		)
		return Vector2i()
	return aligned


static func aligned_window_size(window: Window) -> Vector2i:
	if window == null:
		ServiceContract.fail("missing_campaign_window", "The campaign SDF presenter requires a Window.")
		return Vector2i()
	return align_output_size(window.size)


static func state_name_from_game_state(state: GameState) -> StringName:
	var mapping: CampusVisualMapping = CampusVisualMapping.from_state(state)
	if mapping.competitor_release_visible:
		return &"scrutiny"
	if mapping.compute_link_visible:
		return &"overload"
	if mapping.uses_developed_laboratory():
		return &"growth"
	return &"growth"


func _on_window_size_changed() -> void:
	if _renderer == null:
		return
	var window: Window = get_window()
	if window == null:
		ServiceContract.fail("missing_campaign_window", "The campaign SDF presenter requires a Window.")
		return
	_renderer.set_output_size(aligned_window_size(window))


func _on_renderer_ready(output_texture: Texture2DRD) -> void:
	_ready_texture = output_texture
	if _world_texture != null:
		_world_texture.texture = output_texture
	if _last_state_name == &"":
		_last_state_name = &"growth"
	if _renderer != null:
		_renderer.set_state(_last_state_name)


func _on_renderer_failed(message: String) -> void:
	ServiceContract.fail(
		"sdf_renderer_failed",
		"The campaign SDF renderer failed. %s" % message
	)
