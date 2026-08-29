class_name IsometricCamera
extends Camera3D

const SPECIFICATION_REFERENCE: String = "docs/presentation/isometric-camera.md"
const GROUND_PLANE_Y: float = 0.0
const SETTLE_EPSILON: float = 0.0001
const AXIS_EPSILON: float = 0.000001

@export var min_size: float = 8.0
@export var max_size: float = 80.0
@export var pan_speed: float = 28.0
@export var zoom_step: float = 5.0
@export var pan_smoothing: float = 10.0
@export var zoom_smoothing: float = 12.0
@export var pan_bounds: Rect2 = Rect2(-32.0, -32.0, 64.0, 64.0)
@export var input_enabled: bool = true

var _rig_ready: bool = false
var _locked_basis: Basis = Basis.IDENTITY
var _offset: Vector3 = Vector3.ZERO
var _lateral_axis: Vector3 = Vector3.RIGHT
var _forward_axis: Vector3 = Vector3.FORWARD
var _focus: Vector3 = Vector3.ZERO
var _target_focus: Vector3 = Vector3.ZERO
var _target_size: float = 20.0
var _reference_size: float = 20.0
var _pointer_drag_active: bool = false


func _init() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = 20.0


func collect_contract_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if projection != Camera3D.PROJECTION_ORTHOGONAL:
		errors.append("The isometric camera must use orthogonal projection.")
	if min_size <= 0.0:
		errors.append("The isometric camera minimum size must be greater than zero.")
	if max_size <= min_size:
		errors.append("The isometric camera maximum size must be greater than the minimum size.")
	if size < min_size or size > max_size:
		errors.append("The isometric camera authored size must lie in the allowed size range.")
	if pan_speed <= 0.0:
		errors.append("The isometric camera pan speed must be greater than zero.")
	if zoom_step <= 0.0:
		errors.append("The isometric camera zoom step must be greater than zero.")
	if pan_smoothing <= 0.0:
		errors.append("The isometric camera pan smoothing must be greater than zero.")
	if zoom_smoothing <= 0.0:
		errors.append("The isometric camera zoom smoothing must be greater than zero.")
	if pan_bounds.size.x <= 0.0 or pan_bounds.size.y <= 0.0:
		errors.append("The isometric camera pan bounds size must be greater than zero.")
	return errors


func collect_rig_errors() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var look_direction: Vector3 = -transform.basis.z
	if is_zero_approx(look_direction.y):
		errors.append("The isometric camera look direction must not be horizontal.")
		return errors
	if absf(look_direction.x) < AXIS_EPSILON and absf(look_direction.z) < AXIS_EPSILON:
		errors.append("The isometric camera look direction must not be vertical.")
		return errors
	var hit_distance: float = (GROUND_PLANE_Y - position.y) / look_direction.y
	if hit_distance <= 0.0:
		errors.append("The isometric camera look ray must hit the ground plane.")
	var lateral: Vector3 = Vector3(transform.basis.x.x, 0.0, transform.basis.x.z)
	if lateral.length_squared() < AXIS_EPSILON:
		errors.append("The isometric camera right axis must have a ground component.")
	var forward: Vector3 = Vector3(look_direction.x, 0.0, look_direction.z)
	if forward.length_squared() < AXIS_EPSILON:
		errors.append("The isometric camera look direction must not be vertical.")
	return errors


func bind_rig() -> PackedStringArray:
	var errors: PackedStringArray = collect_contract_errors()
	errors.append_array(collect_rig_errors())
	if not errors.is_empty():
		_rig_ready = false
		return errors
	_capture_rig()
	return PackedStringArray()


func is_rig_ready() -> bool:
	return _rig_ready


func get_focus_point() -> Vector3:
	return _focus


func get_target_focus() -> Vector3:
	return _target_focus


func get_target_size() -> float:
	return _target_size


func get_lateral_axis() -> Vector3:
	return _lateral_axis


func get_forward_axis() -> Vector3:
	return _forward_axis


func get_camera_offset() -> Vector3:
	return _offset


func get_locked_basis() -> Basis:
	return _locked_basis


func nudge_target_focus(world_offset: Vector3) -> void:
	if not _rig_ready:
		return
	_target_focus.x += world_offset.x
	_target_focus.z += world_offset.z
	_clamp_target_focus()


