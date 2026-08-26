extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const INVALID_SNAPSHOT_PATH: String = "user://ms1_03_invalid_pin_snapshot.tres"
const GRAPH_ID: StringName = &"rule_graph.marketing.first_quarter"
const GRAPH_VERSION: int = 1
const PUBLIC_TRUST_PATH: StringName = &"state.company.public_trust_points"
const GOVERNMENT_TRUST_PATH: StringName = &"state.company.government_trust_points"
const CASH_LEDGER_PATH: StringName = &"state.cash_ledger.transactions"
const TEST_EVENT_ID: StringName = &"event.test.trust_changed"
const TEST_SUCCESS: String = "SIMULATION_CORE_TEST_SUCCESS"

var _failure_count: int = 0


class HappyRule extends SimulationRule:
	func _init() -> void:
		stable_id = &"rule.test.trust_update"
		display_name = "Test trust update"
		phase_id = &"rule_phase.test"
		execution_order = 10
		read_state_paths = [&"state.company.public_trust_points"]
		write_state_paths = [
			&"state.company.public_trust_points",
			&"state.cash_ledger.transactions",
		]
		emitted_event_ids = [&"event.test.trust_changed"]
		condition_ids = [&"condition.test.trust_below_limit"]
		graph_group_id = &"rule_group.test"
		specification_references = ["docs/simulation/rule-contract.md"]

	func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
		var trust_result: SimulationIntegerResult = context.read_integer(
			&"state.company.public_trust_points"
		)
		if not trust_result.has_value:
			return SimulationRuleEvaluation.failed(trust_result.diagnostic)
		if not context.record_condition(&"condition.test.trust_below_limit", trust_result.value < 100):
			var condition_diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
			return SimulationRuleEvaluation.failed(condition_diagnostics[condition_diagnostics.size() - 1])
		var draw_result: SimulationIntegerResult = context.draw_integer(&"random_draw.test.audit", 10, 20)
		if not draw_result.has_value:
			return SimulationRuleEvaluation.failed(draw_result.diagnostic)
		if not context.write_integer(
			&"state.company.public_trust_points",
			trust_result.value + 1
		):
			var write_diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
			return SimulationRuleEvaluation.failed(write_diagnostics[write_diagnostics.size() - 1])
		var payload: Dictionary[StringName, Variant] = {
			&"new_value": trust_result.value + 1,
			&"audit_draw": draw_result.value,
		}
		var nested_payload: Dictionary[StringName, Variant] = {
			&"captured_value": 55,
		}
		payload[&"nested"] = nested_payload
		if not context.emit_event(&"event.test.trust_changed", payload):
			var event_diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
			return SimulationRuleEvaluation.failed(event_diagnostics[event_diagnostics.size() - 1])
		nested_payload[&"captured_value"] = 999
		payload[&"added_after_emission"] = true
		var transaction: LedgerTransactionState = LedgerTransactionState.new()
		transaction.stable_id = &"ledger_transaction.runtime.id_000001"
		transaction.month_step_index = 1
		transaction.source_rule_id = stable_id
		transaction.category_id = &"cash_category.test.audit"
		transaction.amount_musd = -2
		if not context.append_ledger_transaction(transaction):
			var ledger_diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
			return SimulationRuleEvaluation.failed(ledger_diagnostics[ledger_diagnostics.size() - 1])
		return SimulationRuleEvaluation.fired()


class NoOpRule extends SimulationRule:
	func _init(rule_id: StringName, order: int = 10) -> void:
		stable_id = rule_id
		display_name = "No-op test Rule"
		phase_id = &"rule_phase.test"
		execution_order = order
		graph_group_id = &"rule_group.test"
		specification_references = ["docs/simulation/rule-contract.md"]

	func evaluate(_context: SimulationContext) -> SimulationRuleEvaluation:
		return SimulationRuleEvaluation.did_not_fire()


class UndeclaredReadRule extends NoOpRule:
	func _init() -> void:
		super(&"rule.test.undeclared_read")
		read_state_paths = [&"state.company.government_trust_points"]

	func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
		var result: SimulationIntegerResult = context.read_integer(
			&"state.company.public_trust_points"
		)
		if result.has_value:
			return SimulationRuleEvaluation.fired()
		return SimulationRuleEvaluation.failed(result.diagnostic)


