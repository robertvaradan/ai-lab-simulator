@tool
extends EditorNode3DGizmoPlugin

const HANDLE_HEIGHT_POS: int = 0
const HANDLE_HEIGHT_NEG: int = 1
const HANDLE_RADIUS_X_POS: int = 2
const HANDLE_RADIUS_X_NEG: int = 3
const HANDLE_RADIUS_Z_POS: int = 4
const HANDLE_RADIUS_Z_NEG: int = 5
const HANDLE_THICKNESS_X_POS: int = 6
const HANDLE_THICKNESS_X_NEG: int = 7
const HANDLE_THICKNESS_Z_POS: int = 8
const HANDLE_THICKNESS_Z_NEG: int = 9
const HEIGHT_HANDLE_COUNT: int = 2
const RADIUS_HANDLE_LAST: int = 5
const AXIS_LENGTH: float = 4096.0
const MESH_SCRIPT: GDScript = preload("res://primitives/cylinder_outline_mesh.gd")

var _initial_height: float = 0.0
var _initial_radius: float = 0.0
var _initial_transform: Transform3D = Transform3D.IDENTITY


func _init() -> void:
	create_material("lines", Color(0.23, 0.78, 0.82), false, true, false)
	create_handle_material("handles", true)
	create_handle_material("thickness_handles", true)


func _get_gizmo_name() -> String:
	return "CylinderOutline"


func _get_priority() -> int:
	return 50


func _has_gizmo(for_node_3d: Node3D) -> bool:
	if for_node_3d is CylinderOutline:
		return true
	var mesh_instance: MeshInstance3D = for_node_3d as MeshInstance3D
	if mesh_instance == null:
		return false
	if mesh_instance.mesh is CylinderOutlineMesh:
		return true
	return mesh_instance.mesh != null and mesh_instance.mesh.get_script() == MESH_SCRIPT


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var mesh: CylinderOutlineMesh = _mesh_of(gizmo)
	if mesh == null:
		return
	var lines: PackedVector3Array = _wire_lines(mesh)
	gizmo.add_lines(lines, get_material("lines", gizmo), false)
	gizmo.add_collision_segments(lines)
	var size_handles: PackedVector3Array = _size_handle_points(mesh.radius, mesh.height)
	var size_ids: PackedInt32Array = PackedInt32Array(
		[
			HANDLE_HEIGHT_POS,
			HANDLE_HEIGHT_NEG,
			HANDLE_RADIUS_X_POS,
			HANDLE_RADIUS_X_NEG,
			HANDLE_RADIUS_Z_POS,
			HANDLE_RADIUS_Z_NEG,
		]
	)
	gizmo.add_handles(size_handles, get_material("handles"), size_ids)
	var thickness_handles: PackedVector3Array = _thickness_handle_points(mesh.radius, mesh.thickness)
	var thickness_ids: PackedInt32Array = PackedInt32Array(
		[HANDLE_THICKNESS_X_POS, HANDLE_THICKNESS_X_NEG, HANDLE_THICKNESS_Z_POS, HANDLE_THICKNESS_Z_NEG]
	)
	gizmo.add_handles(thickness_handles, get_material("thickness_handles"), thickness_ids)


func _get_handle_name(_gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool) -> String:
	match handle_id:
		HANDLE_HEIGHT_POS, HANDLE_HEIGHT_NEG:
			return "Height"
		HANDLE_RADIUS_X_POS, HANDLE_RADIUS_X_NEG, HANDLE_RADIUS_Z_POS, HANDLE_RADIUS_Z_NEG:
			return "Radius"
		HANDLE_THICKNESS_X_POS, HANDLE_THICKNESS_X_NEG, HANDLE_THICKNESS_Z_POS, HANDLE_THICKNESS_Z_NEG:
			return "Thickness"
		_:
			return ""


