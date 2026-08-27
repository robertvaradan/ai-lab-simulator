extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const SNAPSHOT_PATH: String = "user://ms1_01_game_state_round_trip.tres"
const INVALID_SNAPSHOT_PATH: String = "user://ms1_01_invalid_game_state.tres"
const TEST_SUCCESS: String = "GAME_STATE_TEST_SUCCESS"

var _failure_count: int = 0


func _initialize() -> void:
	_remove_test_file(SNAPSHOT_PATH)
	_remove_test_file(INVALID_SNAPSHOT_PATH)

	var definition: MarketingScenarioDefinition = MarketingScenarioFactory.load_definition(SCENARIO_PATH)
	_expect(definition != null, "The Marketing Scenario definition did not load.")
	if definition == null:
		_finish()
		return
	_verify_definition(definition)

	var create_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	_expect(create_result.succeeded(), "The Marketing Scenario state was not created:\n%s" % create_result.format_errors())
	if not create_result.succeeded():
		_finish()
		return
	var state: GameState = create_result.state
	_verify_deep_copy(state, definition.starting_game_state)
	_verify_starting_state(state)
	_verify_stable_identifiers(state)

	var content_catalog: Dictionary[StringName, bool] = definition.build_content_reference_catalog()
	var save_result: GameStateSaveResult = GameStateSnapshotStore.save_snapshot(
		state,
		SNAPSHOT_PATH,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		content_catalog
	)
	_expect(save_result.succeeded(), "The Game State snapshot was not saved:\n%s" % save_result.format_errors())
	if save_result.succeeded():
		_verify_snapshot_text()
		_verify_round_trip(definition, state, content_catalog)
	_verify_invalid_snapshot_rejection(definition, state, content_catalog)
	_finish()


func _verify_definition(definition: MarketingScenarioDefinition) -> void:
	_expect(
		definition.schema_version == GameStateValidator.CURRENT_SCHEMA_VERSION,
		"The Scenario schema version is not %d." % GameStateValidator.CURRENT_SCHEMA_VERSION
	)
	_expect(definition.content_version == 1, "The Scenario content version is not 1.")
	_expect(
		definition.stable_id == &"scenario.marketing.first_quarter",
		"The Scenario identifier is incorrect."
	)
	_expect(definition.difficulty_profile_id == &"difficulty.standard", "The difficulty profile is incorrect.")
	_expect(
		definition.specification_reference == "docs/marketing/marketing-scenario.md",
		"The Scenario specification reference is incorrect."
	)
	var expected_project_ids: Array[StringName] = [
		&"project.research.frontier_model",
		&"project.scale.burst_compute",
		&"project.application.coding_agent",
	]
	_expect(definition.available_project_ids == expected_project_ids, "The available Project identifiers are incorrect.")
	var expected_command_type_ids: Array[StringName] = [&"command.project.start"]
	_expect(definition.command_type_ids == expected_command_type_ids, "The Command type identifiers are incorrect.")
	var validation: GameStateValidationResult = MarketingScenarioValidator.validate(definition)
	_expect(validation.is_valid(), "The Marketing Scenario definition is invalid:\n%s" % validation.format_errors())


func _verify_deep_copy(state: GameState, authored_state: GameState) -> void:
	_expect(state != authored_state, "The factory returned the authored Game State instance.")
	_expect(state.company != authored_state.company, "The factory reused the authored Company State instance.")
	_expect(state.world != authored_state.world, "The factory reused the authored World State instance.")
	_expect(state.cash_ledger != authored_state.cash_ledger, "The factory reused the authored Cash Ledger instance.")
	var state_model: ModelState = state.company.models[&"model.player.starting"]
	var authored_model: ModelState = authored_state.company.models[&"model.player.starting"]
	_expect(state_model != authored_model, "The factory reused the authored Model instance.")
	_expect(state_model.evaluations != authored_model.evaluations, "The factory reused authored Model evaluations.")


