extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const SNAPSHOT_PATH: String = "user://ms1_02_cash_ledger_round_trip.tres"
const TEST_SUCCESS: String = "CASH_LEDGER_TEST_SUCCESS"

var _failure_count: int = 0


func _initialize() -> void:
	_remove_test_file(SNAPSHOT_PATH)
	var definition: MarketingScenarioDefinition = MarketingScenarioFactory.load_definition(SCENARIO_PATH)
	_expect(definition != null, "The Marketing Scenario definition did not load.")
	if definition == null:
		_finish()
		return
	var initial_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	_expect(initial_result.succeeded(), "The initial Game State was not created.")
	if not initial_result.succeeded():
		_finish()
		return

	_verify_append_and_balance(initial_result.state, definition)
	_verify_invalid_transactions(initial_result.state)
	_verify_mutable_transaction_rejection(initial_result.state, definition)
	_verify_game_state_order_validation(initial_result.state, definition)
	_finish()


func _verify_append_and_balance(state: GameState, definition: MarketingScenarioDefinition) -> void:
	var source_ledger: CashLedgerState = state.cash_ledger
	_expect(source_ledger.calculate_balance_musd() == 150, "The opening Cash balance is incorrect.")

	var first_transaction: LedgerTransactionState = _new_transaction(
		&"ledger_transaction.runtime.id_000001",
		1,
		&"rule.finance.project_cost",
		&"cash_category.project_cost",
		-20,
		&"project.runtime.id_000001"
	)
	var first_append: CashLedgerAppendResult = source_ledger.append_transaction(first_transaction)
	_expect(first_append.succeeded(), "The first ledger append failed:\n%s" % first_append.format_errors())
	if not first_append.succeeded():
		return
	_expect(source_ledger.transactions.is_empty(), "The first append mutated the source Cash Ledger.")
	_expect(first_append.ledger != source_ledger, "The first append returned the source Cash Ledger.")
	_expect(first_append.ledger.transactions.size() == 1, "The first append did not add one transaction.")
	var stored_first: LedgerTransactionState = first_append.ledger.transactions[0]
	_expect(stored_first != first_transaction, "The ledger retained the caller-owned transaction reference.")
	_expect(stored_first.is_immutable(), "The appended ledger transaction is mutable.")
	_expect(first_append.ledger.calculate_balance_musd() == 130, "The first derived Cash balance is incorrect.")

	first_transaction.amount_musd = -99
	first_transaction.category_id = &"cash_category.changed_by_caller"
	_expect(stored_first.amount_musd == -20, "A caller mutation changed the appended transaction amount.")
	_expect(
		stored_first.category_id == &"cash_category.project_cost",
		"A caller mutation changed the appended transaction category."
	)
	_expect(first_append.ledger.calculate_balance_musd() == 130, "A caller mutation changed derived Cash.")

	var second_transaction: LedgerTransactionState = _new_transaction(
		&"ledger_transaction.runtime.id_000002",
		1,
		&"rule.finance.contract_revenue",
		&"cash_category.contract_revenue",
		7,
		&"contract.compute.standard"
	)
	var second_append: CashLedgerAppendResult = first_append.ledger.append_transaction(second_transaction)
	_expect(second_append.succeeded(), "The second ledger append failed:\n%s" % second_append.format_errors())
	if not second_append.succeeded():
		return
	_expect(first_append.ledger.transactions.size() == 1, "The second append mutated the prior Cash Ledger.")
	_expect(second_append.ledger.transactions.size() == 2, "The second append has the wrong transaction count.")
	_expect(
		second_append.ledger.transactions[0].stable_id == &"ledger_transaction.runtime.id_000001",
		"The second append changed prior transaction order."
	)
	_expect(
		second_append.ledger.transactions[1].stable_id == &"ledger_transaction.runtime.id_000002",
		"The second append did not preserve append order within one Month Step."
	)
	_expect(second_append.ledger.calculate_balance_musd() == 137, "The second derived Cash balance is incorrect.")

	var third_transaction: LedgerTransactionState = _new_transaction(
		&"ledger_transaction.runtime.id_000003",
		2,
		&"rule.finance.fixed_operating_cost",
		&"cash_category.operating_cost",
		-5
	)
	var third_append: CashLedgerAppendResult = second_append.ledger.append_transaction(third_transaction)
	_expect(third_append.succeeded(), "The third ledger append failed:\n%s" % third_append.format_errors())
	if not third_append.succeeded():
		return
	_expect(third_append.ledger.calculate_balance_musd() == 132, "The final derived Cash balance is incorrect.")

	var state_validation: GameStateValidationResult = _validate_with_ledger(
		state,
		third_append.ledger,
		definition
	)
	_expect(state_validation.is_valid(), "The valid Cash Ledger failed Game State validation:\n%s" % state_validation.format_errors())
	_verify_snapshot_round_trip(state, third_append.ledger, definition)

	var replay_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	_expect(replay_result.succeeded(), "The replay Game State was not created.")
	if not replay_result.succeeded():
		return
	var replay_first: CashLedgerAppendResult = replay_result.state.cash_ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000001",
			1,
			&"rule.finance.project_cost",
			&"cash_category.project_cost",
			-20,
			&"project.runtime.id_000001"
		)
	)
	var replay_second: CashLedgerAppendResult = replay_first.ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000002",
			1,
			&"rule.finance.contract_revenue",
			&"cash_category.contract_revenue",
			7,
			&"contract.compute.standard"
		)
	)
	var replay_third: CashLedgerAppendResult = replay_second.ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000003",
			2,
			&"rule.finance.fixed_operating_cost",
			&"cash_category.operating_cost",
			-5
		)
	)
	_expect(replay_third.succeeded(), "The deterministic replay append failed.")
	if replay_third.succeeded():
		_expect_ledgers_equal(third_append.ledger, replay_third.ledger)


