class_name SimulationStatePathRegistry
extends RefCounted

var _paths: Dictionary[StringName, SimulationStatePath] = {}
var _diagnostics: Array[SimulationDiagnostic] = []
var _is_sealed: bool = false


func register_path(path: SimulationStatePath) -> bool:
	if _is_sealed:
		_add_error(&"state_path_registry.sealed", "The state-path registry is sealed.")
		return false
	if path == null:
		_add_error(&"state_path_registry.missing_path", "A registered state path is missing.")
		return false
	if _paths.has(path.stable_id):
		_add_error(
			&"state_path_registry.duplicate_path_id",
			"State path %s is duplicated." % path.stable_id,
			path.stable_id
		)
		return false
	_paths[path.stable_id] = path
	return true


func seal() -> void:
	_is_sealed = true


func is_sealed() -> bool:
	return _is_sealed


func has_path(path_id: StringName) -> bool:
	return _paths.has(path_id)


func get_path(path_id: StringName) -> SimulationStatePath:
	return _paths.get(path_id)


func get_path_ids() -> Array[StringName]:
	var identifiers: Array[StringName] = []
	identifiers.assign(_paths.keys())
	identifiers.sort()
	return identifiers


func get_diagnostics() -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	diagnostics.assign(_diagnostics)
	return diagnostics


func _add_error(code: StringName, message: String, path: StringName = &"") -> void:
	_diagnostics.append(
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			code,
			message,
			&"",
			path
		)
	)
