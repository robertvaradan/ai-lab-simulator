extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const TEST_SUCCESS: String = "MARKET_EFFECTS_TEST_SUCCESS"
const BUILD_LAB_ID: StringName = &"project.campus.build_laboratory"
const RESEARCH_ID: StringName = &"project.research.frontier_model"
const SCALE_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_PROJECT_ID: StringName = &"project.application.coding_agent"
const CODING_AGENT_APP_ID: StringName = &"application.player.coding_agent"
const STARTING_MODEL_ID: StringName = &"model.player.starting"
const RESEARCH_MODEL_ID: StringName = &"model.player.research_output"
const OPERATING_CATEGORY: StringName = &"cash_category.operating_cost"
const STANDARD_COMPUTE_CATEGORY: StringName = &"cash_category.compute_contract.standard"
const BURST_COMPUTE_CATEGORY: StringName = &"cash_category.compute_contract.burst"
const REVENUE_CATEGORY: StringName = &"cash_category.application.revenue"
const PROJECT_START_CATEGORY: StringName = &"cash_category.project.start"

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
		"The Market effects Simulation Core did not construct:\n%s" % construction.format_diagnostics()
	)
	if not construction.succeeded():
		_finish()
		return

	_verify_derived_calculations()
	_verify_price_exceeds_power_faults()
	_verify_derived_values_are_not_stored()
	_verify_no_market_phase_rule()
	_verify_empty_plan_cash_and_compute(construction.core, state_result.state)
	_verify_research_first(construction.core, state_result.state)
	_verify_scale_first(construction.core, state_result.state)
	_verify_application_first(construction.core, state_result.state)
	_verify_hybrid(construction.core, state_result.state)
	_verify_replay(construction.core, state_result.state)
	_finish()


func _verify_derived_calculations() -> void:
	var leading: Vector3i = CodingAgentMarket.technical_competitiveness_vector(
		_evaluations(80, 70, 70),
		_evaluations(70, 70, 70)
	)
	_expect(leading == Vector3i(10, 0, 0), "Leading technical competitiveness is incorrect.")
	var trailing: Vector3i = CodingAgentMarket.technical_competitiveness_vector(
		_evaluations(60, 70, 70),
		_evaluations(70, 70, 70)
	)
	_expect(trailing == Vector3i(-10, 0, 0), "Trailing technical competitiveness is incorrect.")
	var month_one: Vector3i = CodingAgentMarket.technical_competitiveness_vector(
		_evaluations(72, 70, 76),
		_evaluations(74, 72, 74)
	)
	var month_two: Vector3i = CodingAgentMarket.technical_competitiveness_vector(
		_evaluations(72, 70, 76),
		_evaluations(74, 72, 74)
	)
	_expect(month_one == Vector3i(-2, -2, 2), "Starting Model technical competitiveness is incorrect.")
	_expect(month_two == month_one, "Model age changed technical competitiveness.")
	var research: Vector3i = CodingAgentMarket.technical_competitiveness_vector(
		_evaluations(84, 79, 80),
		_evaluations(82, 78, 74)
	)
	_expect(research == Vector3i(2, 1, 6), "Research-first technical competitiveness is incorrect.")
	var before: CodingAgentDemandCalculation = CodingAgentMarket.calculate_demand(
		_released_model(72, 70, 76),
		_market(70),
		_application(1)
	)
	_expect(before.succeeded, "Demand before the Competitor release failed.")
	_expect(before.customer_contract_count == 12, "Demand before the Competitor release is incorrect.")
	_expect(before.relevance_tier_id == CodingAgentMarket.TIER_LEADING, "Leading relevance tier is incorrect.")
	var after: CodingAgentDemandCalculation = CodingAgentMarket.calculate_demand(
		_released_model(72, 70, 76),
		_market(80),
		_application(1)
	)
	_expect(after.succeeded, "Demand after the Competitor release failed.")
	_expect(after.customer_contract_count == 6, "Demand after the Competitor release is incorrect.")
	_expect(after.relevance_tier_id == CodingAgentMarket.TIER_TRAILING, "Trailing relevance tier is incorrect.")
	var competitive: CodingAgentDemandCalculation = CodingAgentMarket.calculate_demand(
		_released_model(66, 70, 70),
		_market(70),
		_application(1)
	)
	_expect(competitive.succeeded, "Competitive demand failed.")
	_expect(competitive.customer_contract_count == 9, "Competitive demand is incorrect.")
	_expect(
		competitive.relevance_tier_id == CodingAgentMarket.TIER_COMPETITIVE,
		"Competitive relevance tier is incorrect."
	)


