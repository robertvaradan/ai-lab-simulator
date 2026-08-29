class_name SimulationContext
extends RefCounted

const CASH_LEDGER_PATH: StringName = &"state.cash_ledger.transactions"

var _candidate_state: GameState
var _state_path_registry: SimulationStatePathRegistry
var _event_registry: SimulationEventRegistry
var _content_registry: SimulationContentRegistry
var _trace: SimulationTrace
var _random: RandomNumberGenerator
var _current_rule: SimulationRule
var _declared_reads: Dictionary[StringName, bool] = {}
var _declared_writes: Dictionary[StringName, bool] = {}
var _declared_events: Dictionary[StringName, bool] = {}
var _declared_conditions: Dictionary[StringName, bool] = {}
var _diagnostics: Array[SimulationDiagnostic] = []


func _init(
		candidate_state: GameState,
		state_path_registry: SimulationStatePathRegistry,
		event_registry: SimulationEventRegistry,
		content_registry: SimulationContentRegistry,
		trace: SimulationTrace,
		random_seed: int
	) -> void:
	_candidate_state = candidate_state
	_state_path_registry = state_path_registry
	_event_registry = event_registry
	_content_registry = content_registry
	_trace = trace
	_random = RandomNumberGenerator.new()
	_random.seed = random_seed


func _begin_rule(rule: SimulationRule) -> RuleEvaluationTraceRecord:
	_current_rule = rule
	_declared_reads.clear()
	_declared_writes.clear()
	_declared_events.clear()
	_declared_conditions.clear()
	for path_id: StringName in rule.read_state_paths:
		_declared_reads[path_id] = true
	for path_id: StringName in rule.write_state_paths:
		_declared_writes[path_id] = true
	for event_id: StringName in rule.emitted_event_ids:
		_declared_events[event_id] = true
	for condition_id: StringName in rule.condition_ids:
		_declared_conditions[condition_id] = true
	return _trace._begin_rule(rule.stable_id)


func _end_rule() -> void:
	_current_rule = null
	_declared_reads.clear()
	_declared_writes.clear()
	_declared_events.clear()
	_declared_conditions.clear()


