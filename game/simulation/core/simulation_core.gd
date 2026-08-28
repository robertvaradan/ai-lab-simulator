class_name SimulationCore
extends RefCounted

const INTERNAL_OPERATION_ID: StringName = &"operation.internal.compiled_rule_pipeline"
const COMMIT_PLAN_OPERATION_ID: StringName = &"operation.plan.commit"
const STEP_MONTH_OPERATION_ID: StringName = &"operation.time.step_month"
const ADVANCE_UNTIL_ATTENTION_REQUIRED_OPERATION_ID: StringName = (
	&"operation.time.advance_until_attention_required"
)

var _rule_registry: SimulationRuleRegistry
var _content_registry: SimulationContentRegistry
var _state_path_registry: SimulationStatePathRegistry
var _event_registry: SimulationEventRegistry
var _compiled_graph: CompiledRuleGraph
var _pinned_scenario_id: StringName
var _pinned_content_version: int
var _pinned_graph_id: StringName
var _pinned_graph_version: int
var _pinned_content_catalog: Dictionary[StringName, bool] = {}


func _init(
		rule_registry: SimulationRuleRegistry,
		content_registry: SimulationContentRegistry,
		state_path_registry: SimulationStatePathRegistry,
		event_registry: SimulationEventRegistry,
		compiled_graph: CompiledRuleGraph
	) -> void:
	_rule_registry = rule_registry
	_content_registry = content_registry
	_state_path_registry = state_path_registry
	_event_registry = event_registry
	_compiled_graph = compiled_graph
	_pinned_scenario_id = content_registry.scenario_id
	_pinned_content_version = content_registry.content_version
	_pinned_graph_id = compiled_graph.graph_id
	_pinned_graph_version = compiled_graph.graph_version
	_pinned_content_catalog.assign(content_registry.build_content_catalog())


static func create(
		rule_registry: SimulationRuleRegistry,
		content_registry: SimulationContentRegistry,
		state_path_registry: SimulationStatePathRegistry,
		event_registry: SimulationEventRegistry,
		graph_id: StringName,
		graph_version: int,
		initial_state: GameState
	) -> SimulationCoreConstructionResult:
	var result: SimulationCoreConstructionResult = SimulationCoreConstructionResult.new()
	if rule_registry == null:
		_add_construction_error(result, &"simulation_core.missing_rule_registry", "The Rule registry is missing.")
	if content_registry == null:
		_add_construction_error(result, &"simulation_core.missing_content_registry", "The content registry is missing.")
	if state_path_registry == null:
		_add_construction_error(
			result,
			&"simulation_core.missing_state_path_registry",
			"The state-path registry is missing."
		)
	if event_registry == null:
		_add_construction_error(result, &"simulation_core.missing_event_registry", "The event registry is missing.")
	if not result.diagnostics.is_empty():
		return result

	rule_registry.seal()
	content_registry.seal()
	state_path_registry.seal()
	event_registry.seal()
	result.diagnostics.append_array(content_registry.get_diagnostics())
	if not StableIdentifier.is_valid(content_registry.scenario_id):
		_add_construction_error(
			result,
			&"simulation_core.invalid_scenario_id",
			"Content registry Scenario identifier %s is invalid." % content_registry.scenario_id
		)
	if content_registry.content_version < 1:
		_add_construction_error(
			result,
			&"simulation_core.invalid_content_version",
			"The content registry version must be positive."
		)
	if content_registry.build_content_catalog().is_empty():
		_add_construction_error(
			result,
			&"simulation_core.empty_content_registry",
			"The content registry is empty."
		)
	var graph_result: RuleGraphCompilationResult = SimulationRuleGraphCompiler.compile_rule_graph(
		rule_registry,
		state_path_registry,
		event_registry,
		graph_id,
		graph_version,
		content_registry.content_version
	)
	result.diagnostics.append_array(graph_result.diagnostics)
	if graph_result.graph == null or not result.diagnostics.is_empty():
		return result
	var state_validation: GameStateValidationResult = GameStateValidator.validate(
		initial_state,
		content_registry.scenario_id,
		content_registry.content_version,
		graph_id,
		graph_version,
		content_registry.build_content_catalog()
	)
	if not state_validation.is_valid():
		for validation_error: String in state_validation.errors:
			_add_construction_error(
				result,
				&"simulation_core.invalid_initial_state",
				validation_error
			)
		return result
	result.core = SimulationCore.new(
		rule_registry,
		content_registry,
		state_path_registry,
		event_registry,
		graph_result.graph
	)
	return result


