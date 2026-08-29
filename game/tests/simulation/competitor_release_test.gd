extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const TEST_SUCCESS: String = "COMPETITOR_RELEASE_TEST_SUCCESS"
const RESEARCH_ID: StringName = &"project.research.frontier_model"
const NORTHSTAR_ID: StringName = &"competitor.northstar"
const FLAGSHIP_MODEL_ID: StringName = CompetitorDefinition.RELEASED_MODEL_ID
const RELEASE_EVENT_ID: StringName = AdvanceCompetitorsRule.EVENT_ID

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
		"The Competitor Simulation Core did not construct:\n%s" % construction.format_diagnostics()
	)
	if not construction.succeeded():
		_finish()
		return

	_verify_forecast_does_not_reveal_actuals(definition)
	_verify_no_release_before_month_three(construction.core, state_result.state)
	_verify_empty_plan_release(construction.core, state_result.state)
	_verify_player_model_does_not_move_frontier(construction.core, state_result.state)
	_verify_replay_matches(construction.core, state_result.state)
	_finish()


func _verify_forecast_does_not_reveal_actuals(definition: MarketingScenarioDefinition) -> void:
	_expect(
		definition.competitor_definitions.size() == 1,
		"The Marketing Scenario does not contain one Competitor definition."
	)
	if definition.competitor_definitions.is_empty():
		return
	var competitor_definition: CompetitorDefinition = definition.competitor_definitions[0]
	var forecast: CompetitorForecast = competitor_definition.create_forecast()
	_expect(forecast.competitor_id == NORTHSTAR_ID, "The Competitor forecast identifier is incorrect.")
	_expect(forecast.known_release_quarter_index == 1, "The known Competitor release quarter is incorrect.")
	_expect(forecast.projected_coding_evaluation_min == 80, "The projected coding minimum is incorrect.")
	_expect(forecast.projected_coding_evaluation_max == 84, "The projected coding maximum is incorrect.")
	_expect(forecast.projected_reasoning_evaluation_min == 76, "The projected reasoning minimum is incorrect.")
	_expect(forecast.projected_reasoning_evaluation_max == 80, "The projected reasoning maximum is incorrect.")
	_expect(forecast.projected_efficiency_evaluation_min == 70, "The projected efficiency minimum is incorrect.")
	_expect(forecast.projected_efficiency_evaluation_max == 74, "The projected efficiency maximum is incorrect.")
	_expect(
		not forecast.reveals_exact_result(
			competitor_definition.actual_coding_evaluation_points,
			competitor_definition.actual_reasoning_evaluation_points,
			competitor_definition.actual_efficiency_evaluation_points
		),
		"The Competitor forecast reveals the exact result."
	)
	for property: Dictionary in forecast.get_property_list():
		if not property.has("name"):
			continue
		var property_name: String = str(property["name"])
		_expect(
			not property_name.begins_with("actual_"),
			"The Competitor forecast exposes actual evaluation property %s." % property_name
		)


func _verify_no_release_before_month_three(core: SimulationCore, state: GameState) -> void:
	var after_month_one: GameState = _advance_empty_plan(core, state, 1)
	if after_month_one == null:
		return
	_expect_unreleased(after_month_one, "Month Step 1")
	var after_month_two: GameState = _step_months(core, after_month_one, 1)
	if after_month_two == null:
		return
	_expect_unreleased(after_month_two, "Month Step 2")


func _verify_empty_plan_release(core: SimulationCore, state: GameState) -> void:
	var commit: SimulationOperationResult = core.commit_plan(state, Plan.new())
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "An empty Plan did not commit.")
	if not commit.has_candidate_state():
		return
	var month_one: SimulationOperationResult = core.step_month(commit.candidate_state)
	_expect(month_one.has_candidate_state(), "Month Step 1 has no candidate Game State.")
	if not month_one.has_candidate_state():
		return
	var month_two: SimulationOperationResult = core.step_month(month_one.candidate_state)
	_expect(month_two.has_candidate_state(), "Month Step 2 has no candidate Game State.")
	if not month_two.has_candidate_state():
		return
	var month_three: SimulationOperationResult = core.step_month(month_two.candidate_state)
	_expect(
		month_three.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"Month Step 3 did not stop at the Quarter Boundary."
	)
	if not month_three.has_candidate_state():
		return
	_expect_released_world(month_three.candidate_state)
	_expect(
		month_three.candidate_state.attention_events.size() == 1,
		"The Competitor release changed the Quarter Boundary Attention Event count."
	)
	if month_three.candidate_state.attention_events.size() == 1:
		_expect(
			month_three.candidate_state.attention_events[0].event_type_id
			== CreateQuarterBoundaryAttentionRule.EVENT_TYPE_ID,
			"The Competitor release created a Competitor Attention Event."
		)
	_expect(
		month_three.candidate_state.notifications.is_empty(),
		"The Competitor release created a Notification."
	)
	_expect(
		_has_trace_event(month_one.trace, RELEASE_EVENT_ID) == false,
		"Month Step 1 emitted the Competitor release event."
	)
	_expect(
		_has_trace_event(month_two.trace, RELEASE_EVENT_ID) == false,
		"Month Step 2 emitted the Competitor release event."
	)
	_expect(
		_has_trace_event(month_three.trace, RELEASE_EVENT_ID),
		"Month Step 3 did not emit the Competitor release event."
	)
	_expect(
		_rule_order(month_three.trace).find(ResolveProjectCompletionsRule.RULE_ID)
		< _rule_order(month_three.trace).find(AdvanceCompetitorsRule.RULE_ID),
		"The Competitor Rule did not run after Project completions."
	)
	_expect(
		_rule_order(month_three.trace).find(AdvanceCompetitorsRule.RULE_ID)
		< _rule_order(month_three.trace).find(CreateQuarterBoundaryAttentionRule.RULE_ID),
		"The Competitor Rule did not run before the Quarter Boundary Attention Event."
	)


