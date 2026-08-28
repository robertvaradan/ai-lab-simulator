class_name ConsumePendingCommandBatchRule
extends SimulationRule

const RULE_ID: StringName = &"rule.time.consume_pending_command_batch"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Consume Pending Command Batch"
	phase_id = SimulationRulePhase.CONSUME_PENDING_COMMAND_BATCH
	execution_order = 10
	read_state_paths = [CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH]
	write_state_paths = [CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH]
	graph_group_id = &"rule_group.time_model"
	specification_references = ["docs/simulation/time-model.md"]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var batch: PendingCommandBatchState = context.read_pending_command_batch()
	if context.has_fault():
		return _failed_from_context(context)
	if batch == null:
		return SimulationRuleEvaluation.did_not_fire()
	if not batch.consume_once():
		return SimulationRuleEvaluation.failed(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.time.pending_command_batch_already_consumed",
				"Pending Command Batch %s was already consumed." % batch.stable_id,
				stable_id,
				CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH
			)
		)
	if not context.write_pending_command_batch(null):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
