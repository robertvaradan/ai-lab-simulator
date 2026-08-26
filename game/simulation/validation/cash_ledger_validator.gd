class_name CashLedgerValidator
extends RefCounted


static func validate(ledger: CashLedgerState) -> GameStateValidationResult:
	var result: GameStateValidationResult = GameStateValidationResult.new()
	if ledger == null:
		result.add_error("Cash Ledger is missing.")
		return result
	_validate_identifier(ledger.stable_id, "Cash Ledger identifier", result)
	if ledger.opening_balance_musd < 0:
		result.add_error("Cash opening balance must not be negative.")

	var seen_transaction_ids: Dictionary[StringName, bool] = {}
	var previous_month_step_index: int = -1
	for transaction: LedgerTransactionState in ledger.transactions:
		if transaction == null:
			result.add_error("The Cash Ledger contains a missing transaction.")
			continue
		if not transaction.is_immutable():
			result.add_error(
				"Ledger transaction %s must be immutable after append." % transaction.stable_id
			)
		_validate_identifier(transaction.stable_id, "Ledger transaction identifier", result)
		if seen_transaction_ids.has(transaction.stable_id):
			result.add_error("Ledger transaction identifier %s is duplicated." % transaction.stable_id)
		seen_transaction_ids[transaction.stable_id] = true
		if transaction.month_step_index < 1:
			result.add_error("Ledger transaction %s has an invalid Month Step index." % transaction.stable_id)
		elif transaction.month_step_index < previous_month_step_index:
			result.add_error(
				"Ledger transaction %s has Month Step index %d after Month Step index %d."
				% [
					transaction.stable_id,
					transaction.month_step_index,
					previous_month_step_index,
				]
			)
		previous_month_step_index = transaction.month_step_index
		_validate_identifier(
			transaction.source_rule_id,
			"Ledger transaction %s source Rule identifier" % transaction.stable_id,
			result
		)
		_validate_identifier(
			transaction.category_id,
			"Ledger transaction %s category identifier" % transaction.stable_id,
			result
		)
		if transaction.amount_musd == 0:
			result.add_error("Ledger transaction %s amount must not be zero." % transaction.stable_id)
		if transaction.source_entity_id != &"":
			_validate_identifier(
				transaction.source_entity_id,
				"Ledger transaction %s source entity identifier" % transaction.stable_id,
				result
			)
	return result


static func _validate_identifier(
		identifier: StringName,
		field_name: String,
		result: GameStateValidationResult
	) -> void:
	if not StableIdentifier.is_valid(identifier):
		result.add_error("%s %s is invalid." % [field_name, identifier])
