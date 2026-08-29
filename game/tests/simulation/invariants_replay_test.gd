extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const TEST_SUCCESS: String = "INVARIANTS_REPLAY_TEST_SUCCESS"
const BUILD_LAB_ID: StringName = &"project.campus.build_laboratory"
const RESEARCH_ID: StringName = &"project.research.frontier_model"
const SCALE_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_PROJECT_ID: StringName = &"project.application.coding_agent"
const STARTING_MODEL_ID: StringName = &"model.player.starting"

var _failure_count: int = 0


func _initialize() -> void:
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
	var construction: SimulationCoreConstructionResult = MarketingScenarioFactory.create_core(
		definition,
		state_result.state
	)
	_expect(
		construction.succeeded(),
		"The invariant Simulation Core did not construct:\n%s" % construction.format_diagnostics()
	)
	if not construction.succeeded():
		_finish()
		return

	_verify_empty_plan_invariants(construction.core, state_result.state)
	_verify_cash_fault(construction.core, state_result.state)
	_verify_identity_fault(construction.core, state_result.state)
	_verify_early_completion_fault(construction.core, state_result.state)
	_verify_replay("empty", construction.core, definition, state_result.state, [])
	var after_lab: GameState = _complete_build_laboratory(construction.core, state_result.state)
	if after_lab != null:
		_verify_replay(
			"research-first",
			construction.core,
			definition,
			after_lab,
			[_research_command(after_lab, 0)]
		)
		_verify_replay(
			"scale-first",
			construction.core,
			definition,
			after_lab,
			[_scale_command(after_lab, 0)]
		)
		_verify_replay(
			"application-first",
			construction.core,
			definition,
			after_lab,
			[_coding_agent_command(after_lab, 0)]
		)
		_verify_replay(
			"hybrid",
			construction.core,
			definition,
			after_lab,
			[_research_command(after_lab, 0), _coding_agent_command(after_lab, 1)]
		)
	_finish()


func _verify_empty_plan_invariants(core: SimulationCore, state: GameState) -> void:
	var result: SimulationOperationResult = core.step_month(state)
	_expect(result.outcome == SimulationOperationOutcome.Type.COMPLETED, "The invariant Month Step did not complete.")
	_expect(result.has_candidate_state(), "The invariant Month Step has no candidate Game State.")
	_expect(result.diagnostics.is_empty(), "The invariant Month Step returned diagnostics.")
	if not result.has_candidate_state():
		return
	var diagnostics: Array[SimulationDiagnostic] = SimulationInvariantChecker.check_after_month_step(
		result.candidate_state,
		result.trace,
		core.get_compiled_graph().ordered_rules,
		core.get_content_registry(),
		0,
		state.cash_ledger.calculate_balance_musd(),
		0
	)
	_expect(diagnostics.is_empty(), "The valid Month Step failed Simulation Invariants.")


func _verify_cash_fault(core: SimulationCore, state: GameState) -> void:
	var result: SimulationOperationResult = core.step_month(state)
	if not result.has_candidate_state():
		_expect(false, "The cash-fault Month Step has no candidate Game State.")
		return
	var mutated: GameState = _copy_state(result.candidate_state)
	if mutated == null:
		_expect(false, "The cash-fault Game State copy failed.")
		return
	mutated.cash_ledger.opening_balance_musd = mutated.cash_ledger.opening_balance_musd + 11
	var diagnostics: Array[SimulationDiagnostic] = SimulationInvariantChecker.check_after_month_step(
		mutated,
		result.trace,
		core.get_compiled_graph().ordered_rules,
		core.get_content_registry(),
		0,
		state.cash_ledger.calculate_balance_musd(),
		0
	)
	_expect_invariant(
		diagnostics,
		&"invariant.cash_balance",
		SimulationInvariantChecker.INVARIANT_CASH,
		1
	)


