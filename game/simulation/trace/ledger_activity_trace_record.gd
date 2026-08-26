class_name LedgerActivityTraceRecord
extends SimulationTraceRecord

var rule_id: StringName:
	get:
		return _rule_id
var transaction_id: StringName:
	get:
		return _transaction_id
var amount_musd: int:
	get:
		return _amount_musd
var balance_before_musd: int:
	get:
		return _balance_before_musd
var balance_after_musd: int:
	get:
		return _balance_after_musd

var _rule_id: StringName
var _transaction_id: StringName
var _amount_musd: int
var _balance_before_musd: int
var _balance_after_musd: int


func _init(
		p_sequence_index: int,
		p_rule_id: StringName,
		p_transaction_id: StringName,
		p_amount_musd: int,
		p_balance_before_musd: int,
		p_balance_after_musd: int
	) -> void:
	super(p_sequence_index, Kind.LEDGER_ACTIVITY)
	_rule_id = p_rule_id
	_transaction_id = p_transaction_id
	_amount_musd = p_amount_musd
	_balance_before_musd = p_balance_before_musd
	_balance_after_musd = p_balance_after_musd


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"rule_id"] = rule_id
	data[&"transaction_id"] = transaction_id
	data[&"amount_musd"] = amount_musd
	data[&"balance_before_musd"] = balance_before_musd
	data[&"balance_after_musd"] = balance_after_musd
	return data
