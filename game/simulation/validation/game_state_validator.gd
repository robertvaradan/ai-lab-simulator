class_name GameStateValidator
extends RefCounted

const CURRENT_SCHEMA_VERSION: int = 2


static func validate(
		state: GameState,
		expected_scenario_id: StringName,
		expected_content_version: int,
		expected_rule_graph_id: StringName,
		expected_rule_graph_version: int,
		known_content_ids: Dictionary[StringName, bool]
	) -> GameStateValidationResult:
	var result: GameStateValidationResult = GameStateValidationResult.new()
	if state == null:
		result.add_error("Game State is missing.")
		return result
	if state.schema_version != CURRENT_SCHEMA_VERSION:
		result.add_error(
			"Game State schema version %d is incompatible with schema version %d."
			% [state.schema_version, CURRENT_SCHEMA_VERSION]
		)
	if state.content_version != expected_content_version:
		result.add_error(
			"Game State content version %d does not equal expected content version %d."
			% [state.content_version, expected_content_version]
		)
	if state.rule_graph_id != expected_rule_graph_id:
		result.add_error(
			"Game State Rule Graph identifier %s does not equal expected identifier %s."
			% [state.rule_graph_id, expected_rule_graph_id]
		)
	if state.rule_graph_version != expected_rule_graph_version:
		result.add_error(
			"Game State Rule Graph version %d does not equal expected version %d."
			% [state.rule_graph_version, expected_rule_graph_version]
		)
	if state.scenario_id != expected_scenario_id:
		result.add_error(
			"Game State Scenario identifier %s does not equal expected identifier %s."
			% [state.scenario_id, expected_scenario_id]
		)
	_validate_identifier(state.scenario_id, "Game State Scenario identifier", result)
	_validate_identifier(state.rule_graph_id, "Game State Rule Graph identifier", result)
	if known_content_ids.is_empty():
		result.add_error("The content reference catalog is empty.")
	_validate_calendar(state.calendar, known_content_ids, result)
	_validate_company(state.company, known_content_ids, result)
	_validate_world(state.world, known_content_ids, result)
	_validate_cash_ledger(state.cash_ledger, result)
	_validate_pending_command_batch(state.pending_command_batch, known_content_ids, result)
	_validate_attention_events(state.attention_events, known_content_ids, result)
	_validate_notifications(state.notifications, known_content_ids, result)
	_validate_random_generator(state.random_generator_state, result)
	_validate_runtime_id_counters(state.runtime_id_counters, result)
	_validate_plan_commitment_state(state, result)
	return result


