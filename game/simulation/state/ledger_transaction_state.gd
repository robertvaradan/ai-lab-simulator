class_name LedgerTransactionState
extends Resource

@export var stable_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable ledger transaction cannot change its stable identifier.")
			return
		stable_id = value
@export var month_step_index: int = -1:
	set(value):
		if _is_immutable:
			push_error("An immutable ledger transaction cannot change its Month Step index.")
			return
		month_step_index = value
@export var source_rule_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable ledger transaction cannot change its source Rule identifier.")
			return
		source_rule_id = value
@export var category_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable ledger transaction cannot change its category identifier.")
			return
		category_id = value
@export var amount_musd: int = 0:
	set(value):
		if _is_immutable:
			push_error("An immutable ledger transaction cannot change its amount.")
			return
		amount_musd = value
@export var source_entity_id: StringName = &"":
	set(value):
		if _is_immutable:
			push_error("An immutable ledger transaction cannot change its source entity identifier.")
			return
		source_entity_id = value

@export_storage var _is_immutable: bool = false


func _init() -> void:
	pass


func immutable_copy() -> LedgerTransactionState:
	var copied_transaction: LedgerTransactionState = LedgerTransactionState.new()
	copied_transaction.stable_id = stable_id
	copied_transaction.month_step_index = month_step_index
	copied_transaction.source_rule_id = source_rule_id
	copied_transaction.category_id = category_id
	copied_transaction.amount_musd = amount_musd
	copied_transaction.source_entity_id = source_entity_id
	copied_transaction._is_immutable = true
	return copied_transaction


func is_immutable() -> bool:
	return _is_immutable