func _verify_starting_state(state: GameState) -> void:
	_expect(
		state.schema_version == GameStateValidator.CURRENT_SCHEMA_VERSION,
		"The Game State schema version is incorrect."
	)
	_expect(state.content_version == 1, "The Game State content version is incorrect.")
	_expect(
		state.rule_graph_id == &"rule_graph.marketing.first_quarter",
		"The Game State Rule Graph identifier is incorrect."
	)
	_expect(state.rule_graph_version == 1, "The Game State Rule Graph version is incorrect.")
	_expect(state.scenario_id == &"scenario.marketing.first_quarter", "The Game State Scenario identifier is incorrect.")

	_expect(state.calendar.current_month_step_index == 0, "The starting Month Step index is incorrect.")
	_expect(state.calendar.current_quarter_index == 1, "The starting quarter index is incorrect.")
	_expect(state.calendar.phase_id == &"calendar_state.planning", "The Scenario does not start in Planning State.")

	var company: CompanyState = state.company
	_expect(company.staff_person_count == 40, "The starting staff count is incorrect.")
	_expect(company.project_team_count == 2, "The starting project-team count is incorrect.")
	_expect(company.compute_capacity_unit_months == 70, "The starting Compute Capacity is incorrect.")
	_expect(company.fixed_operating_cost_musd_per_month_step == 5, "The fixed operating cost is incorrect.")
	_expect(company.public_trust_points == 55, "The Public Trust value is incorrect.")
	_expect(company.government_trust_points == 50, "The Government Trust value is incorrect.")
	_expect(company.projects.is_empty(), "The starting Company has a Project.")
	_expect(company.applications.is_empty(), "The starting Company has an Application.")

	_expect(company.sites.size() == 1, "The starting Company Site count is incorrect.")
	_expect(company.sites.has(&"site.company.sf_campus"), "The Company Campus is missing.")
	var site: SiteState = company.sites[&"site.company.sf_campus"]
	_expect(site.site_plots.size() == 3, "The Company Campus Site Plot count is incorrect.")
	_expect(
		site.site_plots[&"plot.campus.research"].state_id == &"site_plot_state.compact_lab",
		"The research Site Plot state is incorrect."
	)
	_expect(
		site.site_plots[&"plot.campus.compute_link"].state_id == &"site_plot_state.no_link",
		"The compute-link Site Plot state is incorrect."
	)
	_expect(
		site.site_plots[&"plot.campus.product"].state_id == &"site_plot_state.product_studio",
		"The product Site Plot state is incorrect."
	)

	_expect(company.models.size() == 1, "The starting Model count is incorrect.")
	var model: ModelState = company.models[&"model.player.starting"]
	_expect(model.stable_id == &"model.player.starting", "The starting Model identifier is incorrect.")
	_expect(model.display_name == "Aperture", "The starting Model display name is incorrect.")
	_expect(model.version_label == "1.0", "The starting Model version label is incorrect.")
	_expect(model.release_state_id == &"model_release_state.released", "The starting Model is not released.")
	_expect(model.release_strategy_id == &"release_strategy.commercial_api", "The Release Strategy is incorrect.")
	_expect(model.evaluations.coding_evaluation_points == 72, "The Model coding evaluation is incorrect.")
	_expect(model.evaluations.reasoning_evaluation_points == 70, "The Model reasoning evaluation is incorrect.")
	_expect(model.evaluations.efficiency_evaluation_points == 76, "The Model efficiency evaluation is incorrect.")
	_expect(model.training_compute_unit_months == 90, "The Model training Compute Capacity is incorrect.")
	_expect(
		model.inference_compute_unit_months_per_contract == 2,
		"The Model inference Compute Capacity is incorrect."
	)

	_expect(company.contracts.size() == 1, "The starting compute contract count is incorrect.")
	var contract: ContractState = company.contracts[&"contract.compute.standard"]
	_expect(contract.stable_id == &"contract.compute.standard", "The standard compute contract identifier is incorrect.")
	_expect(
		contract.content_definition_id == &"contract.compute.standard",
		"The standard compute contract content reference is incorrect."
	)
	_expect(contract.status_id == &"contract_state.active", "The standard compute contract is not active.")

	var world: WorldState = state.world
	_expect(world.competitors.size() == 1, "The starting Competitor count is incorrect.")
	var competitor: CompetitorState = world.competitors[&"competitor.northstar"]
	_expect(competitor.stable_id == &"competitor.northstar", "The Competitor identifier is incorrect.")
	_expect(
		competitor.stage_id == &"competitor_stage.northstar.announced",
		"The starting Competitor Stage is incorrect."
	)
	_expect(world.technical_frontier.coding_evaluation_points == 74, "The frontier coding evaluation is incorrect.")
	_expect(world.technical_frontier.reasoning_evaluation_points == 72, "The frontier reasoning evaluation is incorrect.")
	_expect(world.technical_frontier.efficiency_evaluation_points == 74, "The frontier efficiency evaluation is incorrect.")
	_expect(world.markets.size() == 1, "The starting Market count is incorrect.")
	var market: MarketState = world.markets[&"market.coding_agent"]
	_expect(market.possible_customer_contract_count == 12, "The possible customer contract count is incorrect.")
	_expect(
		market.customer_expectation_coding_evaluation_points == 70,
		"The starting customer expectation is incorrect."
	)
	_expect(market.reference_price_musd_per_contract_month == 1, "The reference price is incorrect.")
	_expect(world.active_government_condition_ids.is_empty(), "The starting World has a government condition.")

	_expect(state.cash_ledger.stable_id == &"ledger.cash.company", "The Cash Ledger identifier is incorrect.")
	_expect(state.cash_ledger.opening_balance_musd == 150, "The Cash opening balance is incorrect.")
	_expect(state.cash_ledger.transactions.is_empty(), "The starting Cash Ledger has a transaction.")
	_expect(state.pending_command_batch == null, "The starting state has a Pending Command Batch.")
	_expect(state.attention_events.is_empty(), "The starting state has an Attention Event.")
	_expect(state.notifications.is_empty(), "The starting state has a Notification.")
	_expect(state.random_generator_state == null, "The deterministic Scenario contains random generator state.")

	var expected_counters: Dictionary[StringName, int] = {
		&"application": 1,
		&"command": 1,
		&"command_batch": 1,
		&"contract": 1,
		&"event": 1,
		&"ledger_transaction": 1,
		&"model": 1,
		&"notification": 1,
		&"project": 1,
	}
	_expect(
		state.runtime_id_counters.next_sequence_by_entity_type == expected_counters,
		"The runtime identifier counters are incorrect."
	)


