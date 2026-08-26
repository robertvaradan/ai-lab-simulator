class_name GameStateEcho
extends RefCounted

signal game_state_changed(current_state: GameState, previous_state: GameState)

var _expected_scenario_id: StringName
var _expected_content_version: int
var _expected_rule_graph_id: StringName
var _expected_rule_graph_version: int
var _known_content_ids: Dictionary[StringName, bool] = {}
var _current_state: GameState
var _previous_state: GameState
var _has_previous_state: bool = false
var _initialization_errors: Array[String] = []


func _init(
		initial_state: GameState,
		expected_scenario_id: StringName,
		expected_content_version: int,
		expected_rule_graph_id: StringName,
		expected_rule_graph_version: int,
		known_content_ids: Dictionary[StringName, bool]
	) -> void:
	_expected_scenario_id = expected_scenario_id
	_expected_content_version = expected_content_version
	_expected_rule_graph_id = expected_rule_graph_id
	_expected_rule_graph_version = expected_rule_graph_version
	_known_content_ids.assign(known_content_ids)
	var validation: GameStateValidationResult = _validate(initial_state)
	if not validation.is_valid():
		_initialization_errors.append_array(validation.errors)
		return
	_current_state = initial_state


func is_initialized() -> bool:
	return _current_state != null and _initialization_errors.is_empty()


func get_initialization_errors() -> Array[String]:
	var errors: Array[String] = []
	errors.assign(_initialization_errors)
	return errors


func get_current_state() -> GameState:
	return _current_state


func has_previous_state() -> bool:
	return _has_previous_state


func get_previous_state() -> GameState:
	return _previous_state


func try_replace(candidate_state: GameState) -> GameStateValidationResult:
	var validation: GameStateValidationResult = _validate(candidate_state)
	if not is_initialized():
		validation.add_error("GameStateEcho is not initialized.")
		return validation
	if candidate_state == _current_state:
		validation.add_error("A committed Game State replacement must use a new Game State instance.")
	if not validation.is_valid():
		return validation
	_previous_state = _current_state
	_current_state = candidate_state
	_has_previous_state = true
	game_state_changed.emit(_current_state, _previous_state)
	return validation


func _validate(candidate_state: GameState) -> GameStateValidationResult:
	return GameStateValidator.validate(
		candidate_state,
		_expected_scenario_id,
		_expected_content_version,
		_expected_rule_graph_id,
		_expected_rule_graph_version,
		_known_content_ids
	)
