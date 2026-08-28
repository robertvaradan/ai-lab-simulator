extends SceneTree

const TEST_SUCCESS: String = "BOX_OUTLINE_MESH_TEST_SUCCESS"
const EPSILON: float = 0.0001

var _failure_count: int = 0


func _initialize() -> void:
	_verify_default_contract()
	_verify_voxel_snap()
	_verify_inset_growth()
	_verify_thickness_limit()
	_verify_size_fits_thickness()
	_verify_segments_do_not_overlap()
	_verify_mesh_stays_inside_outer_size()
	_verify_top_and_bottom_faces()
	_verify_face_winding()
	_verify_box_outline_node()
	_finish()


func _verify_default_contract() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	_expect(mesh.size.is_equal_approx(Vector3(1.0, 1.0, 1.0)), "The default outer size is not 1 m.")
	_expect(is_equal_approx(mesh.thickness, VoxelGrid.CELL_SIZE), "The default thickness is not one voxel.")
	_expect(
		mesh.get_inner_size().is_equal_approx(Vector3(0.6, 1.0, 0.6)),
		"The default inner hole is not 0.6 m."
	)


func _verify_voxel_snap() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	mesh.size = Vector3(1.07, 0.33, 0.91)
	_expect(_is_on_grid(mesh.size.x), "The snapped X size is off the voxel grid.")
	_expect(_is_on_grid(mesh.size.y), "The snapped Y size is off the voxel grid.")
	_expect(_is_on_grid(mesh.size.z), "The snapped Z size is off the voxel grid.")
	mesh.thickness = 0.29
	_expect(_is_on_grid(mesh.thickness), "The snapped thickness is off the voxel grid.")
	_expect(mesh.thickness >= VoxelGrid.CELL_SIZE - EPSILON, "The thickness is below one voxel.")


func _verify_inset_growth() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	mesh.size = Vector3(2.0, 0.4, 1.6)
	var outer_before: Vector3 = mesh.size
	var inner_before: Vector3 = mesh.get_inner_size()
	mesh.thickness = 0.4
	_expect(mesh.size.is_equal_approx(outer_before), "Thickness growth moved the outer size.")
	_expect(is_equal_approx(mesh.thickness, 0.4), "The thickness did not accept 0.4 m.")
	var inner_after: Vector3 = mesh.get_inner_size()
	_expect(is_equal_approx(inner_after.x, inner_before.x - 0.4), "X thickness did not grow inward.")
	_expect(is_equal_approx(inner_after.z, inner_before.z - 0.4), "Z thickness did not grow inward.")
	_expect(is_equal_approx(inner_after.y, outer_before.y), "Y size inset when thickness changed.")
	var aabb: AABB = mesh.get_aabb()
	_expect(aabb.size.is_equal_approx(outer_before), "The mesh AABB is not the outer size.")


func _verify_thickness_limit() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	mesh.size = Vector3(1.0, 1.0, 1.0)
	mesh.thickness = 2.0
	_expect(is_equal_approx(mesh.thickness, 0.4), "An oversized thickness did not stop at the inset limit.")
	_expect(mesh.size.is_equal_approx(Vector3(1.0, 1.0, 1.0)), "An oversized thickness changed the outer size.")


func _verify_size_fits_thickness() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	mesh.thickness = 0.4
	mesh.size = Vector3(0.2, 0.2, 0.2)
	_expect(mesh.size.x >= 1.0 - EPSILON, "A small X size did not keep a one-voxel hole.")
	_expect(mesh.size.z >= 1.0 - EPSILON, "A small Z size did not keep a one-voxel hole.")
	_expect(is_equal_approx(mesh.thickness, 0.4), "Fitting the outer size changed thickness.")
	_expect(_is_on_grid(mesh.size.x) and _is_on_grid(mesh.size.z), "The fitted size left the voxel grid.")


func _verify_segments_do_not_overlap() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	mesh.size = Vector3(2.0, 0.6, 1.6)
	mesh.thickness = 0.4
	var centers: PackedVector3Array = mesh.get_segment_centers()
	var sizes: PackedVector3Array = mesh.get_segment_sizes()
	_expect(centers.size() == BoxOutlineMesh.SEGMENT_COUNT, "The outline does not have four bars.")
	_expect(sizes.size() == BoxOutlineMesh.SEGMENT_COUNT, "The outline does not have four bar sizes.")
	for first_index: int in BoxOutlineMesh.SEGMENT_COUNT:
		var first_box: AABB = AABB(centers[first_index] - sizes[first_index] * 0.5, sizes[first_index])
		for second_index: int in range(first_index + 1, BoxOutlineMesh.SEGMENT_COUNT):
			var second_box: AABB = AABB(centers[second_index] - sizes[second_index] * 0.5, sizes[second_index])
			_expect(not _volumes_overlap(first_box, second_box), "Outline bars overlap.")


