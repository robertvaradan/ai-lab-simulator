extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const TEST_SUCCESS: String = "MONTH_STEP_TEST_SUCCESS"

var _failure_count: int = 0
var _core_case_count: int = 0
var _host_case_count: int = 0


class FaultOnSecondMonthRule extends SimulationRule:
	func _init() -> void:
		stable_id = &"rule.test.fault_on_second_month"
		display_name = "Fault on second Month Step"
		phase_id = SimulationRulePhase.EVALUATE_LOSS_CONDITIONS
		execution_order = 10
		read_state_paths = [CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX]
		graph_group_id = &"rule_group.test"
		specification_references = ["docs/simulation/time-model.md"]

	func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
		var month_result: SimulationIntegerResult = context.read_integer(
			CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
		)
		if not month_result.has_value:
			return SimulationRuleEvaluation.failed(month_result.diagnostic)
		if month_result.value != 2:
			return SimulationRuleEvaluation.did_not_fire()
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.test.forced_month_two_fault",
				"The test Rule faulted Month Step 2.",
				stable_id,
				CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
			)
		)


class GameStateConsumer extends Node:
	var service: GameStateService
	var entered_with_service: bool = false

	func inject(game_state_service: GameStateService) -> void:
		service = game_state_service

	func _enter_tree() -> void:
		entered_with_service = service != null


class AdvanceHostContext extends ServiceContext:
	var definition: MarketingScenarioDefinition
	var initial_state: GameState
	var service: GameStateService
	var consumer: GameStateConsumer

	func _init(scenario_definition: MarketingScenarioDefinition, starting_state: GameState) -> void:
		definition = scenario_definition
		initial_state = starting_state
		consumer = GameStateConsumer.new()
		consumer.name = "AdvanceGameStateConsumer"
		add_child(consumer)

	func _register_services(provider: ServiceProvider) -> void:
		service = GameStateService.new(
			self,
			initial_state,
			definition.stable_id,
			definition.content_version,
			definition.rule_graph_id,
			definition.rule_graph_version,
			definition.build_content_reference_catalog()
		)
		provider.provide(GameStateService, service)

	func _inject_services(provider: ServiceProvider) -> void:
		var resolved_service: Service = provider.resolve(GameStateService)
		consumer.inject(resolved_service as GameStateService)


class PublicationListener extends RefCounted:
	var notification_count: int = 0
	var current_state: GameState
	var previous_state: GameState

	func on_game_state_changed(replacement: GameState, previous: GameState) -> void:
		notification_count += 1
		current_state = replacement
		previous_state = previous


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
		"The Month Step Simulation Core did not construct:\n%s" % construction.format_diagnostics()
	)
	if not construction.succeeded():
		_finish()
		return

	_verify_one_month_step(construction.core, state_result.state)
	_verify_pending_command_batch_consumed_once(construction.core, state_result.state)
	_verify_three_month_steps_stop_at_quarter_boundary(construction.core, state_result.state)
	_verify_advance_matches_month_step_pipeline(construction.core, state_result.state)
	_verify_unresolved_attention_rejects_time(construction.core, state_result.state)
	_core_case_count = 5
	if _failure_count > 0:
		_finish()
		return
	call_deferred("_run_host_tests", definition, state_result.state)