func _verify_price_exceeds_power_faults() -> void:
	var result: CodingAgentDemandCalculation = CodingAgentMarket.calculate_demand(
		_released_model(72, 70, 76),
		_market(70),
		_application(3)
	)
	_expect(not result.succeeded, "A price above pricing power succeeded.")
	_expect(
		result.diagnostic != null and result.diagnostic.code == &"market.price_exceeds_pricing_power",
		"A price above pricing power has the wrong diagnostic."
	)


func _verify_derived_values_are_not_stored() -> void:
	var model: ModelState = ModelState.new()
	for property: Dictionary in model.get_property_list():
		if not property.has("name"):
			continue
		var property_name: String = str(property["name"])
		_expect(
			property_name != "competitiveness"
			and property_name != "relevance"
			and property_name != "pricing_power_musd"
			and property_name != "customer_demand",
			"ModelState stores derived market property %s." % property_name
		)


func _verify_no_market_phase_rule() -> void:
	var registry: SimulationRuleRegistry = TimeModelRuleFactory.create_registry()
	for rule: SimulationRule in registry.get_rules_in_registration_order():
		_expect(
			rule.phase_id != SimulationRulePhase.RESOLVE_MARKET_CHANGES,
			"Rule %s is registered in Resolve Market changes." % rule.stable_id
		)


func _verify_empty_plan_cash_and_compute(core: SimulationCore, state: GameState) -> void:
	var advanced: SimulationOperationResult = _advance_until_boundary(core, state, [])
	if advanced == null or not advanced.has_candidate_state():
		return
	var ended: GameState = advanced.candidate_state
	_expect(ended.cash_ledger.calculate_balance_musd() == 123, "Empty-plan Cash is incorrect.")
	_expect(ended.company.compute_capacity_unit_months == 70, "Empty-plan Compute Capacity changed.")
	_expect(_category_total(ended, OPERATING_CATEGORY) == -15, "Empty-plan operating cost is incorrect.")
	_expect(
		_category_total(ended, STANDARD_COMPUTE_CATEGORY) == -12,
		"Empty-plan standard compute cost is incorrect."
	)
	_expect(_category_total(ended, REVENUE_CATEGORY) == 0, "Empty-plan posted Application Revenue.")
	_expect(
		not _has_trace_event(advanced.trace, PostApplicationRevenueRule.EVENT_ID),
		"Empty-plan emitted a Revenue event."
	)
	_expect(
		_count_trace_events(advanced.trace, PostOperatingCostRule.EVENT_ID) == 3,
		"Empty-plan did not post operating cost in each Month Step."
	)
	_expect(
		_count_trace_events(advanced.trace, PostComputeContractCostsRule.EVENT_ID) == 3,
		"Empty-plan did not post standard compute cost in each Month Step."
	)


