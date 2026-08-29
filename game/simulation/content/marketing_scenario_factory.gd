class_name MarketingScenarioFactory
extends RefCounted


static func load_definition(path: String) -> MarketingScenarioDefinition:
	var loaded_resource: Resource = ResourceLoader.load(
		path,
		"",
		ResourceLoader.CACHE_MODE_IGNORE_DEEP
	)
	if loaded_resource == null:
		push_error("Marketing Scenario definition could not be loaded: %s" % path)
		return null
	if not loaded_resource is MarketingScenarioDefinition:
		push_error("Resource is not a Marketing Scenario definition: %s" % path)
		return null
	var definition: MarketingScenarioDefinition = loaded_resource
	var validation: GameStateValidationResult = MarketingScenarioValidator.validate(definition)
	if not validation.is_valid():
		push_error("Marketing Scenario definition is invalid:\n%s" % validation.format_errors())
		return null
	return definition


static func create_state(definition: MarketingScenarioDefinition) -> GameStateLoadResult:
	var result: GameStateLoadResult = GameStateLoadResult.new()
	var definition_validation: GameStateValidationResult = MarketingScenarioValidator.validate(definition)
	if not definition_validation.is_valid():
		result.errors.append_array(definition_validation.errors)
		return result
	var duplicated_resource: Resource = definition.starting_game_state.duplicate_deep(
		Resource.DEEP_DUPLICATE_ALL
	)
	if not duplicated_resource is GameState:
		result.add_error("The duplicated Marketing Scenario starting state is not a Game State.")
		return result
	var duplicated_state: GameState = duplicated_resource
	var opening_reports: Array[QuarterlyReportState] = []
	opening_reports.append(
		QuarterlyReportCompiler.compile_opening(
			duplicated_state,
			definition.competitor_definitions
		)
	)
	duplicated_state.quarterly_reports = opening_reports
	var state_validation: GameStateValidationResult = GameStateValidator.validate(
		duplicated_state,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		definition.build_content_reference_catalog()
	)
	if not state_validation.is_valid():
		result.errors.append_array(state_validation.errors)
		return result
	result.state = duplicated_state
	return result


static func create_core(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> SimulationCoreConstructionResult:
	return SimulationCore.create(
		TimeModelRuleFactory.create_registry(),
		definition.build_content_registry(),
		CanonicalSimulationStatePaths.create_registry(),
		TimeModelEventFactory.create_registry(),
		definition.rule_graph_id,
		definition.rule_graph_version,
		state
	)