func _verify_one_month_step(core: SimulationCore, state: GameState) -> void:
	var input_before: PackedByteArray = var_to_bytes_with_objects(state)
	var result: SimulationOperationResult = core.step_month(state)
	_expect(result.outcome == SimulationOperationOutcome.Type.COMPLETED, "The first Month Step did not complete.")
	_expect(result.has_candidate_state(), "The first Month Step has no candidate Game State.")
	_expect(var_to_bytes_with_objects(state) == input_before, "step_month mutated its input Game State.")
	if not result.has_candidate_state():
		return
	_expect(result.candidate_state != state, "step_month returned its input Game State instance.")
	_expect(
		result.candidate_state.calendar.current_month_step_index == 1,
		"The first Month Step did not set month index 1."
	)
	_expect(
		result.candidate_state.calendar.current_quarter_index == 1,
		"The first Month Step changed the quarter index."
	)
	_expect(
		result.candidate_state.calendar.phase_id == &"calendar_state.planning",
		"The first Month Step left Planning State."
	)
	_expect(
		result.candidate_state.attention_events.is_empty(),
		"The first Month Step created an Attention Event."
	)
	_expect(
		result.candidate_state.quarterly_reports.size() == 1,
		"The first Month Step created an ending Quarterly Report."
	)
	_expect(
		result.candidate_state.pending_command_batch == null,
		"The first Month Step retained a Pending Command Batch."
	)
	_expect(result.trace != null and result.trace.is_sealed(), "The first Month Step did not seal its trace.")
	_expect(
		_rule_order(result.trace)
		== [
			OpenMonthStepRule.RULE_ID,
			ConsumePendingCommandBatchRule.RULE_ID,
			PostCommittedProjectCostsRule.RULE_ID,
			AdvanceActiveProjectsRule.RULE_ID,
			ResolveProjectCompletionsRule.RULE_ID,
			AdvanceCompetitorsRule.RULE_ID,
			PostOperatingCostRule.RULE_ID,
			PostComputeContractCostsRule.RULE_ID,
			PostApplicationRevenueRule.RULE_ID,
			CreateQuarterBoundaryAttentionRule.RULE_ID,
			CreateProjectCompletionNotificationRule.RULE_ID,
			CreateQuarterlyReportRule.RULE_ID,
			CloseMonthStepRule.RULE_ID,
		],
		"The Month Step pipeline did not use canonical Rule phase order."
	)


func _verify_pending_command_batch_consumed_once(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "An empty Plan did not commit.")
	if not commit.has_candidate_state():
		return
	_expect(commit.candidate_state.pending_command_batch != null, "commit_plan did not create a Pending Command Batch.")
	var first_month: SimulationOperationResult = core.step_month(commit.candidate_state)
	_expect(first_month.outcome == SimulationOperationOutcome.Type.COMPLETED, "The committed Plan Month Step did not complete.")
	if not first_month.has_candidate_state():
		return
	_expect(
		first_month.candidate_state.pending_command_batch == null,
		"The first Month Step after commit did not consume the Pending Command Batch."
	)
	var second_month: SimulationOperationResult = core.step_month(first_month.candidate_state)
	_expect(second_month.outcome == SimulationOperationOutcome.Type.COMPLETED, "The second Month Step did not complete.")
	if not second_month.has_candidate_state():
		return
	_expect(
		second_month.candidate_state.pending_command_batch == null,
		"A later Month Step restored a Pending Command Batch."
	)
	_expect(
		second_month.candidate_state.calendar.current_month_step_index == 2,
		"The second Month Step did not set month index 2."
	)


func _verify_three_month_steps_stop_at_quarter_boundary(core: SimulationCore, state: GameState) -> void:
	var month_one: SimulationOperationResult = core.step_month(state)
	_expect(month_one.has_candidate_state(), "The first Month Step in the Quarter Boundary sequence has no candidate.")
	if not month_one.has_candidate_state():
		return
	var month_two: SimulationOperationResult = core.step_month(month_one.candidate_state)
	_expect(month_two.has_candidate_state(), "The second Month Step in the Quarter Boundary sequence has no candidate.")
	if not month_two.has_candidate_state():
		return
	var month_three: SimulationOperationResult = core.step_month(month_two.candidate_state)
	_expect(
		month_three.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The third Month Step did not require a decision."
	)
	_expect(month_three.has_candidate_state(), "The Quarter Boundary result has no candidate Game State.")
	if not month_three.has_candidate_state():
		return
	_expect(
		month_three.candidate_state.calendar.current_month_step_index == 3,
		"The Quarter Boundary did not resolve Month Step 3."
	)
	_expect(
		month_three.candidate_state.calendar.current_quarter_index == 1,
		"The first Quarter Boundary changed the quarter index."
	)
	_expect(
		month_three.candidate_state.attention_events.size() == 1,
		"The Quarter Boundary did not create one Attention Event."
	)
	if month_three.candidate_state.attention_events.size() == 1:
		var event: AttentionEventState = month_three.candidate_state.attention_events[0]
		_expect(
			event.event_type_id == CreateQuarterBoundaryAttentionRule.EVENT_TYPE_ID,
			"The Quarter Boundary Attention Event has the wrong type."
		)
		_expect(
			event.stable_id == StableIdentifier.format_runtime_identifier(&"event", 1),
			"The Quarter Boundary Attention Event identifier is incorrect."
		)
	_expect(
		month_three.candidate_state.quarterly_reports.size() == 2,
		"The Quarter Boundary did not create the ending Quarterly Report."
	)
	if month_three.candidate_state.quarterly_reports.size() == 2:
		_expect(
			month_three.candidate_state.quarterly_reports[1].stable_id
			== StableIdentifier.format_runtime_identifier(&"quarterly_report", 1),
			"The ending Quarterly Report identifier is incorrect."
		)
	_expect(
		month_three.candidate_state.notifications.is_empty(),
		"The Quarter Boundary created a Notification."
	)


