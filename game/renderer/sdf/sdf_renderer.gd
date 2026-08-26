class_name SdfRenderer
extends Node

signal renderer_ready(output_texture: Texture2DRD)
signal renderer_failed(message: String)
signal dispatch_submitted(state_name: String)

const SHADER_RESOURCE: RDShaderFile = preload("res://renderer/sdf/campus_sdf.glsl")
const STATE_NAMES: Array[StringName] = [&"growth", &"overload", &"scrutiny"]
const WORKGROUP_SIZE := Vector2i(8, 8)
const DEFAULT_CAMERA := Vector3(0.78, 0.62, 8.1)

@export var output_size := Vector2i(640, 360)

var output_texture := Texture2DRD.new()

var _rd: RenderingDevice
var _shader_rid := RID()
var _pipeline_rid := RID()
var _output_rid := RID()
var _uniform_set_rid := RID()
var _state_index := 0
var _dirty := false
var _initialized := false
var _published := false
var _failed := false
var _elapsed_seconds := 0.0


func _ready() -> void:
	if output_size.x <= 0 or output_size.y <= 0:
		_report_failure("SDF output dimensions must be positive; received %s." % output_size)
		return
	if output_size.x % WORKGROUP_SIZE.x != 0 or output_size.y % WORKGROUP_SIZE.y != 0:
		_report_failure("SDF output dimensions %s must be divisible by workgroup size %s." % [output_size, WORKGROUP_SIZE])
		return
	RenderingServer.call_on_render_thread(_initialize_renderer)


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	if _failed or not _initialized:
		return
	if not _published:
		output_texture.texture_rd_rid = _output_rid
		_published = true
		renderer_ready.emit(output_texture)
	if _dirty:
		_dirty = false
		var requested_state := _state_index
		RenderingServer.call_on_render_thread(_dispatch.bind(requested_state, _elapsed_seconds))


func set_state(state: StringName) -> void:
	var requested_index := STATE_NAMES.find(state)
	if requested_index < 0:
		_report_failure("Unknown SDF state '%s'. Contract states are %s." % [state, STATE_NAMES])
		return
	_state_index = requested_index
	_dirty = true


func request_render() -> void:
	if _failed:
		return
	_dirty = true


func _initialize_renderer() -> void:
	_rd = RenderingServer.get_rendering_device()
	if _rd == null:
		call_deferred("_report_failure", "The active Godot renderer did not provide a main RenderingDevice. Forward+ compute support is required.")
		return

	var shader_spirv := SHADER_RESOURCE.get_spirv()
	_shader_rid = _rd.shader_create_from_spirv(shader_spirv)
	if not _shader_rid.is_valid():
		call_deferred("_report_failure", "Godot could not create the SDF compute shader RID. Inspect shader import errors.")
		return
	_pipeline_rid = _rd.compute_pipeline_create(_shader_rid)
	if not _pipeline_rid.is_valid():
		call_deferred("_report_failure", "Godot could not create the SDF compute pipeline RID.")
		return

	var texture_format := RDTextureFormat.new()
	texture_format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	texture_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	texture_format.width = output_size.x
	texture_format.height = output_size.y
	texture_format.depth = 1
	texture_format.array_layers = 1
	texture_format.mipmaps = 1
	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)
	var texture_view := RDTextureView.new()
	_output_rid = _rd.texture_create(texture_format, texture_view, [])
	if not _output_rid.is_valid():
		call_deferred("_report_failure", "Godot could not create the SDF output texture RID.")
		return

	var output_uniform := RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_uniform.binding = 0
	output_uniform.add_id(_output_rid)
	_uniform_set_rid = _rd.uniform_set_create([output_uniform], _shader_rid, 0)
	if not _uniform_set_rid.is_valid():
		call_deferred("_report_failure", "Godot could not create the SDF output uniform set RID.")
		return

	_initialized = true
	print("SDF_RENDERER_INITIALIZED api=RenderingDevice resolution=%dx%d workgroup=%dx%d shader=%s" % [
		output_size.x,
		output_size.y,
		WORKGROUP_SIZE.x,
		WORKGROUP_SIZE.y,
		SHADER_RESOURCE.resource_path,
	])


func _dispatch(state_index: int, elapsed_seconds: float) -> void:
	if not _initialized or _failed:
		return
	var push_values := PackedFloat32Array([
		float(output_size.x),
		float(output_size.y),
		float(state_index),
		elapsed_seconds,
		DEFAULT_CAMERA.x,
		DEFAULT_CAMERA.y,
		DEFAULT_CAMERA.z,
		0.0,
	])
	var compute_list := _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline_rid)
	_rd.compute_list_bind_uniform_set(compute_list, _uniform_set_rid, 0)
	_rd.compute_list_set_push_constant(compute_list, push_values.to_byte_array(), 32)
	_rd.compute_list_dispatch(
		compute_list,
		output_size.x / WORKGROUP_SIZE.x,
		output_size.y / WORKGROUP_SIZE.y,
		1
	)
	_rd.compute_list_end()
	call_deferred("_notify_dispatch_submitted", state_index)


func _notify_dispatch_submitted(state_index: int) -> void:
	if state_index < 0 or state_index >= STATE_NAMES.size():
		_report_failure("Compute dispatch returned an invalid state index: %d." % state_index)
		return
	var state_name: String = String(STATE_NAMES[state_index])
	print("SDF_DISPATCH_SUBMITTED state=%s resolution=%dx%d groups=%dx%d" % [
		state_name,
		output_size.x,
		output_size.y,
		output_size.x / WORKGROUP_SIZE.x,
		output_size.y / WORKGROUP_SIZE.y,
	])
	dispatch_submitted.emit(state_name)


func _report_failure(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	renderer_failed.emit(message)


func _exit_tree() -> void:
	if _published:
		output_texture.texture_rd_rid = RID()
		_published = false
	if _rd != null:
		RenderingServer.call_on_render_thread(_free_renderer_resources)


func _free_renderer_resources() -> void:
	if _rd == null:
		return
	var resource_rids: Array[RID] = [_uniform_set_rid, _output_rid, _pipeline_rid, _shader_rid]
	for resource_rid: RID in resource_rids:
		if resource_rid.is_valid():
			_rd.free_rid(resource_rid)
	_uniform_set_rid = RID()
	_output_rid = RID()
	_pipeline_rid = RID()
	_shader_rid = RID()
