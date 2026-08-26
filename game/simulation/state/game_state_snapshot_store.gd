class_name GameStateSnapshotStore
extends RefCounted


static func save_snapshot(
		state: GameState,
		path: String,
		expected_scenario_id: StringName,
		expected_content_version: int,
		expected_rule_graph_id: StringName,
		expected_rule_graph_version: int,
		known_content_ids: Dictionary[StringName, bool]
	) -> GameStateSaveResult:
	var result: GameStateSaveResult = GameStateSaveResult.new()
	if path.get_extension().to_lower() != "tres":
		result.add_error("Game State snapshot path must use the .tres extension.")
		return result
	var validation: GameStateValidationResult = GameStateValidator.validate(
		state,
		expected_scenario_id,
		expected_content_version,
		expected_rule_graph_id,
		expected_rule_graph_version,
		known_content_ids
	)
	if not validation.is_valid():
		result.errors.append_array(validation.errors)
		result.error_code = ERR_INVALID_DATA
		return result
	result.error_code = ResourceSaver.save(state, path)
	if result.error_code != OK:
		result.errors.append("ResourceSaver failed with error code %d." % result.error_code)
	return result


static func load_snapshot(
		path: String,
		expected_scenario_id: StringName,
		expected_content_version: int,
		expected_rule_graph_id: StringName,
		expected_rule_graph_version: int,
		known_content_ids: Dictionary[StringName, bool]
	) -> GameStateLoadResult:
	var result: GameStateLoadResult = GameStateLoadResult.new()
	if path.get_extension().to_lower() != "tres":
		result.add_error("Game State snapshot path must use the .tres extension.")
		return result
	if not ResourceLoader.exists(path):
		result.add_error("Game State snapshot does not exist: %s" % path)
		return result
	var loaded_resource: Resource = ResourceLoader.load(
		path,
		"",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP
	)
	if loaded_resource == null:
		result.add_error("Game State snapshot could not be loaded: %s" % path)
		return result
	if not loaded_resource is GameState:
		result.add_error("Snapshot root is not a Game State: %s" % path)
		return result
	var loaded_state: GameState = loaded_resource
	var validation: GameStateValidationResult = GameStateValidator.validate(
		loaded_state,
		expected_scenario_id,
		expected_content_version,
		expected_rule_graph_id,
		expected_rule_graph_version,
		known_content_ids
	)
	if not validation.is_valid():
		result.errors.append_array(validation.errors)
		return result
	result.state = loaded_state
	return result