func _verify_stable_identifiers(state: GameState) -> void:
	_expect(StableIdentifier.is_valid(&"model.player.starting"), "A canonical stable identifier was rejected.")
	_expect(not StableIdentifier.is_valid(&"Model Player Starting"), "An invalid stable identifier was accepted.")
	_expect(
		StableIdentifier.format_runtime_identifier(&"model", 7) == &"model.runtime.id_000007",
		"The deterministic runtime identifier is incorrect."
	)
	_expect(
		StableIdentifier.is_valid(StableIdentifier.format_runtime_identifier(&"ledger_transaction", 1)),
		"A formatted ledger transaction identifier is invalid."
	)
	var model: ModelState = state.company.models[&"model.player.starting"]
	var identifier_before_rename: StringName = model.stable_id
	model.display_name = "Keystone"
	model.version_label = "2.0-preview"
	_expect(model.stable_id == identifier_before_rename, "A Model rename changed its stable identifier.")
	model.display_name = "Aperture"
	model.version_label = "1.0"


func _verify_snapshot_text() -> void:
	var snapshot_text: String = FileAccess.get_file_as_string(SNAPSHOT_PATH)
	_expect(not snapshot_text.is_empty(), "The saved Game State snapshot is empty.")
	_expect(not snapshot_text.contains("GameStateEcho"), "The snapshot contains GameStateEcho.")
	_expect(not snapshot_text.contains("listener"), "The snapshot contains a listener reference.")
	_expect(not snapshot_text.contains("active_plan"), "The snapshot contains a draft Plan.")
	_expect(
		not snapshot_text.contains("MarketingScenarioDefinition"),
		"The snapshot contains authored Scenario definitions."
	)


