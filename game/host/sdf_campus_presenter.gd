class_name SdfCampusPresenter
extends Node

const OUTPUT_SIZE: Vector2i = Vector2i(1920, 1080)

var _renderer: SdfRenderer
var _world_texture: TextureRect
var _last_state_name: StringName = &""
var _ready_texture: Texture2DRD


func _ready() -> void:
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
	_renderer.output_size = OUTPUT_SIZE
	_renderer.renderer_ready.connect(_on_renderer_ready)
	_renderer.renderer_failed.connect(_on_renderer_failed)
	add_child(_renderer)


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
	return OUTPUT_SIZE


func get_presented_state_name() -> StringName:
	return _last_state_name


func get_world_texture() -> TextureRect:
	return _world_texture


static func state_name_from_game_state(state: GameState) -> StringName:
	var mapping: CampusVisualMapping = CampusVisualMapping.from_state(state)
	if mapping.competitor_release_visible:
		return &"scrutiny"
	if mapping.compute_link_visible:
		return &"overload"
	if mapping.uses_developed_laboratory():
		return &"growth"
	return &"growth"


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
