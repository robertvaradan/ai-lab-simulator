extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const TEST_SUCCESS: String = "QUARTERLY_REPORT_TEST_SUCCESS"
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
		"The Quarterly Report Simulation Core did not construct:\n%s" % construction.format_diagnostics()
	)
	if not construction.succeeded():
		_finish()
		return

	_verify_opening_report(definition, state_result.state)
	_verify_empty_plan_ending(construction.core, definition, state_result.state)
	_verify_research_first_ending(construction.core, definition, state_result.state)
	_verify_scale_first_ending(construction.core, definition, state_result.state)
	_verify_application_first_ending(construction.core, definition, state_result.state)
	_verify_hybrid_ending(construction.core, definition, state_result.state)
	_verify_recompile_equality(construction.core, definition, state_result.state)
	_verify_compile_does_not_change_state(construction.core, definition, state_result.state)
	_verify_attention_before_report(construction.core, state_result.state)
	_verify_replay(construction.core, state_result.state)
	_finish()


func _verify_opening_report(definition: MarketingScenarioDefinition, state: GameState) -> void:
	_expect(state.quarterly_reports.size() == 1, "The starting Game State does not contain one Quarterly Report.")
	if state.quarterly_reports.is_empty():
		return
	var report: QuarterlyReportState = state.quarterly_reports[0]
	_expect(report.stable_id == QuarterlyReportState.KIND_OPENING, "The opening report identifier is incorrect.")
	_expect(report.report_kind_id == QuarterlyReportState.KIND_OPENING, "The opening report kind is incorrect.")
	_expect(report.cash_balance_musd == 150, "The opening report Cash is incorrect.")
	_expect(report.cash_changes.is_empty(), "The opening report contains Cash changes.")
	_expect(report.released_competitor_evaluations == null, "The opening report reveals actual Competitor evaluations.")
	_expect(report.competitor_forecasts.size() == 1, "The opening report forecast count is incorrect.")
	if report.competitor_forecasts.size() == 1:
		var forecast: CompetitorForecast = report.competitor_forecasts[0]
		_expect(forecast.known_release_quarter_index == 1, "The opening Northstar release quarter is incorrect.")
		_expect(forecast.projected_coding_evaluation_min == 80, "The opening coding projection minimum is incorrect.")
		_expect(forecast.projected_coding_evaluation_max == 84, "The opening coding projection maximum is incorrect.")
		_expect(forecast.projected_reasoning_evaluation_min == 76, "The opening reasoning projection minimum is incorrect.")
		_expect(forecast.projected_reasoning_evaluation_max == 80, "The opening reasoning projection maximum is incorrect.")
		_expect(forecast.projected_efficiency_evaluation_min == 70, "The opening efficiency projection minimum is incorrect.")
		_expect(forecast.projected_efficiency_evaluation_max == 74, "The opening efficiency projection maximum is incorrect.")
	var recompiled: QuarterlyReportState = QuarterlyReportCompiler.compile_opening(
		state,
		definition.competitor_definitions
	)
	_expect(
		var_to_bytes_with_objects(report) == var_to_bytes_with_objects(recompiled),
		"The opening report does not equal a recompile from starting Game State."
	)


