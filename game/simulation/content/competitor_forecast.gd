class_name CompetitorForecast
extends Resource

@export var competitor_id: StringName = &""
@export var known_release_quarter_index: int = -1
@export var projected_coding_evaluation_min: int = -1
@export var projected_coding_evaluation_max: int = -1
@export var projected_reasoning_evaluation_min: int = -1
@export var projected_reasoning_evaluation_max: int = -1
@export var projected_efficiency_evaluation_min: int = -1
@export var projected_efficiency_evaluation_max: int = -1


func _init() -> void:
	pass


func reveals_exact_result(
		actual_coding_evaluation_points: int,
		actual_reasoning_evaluation_points: int,
		actual_efficiency_evaluation_points: int
	) -> bool:
	return (
		_range_is_point(
			projected_coding_evaluation_min,
			projected_coding_evaluation_max,
			actual_coding_evaluation_points
		)
		or _range_is_point(
			projected_reasoning_evaluation_min,
			projected_reasoning_evaluation_max,
			actual_reasoning_evaluation_points
		)
		or _range_is_point(
			projected_efficiency_evaluation_min,
			projected_efficiency_evaluation_max,
			actual_efficiency_evaluation_points
		)
	)


func _range_is_point(range_min: int, range_max: int, actual_value: int) -> bool:
	return range_min == range_max and range_min == actual_value