func nudge_target_size(size_delta: float) -> void:
	if not _rig_ready:
		return
	_target_size = clampf(_target_size + size_delta, min_size, max_size)


func snap_to_targets() -> void:
	if not _rig_ready:
		return
	_focus = _target_focus
	size = _target_size
	_apply_pose()


func advance(delta: float) -> void:
	if delta < 0.0:
		push_error("Isometric camera advance delta must not be negative.")
		return
	if not _rig_ready:
		return
	_read_keyboard_pan(delta)
	_focus = _smooth_vector(_focus, _target_focus, pan_smoothing, delta)
	size = _smooth_scalar(size, _target_size, zoom_smoothing, delta)
	_apply_pose()


func _ready() -> void:
	var errors: PackedStringArray = bind_rig()
	for message: String in errors:
		push_error(message)
		printerr(message)
	if not _rig_ready:
		set_process(false)
		return
	set_process(true)


func _process(delta: float) -> void:
	advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not _rig_ready:
		return
	if event.is_echo():
		return
	if event.is_action_pressed(&"camera_zoom_in"):
		nudge_target_size(-zoom_step)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"camera_zoom_out"):
		nudge_target_size(zoom_step)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_MIDDLE:
			_pointer_drag_active = mouse_button.pressed
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and _pointer_drag_active:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_apply_pointer_pan(motion.relative)
		get_viewport().set_input_as_handled()


func _capture_rig() -> void:
	var look_direction: Vector3 = -transform.basis.z
	var hit_distance: float = (GROUND_PLANE_Y - position.y) / look_direction.y
	_focus = position + look_direction * hit_distance
	_focus.y = GROUND_PLANE_Y
	_target_focus = _focus
	_clamp_target_focus()
	_focus = _target_focus
	_offset = position - _focus
	_locked_basis = transform.basis
	_lateral_axis = Vector3(transform.basis.x.x, 0.0, transform.basis.x.z).normalized()
	_forward_axis = Vector3(look_direction.x, 0.0, look_direction.z).normalized()
	_target_size = size
	_reference_size = size
	_rig_ready = true
	_apply_pose()


func _read_keyboard_pan(delta: float) -> void:
	if not input_enabled:
		return
	var pan_axes := Vector2(
		Input.get_axis(&"camera_pan_left", &"camera_pan_right"),
		Input.get_axis(&"camera_pan_back", &"camera_pan_forward")
	)
	if pan_axes.length_squared() > 1.0:
		pan_axes = pan_axes.normalized()
	if pan_axes == Vector2.ZERO:
		return
	var speed_scale: float = _target_size / _reference_size
	var move: Vector3 = (
		(_lateral_axis * pan_axes.x) + (_forward_axis * pan_axes.y)
	) * pan_speed * speed_scale * delta
	nudge_target_focus(move)


func _apply_pointer_pan(screen_delta: Vector2) -> void:
	var view_height: float = get_viewport().get_visible_rect().size.y
	if view_height <= 0.0:
		push_error("Isometric camera pointer pan requires a positive viewport height.")
		return
	var world_per_pixel: float = size / view_height
	var move: Vector3 = (
		(_lateral_axis * screen_delta.x) + (_forward_axis * -screen_delta.y)
	) * world_per_pixel
	nudge_target_focus(move)


func _clamp_target_focus() -> void:
	_target_focus.x = clampf(_target_focus.x, pan_bounds.position.x, pan_bounds.end.x)
	_target_focus.y = GROUND_PLANE_Y
	_target_focus.z = clampf(_target_focus.z, pan_bounds.position.y, pan_bounds.end.y)


func _apply_pose() -> void:
	transform = Transform3D(_locked_basis, _focus + _offset)


func _smooth_vector(current: Vector3, target: Vector3, smoothing: float, delta: float) -> Vector3:
	if current.distance_squared_to(target) <= SETTLE_EPSILON * SETTLE_EPSILON:
		return target
	var factor: float = 1.0 - exp(-smoothing * delta)
	return current.lerp(target, factor)


func _smooth_scalar(current: float, target: float, smoothing: float, delta: float) -> float:
	if absf(current - target) <= SETTLE_EPSILON:
		return target
	var factor: float = 1.0 - exp(-smoothing * delta)
	return lerpf(current, target, factor)