# This is the canonical internal Rule pipeline seam. Public Simulation Host operations must wrap it.
func _execute_compiled_rules(input_state: GameState, random_seed: int) -> SimulationOperationResult:
	var trace: SimulationTrace = SimulationTrace.new(INTERNAL_OPERATION_ID, random_seed)
	var input_diagnostics: Array[SimulationDiagnostic] = _input_state_diagnostics(input_state)
	if not input_diagnostics.is_empty():
		return _faulted_result(trace, input_diagnostics)
	var candidate_state: GameState = _copy_state(input_state)
	if candidate_state == null:
		return _faulted_result(trace, [_state_copy_failed_diagnostic()])
	var rule_diagnostics: Array[SimulationDiagnostic] = _evaluate_compiled_rules(
		candidate_state,
		trace,
		random_seed
	)
	if not rule_diagnostics.is_empty():
		return _faulted_result(trace, rule_diagnostics)
	var candidate_diagnostics: Array[SimulationDiagnostic] = _candidate_state_diagnostics(candidate_state)
	if not candidate_diagnostics.is_empty():
		return _faulted_result(trace, candidate_diagnostics)
	return SimulationOperationResult.new(
		SimulationOperationOutcome.Type.COMPLETED,
		candidate_state,
		trace,
		[]
	)


func step_month(state: GameState) -> SimulationOperationResult:
	var trace: SimulationTrace = SimulationTrace.new(STEP_MONTH_OPERATION_ID, 0)
	var input_diagnostics: Array[SimulationDiagnostic] = _input_state_diagnostics(state)
	if not input_diagnostics.is_empty():
		return _faulted_result(trace, input_diagnostics)
	if _has_unresolved_attention(state):
		return _rejected_unresolved_attention(trace)
	var candidate_state: GameState = _copy_state(state)
	if candidate_state == null:
		return _faulted_result(trace, [_state_copy_failed_diagnostic()])
	var month_diagnostics: Array[SimulationDiagnostic] = _apply_month_step(candidate_state, trace, 0)
	if not month_diagnostics.is_empty():
		return _faulted_result(trace, month_diagnostics)
	return _month_step_success_result(candidate_state, trace)


func advance_until_attention_required(state: GameState) -> SimulationOperationResult:
	var trace: SimulationTrace = SimulationTrace.new(ADVANCE_UNTIL_ATTENTION_REQUIRED_OPERATION_ID, 0)
	var input_diagnostics: Array[SimulationDiagnostic] = _input_state_diagnostics(state)
	if not input_diagnostics.is_empty():
		return _faulted_result(trace, input_diagnostics)
	if _has_unresolved_attention(state):
		return _rejected_unresolved_attention(trace)
	var candidate_state: GameState = _copy_state(state)
	if candidate_state == null:
		return _faulted_result(trace, [_state_copy_failed_diagnostic()])
	while not _has_unresolved_attention(candidate_state):
		var month_diagnostics: Array[SimulationDiagnostic] = _apply_month_step(candidate_state, trace, 0)
		if not month_diagnostics.is_empty():
			return _faulted_result(trace, month_diagnostics)
	return _month_step_success_result(candidate_state, trace)


func get_compiled_graph() -> CompiledRuleGraph:
	return _compiled_graph


func validate_plan(state: GameState, plan: Plan) -> PlanValidationResult:
	var result: PlanValidationResult = PlanValidationResult.new()
	var input_validation: GameStateValidationResult = _validate_state(state)
	if not input_validation.is_valid():
		for validation_error: String in input_validation.errors:
			result._add_fault(
				&"simulation_core.invalid_input_state",
				validation_error
			)
		return result
	return PlanValidator.validate(state, plan, _content_registry)