func _verify_advance_matches_month_step_pipeline(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.has_candidate_state(), "Advance pipeline commit has no candidate Game State.")
	if not commit.has_candidate_state():
		return
	_expect(
		commit.candidate_state.calendar.current_month_step_index == 0,
		"commit_plan advanced time."
	)
	var stepped: SimulationOperationResult = core.step_month(commit.candidate_state)
	_expect(stepped.has_candidate_state(), "The first compared Month Step has no candidate Game State.")
	if not stepped.has_candidate_state():
		return
	stepped = core.step_month(stepped.candidate_state)
	_expect(stepped.has_candidate_state(), "The second compared Month Step has no candidate Game State.")
	if not stepped.has_candidate_state():
		return
	stepped = core.step_month(stepped.candidate_state)
	var advanced: SimulationOperationResult = core.advance_until_attention_required(commit.candidate_state)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"advance_until_attention_required did not stop at the Quarter Boundary."
	)
	_expect(advanced.has_candidate_state(), "advance_until_attention_required has no candidate Game State.")
	if not advanced.has_candidate_state() or not stepped.has_candidate_state():
		return
	_expect(
		var_to_bytes_with_objects(advanced.candidate_state)
		== var_to_bytes_with_objects(stepped.candidate_state),
		"advance_until_attention_required did not use the same Month Step pipeline as step_month."
	)
	_expect(
		_rule_order(advanced.trace).size() == 39,
		"advance_until_attention_required did not run three Month Step pipelines."
	)


func _verify_unresolved_attention_rejects_time(core: SimulationCore, state: GameState) -> void:
	var boundary: SimulationOperationResult = core.advance_until_attention_required(state)
	_expect(
		boundary.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"Advance from Planning did not stop at the Quarter Boundary."
	)
	if not boundary.has_candidate_state():
		return
	var rejected_step: SimulationOperationResult = core.step_month(boundary.candidate_state)
	_expect(
		rejected_step.outcome == SimulationOperationOutcome.Type.REJECTED,
		"step_month accepted unresolved required input."
	)
	_expect(not rejected_step.has_candidate_state(), "A rejected step_month exposed candidate Game State.")
	_expect(
		_has_operation_diagnostic(rejected_step, &"simulation_core.unresolved_attention_events"),
		"The rejected step_month has the wrong diagnostic."
	)
	var rejected_advance: SimulationOperationResult = core.advance_until_attention_required(
		boundary.candidate_state
	)
	_expect(
		rejected_advance.outcome == SimulationOperationOutcome.Type.REJECTED,
		"advance_until_attention_required accepted unresolved required input."
	)
	_expect(
		not rejected_advance.has_candidate_state(),
		"A rejected advance_until_attention_required exposed candidate Game State."
	)


func _run_host_tests(definition: MarketingScenarioDefinition, state: GameState) -> void:
	_verify_host_advance_publishes_once(definition, state)
	_verify_faulted_advance_does_not_publish(definition, state)
	_host_case_count = 2
	_finish()


