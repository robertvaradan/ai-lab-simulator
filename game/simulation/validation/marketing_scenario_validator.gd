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

	_validate_project_definitions(definition, available_project_ids, catalog, result)

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


static func _validate_project_definitions(
		definition: MarketingScenarioDefinition,
		available_project_ids: Dictionary[StringName, bool],
		catalog: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	var defined_project_ids: Dictionary[StringName, bool] = {}
	for project_definition: ProjectDefinition in definition.project_definitions:
		if project_definition == null:
			result.add_error("A Project definition is missing.")
			continue
		if not StableIdentifier.is_valid(project_definition.stable_id):
			result.add_error("Project definition identifier %s is invalid." % project_definition.stable_id)
			continue
		if defined_project_ids.has(project_definition.stable_id):
			result.add_error("Project definition identifier %s is duplicated." % project_definition.stable_id)
		defined_project_ids[project_definition.stable_id] = true
		if not available_project_ids.has(project_definition.stable_id):
			result.add_error(
				"Project definition %s is not an available Project." % project_definition.stable_id
			)
		if project_definition.specification_reference != "docs/marketing/marketing-scenario.md":
			result.add_error(
				"Project %s specification reference is invalid." % project_definition.stable_id
			)
		if project_definition.schema_version != GameStateValidator.CURRENT_SCHEMA_VERSION:
			result.add_error(
				"Project %s schema version %d is incompatible with schema version %d."
				% [
					project_definition.stable_id,
					project_definition.schema_version,
					GameStateValidator.CURRENT_SCHEMA_VERSION,
				]
			)
		if project_definition.start_cost_musd < 0:
			result.add_error("Project %s start cost must not be negative." % project_definition.stable_id)
		if project_definition.duration_month_steps < 1:
			result.add_error("Project %s duration must be at least one Month Step." % project_definition.stable_id)
		if project_definition.reserved_project_teams < 0:
			result.add_error(
				"Project %s reserved project teams must not be negative." % project_definition.stable_id
			)
		if project_definition.reserved_compute_unit_months < 0:
			result.add_error(
				"Project %s reserved Compute Capacity must not be negative." % project_definition.stable_id
			)
		for prerequisite_id: StringName in project_definition.prerequisite_project_ids:
			if not StableIdentifier.is_valid(prerequisite_id):
				result.add_error(
					"Project %s prerequisite identifier %s is invalid."
					% [project_definition.stable_id, prerequisite_id]
				)
		var payload_keys: Dictionary[StringName, bool] = {}
		for payload_key: StringName in project_definition.required_payload_keys:
			if not StableIdentifier.is_valid_entity_type(payload_key):
				result.add_error(
					"Project %s payload key %s is invalid." % [project_definition.stable_id, payload_key]
				)
			if payload_keys.has(payload_key):
				result.add_error(
					"Project %s payload key %s is duplicated." % [project_definition.stable_id, payload_key]
				)
			payload_keys[payload_key] = true
		if not payload_keys.has(ProjectDefinition.PAYLOAD_PROJECT_ID):
			result.add_error(
				"Project %s must require payload key project_id." % project_definition.stable_id
			)
		_validate_completion_effect(project_definition, catalog, result)
	if defined_project_ids.size() != available_project_ids.size():
		result.add_error("Each available Project must have exactly one Project definition.")
	for available_project_id: StringName in available_project_ids.keys():
		if not defined_project_ids.has(available_project_id):
			result.add_error("Available Project %s has no Project definition." % available_project_id)
	_validate_marketing_project_values(definition, result)


static func _validate_completion_effect(
		project_definition: ProjectDefinition,
		catalog: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	match project_definition.completion_effect_id:
		ProjectDefinition.EFFECT_RESEARCH_MODEL:
			if project_definition.completed_model_id != &"model.player.research_output":
				result.add_error(
					"Research Project completed Model identifier is invalid."
				)
			if project_definition.completed_model_coding_evaluation_points != 84:
				result.add_error("Research Project coding evaluation is invalid.")
			if project_definition.completed_model_reasoning_evaluation_points != 79:
				result.add_error("Research Project reasoning evaluation is invalid.")
			if project_definition.completed_model_efficiency_evaluation_points != 80:
				result.add_error("Research Project efficiency evaluation is invalid.")
			if project_definition.completed_model_inference_compute_unit_months_per_contract != 2:
				result.add_error("Research Project inference Compute Capacity is invalid.")
		ProjectDefinition.EFFECT_BURST_COMPUTE:
			if project_definition.completed_contract_id != &"contract.compute.burst":
				result.add_error("Scale Project completed contract identifier is invalid.")
			if not catalog.has(project_definition.completed_contract_id):
				result.add_error(
					"Scale Project completed contract %s does not exist in the content reference catalog."
					% project_definition.completed_contract_id
				)
			if project_definition.completed_contract_compute_unit_months != 60:
				result.add_error("Scale Project Compute Capacity addition is invalid.")
		ProjectDefinition.EFFECT_CODING_AGENT:
			if project_definition.completed_application_id != &"application.player.coding_agent":
				result.add_error("Coding Agent Project completed Application identifier is invalid.")
			if not catalog.has(project_definition.completed_application_id):
				result.add_error(
					"Coding Agent Project completed Application %s does not exist in the content reference catalog."
					% project_definition.completed_application_id
				)
			if project_definition.completed_application_price_musd_per_contract_month != 1:
				result.add_error("Coding Agent Project price is invalid.")
		_:
			result.add_error(
				"Project %s completion effect identifier %s is invalid."
				% [project_definition.stable_id, project_definition.completion_effect_id]
			)


static func _validate_marketing_project_values(
		definition: MarketingScenarioDefinition,
		result: GameStateValidationResult
	) -> void:
	for project_definition: ProjectDefinition in definition.project_definitions:
		if project_definition == null:
			continue
		match project_definition.stable_id:
			&"project.research.frontier_model":
				_expect_project_numbers(
					project_definition,
					65,
					3,
					1,
					30,
					ProjectDefinition.EFFECT_RESEARCH_MODEL,
					result
				)
			&"project.scale.burst_compute":
				_expect_project_numbers(
					project_definition,
					30,
					1,
					1,
					0,
					ProjectDefinition.EFFECT_BURST_COMPUTE,
					result
				)
			&"project.application.coding_agent":
				_expect_project_numbers(
					project_definition,
					40,
					2,
					1,
					10,
					ProjectDefinition.EFFECT_CODING_AGENT,
					result
				)


static func _expect_project_numbers(
		project_definition: ProjectDefinition,
		start_cost_musd: int,
		duration_month_steps: int,
		reserved_project_teams: int,
		reserved_compute_unit_months: int,
		completion_effect_id: StringName,
		result: GameStateValidationResult
	) -> void:
	if project_definition.start_cost_musd != start_cost_musd:
		result.add_error(
			"Project %s start cost must be %d MUSD." % [project_definition.stable_id, start_cost_musd]
		)
	if project_definition.duration_month_steps != duration_month_steps:
		result.add_error(
			"Project %s duration must be %d Month Steps."
			% [project_definition.stable_id, duration_month_steps]
		)
	if project_definition.reserved_project_teams != reserved_project_teams:
		result.add_error(
			"Project %s must reserve %d project teams."
			% [project_definition.stable_id, reserved_project_teams]
		)
	if project_definition.reserved_compute_unit_months != reserved_compute_unit_months:
		result.add_error(
			"Project %s must reserve %d compute-unit-months."
			% [project_definition.stable_id, reserved_compute_unit_months]
		)
	if project_definition.completion_effect_id != completion_effect_id:
		result.add_error(
			"Project %s completion effect identifier is invalid." % project_definition.stable_id
		)
	if not project_definition.prerequisite_project_ids.is_empty():
		result.add_error("Project %s must not declare a prerequisite." % project_definition.stable_id)