func _verify_research_first(core: SimulationCore, state: GameState) -> void:
	var after_lab: GameState = _complete_build_laboratory(core, state)
	if after_lab == null:
		return
	var month_one_competitiveness: Vector3i = CodingAgentMarket.technical_competitiveness_vector(
		after_lab.company.models[STARTING_MODEL_ID].evaluations,
		after_lab.world.technical_frontier
	)
	var after_research_month_one: GameState = _advance_plan(
		core,
		after_lab,
		[_research_command(after_lab, 0)],
		1
	)
	if after_research_month_one == null:
		return
	var month_two_competitiveness: Vector3i = CodingAgentMarket.technical_competitiveness_vector(
		after_research_month_one.company.models[STARTING_MODEL_ID].evaluations,
		after_research_month_one.world.technical_frontier
	)
	_expect(
		month_two_competitiveness == month_one_competitiveness,
		"Model age changed technical competitiveness during the Research-first run."
	)
	var ended: GameState = _step_months(core, after_research_month_one, 1)
	if ended == null:
		return
	_expect(ended.cash_ledger.calculate_balance_musd() == 48, "Research-first Cash is incorrect.")
	_expect(_category_total(ended, PROJECT_START_CATEGORY) == -75, "Research-first Project cost is incorrect.")
	_expect(_category_total(ended, OPERATING_CATEGORY) == -15, "Research-first operating cost is incorrect.")
	_expect(
		_category_total(ended, STANDARD_COMPUTE_CATEGORY) == -12,
		"Research-first standard compute cost is incorrect."
	)
	_expect(ended.company.compute_capacity_unit_months == 70, "Research-first Compute Capacity changed.")
	_expect(
		not ended.company.applications.has(CODING_AGENT_APP_ID),
		"Research-first created the Coding Agent."
	)
	_expect(
		ended.company.projects[RESEARCH_ID].status_id == ProjectState.STATUS_ACTIVE,
		"Research-first completed the Research Project before the Quarter Boundary."
	)
	_expect(
		not ended.company.models.has(RESEARCH_MODEL_ID),
		"Research-first released the completed Model before the Quarter Boundary."
	)
	_expect(_category_total(ended, REVENUE_CATEGORY) == 0, "Research-first posted Application Revenue.")


func _verify_scale_first(core: SimulationCore, state: GameState) -> void:
	var after_lab: GameState = _complete_build_laboratory(core, state)
	if after_lab == null:
		return
	var advanced: SimulationOperationResult = _advance_until_boundary(
		core,
		after_lab,
		[_scale_command(after_lab, 0)]
	)
	if advanced == null or not advanced.has_candidate_state():
		return
	var ended: GameState = advanced.candidate_state
	_expect(ended.cash_ledger.calculate_balance_musd() == 67, "Scale-first Cash is incorrect.")
	_expect(_category_total(ended, PROJECT_START_CATEGORY) == -40, "Scale-first Project cost is incorrect.")
	_expect(_category_total(ended, OPERATING_CATEGORY) == -15, "Scale-first operating cost is incorrect.")
	_expect(
		_category_total(ended, STANDARD_COMPUTE_CATEGORY) == -12,
		"Scale-first standard compute cost is incorrect."
	)
	_expect(_category_total(ended, BURST_COMPUTE_CATEGORY) == -16, "Scale-first burst compute cost is incorrect.")
	_expect(ended.company.compute_capacity_unit_months == 130, "Scale-first Compute Capacity is incorrect.")
	_expect(
		ended.company.contracts.has(&"contract.compute.burst"),
		"Scale-first did not keep the burst compute contract."
	)
	_expect(
		_count_trace_events(advanced.trace, PostComputeContractCostsRule.EVENT_ID) == 4,
		"Scale-first did not post each active compute contract in each Month Step after the laboratory."
	)


