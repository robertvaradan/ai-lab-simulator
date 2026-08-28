@tool
class_name CylinderOutlineMesh
extends PrimitiveMesh

const SPECIFICATION_REFERENCE: String = "docs/tools/editor-primitives.md"

@export var height: float = 1.0:
	get:
		return _height
	set(value):
		_set_height(value)

@export var radius: float = 1.0:
	get:
		return _radius
	set(value):
		_set_radius(value)

@export var thickness: float = 0.2:
	get:
		return _thickness
	set(value):
		_set_thickness(value)

@export var radial_segments: int = 16:
	get:
		return _radial_segments
	set(value):
		_set_radial_segments(value)

var _height: float = 1.0
var _radius: float = 1.0
var _thickness: float = 0.2
var _radial_segments: int = 16
var _emit_vertices: PackedVector3Array = PackedVector3Array()
var _emit_normals: PackedVector3Array = PackedVector3Array()
var _emit_tangents: PackedFloat32Array = PackedFloat32Array()
var _emit_uvs: PackedVector2Array = PackedVector2Array()
var _emit_indices: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	_radius = VoxelGrid.fit_radius(_radius, _thickness)
	_height = VoxelGrid.snap_length(_height)
	_thickness = VoxelGrid.snap_cylinder_thickness(_thickness, _radius)
	_radial_segments = VoxelGrid.snap_radial_segments(_radial_segments)


func get_inner_radius() -> float:
	return _radius - _thickness


func _create_mesh_array() -> Array:
	_emit_vertices = PackedVector3Array()
	_emit_normals = PackedVector3Array()
	_emit_tangents = PackedFloat32Array()
	_emit_uvs = PackedVector2Array()
	_emit_indices = PackedInt32Array()
	var half_height: float = _height * 0.5
	var inner_radius: float = get_inner_radius()
	var segment_count: int = _radial_segments
	for segment_index: int in segment_count:
		var angle_a: float = TAU * float(segment_index) / float(segment_count)
		var angle_b: float = TAU * float(segment_index + 1) / float(segment_count)
		var outer_a: Vector3 = _point_on_ring(angle_a, _radius, 0.0)
		var outer_b: Vector3 = _point_on_ring(angle_b, _radius, 0.0)
		var inner_a: Vector3 = _point_on_ring(angle_a, inner_radius, 0.0)
		var inner_b: Vector3 = _point_on_ring(angle_b, inner_radius, 0.0)
		var outer_a_top: Vector3 = outer_a + Vector3(0.0, half_height, 0.0)
		var outer_b_top: Vector3 = outer_b + Vector3(0.0, half_height, 0.0)
		var outer_a_bottom: Vector3 = outer_a - Vector3(0.0, half_height, 0.0)
		var outer_b_bottom: Vector3 = outer_b - Vector3(0.0, half_height, 0.0)
		var inner_a_top: Vector3 = inner_a + Vector3(0.0, half_height, 0.0)
		var inner_b_top: Vector3 = inner_b + Vector3(0.0, half_height, 0.0)
		var inner_a_bottom: Vector3 = inner_a - Vector3(0.0, half_height, 0.0)
		var inner_b_bottom: Vector3 = inner_b - Vector3(0.0, half_height, 0.0)
		var outer_normal: Vector3 = _facet_normal(outer_a, outer_b)
		var inner_normal: Vector3 = -outer_normal
		_append_quad(outer_b_bottom, outer_a_bottom, outer_a_top, outer_b_top, outer_normal)
		_append_quad(inner_a_bottom, inner_b_bottom, inner_b_top, inner_a_top, inner_normal)
		_append_quad(outer_a_top, inner_a_top, inner_b_top, outer_b_top, Vector3.UP)
		_append_quad(outer_b_bottom, inner_b_bottom, inner_a_bottom, outer_a_bottom, Vector3.DOWN)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _emit_vertices
	arrays[Mesh.ARRAY_NORMAL] = _emit_normals
	arrays[Mesh.ARRAY_TANGENT] = _emit_tangents
	arrays[Mesh.ARRAY_TEX_UV] = _emit_uvs
	arrays[Mesh.ARRAY_INDEX] = _emit_indices
	return arrays


func _set_height(value: float) -> void:
	var next_height: float = VoxelGrid.snap_length(value)
	if is_equal_approx(next_height, _height):
		return
	_height = next_height
	request_update()


func _set_radius(value: float) -> void:
	var next_radius: float = VoxelGrid.fit_radius(value, _thickness)
	if is_equal_approx(next_radius, _radius):
		return
	_radius = next_radius
	request_update()


func _set_thickness(value: float) -> void:
	var next_thickness: float = VoxelGrid.snap_cylinder_thickness(value, _radius)
	if is_equal_approx(next_thickness, _thickness):
		return
	_thickness = next_thickness
	request_update()


func _set_radial_segments(value: int) -> void:
	var next_segments: int = VoxelGrid.snap_radial_segments(value)
	if next_segments == _radial_segments:
		return
	_radial_segments = next_segments
	request_update()


func _point_on_ring(angle: float, ring_radius: float, y: float) -> Vector3:
	return Vector3(cos(angle) * ring_radius, y, sin(angle) * ring_radius)


func _facet_normal(outer_a: Vector3, outer_b: Vector3) -> Vector3:
	var edge: Vector3 = outer_b - outer_a
	return Vector3(edge.z, 0.0, -edge.x).normalized()


func _append_quad(v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3) -> void:
	var corner_1: Vector3 = v1
	var corner_2: Vector3 = v2
	var corner_3: Vector3 = v3
	var alignment: Vector3 = (v1 - v0).cross(v3 - v0)
	if alignment.dot(normal) < 0.0:
		corner_1 = v3
		corner_3 = v1
	var tangent: Vector3 = (corner_1 - v0)
	if tangent.length_squared() < 0.000001:
		tangent = Vector3.RIGHT
	else:
		tangent = tangent.normalized()
	var base_index: int = _emit_vertices.size()
	_emit_vertices.append(v0)
	_emit_vertices.append(corner_1)
	_emit_vertices.append(corner_2)
	_emit_vertices.append(corner_3)
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
