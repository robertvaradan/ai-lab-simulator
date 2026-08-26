class_name SimulationTrace
extends RefCounted

var operation_id: StringName:
	get:
		return _operation_id
var random_seed: int:
	get:
		return _random_seed

var _operation_id: StringName
var _random_seed: int
var _records: Array[SimulationTraceRecord] = []
var _is_sealed: bool = false


func _init(p_operation_id: StringName, p_random_seed: int) -> void:
	_operation_id = p_operation_id
	_random_seed = p_random_seed


func _begin_rule(rule_id: StringName) -> RuleEvaluationTraceRecord:
	if _is_sealed:
		return null
	var record: RuleEvaluationTraceRecord = RuleEvaluationTraceRecord.new(_records.size(), rule_id)
	_records.append(record)
	return record


func _append_condition(rule_id: StringName, condition_id: StringName, result: bool) -> void:
	if _is_sealed:
		return
	_records.append(ConditionTraceRecord.new(_records.size(), rule_id, condition_id, result))


func _append_read(
		rule_id: StringName,
		state_path: StringName,
		succeeded: bool,
		has_value: bool = false,
		value: int = 0
	) -> void:
	if _is_sealed:
		return
	_records.append(
		StateReadTraceRecord.new(
			_records.size(), rule_id, state_path, succeeded, has_value, value
		)
	)


func _append_write(
		rule_id: StringName,
		state_path: StringName,
		succeeded: bool,
		has_before_value: bool = false,
		before_value: int = 0,
		has_after_value: bool = false,
		after_value: int = 0
	) -> void:
	if _is_sealed:
		return
	_records.append(
		StateWriteTraceRecord.new(
			_records.size(),
			rule_id,
			state_path,
			succeeded,
			has_before_value,
			before_value,
			has_after_value,
			after_value
		)
	)


func _append_event(
		rule_id: StringName,
		event_id: StringName,
		succeeded: bool,
		payload: Dictionary[StringName, Variant]
	) -> void:
	if _is_sealed:
		return
	_records.append(EventEmissionTraceRecord.new(_records.size(), rule_id, event_id, succeeded, payload))


func _append_ledger(
		rule_id: StringName,
		transaction_id: StringName,
		amount_musd: int,
		balance_before_musd: int,
		balance_after_musd: int
	) -> void:
	if _is_sealed:
		return
	_records.append(
		LedgerActivityTraceRecord.new(
			_records.size(),
			rule_id,
			transaction_id,
			amount_musd,
			balance_before_musd,
			balance_after_musd
		)
	)


func _append_random_draw(
		rule_id: StringName,
		draw_id: StringName,
		minimum: int,
		maximum: int,
		value: int
	) -> void:
	if _is_sealed:
		return
	_records.append(
		RandomDrawTraceRecord.new(
			_records.size(), rule_id, draw_id, minimum, maximum, value
		)
	)


func _append_contract_fault(diagnostic_code: StringName) -> void:
	if _is_sealed:
		return
	_records.append(ContractFaultTraceRecord.new(_records.size(), diagnostic_code))


func _append_plan_commitment(
		pending_command_batch_id: StringName,
		command_ids: Array[StringName],
		resolved_attention_event_ids: Array[StringName]
	) -> void:
	if _is_sealed:
		return
	_records.append(
		PlanCommitmentTraceRecord.new(
			_records.size(),
			pending_command_batch_id,
			command_ids,
			resolved_attention_event_ids
		)
	)


func _seal() -> void:
	if _is_sealed:
		return
	for record: SimulationTraceRecord in _records:
		record._seal_record()
	_is_sealed = true


func is_sealed() -> bool:
	return _is_sealed


func get_records() -> Array[SimulationTraceRecord]:
	var records: Array[SimulationTraceRecord] = []
	records.assign(_records)
	return records


func to_canonical_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for record: SimulationTraceRecord in _records:
		data.append(record.to_dictionary())
	return data