func _verify_application_first(core: SimulationCore, state: GameState) -> void:
	var after_lab: GameState = _complete_build_laboratory(core, state)
	if after_lab == null:
		return
	var commit: SimulationOperationResult = _commit(core, after_lab, [_coding_agent_command(after_lab, 0)])
	if commit == null or not commit.has_candidate_state():
		return
	var month_two: SimulationOperationResult = core.step_month(commit.candidate_state)
	_expect(month_two.has_candidate_state(), "Application-first Month Step 2 has no candidate Game State.")
	if not month_two.has_candidate_state():
		return
	_expect(
		not month_two.candidate_state.company.applications.has(CODING_AGENT_APP_ID),
		"The Coding Agent became active before Month Step 3."
	)
	_expect(
		not _has_trace_event(month_two.trace, PostApplicationRevenueRule.EVENT_ID),
		"Month Step 2 posted Coding Agent Revenue."
	)
	var month_three: SimulationOperationResult = core.step_month(month_two.candidate_state)
	_expect(
		month_three.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"Application-first Month Step 3 did not stop at the Quarter Boundary."
	)
	if not month_three.has_candidate_state():
		return
	_expect(
		month_three.candidate_state.company.applications.has(CODING_AGENT_APP_ID),
		"The Coding Agent Project did not create the Coding Agent in Month Step 3."
	)
	var ended: GameState = month_three.candidate_state
	_expect(ended.cash_ledger.calculate_balance_musd() == 79, "Application-first Cash is incorrect.")
	_expect(_category_total(ended, PROJECT_START_CATEGORY) == -50, "Application-first Project cost is incorrect.")
	_expect(_category_total(ended, OPERATING_CATEGORY) == -15, "Application-first operating cost is incorrect.")
	_expect(
		_category_total(ended, STANDARD_COMPUTE_CATEGORY) == -12,
		"Application-first standard compute cost is incorrect."
	)
	_expect(_category_total(ended, REVENUE_CATEGORY) == 6, "Application-first Revenue is incorrect.")
	_expect(ended.company.compute_capacity_unit_months == 70, "Application-first inference reduced Compute Capacity.")
	_expect(
		ended.company.applications[CODING_AGENT_APP_ID].active_customer_contract_count == 6,
		"Application-first ending customer-contract count is incorrect."
	)
	_expect(
		ended.company.applications[CODING_AGENT_APP_ID].supporting_model_id == STARTING_MODEL_ID,
		"Application-first changed the supporting Model."
	)
	_expect(
		_revenue_payload_int(month_three.trace, &"customer_contract_count") == 6,
		"Month Step 3 demand is incorrect."
	)
	_expect(_revenue_payload_int(month_three.trace, &"revenue_musd") == 6, "Month Step 3 Revenue is incorrect.")
	_expect(
		_revenue_payload_name(month_three.trace, &"supporting_model_id") == STARTING_MODEL_ID,
		"The Revenue event supporting Model is incorrect."
	)
	_expect(
		_revenue_payload_int(month_three.trace, &"customer_expectation_coding_evaluation_points") == 80,
		"The Revenue event customer expectation is incorrect."
	)
	_expect(
		_event_index(month_three.trace, AdvanceCompetitorsRule.EVENT_ID)
		< _event_index(month_three.trace, PostApplicationRevenueRule.EVENT_ID),
		"Month Step 3 posted Revenue before the Competitor release."
	)


