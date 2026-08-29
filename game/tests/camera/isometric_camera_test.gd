extends SceneTree

const TEST_SUCCESS: String = "ISOMETRIC_CAMERA_TEST_SUCCESS"
const EPSILON: float = 0.0001
const CASE_COUNT: int = 10

var _failure_count: int = 0


func _initialize() -> void:
	_verify_contract_errors()
	_verify_vertical_look_is_rejected()
	_verify_authored_pose_is_preserved()
	_verify_pan_does_not_rotate()
	_verify_zoom_does_not_rotate_or_move_focus()
	_verify_smoothing()
	_verify_negative_delta_is_rejected()
	_verify_pan_bounds()
	_verify_zoom_limits()
	_verify_disabled_input_does_not_read_actions()
	_finish()


func _verify_contract_errors() -> void:
	var camera: IsometricCamera = _make_unready_camera()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.min_size = 0.0
	camera.max_size = 0.0
	camera.pan_speed = 0.0
	camera.zoom_step = 0.0
	camera.pan_smoothing = 0.0
	camera.zoom_smoothing = 0.0
	camera.pan_bounds = Rect2(0.0, 0.0, 0.0, 0.0)
	var errors: PackedStringArray = camera.collect_contract_errors()
	_expect(errors.size() >= 7, "An invalid camera did not report contract errors.")
	_expect(_contains_error(errors, "orthogonal projection"), "Perspective projection was accepted.")
	_expect(_contains_error(errors, "minimum size"), "A zero minimum size was accepted.")
	_expect(_contains_error(errors, "maximum size"), "A maximum size equal to the minimum was accepted.")
	_expect(_contains_error(errors, "pan speed"), "A zero pan speed was accepted.")
	_expect(_contains_error(errors, "zoom step"), "A zero zoom step was accepted.")
	_expect(_contains_error(errors, "pan smoothing"), "A zero pan smoothing was accepted.")
	_expect(_contains_error(errors, "zoom smoothing"), "A zero zoom smoothing was accepted.")
	_expect(_contains_error(errors, "pan bounds"), "A zero pan bounds size was accepted.")
	camera.free()


func _verify_vertical_look_is_rejected() -> void:
	var camera: IsometricCamera = _make_unready_camera()
	camera.transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(0.0, 10.0, 0.0))
	var errors: PackedStringArray = camera.collect_rig_errors()
	_expect(_contains_error(errors, "must not be vertical"), "A vertical look direction was accepted.")
	camera.free()


func _verify_authored_pose_is_preserved() -> void:
	var camera: IsometricCamera = _make_ready_camera()
	var expected_origin := Vector3(12.0, 16.0, 12.0)
	_expect(camera.is_rig_ready(), "A valid camera did not capture its rig.")
	_expect(
		camera.position.distance_to(expected_origin) < EPSILON,
		"Rig capture moved the authored camera origin."
	)
	_expect(
		camera.transform.basis.is_equal_approx(camera.get_locked_basis()),
		"Rig capture changed the authored basis."
	)
	_expect(is_equal_approx(camera.get_focus_point().y, 0.0), "The focus point left the ground plane.")
	_expect(
		camera.position.is_equal_approx(camera.get_focus_point() + camera.get_camera_offset()),
		"The camera origin is not focus plus offset."
	)
	camera.free()


func _verify_pan_does_not_rotate() -> void:
	var camera: IsometricCamera = _make_ready_camera()
	var start_basis: Basis = camera.transform.basis
	var start_focus: Vector3 = camera.get_focus_point()
	var lateral: Vector3 = camera.get_lateral_axis()
	var forward: Vector3 = camera.get_forward_axis()
	_expect(is_equal_approx(lateral.y, 0.0), "The lateral axis is not on the ground plane.")
	_expect(is_equal_approx(forward.y, 0.0), "The forward axis is not on the ground plane.")
	camera.nudge_target_focus(lateral * 4.0)
	camera.snap_to_targets()
	var focus_delta: Vector3 = camera.get_focus_point() - start_focus
	_expect(focus_delta.dot(lateral) > 3.9, "A lateral pan did not move along the lateral axis.")
	_expect(absf(focus_delta.dot(forward)) < 0.01, "A lateral pan moved along the forward axis.")
	_expect(camera.transform.basis.is_equal_approx(start_basis), "Pan rotated the camera.")
	_expect(
		camera.position.is_equal_approx(camera.get_focus_point() + camera.get_camera_offset()),
		"Pan changed the camera offset."
	)
	camera.rotate_y(0.35)
	camera.advance(0.016)
	_expect(camera.transform.basis.is_equal_approx(start_basis), "The camera kept an applied rotation.")
	camera.free()


func _verify_zoom_does_not_rotate_or_move_focus() -> void:
	var camera: IsometricCamera = _make_ready_camera()
	var start_basis: Basis = camera.transform.basis
	var start_focus: Vector3 = camera.get_focus_point()
	var start_size: float = camera.size
	camera.nudge_target_size(-6.0)
	camera.snap_to_targets()
	_expect(is_equal_approx(camera.size, start_size - 6.0), "Zoom in did not decrease the orthogonal size.")
	_expect(camera.get_focus_point().is_equal_approx(start_focus), "Zoom moved the focus point.")
	_expect(camera.transform.basis.is_equal_approx(start_basis), "Zoom rotated the camera.")
	camera.nudge_target_size(6.0)
	camera.snap_to_targets()
	_expect(is_equal_approx(camera.size, start_size), "Zoom out did not restore the orthogonal size.")
	camera.free()