func _verify_host_advance_publishes_once(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var context: AdvanceHostContext = AdvanceHostContext.new(definition, _duplicate_state(state))
	root.add_child(context)
	_expect(context.consumer.entered_with_service, "GameStateService was not injected before consumer entry.")
	var listener: PublicationListener = PublicationListener.new()
	context.service.get_game_state_echo().game_state_changed.connect(listener.on_game_state_changed)
	var construction: SimulationCoreConstructionResult = MarketingScenarioFactory.create_core(
		definition,
		context.service.get_current_state()
	)
	_expect(construction.succeeded(), "The Host Advance Simulation Core did not construct.")
	if not construction.succeeded():
		context.queue_free()
		return
	var action: SimulationAdvanceAction = SimulationAdvanceAction.new(construction.core, context.service)
	var result: SimulationOperationResult = action.execute(Plan.new())
	_expect(
		result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The production Advance action did not stop at the Quarter Boundary."
	)
	_expect(listener.notification_count == 1, "The production Advance action did not emit one Game State change.")
	_expect(result.has_candidate_state(), "The production Advance action has no candidate Game State.")
	if result.has_candidate_state():
		_expect(
			context.service.get_current_state() == result.candidate_state,
			"The production Advance action did not publish its final candidate Game State."
		)
		_expect(
			context.service.get_current_state().calendar.current_month_step_index == 3,
			"The published Advance Game State is not the Quarter Boundary."
		)
		_expect(
			context.service.get_current_state().pending_command_batch == null,
			"The published Advance Game State retained the committed Plan candidate batch."
		)
	var traces: Array[SimulationTrace] = action.get_session_traces()
	_expect(traces.size() == 2, "The production Advance action did not retain commit then advancement traces.")
	if traces.size() == 2:
		_expect(
			traces[0].operation_id == SimulationCore.COMMIT_PLAN_OPERATION_ID,
			"The first retained trace is not the Plan commitment trace."
		)
		_expect(
			traces[1].operation_id == SimulationCore.ADVANCE_UNTIL_ATTENTION_REQUIRED_OPERATION_ID,
			"The second retained trace is not the advancement trace."
		)
	context.queue_free()


func _verify_faulted_advance_does_not_publish(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var context: AdvanceHostContext = AdvanceHostContext.new(definition, _duplicate_state(state))
	root.add_child(context)
	var listener: PublicationListener = PublicationListener.new()
	context.service.get_game_state_echo().game_state_changed.connect(listener.on_game_state_changed)
	var rule_registry: SimulationRuleRegistry = TimeModelRuleFactory.create_registry()
	rule_registry.register_rule(FaultOnSecondMonthRule.new())
	var construction: SimulationCoreConstructionResult = SimulationCore.create(
		rule_registry,
		definition.build_content_registry(),
		CanonicalSimulationStatePaths.create_registry(),
		TimeModelEventFactory.create_registry(),
		definition.rule_graph_id,
		definition.rule_graph_version,
		context.service.get_current_state()
	)
	_expect(construction.succeeded(), "The faulted Advance Simulation Core did not construct.")
	if not construction.succeeded():
		context.queue_free()
		return
	var starting_state: GameState = context.service.get_current_state()
	var action: SimulationAdvanceAction = SimulationAdvanceAction.new(construction.core, context.service)
	var result: SimulationOperationResult = action.execute(Plan.new())
	_expect(result.outcome == SimulationOperationOutcome.Type.FAULTED, "A faulted Advance operation did not fault.")
	_expect(not result.has_candidate_state(), "A faulted Advance operation returned a candidate Game State.")
	_expect(listener.notification_count == 0, "A faulted Advance operation published Game State.")
	_expect(
		context.service.get_current_state() == starting_state,
		"A faulted Advance operation replaced the committed Game State."
	)
	context.queue_free()


func _rule_order(trace: SimulationTrace) -> Array[StringName]:
	var rule_ids: Array[StringName] = []
	if trace == null:
		return rule_ids
	for record: SimulationTraceRecord in trace.get_records():
		var rule_record: RuleEvaluationTraceRecord = record as RuleEvaluationTraceRecord
		if rule_record != null:
			rule_ids.append(rule_record.rule_id)
	return rule_ids


func _has_operation_diagnostic(result: SimulationOperationResult, code: StringName) -> bool:
	for diagnostic: SimulationDiagnostic in result.diagnostics:
		if diagnostic.code == code:
			return true
	return false


func _duplicate_state(state: GameState) -> GameState:
	var duplicated_resource: Resource = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if duplicated_resource is GameState:
		return duplicated_resource
	_expect(false, "The test could not deep-copy Game State.")
	return null


func _finish() -> void:
	if _failure_count > 0:
		printerr("MONTH_STEP_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=%d" % [TEST_SUCCESS, _core_case_count + _host_case_count])
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