func _verify_hybrid(core: SimulationCore, state: GameState) -> void:
	var after_lab: GameState = _complete_build_laboratory(core, state)
	if after_lab == null:
		return
	var advanced: SimulationOperationResult = _advance_until_boundary(
		core,
		after_lab,
		[_research_command(after_lab, 0), _coding_agent_command(after_lab, 1)]
	)
	if advanced == null or not advanced.has_candidate_state():
		return
	var ended: GameState = advanced.candidate_state
	_expect(ended.cash_ledger.calculate_balance_musd() == 14, "Hybrid Cash is incorrect.")
	_expect(_category_total(ended, PROJECT_START_CATEGORY) == -115, "Hybrid Project cost is incorrect.")
	_expect(_category_total(ended, OPERATING_CATEGORY) == -15, "Hybrid operating cost is incorrect.")
	_expect(_category_total(ended, STANDARD_COMPUTE_CATEGORY) == -12, "Hybrid standard compute cost is incorrect.")
	_expect(_category_total(ended, REVENUE_CATEGORY) == 6, "Hybrid Revenue is incorrect.")
	_expect(
		ended.company.projects[RESEARCH_ID].status_id == ProjectState.STATUS_ACTIVE,
		"Hybrid completed the Research Project before the Quarter Boundary."
	)
	_expect(not ended.company.models.has(RESEARCH_MODEL_ID), "Hybrid released the completed Model before the Quarter Boundary.")
	_expect(
		ended.company.applications[CODING_AGENT_APP_ID].supporting_model_id == STARTING_MODEL_ID,
		"Hybrid replaced the Coding Agent supporting Model."
	)
	_expect(
		ended.company.applications[CODING_AGENT_APP_ID].active_customer_contract_count == 6,
		"Hybrid ending customer-contract count is incorrect."
	)


func _verify_replay(core: SimulationCore, state: GameState) -> void:
	var first: SimulationOperationResult = _advance_until_boundary(core, state, [])
	var second: SimulationOperationResult = _advance_until_boundary(core, state, [])
	if first == null or second == null:
		return
	if not first.has_candidate_state() or not second.has_candidate_state():
		return
	_expect(
		var_to_bytes_with_objects(first.candidate_state)
		== var_to_bytes_with_objects(second.candidate_state),
		"Replay produced a different empty-plan Game State."
	)
	_expect(
		first.trace.to_canonical_data() == second.trace.to_canonical_data(),
		"Replay produced a different empty-plan Simulation Trace."
	)
	_expect(first.candidate_state.cash_ledger.calculate_balance_musd() == 123, "Replay Cash is incorrect.")


func _complete_build_laboratory(core: SimulationCore, state: GameState) -> GameState:
	return _advance_plan(core, state, [_build_lab_command(state, 0)], 1)


func _advance_until_boundary(
		core: SimulationCore,
		state: GameState,
		commands: Array[Command]
	) -> SimulationOperationResult:
	var commit: SimulationOperationResult = _commit(core, state, commands)
	if commit == null or not commit.has_candidate_state():
		return null
	var advanced: SimulationOperationResult = core.advance_until_attention_required(commit.candidate_state)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"Advance did not stop at the Quarter Boundary."
	)
	return advanced


func _commit(core: SimulationCore, state: GameState, commands: Array[Command]) -> SimulationOperationResult:
	var plan: Plan = Plan.new()
	plan.commands.assign(commands)
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The Market effects Plan did not commit.")
	return commit


func _advance_plan(
		core: SimulationCore,
		state: GameState,
		commands: Array[Command],
		month_count: int
	) -> GameState:
	var commit: SimulationOperationResult = _commit(core, state, commands)
	if commit == null or not commit.has_candidate_state():
		return null
	return _step_months(core, commit.candidate_state, month_count)


func _step_months(core: SimulationCore, state: GameState, month_count: int) -> GameState:
	var current: GameState = state
	for _month_index: int in range(month_count):
		var result: SimulationOperationResult = core.step_month(current)
		_expect(
			result.outcome == SimulationOperationOutcome.Type.COMPLETED
			or result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
			"A Market effects Month Step did not complete."
		)
		if not result.has_candidate_state():
			return null
		current = result.candidate_state
	return current


func _build_lab_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = BUILD_LAB_ID
	command.payload = payload
	return command


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
	payload[&"project_id"] = CODING_AGENT_PROJECT_ID
	payload[&"supporting_model_id"] = STARTING_MODEL_ID
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


func _evaluations(coding: int, reasoning: int, efficiency: int) -> ModelEvaluationState:
	var evaluations: ModelEvaluationState = ModelEvaluationState.new()
	evaluations.coding_evaluation_points = coding
	evaluations.reasoning_evaluation_points = reasoning
	evaluations.efficiency_evaluation_points = efficiency
	return evaluations