static func _validate_calendar(
		calendar: CalendarState,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	if calendar == null:
		result.add_error("Calendar State is missing.")
		return
	if calendar.current_month_step_index < 0:
		result.add_error("The current Month Step index must not be negative.")
	if calendar.current_quarter_index < 1:
		result.add_error("The current quarter index must be greater than zero.")
	_validate_content_reference(calendar.phase_id, "Calendar phase identifier", known_content_ids, result)


static func _validate_company(
		company: CompanyState,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	if company == null:
		result.add_error("Company State is missing.")
		return
	_validate_nonnegative(company.staff_person_count, "Company staff person count", result)
	_validate_nonnegative(company.project_team_count, "Company project team count", result)
	_validate_nonnegative(company.compute_capacity_unit_months, "Company Compute Capacity", result)
	_validate_nonnegative(
		company.fixed_operating_cost_musd_per_month_step,
		"Company fixed operating cost",
		result
	)
	_validate_evaluation(company.public_trust_points, "Company Public Trust", result)
	_validate_evaluation(company.government_trust_points, "Company Government Trust", result)

	var site_ids: Array[StringName] = []
	site_ids.assign(company.sites.keys())
	site_ids.sort()
	for site_id: StringName in site_ids:
		var site: SiteState = company.sites[site_id]
		if site == null:
			result.add_error("Site %s is missing its state." % site_id)
			continue
		_validate_dictionary_identifier(site_id, site.stable_id, "Site", result)
		var plot_ids: Array[StringName] = []
		plot_ids.assign(site.site_plots.keys())
		plot_ids.sort()
		for plot_id: StringName in plot_ids:
			var plot: SitePlotState = site.site_plots[plot_id]
			if plot == null:
				result.add_error("Site Plot %s is missing its state." % plot_id)
				continue
			_validate_dictionary_identifier(plot_id, plot.stable_id, "Site Plot", result)
			_validate_content_reference(
				plot.state_id,
				"Site Plot %s state identifier" % plot_id,
				known_content_ids,
				result
			)

	var project_ids: Array[StringName] = []
	project_ids.assign(company.projects.keys())
	project_ids.sort()
	for project_id: StringName in project_ids:
		var project: ProjectState = company.projects[project_id]
		if project == null:
			result.add_error("Project %s is missing its state." % project_id)
			continue
		_validate_dictionary_identifier(project_id, project.stable_id, "Project", result)
		_validate_content_reference(
			project.content_definition_id,
			"Project %s content identifier" % project_id,
			known_content_ids,
			result
		)
		_validate_content_reference(
			project.status_id,
			"Project %s status identifier" % project_id,
			known_content_ids,
			result
		)
		_validate_nonnegative(
			project.remaining_month_steps,
			"Project %s remaining Month Steps" % project_id,
			result
		)
		_validate_nonnegative(
			project.reserved_project_teams,
			"Project %s reserved project teams" % project_id,
			result
		)
		_validate_nonnegative(
			project.reserved_compute_unit_months,
			"Project %s reserved Compute Capacity" % project_id,
			result
		)
		if project.started_month_step_index < 1:
			result.add_error("Project %s start Month Step index is invalid." % project_id)
		if project.status_id == ProjectState.STATUS_COMPLETED:
			if project.completed_month_step_index < project.started_month_step_index:
				result.add_error("Project %s completion Month Step index is invalid." % project_id)
			if project.remaining_month_steps != 0:
				result.add_error("Completed Project %s still has remaining Month Steps." % project_id)
			if project.reserved_project_teams != 0 or project.reserved_compute_unit_months != 0:
				result.add_error("Completed Project %s still holds a reservation." % project_id)
		elif project.status_id == ProjectState.STATUS_ACTIVE:
			if project.completed_month_step_index != 0:
				result.add_error("Active Project %s has a completion Month Step index." % project_id)
			if project.remaining_month_steps < 1:
				result.add_error("Active Project %s has no remaining Month Steps." % project_id)
		_validate_payload_keys(
			project.start_payload,
			"Project %s start payload" % project_id,
			result
		)

	if ProjectCapacity.reserved_project_teams(company.projects) > company.project_team_count:
		result.add_error("Active Projects reserve more project teams than the Company has.")
	if ProjectCapacity.reserved_compute_unit_months(company.projects) > company.compute_capacity_unit_months:
		result.add_error("Active Projects reserve more Compute Capacity than the Company has.")

	var model_ids: Array[StringName] = []
	model_ids.assign(company.models.keys())
	model_ids.sort()
	for model_id: StringName in model_ids:
		_validate_model_entity(
			model_id,
			company.models[model_id],
			"Model",
			known_content_ids,
			result
		)

	var application_ids: Array[StringName] = []
	application_ids.assign(company.applications.keys())
	application_ids.sort()
	for application_id: StringName in application_ids:
		var application: ApplicationState = company.applications[application_id]
		if application == null:
			result.add_error("Application %s is missing its state." % application_id)
			continue
		_validate_dictionary_identifier(application_id, application.stable_id, "Application", result)
		_validate_content_reference(
			application.content_definition_id,
			"Application %s content identifier" % application_id,
			known_content_ids,
			result
		)
		_validate_content_reference(
			application.status_id,
			"Application %s status identifier" % application_id,
			known_content_ids,
			result
		)
		if application.supporting_model_id == &"":
			result.add_error("Application %s supporting Model identifier is missing." % application_id)
		else:
			_validate_identifier(
				application.supporting_model_id,
				"Application %s supporting Model identifier" % application_id,
				result
			)
			if not company.models.has(application.supporting_model_id):
				result.add_error(
					"Application %s supporting Model %s does not exist."
					% [application_id, application.supporting_model_id]
				)
		_validate_nonnegative(
			application.price_musd_per_contract_month,
			"Application %s price" % application_id,
			result
		)

	var contract_ids: Array[StringName] = []
	contract_ids.assign(company.contracts.keys())
	contract_ids.sort()
	for contract_id: StringName in contract_ids:
		var contract: ContractState = company.contracts[contract_id]
		if contract == null:
			result.add_error("Contract %s is missing its state." % contract_id)
			continue
		_validate_dictionary_identifier(contract_id, contract.stable_id, "Contract", result)
		_validate_content_reference(
			contract.content_definition_id,
			"Contract %s content identifier" % contract_id,
			known_content_ids,
			result
		)
		_validate_content_reference(
			contract.status_id,
			"Contract %s status identifier" % contract_id,
			known_content_ids,
			result
		)


static func _validate_world(
		world: WorldState,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	if world == null:
		result.add_error("World State is missing.")
		return
	_validate_model_evaluations(world.technical_frontier, "Technical frontier", result)

	var world_model_ids: Array[StringName] = []
	world_model_ids.assign(world.models.keys())
	world_model_ids.sort()
	for world_model_id: StringName in world_model_ids:
		_validate_model_entity(
			world_model_id,
			world.models[world_model_id],
			"World Model",
			known_content_ids,
			result
		)

	var competitor_ids: Array[StringName] = []
	competitor_ids.assign(world.competitors.keys())
	competitor_ids.sort()
	for competitor_id: StringName in competitor_ids:
		var competitor: CompetitorState = world.competitors[competitor_id]
		if competitor == null:
			result.add_error("Competitor %s is missing its state." % competitor_id)
			continue
		_validate_dictionary_identifier(competitor_id, competitor.stable_id, "Competitor", result)
		_validate_content_reference(
			competitor.stage_id,
			"Competitor %s stage identifier" % competitor_id,
			known_content_ids,
			result
		)

	var market_ids: Array[StringName] = []
	market_ids.assign(world.markets.keys())
	market_ids.sort()
	for market_id: StringName in market_ids:
		var market: MarketState = world.markets[market_id]
		if market == null:
			result.add_error("Market %s is missing its state." % market_id)
			continue
		_validate_dictionary_identifier(market_id, market.stable_id, "Market", result)
		_validate_nonnegative(
			market.possible_customer_contract_count,
			"Market %s possible customer contract count" % market_id,
			result
		)
		_validate_evaluation(
			market.customer_expectation_coding_evaluation_points,
			"Market %s customer expectation" % market_id,
			result
		)
		_validate_nonnegative(
			market.reference_price_musd_per_contract_month,
			"Market %s reference price" % market_id,
			result
		)

	var government_ids: Array[StringName] = []
	government_ids.assign(world.active_government_condition_ids.keys())
	government_ids.sort()
	_validate_unique_content_references(
		government_ids,
		"active government condition",
		known_content_ids,
		result
	)


static func _validate_cash_ledger(ledger: CashLedgerState, result: GameStateValidationResult) -> void:
	var ledger_validation: GameStateValidationResult = CashLedgerValidator.validate(ledger)
	result.errors.append_array(ledger_validation.errors)


static func _validate_pending_command_batch(
		batch: PendingCommandBatchState,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	if batch == null:
		return
	_validate_identifier(batch.stable_id, "Pending Command Batch identifier", result)
	if not batch.is_immutable():
		result.add_error("The Pending Command Batch must be immutable after Plan commitment.")
	if batch.is_consumed():
		result.add_error("A consumed Pending Command Batch must not remain in Game State.")
	_validate_commands(batch.commands, "Pending Command Batch", known_content_ids, result)


static func _validate_commands(
		commands: Array[Command],
		owner_name: String,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	var seen_command_ids: Dictionary[StringName, bool] = {}
	for command: Command in commands:
		if command == null:
			result.add_error("%s contains a missing Command." % owner_name)
			continue
		_validate_identifier(command.stable_id, "%s Command identifier" % owner_name, result)
		if seen_command_ids.has(command.stable_id):
			result.add_error("%s Command identifier %s is duplicated." % [owner_name, command.stable_id])
		seen_command_ids[command.stable_id] = true
		if not command.is_immutable():
			result.add_error("%s Command %s must be immutable." % [owner_name, command.stable_id])
		_validate_content_reference(
			command.command_type_id,
			"%s Command type identifier" % owner_name,
			known_content_ids,
			result
		)
		if not String(command.command_type_id).begins_with("command."):
			result.add_error(
				"%s Command type identifier %s is not a Command type."
				% [owner_name, command.command_type_id]
			)


static func _validate_attention_events(
		events: Array[AttentionEventState],
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	var seen_event_ids: Dictionary[StringName, bool] = {}
	for event: AttentionEventState in events:
		if event == null:
			result.add_error("Attention Events contain a missing event.")
			continue
		_validate_identifier(event.stable_id, "Attention Event identifier", result)
		if seen_event_ids.has(event.stable_id):
			result.add_error("Attention Event identifier %s is duplicated." % event.stable_id)
		seen_event_ids[event.stable_id] = true
		_validate_content_reference(
			event.event_type_id,
			"Attention Event %s type identifier" % event.stable_id,
			known_content_ids,
			result
		)


static func _validate_notifications(
		notifications: Array[NotificationState],
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	var seen_notification_ids: Dictionary[StringName, bool] = {}
	for notification: NotificationState in notifications:
		if notification == null:
			result.add_error("Notifications contain a missing Notification.")
			continue
		_validate_identifier(notification.stable_id, "Notification identifier", result)
		if seen_notification_ids.has(notification.stable_id):
			result.add_error("Notification identifier %s is duplicated." % notification.stable_id)
		seen_notification_ids[notification.stable_id] = true
		_validate_content_reference(
			notification.notification_type_id,
			"Notification %s type identifier" % notification.stable_id,
			known_content_ids,
			result
		)
		if notification.source_entity_id != &"":
			_validate_identifier(
				notification.source_entity_id,
				"Notification %s source entity identifier" % notification.stable_id,
				result
			)


static func _validate_random_generator(
		random_generator: RandomGeneratorState,
		result: GameStateValidationResult
	) -> void:
	if random_generator == null:
		return
	if random_generator.seed == -1:
		result.add_error("The random generator seed is missing.")
	if random_generator.state == -1:
		result.add_error("The random generator state is missing.")


static func _validate_runtime_id_counters(
		counters: RuntimeIdCountersState,
		result: GameStateValidationResult
	) -> void:
	if counters == null:
		result.add_error("Runtime identifier counters are missing.")
		return
	if counters.next_sequence_by_entity_type.is_empty():
		result.add_error("Runtime identifier counters are empty.")
	var entity_types: Array[StringName] = []
	entity_types.assign(counters.next_sequence_by_entity_type.keys())
	entity_types.sort()
	for entity_type: StringName in entity_types:
		if not StableIdentifier.is_valid_entity_type(entity_type):
			result.add_error("Runtime entity type %s is invalid." % entity_type)
		if counters.next_sequence_by_entity_type[entity_type] < 1:
			result.add_error("Runtime entity type %s has an invalid next sequence." % entity_type)


static func _validate_plan_commitment_state(
		state: GameState,
		result: GameStateValidationResult
	) -> void:
	if state.runtime_id_counters == null:
		return
	var counters: Dictionary[StringName, int] = (
		state.runtime_id_counters.next_sequence_by_entity_type
	)
	for required_entity_type: StringName in [&"command", &"command_batch"]:
		if not counters.has(required_entity_type):
			result.add_error(
				"Runtime identifier counter %s is missing." % required_entity_type
			)
	if state.pending_command_batch == null:
		return
	if not counters.has(&"command") or not counters.has(&"command_batch"):
		return
	var batch_sequence: int = counters[&"command_batch"] - 1
	if batch_sequence < 1:
		result.add_error("The Pending Command Batch was not allocated by its runtime identifier counter.")
	else:
		var expected_batch_id: StringName = StableIdentifier.format_runtime_identifier(
			&"command_batch",
			batch_sequence
		)
		if state.pending_command_batch.stable_id != expected_batch_id:
			result.add_error(
				"Pending Command Batch identifier %s does not equal allocated identifier %s."
				% [state.pending_command_batch.stable_id, expected_batch_id]
			)
	var commands: Array[Command] = state.pending_command_batch.commands
	var first_command_sequence: int = counters[&"command"] - commands.size()
	if first_command_sequence < 1:
		result.add_error("The Pending Command Batch Commands exceed allocated Command identifiers.")
		return
	for command_index: int in range(commands.size()):
		var command: Command = commands[command_index]
		if command == null:
			continue
		var expected_command_id: StringName = StableIdentifier.format_runtime_identifier(
			&"command",
			first_command_sequence + command_index
		)
		if command.stable_id != expected_command_id:
			result.add_error(
				"Pending Command Batch Command at index %d has identifier %s instead of %s."
				% [command_index, command.stable_id, expected_command_id]
			)


static func _validate_model_entity(
		model_id: StringName,
		model: ModelState,
		owner_name: String,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	if model == null:
		result.add_error("%s %s is missing its state." % [owner_name, model_id])
		return
	_validate_dictionary_identifier(model_id, model.stable_id, owner_name, result)
	if model.display_name.is_empty():
		result.add_error("%s %s display name is missing." % [owner_name, model_id])
	if model.version_label.is_empty():
		result.add_error("%s %s version label is missing." % [owner_name, model_id])
	_validate_content_reference(
		model.release_state_id,
		"%s %s release-state identifier" % [owner_name, model_id],
		known_content_ids,
		result
	)
	_validate_content_reference(
		model.release_strategy_id,
		"%s %s Release Strategy identifier" % [owner_name, model_id],
		known_content_ids,
		result
	)
	_validate_model_evaluations(model.evaluations, "%s %s" % [owner_name, model_id], result)
	_validate_nonnegative(
		model.training_compute_unit_months,
		"%s %s training Compute Capacity" % [owner_name, model_id],
		result
	)
	_validate_nonnegative(
		model.inference_compute_unit_months_per_contract,
		"%s %s inference Compute Capacity" % [owner_name, model_id],
		result
	)


static func _validate_model_evaluations(
		evaluations: ModelEvaluationState,
		owner_name: String,
		result: GameStateValidationResult
	) -> void:
	if evaluations == null:
		result.add_error("%s evaluations are missing." % owner_name)
		return
	_validate_evaluation(evaluations.coding_evaluation_points, "%s coding evaluation" % owner_name, result)
	_validate_evaluation(
		evaluations.reasoning_evaluation_points,
		"%s reasoning evaluation" % owner_name,
		result
	)
	_validate_evaluation(
		evaluations.efficiency_evaluation_points,
		"%s efficiency evaluation" % owner_name,
		result
	)


static func _validate_evaluation(value: int, field_name: String, result: GameStateValidationResult) -> void:
	if value < 0 or value > 100:
		result.add_error("%s must be from 0 through 100." % field_name)


static func _validate_nonnegative(value: int, field_name: String, result: GameStateValidationResult) -> void:
	if value < 0:
		result.add_error("%s must not be negative." % field_name)


static func _validate_dictionary_identifier(
		dictionary_id: StringName,
		state_id: StringName,
		entity_name: String,
		result: GameStateValidationResult
	) -> void:
	_validate_identifier(dictionary_id, "%s dictionary identifier" % entity_name, result)
	_validate_identifier(state_id, "%s state identifier" % entity_name, result)
	if dictionary_id != state_id:
		result.add_error(
			"%s dictionary identifier %s does not equal state identifier %s."
			% [entity_name, dictionary_id, state_id]
		)


static func _validate_identifier(
		identifier: StringName,
		field_name: String,
		result: GameStateValidationResult
	) -> void:
	if not StableIdentifier.is_valid(identifier):
		result.add_error("%s %s is invalid." % [field_name, identifier])


static func _validate_content_reference(
		identifier: StringName,
		field_name: String,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	_validate_identifier(identifier, field_name, result)
	if not known_content_ids.has(identifier):
		result.add_error("%s %s does not exist in the content reference catalog." % [field_name, identifier])


static func _validate_payload_keys(
		payload: Dictionary[StringName, Variant],
		owner_name: String,
		result: GameStateValidationResult
	) -> void:
	var keys: Array[StringName] = []
	keys.assign(payload.keys())
	keys.sort()
	for key: StringName in keys:
		if not StableIdentifier.is_valid_entity_type(key):
			result.add_error("%s key %s is invalid." % [owner_name, key])


static func _validate_unique_content_references(
		identifiers: Array[StringName],
		entity_name: String,
		known_content_ids: Dictionary[StringName, bool],
		result: GameStateValidationResult
	) -> void:
	var seen_ids: Dictionary[StringName, bool] = {}
	for identifier: StringName in identifiers:
		_validate_content_reference(identifier, "%s identifier" % entity_name, known_content_ids, result)
		if seen_ids.has(identifier):
			result.add_error("%s identifier %s is duplicated." % [entity_name, identifier])
		seen_ids[identifier] = true
