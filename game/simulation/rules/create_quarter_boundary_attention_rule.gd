class_name CreateQuarterBoundaryAttentionRule
extends SimulationRule

const RULE_ID: StringName = &"rule.time.create_quarter_boundary_attention"
const EVENT_TYPE_ID: StringName = &"attention_event.quarter_boundary"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Create Quarter Boundary Attention Event"
	phase_id = SimulationRulePhase.CREATE_ATTENTION_EVENTS
	execution_order = 10
	read_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.RUNTIME_EVENT_SEQUENCE,
		CanonicalSimulationStatePaths.ATTENTION_EVENTS,
	]
	write_state_paths = [
		CanonicalSimulationStatePaths.RUNTIME_EVENT_SEQUENCE,
		CanonicalSimulationStatePaths.ATTENTION_EVENTS,
	]
	emitted_event_ids = [TimeModelEventFactory.QUARTER_BOUNDARY_EVENT]
	graph_group_id = &"rule_group.time_model"
	specification_references = ["docs/simulation/time-model.md"]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	if month_result.value < 1 or month_result.value % 3 != 0:
		return SimulationRuleEvaluation.did_not_fire()
	var sequence_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.RUNTIME_EVENT_SEQUENCE
	)
	if not sequence_result.has_value:
		return SimulationRuleEvaluation.failed(sequence_result.diagnostic)
	var event: AttentionEventState = AttentionEventState.new()
	event.stable_id = StableIdentifier.format_runtime_identifier(&"event", sequence_result.value)
	event.event_type_id = EVENT_TYPE_ID
	if not context.write_integer(
		CanonicalSimulationStatePaths.RUNTIME_EVENT_SEQUENCE,
		sequence_result.value + 1
	):
		return _failed_from_context(context)
	var events: Array[AttentionEventState] = context.read_attention_events()
	if context.has_fault():
		return _failed_from_context(context)
	events.append(event)
	if not context.write_attention_events(events):
		return _failed_from_context(context)
	var payload: Dictionary[StringName, Variant] = {
		&"attention_event_id": event.stable_id,
		&"month_step_index": month_result.value,
	}
	if not context.emit_event(TimeModelEventFactory.QUARTER_BOUNDARY_EVENT, payload):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
