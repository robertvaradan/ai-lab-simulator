@tool
extends EditorNode3DGizmoPlugin

const HANDLE_SIZE_X_POS: int = 0
const HANDLE_SIZE_X_NEG: int = 1
const HANDLE_SIZE_Y_POS: int = 2
const HANDLE_SIZE_Y_NEG: int = 3
const HANDLE_SIZE_Z_POS: int = 4
const HANDLE_SIZE_Z_NEG: int = 5
const HANDLE_THICKNESS_X_POS: int = 6
const HANDLE_THICKNESS_X_NEG: int = 7
const HANDLE_THICKNESS_Z_POS: int = 8
const HANDLE_THICKNESS_Z_NEG: int = 9
const SIZE_HANDLE_COUNT: int = 6
const AXIS_LENGTH: float = 4096.0

var _initial_size: Vector3 = Vector3.ZERO
var _initial_transform: Transform3D = Transform3D.IDENTITY


func _init() -> void:
	create_material("lines", Color(0.23, 0.78, 0.82), false, true, false)
	create_handle_material("handles")
	create_handle_material("thickness_handles")


func _get_gizmo_name() -> String:
	return "BoxOutlineMesh"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	var mesh_instance: MeshInstance3D = for_node_3d as MeshInstance3D
	if mesh_instance == null:
		return false
	return mesh_instance.mesh is BoxOutlineMesh


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var mesh: BoxOutlineMesh = _mesh_of(gizmo)
	if mesh == null:
		return
	gizmo.add_lines(_wire_lines(mesh.size, mesh.get_inner_size()), get_material("lines", gizmo), false)
	var size_handles: PackedVector3Array = _size_handle_points(mesh.size)
	var size_ids: PackedInt32Array = PackedInt32Array(
		[HANDLE_SIZE_X_POS, HANDLE_SIZE_X_NEG, HANDLE_SIZE_Y_POS, HANDLE_SIZE_Y_NEG, HANDLE_SIZE_Z_POS, HANDLE_SIZE_Z_NEG]
	)
	gizmo.add_handles(size_handles, get_material("handles", gizmo), size_ids)
	var thickness_handles: PackedVector3Array = _thickness_handle_points(mesh.size, mesh.thickness)
	var thickness_ids: PackedInt32Array = PackedInt32Array(
		[HANDLE_THICKNESS_X_POS, HANDLE_THICKNESS_X_NEG, HANDLE_THICKNESS_Z_POS, HANDLE_THICKNESS_Z_NEG]
	)
	gizmo.add_handles(thickness_handles, get_material("thickness_handles", gizmo), thickness_ids)


func _get_handle_name(_gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool) -> String:
	match handle_id:
		HANDLE_SIZE_X_POS, HANDLE_SIZE_X_NEG:
			return "Size X"
		HANDLE_SIZE_Y_POS, HANDLE_SIZE_Y_NEG:
			return "Size Y"
		HANDLE_SIZE_Z_POS, HANDLE_SIZE_Z_NEG:
			return "Size Z"
		HANDLE_THICKNESS_X_POS, HANDLE_THICKNESS_X_NEG, HANDLE_THICKNESS_Z_POS, HANDLE_THICKNESS_Z_NEG:
			return "Thickness"
		_:
			return ""


func _get_handle_value(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> Variant:
	var mesh: BoxOutlineMesh = _mesh_of(gizmo)
	var node: Node3D = gizmo.get_node_3d()
	if mesh == null or node == null:
		return {}
	return {
		"size": mesh.size,
		"thickness": mesh.thickness,
		"origin": node.global_position,
	}


func _begin_handle_action(gizmo: EditorNode3DGizmo, _handle_id: int, _secondary: bool) -> void:
	var mesh: BoxOutlineMesh = _mesh_of(gizmo)
	var node: Node3D = gizmo.get_node_3d()
	if mesh == null or node == null:
		return
	_initial_size = mesh.size
	_initial_transform = node.global_transform


func _set_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	_secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2
) -> void:
	var mesh: BoxOutlineMesh = _mesh_of(gizmo)
	var node: Node3D = gizmo.get_node_3d()
	if mesh == null or node == null or camera == null:
		return
	var segment: PackedVector3Array = _local_drag_segment(camera, screen_pos)
	if handle_id < SIZE_HANDLE_COUNT:
		_set_size_handle(mesh, node, handle_id, segment)
		return
	_set_thickness_handle(mesh, handle_id, segment)


func _commit_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	_secondary: bool,
	restore: Variant,
	cancel: bool
) -> void:
	var mesh: BoxOutlineMesh = _mesh_of(gizmo)
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
	var action_name: String = "Change Box Outline Thickness"
	if handle_id < SIZE_HANDLE_COUNT:
		action_name = "Change Box Outline Size"
	undo.create_action(action_name)
	undo.add_do_property(mesh, "size", mesh.size)
	undo.add_do_property(mesh, "thickness", mesh.thickness)
	undo.add_do_property(node, "global_position", node.global_position)
	undo.add_undo_property(mesh, "size", restore_data["size"])
	undo.add_undo_property(mesh, "thickness", restore_data["thickness"])
	undo.add_undo_property(node, "global_position", restore_data["origin"])
	undo.commit_action()