func _verify_empty_plan_ending(
		core: SimulationCore,
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var ended: GameState = _ending_state(core, state, [])
	if ended == null:
		return
	var report: QuarterlyReportState = _require_ending_report(ended)
	if report == null:
		return
	_expect(report.cash_balance_musd == 123, "Empty-plan ending Cash is incorrect.")
	_expect(_cash_change(report, OPERATING_CATEGORY) == -15, "Empty-plan operating cost is incorrect.")
	_expect(_cash_change(report, STANDARD_COMPUTE_CATEGORY) == -12, "Empty-plan standard compute cost is incorrect.")
	_expect(not _has_cash_category(report, PROJECT_START_CATEGORY), "Empty-plan posted a Project start cost.")
	_expect(not _has_cash_category(report, REVENUE_CATEGORY), "Empty-plan posted Application Revenue.")
	_expect(report.projects.is_empty(), "Empty-plan ending report contains a Project.")
	_expect(report.applications.is_empty(), "Empty-plan ending report contains an Application.")
	_verify_released_northstar(report)
	_verify_frontier_and_expectation_delta(report)
	_verify_unchanged_trust(report)
	_expect_ending_equals_recompile(ended, definition, report)


func _verify_research_first_ending(
		core: SimulationCore,
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var ended: GameState = _ending_state(core, state, [_research_command(state, 0)])
	if ended == null:
		return
	var report: QuarterlyReportState = _require_ending_report(ended)
	if report == null:
		return
	_expect(report.cash_balance_musd == 58, "Research-first ending Cash is incorrect.")
	_expect(_cash_change(report, PROJECT_START_CATEGORY) == -65, "Research-first Project cost is incorrect.")
	_expect(_cash_change(report, OPERATING_CATEGORY) == -15, "Research-first operating cost is incorrect.")
	_expect(_cash_change(report, STANDARD_COMPUTE_CATEGORY) == -12, "Research-first standard compute cost is incorrect.")
	_expect(not _has_cash_category(report, REVENUE_CATEGORY), "Research-first posted Application Revenue.")
	_expect(_has_completed_project(report, RESEARCH_ID), "Research-first did not complete the Research Project.")
	_expect(_model_coding(report, RESEARCH_MODEL_ID) == 84, "Research-first Model coding evaluation is incorrect.")
	_expect(_model_reasoning(report, RESEARCH_MODEL_ID) == 79, "Research-first Model reasoning evaluation is incorrect.")
	_expect(_model_efficiency(report, RESEARCH_MODEL_ID) == 80, "Research-first Model efficiency evaluation is incorrect.")
	_expect(report.applications.is_empty(), "Research-first ending report contains an Application.")
	_verify_released_northstar(report)
	_verify_frontier_and_expectation_delta(report)
	_verify_unchanged_trust(report)
	_expect_ending_equals_recompile(ended, definition, report)


func _verify_scale_first_ending(
		core: SimulationCore,
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var ended: GameState = _ending_state(core, state, [_scale_command(state, 0)])
	if ended == null:
		return
	var report: QuarterlyReportState = _require_ending_report(ended)
	if report == null:
		return
	_expect(report.cash_balance_musd == 69, "Scale-first ending Cash is incorrect.")
	_expect(_cash_change(report, PROJECT_START_CATEGORY) == -30, "Scale-first Project cost is incorrect.")
	_expect(_cash_change(report, OPERATING_CATEGORY) == -15, "Scale-first operating cost is incorrect.")
	_expect(_cash_change(report, STANDARD_COMPUTE_CATEGORY) == -12, "Scale-first standard compute cost is incorrect.")
	_expect(_cash_change(report, BURST_COMPUTE_CATEGORY) == -24, "Scale-first burst compute cost is incorrect.")
	_expect(_has_completed_project(report, SCALE_ID), "Scale-first did not complete the Scale Project.")
	_expect(report.applications.is_empty(), "Scale-first ending report contains an Application.")
	_verify_released_northstar(report)
	_verify_frontier_and_expectation_delta(report)
	_verify_unchanged_trust(report)
	_expect_ending_equals_recompile(ended, definition, report)


func _verify_application_first_ending(
		core: SimulationCore,
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var ended: GameState = _ending_state(core, state, [_coding_agent_command(state, 0)])
	if ended == null:
		return
	var report: QuarterlyReportState = _require_ending_report(ended)
	if report == null:
		return
	_expect(report.cash_balance_musd == 101, "Application-first ending Cash is incorrect.")
	_expect(_cash_change(report, PROJECT_START_CATEGORY) == -40, "Application-first Project cost is incorrect.")
	_expect(_cash_change(report, OPERATING_CATEGORY) == -15, "Application-first operating cost is incorrect.")
	_expect(
		_cash_change(report, STANDARD_COMPUTE_CATEGORY) == -12,
		"Application-first standard compute cost is incorrect."
	)
	_expect(_cash_change(report, REVENUE_CATEGORY) == 18, "Application-first Revenue is incorrect.")
	_expect(
		_has_completed_project(report, CODING_AGENT_PROJECT_ID),
		"Application-first did not complete the Coding Agent Project."
	)
	var application: QuarterlyReportApplicationEntry = _application_entry(report, CODING_AGENT_APP_ID)
	_expect(application != null, "Application-first ending report is missing the Coding Agent.")
	if application != null:
		_expect(application.supporting_model_id == STARTING_MODEL_ID, "Application-first changed the supporting Model.")
		_expect(application.active_customer_contract_count == 6, "Application-first ending contract count is incorrect.")
		_expect(application.price_musd_per_contract_month == 1, "Application-first price is incorrect.")
	_verify_released_northstar(report)
	_verify_frontier_and_expectation_delta(report)
	_verify_unchanged_trust(report)
	_expect_ending_equals_recompile(ended, definition, report)


func _verify_hybrid_ending(
		core: SimulationCore,
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var ended: GameState = _ending_state(
		core,
		state,
		[_research_command(state, 0), _coding_agent_command(state, 1)]
	)
	if ended == null:
		return
	var report: QuarterlyReportState = _require_ending_report(ended)
	if report == null:
		return
	_expect(report.cash_balance_musd == 36, "Hybrid ending Cash is incorrect.")
	_expect(_cash_change(report, PROJECT_START_CATEGORY) == -105, "Hybrid Project cost is incorrect.")
	_expect(_cash_change(report, OPERATING_CATEGORY) == -15, "Hybrid operating cost is incorrect.")
	_expect(_cash_change(report, STANDARD_COMPUTE_CATEGORY) == -12, "Hybrid standard compute cost is incorrect.")
	_expect(_cash_change(report, REVENUE_CATEGORY) == 18, "Hybrid Revenue is incorrect.")
	_expect(_has_completed_project(report, RESEARCH_ID), "Hybrid did not complete the Research Project.")
	_expect(
		_has_completed_project(report, CODING_AGENT_PROJECT_ID),
		"Hybrid did not complete the Coding Agent Project."
	)
	_expect(_model_coding(report, RESEARCH_MODEL_ID) == 84, "Hybrid Model coding evaluation is incorrect.")
	var application: QuarterlyReportApplicationEntry = _application_entry(report, CODING_AGENT_APP_ID)
	_expect(application != null, "Hybrid ending report is missing the Coding Agent.")
	if application != null:
		_expect(application.supporting_model_id == STARTING_MODEL_ID, "Hybrid replaced the Coding Agent supporting Model.")
		_expect(application.active_customer_contract_count == 6, "Hybrid ending contract count is incorrect.")
	_verify_released_northstar(report)
	_verify_frontier_and_expectation_delta(report)
	_verify_unchanged_trust(report)
	_expect_ending_equals_recompile(ended, definition, report)


func _verify_recompile_equality(
		core: SimulationCore,
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var ended: GameState = _ending_state(core, state, [_research_command(state, 0)])
	if ended == null:
		return
	var report: QuarterlyReportState = _require_ending_report(ended)
	if report == null:
		return
	_expect_ending_equals_recompile(ended, definition, report)
	_expect(
		ended.quarterly_reports[0].released_competitor_evaluations == null,
		"The stored opening report gained actual Competitor evaluations."
	)


func _verify_compile_does_not_change_state(
		core: SimulationCore,
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var ended: GameState = _ending_state(core, state, [])
	if ended == null:
		return
	var report: QuarterlyReportState = _require_ending_report(ended)
	if report == null:
		return
	var company_before: PackedByteArray = var_to_bytes_with_objects(ended.company)
	var world_before: PackedByteArray = var_to_bytes_with_objects(ended.world)
	var ledger_before: PackedByteArray = var_to_bytes_with_objects(ended.cash_ledger)
	var frontier_coding: int = ended.world.technical_frontier.coding_evaluation_points
	var recompiled: QuarterlyReportState = QuarterlyReportCompiler.compile_ending(
		ended,
		definition.competitor_definitions,
		report.stable_id,
		ended.quarterly_reports[0]
	)
	_expect(recompiled != null, "The immutability recompile did not produce a report.")
	_expect(
		var_to_bytes_with_objects(ended.company) == company_before,
		"Quarterly Report compilation changed Company State."
	)
	_expect(
		var_to_bytes_with_objects(ended.world) == world_before,
		"Quarterly Report compilation changed World State."
	)
	_expect(
		var_to_bytes_with_objects(ended.cash_ledger) == ledger_before,
		"Quarterly Report compilation changed the Cash Ledger."
	)
	_expect(report.is_immutable(), "The ending Quarterly Report is mutable.")
	ended.world.technical_frontier.coding_evaluation_points = 1
	ended.company.public_trust_points = 1
	_expect(
		report.technical_frontier.coding_evaluation_points == frontier_coding,
		"A World State mutation changed the stored Quarterly Report."
	)
	_expect(report.public_trust_points == 55, "A Company State mutation changed the stored Quarterly Report.")
	_expect(ended.cash_ledger.calculate_balance_musd() == 123, "A report snapshot changed Cash Ledger balance.")


func _verify_attention_before_report(core: SimulationCore, state: GameState) -> void:
	var advanced: SimulationOperationResult = _advance_until_boundary(core, state, [])
	if advanced == null or advanced.trace == null:
		return
	var rule_ids: Array[StringName] = _rule_order(advanced.trace)
	var attention_index: int = rule_ids.find(CreateQuarterBoundaryAttentionRule.RULE_ID)
	var report_index: int = rule_ids.find(CreateQuarterlyReportRule.RULE_ID)
	_expect(attention_index >= 0, "The Quarter Boundary Attention Event Rule did not run.")
	_expect(report_index >= 0, "The Quarterly Report Rule did not run.")
	_expect(
		attention_index >= 0 and report_index > attention_index,
		"The Quarterly Report ran before the Quarter Boundary Attention Event."
	)
	var month_three_start: int = 26
	if rule_ids.size() >= 39:
		_expect(
			rule_ids[month_three_start + 9] == CreateQuarterBoundaryAttentionRule.RULE_ID,
			"Month Step 3 did not run the Attention Event Rule before the Quarterly Report."
		)
		_expect(
			rule_ids[month_three_start + 11] == CreateQuarterlyReportRule.RULE_ID,
			"Month Step 3 did not run the Quarterly Report Rule after Notifications."
		)
	var attention_event_index: int = _event_index(advanced.trace, TimeModelEventFactory.QUARTER_BOUNDARY_EVENT)
	var report_event_index: int = _event_index(advanced.trace, CreateQuarterlyReportRule.EVENT_ID)
	_expect(attention_event_index >= 0, "The Quarter Boundary Attention Event was not emitted.")
	_expect(report_event_index >= 0, "The Quarterly Report event was not emitted.")
	_expect(
		attention_event_index >= 0 and report_event_index > attention_event_index,
		"The Quarterly Report event ran before the Quarter Boundary Attention Event."
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
	_expect(first.candidate_state.quarterly_reports.size() == 2, "Replay did not retain both Quarterly Reports.")


func _verify_released_northstar(report: QuarterlyReportState) -> void:
	_expect(
		report.competitor_stage_id == &"competitor_stage.northstar.flagship_released",
		"The ending Competitor Stage is incorrect."
	)
	_expect(
		report.released_competitor_model_id == CompetitorDefinition.RELEASED_MODEL_ID,
		"The ending released Competitor Model identifier is incorrect."
	)
	_expect(report.released_competitor_evaluations != null, "The ending report is missing actual Northstar evaluations.")
	if report.released_competitor_evaluations == null:
		return
	_expect(
		report.released_competitor_evaluations.coding_evaluation_points == 82,
		"The ending Northstar coding evaluation is incorrect."
	)
	_expect(
		report.released_competitor_evaluations.reasoning_evaluation_points == 78,
		"The ending Northstar reasoning evaluation is incorrect."
	)
	_expect(
		report.released_competitor_evaluations.efficiency_evaluation_points == 72,
		"The ending Northstar efficiency evaluation is incorrect."
	)


func _verify_frontier_and_expectation_delta(report: QuarterlyReportState) -> void:
	_expect(report.technical_frontier != null, "The ending technical frontier is missing.")
	_expect(report.previous_technical_frontier != null, "The ending previous technical frontier is missing.")
	if report.technical_frontier == null or report.previous_technical_frontier == null:
		return
	_expect(report.technical_frontier.coding_evaluation_points == 82, "The ending frontier coding evaluation is incorrect.")
	_expect(
		report.technical_frontier.reasoning_evaluation_points == 78,
		"The ending frontier reasoning evaluation is incorrect."
	)
	_expect(
		report.technical_frontier.efficiency_evaluation_points == 74,
		"The ending frontier efficiency evaluation is incorrect."
	)
	_expect(
		report.previous_technical_frontier.coding_evaluation_points == 74,
		"The previous frontier coding evaluation is incorrect."
	)
	_expect(
		report.previous_technical_frontier.reasoning_evaluation_points == 72,
		"The previous frontier reasoning evaluation is incorrect."
	)
	_expect(
		report.previous_technical_frontier.efficiency_evaluation_points == 74,
		"The previous frontier efficiency evaluation is incorrect."
	)
	_expect(report.customer_expectation_coding_evaluation_points == 80, "The ending customer expectation is incorrect.")
	_expect(
		report.previous_customer_expectation_coding_evaluation_points == 70,
		"The previous customer expectation is incorrect."
	)


func _verify_unchanged_trust(report: QuarterlyReportState) -> void:
	_expect(report.public_trust_points == 55, "The ending Public Trust is incorrect.")
	_expect(report.previous_public_trust_points == 55, "The previous Public Trust changed.")
	_expect(report.government_trust_points == 50, "The ending Government Trust is incorrect.")
	_expect(report.previous_government_trust_points == 50, "The previous Government Trust changed.")


func _expect_ending_equals_recompile(
		ended: GameState,
		definition: MarketingScenarioDefinition,
		report: QuarterlyReportState
	) -> void:
	var recompiled: QuarterlyReportState = QuarterlyReportCompiler.compile_ending(
		ended,
		definition.competitor_definitions,
		report.stable_id,
		ended.quarterly_reports[0]
	)
	_expect(
		var_to_bytes_with_objects(report) == var_to_bytes_with_objects(recompiled),
		"The ending Quarterly Report does not equal a recompile from authoritative Game State."
	)


func _ending_state(core: SimulationCore, state: GameState, commands: Array[Command]) -> GameState:
	var advanced: SimulationOperationResult = _advance_until_boundary(core, state, commands)
	if advanced == null or not advanced.has_candidate_state():
		return null
	return advanced.candidate_state


func _require_ending_report(ended: GameState) -> QuarterlyReportState:
	_expect(ended.quarterly_reports.size() == 2, "The ending Game State does not contain two Quarterly Reports.")
	if ended.quarterly_reports.size() != 2:
		return null
	var report: QuarterlyReportState = ended.quarterly_reports[1]
	_expect(report.report_kind_id == QuarterlyReportState.KIND_ENDING, "The ending report kind is incorrect.")
	_expect(
		report.stable_id == StableIdentifier.format_runtime_identifier(&"quarterly_report", 1),
		"The ending report identifier is incorrect."
	)
	_expect(report.quarter_index == 1, "The ending report quarter is incorrect.")
	_expect(report.month_step_index == 3, "The ending report Month Step is incorrect.")
	return report


func _advance_until_boundary(
		core: SimulationCore,
		state: GameState,
		commands: Array[Command]
	) -> SimulationOperationResult:
	var plan: Plan = Plan.new()
	plan.commands.assign(commands)
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The Quarterly Report Plan did not commit.")
	if not commit.has_candidate_state():
		return null
	var advanced: SimulationOperationResult = core.advance_until_attention_required(commit.candidate_state)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"Advance did not stop at the Quarter Boundary."
	)
	return advanced


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


func _cash_change(report: QuarterlyReportState, category_id: StringName) -> int:
	for cash_change: QuarterlyReportCashChange in report.cash_changes:
		if cash_change != null and cash_change.category_id == category_id:
			return cash_change.amount_musd
	return 0


func _has_cash_category(report: QuarterlyReportState, category_id: StringName) -> bool:
	for cash_change: QuarterlyReportCashChange in report.cash_changes:
		if cash_change != null and cash_change.category_id == category_id:
			return true
	return false


func _has_completed_project(report: QuarterlyReportState, project_id: StringName) -> bool:
	for project_entry: QuarterlyReportProjectEntry in report.projects:
		if (
			project_entry != null
			and project_entry.project_id == project_id
			and project_entry.status_id == ProjectState.STATUS_COMPLETED
			and project_entry.remaining_month_steps == 0
		):
			return true
	return false


func _model_coding(report: QuarterlyReportState, model_id: StringName) -> int:
	for model_entry: QuarterlyReportModelEntry in report.models:
		if model_entry != null and model_entry.model_id == model_id:
			return model_entry.coding_evaluation_points
	return -1


func _model_reasoning(report: QuarterlyReportState, model_id: StringName) -> int:
	for model_entry: QuarterlyReportModelEntry in report.models:
		if model_entry != null and model_entry.model_id == model_id:
			return model_entry.reasoning_evaluation_points
	return -1


func _model_efficiency(report: QuarterlyReportState, model_id: StringName) -> int:
	for model_entry: QuarterlyReportModelEntry in report.models:
		if model_entry != null and model_entry.model_id == model_id:
			return model_entry.efficiency_evaluation_points
	return -1


func _application_entry(
		report: QuarterlyReportState,
		application_id: StringName
	) -> QuarterlyReportApplicationEntry:
	for application_entry: QuarterlyReportApplicationEntry in report.applications:
		if application_entry != null and application_entry.application_id == application_id:
			return application_entry
	return null


func _rule_order(trace: SimulationTrace) -> Array[StringName]:
	var rule_ids: Array[StringName] = []
	if trace == null:
		return rule_ids
	for record: SimulationTraceRecord in trace.get_records():
		var rule_record: RuleEvaluationTraceRecord = record as RuleEvaluationTraceRecord
		if rule_record != null:
			rule_ids.append(rule_record.rule_id)
	return rule_ids


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


func _finish() -> void:
	if _failure_count > 0:
		printerr("QUARTERLY_REPORT_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=10" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