func _get_handle_value(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> Variant:
	var mesh: CylinderOutlineMesh = _mesh_of(gizmo)
	var node: Node3D = gizmo.get_node_3d()
	if mesh == null or node == null:
		return {}
	return {
		"height": mesh.height,
		"radius": mesh.radius,
		"thickness": mesh.thickness,
		"origin": node.global_position,
	}


func _begin_handle_action(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> void:
	var mesh: CylinderOutlineMesh = _mesh_of(gizmo)
	var node: Node3D = gizmo.get_node_3d()
	if mesh == null or node == null:
		return
	_initial_height = mesh.height
	_initial_radius = mesh.radius
	_initial_transform = node.global_transform


func _set_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	_secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2
) -> void:
	var mesh: CylinderOutlineMesh = _mesh_of(gizmo)
	var node: Node3D = gizmo.get_node_3d()
	if mesh == null or node == null or camera == null:
		return
	var segment: PackedVector3Array = _local_drag_segment(camera, screen_pos)
	if handle_id < HEIGHT_HANDLE_COUNT:
		_set_height_handle(mesh, node, handle_id, segment)
	elif handle_id <= RADIUS_HANDLE_LAST:
		_set_radius_handle(mesh, node, handle_id, segment)
	else:
		_set_thickness_handle(mesh, handle_id, segment)
	node.update_gizmos()


func _commit_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	_secondary: bool,
	restore: Variant,
	cancel: bool
) -> void:
	var mesh: CylinderOutlineMesh = _mesh_of(gizmo)
	var node: Node3D = gizmo.get_node_3d()
	if mesh == null or node == null:
		return
	if not restore is Dictionary:
		return
	var restore_data: Dictionary = restore
	if cancel:
		_apply_restore(mesh, node, restore_data)
		return
	var undo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	var action_name: String = "Change Cylinder Outline Thickness"
	if handle_id < HEIGHT_HANDLE_COUNT:
		action_name = "Change Cylinder Outline Height"
	elif handle_id <= RADIUS_HANDLE_LAST:
		action_name = "Change Cylinder Outline Radius"
	undo.create_action(action_name)
	undo.add_do_property(mesh, "height", mesh.height)
	undo.add_do_property(mesh, "radius", mesh.radius)
	undo.add_do_property(mesh, "thickness", mesh.thickness)
	undo.add_do_property(node, "global_position", node.global_position)
	undo.add_undo_property(mesh, "height", restore_data["height"])
	undo.add_undo_property(mesh, "radius", restore_data["radius"])
	undo.add_undo_property(mesh, "thickness", restore_data["thickness"])
	undo.add_undo_property(node, "global_position", restore_data["origin"])
	undo.commit_action()


func _mesh_of(gizmo: EditorNode3DGizmo) -> CylinderOutlineMesh:
	var node: Node3D = gizmo.get_node_3d()
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance == null:
		return null
	return mesh_instance.mesh as CylinderOutlineMesh


func _size_handle_points(radius: float, height: float) -> PackedVector3Array:
	var half_height: float = height * 0.5
	var handles: PackedVector3Array = PackedVector3Array()
	handles.append(Vector3(0.0, half_height, 0.0))
	handles.append(Vector3(0.0, -half_height, 0.0))
	handles.append(Vector3(radius, 0.0, 0.0))
	handles.append(Vector3(-radius, 0.0, 0.0))
	handles.append(Vector3(0.0, 0.0, radius))
	handles.append(Vector3(0.0, 0.0, -radius))
	return handles


func _thickness_handle_points(radius: float, thickness: float) -> PackedVector3Array:
	var inner_radius: float = radius - thickness
	var handles: PackedVector3Array = PackedVector3Array()
	handles.append(Vector3(inner_radius, 0.0, 0.0))
	handles.append(Vector3(-inner_radius, 0.0, 0.0))
	handles.append(Vector3(0.0, 0.0, inner_radius))
	handles.append(Vector3(0.0, 0.0, -inner_radius))
	return handles


func _wire_lines(mesh: CylinderOutlineMesh) -> PackedVector3Array:
	var lines: PackedVector3Array = PackedVector3Array()
	var half_height: float = mesh.height * 0.5
	var inner_radius: float = mesh.get_inner_radius()
	lines.append_array(_ring_edges(mesh.radius, half_height, mesh.radial_segments))
	lines.append_array(_ring_edges(mesh.radius, -half_height, mesh.radial_segments))
	lines.append_array(_ring_edges(inner_radius, half_height, mesh.radial_segments))
	lines.append_array(_ring_edges(inner_radius, -half_height, mesh.radial_segments))
	for segment_index: int in mesh.radial_segments:
		var angle: float = TAU * float(segment_index) / float(mesh.radial_segments)
		var outer: Vector3 = _point_on_ring(angle, mesh.radius)
		var inner: Vector3 = _point_on_ring(angle, inner_radius)
		lines.append(outer + Vector3(0.0, half_height, 0.0))
		lines.append(outer + Vector3(0.0, -half_height, 0.0))
		lines.append(inner + Vector3(0.0, half_height, 0.0))
		lines.append(inner + Vector3(0.0, -half_height, 0.0))
	return lines


