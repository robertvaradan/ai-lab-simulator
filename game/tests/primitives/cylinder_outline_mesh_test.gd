extends SceneTree

const TEST_SUCCESS: String = "CYLINDER_OUTLINE_MESH_TEST_SUCCESS"
const EPSILON: float = 0.0001
const CASE_COUNT: int = 11

var _failure_count: int = 0


func _initialize() -> void:
	_verify_default_contract()
	_verify_voxel_snap()
	_verify_inset_growth()
	_verify_thickness_limit()
	_verify_radius_fits_thickness()
	_verify_radial_segments()
	_verify_hexagonal_and_octagonal_rings()
	_verify_mesh_stays_inside_outer_radius()
	_verify_top_and_bottom_faces()
	_verify_face_winding()
	_verify_cylinder_outline_node()
	_finish()


func _verify_default_contract() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	_expect(is_equal_approx(mesh.height, 1.0), "The default height is not 1 m.")
	_expect(is_equal_approx(mesh.radius, 1.0), "The default radius is not 1 m.")
	_expect(is_equal_approx(mesh.thickness, VoxelGrid.CELL_SIZE), "The default thickness is not one voxel.")
	_expect(is_equal_approx(mesh.get_inner_radius(), 0.8), "The default inner radius is not 0.8 m.")
	_expect(mesh.radial_segments == 16, "The default radial segment count is not 16.")


func _verify_voxel_snap() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	mesh.height = 0.33
	mesh.radius = 1.07
	mesh.thickness = 0.29
	_expect(_is_on_grid(mesh.height), "The snapped height is off the voxel grid.")
	_expect(_is_on_grid(mesh.radius), "The snapped radius is off the voxel grid.")
	_expect(_is_on_grid(mesh.thickness), "The snapped thickness is off the voxel grid.")
	_expect(mesh.thickness >= VoxelGrid.CELL_SIZE - EPSILON, "The thickness is below one voxel.")
	mesh.radial_segments = 7
	_expect(mesh.radial_segments == 7, "Radial segments snapped away from 7.")


func _verify_inset_growth() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	mesh.radius = 2.0
	mesh.height = 0.4
	var outer_radius_before: float = mesh.radius
	var inner_before: float = mesh.get_inner_radius()
	mesh.thickness = 0.4
	_expect(is_equal_approx(mesh.radius, outer_radius_before), "Thickness growth moved the outer radius.")
	_expect(is_equal_approx(mesh.thickness, 0.4), "The thickness did not accept 0.4 m.")
	_expect(
		is_equal_approx(mesh.get_inner_radius(), inner_before - 0.2),
		"Thickness did not grow inward."
	)
	_expect(is_equal_approx(mesh.height, 0.4), "Height inset when thickness changed.")


func _verify_thickness_limit() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	mesh.radius = 1.0
	mesh.thickness = 2.0
	_expect(is_equal_approx(mesh.thickness, 0.8), "An oversized thickness did not stop at the inset limit.")
	_expect(is_equal_approx(mesh.radius, 1.0), "An oversized thickness changed the outer radius.")


func _verify_radius_fits_thickness() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	mesh.thickness = 0.4
	mesh.radius = 0.2
	_expect(mesh.radius >= 0.6 - EPSILON, "A small radius did not keep a one-voxel hole.")
	_expect(is_equal_approx(mesh.thickness, 0.4), "Fitting the outer radius changed thickness.")
	_expect(_is_on_grid(mesh.radius), "The fitted radius left the voxel grid.")


func _verify_radial_segments() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	mesh.radial_segments = 2
	_expect(mesh.radial_segments == 3, "A radial segment count below 3 was not raised to 3.")
	mesh.radial_segments = 16
	_expect(_quad_count(mesh) == 4 * 16, "A 16-segment outline does not have 64 quads.")


