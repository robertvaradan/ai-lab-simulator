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
	_validate_competitor_definitions(definition, catalog, result)
	_validate_contract_definitions(definition, catalog, result)

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


static func _validate_competitor_definitions(
		definition: MarketingScenarioDefinition,
		catalog: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	if definition.competitor_definitions.size() != 1:
		result.add_error("The Marketing Scenario must contain exactly one Competitor definition.")
	var defined_competitor_ids: Dictionary[StringName, bool] = {}
	for competitor_definition: CompetitorDefinition in definition.competitor_definitions:
		if competitor_definition == null:
			result.add_error("A Competitor definition is missing.")
			continue
		if not StableIdentifier.is_valid(competitor_definition.stable_id):
			result.add_error(
				"Competitor definition identifier %s is invalid." % competitor_definition.stable_id
			)
			continue
		if defined_competitor_ids.has(competitor_definition.stable_id):
			result.add_error(
				"Competitor definition identifier %s is duplicated." % competitor_definition.stable_id
			)
		defined_competitor_ids[competitor_definition.stable_id] = true
		if competitor_definition.stable_id != &"competitor.northstar":
			result.add_error("The Marketing Scenario Competitor identifier must be competitor.northstar.")
		if not catalog.has(competitor_definition.stable_id):
			result.add_error(
				"Competitor identifier %s does not exist in the content reference catalog."
				% competitor_definition.stable_id
			)
		if competitor_definition.specification_reference != "docs/marketing/marketing-scenario.md":
			result.add_error(
				"Competitor %s specification reference is invalid." % competitor_definition.stable_id
			)
		if competitor_definition.schema_version != GameStateValidator.CURRENT_SCHEMA_VERSION:
			result.add_error(
				"Competitor %s schema version %d is incompatible with schema version %d."
				% [
					competitor_definition.stable_id,
					competitor_definition.schema_version,
					GameStateValidator.CURRENT_SCHEMA_VERSION,
				]
			)
		if competitor_definition.announced_stage_id != &"competitor_stage.northstar.announced":
			result.add_error("Northstar announced Competitor Stage identifier is invalid.")
		if competitor_definition.released_stage_id != &"competitor_stage.northstar.flagship_released":
			result.add_error("Northstar released Competitor Stage identifier is invalid.")
		_validate_content_in_catalog(
			competitor_definition.announced_stage_id,
			"Northstar announced Competitor Stage",
			catalog,
			result
		)
		_validate_content_in_catalog(
			competitor_definition.released_stage_id,
			"Northstar released Competitor Stage",
			catalog,
			result
		)
		if competitor_definition.release_month_step_index != 3:
			result.add_error("Northstar release Month Step must be 3.")
		if competitor_definition.known_release_quarter_index != 1:
			result.add_error("Northstar known release quarter must be 1.")
		if competitor_definition.projected_coding_evaluation_min != 80:
			result.add_error("Northstar projected coding minimum is invalid.")
		if competitor_definition.projected_coding_evaluation_max != 84:
			result.add_error("Northstar projected coding maximum is invalid.")
		if competitor_definition.projected_reasoning_evaluation_min != 76:
			result.add_error("Northstar projected reasoning minimum is invalid.")
		if competitor_definition.projected_reasoning_evaluation_max != 80:
			result.add_error("Northstar projected reasoning maximum is invalid.")
		if competitor_definition.projected_efficiency_evaluation_min != 70:
			result.add_error("Northstar projected efficiency minimum is invalid.")
		if competitor_definition.projected_efficiency_evaluation_max != 74:
			result.add_error("Northstar projected efficiency maximum is invalid.")
		if competitor_definition.actual_coding_evaluation_points != 82:
			result.add_error("Northstar actual coding evaluation is invalid.")
		if competitor_definition.actual_reasoning_evaluation_points != 78:
			result.add_error("Northstar actual reasoning evaluation is invalid.")
		if competitor_definition.actual_efficiency_evaluation_points != 72:
			result.add_error("Northstar actual efficiency evaluation is invalid.")
		_validate_projected_range(
			competitor_definition.projected_coding_evaluation_min,
			competitor_definition.projected_coding_evaluation_max,
			competitor_definition.actual_coding_evaluation_points,
			"coding",
			result
		)
		_validate_projected_range(
			competitor_definition.projected_reasoning_evaluation_min,
			competitor_definition.projected_reasoning_evaluation_max,
			competitor_definition.actual_reasoning_evaluation_points,
			"reasoning",
			result
		)
		_validate_projected_range(
			competitor_definition.projected_efficiency_evaluation_min,
			competitor_definition.projected_efficiency_evaluation_max,
			competitor_definition.actual_efficiency_evaluation_points,
			"efficiency",
			result
		)
		var forecast: CompetitorForecast = competitor_definition.create_forecast()
		if forecast.reveals_exact_result(
			competitor_definition.actual_coding_evaluation_points,
			competitor_definition.actual_reasoning_evaluation_points,
			competitor_definition.actual_efficiency_evaluation_points
		):
			result.add_error("The Northstar projection reveals the exact release result.")
		if competitor_definition.released_model_id != CompetitorDefinition.RELEASED_MODEL_ID:
			result.add_error("Northstar released Model identifier is invalid.")
		if competitor_definition.released_model_display_name != "Northstar Flagship":
			result.add_error("Northstar released Model display name is invalid.")
		if competitor_definition.released_model_version_label != "1.0":
			result.add_error("Northstar released Model version label is invalid.")
		if competitor_definition.released_model_release_strategy_id != &"release_strategy.commercial_api":
			result.add_error("Northstar released Model Release Strategy is invalid.")
		_validate_content_in_catalog(
			competitor_definition.released_model_release_strategy_id,
			"Northstar released Model Release Strategy",
			catalog,
			result
		)
		if competitor_definition.released_model_training_compute_unit_months != 0:
			result.add_error("Northstar released Model training Compute Capacity is invalid.")
		if competitor_definition.released_model_inference_compute_unit_months_per_contract != 0:
			result.add_error("Northstar released Model inference Compute Capacity is invalid.")
		if competitor_definition.customer_expectation_market_id != CompetitorDefinition.CODING_AGENT_MARKET_ID:
			result.add_error("Northstar customer-expectation Market identifier is invalid.")
		if competitor_definition.released_customer_expectation_coding_evaluation_points != 80:
			result.add_error("Northstar released customer expectation is invalid.")
		if competitor_definition.release_event_id != CompetitorDefinition.RELEASE_EVENT_ID:
			result.add_error("Northstar release event identifier is invalid.")


static func _validate_contract_definitions(
		definition: MarketingScenarioDefinition,
		catalog: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	if definition.contract_definitions.size() != 2:
		result.add_error("The Marketing Scenario must contain exactly two compute-contract definitions.")
	var defined_contract_ids: Dictionary[StringName, bool] = {}
	for contract_definition: ContractDefinition in definition.contract_definitions:
		if contract_definition == null:
			result.add_error("A contract definition is missing.")
			continue
		if not StableIdentifier.is_valid(contract_definition.stable_id):
			result.add_error(
				"Contract definition identifier %s is invalid." % contract_definition.stable_id
			)
			continue
		if defined_contract_ids.has(contract_definition.stable_id):
			result.add_error(
				"Contract definition identifier %s is duplicated." % contract_definition.stable_id
			)
		defined_contract_ids[contract_definition.stable_id] = true
		if not catalog.has(contract_definition.stable_id):
			result.add_error(
				"Contract identifier %s does not exist in the content reference catalog."
				% contract_definition.stable_id
			)
		if contract_definition.specification_reference != "docs/marketing/marketing-scenario.md":
			result.add_error(
				"Contract %s specification reference is invalid." % contract_definition.stable_id
			)
		if contract_definition.schema_version != GameStateValidator.CURRENT_SCHEMA_VERSION:
			result.add_error(
				"Contract %s schema version %d is incompatible with schema version %d."
				% [
					contract_definition.stable_id,
					contract_definition.schema_version,
					GameStateValidator.CURRENT_SCHEMA_VERSION,
				]
			)
		_validate_content_in_catalog(
			contract_definition.ledger_category_id,
			"Contract %s ledger category" % contract_definition.stable_id,
			catalog,
			result
		)
		match contract_definition.stable_id:
			&"contract.compute.standard":
				if contract_definition.monthly_cost_musd != 4:
					result.add_error("The standard compute contract monthly cost must be 4 MUSD.")
				if contract_definition.ledger_category_id != &"cash_category.compute_contract.standard":
					result.add_error("The standard compute contract ledger category is invalid.")
			&"contract.compute.burst":
				if contract_definition.monthly_cost_musd != 8:
					result.add_error("The burst compute contract monthly cost must be 8 MUSD.")
				if contract_definition.ledger_category_id != &"cash_category.compute_contract.burst":
					result.add_error("The burst compute contract ledger category is invalid.")
			_:
				result.add_error(
					"Contract definition %s is not a Marketing Scenario compute contract."
					% contract_definition.stable_id
				)
	if not defined_contract_ids.has(&"contract.compute.standard"):
		result.add_error("The standard compute contract definition is missing.")
	if not defined_contract_ids.has(&"contract.compute.burst"):
		result.add_error("The burst compute contract definition is missing.")
	_validate_content_in_catalog(
		&"cash_category.operating_cost",
		"Operating cost ledger category",
		catalog,
		result
	)
	_validate_content_in_catalog(
		&"cash_category.application.revenue",
		"Application Revenue ledger category",
		catalog,
		result
	)


static func _validate_projected_range(
		range_min: int,
		range_max: int,
		actual_value: int,
		dimension_name: String,
		result: GameStateValidationResult
	) -> void:
	if range_min >= range_max:
		result.add_error("Northstar projected %s range must contain more than one value." % dimension_name)
	if actual_value < range_min or actual_value > range_max:
		result.add_error("Northstar actual %s evaluation is outside the projected range." % dimension_name)


static func _validate_content_in_catalog(
		content_id: StringName,
		owner_name: String,
		catalog: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	if not catalog.has(content_id):
		result.add_error("%s %s does not exist in the content reference catalog." % [owner_name, content_id])
