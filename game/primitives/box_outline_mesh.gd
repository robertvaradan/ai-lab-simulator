@tool
class_name BoxOutlineMesh
extends PrimitiveMesh

const SPECIFICATION_REFERENCE: String = "docs/tools/editor-primitives.md"
const SEGMENT_COUNT: int = 4

@export var size: Vector3 = Vector3(1.0, 1.0, 1.0):
	get:
		return _size
	set(value):
		_set_size(value)

@export var thickness: float = 0.2:
	get:
		return _thickness
	set(value):
		_set_thickness(value)

var _size: Vector3 = Vector3(1.0, 1.0, 1.0)
var _thickness: float = 0.2
var _emit_vertices: PackedVector3Array = PackedVector3Array()
var _emit_normals: PackedVector3Array = PackedVector3Array()
var _emit_tangents: PackedFloat32Array = PackedFloat32Array()
var _emit_uvs: PackedVector2Array = PackedVector2Array()
var _emit_indices: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	_size = VoxelGrid.fit_size(_size, _thickness)
	_thickness = VoxelGrid.snap_thickness(_thickness, _size)


func get_inner_size() -> Vector3:
	return Vector3(_size.x - _thickness * 2.0, _size.y, _size.z - _thickness * 2.0)


func get_segment_centers() -> PackedVector3Array:
	var half: Vector3 = _size * 0.5
	var half_thickness: float = _thickness * 0.5
	var centers: PackedVector3Array = PackedVector3Array()
	centers.append(Vector3(0.0, 0.0, half.z - half_thickness))
	centers.append(Vector3(0.0, 0.0, -half.z + half_thickness))
	centers.append(Vector3(-half.x + half_thickness, 0.0, 0.0))
	centers.append(Vector3(half.x - half_thickness, 0.0, 0.0))
	return centers


func get_segment_sizes() -> PackedVector3Array:
	var inner_depth: float = _size.z - _thickness * 2.0
	var sizes: PackedVector3Array = PackedVector3Array()
	sizes.append(Vector3(_size.x, _size.y, _thickness))
	sizes.append(Vector3(_size.x, _size.y, _thickness))
	sizes.append(Vector3(_thickness, _size.y, inner_depth))
	sizes.append(Vector3(_thickness, _size.y, inner_depth))
	return sizes


func _create_mesh_array() -> Array:
	_emit_vertices = PackedVector3Array()
	_emit_normals = PackedVector3Array()
	_emit_tangents = PackedFloat32Array()
	_emit_uvs = PackedVector2Array()
	_emit_indices = PackedInt32Array()
	var centers: PackedVector3Array = get_segment_centers()
	var sizes: PackedVector3Array = get_segment_sizes()
	for segment_index: int in SEGMENT_COUNT:
		_append_box(centers[segment_index], sizes[segment_index])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _emit_vertices
	arrays[Mesh.ARRAY_NORMAL] = _emit_normals
	arrays[Mesh.ARRAY_TANGENT] = _emit_tangents
	arrays[Mesh.ARRAY_TEX_UV] = _emit_uvs
	arrays[Mesh.ARRAY_INDEX] = _emit_indices
	return arrays


func _set_size(value: Vector3) -> void:
	var next_size: Vector3 = VoxelGrid.fit_size(value, _thickness)
	if next_size.is_equal_approx(_size):
		return
	_size = next_size
	request_update()


func _set_thickness(value: float) -> void:
	var next_thickness: float = VoxelGrid.snap_thickness(value, _size)
	if is_equal_approx(next_thickness, _thickness):
		return
	_thickness = next_thickness
	request_update()


func _append_box(center: Vector3, box_size: Vector3) -> void:
	var half: Vector3 = box_size * 0.5
	_append_face(center + Vector3(half.x, 0.0, 0.0), Vector3.RIGHT, Vector3.BACK, half.z, half.y)
	_append_face(center + Vector3(-half.x, 0.0, 0.0), Vector3.LEFT, Vector3.FORWARD, half.z, half.y)
	_append_face(center + Vector3(0.0, half.y, 0.0), Vector3.UP, Vector3.RIGHT, half.x, half.z)
	_append_face(center + Vector3(0.0, -half.y, 0.0), Vector3.DOWN, Vector3.RIGHT, half.x, half.z)
	_append_face(center + Vector3(0.0, 0.0, half.z), Vector3.BACK, Vector3.RIGHT, half.x, half.y)
	_append_face(center + Vector3(0.0, 0.0, -half.z), Vector3.FORWARD, Vector3.LEFT, half.x, half.y)


func _append_face(
	face_center: Vector3,
	normal: Vector3,
	tangent: Vector3,
	half_u: float,
	half_v: float
) -> void:
	var bitangent: Vector3 = normal.cross(tangent)
	var v0: Vector3 = face_center - tangent * half_u - bitangent * half_v
	var v1: Vector3 = face_center + tangent * half_u - bitangent * half_v
	var v2: Vector3 = face_center + tangent * half_u + bitangent * half_v
	var v3: Vector3 = face_center - tangent * half_u + bitangent * half_v
	var base_index: int = _emit_vertices.size()
	_emit_vertices.append(v0)
	_emit_vertices.append(v1)
	_emit_vertices.append(v2)
	_emit_vertices.append(v3)
	_emit_normals.append(normal)
	_emit_normals.append(normal)
	_emit_normals.append(normal)
	_emit_normals.append(normal)
	_emit_tangents.append(tangent.x)
	_emit_tangents.append(tangent.y)
	_emit_tangents.append(tangent.z)
	_emit_tangents.append(1.0)
	_emit_tangents.append(tangent.x)
	_emit_tangents.append(tangent.y)
	_emit_tangents.append(tangent.z)
	_emit_tangents.append(1.0)
	_emit_tangents.append(tangent.x)
	_emit_tangents.append(tangent.y)
	_emit_tangents.append(tangent.z)
	_emit_tangents.append(1.0)
	_emit_tangents.append(tangent.x)
	_emit_tangents.append(tangent.y)
	_emit_tangents.append(tangent.z)
	_emit_tangents.append(1.0)
	_emit_uvs.append(Vector2(0.0, 1.0))
	_emit_uvs.append(Vector2(1.0, 1.0))
	_emit_uvs.append(Vector2(1.0, 0.0))
	_emit_uvs.append(Vector2(0.0, 0.0))
	_emit_indices.append(base_index)
	_emit_indices.append(base_index + 2)
	_emit_indices.append(base_index + 1)
	_emit_indices.append(base_index)
	_emit_indices.append(base_index + 3)
	_emit_indices.append(base_index + 2)
