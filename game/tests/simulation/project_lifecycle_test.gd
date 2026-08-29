extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const TEST_SUCCESS: String = "PROJECT_LIFECYCLE_TEST_SUCCESS"
const RESEARCH_ID: StringName = &"project.research.frontier_model"
const SCALE_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_ID: StringName = &"project.application.coding_agent"

var _failure_count: int = 0


func _initialize() -> void:
	var definition: MarketingScenarioDefinition = MarketingScenarioFactory.load_definition(SCENARIO_PATH)
	_expect(definition != null, "The Marketing Scenario definition did not load.")
	if definition == null:
		_finish()
		return
	var state_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	_expect(state_result.succeeded(), "The starting Game State was not created.")
	if not state_result.succeeded():
		_finish()
		return
	var construction: SimulationCoreConstructionResult = MarketingScenarioFactory.create_core(
		definition,
		state_result.state
	)
	_expect(
		construction.succeeded(),
		"The Project Simulation Core did not construct:\n%s" % construction.format_diagnostics()
	)
	if not construction.succeeded():
		_finish()
		return

	_verify_research_payload_required(construction.core, state_result.state)
	_verify_three_project_plan_rejected(construction.core, state_result.state)
	_verify_duplicate_start_rejected(construction.core, state_result.state)
	_verify_cost_exceeds_cash(construction.core, state_result.state)
	_verify_compute_capacity_exceeded(construction.core, state_result.state)
	_verify_hybrid_plan_valid(construction.core, state_result.state)
	_verify_research_lifecycle(construction.core, state_result.state)
	_verify_scale_lifecycle(construction.core, state_result.state)
	_verify_coding_agent_lifecycle(construction.core, state_result.state)
	_verify_hybrid_lifecycle(construction.core, state_result.state)
	_verify_prerequisite_rejection(definition, state_result.state)
	_finish()