func _verify_invalid_transactions(source_state: GameState) -> void:
	var valid_transaction: LedgerTransactionState = _new_transaction(
		&"ledger_transaction.runtime.id_000010",
		2,
		&"rule.finance.valid",
		&"cash_category.valid",
		-1
	)
	var valid_append: CashLedgerAppendResult = source_state.cash_ledger.append_transaction(valid_transaction)
	_expect(valid_append.succeeded(), "The invalid-transaction fixture could not be created.")
	if not valid_append.succeeded():
		return

	var duplicate_result: CashLedgerAppendResult = valid_append.ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000010",
			2,
			&"rule.finance.valid",
			&"cash_category.valid",
			1
		)
	)
	_expect_append_failure(duplicate_result, "duplicated", "A duplicate transaction identifier was accepted.")

	var zero_result: CashLedgerAppendResult = source_state.cash_ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000011",
			1,
			&"rule.finance.valid",
			&"cash_category.valid",
			0
		)
	)
	_expect_append_failure(zero_result, "must not be zero", "A zero transaction amount was accepted.")

	var invalid_id_result: CashLedgerAppendResult = source_state.cash_ledger.append_transaction(
		_new_transaction(
			&"Invalid Transaction",
			1,
			&"rule.finance.valid",
			&"cash_category.valid",
			1
		)
	)
	_expect_append_failure(invalid_id_result, "is invalid", "An invalid transaction identifier was accepted.")

	var missing_rule_result: CashLedgerAppendResult = source_state.cash_ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000012",
			1,
			&"",
			&"cash_category.valid",
			1
		)
	)
	_expect_append_failure(missing_rule_result, "source Rule identifier", "A missing source Rule was accepted.")

	var missing_category_result: CashLedgerAppendResult = source_state.cash_ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000013",
			1,
			&"rule.finance.valid",
			&"",
			1
		)
	)
	_expect_append_failure(missing_category_result, "category identifier", "A missing category was accepted.")

	var invalid_month_result: CashLedgerAppendResult = source_state.cash_ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000014",
			0,
			&"rule.finance.valid",
			&"cash_category.valid",
			1
		)
	)
	_expect_append_failure(invalid_month_result, "Month Step index", "An invalid Month Step index was accepted.")

	var out_of_order_result: CashLedgerAppendResult = valid_append.ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000015",
			1,
			&"rule.finance.valid",
			&"cash_category.valid",
			1
		)
	)
	_expect_append_failure(out_of_order_result, "after Month Step index", "An out-of-order Month Step was accepted.")
	_expect(valid_append.ledger.transactions.size() == 1, "An invalid append mutated its source Cash Ledger.")

	var invalid_entity_result: CashLedgerAppendResult = source_state.cash_ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000016",
			1,
			&"rule.finance.valid",
			&"cash_category.valid",
			1,
			&"Invalid Entity"
		)
	)
	_expect_append_failure(invalid_entity_result, "source entity identifier", "An invalid source entity was accepted.")

	var missing_result: CashLedgerAppendResult = source_state.cash_ledger.append_transaction(null)
	_expect_append_failure(missing_result, "is missing", "A missing transaction was accepted.")