func _verify_identity_fault(core: SimulationCore, state: GameState) -> void:
	var result: SimulationOperationResult = core.step_month(state)
	if not result.has_candidate_state():
		_expect(false, "The identity-fault Month Step has no candidate Game State.")
		return
	var mutated: GameState = _copy_state(result.candidate_state)
	if mutated == null or not mutated.company.models.has(STARTING_MODEL_ID):
		_expect(false, "The identity-fault Game State copy failed.")
		return
	var source_model: ModelState = mutated.company.models[STARTING_MODEL_ID]
	var duplicate_model: ModelState = ModelState.new()
	duplicate_model.stable_id = source_model.stable_id
	duplicate_model.display_name = source_model.display_name
	duplicate_model.version_label = source_model.version_label
	duplicate_model.release_state_id = source_model.release_state_id
	duplicate_model.release_strategy_id = source_model.release_strategy_id
	duplicate_model.evaluations = source_model.evaluations
	duplicate_model.training_compute_unit_months = source_model.training_compute_unit_months
	duplicate_model.inference_compute_unit_months_per_contract = (
		source_model.inference_compute_unit_months_per_contract
	)
	mutated.company.models[&"model.player.duplicate"] = duplicate_model
	var diagnostics: Array[SimulationDiagnostic] = SimulationInvariantChecker.check_after_month_step(
		mutated,
		result.trace,
		core.get_compiled_graph().ordered_rules,
		core.get_content_registry(),
		0,
		state.cash_ledger.calculate_balance_musd(),
		0
	)
	_expect_invariant(
		diagnostics,
		&"invariant.duplicate_entity_id",
		SimulationInvariantChecker.INVARIANT_IDENTITY,
		1
	)


func _verify_early_completion_fault(core: SimulationCore, state: GameState) -> void:
	var after_lab: GameState = _complete_build_laboratory(core, state)
	if after_lab == null:
		return
	var advanced: SimulationOperationResult = _advance_until_boundary(
		core,
		after_lab,
		[_scale_command(after_lab, 0)]
	)
	if advanced == null or not advanced.has_candidate_state():
		return
	var mutated: GameState = _copy_state(advanced.candidate_state)
	if mutated == null or not mutated.company.projects.has(SCALE_ID):
		_expect(false, "The early-completion Game State copy failed.")
		return
	mutated.company.projects[SCALE_ID].completed_month_step_index = 1
	var previous_cash_balance_musd: int = mutated.cash_ledger.calculate_balance_musd()
	for transaction: LedgerTransactionState in mutated.cash_ledger.transactions:
		if transaction != null and transaction.month_step_index == 3:
			previous_cash_balance_musd -= transaction.amount_musd
	var diagnostics: Array[SimulationDiagnostic] = SimulationInvariantChecker.check_after_month_step(
		mutated,
		advanced.trace,
		core.get_compiled_graph().ordered_rules,
		core.get_content_registry(),
		2,
		previous_cash_balance_musd,
		0
	)
	_expect_invariant(
		diagnostics,
		&"invariant.project_completed_before_declared_month",
		SimulationInvariantChecker.INVARIANT_TIME,
		3
	)