func _ring_edges(ring_radius: float, y: float, segment_count: int) -> PackedVector3Array:
	var lines: PackedVector3Array = PackedVector3Array()
	for segment_index: int in segment_count:
		var angle_a: float = TAU * float(segment_index) / float(segment_count)
		var angle_b: float = TAU * float(segment_index + 1) / float(segment_count)
		var point_a: Vector3 = _point_on_ring(angle_a, ring_radius) + Vector3(0.0, y, 0.0)
		var point_b: Vector3 = _point_on_ring(angle_b, ring_radius) + Vector3(0.0, y, 0.0)
		lines.append(point_a)
		lines.append(point_b)
	return lines


func _point_on_ring(angle: float, ring_radius: float) -> Vector3:
	return Vector3(cos(angle) * ring_radius, 0.0, sin(angle) * ring_radius)


func _local_drag_segment(camera: Camera3D, screen_pos: Vector2) -> PackedVector3Array:
	var inverse: Transform3D = _initial_transform.affine_inverse()
	var ray_from: Vector3 = camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(screen_pos)
	var segment: PackedVector3Array = PackedVector3Array()
	segment.append(inverse * ray_from)
	segment.append(inverse * (ray_from + ray_dir * AXIS_LENGTH))
	return segment


func _closest_on_axis(axis: int, segment: PackedVector3Array) -> float:
	var axis_start: Vector3 = Vector3.ZERO
	var axis_end: Vector3 = Vector3.ZERO
	axis_start[axis] = AXIS_LENGTH
	axis_end[axis] = -AXIS_LENGTH
	var closest: PackedVector3Array = Geometry3D.get_closest_points_between_segments(
		axis_start,
		axis_end,
		segment[0],
		segment[1]
	)
	return closest[0][axis]


func _set_height_handle(
	mesh: CylinderOutlineMesh,
	node: Node3D,
	handle_id: int,
	segment: PackedVector3Array
) -> void:
	var sign: int = 1
	if handle_id == HANDLE_HEIGHT_NEG:
		sign = -1
	var axis_value: float = _closest_on_axis(1, segment)
	var next_height: float = _initial_height
	var from_center: bool = Input.is_key_pressed(KEY_ALT)
	if from_center:
		next_height = absf(axis_value) * 2.0
	elif sign > 0:
		next_height = axis_value - _initial_height * -0.5
	else:
		next_height = _initial_height * 0.5 - axis_value
	mesh.height = next_height
	if from_center:
		node.global_position = _initial_transform.origin
		return
	var negative_end: float = _initial_height * -0.5
	var positive_end: float = _initial_height * 0.5
	if sign > 0:
		positive_end = negative_end + mesh.height
	else:
		negative_end = positive_end - mesh.height
	var offset: Vector3 = Vector3.ZERO
	offset.y = (positive_end + negative_end) * 0.5
	node.global_position = _initial_transform * offset


func _set_radius_handle(
	mesh: CylinderOutlineMesh,
	node: Node3D,
	handle_id: int,
	segment: PackedVector3Array
) -> void:
	var axis: int = 0
	match handle_id:
		HANDLE_RADIUS_X_POS, HANDLE_RADIUS_X_NEG:
			axis = 0
		HANDLE_RADIUS_Z_POS, HANDLE_RADIUS_Z_NEG:
			axis = 2
		_:
			return
	var axis_value: float = _closest_on_axis(axis, segment)
	mesh.radius = absf(axis_value)
	node.global_position = _initial_transform.origin


func _set_thickness_handle(mesh: CylinderOutlineMesh, handle_id: int, segment: PackedVector3Array) -> void:
	var axis: int = 0
	var sign: int = 1
	match handle_id:
		HANDLE_THICKNESS_X_POS:
			axis = 0
			sign = 1
		HANDLE_THICKNESS_X_NEG:
			axis = 0
			sign = -1
		HANDLE_THICKNESS_Z_POS:
			axis = 2
			sign = 1
		HANDLE_THICKNESS_Z_NEG:
			axis = 2
			sign = -1
		_:
			return
	var axis_value: float = _closest_on_axis(axis, segment)
	mesh.thickness = _initial_radius - float(sign) * axis_value


func _apply_restore(mesh: CylinderOutlineMesh, node: Node3D, restore_data: Dictionary) -> void:
	var restored_height: Variant = restore_data["height"]
	var restored_radius: Variant = restore_data["radius"]
	var restored_thickness: Variant = restore_data["thickness"]
	var restored_origin: Variant = restore_data["origin"]
	if restored_height is float:
		mesh.height = restored_height
	if restored_radius is float:
		mesh.radius = restored_radius
	if restored_thickness is float:
		mesh.thickness = restored_thickness
	if restored_origin is Vector3:
		node.global_position = restored_origin