class UndeclaredWriteRule extends NoOpRule:
	func _init() -> void:
		super(&"rule.test.undeclared_write")
		write_state_paths = [&"state.company.government_trust_points"]

	func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
		if not context.write_integer(&"state.company.government_trust_points", 51):
			var declared_write_diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
			return SimulationRuleEvaluation.failed(
				declared_write_diagnostics[declared_write_diagnostics.size() - 1]
			)
		if context.write_integer(&"state.company.public_trust_points", 99):
			return SimulationRuleEvaluation.fired()
		var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
		return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])


func _initialize() -> void:
	_remove_test_file(INVALID_SNAPSHOT_PATH)
	var definition: MarketingScenarioDefinition = MarketingScenarioFactory.load_definition(SCENARIO_PATH)
	_expect(definition != null, "The Marketing Scenario definition did not load.")
	if definition == null:
		_finish()
		return
	var state_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	_expect(state_result.succeeded(), "The starting Game State was not created.")
	if not state_result.succeeded():
		_finish()
		return

	_verify_registry_contracts(definition, state_result.state)
	_verify_graph_contracts(definition, state_result.state)
	_verify_pin_contracts(definition, state_result.state)
	_verify_success_and_replay(definition, state_result.state)
	_verify_undeclared_access(definition, state_result.state)
	_verify_operation_result_contract(state_result.state)
	_finish()