func _released_model(coding: int, reasoning: int, efficiency: int) -> ModelState:
	var model: ModelState = ModelState.new()
	model.stable_id = STARTING_MODEL_ID
	model.release_state_id = CodingAgentMarket.RELEASED_STATE_ID
	model.evaluations = _evaluations(coding, reasoning, efficiency)
	model.inference_compute_unit_months_per_contract = 2
	return model


func _market(expectation: int) -> MarketState:
	var market: MarketState = MarketState.new()
	market.stable_id = CodingAgentMarket.MARKET_ID
	market.possible_customer_contract_count = 12
	market.customer_expectation_coding_evaluation_points = expectation
	market.reference_price_musd_per_contract_month = 1
	return market


func _application(price_musd: int) -> ApplicationState:
	var application: ApplicationState = ApplicationState.new()
	application.stable_id = CODING_AGENT_APP_ID
	application.content_definition_id = CODING_AGENT_APP_ID
	application.status_id = ApplicationState.STATUS_ACTIVE
	application.supporting_model_id = STARTING_MODEL_ID
	application.price_musd_per_contract_month = price_musd
	application.active_customer_contract_count = 0
	return application


func _category_total(state: GameState, category_id: StringName) -> int:
	var total: int = 0
	for transaction: LedgerTransactionState in state.cash_ledger.transactions:
		if transaction.category_id == category_id:
			total += transaction.amount_musd
	return total


func _has_trace_event(trace: SimulationTrace, event_id: StringName) -> bool:
	return _count_trace_events(trace, event_id) > 0


func _count_trace_events(trace: SimulationTrace, event_id: StringName) -> int:
	var count: int = 0
	if trace == null:
		return count
	for record: SimulationTraceRecord in trace.get_records():
		if record.kind != SimulationTraceRecord.Kind.EVENT_EMISSION:
			continue
		var event_record: EventEmissionTraceRecord = record as EventEmissionTraceRecord
		if event_record != null and event_record.succeeded and event_record.event_id == event_id:
			count += 1
	return count


func _event_index(trace: SimulationTrace, event_id: StringName) -> int:
	if trace == null:
		return -1
	var records: Array[SimulationTraceRecord] = trace.get_records()
	for index: int in range(records.size()):
		if records[index].kind != SimulationTraceRecord.Kind.EVENT_EMISSION:
			continue
		var event_record: EventEmissionTraceRecord = records[index] as EventEmissionTraceRecord
		if event_record != null and event_record.succeeded and event_record.event_id == event_id:
			return index
	return -1


func _revenue_payload_int(trace: SimulationTrace, key: StringName) -> int:
	var payload: Dictionary[StringName, Variant] = _revenue_payload(trace)
	if payload.is_empty() or not payload.has(key):
		return -1
	return str(payload[key]).to_int()


func _revenue_payload_name(trace: SimulationTrace, key: StringName) -> StringName:
	var payload: Dictionary[StringName, Variant] = _revenue_payload(trace)
	if payload.is_empty() or not payload.has(key):
		return &""
	return StringName(str(payload[key]))


func _revenue_payload(trace: SimulationTrace) -> Dictionary[StringName, Variant]:
	var payload: Dictionary[StringName, Variant] = {}
	if trace == null:
		return payload
	for record: SimulationTraceRecord in trace.get_records():
		if record.kind != SimulationTraceRecord.Kind.EVENT_EMISSION:
			continue
		var event_record: EventEmissionTraceRecord = record as EventEmissionTraceRecord
		if (
			event_record != null
			and event_record.succeeded
			and event_record.event_id == PostApplicationRevenueRule.EVENT_ID
		):
			payload.assign(event_record.payload)
			return payload
	return payload


func _finish() -> void:
	if _failure_count > 0:
		printerr("MARKET_EFFECTS_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=10" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