func _verify_player_model_does_not_move_frontier(core: SimulationCore, state: GameState) -> void:
	var after_month_three: GameState = _advance_plan(core, state, [_research_command(state, 0)], 3)
	if after_month_three == null:
		return
	_expect_released_world(after_month_three)
	_expect(
		after_month_three.company.models.has(&"model.player.research_output"),
		"The Research Project did not create the player Model."
	)
	if after_month_three.company.models.has(&"model.player.research_output"):
		var research_model: ModelState = after_month_three.company.models[&"model.player.research_output"]
		_expect(
			research_model.evaluations.coding_evaluation_points == 84,
			"The Research Model coding evaluation is incorrect."
		)
		_expect(
			research_model.evaluations.reasoning_evaluation_points == 79,
			"The Research Model reasoning evaluation is incorrect."
		)
		_expect(
			research_model.evaluations.efficiency_evaluation_points == 80,
			"The Research Model efficiency evaluation is incorrect."
		)
	_expect(
		not after_month_three.company.models.has(FLAGSHIP_MODEL_ID),
		"The Competitor Model was stored in Company State."
	)


func _verify_replay_matches(core: SimulationCore, state: GameState) -> void:
	var first: SimulationOperationResult = _advance_empty_until_boundary(core, state)
	var second: SimulationOperationResult = _advance_empty_until_boundary(core, state)
	if first == null or second == null:
		return
	if not first.has_candidate_state() or not second.has_candidate_state():
		return
	_expect_released_world(first.candidate_state)
	_expect_released_world(second.candidate_state)
	_expect(
		var_to_bytes_with_objects(first.candidate_state)
		== var_to_bytes_with_objects(second.candidate_state),
		"Replay produced a different Competitor release Game State."
	)
	_expect(
		first.trace.to_canonical_data() == second.trace.to_canonical_data(),
		"Replay produced a different Competitor release Simulation Trace."
	)
	var first_model: ModelState = first.candidate_state.world.models[FLAGSHIP_MODEL_ID]
	var second_model: ModelState = second.candidate_state.world.models[FLAGSHIP_MODEL_ID]
	_expect(
		first_model.evaluations.coding_evaluation_points == 82
		and second_model.evaluations.coding_evaluation_points == 82,
		"Replay did not preserve the actual coding evaluation."
	)
	_expect(
		first_model.evaluations.reasoning_evaluation_points == 78
		and second_model.evaluations.reasoning_evaluation_points == 78,
		"Replay did not preserve the actual reasoning evaluation."
	)
	_expect(
		first_model.evaluations.efficiency_evaluation_points == 72
		and second_model.evaluations.efficiency_evaluation_points == 72,
		"Replay did not preserve the actual efficiency evaluation."
	)


func _expect_unreleased(state: GameState, month_label: String) -> void:
	var competitor: CompetitorState = state.world.competitors[NORTHSTAR_ID]
	_expect(
		competitor.stage_id == &"competitor_stage.northstar.announced",
		"%s changed the Competitor Stage." % month_label
	)
	_expect(state.world.models.is_empty(), "%s created a World Model." % month_label)
	_expect(
		state.world.technical_frontier.coding_evaluation_points == 74,
		"%s changed the coding technical frontier." % month_label
	)
	_expect(
		state.world.technical_frontier.reasoning_evaluation_points == 72,
		"%s changed the reasoning technical frontier." % month_label
	)
	_expect(
		state.world.technical_frontier.efficiency_evaluation_points == 74,
		"%s changed the efficiency technical frontier." % month_label
	)
	_expect(
		state.world.markets[&"market.coding_agent"].customer_expectation_coding_evaluation_points == 70,
		"%s changed the Coding Agent customer expectation." % month_label
	)


