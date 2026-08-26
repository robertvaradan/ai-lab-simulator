class_name GameStateService
extends Service

var _expected_scenario_id: StringName
var _expected_content_version: int
var _expected_rule_graph_id: StringName
var _expected_rule_graph_version: int
var _known_content_ids: Dictionary[StringName, bool] = {}
var _game_state_echo: GameStateEcho


func _init(
		context: ServiceContext,
		initial_state: GameState,
		expected_scenario_id: StringName,
		expected_content_version: int,
		expected_rule_graph_id: StringName,
		expected_rule_graph_version: int,
		known_content_ids: Dictionary[StringName, bool]
	) -> void:
	super(context)
	_expected_scenario_id = expected_scenario_id
	_expected_content_version = expected_content_version
	_expected_rule_graph_id = expected_rule_graph_id
	_expected_rule_graph_version = expected_rule_graph_version
	_known_content_ids.assign(known_content_ids)
	_game_state_echo = GameStateEcho.new(
		initial_state,
		_expected_scenario_id,
		_expected_content_version,
		_expected_rule_graph_id,
		_expected_rule_graph_version,
		_known_content_ids
	)
	if not _game_state_echo.is_initialized():
		ServiceContract.fail(
			"invalid_initial_game_state",
			"A Game State service must receive a complete and valid initial Game State. %s"
			% " ".join(_game_state_echo.get_initialization_errors())
		)


func get_game_state_echo() -> GameStateEcho:
	return _game_state_echo


func get_current_state() -> GameState:
	return _game_state_echo.get_current_state()


func publish_operation_result(operation_result: SimulationOperationResult) -> GameStateValidationResult:
	var validation: GameStateValidationResult = GameStateValidationResult.new()
	if operation_result == null:
		validation.add_error("The Simulation Operation Result is missing.")
		return validation
	if (
		operation_result.outcome != SimulationOperationOutcome.Type.COMPLETED
		and operation_result.outcome != SimulationOperationOutcome.Type.DECISION_REQUIRED
	):
		validation.add_error(
			"Only a COMPLETED or DECISION_REQUIRED Simulation Operation Result can publish Game State."
		)
		return validation
	if not operation_result.has_candidate_state():
		validation.add_error("The successful Simulation Operation Result has no candidate Game State.")
		return validation
	return _game_state_echo.try_replace(operation_result.candidate_state)


func save_snapshot(path: String) -> GameStateSaveResult:
	return GameStateSnapshotStore.save_snapshot(
		get_current_state(),
		path,
		_expected_scenario_id,
		_expected_content_version,
		_expected_rule_graph_id,
		_expected_rule_graph_version,
		_known_content_ids
	)


func load_snapshot(path: String) -> GameStateLoadResult:
	var load_result: GameStateLoadResult = GameStateSnapshotStore.load_snapshot(
		path,
		_expected_scenario_id,
		_expected_content_version,
		_expected_rule_graph_id,
		_expected_rule_graph_version,
		_known_content_ids
	)
	if not load_result.succeeded():
		return load_result
	var publication_result: GameStateValidationResult = _game_state_echo.try_replace(load_result.state)
	if publication_result.is_valid():
		return load_result
	load_result.state = null
	load_result.errors.append_array(publication_result.errors)
	return load_result