func _verify_replay(
		label: String,
		core: SimulationCore,
		definition: MarketingScenarioDefinition,
		state: GameState,
		commands: Array[Command]
	) -> void:
	var first: SimulationOperationResult = _advance_until_boundary(core, state, commands)
	var second: SimulationOperationResult = _advance_until_boundary(core, state, commands)
	if first == null or second == null:
		return
	if not first.has_candidate_state() or not second.has_candidate_state():
		return
	_expect(first.diagnostics.is_empty(), "%s first replay returned diagnostics." % label)
	_expect(second.diagnostics.is_empty(), "%s second replay returned diagnostics." % label)
	_expect(
		var_to_bytes_with_objects(first.candidate_state)
		== var_to_bytes_with_objects(second.candidate_state),
		"%s replay produced a different Game State." % label
	)
	_expect(
		first.trace.to_canonical_data() == second.trace.to_canonical_data(),
		"%s replay produced a different Simulation Trace." % label
	)
	_expect(
		var_to_bytes_with_objects(first.candidate_state.cash_ledger)
		== var_to_bytes_with_objects(second.candidate_state.cash_ledger),
		"%s replay produced a different Cash Ledger." % label
	)
	_expect(
		first.candidate_state.cash_ledger.calculate_balance_musd()
		== second.candidate_state.cash_ledger.calculate_balance_musd(),
		"%s replay produced a different Cash balance." % label
	)
	var reconstructed: SimulationCoreConstructionResult = MarketingScenarioFactory.create_core(
		definition,
		state
	)
	_expect(reconstructed.succeeded(), "%s reconstructed Simulation Core failed." % label)
	if not reconstructed.succeeded():
		return
	var reconstructed_run: SimulationOperationResult = _advance_until_boundary(
		reconstructed.core,
		state,
		commands
	)
	if reconstructed_run == null or not reconstructed_run.has_candidate_state():
		return
	_expect(
		var_to_bytes_with_objects(first.candidate_state)
		== var_to_bytes_with_objects(reconstructed_run.candidate_state),
		"%s reconstructed core produced a different Game State." % label
	)


func _complete_build_laboratory(core: SimulationCore, state: GameState) -> GameState:
	var plan: Plan = Plan.new()
	plan.commands.append(_build_lab_command(state, 0))
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The Build Laboratory Plan did not commit.")
	if not commit.has_candidate_state():
		return null
	var stepped: SimulationOperationResult = core.step_month(commit.candidate_state)
	_expect(
		stepped.outcome == SimulationOperationOutcome.Type.COMPLETED,
		"The Build Laboratory Month Step did not complete."
	)
	if not stepped.has_candidate_state():
		return null
	return stepped.candidate_state


func _advance_until_boundary(
		core: SimulationCore,
		state: GameState,
		commands: Array[Command]
	) -> SimulationOperationResult:
	var plan: Plan = Plan.new()
	plan.commands.assign(commands)
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The invariant Plan did not commit.")
	if not commit.has_candidate_state():
		return null
	var advanced: SimulationOperationResult = core.advance_until_attention_required(commit.candidate_state)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"Advance did not stop at the Quarter Boundary."
	)
	_expect(advanced.has_candidate_state(), "Advance has no candidate Game State.")
	if advanced.has_candidate_state():
		_expect(
			advanced.candidate_state.calendar.current_month_step_index == 3,
			"Advance did not end at Month Step 3."
		)
	return advanced


func _build_lab_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = BUILD_LAB_ID
	command.payload = payload
	return command


func _research_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = RESEARCH_ID
	payload[&"model_display_name"] = "Aperture"
	payload[&"model_version_label"] = "2.0"
	payload[&"release_strategy_id"] = &"release_strategy.commercial_api"
	command.payload = payload
	return command


func _scale_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = SCALE_ID
	command.payload = payload
	return command


func _coding_agent_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CODING_AGENT_PROJECT_ID
	payload[&"supporting_model_id"] = STARTING_MODEL_ID
	command.payload = payload
	return command


func _make_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	return command


func _copy_state(state: GameState) -> GameState:
	var duplicated_resource: Resource = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if duplicated_resource is GameState:
		return duplicated_resource
	return null


func _expect_invariant(
		diagnostics: Array[SimulationDiagnostic],
		code: StringName,
		invariant_id: StringName,
		month_step_index: int
	) -> void:
	var found: bool = false
	for diagnostic: SimulationDiagnostic in diagnostics:
		if diagnostic.code != code:
			continue
		found = true
		_expect(diagnostic.invariant_id == invariant_id, "Invariant identifier %s is incorrect." % code)
		_expect(
			diagnostic.month_step_index == month_step_index,
			"Invariant %s Month Step index is incorrect." % code
		)
	_expect(found, "Expected invariant diagnostic %s is missing." % code)


func _finish() -> void:
	if _failure_count > 0:
		printerr("INVARIANTS_REPLAY_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=9" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