func read_integer(state_path: StringName) -> SimulationIntegerResult:
	var rule_id: StringName = _current_rule_id()
	if not _require_current_rule(state_path):
		_trace._append_read(rule_id, state_path, false)
		return SimulationIntegerResult.failure(_diagnostics[_diagnostics.size() - 1])
	if not _declared_reads.has(state_path):
		var undeclared_diagnostic: SimulationDiagnostic = _fault(
			&"context.undeclared_read",
			"Rule %s read undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return SimulationIntegerResult.failure(undeclared_diagnostic)
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null:
		var unknown_diagnostic: SimulationDiagnostic = _fault(
			&"context.unknown_read_path",
			"Rule %s read unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return SimulationIntegerResult.failure(unknown_diagnostic)
	if path.value_type != SimulationStatePath.ValueType.INTEGER:
		var type_diagnostic: SimulationDiagnostic = _fault(
			&"context.read_type_mismatch",
			"Rule %s used integer access for state path %s with a different type."
			% [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return SimulationIntegerResult.failure(type_diagnostic)
	var result: SimulationIntegerResult = path.read_integer(_candidate_state)
	if not result.has_value:
		var access_diagnostic: SimulationDiagnostic = _fault(
			&"context.read_failed",
			"Rule %s could not read state path %s. %s"
			% [rule_id, state_path, result.diagnostic.message],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return SimulationIntegerResult.failure(access_diagnostic)
	_trace._append_read(rule_id, state_path, true, true, result.value)
	return result


func write_integer(state_path: StringName, value: int) -> bool:
	var rule_id: StringName = _current_rule_id()
	if not _require_current_rule(state_path):
		_trace._append_write(rule_id, state_path, false)
		return false
	if not _declared_writes.has(state_path):
		_fault(
			&"context.undeclared_write",
			"Rule %s wrote undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null:
		_fault(
			&"context.unknown_write_path",
			"Rule %s wrote unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	if path.value_type != SimulationStatePath.ValueType.INTEGER:
		_fault(
			&"context.write_type_mismatch",
			"Rule %s used integer access for state path %s with a different type."
			% [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var before_result: SimulationIntegerResult = path.read_integer(_candidate_state)
	if not before_result.has_value:
		_fault(
			&"context.write_read_before_failed",
			"Rule %s could not read state path %s before its write."
			% [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var write_diagnostic: SimulationDiagnostic = path.write_integer(_candidate_state, value)
	if write_diagnostic != null:
		_fault(
			&"context.write_failed",
			"Rule %s could not write state path %s. %s"
			% [rule_id, state_path, write_diagnostic.message],
			state_path
		)
		_trace._append_write(rule_id, state_path, false, true, before_result.value)
		return false
	_trace._append_write(rule_id, state_path, true, true, before_result.value, true, value)
	return true


func read_pending_command_batch() -> PendingCommandBatchState:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH
	if not _require_current_rule(state_path):
		_trace._append_read(rule_id, state_path, false)
		return null
	if not _declared_reads.has(state_path):
		_fault(
			&"context.undeclared_read",
			"Rule %s read undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return null
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.PENDING_COMMAND_BATCH:
		_fault(
			&"context.unknown_read_path",
			"Rule %s read unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return null
	var batch: PendingCommandBatchState = path.read_pending_command_batch(_candidate_state)
	_trace._append_read(rule_id, state_path, true, true, 0 if batch == null else 1)
	return batch


func write_pending_command_batch(batch: PendingCommandBatchState) -> bool:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.PENDING_COMMAND_BATCH
	if not _require_current_rule(state_path):
		_trace._append_write(rule_id, state_path, false)
		return false
	if not _declared_writes.has(state_path):
		_fault(
			&"context.undeclared_write",
			"Rule %s wrote undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.PENDING_COMMAND_BATCH:
		_fault(
			&"context.unknown_write_path",
			"Rule %s wrote unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var before_batch: PendingCommandBatchState = path.read_pending_command_batch(_candidate_state)
	var write_diagnostic: SimulationDiagnostic = path.write_pending_command_batch(
		_candidate_state,
		batch
	)
	if write_diagnostic != null:
		_fault(
			&"context.write_failed",
			"Rule %s could not write state path %s. %s"
			% [rule_id, state_path, write_diagnostic.message],
			state_path
		)
		_trace._append_write(rule_id, state_path, false, true, 0 if before_batch == null else 1)
		return false
	_trace._append_write(
		rule_id,
		state_path,
		true,
		true,
		0 if before_batch == null else 1,
		true,
		0 if batch == null else 1
	)
	return true


func read_attention_events() -> Array[AttentionEventState]:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.ATTENTION_EVENTS
	var events: Array[AttentionEventState] = []
	if not _require_current_rule(state_path):
		_trace._append_read(rule_id, state_path, false)
		return events
	if not _declared_reads.has(state_path):
		_fault(
			&"context.undeclared_read",
			"Rule %s read undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return events
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.ATTENTION_EVENTS:
		_fault(
			&"context.unknown_read_path",
			"Rule %s read unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return events
	events = path.read_attention_events(_candidate_state)
	_trace._append_read(rule_id, state_path, true, true, events.size())
	return events


func write_attention_events(events: Array[AttentionEventState]) -> bool:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.ATTENTION_EVENTS
	if not _require_current_rule(state_path):
		_trace._append_write(rule_id, state_path, false)
		return false
	if not _declared_writes.has(state_path):
		_fault(
			&"context.undeclared_write",
			"Rule %s wrote undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.ATTENTION_EVENTS:
		_fault(
			&"context.unknown_write_path",
			"Rule %s wrote unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var before_events: Array[AttentionEventState] = path.read_attention_events(_candidate_state)
	var write_diagnostic: SimulationDiagnostic = path.write_attention_events(_candidate_state, events)
	if write_diagnostic != null:
		_fault(
			&"context.write_failed",
			"Rule %s could not write state path %s. %s"
			% [rule_id, state_path, write_diagnostic.message],
			state_path
		)
		_trace._append_write(rule_id, state_path, false, true, before_events.size())
		return false
	_trace._append_write(
		rule_id,
		state_path,
		true,
		true,
		before_events.size(),
		true,
		events.size()
	)
	return true


func read_notifications() -> Array[NotificationState]:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.NOTIFICATIONS
	var notifications: Array[NotificationState] = []
	if not _require_current_rule(state_path):
		_trace._append_read(rule_id, state_path, false)
		return notifications
	if not _declared_reads.has(state_path):
		_fault(
			&"context.undeclared_read",
			"Rule %s read undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return notifications
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.NOTIFICATIONS:
		_fault(
			&"context.unknown_read_path",
			"Rule %s read unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return notifications
	notifications = path.read_notifications(_candidate_state)
	_trace._append_read(rule_id, state_path, true, true, notifications.size())
	return notifications


func read_quarterly_reports() -> Array[QuarterlyReportState]:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.QUARTERLY_REPORTS
	var reports: Array[QuarterlyReportState] = []
	if not _require_current_rule(state_path):
		_trace._append_read(rule_id, state_path, false)
		return reports
	if not _declared_reads.has(state_path):
		_fault(
			&"context.undeclared_read",
			"Rule %s read undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return reports
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.QUARTERLY_REPORTS:
		_fault(
			&"context.unknown_read_path",
			"Rule %s read unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return reports
	reports = path.read_quarterly_reports(_candidate_state)
	_trace._append_read(rule_id, state_path, true, true, reports.size())
	return reports


func write_quarterly_reports(reports: Array[QuarterlyReportState]) -> bool:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.QUARTERLY_REPORTS
	if not _require_current_rule(state_path):
		_trace._append_write(rule_id, state_path, false)
		return false
	if not _declared_writes.has(state_path):
		_fault(
			&"context.undeclared_write",
			"Rule %s wrote undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.QUARTERLY_REPORTS:
		_fault(
			&"context.unknown_write_path",
			"Rule %s wrote unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var before_reports: Array[QuarterlyReportState] = path.read_quarterly_reports(_candidate_state)
	var write_diagnostic: SimulationDiagnostic = path.write_quarterly_reports(_candidate_state, reports)
	if write_diagnostic != null:
		_fault(
			&"context.write_failed",
			"Rule %s could not write state path %s. %s"
			% [rule_id, state_path, write_diagnostic.message],
			state_path
		)
		_trace._append_write(rule_id, state_path, false, true, before_reports.size())
		return false
	_trace._append_write(
		rule_id,
		state_path,
		true,
		true,
		before_reports.size(),
		true,
		reports.size()
	)
	return true


func read_cash_ledger() -> CashLedgerState:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.CASH_LEDGER_TRANSACTIONS
	if not _require_current_rule(state_path):
		_trace._append_read(rule_id, state_path, false)
		return null
	if not _declared_reads.has(state_path):
		_fault(
			&"context.undeclared_read",
			"Rule %s read undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return null
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.CASH_LEDGER:
		_fault(
			&"context.unknown_read_path",
			"Rule %s read unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return null
	var ledger: CashLedgerState = path.read_cash_ledger(_candidate_state)
	_trace._append_read(
		rule_id,
		state_path,
		true,
		true,
		0 if ledger == null else ledger.transactions.size()
	)
	return ledger


func get_candidate_state_for_report() -> GameState:
	if not _require_current_rule():
		return null
	if not _declared_writes.has(CanonicalSimulationStatePaths.QUARTERLY_REPORTS):
		_fault(
			&"context.undeclared_write",
			"Rule %s requested candidate Game State for a Quarterly Report without a report write."
			% _current_rule_id(),
			CanonicalSimulationStatePaths.QUARTERLY_REPORTS
		)
		return null
	return _candidate_state


func write_notifications(notifications: Array[NotificationState]) -> bool:
	var rule_id: StringName = _current_rule_id()
	var state_path: StringName = CanonicalSimulationStatePaths.NOTIFICATIONS
	if not _require_current_rule(state_path):
		_trace._append_write(rule_id, state_path, false)
		return false
	if not _declared_writes.has(state_path):
		_fault(
			&"context.undeclared_write",
			"Rule %s wrote undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.NOTIFICATIONS:
		_fault(
			&"context.unknown_write_path",
			"Rule %s wrote unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var before_notifications: Array[NotificationState] = path.read_notifications(_candidate_state)
	var write_diagnostic: SimulationDiagnostic = path.write_notifications(_candidate_state, notifications)
	if write_diagnostic != null:
		_fault(
			&"context.write_failed",
			"Rule %s could not write state path %s. %s"
			% [rule_id, state_path, write_diagnostic.message],
			state_path
		)
		_trace._append_write(rule_id, state_path, false, true, before_notifications.size())
		return false
	_trace._append_write(
		rule_id,
		state_path,
		true,
		true,
		before_notifications.size(),
		true,
		notifications.size()
	)
	return true


func read_resource_dictionary(state_path: StringName) -> Dictionary:
	var resources: Dictionary = {}
	var rule_id: StringName = _current_rule_id()
	if not _require_current_rule(state_path):
		_trace._append_read(rule_id, state_path, false)
		return resources
	if not _declared_reads.has(state_path):
		_fault(
			&"context.undeclared_read",
			"Rule %s read undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return resources
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.RESOURCE_DICTIONARY:
		_fault(
			&"context.unknown_read_path",
			"Rule %s read unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_read(rule_id, state_path, false)
		return resources
	resources = path.read_resource_dictionary(_candidate_state)
	_trace._append_read(rule_id, state_path, true, true, resources.size())
	return resources


func write_resource_dictionary(state_path: StringName, resources: Dictionary) -> bool:
	var rule_id: StringName = _current_rule_id()
	if not _require_current_rule(state_path):
		_trace._append_write(rule_id, state_path, false)
		return false
	if not _declared_writes.has(state_path):
		_fault(
			&"context.undeclared_write",
			"Rule %s wrote undeclared state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var path: SimulationStatePath = _state_path_registry.get_path(state_path)
	if path == null or path.value_type != SimulationStatePath.ValueType.RESOURCE_DICTIONARY:
		_fault(
			&"context.unknown_write_path",
			"Rule %s wrote unknown state path %s." % [rule_id, state_path],
			state_path
		)
		_trace._append_write(rule_id, state_path, false)
		return false
	var before_resources: Dictionary = path.read_resource_dictionary(_candidate_state)
	var write_diagnostic: SimulationDiagnostic = path.write_resource_dictionary(_candidate_state, resources)
	if write_diagnostic != null:
		_fault(
			&"context.write_failed",
			"Rule %s could not write state path %s. %s"
			% [rule_id, state_path, write_diagnostic.message],
			state_path
		)
		_trace._append_write(rule_id, state_path, false, true, before_resources.size())
		return false
	_trace._append_write(
		rule_id,
		state_path,
		true,
		true,
		before_resources.size(),
		true,
		resources.size()
	)
	return true


func get_project_definition(project_id: StringName) -> ProjectDefinition:
	if not _require_current_rule():
		return null
	if _content_registry == null:
		_fault(
			&"context.missing_content_registry",
			"Rule %s required Project content without a content registry." % _current_rule_id()
		)
		return null
	var definition: ProjectDefinition = _content_registry.get_project_definition(project_id)
	if definition == null:
		_fault(
			&"context.unknown_project_definition",
			"Rule %s requested unknown Project definition %s." % [_current_rule_id(), project_id]
		)
		return null
	return definition


func get_competitor_ids() -> Array[StringName]:
	var competitor_ids: Array[StringName] = []
	if not _require_current_rule():
		return competitor_ids
	if _content_registry == null:
		_fault(
			&"context.missing_content_registry",
			"Rule %s required Competitor content without a content registry." % _current_rule_id()
		)
		return competitor_ids
	return _content_registry.get_competitor_ids()


func get_competitor_definition(competitor_id: StringName) -> CompetitorDefinition:
	if not _require_current_rule():
		return null
	if _content_registry == null:
		_fault(
			&"context.missing_content_registry",
			"Rule %s required Competitor content without a content registry." % _current_rule_id()
		)
		return null
	var definition: CompetitorDefinition = _content_registry.get_competitor_definition(competitor_id)
	if definition == null:
		_fault(
			&"context.unknown_competitor_definition",
			"Rule %s requested unknown Competitor definition %s." % [_current_rule_id(), competitor_id]
		)
		return null
	return definition


func get_contract_definition(contract_id: StringName) -> ContractDefinition:
	if not _require_current_rule():
		return null
	if _content_registry == null:
		_fault(
			&"context.missing_content_registry",
			"Rule %s required contract content without a content registry." % _current_rule_id()
		)
		return null
	var definition: ContractDefinition = _content_registry.get_contract_definition(contract_id)
	if definition == null:
		_fault(
			&"context.unknown_contract_definition",
			"Rule %s requested unknown contract definition %s." % [_current_rule_id(), contract_id]
		)
		return null
	return definition


func record_condition(condition_id: StringName, result: bool) -> bool:
	if not _require_current_rule():
		return false
	var rule_id: StringName = _current_rule_id()
	if not _declared_conditions.has(condition_id):
		_fault(
			&"context.undeclared_condition",
			"Rule %s evaluated undeclared condition %s." % [rule_id, condition_id]
		)
		return false
	_trace._append_condition(rule_id, condition_id, result)
	return true


func emit_event(event_id: StringName, payload: Dictionary[StringName, Variant]) -> bool:
	var rule_id: StringName = _current_rule_id()
	if not _require_current_rule():
		_trace._append_event(rule_id, event_id, false, payload)
		return false
	if not _declared_events.has(event_id):
		_fault(
			&"context.undeclared_event",
			"Rule %s emitted undeclared event %s." % [rule_id, event_id]
		)
		_trace._append_event(rule_id, event_id, false, payload)
		return false
	if not _event_registry.has_event(event_id):
		_fault(
			&"context.unknown_event",
			"Rule %s emitted unknown event %s." % [rule_id, event_id]
		)
		_trace._append_event(rule_id, event_id, false, payload)
		return false
	_trace._append_event(rule_id, event_id, true, payload)
	return true


func append_ledger_transaction(transaction: LedgerTransactionState) -> bool:
	var rule_id: StringName = _current_rule_id()
	if not _require_current_rule(CASH_LEDGER_PATH):
		_trace._append_write(rule_id, CASH_LEDGER_PATH, false)
		return false
	if not _declared_writes.has(CASH_LEDGER_PATH):
		_fault(
			&"context.undeclared_write",
			"Rule %s wrote undeclared state path %s." % [rule_id, CASH_LEDGER_PATH],
			CASH_LEDGER_PATH
		)
		_trace._append_write(rule_id, CASH_LEDGER_PATH, false)
		return false
	if transaction == null:
		_fault(&"context.missing_ledger_transaction", "Rule %s provided a missing ledger transaction." % rule_id)
		_trace._append_write(rule_id, CASH_LEDGER_PATH, false)
		return false
	if transaction.source_rule_id != rule_id:
		_fault(
			&"context.ledger_source_rule_mismatch",
			"Ledger transaction %s identifies source Rule %s instead of active Rule %s."
			% [transaction.stable_id, transaction.source_rule_id, rule_id]
		)
		_trace._append_write(rule_id, CASH_LEDGER_PATH, false)
		return false
	var path: SimulationStatePath = _state_path_registry.get_path(CASH_LEDGER_PATH)
	if path == null or path.value_type != SimulationStatePath.ValueType.CASH_LEDGER:
		_fault(
			&"context.ledger_path_contract",
			"Cash Ledger state path %s is not registered with the Cash Ledger type." % CASH_LEDGER_PATH,
			CASH_LEDGER_PATH
		)
		_trace._append_write(rule_id, CASH_LEDGER_PATH, false)
		return false
	var source_ledger: CashLedgerState = path.read_cash_ledger(_candidate_state)
	if source_ledger == null:
		_fault(&"context.missing_cash_ledger", "The candidate Game State Cash Ledger is missing.")
		_trace._append_write(rule_id, CASH_LEDGER_PATH, false)
		return false
	var balance_before: int = source_ledger.calculate_balance_musd()
	var append_result: CashLedgerAppendResult = source_ledger.append_transaction(transaction)
	if not append_result.succeeded():
		_fault(
			&"context.ledger_append_failed",
			"Rule %s could not append ledger transaction %s. %s"
			% [rule_id, transaction.stable_id, append_result.format_errors()],
			CASH_LEDGER_PATH
		)
		_trace._append_write(
			rule_id, CASH_LEDGER_PATH, false, true, source_ledger.transactions.size()
		)
		return false
	var write_diagnostic: SimulationDiagnostic = path.write_cash_ledger(_candidate_state, append_result.ledger)
	if write_diagnostic != null:
		_fault(&"context.ledger_write_failed", write_diagnostic.message, CASH_LEDGER_PATH)
		_trace._append_write(
			rule_id, CASH_LEDGER_PATH, false, true, source_ledger.transactions.size()
		)
		return false
	var balance_after: int = append_result.ledger.calculate_balance_musd()
	_trace._append_write(
		rule_id,
		CASH_LEDGER_PATH,
		true,
		true,
		source_ledger.transactions.size(),
		true,
		append_result.ledger.transactions.size()
	)
	_trace._append_ledger(
		rule_id,
		transaction.stable_id,
		transaction.amount_musd,
		balance_before,
		balance_after
	)
	return true


func draw_integer(draw_id: StringName, minimum: int, maximum: int) -> SimulationIntegerResult:
	if not _require_current_rule():
		return SimulationIntegerResult.failure(_diagnostics[_diagnostics.size() - 1])
	var rule_id: StringName = _current_rule_id()
	if not StableIdentifier.is_valid(draw_id):
		return SimulationIntegerResult.failure(
			_fault(
				&"context.invalid_random_draw_id",
				"Rule %s used invalid random draw identifier %s." % [rule_id, draw_id]
			)
		)
	if minimum > maximum:
		return SimulationIntegerResult.failure(
			_fault(
				&"context.invalid_random_range",
				"Rule %s used random range %d through %d." % [rule_id, minimum, maximum]
			)
		)
	var value: int = _random.randi_range(minimum, maximum)
	_trace._append_random_draw(rule_id, draw_id, minimum, maximum, value)
	return SimulationIntegerResult.success(value)


func has_fault() -> bool:
	return not _diagnostics.is_empty()


func get_diagnostics() -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	diagnostics.assign(_diagnostics)
	return diagnostics


func _require_current_rule(state_path: StringName = &"") -> bool:
	if _current_rule != null:
		return true
	_diagnostics.append(
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"context.no_active_rule",
			"The Simulation Context does not have an active Rule.",
			&"",
			state_path
		)
	)
	return false


func _current_rule_id() -> StringName:
	if _current_rule == null:
		return &""
	return _current_rule.stable_id


func _fault(code: StringName, message: String, state_path: StringName = &"") -> SimulationDiagnostic:
	var diagnostic: SimulationDiagnostic = SimulationDiagnostic.new(
		SimulationDiagnostic.Severity.ERROR,
		code,
		message,
		_current_rule_id(),
		state_path
	)
	_diagnostics.append(diagnostic)
	return diagnostic
