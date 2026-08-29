extends SceneTree

const TEST_SUCCESS: String = "RULE_GRAPH_TRACE_VIEW_TEST_SUCCESS"
const BUILD_LAB_ID: StringName = &"project.campus.build_laboratory"
const RESEARCH_ID: StringName = &"project.research.frontier_model"

var _failure_count: int = 0


func _initialize() -> void:
	var created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(created.succeeded(), "The trace-view laboratory session did not start:\n%s" % created.format_diagnostics())
	if not created.succeeded():
		_finish()
		return
	_verify_empty_plan_months(created.session)
	_verify_selected_month_mismatch(created.session)
	_verify_research_month_one()
	_finish()


func _verify_empty_plan_months(session: SimulationLabSession) -> void:
	session.commit_staged_plan()
	var advanced: SimulationOperationResult = session.advance_until_attention_required()
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The trace-view advance did not stop at the Attention Boundary."
	)
	var month_one: RuleGraphTraceViewResult = session.classify_trace_month(1, advanced.trace)
	_expect(month_one.succeeded(), "Month Step 1 classification failed:\n%s" % month_one.format_diagnostics())
	if month_one.succeeded():
		_expect(month_one.view.month_step_index == 1, "Month Step 1 view has the wrong Month Step.")
		_expect(
			_status(month_one.view, CreateQuarterBoundaryAttentionRule.RULE_ID)
			== SimulationRuleEvaluation.Status.DID_NOT_FIRE,
			"Month Step 1 classified the Quarter Boundary Rule as fired."
		)
		_expect(
			_status(month_one.view, OpenMonthStepRule.RULE_ID) == SimulationRuleEvaluation.Status.FIRED,
			"Month Step 1 did not classify Open Month Step as fired."
		)
		var open_view: RuleGraphTraceRuleView = month_one.view.get_rule_view(OpenMonthStepRule.RULE_ID)
		_expect(open_view != null and open_view.write_state_paths.size() >= 1, "Month Step 1 is missing Open Month Step writes.")
		if open_view != null and open_view.write_state_paths.size() >= 1:
			_expect(
				open_view.write_state_paths[0] == CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
				"Month Step 1 Open Month Step write path is incorrect."
			)
			_expect(open_view.write_has_before_values[0], "Month Step 1 Open Month Step is missing the before value.")
			_expect(open_view.write_has_after_values[0], "Month Step 1 Open Month Step is missing the after value.")
			_expect(open_view.write_before_values[0] == 0, "Month Step 1 Open Month Step before value is incorrect.")
			_expect(open_view.write_after_values[0] == 1, "Month Step 1 Open Month Step after value is incorrect.")
	var month_three: RuleGraphTraceViewResult = session.classify_trace_month(3)
	_expect(month_three.succeeded(), "Month Step 3 classification failed:\n%s" % month_three.format_diagnostics())
	if month_three.succeeded():
		_expect(month_three.view.month_step_index == 3, "Month Step 3 view has the wrong Month Step.")
		_expect(
			_status(month_three.view, CreateQuarterBoundaryAttentionRule.RULE_ID)
			== SimulationRuleEvaluation.Status.FIRED,
			"Month Step 3 did not classify the Quarter Boundary Rule as fired."
		)
		_expect(
			_status(month_three.view, ConsumePendingCommandBatchRule.RULE_ID)
			== SimulationRuleEvaluation.Status.DID_NOT_FIRE,
			"Month Step 3 classified consume-batch as fired."
		)
		_expect(
			_status(month_three.view, CloseMonthStepRule.RULE_ID) == SimulationRuleEvaluation.Status.FIRED,
			"Month Step 3 did not classify Close Month Step as fired."
		)


func _verify_selected_month_mismatch(session: SimulationLabSession) -> void:
	var mismatch: RuleGraphTraceViewResult = session.classify_trace_month(4)
	_expect(not mismatch.succeeded(), "Month Step 4 classification succeeded for a three-month trace.")
	if mismatch.diagnostics.is_empty():
		return
	_expect(
		mismatch.diagnostics[0].code == &"rule_graph_trace.month_step_mismatch",
		"The missing Month Step diagnostic is incorrect."
	)


func _verify_research_month_one() -> void:
	var created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(created.succeeded(), "The Research trace-view session did not start.")
	if not created.succeeded():
		return
	var session: SimulationLabSession = created.session
	session.stage_command(_build_lab_command(session.get_state(), 0))
	session.commit_staged_plan()
	var lab_result: SimulationOperationResult = session.step_month()
	_expect(lab_result.is_successful(), "The Build Laboratory Month Step failed.")
	session.stage_command(_research_command(session.get_state(), 0))
	session.commit_staged_plan()
	var month_one_result: SimulationOperationResult = session.step_month()
	_expect(month_one_result.is_successful(), "The Research Month Step 1 failed.")
	var classified: RuleGraphTraceViewResult = session.classify_trace_month(1, month_one_result.trace)
	_expect(classified.succeeded(), "Research Month Step 1 classification failed:\n%s" % classified.format_diagnostics())
	if not classified.succeeded():
		return
	_expect(
		_status(classified.view, PostCommittedProjectCostsRule.RULE_ID)
		== SimulationRuleEvaluation.Status.FIRED,
		"Research Month Step 1 did not classify Project cost posting as fired."
	)
	_expect(
		_status(classified.view, CreateQuarterBoundaryAttentionRule.RULE_ID)
		== SimulationRuleEvaluation.Status.DID_NOT_FIRE,
		"Research Month Step 1 classified the Quarter Boundary Rule as fired."
	)


func _status(view: RuleGraphTraceView, rule_id: StringName) -> SimulationRuleEvaluation.Status:
	var rule_view: RuleGraphTraceRuleView = view.get_rule_view(rule_id)
	if rule_view == null:
		return SimulationRuleEvaluation.Status.FAILED
	return rule_view.status


func _build_lab_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = BUILD_LAB_ID
	command.payload = payload
	return command


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


func _finish() -> void:
	if _failure_count > 0:
		printerr("RULE_GRAPH_TRACE_VIEW_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=3" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