func _verify_game_state_order_validation(
		source_state: GameState,
		definition: MarketingScenarioDefinition
	) -> void:
	var invalid_ledger: CashLedgerState = CashLedgerState.new()
	invalid_ledger.stable_id = source_state.cash_ledger.stable_id
	invalid_ledger.opening_balance_musd = source_state.cash_ledger.opening_balance_musd
	invalid_ledger.transactions = [
		_new_transaction(
			&"ledger_transaction.runtime.id_000020",
			2,
			&"rule.finance.valid",
			&"cash_category.valid",
			-1
		),
		_new_transaction(
			&"ledger_transaction.runtime.id_000021",
			1,
			&"rule.finance.valid",
			&"cash_category.valid",
			1
		),
	]
	var validation: GameStateValidationResult = _validate_with_ledger(
		source_state,
		invalid_ledger,
		definition
	)
	_expect(not validation.is_valid(), "Game State validation accepted out-of-order ledger transactions.")
	_expect(
		validation.format_errors().contains("after Month Step index"),
		"Game State validation did not identify the ledger order invariant."
	)


func _verify_mutable_transaction_rejection(
		source_state: GameState,
		definition: MarketingScenarioDefinition
	) -> void:
	var mutable_transaction: LedgerTransactionState = _new_transaction(
		&"ledger_transaction.runtime.id_000030",
		1,
		&"rule.finance.valid",
		&"cash_category.valid",
		-1
	)
	var invalid_source_ledger: CashLedgerState = CashLedgerState.new()
	invalid_source_ledger.stable_id = source_state.cash_ledger.stable_id
	invalid_source_ledger.opening_balance_musd = source_state.cash_ledger.opening_balance_musd
	invalid_source_ledger.transactions = [mutable_transaction]

	var state_validation: GameStateValidationResult = _validate_with_ledger(
		source_state,
		invalid_source_ledger,
		definition
	)
	_expect(not state_validation.is_valid(), "Game State validation accepted a mutable ledger transaction.")
	_expect(
		state_validation.format_errors().contains("must be immutable after append"),
		"Game State validation did not identify the mutable ledger transaction."
	)

	var append_result: CashLedgerAppendResult = invalid_source_ledger.append_transaction(
		_new_transaction(
			&"ledger_transaction.runtime.id_000031",
			1,
			&"rule.finance.valid",
			&"cash_category.valid",
			1
		)
	)
	_expect_append_failure(
		append_result,
		"must be immutable after append",
		"Append accepted a source Cash Ledger with a mutable stored transaction."
	)
	_expect(not mutable_transaction.is_immutable(), "A failed append repaired its mutable source transaction.")
	_expect(invalid_source_ledger.transactions.size() == 1, "A failed append changed its invalid source Cash Ledger.")
	_expect(
		invalid_source_ledger.transactions[0] == mutable_transaction,
		"A failed append replaced the invalid source transaction."
	)


func _verify_snapshot_round_trip(
		source_state: GameState,
		ledger: CashLedgerState,
		definition: MarketingScenarioDefinition
	) -> void:
	var duplicated_ledger_resource: Resource = ledger.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_expect(duplicated_ledger_resource is CashLedgerState, "The duplicated ledger is not a Cash Ledger.")
	if duplicated_ledger_resource is CashLedgerState:
		var duplicated_ledger: CashLedgerState = duplicated_ledger_resource
		for duplicated_transaction: LedgerTransactionState in duplicated_ledger.transactions:
			_expect(
				duplicated_transaction.is_immutable(),
				"A transaction-bearing deep duplicate lost transaction immutability."
			)

	var duplicated_resource: Resource = source_state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	_expect(duplicated_resource is GameState, "The snapshot ledger fixture is not a Game State.")
	if not duplicated_resource is GameState:
		return
	var snapshot_state: GameState = duplicated_resource
	snapshot_state.cash_ledger = ledger
	var save_result: GameStateSaveResult = GameStateSnapshotStore.save_snapshot(
		snapshot_state,
		SNAPSHOT_PATH,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		definition.build_content_reference_catalog()
	)
	_expect(save_result.succeeded(), "The transaction-bearing snapshot was not saved:\n%s" % save_result.format_errors())
	if not save_result.succeeded():
		return
	var load_result: GameStateLoadResult = GameStateSnapshotStore.load_snapshot(
		SNAPSHOT_PATH,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		definition.build_content_reference_catalog()
	)
	_expect(load_result.succeeded(), "The transaction-bearing snapshot did not load:\n%s" % load_result.format_errors())
	if not load_result.succeeded():
		return
	_expect_ledgers_equal(ledger, load_result.state.cash_ledger)
	for transaction: LedgerTransactionState in load_result.state.cash_ledger.transactions:
		_expect(transaction.is_immutable(), "A loaded ledger transaction is mutable.")