func _mesh_of(gizmo: EditorNode3DGizmo) -> BoxOutlineMesh:
	var node: Node3D = gizmo.get_node_3d()
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance == null:
		return null
	return mesh_instance.mesh as BoxOutlineMesh


func _size_handle_points(size: Vector3) -> PackedVector3Array:
	var half: Vector3 = size * 0.5
	var handles: PackedVector3Array = PackedVector3Array()
	handles.append(Vector3(half.x, 0.0, 0.0))
	handles.append(Vector3(-half.x, 0.0, 0.0))
	handles.append(Vector3(0.0, half.y, 0.0))
	handles.append(Vector3(0.0, -half.y, 0.0))
	handles.append(Vector3(0.0, 0.0, half.z))
	handles.append(Vector3(0.0, 0.0, -half.z))
	return handles


func _thickness_handle_points(size: Vector3, thickness: float) -> PackedVector3Array:
	var half: Vector3 = size * 0.5
	var handles: PackedVector3Array = PackedVector3Array()
	handles.append(Vector3(half.x - thickness, 0.0, 0.0))
	handles.append(Vector3(-half.x + thickness, 0.0, 0.0))
	handles.append(Vector3(0.0, 0.0, half.z - thickness))
	handles.append(Vector3(0.0, 0.0, -half.z + thickness))
	return handles


func _wire_lines(outer_size: Vector3, inner_size: Vector3) -> PackedVector3Array:
	var lines: PackedVector3Array = PackedVector3Array()
	lines.append_array(_box_edges(outer_size))
	lines.append_array(_box_edges(inner_size))
	return lines


func _box_edges(box_size: Vector3) -> PackedVector3Array:
	var half: Vector3 = box_size * 0.5
	var corners: PackedVector3Array = PackedVector3Array()
	var signs: Array[int] = [-1, 1]
	for y_sign: int in signs:
		for z_sign: int in signs:
			for x_sign: int in signs:
				corners.append(Vector3(half.x * float(x_sign), half.y * float(y_sign), half.z * float(z_sign)))
	var edge_pairs: Array[Vector2i] = [
		Vector2i(0, 1),
		Vector2i(2, 3),
		Vector2i(0, 2),
		Vector2i(1, 3),
		Vector2i(4, 5),
		Vector2i(6, 7),
		Vector2i(4, 6),
		Vector2i(5, 7),
		Vector2i(0, 4),
		Vector2i(1, 5),
		Vector2i(2, 6),
		Vector2i(3, 7),
	]
	var lines: PackedVector3Array = PackedVector3Array()
	for edge: Vector2i in edge_pairs:
		lines.append(corners[edge.x])
		lines.append(corners[edge.y])
	return lines


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


func _set_size_handle(mesh: BoxOutlineMesh, node: Node3D, handle_id: int, segment: PackedVector3Array) -> void:
	var axis: int = handle_id / 2
	if handle_id == HANDLE_SIZE_Y_POS or handle_id == HANDLE_SIZE_Y_NEG:
		axis = 1
	elif handle_id == HANDLE_SIZE_Z_POS or handle_id == HANDLE_SIZE_Z_NEG:
		axis = 2
	elif handle_id == HANDLE_SIZE_X_POS or handle_id == HANDLE_SIZE_X_NEG:
		axis = 0
	var sign: int = 1
	if handle_id % 2 == 1:
		sign = -1
	var axis_value: float = _closest_on_axis(axis, segment)
	var next_size: Vector3 = _initial_size
	var from_center: bool = Input.is_key_pressed(KEY_ALT)
	if from_center:
		next_size[axis] = absf(axis_value) * 2.0
	elif sign > 0:
		next_size[axis] = axis_value - _initial_size[axis] * -0.5
	else:
		next_size[axis] = _initial_size[axis] * 0.5 - axis_value
	mesh.size = next_size
	if from_center:
		node.global_position = _initial_transform.origin
		return
	var negative_end: float = _initial_size[axis] * -0.5
	var positive_end: float = _initial_size[axis] * 0.5
	if sign > 0:
		positive_end = negative_end + mesh.size[axis]
	else:
		negative_end = positive_end - mesh.size[axis]
	var offset: Vector3 = Vector3.ZERO
	offset[axis] = (positive_end + negative_end) * 0.5
	node.global_position = _initial_transform * offset


func _set_thickness_handle(mesh: BoxOutlineMesh, handle_id: int, segment: PackedVector3Array) -> void:
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
	var next_thickness: float = _initial_size[axis] * 0.5 - float(sign) * axis_value
	mesh.thickness = next_thickness


func _apply_restore(mesh: BoxOutlineMesh, node: Node3D, restore_data: Dictionary) -> void:
	var restored_size: Variant = restore_data["size"]
	var restored_thickness: Variant = restore_data["thickness"]
	var restored_origin: Variant = restore_data["origin"]
	if restored_size is Vector3:
		mesh.size = restored_size
	if restored_thickness is float:
		mesh.thickness = restored_thickness
	if restored_origin is Vector3:
		node.global_position = restored_origin