func _verify_round_trip(
		definition: MarketingScenarioDefinition,
		source_state: GameState,
		content_catalog: Dictionary[StringName, bool]
	) -> void:
	var first_load: GameStateLoadResult = GameStateSnapshotStore.load_snapshot(
		SNAPSHOT_PATH,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		content_catalog
	)
	_expect(first_load.succeeded(), "The first snapshot load failed:\n%s" % first_load.format_errors())
	if not first_load.succeeded():
		return
	_verify_starting_state(first_load.state)
	_expect(first_load.state != source_state, "The snapshot load returned the source Game State instance.")
	first_load.state.company.models[&"model.player.starting"].display_name = "Cache Probe"

	var second_load: GameStateLoadResult = GameStateSnapshotStore.load_snapshot(
		SNAPSHOT_PATH,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		content_catalog
	)
	_expect(second_load.succeeded(), "The cache-independent snapshot load failed:\n%s" % second_load.format_errors())
	if second_load.succeeded():
		_expect(second_load.state != first_load.state, "The cache-independent load reused the first Game State instance.")
		_expect(
			second_load.state.company.models[&"model.player.starting"].display_name == "Aperture",
			"The cache-independent load reused a mutated nested Resource."
		)
		_verify_starting_state(second_load.state)


func _verify_invalid_snapshot_rejection(
		definition: MarketingScenarioDefinition,
		valid_state: GameState,
		content_catalog: Dictionary[StringName, bool]
	) -> void:
	var invalid_resource: Resource = valid_state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_expect(invalid_resource is GameState, "The invalid-state test could not duplicate Game State.")
	if not invalid_resource is GameState:
		return
	var invalid_state: GameState = invalid_resource
	invalid_state.schema_version = GameStateValidator.CURRENT_SCHEMA_VERSION + 1
	var invalid_save_result: GameStateSaveResult = GameStateSnapshotStore.save_snapshot(
		invalid_state,
		INVALID_SNAPSHOT_PATH,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		content_catalog
	)
	_expect(not invalid_save_result.succeeded(), "The snapshot store saved an incompatible schema version.")

	var raw_save_error: Error = ResourceSaver.save(invalid_state, INVALID_SNAPSHOT_PATH)
	_expect(raw_save_error == OK, "The invalid-state test fixture could not be saved.")
	if raw_save_error == OK:
		var invalid_load_result: GameStateLoadResult = GameStateSnapshotStore.load_snapshot(
			INVALID_SNAPSHOT_PATH,
			definition.stable_id,
			definition.content_version,
			definition.rule_graph_id,
			definition.rule_graph_version,
			content_catalog
		)
		_expect(not invalid_load_result.succeeded(), "The snapshot loader accepted an incompatible schema version.")
		_expect(invalid_load_result.state == null, "An invalid snapshot exposed a Game State instance.")

	invalid_state.schema_version = GameStateValidator.CURRENT_SCHEMA_VERSION
	invalid_state.company.models[&"model.player.starting"].release_strategy_id = &"release_strategy.missing"
	raw_save_error = ResourceSaver.save(invalid_state, INVALID_SNAPSHOT_PATH)
	_expect(raw_save_error == OK, "The missing-reference test fixture could not be saved.")
	if raw_save_error == OK:
		var missing_reference_result: GameStateLoadResult = GameStateSnapshotStore.load_snapshot(
			INVALID_SNAPSHOT_PATH,
			definition.stable_id,
			definition.content_version,
			definition.rule_graph_id,
			definition.rule_graph_version,
			content_catalog
		)
		_expect(not missing_reference_result.succeeded(), "The snapshot loader accepted a missing content reference.")
		_expect(missing_reference_result.state == null, "A snapshot with a missing reference exposed Game State.")


func _remove_test_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var remove_error: Error = DirAccess.remove_absolute(absolute_path)
	if remove_error != OK:
		_expect(false, "The test file could not be removed: %s" % path)


func _finish() -> void:
	_remove_test_file(SNAPSHOT_PATH)
	_remove_test_file(INVALID_SNAPSHOT_PATH)
	if _failure_count > 0:
		printerr("GAME_STATE_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=1" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