func _validate_with_ledger(
		source_state: GameState,
		ledger: CashLedgerState,
		definition: MarketingScenarioDefinition
	) -> GameStateValidationResult:
	var duplicated_resource: Resource = source_state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if not duplicated_resource is GameState:
		var failed_result: GameStateValidationResult = GameStateValidationResult.new()
		failed_result.add_error("The ledger validation fixture is not a Game State.")
		return failed_result
	var candidate_state: GameState = duplicated_resource
	candidate_state.cash_ledger = ledger
	return GameStateValidator.validate(
		candidate_state,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		definition.build_content_reference_catalog()
	)


func _new_transaction(
		stable_id: StringName,
		month_step_index: int,
		source_rule_id: StringName,
		category_id: StringName,
		amount_musd: int,
		source_entity_id: StringName = &""
	) -> LedgerTransactionState:
	var transaction: LedgerTransactionState = LedgerTransactionState.new()
	transaction.stable_id = stable_id
	transaction.month_step_index = month_step_index
	transaction.source_rule_id = source_rule_id
	transaction.category_id = category_id
	transaction.amount_musd = amount_musd
	transaction.source_entity_id = source_entity_id
	return transaction


func _expect_append_failure(
		result: CashLedgerAppendResult,
		expected_error_text: String,
		failure_message: String
	) -> void:
	_expect(not result.succeeded(), failure_message)
	_expect(result.ledger == null, "A failed ledger append exposed a candidate Cash Ledger.")
	_expect(
		result.format_errors().contains(expected_error_text),
		"The failed ledger append did not identify its contract violation: %s" % result.format_errors()
	)


func _expect_ledgers_equal(expected: CashLedgerState, actual: CashLedgerState) -> void:
	_expect(expected.stable_id == actual.stable_id, "Replay changed the Cash Ledger identifier.")
	_expect(
		expected.opening_balance_musd == actual.opening_balance_musd,
		"Replay changed the Cash opening balance."
	)
	_expect(expected.transactions.size() == actual.transactions.size(), "Replay changed transaction count.")
	if expected.transactions.size() != actual.transactions.size():
		return
	for index: int in range(expected.transactions.size()):
		var expected_transaction: LedgerTransactionState = expected.transactions[index]
		var actual_transaction: LedgerTransactionState = actual.transactions[index]
		_expect(expected_transaction.stable_id == actual_transaction.stable_id, "Replay changed transaction order.")
		_expect(
			expected_transaction.month_step_index == actual_transaction.month_step_index,
			"Replay changed a transaction Month Step index."
		)
		_expect(expected_transaction.source_rule_id == actual_transaction.source_rule_id, "Replay changed a source Rule.")
		_expect(expected_transaction.category_id == actual_transaction.category_id, "Replay changed a category.")
		_expect(expected_transaction.amount_musd == actual_transaction.amount_musd, "Replay changed an amount.")
		_expect(
			expected_transaction.source_entity_id == actual_transaction.source_entity_id,
			"Replay changed a source entity."
		)
	_expect(expected.calculate_balance_musd() == actual.calculate_balance_musd(), "Replay changed derived Cash.")


func _finish() -> void:
	_remove_test_file(SNAPSHOT_PATH)
	if _failure_count > 0:
		printerr("CASH_LEDGER_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=4" % TEST_SUCCESS)
	quit(0)


func _remove_test_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var remove_error: Error = DirAccess.remove_absolute(absolute_path)
	if remove_error != OK:
		_expect(false, "The test file could not be removed: %s" % path)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