func commit_plan(state: GameState, plan: Plan) -> SimulationOperationResult:
	var trace: SimulationTrace = SimulationTrace.new(COMMIT_PLAN_OPERATION_ID, 0)
	var plan_validation: PlanValidationResult = validate_plan(state, plan)
	if not plan_validation.is_valid():
		var rejected_outcome: SimulationOperationOutcome.Type = (
			SimulationOperationOutcome.Type.FAULTED
			if plan_validation.has_contract_fault()
			else SimulationOperationOutcome.Type.REJECTED
		)
		return SimulationOperationResult.new(
			rejected_outcome,
			null,
			trace,
			plan_validation.diagnostics
		)

	var duplicated_resource: Resource = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if not duplicated_resource is GameState:
		var copy_diagnostics: Array[SimulationDiagnostic] = [
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"simulation_core.state_copy_failed",
				"The input Game State did not create a Game State deep copy."
			),
		]
		return SimulationOperationResult.new(
			SimulationOperationOutcome.Type.FAULTED,
			null,
			trace,
			copy_diagnostics
		)
	var candidate_state: GameState = duplicated_resource
	var next_batch_sequence: int = (
		candidate_state.runtime_id_counters.next_sequence_by_entity_type[&"command_batch"]
	)
	var batch_id: StringName = StableIdentifier.format_runtime_identifier(
		&"command_batch",
		next_batch_sequence
	)
	var batch: PendingCommandBatchState = PendingCommandBatchState.create_committed(
		batch_id,
		plan.commands
	)
	if batch == null:
		var batch_diagnostics: Array[SimulationDiagnostic] = [
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"simulation_core.pending_command_batch_creation_failed",
				"The valid Plan did not create a Pending Command Batch."
			),
		]
		return SimulationOperationResult.new(
			SimulationOperationOutcome.Type.FAULTED,
			null,
			trace,
			batch_diagnostics
		)
	candidate_state.pending_command_batch = batch
	candidate_state.attention_events.clear()
	var next_counters: Dictionary[StringName, int] = {}
	next_counters.assign(candidate_state.runtime_id_counters.next_sequence_by_entity_type)
	next_counters[&"command_batch"] = next_batch_sequence + 1
	next_counters[&"command"] = next_counters[&"command"] + plan.commands.size()
	candidate_state.runtime_id_counters.next_sequence_by_entity_type = next_counters

	var candidate_validation: GameStateValidationResult = _validate_state(candidate_state)
	if not candidate_validation.is_valid():
		var candidate_diagnostics: Array[SimulationDiagnostic] = []
		for validation_error: String in candidate_validation.errors:
			candidate_diagnostics.append(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"simulation_core.invalid_candidate_state",
					validation_error
				)
			)
		return SimulationOperationResult.new(
			SimulationOperationOutcome.Type.FAULTED,
			null,
			trace,
			candidate_diagnostics
		)

	var command_ids: Array[StringName] = []
	for command: Command in plan.commands:
		command_ids.append(command.stable_id)
	var resolved_attention_event_ids: Array[StringName] = []
	for event: AttentionEventState in state.attention_events:
		resolved_attention_event_ids.append(event.stable_id)
	trace._append_plan_commitment(batch_id, command_ids, resolved_attention_event_ids)
	var diagnostics: Array[SimulationDiagnostic] = []
	return SimulationOperationResult.new(
		SimulationOperationOutcome.Type.COMPLETED,
		candidate_state,
		trace,
		diagnostics
	)


func _validate_state(state: GameState) -> GameStateValidationResult:
	return GameStateValidator.validate(
		state,
		_pinned_scenario_id,
		_pinned_content_version,
		_pinned_graph_id,
		_pinned_graph_version,
		_pinned_content_catalog
	)


func _evaluate_compiled_rules(
		candidate_state: GameState,
		trace: SimulationTrace,
		random_seed: int
	) -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	var context: SimulationContext = SimulationContext.new(
		candidate_state,
		_state_path_registry,
		_event_registry,
		trace,
		random_seed
	)
	for rule: SimulationRule in _compiled_graph.ordered_rules:
		var rule_record: RuleEvaluationTraceRecord = context._begin_rule(rule)
		var evaluation: SimulationRuleEvaluation = rule.evaluate(context)
		if evaluation == null:
			diagnostics.append(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"simulation_core.missing_rule_evaluation",
					"Rule %s returned a missing evaluation." % rule.stable_id,
					rule.stable_id
				)
			)
			rule_record._set_status(SimulationRuleEvaluation.Status.FAILED)
			context._end_rule()
			return diagnostics
		rule_record._set_status(evaluation.status)
		if evaluation.status == SimulationRuleEvaluation.Status.FAILED and evaluation.diagnostic != null:
			diagnostics.append(evaluation.diagnostic)
		if context.has_fault():
			rule_record._set_status(SimulationRuleEvaluation.Status.FAILED)
			diagnostics.append_array(context.get_diagnostics())
		context._end_rule()
		if rule_record.status == SimulationRuleEvaluation.Status.FAILED:
			if diagnostics.is_empty():
				diagnostics.append(
					SimulationDiagnostic.new(
						SimulationDiagnostic.Severity.ERROR,
						&"simulation_core.rule_failed_without_diagnostic",
						"Rule %s failed without a diagnostic." % rule.stable_id,
						rule.stable_id
					)
				)
			return diagnostics
	return diagnostics


