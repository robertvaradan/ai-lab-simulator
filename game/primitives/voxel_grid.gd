class_name VoxelGrid
extends Object

const CELL_SIZE: float = 0.2
const SPECIFICATION_REFERENCE: String = "docs/tools/editor-primitives.md"


static func snap_length(value: float) -> float:
	var snapped: float = round(value / CELL_SIZE) * CELL_SIZE
	if snapped < CELL_SIZE:
		return CELL_SIZE
	return snapped


static func snap_size(value: Vector3) -> Vector3:
	return Vector3(snap_length(value.x), snap_length(value.y), snap_length(value.z))


static func max_thickness(size: Vector3) -> float:
	var limit: float = (minf(size.x, size.z) - CELL_SIZE) * 0.5
	if limit < CELL_SIZE:
		return CELL_SIZE
	return limit


static func minimum_outer_length(thickness: float) -> float:
	return snap_length(thickness) * 2.0 + CELL_SIZE


static func snap_thickness(value: float, size: Vector3) -> float:
	var snapped: float = snap_length(value)
	var limit: float = max_thickness(size)
	if snapped > limit:
		return limit
	return snapped


static func fit_size(size: Vector3, thickness: float) -> Vector3:
	var fitted: Vector3 = snap_size(size)
	var minimum_length: float = minimum_outer_length(thickness)
	if fitted.x < minimum_length:
		fitted.x = minimum_length
	if fitted.z < minimum_length:
		fitted.z = minimum_length
	return fitted