func _verify_mesh_stays_inside_outer_size() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	mesh.size = Vector3(1.8, 0.8, 1.2)
	mesh.thickness = 0.2
	var vertices: PackedVector3Array = _vertices_of(mesh)
	_expect(vertices.size() > 0, "The outline mesh has no vertices.")
	var half: Vector3 = mesh.size * 0.5
	var inner_half: Vector3 = mesh.get_inner_size() * 0.5
	var saw_outer_x: bool = false
	var saw_inner_x: bool = false
	for vertex: Vector3 in vertices:
		_expect(absf(vertex.x) <= half.x + EPSILON, "A vertex sits outside the outer X face.")
		_expect(absf(vertex.y) <= half.y + EPSILON, "A vertex sits outside the outer Y face.")
		_expect(absf(vertex.z) <= half.z + EPSILON, "A vertex sits outside the outer Z face.")
		if is_equal_approx(absf(vertex.x), half.x):
			saw_outer_x = true
		if is_equal_approx(absf(vertex.x), inner_half.x):
			saw_inner_x = true
	_expect(saw_outer_x, "The mesh has no outer X face.")
	_expect(saw_inner_x, "The mesh has no inset inner X face.")


func _verify_top_and_bottom_faces() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	mesh.size = Vector3(1.8, 0.8, 1.2)
	mesh.thickness = 0.2
	var arrays: Array = mesh.get_mesh_arrays()
	var vertex_value: Variant = arrays[Mesh.ARRAY_VERTEX]
	var index_value: Variant = arrays[Mesh.ARRAY_INDEX]
	var normal_value: Variant = arrays[Mesh.ARRAY_NORMAL]
	_expect(vertex_value is PackedVector3Array, "The mesh vertex array is missing.")
	_expect(index_value is PackedInt32Array, "The mesh index array is missing.")
	_expect(normal_value is PackedVector3Array, "The mesh normal array is missing.")
	if not vertex_value is PackedVector3Array:
		return
	if not index_value is PackedInt32Array:
		return
	if not normal_value is PackedVector3Array:
		return
	var vertices: PackedVector3Array = vertex_value
	var indices: PackedInt32Array = index_value
	var normals: PackedVector3Array = normal_value
	var top_count: int = 0
	var bottom_count: int = 0
	var triangle_count: int = indices.size() / 3
	for triangle_index: int in triangle_count:
		var i0: int = indices[triangle_index * 3]
		var stored_normal: Vector3 = normals[i0]
		if stored_normal.dot(Vector3.UP) > 0.9:
			top_count += 1
			_expect(is_equal_approx(vertices[i0].y, mesh.size.y * 0.5), "A top face is not on the outer top.")
		if stored_normal.dot(Vector3.DOWN) > 0.9:
			bottom_count += 1
			_expect(is_equal_approx(vertices[i0].y, -mesh.size.y * 0.5), "A bottom face is not on the outer bottom.")
	_expect(top_count == 8, "The outline does not have eight top triangles.")
	_expect(bottom_count == 8, "The outline does not have eight bottom triangles.")


func _verify_face_winding() -> void:
	var mesh: BoxOutlineMesh = BoxOutlineMesh.new()
	var arrays: Array = mesh.get_mesh_arrays()
	var vertex_value: Variant = arrays[Mesh.ARRAY_VERTEX]
	var index_value: Variant = arrays[Mesh.ARRAY_INDEX]
	var normal_value: Variant = arrays[Mesh.ARRAY_NORMAL]
	_expect(vertex_value is PackedVector3Array, "The mesh vertex array is missing.")
	_expect(index_value is PackedInt32Array, "The mesh index array is missing.")
	_expect(normal_value is PackedVector3Array, "The mesh normal array is missing.")
	if not vertex_value is PackedVector3Array:
		return
	if not index_value is PackedInt32Array:
		return
	if not normal_value is PackedVector3Array:
		return
	var vertices: PackedVector3Array = vertex_value
	var indices: PackedInt32Array = index_value
	var normals: PackedVector3Array = normal_value
	_expect(indices.size() >= 3, "The mesh has no triangles.")
	if indices.size() < 3:
		return
	var triangle_count: int = indices.size() / 3
	for triangle_index: int in triangle_count:
		var i0: int = indices[triangle_index * 3]
		var i1: int = indices[triangle_index * 3 + 1]
		var i2: int = indices[triangle_index * 3 + 2]
		var v0: Vector3 = vertices[i0]
		var v1: Vector3 = vertices[i1]
		var v2: Vector3 = vertices[i2]
		var winding_normal: Vector3 = (v1 - v0).cross(v2 - v0)
		_expect(
			winding_normal.dot(normals[i0]) < 0.0,
			"Triangle winding does not match Godot PrimitiveMesh front faces."
		)


func _verify_box_outline_node() -> void:
	var outline: BoxOutline = BoxOutline.new()
	root.add_child(outline)
	_expect(outline.mesh is BoxOutlineMesh, "The BoxOutline node did not create a BoxOutlineMesh.")
	outline.free()


func _vertices_of(mesh: BoxOutlineMesh) -> PackedVector3Array:
	var arrays: Array = mesh.get_mesh_arrays()
	var vertex_value: Variant = arrays[Mesh.ARRAY_VERTEX]
	if vertex_value is PackedVector3Array:
		return vertex_value
	return PackedVector3Array()


func _volumes_overlap(first_box: AABB, second_box: AABB) -> bool:
	var overlap: AABB = first_box.intersection(second_box)
	if overlap.size.x <= EPSILON:
		return false
	if overlap.size.y <= EPSILON:
		return false
	if overlap.size.z <= EPSILON:
		return false
	return true


func _is_on_grid(value: float) -> bool:
	var cells: float = value / VoxelGrid.CELL_SIZE
	return is_equal_approx(cells, roundf(cells))


func _finish() -> void:
	if _failure_count > 0:
		printerr("BOX_OUTLINE_MESH_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=10" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