func _expect_released_world(state: GameState) -> void:
	var competitor: CompetitorState = state.world.competitors[NORTHSTAR_ID]
	_expect(
		competitor.stage_id == &"competitor_stage.northstar.flagship_released",
		"The Competitor Stage is not flagship_released after Month Step 3."
	)
	_expect(state.world.models.has(FLAGSHIP_MODEL_ID), "The Competitor Model is missing from World State.")
	if not state.world.models.has(FLAGSHIP_MODEL_ID):
		return
	var model: ModelState = state.world.models[FLAGSHIP_MODEL_ID]
	_expect(model.stable_id == FLAGSHIP_MODEL_ID, "The Competitor Model identifier is incorrect.")
	_expect(model.display_name == "Northstar Flagship", "The Competitor Model display name is incorrect.")
	_expect(model.version_label == "1.0", "The Competitor Model version label is incorrect.")
	_expect(
		model.release_strategy_id == &"release_strategy.commercial_api",
		"The Competitor Model Release Strategy is incorrect."
	)
	_expect(model.release_state_id == &"model_release_state.released", "The Competitor Model is not released.")
	_expect(model.training_compute_unit_months == 0, "The Competitor Model training Compute Capacity is incorrect.")
	_expect(
		model.inference_compute_unit_months_per_contract == 0,
		"The Competitor Model inference Compute Capacity is incorrect."
	)
	_expect(model.evaluations.coding_evaluation_points == 82, "The actual coding evaluation is incorrect.")
	_expect(model.evaluations.reasoning_evaluation_points == 78, "The actual reasoning evaluation is incorrect.")
	_expect(model.evaluations.efficiency_evaluation_points == 72, "The actual efficiency evaluation is incorrect.")
	_expect(
		state.world.technical_frontier.coding_evaluation_points == 82,
		"The coding technical frontier is incorrect."
	)
	_expect(
		state.world.technical_frontier.reasoning_evaluation_points == 78,
		"The reasoning technical frontier is incorrect."
	)
	_expect(
		state.world.technical_frontier.efficiency_evaluation_points == 74,
		"The efficiency technical frontier is incorrect."
	)
	_expect(
		state.world.markets[&"market.coding_agent"].customer_expectation_coding_evaluation_points == 80,
		"The Coding Agent customer expectation is incorrect."
	)


func _advance_empty_until_boundary(core: SimulationCore, state: GameState) -> SimulationOperationResult:
	var commit: SimulationOperationResult = core.commit_plan(state, Plan.new())
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The replay empty Plan did not commit.")
	if not commit.has_candidate_state():
		return null
	var advanced: SimulationOperationResult = core.advance_until_attention_required(commit.candidate_state)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"Replay Advance did not stop at the Quarter Boundary."
	)
	return advanced


func _advance_empty_plan(core: SimulationCore, state: GameState, month_count: int) -> GameState:
	return _advance_plan(core, state, [], month_count)


func _advance_plan(
		core: SimulationCore,
		state: GameState,
		commands: Array[Command],
		month_count: int
	) -> GameState:
	var plan: Plan = Plan.new()
	plan.commands.assign(commands)
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The Competitor test Plan did not commit.")
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
			"A Competitor Month Step did not complete."
		)
		if not result.has_candidate_state():
			return null
		current = result.candidate_state
	return current


func _research_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = RESEARCH_ID
	payload[&"model_display_name"] = "Aperture"
	payload[&"model_version_label"] = "2.0"
	payload[&"release_strategy_id"] = &"release_strategy.commercial_api"
	command.payload = payload
	return command


func _has_trace_event(trace: SimulationTrace, event_id: StringName) -> bool:
	if trace == null:
		return false
	for record: SimulationTraceRecord in trace.get_records():
		var event_record: EventEmissionTraceRecord = record as EventEmissionTraceRecord
		if event_record != null and event_record.succeeded and event_record.event_id == event_id:
			return true
	return false


func _rule_order(trace: SimulationTrace) -> Array[StringName]:
	var rule_ids: Array[StringName] = []
	if trace == null:
		return rule_ids
	for record: SimulationTraceRecord in trace.get_records():
		var rule_record: RuleEvaluationTraceRecord = record as RuleEvaluationTraceRecord
		if rule_record != null:
			rule_ids.append(rule_record.rule_id)
	return rule_ids


func _finish() -> void:
	if _failure_count > 0:
		printerr("COMPETITOR_RELEASE_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=5" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