func _verify_smoothing() -> void:
	var camera: IsometricCamera = _make_ready_camera()
	var start_position: Vector3 = camera.position
	var start_size: float = camera.size
	camera.nudge_target_focus(Vector3(10.0, 0.0, 0.0))
	camera.nudge_target_size(-8.0)
	camera.advance(0.016)
	var moved: float = camera.position.distance_to(start_position)
	_expect(moved > 0.5, "Smoothing did not move the camera.")
	_expect(moved < 5.0, "Smoothing reached the pan target in one short step.")
	_expect(camera.size < start_size, "Smoothing did not change the orthogonal size.")
	_expect(camera.size > start_size - 8.0 + EPSILON, "Smoothing reached the zoom target in one short step.")
	_expect(
		camera.transform.basis.is_equal_approx(camera.get_locked_basis()),
		"Smoothing rotated the camera."
	)
	camera.snap_to_targets()
	_expect(
		camera.position.is_equal_approx(start_position + Vector3(10.0, 0.0, 0.0)),
		"Snap did not reach the pan target."
	)
	_expect(is_equal_approx(camera.size, start_size - 8.0), "Snap did not reach the zoom target.")
	camera.free()


func _verify_negative_delta_is_rejected() -> void:
	var camera: IsometricCamera = _make_ready_camera()
	var start_position: Vector3 = camera.position
	var start_size: float = camera.size
	camera.nudge_target_focus(Vector3(4.0, 0.0, 0.0))
	camera.advance(-0.016)
	_expect(camera.position.is_equal_approx(start_position), "A negative delta moved the camera.")
	_expect(is_equal_approx(camera.size, start_size), "A negative delta changed the orthogonal size.")
	camera.free()


func _verify_pan_bounds() -> void:
	var camera: IsometricCamera = _make_ready_camera()
	camera.nudge_target_focus(Vector3(1000.0, 5.0, 1000.0))
	camera.snap_to_targets()
	_expect(is_equal_approx(camera.get_focus_point().x, camera.pan_bounds.end.x), "Pan did not clamp to the maximum X bound.")
	_expect(is_equal_approx(camera.get_focus_point().z, camera.pan_bounds.end.y), "Pan did not clamp to the maximum Z bound.")
	_expect(is_equal_approx(camera.get_focus_point().y, 0.0), "Pan left the ground plane.")
	camera.nudge_target_focus(Vector3(-2000.0, 0.0, -2000.0))
	camera.snap_to_targets()
	_expect(
		is_equal_approx(camera.get_focus_point().x, camera.pan_bounds.position.x),
		"Pan did not clamp to the minimum X bound."
	)
	_expect(
		is_equal_approx(camera.get_focus_point().z, camera.pan_bounds.position.y),
		"Pan did not clamp to the minimum Z bound."
	)
	camera.free()


func _verify_zoom_limits() -> void:
	var camera: IsometricCamera = _make_ready_camera()
	camera.nudge_target_size(-1000.0)
	camera.snap_to_targets()
	_expect(is_equal_approx(camera.size, camera.min_size), "Zoom in passed the minimum size.")
	camera.nudge_target_size(1000.0)
	camera.snap_to_targets()
	_expect(is_equal_approx(camera.size, camera.max_size), "Zoom out passed the maximum size.")
	camera.free()


func _verify_disabled_input_does_not_read_actions() -> void:
	var camera: IsometricCamera = _make_ready_camera()
	_expect(not camera.input_enabled, "The test camera enabled input.")
	var start_focus: Vector3 = camera.get_focus_point()
	var start_size: float = camera.size
	camera.advance(0.05)
	_expect(camera.get_focus_point().is_equal_approx(start_focus), "Disabled input panned the camera.")
	_expect(is_equal_approx(camera.size, start_size), "Disabled input zoomed the camera.")
	camera.free()


func _make_unready_camera() -> IsometricCamera:
	var camera := IsometricCamera.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0
	camera.min_size = 8.0
	camera.max_size = 80.0
	camera.pan_speed = 28.0
	camera.zoom_step = 5.0
	camera.pan_smoothing = 10.0
	camera.zoom_smoothing = 12.0
	camera.pan_bounds = Rect2(-32.0, -32.0, 64.0, 64.0)
	camera.input_enabled = false
	return camera


func _make_ready_camera() -> IsometricCamera:
	var camera: IsometricCamera = _make_unready_camera()
	var origin := Vector3(12.0, 16.0, 12.0)
	camera.transform = Transform3D(Basis.looking_at(Vector3(-1.0, -1.0, -1.0), Vector3.UP), origin)
	var errors: PackedStringArray = camera.bind_rig()
	_expect(errors.is_empty(), "A valid camera reported rig errors.")
	_expect(camera.is_rig_ready(), "A valid camera did not become ready.")
	return camera


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for message: String in errors:
		if message.find(fragment) >= 0:
			return true
	return false


func _finish() -> void:
	if _failure_count > 0:
		printerr("ISOMETRIC_CAMERA_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=%d" % [TEST_SUCCESS, CASE_COUNT])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