func _verify_hexagonal_and_octagonal_rings() -> void:
	var hex_mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	hex_mesh.radial_segments = 6
	_expect(hex_mesh.radial_segments == 6, "The hexagonal segment count is not 6.")
	_expect(_unique_xz_directions(hex_mesh).size() == 6, "The hexagonal ring does not have six unique XZ directions.")
	_expect(_quad_count(hex_mesh) == 24, "A hexagonal outline does not have 24 quads.")
	var oct_mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	oct_mesh.radial_segments = 8
	_expect(oct_mesh.radial_segments == 8, "The octagonal segment count is not 8.")
	_expect(_unique_xz_directions(oct_mesh).size() == 8, "The octagonal ring does not have eight unique XZ directions.")
	_expect(_quad_count(oct_mesh) == 32, "An octagonal outline does not have 32 quads.")


func _verify_mesh_stays_inside_outer_radius() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	mesh.radius = 1.6
	mesh.height = 0.8
	mesh.thickness = 0.4
	mesh.radial_segments = 8
	var vertices: PackedVector3Array = _vertices_of(mesh)
	_expect(vertices.size() > 0, "The mesh has no vertices.")
	var half_height: float = mesh.height * 0.5
	var inner_radius: float = mesh.get_inner_radius()
	for vertex: Vector3 in vertices:
		var radial: float = Vector2(vertex.x, vertex.z).length()
		_expect(radial <= mesh.radius + EPSILON, "A vertex sits outside the outer radius.")
		_expect(radial >= inner_radius - EPSILON, "A vertex sits inside the inner hole.")
		_expect(absf(vertex.y) <= half_height + EPSILON, "A vertex sits outside the height.")


func _verify_top_and_bottom_faces() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	mesh.height = 0.8
	mesh.radius = 1.2
	mesh.thickness = 0.2
	mesh.radial_segments = 8
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
			_expect(is_equal_approx(vertices[i0].y, mesh.height * 0.5), "A top face is not on the outer top.")
		if stored_normal.dot(Vector3.DOWN) > 0.9:
			bottom_count += 1
			_expect(is_equal_approx(vertices[i0].y, -mesh.height * 0.5), "A bottom face is not on the outer bottom.")
	_expect(top_count == 16, "The octagonal outline does not have sixteen top triangles.")
	_expect(bottom_count == 16, "The octagonal outline does not have sixteen bottom triangles.")


func _verify_face_winding() -> void:
	var mesh: CylinderOutlineMesh = CylinderOutlineMesh.new()
	mesh.radial_segments = 6
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


func _verify_cylinder_outline_node() -> void:
	var outline: CylinderOutline = CylinderOutline.new()
	root.add_child(outline)
	_expect(outline.mesh is CylinderOutlineMesh, "The CylinderOutline node did not create a CylinderOutlineMesh.")
	outline.free()


func _quad_count(mesh: CylinderOutlineMesh) -> int:
	var arrays: Array = mesh.get_mesh_arrays()
	var index_value: Variant = arrays[Mesh.ARRAY_INDEX]
	if not index_value is PackedInt32Array:
		return 0
	var indices: PackedInt32Array = index_value
	return indices.size() / 6


func _unique_xz_directions(mesh: CylinderOutlineMesh) -> PackedVector2Array:
	var vertices: PackedVector3Array = _vertices_of(mesh)
	var directions: PackedVector2Array = PackedVector2Array()
	for vertex: Vector3 in vertices:
		var radial: Vector2 = Vector2(vertex.x, vertex.z)
		if radial.length() < EPSILON:
			continue
		var direction: Vector2 = radial.normalized()
		var found: bool = false
		for existing: Vector2 in directions:
			if existing.distance_to(direction) < 0.01:
				found = true
				break
		if found:
			continue
		directions.append(direction)
	return directions


func _vertices_of(mesh: CylinderOutlineMesh) -> PackedVector3Array:
	var arrays: Array = mesh.get_mesh_arrays()
	var vertex_value: Variant = arrays[Mesh.ARRAY_VERTEX]
	if vertex_value is PackedVector3Array:
		return vertex_value
	return PackedVector3Array()


func _is_on_grid(value: float) -> bool:
	var cells: float = value / VoxelGrid.CELL_SIZE
	return is_equal_approx(cells, roundf(cells))


func _finish() -> void:
	if _failure_count > 0:
		printerr("CYLINDER_OUTLINE_MESH_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=%d" % [TEST_SUCCESS, CASE_COUNT])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