func _verify_registry_contracts(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var first_rule: NoOpRule = NoOpRule.new(&"rule.test.first")
	var duplicate_rule: NoOpRule = NoOpRule.new(&"rule.test.first")
	var duplicate_registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	_expect(duplicate_registry.register_rule(first_rule), "The Rule registry rejected its first Rule.")
	_expect(not duplicate_registry.register_rule(duplicate_rule), "The Rule registry accepted a duplicate Rule identifier.")
	var duplicate_construction: SimulationCoreConstructionResult = _construct_core(
		definition,
		state,
		duplicate_registry
	)
	_expect(not duplicate_construction.succeeded(), "Duplicate Rule identifiers did not prevent Simulation Core construction.")
	_expect(
		_has_diagnostic(duplicate_construction.diagnostics, &"rule_registry.duplicate_rule_id"),
		"Duplicate Rule construction did not retain its typed diagnostic."
	)

	var sealed_rule_registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	_expect(
		sealed_rule_registry.register_rule(NoOpRule.new(&"rule.test.sealed_first")),
		"The Rule registry rejected registration before sealing."
	)
	sealed_rule_registry.seal()
	_expect(sealed_rule_registry.is_sealed(), "The Rule registry did not seal.")
	_expect(
		sealed_rule_registry.get_rule(&"rule.test.sealed_first").is_metadata_sealed(),
		"Rule metadata did not seal with its registry."
	)
	_expect(
		not sealed_rule_registry.register_rule(NoOpRule.new(&"rule.test.sealed_late")),
		"The sealed Rule registry accepted a Rule."
	)

	var content_registry: SimulationContentRegistry = definition.build_content_registry()
	content_registry.seal()
	_expect(content_registry.is_sealed(), "The content registry did not seal.")
	_expect(
		not content_registry.register_content(&"content.test.late"),
		"The sealed content registry accepted content."
	)
	var path_registry: SimulationStatePathRegistry = _build_state_path_registry()
	path_registry.seal()
	_expect(
		not path_registry.register_path(
			SimulationStatePath.new(
				&"state.test.late",
				SimulationStatePath.Accessor.COMPANY_PUBLIC_TRUST_POINTS,
				SimulationStatePath.ValueType.INTEGER
			)
		),
		"The sealed state-path registry accepted a path."
	)
	var event_registry: SimulationEventRegistry = _build_event_registry()
	event_registry.seal()
	_expect(
		not event_registry.register_event(&"event.test.late"),
		"The sealed event registry accepted an event."
	)


func _verify_graph_contracts(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var direct_rule_registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	var direct_rule: NoOpRule = NoOpRule.new(&"rule.test.direct_compile")
	direct_rule_registry.register_rule(direct_rule)
	var direct_path_registry: SimulationStatePathRegistry = _build_state_path_registry()
	var direct_event_registry: SimulationEventRegistry = _build_event_registry()
	var direct_result: RuleGraphCompilationResult = SimulationRuleGraphCompiler.compile_rule_graph(
		direct_rule_registry,
		direct_path_registry,
		direct_event_registry,
		GRAPH_ID,
		GRAPH_VERSION,
		definition.content_version
	)
	_expect(direct_result.succeeded(), "Direct Rule Graph compilation failed.")
	_expect(direct_rule_registry.is_sealed(), "Direct compilation did not seal the Rule registry.")
	_expect(direct_path_registry.is_sealed(), "Direct compilation did not seal the state-path registry.")
	_expect(direct_event_registry.is_sealed(), "Direct compilation did not seal the event registry.")
	_expect(direct_rule.is_metadata_sealed(), "Direct compilation retained mutable Rule metadata.")
	if direct_result.succeeded():
		_expect(
			direct_result.graph.ordered_rules[0] == direct_rule,
			"Direct compilation did not retain the sealed registered Rule object."
		)

	var ordering_registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	var later_rule: NoOpRule = NoOpRule.new(&"rule.test.later", 20)
	var earlier_rule: NoOpRule = NoOpRule.new(&"rule.test.earlier", 10)
	ordering_registry.register_rule(later_rule)
	ordering_registry.register_rule(earlier_rule)
	var ordering_result: SimulationCoreConstructionResult = _construct_core(
		definition,
		state,
		ordering_registry
	)
	_expect(ordering_result.succeeded(), "A valid stable-order graph did not compile.")
	if ordering_result.succeeded():
		var ordered_rules: Array[SimulationRule] = ordering_result.core.get_compiled_graph().ordered_rules
		_expect(ordered_rules.size() == 2, "The compiled graph has the wrong Rule count.")
		if ordered_rules.size() == 2:
			_expect(ordered_rules[0] == earlier_rule, "The compiled graph did not use stable execution order.")
			_expect(ordered_rules[1] == later_rule, "The compiled graph changed Rule object identity.")

	var missing_path_rule: NoOpRule = NoOpRule.new(&"rule.test.missing_path")
	missing_path_rule.read_state_paths = [&"state.company.unknown"]
	_expect_invalid_graph(definition, state, [missing_path_rule], &"rule_graph.unknown_read_state_path")

	var missing_event_rule: NoOpRule = NoOpRule.new(&"rule.test.missing_event")
	missing_event_rule.emitted_event_ids = [&"event.test.unknown"]
	_expect_invalid_graph(definition, state, [missing_event_rule], &"rule_graph.unknown_emitted_event")

	var missing_dependency_rule: NoOpRule = NoOpRule.new(&"rule.test.missing_dependency", -1)
	missing_dependency_rule.order_after_rule_ids = [&"rule.test.not_registered"]
	_expect_invalid_graph(
		definition,
		state,
		[missing_dependency_rule],
		&"rule_graph.missing_order_dependency"
	)

	var cycle_first: NoOpRule = NoOpRule.new(&"rule.test.cycle_first", -1)
	var cycle_second: NoOpRule = NoOpRule.new(&"rule.test.cycle_second", -1)
	cycle_first.order_after_rule_ids = [cycle_second.stable_id]
	cycle_second.order_after_rule_ids = [cycle_first.stable_id]
	_expect_invalid_graph(
		definition,
		state,
		[cycle_first, cycle_second],
		&"rule_graph.same_step_cycle"
	)

	var writer_first: NoOpRule = NoOpRule.new(&"rule.test.writer_first", 10)
	var writer_second: NoOpRule = NoOpRule.new(&"rule.test.writer_second", 10)
	writer_first.write_state_paths = [PUBLIC_TRUST_PATH]
	writer_second.write_state_paths = [PUBLIC_TRUST_PATH]
	_expect_invalid_graph(
		definition,
		state,
		[writer_first, writer_second],
		&"rule_graph.ambiguous_same_path_write"
	)

	var invalid_metadata_rule: NoOpRule = NoOpRule.new(&"rule.test.invalid_metadata")
	invalid_metadata_rule.specification_references = []
	_expect_invalid_graph(
		definition,
		state,
		[invalid_metadata_rule],
		&"rule_graph.missing_specification_reference"
	)


func _verify_pin_contracts(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var schema_mismatch: GameState = _duplicate_state(state)
	schema_mismatch.schema_version += 1
	_expect_construction_pin_failure(definition, schema_mismatch, "schema version")

	var content_mismatch: GameState = _duplicate_state(state)
	content_mismatch.content_version += 1
	_expect_construction_pin_failure(definition, content_mismatch, "content version")

	var graph_id_mismatch: GameState = _duplicate_state(state)
	graph_id_mismatch.rule_graph_id = &"rule_graph.marketing.other"
	_expect_construction_pin_failure(definition, graph_id_mismatch, "Rule Graph identifier")

	var graph_version_mismatch: GameState = _duplicate_state(state)
	graph_version_mismatch.rule_graph_version += 1
	_expect_construction_pin_failure(definition, graph_version_mismatch, "Rule Graph version")

	var save_error: Error = ResourceSaver.save(graph_version_mismatch, INVALID_SNAPSHOT_PATH)
	_expect(save_error == OK, "The Rule Graph mismatch snapshot fixture was not saved.")
	if save_error == OK:
		var load_result: GameStateLoadResult = GameStateSnapshotStore.load_snapshot(
			INVALID_SNAPSHOT_PATH,
			definition.stable_id,
			definition.content_version,
			definition.rule_graph_id,
			definition.rule_graph_version,
			definition.build_content_reference_catalog()
		)
		_expect(not load_result.succeeded(), "Snapshot validation accepted a Rule Graph version mismatch.")
		_expect(load_result.state == null, "An incompatible snapshot exposed a Game State.")
		_expect(
			load_result.format_errors().contains("Rule Graph version"),
			"Snapshot validation did not identify the Rule Graph version mismatch."
		)


func _verify_success_and_replay(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	var registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	var happy_rule: HappyRule = HappyRule.new()
	registry.register_rule(happy_rule)
	var construction: SimulationCoreConstructionResult = _construct_core(definition, state, registry)
	_expect(construction.succeeded(), "The valid Simulation Core did not construct:\n%s" % construction.format_diagnostics())
	if not construction.succeeded():
		return
	_expect(
		construction.core.get_compiled_graph().ordered_rules[0] == happy_rule,
		"The compiled graph did not retain the registered Rule evaluator object."
	)
	var input_before: PackedByteArray = var_to_bytes_with_objects(state)
	var first_result: SimulationOperationResult = construction.core._execute_compiled_rules(state, 424242)
	_expect(first_result.outcome == SimulationOperationOutcome.Type.COMPLETED, "The valid Rule operation did not complete.")
	_expect(first_result.has_candidate_state(), "The completed operation has no candidate Game State.")
	_expect(first_result.trace != null and first_result.trace.is_sealed(), "The completed result did not seal its trace.")
	_expect(var_to_bytes_with_objects(state) == input_before, "A successful operation mutated its input Game State.")
	if not first_result.has_candidate_state():
		return
	_expect(first_result.candidate_state != state, "The completed operation returned its input Game State instance.")
	_expect(
		first_result.candidate_state.company.public_trust_points == 56,
		"The declared state write did not update the candidate Game State."
	)
	_expect(state.company.public_trust_points == 55, "The declared state write changed the input Game State.")
	_expect(first_result.candidate_state.cash_ledger.transactions.size() == 1, "Ledger activity was not applied.")
	_expect(first_result.candidate_state.cash_ledger.calculate_balance_musd() == 148, "Ledger activity changed Cash incorrectly.")
	_verify_success_trace(first_result.trace)

	var second_result: SimulationOperationResult = construction.core._execute_compiled_rules(state, 424242)
	_expect(second_result.outcome == SimulationOperationOutcome.Type.COMPLETED, "The deterministic replay did not complete.")
	if second_result.has_candidate_state():
		_expect(
			var_to_bytes_with_objects(first_result.candidate_state)
			== var_to_bytes_with_objects(second_result.candidate_state),
			"A fixed Rule input produced a different candidate Game State on replay."
		)
	_expect(
		first_result.trace.to_canonical_data() == second_result.trace.to_canonical_data(),
		"A fixed Rule input produced a different Simulation Trace on replay."
	)


func _verify_success_trace(trace: SimulationTrace) -> void:
	var records: Array[SimulationTraceRecord] = trace.get_records()
	var expected_kinds: Array[SimulationTraceRecord.Kind] = [
		SimulationTraceRecord.Kind.RULE_EVALUATION,
		SimulationTraceRecord.Kind.STATE_READ,
		SimulationTraceRecord.Kind.CONDITION,
		SimulationTraceRecord.Kind.RANDOM_DRAW,
		SimulationTraceRecord.Kind.STATE_WRITE,
		SimulationTraceRecord.Kind.EVENT_EMISSION,
		SimulationTraceRecord.Kind.STATE_WRITE,
		SimulationTraceRecord.Kind.LEDGER_ACTIVITY,
	]
	_expect(records.size() == expected_kinds.size(), "The successful Simulation Trace has the wrong record count.")
	if records.size() != expected_kinds.size():
		return
	for index: int in range(records.size()):
		_expect(records[index].sequence_index == index, "A Simulation Trace sequence index is unstable.")
		_expect(records[index].kind == expected_kinds[index], "Simulation Trace record %d has the wrong type." % index)
		_expect(records[index].is_sealed(), "A captured Simulation Trace record remained mutable.")
	var rule_record: RuleEvaluationTraceRecord = records[0] as RuleEvaluationTraceRecord
	_expect(rule_record != null, "The Rule trace record has the wrong concrete type.")
	if rule_record != null:
		_expect(rule_record.rule_id == &"rule.test.trust_update", "The Rule trace record has the wrong Rule identifier.")
		_expect(rule_record.status == SimulationRuleEvaluation.Status.FIRED, "The Rule trace did not record that the Rule fired.")
	var read_record: StateReadTraceRecord = records[1] as StateReadTraceRecord
	_expect(read_record != null and read_record.succeeded, "The declared read was not traced as successful.")
	var write_record: StateWriteTraceRecord = records[4] as StateWriteTraceRecord
	_expect(write_record != null and write_record.succeeded, "The declared write was not traced as successful.")
	if write_record != null:
		_expect(write_record.has_before_value, "The write trace has no before value.")
		_expect(write_record.has_after_value, "The write trace has no after value.")
		_expect(write_record.before_value == 55 and write_record.after_value == 56, "The write trace has incorrect before or after data.")
	var event_record: EventEmissionTraceRecord = records[5] as EventEmissionTraceRecord
	_expect(event_record != null and event_record.succeeded, "The declared event was not traced as successful.")
	if event_record != null:
		var canonical_before_exposure: String = var_to_str(trace.to_canonical_data())
		_expect(
			canonical_before_exposure.contains("captured_value")
			and canonical_before_exposure.contains("55")
			and not canonical_before_exposure.contains("999")
			and not canonical_before_exposure.contains("added_after_emission"),
			"The event trace did not deep-copy its nested payload at capture time."
		)
		var exposed_payload: Dictionary[StringName, Variant] = event_record.payload
		exposed_payload[&"mutated_after_capture"] = true
		var exposed_records: Array[SimulationTraceRecord] = trace.get_records()
		exposed_records.clear()
		_expect(
			var_to_str(trace.to_canonical_data()) == canonical_before_exposure,
			"A caller mutated captured Simulation Trace history through exposed containers."
		)
		_expect(trace.get_records().size() == expected_kinds.size(), "A caller mutated the trace record collection.")
	var ledger_record: LedgerActivityTraceRecord = records[7] as LedgerActivityTraceRecord
	_expect(ledger_record != null and ledger_record.balance_after_musd == 148, "The ledger activity trace is incorrect.")


func _verify_undeclared_access(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> void:
	_verify_fault_rule(definition, state, UndeclaredReadRule.new(), &"context.undeclared_read", SimulationTraceRecord.Kind.STATE_READ)
	_verify_fault_rule(definition, state, UndeclaredWriteRule.new(), &"context.undeclared_write", SimulationTraceRecord.Kind.STATE_WRITE)


func _verify_fault_rule(
		definition: MarketingScenarioDefinition,
		state: GameState,
		rule: SimulationRule,
		expected_code: StringName,
		expected_trace_kind: SimulationTraceRecord.Kind
	) -> void:
	var registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	registry.register_rule(rule)
	var construction: SimulationCoreConstructionResult = _construct_core(definition, state, registry)
	_expect(construction.succeeded(), "The undeclared-access test Core did not construct.")
	if not construction.succeeded():
		return
	var input_before: PackedByteArray = var_to_bytes_with_objects(state)
	var operation_result: SimulationOperationResult = construction.core._execute_compiled_rules(state, 7)
	_expect(operation_result.outcome == SimulationOperationOutcome.Type.FAULTED, "Undeclared state access did not fault.")
	_expect(not operation_result.has_candidate_state(), "A faulted operation exposed candidate Game State.")
	_expect(var_to_bytes_with_objects(state) == input_before, "A faulted operation mutated its input Game State.")
	_expect(_has_diagnostic(operation_result.diagnostics, expected_code), "The state-access fault has the wrong diagnostic code.")
	var matching_diagnostic: SimulationDiagnostic = _find_diagnostic(operation_result.diagnostics, expected_code)
	if matching_diagnostic != null:
		_expect(matching_diagnostic.rule_id == rule.stable_id, "The access diagnostic has the wrong Rule identifier.")
		_expect(matching_diagnostic.state_path == PUBLIC_TRUST_PATH, "The access diagnostic has the wrong state path.")
	var records: Array[SimulationTraceRecord] = operation_result.trace.get_records()
	var expected_record_count: int = 3 if rule is UndeclaredWriteRule else 2
	_expect(records.size() == expected_record_count, "The undeclared-access trace has the wrong record count.")
	if records.size() == expected_record_count:
		_expect(records[0] is RuleEvaluationTraceRecord, "The fault trace does not start with a Rule record.")
		var access_record: SimulationTraceRecord = records[records.size() - 1]
		_expect(access_record.kind == expected_trace_kind, "The fault trace has the wrong access record type.")
		var rule_record: RuleEvaluationTraceRecord = records[0] as RuleEvaluationTraceRecord
		if rule_record != null:
			_expect(rule_record.status == SimulationRuleEvaluation.Status.FAILED, "The trace did not mark the Rule failed.")
		if access_record is StateReadTraceRecord:
			_expect(not (access_record as StateReadTraceRecord).succeeded, "The undeclared read trace reports success.")
		if access_record is StateWriteTraceRecord:
			_expect(not (access_record as StateWriteTraceRecord).succeeded, "The undeclared write trace reports success.")
		if rule is UndeclaredWriteRule:
			var partial_write: StateWriteTraceRecord = records[1] as StateWriteTraceRecord
			_expect(
				partial_write != null and partial_write.succeeded,
				"The fault trace did not retain successful discarded internal work."
			)
			_expect(
				state.company.government_trust_points == 50,
				"A fault exposed a prior candidate-state write through the input Game State."
			)


func _verify_operation_result_contract(state: GameState) -> void:
	var diagnostics: Array[SimulationDiagnostic] = []
	var null_trace_result: SimulationOperationResult = SimulationOperationResult.new(
		SimulationOperationOutcome.Type.COMPLETED,
		state,
		null,
		diagnostics
	)
	_expect(null_trace_result.outcome == SimulationOperationOutcome.Type.FAULTED, "A null trace did not fault result construction.")
	_expect(not null_trace_result.has_candidate_state(), "A null-trace result exposed candidate state.")
	_expect(null_trace_result.trace != null, "A null-trace result still exposes a null trace.")
	if null_trace_result.trace != null:
		_expect(
			null_trace_result.trace.operation_id == &"operation.result_contract_fault",
			"A null-trace result has an unstable contract-fault trace identifier."
		)
		var contract_records: Array[SimulationTraceRecord] = null_trace_result.trace.get_records()
		_expect(contract_records.size() == 1, "The null-trace contract-fault trace is not minimal.")
		if contract_records.size() == 1:
			var contract_record: ContractFaultTraceRecord = contract_records[0] as ContractFaultTraceRecord
			_expect(
				contract_record != null
				and contract_record.diagnostic_code == &"operation_result.missing_trace",
				"The null-trace contract-fault trace has the wrong typed record."
			)
	var invalid_rejected: SimulationOperationResult = SimulationOperationResult.new(
		SimulationOperationOutcome.Type.REJECTED,
		state,
		SimulationTrace.new(&"operation.test.result_contract", 0),
		diagnostics
	)
	_expect(invalid_rejected.outcome == SimulationOperationOutcome.Type.FAULTED, "An inconsistent rejected result remained REJECTED.")
	_expect(not invalid_rejected.has_candidate_state(), "An inconsistent rejected result exposed candidate state.")
	_expect(
		_has_diagnostic(invalid_rejected.diagnostics, &"operation_result.candidate_contract"),
		"An inconsistent result did not report its contract fault."
	)
	var invalid_completed: SimulationOperationResult = SimulationOperationResult.new(
		SimulationOperationOutcome.Type.COMPLETED,
		null,
		SimulationTrace.new(&"operation.test.result_contract", 0),
		diagnostics
	)
	_expect(invalid_completed.outcome == SimulationOperationOutcome.Type.FAULTED, "A completed result without state remained COMPLETED.")
	var rejection_diagnostics: Array[SimulationDiagnostic] = [
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"operation.test.expected_rejection",
			"The test input is rejected."
		),
	]
	var rejected: SimulationOperationResult = SimulationOperationResult.new(
		SimulationOperationOutcome.Type.REJECTED,
		null,
		SimulationTrace.new(&"operation.test.result_contract", 0),
		rejection_diagnostics
	)
	_expect(rejected.outcome == SimulationOperationOutcome.Type.REJECTED, "A consistent rejected result changed outcome.")
	var decision: SimulationOperationResult = SimulationOperationResult.new(
		SimulationOperationOutcome.Type.DECISION_REQUIRED,
		state,
		SimulationTrace.new(&"operation.test.result_contract", 0),
		diagnostics
	)
	_expect(decision.has_candidate_state(), "A DECISION_REQUIRED result rejected complete candidate state.")


func _construct_core(
		definition: MarketingScenarioDefinition,
		state: GameState,
		rule_registry: SimulationRuleRegistry
	) -> SimulationCoreConstructionResult:
	return SimulationCore.create(
		rule_registry,
		definition.build_content_registry(),
		_build_state_path_registry(),
		_build_event_registry(),
		GRAPH_ID,
		GRAPH_VERSION,
		state
	)


func _build_state_path_registry() -> SimulationStatePathRegistry:
	var registry: SimulationStatePathRegistry = SimulationStatePathRegistry.new()
	registry.register_path(
		SimulationStatePath.new(
			PUBLIC_TRUST_PATH,
			SimulationStatePath.Accessor.COMPANY_PUBLIC_TRUST_POINTS,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			GOVERNMENT_TRUST_PATH,
			SimulationStatePath.Accessor.COMPANY_GOVERNMENT_TRUST_POINTS,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			CASH_LEDGER_PATH,
			SimulationStatePath.Accessor.CASH_LEDGER_TRANSACTIONS,
			SimulationStatePath.ValueType.CASH_LEDGER
		)
	)
	return registry


func _build_event_registry() -> SimulationEventRegistry:
	var registry: SimulationEventRegistry = SimulationEventRegistry.new()
	registry.register_event(TEST_EVENT_ID)
	return registry


func _expect_invalid_graph(
		definition: MarketingScenarioDefinition,
		state: GameState,
		rules: Array[SimulationRule],
		expected_code: StringName
	) -> void:
	var registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	for rule: SimulationRule in rules:
		registry.register_rule(rule)
	var construction: SimulationCoreConstructionResult = _construct_core(definition, state, registry)
	_expect(not construction.succeeded(), "An invalid Rule Graph constructed a Simulation Core: %s" % expected_code)
	_expect(_has_diagnostic(construction.diagnostics, expected_code), "Invalid Rule Graph diagnostic is missing: %s" % expected_code)


func _expect_construction_pin_failure(
		definition: MarketingScenarioDefinition,
		state: GameState,
		expected_text: String
	) -> void:
	var registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	registry.register_rule(NoOpRule.new(&"rule.test.pin_check"))
	var construction: SimulationCoreConstructionResult = _construct_core(definition, state, registry)
	_expect(not construction.succeeded(), "Simulation Core construction accepted mismatched %s." % expected_text)
	_expect(
		construction.format_diagnostics().contains(expected_text),
		"Simulation Core construction did not identify mismatched %s." % expected_text
	)


func _duplicate_state(state: GameState) -> GameState:
	var duplicated_resource: Resource = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if duplicated_resource is GameState:
		return duplicated_resource
	_expect(false, "The test could not deep-copy Game State.")
	return null


func _has_diagnostic(
		diagnostics: Array[SimulationDiagnostic],
		code: StringName
	) -> bool:
	return _find_diagnostic(diagnostics, code) != null


func _find_diagnostic(
		diagnostics: Array[SimulationDiagnostic],
		code: StringName
	) -> SimulationDiagnostic:
	for diagnostic: SimulationDiagnostic in diagnostics:
		if diagnostic.code == code:
			return diagnostic
	return null


func _remove_test_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var remove_error: Error = DirAccess.remove_absolute(absolute_path)
	if remove_error != OK:
		_expect(false, "The test file could not be removed: %s" % path)


func _finish() -> void:
	_remove_test_file(INVALID_SNAPSHOT_PATH)
	if _failure_count > 0:
		printerr("SIMULATION_CORE_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=6" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
