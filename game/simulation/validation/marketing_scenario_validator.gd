class_name MarketingScenarioValidator
extends RefCounted


static func validate(definition: MarketingScenarioDefinition) -> GameStateValidationResult:
	var result: GameStateValidationResult = GameStateValidationResult.new()
	if definition == null:
		result.add_error("Marketing Scenario definition is missing.")
		return result
	if definition.schema_version != GameStateValidator.CURRENT_SCHEMA_VERSION:
		result.add_error(
			"Marketing Scenario schema version %d is incompatible with schema version %d."
			% [definition.schema_version, GameStateValidator.CURRENT_SCHEMA_VERSION]
		)
	if definition.content_version != 1:
		result.add_error("Marketing Scenario content version must be 1.")
	if definition.rule_graph_id != &"rule_graph.marketing.first_quarter":
		result.add_error("Marketing Scenario Rule Graph identifier is invalid.")
	if definition.rule_graph_version != 1:
		result.add_error("Marketing Scenario Rule Graph version must be 1.")
	if definition.stable_id != &"scenario.marketing.first_quarter":
		result.add_error("Marketing Scenario identifier must be scenario.marketing.first_quarter.")
	if definition.difficulty_profile_id != &"difficulty.standard":
		result.add_error("Marketing Scenario difficulty profile must be difficulty.standard.")
	if definition.specification_reference != "docs/marketing/marketing-scenario.md":
		result.add_error("Marketing Scenario specification reference is invalid.")

	var catalog: Dictionary[StringName, bool] = {}
	for identifier: StringName in definition.content_reference_ids:
		if not StableIdentifier.is_valid(identifier):
			result.add_error("Content reference identifier %s is invalid." % identifier)
		if catalog.has(identifier):
			result.add_error("Content reference identifier %s is duplicated." % identifier)
		catalog[identifier] = true
	if not catalog.has(definition.difficulty_profile_id):
		result.add_error("The difficulty profile does not exist in the content reference catalog.")

	var available_project_ids: Dictionary[StringName, bool] = {}
	for project_id: StringName in definition.available_project_ids:
		if not StableIdentifier.is_valid(project_id):
			result.add_error("Available Project identifier %s is invalid." % project_id)
		if available_project_ids.has(project_id):
			result.add_error("Available Project identifier %s is duplicated." % project_id)
		available_project_ids[project_id] = true
		if not catalog.has(project_id):
			result.add_error("Available Project identifier %s does not exist in the content reference catalog." % project_id)
	var required_project_ids: Array[StringName] = [
		&"project.research.frontier_model",
		&"project.scale.burst_compute",
		&"project.application.coding_agent",
	]
	if available_project_ids.size() != required_project_ids.size():
		result.add_error("The Marketing Scenario must contain exactly three available Projects.")
	for required_project_id: StringName in required_project_ids:
		if not available_project_ids.has(required_project_id):
			result.add_error("Required available Project %s is missing." % required_project_id)

	var command_types: Dictionary[StringName, bool] = {}
	for command_type_id: StringName in definition.command_type_ids:
		if not StableIdentifier.is_valid(command_type_id):
			result.add_error("Command type identifier %s is invalid." % command_type_id)
		if command_types.has(command_type_id):
			result.add_error("Command type identifier %s is duplicated." % command_type_id)
		command_types[command_type_id] = true
		if not catalog.has(command_type_id):
			result.add_error(
				"Command type identifier %s does not exist in the content reference catalog."
				% command_type_id
			)
	if command_types.size() != 1 or not command_types.has(&"command.project.start"):
		result.add_error("The Marketing Scenario must register command.project.start as its Command type.")

	if definition.starting_game_state == null:
		result.add_error("Marketing Scenario starting Game State is missing.")
		return result
	if definition.starting_game_state.random_generator_state != null:
		result.add_error("The Marketing Scenario must not contain random generator state.")
	var state_result: GameStateValidationResult = GameStateValidator.validate(
		definition.starting_game_state,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		catalog
	)
	result.errors.append_array(state_result.errors)
	return result