func _apply_month_step(
		candidate_state: GameState,
		trace: SimulationTrace,
		random_seed: int
	) -> Array[SimulationDiagnostic]:
	var before_month_index: int = candidate_state.calendar.current_month_step_index
	var rule_diagnostics: Array[SimulationDiagnostic] = _evaluate_compiled_rules(
		candidate_state,
		trace,
		random_seed
	)
	if not rule_diagnostics.is_empty():
		return rule_diagnostics
	var candidate_diagnostics: Array[SimulationDiagnostic] = _candidate_state_diagnostics(candidate_state)
	if not candidate_diagnostics.is_empty():
		return candidate_diagnostics
	var after_month_index: int = candidate_state.calendar.current_month_step_index
	if after_month_index != before_month_index + 1:
		return [
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"simulation_core.month_step_index_not_incremented",
				"Month Step index changed from %d to %d." % [before_month_index, after_month_index]
			),
		]
	if after_month_index % 3 == 0 and candidate_state.attention_events.is_empty():
		return [
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"simulation_core.quarter_boundary_attention_missing",
				"Month Step %d did not create a Quarter Boundary Attention Event." % after_month_index
			),
		]
	return []


func _month_step_success_result(
		candidate_state: GameState,
		trace: SimulationTrace
	) -> SimulationOperationResult:
	var outcome: SimulationOperationOutcome.Type = (
		SimulationOperationOutcome.Type.DECISION_REQUIRED
		if _has_unresolved_attention(candidate_state)
		else SimulationOperationOutcome.Type.COMPLETED
	)
	return SimulationOperationResult.new(outcome, candidate_state, trace, [])


func _has_unresolved_attention(state: GameState) -> bool:
	return not state.attention_events.is_empty()


func _rejected_unresolved_attention(trace: SimulationTrace) -> SimulationOperationResult:
	var diagnostics: Array[SimulationDiagnostic] = [
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"simulation_core.unresolved_attention_events",
			"Time progression cannot start while required input is unresolved."
		),
	]
	return SimulationOperationResult.new(
		SimulationOperationOutcome.Type.REJECTED,
		null,
		trace,
		diagnostics
	)


func _input_state_diagnostics(state: GameState) -> Array[SimulationDiagnostic]:
	return _validation_diagnostics(_validate_state(state), &"simulation_core.invalid_input_state")


func _candidate_state_diagnostics(state: GameState) -> Array[SimulationDiagnostic]:
	return _validation_diagnostics(_validate_state(state), &"simulation_core.invalid_candidate_state")


func _validation_diagnostics(
		validation: GameStateValidationResult,
		code: StringName
	) -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	if validation.is_valid():
		return diagnostics
	for validation_error: String in validation.errors:
		diagnostics.append(
			SimulationDiagnostic.new(SimulationDiagnostic.Severity.ERROR, code, validation_error)
		)
	return diagnostics


func _copy_state(state: GameState) -> GameState:
	var duplicated_resource: Resource = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if duplicated_resource is GameState:
		return duplicated_resource
	return null


func _state_copy_failed_diagnostic() -> SimulationDiagnostic:
	return SimulationDiagnostic.new(
		SimulationDiagnostic.Severity.ERROR,
		&"simulation_core.state_copy_failed",
		"The input Game State did not create a Game State deep copy."
	)


func _faulted_result(
		trace: SimulationTrace,
		diagnostics: Array[SimulationDiagnostic]
	) -> SimulationOperationResult:
	return SimulationOperationResult.new(
		SimulationOperationOutcome.Type.FAULTED,
		null,
		trace,
		diagnostics
	)


static func _add_construction_error(
		result: SimulationCoreConstructionResult,
		code: StringName,
		message: String
	) -> void:
	result.diagnostics.append(
		SimulationDiagnostic.new(SimulationDiagnostic.Severity.ERROR, code, message)
	)