func _verify_research_payload_required(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	var command: Command = _make_command(state, 0)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = RESEARCH_ID
	command.payload = payload
	plan.commands.append(command)
	var validation: PlanValidationResult = core.validate_plan(state, plan)
	_expect(not validation.is_valid(), "A Research start Command without payload fields passed validation.")
	_expect(
		_has_plan_diagnostic(validation, &"plan.project_payload_invalid"),
		"Missing Research payload did not report plan.project_payload_invalid."
	)


func _verify_three_project_plan_rejected(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	plan.commands.append(_research_command(state, 0))
	plan.commands.append(_scale_command(state, 1))
	plan.commands.append(_coding_agent_command(state, 2))
	var validation: PlanValidationResult = core.validate_plan(state, plan)
	_expect(not validation.is_valid(), "A three-Project Plan passed validation.")
	_expect(
		_has_plan_diagnostic(validation, &"plan.project_teams_exceeded"),
		"A three-Project Plan did not fail on the project-team limit."
	)


func _verify_duplicate_start_rejected(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	plan.commands.append(_scale_command(state, 0))
	plan.commands.append(_scale_command(state, 1))
	var validation: PlanValidationResult = core.validate_plan(state, plan)
	_expect(not validation.is_valid(), "A duplicate Project start Plan passed validation.")
	_expect(
		_has_plan_diagnostic(validation, &"plan.project_duplicate_start"),
		"A duplicate Project start Plan has the wrong diagnostic."
	)


func _verify_cost_exceeds_cash(core: SimulationCore, state: GameState) -> void:
	var poor_state: GameState = _duplicate_state(state)
	if poor_state == null:
		return
	poor_state.cash_ledger.opening_balance_musd = 10
	var plan: Plan = Plan.new()
	plan.commands.append(_research_command(poor_state, 0))
	var validation: PlanValidationResult = core.validate_plan(poor_state, plan)
	_expect(not validation.is_valid(), "A Project start that exceeds Cash passed validation.")
	_expect(
		_has_plan_diagnostic(validation, &"plan.project_cost_exceeds_cash"),
		"A Project start that exceeds Cash has the wrong diagnostic."
	)


func _verify_compute_capacity_exceeded(core: SimulationCore, state: GameState) -> void:
	var limited_state: GameState = _duplicate_state(state)
	if limited_state == null:
		return
	limited_state.company.compute_capacity_unit_months = 5
	var plan: Plan = Plan.new()
	plan.commands.append(_research_command(limited_state, 0))
	var validation: PlanValidationResult = core.validate_plan(limited_state, plan)
	_expect(not validation.is_valid(), "A Project start that exceeds free Compute Capacity passed validation.")
	_expect(
		_has_plan_diagnostic(validation, &"plan.project_compute_exceeded"),
		"A Project start that exceeds free Compute Capacity has the wrong diagnostic."
	)


func _verify_hybrid_plan_valid(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	plan.commands.append(_research_command(state, 0))
	plan.commands.append(_coding_agent_command(state, 1))
	var validation: PlanValidationResult = core.validate_plan(state, plan)
	_expect(validation.is_valid(), "A valid hybrid Plan failed validation:\n%s" % validation.format_diagnostics())
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "A valid hybrid Plan did not commit.")
	if commit.has_candidate_state():
		_expect(
			commit.candidate_state.company.projects.is_empty(),
			"Plan commitment started a Project."
		)


func _verify_research_lifecycle(core: SimulationCore, state: GameState) -> void:
	var after_month_one: GameState = _advance_plan(core, state, [_research_command(state, 0)], 1)
	if after_month_one == null:
		return
	_expect(after_month_one.company.projects.has(RESEARCH_ID), "The Research Project did not start.")
	var research: ProjectState = after_month_one.company.projects[RESEARCH_ID]
	_expect(research.status_id == ProjectState.STATUS_ACTIVE, "The Research Project is not active after Month Step 1.")
	_expect(research.remaining_month_steps == 2, "The Research Project remaining duration is incorrect after Month Step 1.")
	_expect(research.reserved_project_teams == 1, "The Research Project did not reserve one project team.")
	_expect(research.reserved_compute_unit_months == 30, "The Research Project Compute reservation is incorrect.")
	_expect(
		after_month_one.cash_ledger.calculate_balance_musd() == 85,
		"The Research Project start cost did not post 65 MUSD."
	)
	_expect(
		ProjectCapacity.free_project_teams(after_month_one.company) == 1,
		"The Research Project did not leave one free project team."
	)
	var after_month_three: GameState = _step_months(core, after_month_one, 2)
	if after_month_three == null:
		return
	research = after_month_three.company.projects[RESEARCH_ID]
	_expect(research.status_id == ProjectState.STATUS_COMPLETED, "The Research Project did not complete in Month Step 3.")
	_expect(
		after_month_three.company.models.has(&"model.player.research_output"),
		"The Research Project did not create the completed Model."
	)
	var completed_model: ModelState = after_month_three.company.models[&"model.player.research_output"]
	_expect(completed_model.display_name == "Aperture", "The completed Model display name is incorrect.")
	_expect(completed_model.version_label == "2.0", "The completed Model version label is incorrect.")
	_expect(completed_model.evaluations.coding_evaluation_points == 84, "The completed Model coding evaluation is incorrect.")
	_expect(completed_model.training_compute_unit_months == 30, "The completed Model training Compute Capacity is incorrect.")
	_expect(
		_has_project_completion_notification(after_month_three, RESEARCH_ID),
		"The Research Project completion did not create a Notification."
	)


func _verify_scale_lifecycle(core: SimulationCore, state: GameState) -> void:
	var after_month_one: GameState = _advance_plan(core, state, [_scale_command(state, 0)], 1)
	if after_month_one == null:
		return
	var scale_project: ProjectState = after_month_one.company.projects[SCALE_ID]
	_expect(scale_project.status_id == ProjectState.STATUS_COMPLETED, "The Scale Project did not complete in its start Month Step.")
	_expect(
		after_month_one.company.contracts.has(&"contract.compute.burst"),
		"The Scale Project did not create the burst compute contract."
	)
	_expect(
		after_month_one.company.compute_capacity_unit_months == 130,
		"The Scale Project did not add 60 compute-unit-months."
	)
	_expect(
		after_month_one.cash_ledger.calculate_balance_musd() == 120,
		"The Scale Project start cost did not post 30 MUSD."
	)
	_expect(
		ProjectCapacity.free_project_teams(after_month_one.company) == 2,
		"The completed Scale Project still reserves a project team."
	)


func _verify_coding_agent_lifecycle(core: SimulationCore, state: GameState) -> void:
	var after_month_one: GameState = _advance_plan(core, state, [_coding_agent_command(state, 0)], 1)
	if after_month_one == null:
		return
	var coding_agent: ProjectState = after_month_one.company.projects[CODING_AGENT_ID]
	_expect(coding_agent.status_id == ProjectState.STATUS_ACTIVE, "The Coding Agent Project is not active after Month Step 1.")
	_expect(coding_agent.remaining_month_steps == 1, "The Coding Agent Project remaining duration is incorrect after Month Step 1.")
	var after_month_two: GameState = _step_months(core, after_month_one, 1)
	if after_month_two == null:
		return
	coding_agent = after_month_two.company.projects[CODING_AGENT_ID]
	_expect(coding_agent.status_id == ProjectState.STATUS_COMPLETED, "The Coding Agent Project did not complete in Month Step 2.")
	_expect(
		after_month_two.company.applications.has(&"application.player.coding_agent"),
		"The Coding Agent Project did not create the Coding Agent."
	)
	var application: ApplicationState = after_month_two.company.applications[&"application.player.coding_agent"]
	_expect(
		application.supporting_model_id == &"model.player.starting",
		"The Coding Agent does not reference the start-command Model."
	)
	_expect(application.price_musd_per_contract_month == 1, "The Coding Agent price is incorrect.")
	_expect(
		after_month_two.cash_ledger.calculate_balance_musd() == 110,
		"The Coding Agent Project start cost did not post 40 MUSD."
	)


func _verify_hybrid_lifecycle(core: SimulationCore, state: GameState) -> void:
	var ended: GameState = _advance_plan(
		core,
		state,
		[_research_command(state, 0), _coding_agent_command(state, 1)],
		3
	)
	if ended == null:
		return
	_expect(
		ended.company.projects[RESEARCH_ID].status_id == ProjectState.STATUS_COMPLETED,
		"The hybrid Research Project did not complete."
	)
	_expect(
		ended.company.projects[CODING_AGENT_ID].status_id == ProjectState.STATUS_COMPLETED,
		"The hybrid Coding Agent Project did not complete."
	)
	_expect(
		ended.company.applications[&"application.player.coding_agent"].supporting_model_id
		== &"model.player.starting",
		"The hybrid Coding Agent replaced its supporting Model."
	)
	_expect(
		ended.company.models.has(&"model.player.research_output"),
		"The hybrid Research Project did not create its Model."
	)
	_expect(
		ended.cash_ledger.calculate_balance_musd() == 45,
		"The hybrid Project start costs did not post 105 MUSD."
	)


func _verify_prerequisite_rejection(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var gated: ProjectDefinition = ProjectDefinition.new()
	gated.stable_id = &"project.test.gated"
	gated.specification_reference = "docs/marketing/marketing-scenario.md"
	gated.schema_version = GameStateValidator.CURRENT_SCHEMA_VERSION
	gated.start_cost_musd = 1
	gated.duration_month_steps = 1
	gated.reserved_project_teams = 1
	gated.reserved_compute_unit_months = 0
	gated.prerequisite_project_ids = [RESEARCH_ID]
	gated.required_payload_keys = [ProjectDefinition.PAYLOAD_PROJECT_ID]
	gated.completion_effect_id = ProjectDefinition.EFFECT_BURST_COMPUTE
	gated.completed_contract_id = &"contract.compute.burst"
	gated.completed_contract_compute_unit_months = 0
	var registry: SimulationContentRegistry = definition.build_content_registry()
	_expect(registry.register_content(&"project.test.gated"), "The test registry rejected the gated Project identifier.")
	_expect(registry.register_project_definition(gated), "The test registry rejected the gated Project definition.")
	var construction: SimulationCoreConstructionResult = SimulationCore.create(
		TimeModelRuleFactory.create_registry(),
		registry,
		CanonicalSimulationStatePaths.create_registry(),
		TimeModelEventFactory.create_registry(),
		definition.rule_graph_id,
		definition.rule_graph_version,
		state
	)
	_expect(construction.succeeded(), "The prerequisite test Simulation Core did not construct.")
	if not construction.succeeded():
		return
	var plan: Plan = Plan.new()
	var command: Command = _make_command(state, 0)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = &"project.test.gated"
	command.payload = payload
	plan.commands.append(command)
	var validation: PlanValidationResult = construction.core.validate_plan(state, plan)
	_expect(not validation.is_valid(), "A Project with an unmet prerequisite passed validation.")
	_expect(
		_has_plan_diagnostic(validation, &"plan.project_prerequisite_missing"),
		"An unmet Project prerequisite has the wrong diagnostic."
	)


func _advance_plan(
		core: SimulationCore,
		state: GameState,
		commands: Array[Command],
		month_count: int
	) -> GameState:
	var plan: Plan = Plan.new()
	plan.commands.assign(commands)
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The Project Plan did not commit.")
	if not commit.has_candidate_state():
		return null
	return _step_months(core, commit.candidate_state, month_count)


func _step_months(core: SimulationCore, state: GameState, month_count: int) -> GameState:
	var current: GameState = state
	for _month_index: int in range(month_count):
		var result: SimulationOperationResult = core.step_month(current)
		_expect(
			result.outcome == SimulationOperationOutcome.Type.COMPLETED
			or result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
			"A Project Month Step did not complete."
		)
		if not result.has_candidate_state():
			return null
		current = result.candidate_state
	return current


func _research_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = RESEARCH_ID
	payload[&"model_display_name"] = "Aperture"
	payload[&"model_version_label"] = "2.0"
	payload[&"release_strategy_id"] = &"release_strategy.commercial_api"
	command.payload = payload
	return command


func _scale_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = SCALE_ID
	command.payload = payload
	return command


func _coding_agent_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CODING_AGENT_ID
	payload[&"supporting_model_id"] = &"model.player.starting"
	command.payload = payload
	return command


func _make_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	return command


func _has_project_completion_notification(state: GameState, project_id: StringName) -> bool:
	for notification: NotificationState in state.notifications:
		if notification == null:
			continue
		if (
			notification.notification_type_id == NotificationState.TYPE_PROJECT_COMPLETED
			and notification.source_entity_id == project_id
		):
			return true
	return false


func _duplicate_state(state: GameState) -> GameState:
	var duplicated_resource: Resource = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if duplicated_resource is GameState:
		return duplicated_resource
	_expect(false, "The test could not deep-copy Game State.")
	return null


func _has_plan_diagnostic(result: PlanValidationResult, code: StringName) -> bool:
	for diagnostic: SimulationDiagnostic in result.diagnostics:
		if diagnostic.code == code:
			return true
	return false


func _finish() -> void:
	if _failure_count > 0:
		printerr("PROJECT_LIFECYCLE_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=11" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
