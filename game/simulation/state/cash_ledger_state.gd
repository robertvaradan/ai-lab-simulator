class_name CashLedgerState
extends Resource

@export var stable_id: StringName = &""
@export var opening_balance_musd: int = -1
@export var transactions: Array[LedgerTransactionState] = []


func _init() -> void:
	pass


func calculate_balance_musd() -> int:
	var balance_musd: int = opening_balance_musd
	for transaction: LedgerTransactionState in transactions:
		balance_musd += transaction.amount_musd
	return balance_musd


func append_transaction(transaction: LedgerTransactionState) -> CashLedgerAppendResult:
	var result: CashLedgerAppendResult = CashLedgerAppendResult.new()
	var source_validation: GameStateValidationResult = CashLedgerValidator.validate(self)
	if not source_validation.is_valid():
		result.errors.append_array(source_validation.errors)
		return result
	if transaction == null:
		result.add_error("The ledger transaction is missing.")
		return result

	var appended_ledger: CashLedgerState = CashLedgerState.new()
	appended_ledger.stable_id = stable_id
	appended_ledger.opening_balance_musd = opening_balance_musd
	for existing_transaction: LedgerTransactionState in transactions:
		if existing_transaction == null:
			appended_ledger.transactions.append(null)
			continue
		appended_ledger.transactions.append(existing_transaction.immutable_copy())
	appended_ledger.transactions.append(transaction.immutable_copy())

	var validation: GameStateValidationResult = CashLedgerValidator.validate(appended_ledger)
	if not validation.is_valid():
		result.errors.append_array(validation.errors)
		return result
	result.ledger = appended_ledger
	return result
