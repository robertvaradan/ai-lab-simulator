extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const GRAPH_ID: StringName = &"rule_graph.marketing.first_quarter"
const GRAPH_VERSION: int = 1
const START_PROJECT_COMMAND_TYPE: StringName = &"command.project.start"
const ACKNOWLEDGMENT_EVENT_TYPE: StringName = &"attention_event.acknowledgment"
const IDENTIFIER_ONLY_RESPONSE_TYPE: StringName = &"attention_response.identifier_only"
const TEST_SUCCESS: String = "PLAN_COMMITMENT_TEST_SUCCESS"

var _failure_count: int = 0


class NoOpRule extends SimulationRule:
	func _init() -> void:
		stable_id = &"rule.test.plan_commitment_noop"
		display_name = "Plan commitment test Rule"
		phase_id = &"rule_phase.test"
		execution_order = 10
		graph_group_id = &"rule_group.test"
		specification_references = ["docs/simulation/README.md"]

	func evaluate(_context: SimulationContext) -> SimulationRuleEvaluation:
		return SimulationRuleEvaluation.did_not_fire()


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
	var construction: SimulationCoreConstructionResult = _construct_core(definition, state_result.state)
	_expect(
		construction.succeeded(),
		"The Plan commitment Simulation Core did not construct:\n%s" % construction.format_diagnostics()
	)
	if not construction.succeeded():
		_finish()
		return

	_verify_empty_plan_commitment(construction.core, state_result.state)
	_verify_invalid_plan_does_not_commit(construction.core, state_result.state)
	_verify_prior_validation_does_not_bypass_commit(construction.core, state_result.state)
	_verify_identifier_without_required_response(construction.core, state_result.state)
	_verify_unresolved_attention_event_does_not_commit(construction.core, state_result.state)
	_verify_pending_command_batch_executes_once(construction.core, state_result.state, definition)
	_finish()


func _verify_empty_plan_commitment(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	var input_before: PackedByteArray = var_to_bytes_with_objects(state)
	var validation: PlanValidationResult = core.validate_plan(state, plan)
	_expect(validation.is_valid(), "An empty Plan failed validation:\n%s" % validation.format_diagnostics())
	_expect(var_to_bytes_with_objects(state) == input_before, "validate_plan mutated its input Game State.")
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "An empty Plan did not commit.")
	_expect(commit.has_candidate_state(), "A committed empty Plan has no candidate Game State.")
	_expect(var_to_bytes_with_objects(state) == input_before, "commit_plan mutated its input Game State.")
	if not commit.has_candidate_state():
		return
	_expect(commit.candidate_state != state, "commit_plan returned its input Game State instance.")
	_expect(commit.candidate_state.pending_command_batch != null, "commit_plan did not create a Pending Command Batch.")
	if commit.candidate_state.pending_command_batch != null:
		_expect(
			commit.candidate_state.pending_command_batch.is_immutable(),
			"The committed Pending Command Batch is mutable."
		)
		_expect(
			not commit.candidate_state.pending_command_batch.is_consumed(),
			"commit_plan consumed the Pending Command Batch."
		)
		_expect(
			commit.candidate_state.pending_command_batch.commands.is_empty(),
			"An empty Plan created Pending Command Batch Commands."
		)
		_expect(
			commit.candidate_state.pending_command_batch.stable_id
			== StableIdentifier.format_runtime_identifier(&"command_batch", 1),
			"The first Pending Command Batch identifier is incorrect."
		)
	_expect(
		commit.candidate_state.runtime_id_counters.next_sequence_by_entity_type[&"command_batch"] == 2,
		"commit_plan did not allocate the Pending Command Batch identifier."
	)
	_expect(
		commit.candidate_state.runtime_id_counters.next_sequence_by_entity_type[&"command"] == 1,
		"An empty Plan allocated a Command identifier."
	)
	_expect(commit.candidate_state.company.projects.is_empty(), "Plan commitment applied a Project Command.")
	_expect(commit.trace != null and commit.trace.is_sealed(), "The commit result did not seal its trace.")
	if commit.trace != null and commit.candidate_state.pending_command_batch != null:
		var records: Array[SimulationTraceRecord] = commit.trace.get_records()
		_expect(records.size() == 1, "The empty Plan commitment trace has the wrong record count.")
		if records.size() == 1:
			var commitment_record: PlanCommitmentTraceRecord = records[0] as PlanCommitmentTraceRecord
			_expect(commitment_record != null, "The commitment trace record has the wrong concrete type.")
			if commitment_record != null:
				_expect(
					commitment_record.pending_command_batch_id
					== commit.candidate_state.pending_command_batch.stable_id,
					"The commitment trace has the wrong Pending Command Batch identifier."
				)
				_expect(
					commitment_record.command_ids.is_empty(),
					"The empty Plan commitment trace recorded a Command identifier."
				)


func _verify_invalid_plan_does_not_commit(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	plan.commands.append(_make_command(state, 0, &"command.unknown.type"))
	var input_before: PackedByteArray = var_to_bytes_with_objects(state)
	var validation: PlanValidationResult = core.validate_plan(state, plan)
	_expect(not validation.is_valid(), "An unknown Command type passed Plan validation.")
	_expect(
		_has_plan_diagnostic(validation, &"plan.command_type_unknown"),
		"Unknown Command type validation has the wrong diagnostic."
	)
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.REJECTED, "An invalid Plan did not reject.")
	_expect(not commit.has_candidate_state(), "An invalid Plan exposed candidate Game State.")
	_expect(var_to_bytes_with_objects(state) == input_before, "A rejected commit mutated its input Game State.")
	_expect(
		_has_operation_diagnostic(commit, &"plan.command_type_unknown"),
		"The rejected commit has the wrong diagnostic."
	)


func _verify_prior_validation_does_not_bypass_commit(core: SimulationCore, state: GameState) -> void:
	var plan: Plan = Plan.new()
	var first_validation: PlanValidationResult = core.validate_plan(state, plan)
	_expect(first_validation.is_valid(), "The prior-validation test Plan was not valid.")
	plan.commands.append(_make_command(state, 0, &"command.unknown.type"))
	var second_validation: PlanValidationResult = core.validate_plan(state, plan)
	_expect(not second_validation.is_valid(), "A mutated Plan reused its earlier validation success.")
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(
		commit.outcome == SimulationOperationOutcome.Type.REJECTED,
		"A previously valid Plan skipped commit validation."
	)
	_expect(not commit.has_candidate_state(), "A stale validation success exposed candidate Game State.")

	var valid_plan: Plan = Plan.new()
	var valid_validation: PlanValidationResult = core.validate_plan(state, valid_plan)
	_expect(valid_validation.is_valid(), "The unchanged-state validation Plan was not valid.")
	var blocked_state: GameState = _duplicate_state(state)
	if blocked_state == null:
		return
	_add_acknowledgment_event(blocked_state)
	var blocked_commit: SimulationOperationResult = core.commit_plan(blocked_state, valid_plan)
	_expect(
		blocked_commit.outcome == SimulationOperationOutcome.Type.REJECTED,
		"A prior validation against a different Game State authorized commit."
	)
	_expect(
		_has_operation_diagnostic(blocked_commit, &"plan.attention_event_response_required"),
		"Commit against a later Game State did not require the new Attention Event response."
	)


func _verify_identifier_without_required_response(core: SimulationCore, state: GameState) -> void:
	var blocked_state: GameState = _duplicate_state(state)
	if blocked_state == null:
		return
	var event: AttentionEventState = _add_acknowledgment_event(blocked_state)
	var plan: Plan = Plan.new()
	var identifier_only: AttentionEventResponse = AttentionEventResponse.new()
	identifier_only.attention_event_id = event.stable_id
	identifier_only.response_type_id = IDENTIFIER_ONLY_RESPONSE_TYPE
	plan.attention_event_responses.append(identifier_only)
	var input_before: PackedByteArray = var_to_bytes_with_objects(blocked_state)
	var commit: SimulationOperationResult = core.commit_plan(blocked_state, plan)
	_expect(
		commit.outcome == SimulationOperationOutcome.Type.REJECTED,
		"An Attention Event identifier without its required response committed."
	)
	_expect(not commit.has_candidate_state(), "An identifier-only response exposed candidate Game State.")
	_expect(var_to_bytes_with_objects(blocked_state) == input_before, "The identifier-only commit mutated Game State.")
	_expect(
		blocked_state.attention_events.size() == 1
		and blocked_state.attention_events[0].stable_id == event.stable_id,
		"The identifier-only response resolved the Attention Event on the input Game State."
	)
	_expect(
		_has_operation_diagnostic(commit, &"plan.attention_event_response_type_mismatch")
		or _has_operation_diagnostic(commit, &"plan.attention_event_response_required"),
		"The identifier-only response did not report a required-response rejection."
	)


func _verify_unresolved_attention_event_does_not_commit(core: SimulationCore, state: GameState) -> void:
	var blocked_state: GameState = _duplicate_state(state)
	if blocked_state == null:
		return
	var first_event: AttentionEventState = _add_acknowledgment_event(blocked_state)
	var second_event: AttentionEventState = _add_acknowledgment_event(blocked_state)
	var plan: Plan = Plan.new()
	plan.attention_event_responses.append(_make_acknowledgment(first_event.stable_id))
	var commit: SimulationOperationResult = core.commit_plan(blocked_state, plan)
	_expect(
		commit.outcome == SimulationOperationOutcome.Type.REJECTED,
		"A Plan that left one Attention Event unresolved committed."
	)
	_expect(not commit.has_candidate_state(), "A partially resolved Plan exposed candidate Game State.")
	_expect(
		_has_operation_diagnostic(commit, &"plan.attention_event_response_required"),
		"A partially resolved Plan did not identify the missing Attention Event response."
	)
	_expect(
		blocked_state.attention_events.size() == 2,
		"A rejected Attention Event Plan changed the input Attention Event batch."
	)

	var complete_plan: Plan = Plan.new()
	complete_plan.attention_event_responses.append(_make_acknowledgment(first_event.stable_id))
	complete_plan.attention_event_responses.append(_make_acknowledgment(second_event.stable_id))
	var complete_commit: SimulationOperationResult = core.commit_plan(blocked_state, complete_plan)
	_expect(
		complete_commit.outcome == SimulationOperationOutcome.Type.COMPLETED,
		"A Plan with every required Attention Event response did not commit."
	)
	if complete_commit.has_candidate_state():
		_expect(
			complete_commit.candidate_state.attention_events.is_empty(),
			"commit_plan did not clear satisfied Attention Events."
		)


func _verify_pending_command_batch_executes_once(
		core: SimulationCore,
		state: GameState,
		definition: MarketingScenarioDefinition
	) -> void:
	var plan: Plan = Plan.new()
	var start_command: Command = _make_command(state, 0, START_PROJECT_COMMAND_TYPE)
	var mutation_payload: Dictionary[StringName, Variant] = {}
	mutation_payload[&"project_id"] = &"project.research.frontier_model"
	start_command.payload = mutation_payload
	plan.commands.append(start_command)
	var commit: SimulationOperationResult = core.commit_plan(state, plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "A valid Command Plan did not commit.")
	_expect(commit.has_candidate_state(), "A valid Command Plan has no candidate Game State.")
	if not commit.has_candidate_state():
		return
	_expect(
		commit.candidate_state.company.projects.is_empty(),
		"Plan commitment applied a Command instead of storing a Pending Command Batch."
	)
	var batch: PendingCommandBatchState = commit.candidate_state.pending_command_batch
	_expect(batch != null, "A valid Command Plan has no Pending Command Batch.")
	if batch == null:
		return
	_expect(batch.commands.size() == 1, "The committed Pending Command Batch has the wrong Command count.")
	if batch.commands.size() == 1:
		_expect(batch.commands[0].is_immutable(), "A committed Command remained mutable.")
		_expect(
			batch.commands[0].stable_id == start_command.stable_id,
			"The committed Command identifier is incorrect."
		)
	start_command.payload[&"mutated_after_commit"] = true
	if batch.commands.size() == 1:
		_expect(
			not batch.commands[0].payload.has(&"mutated_after_commit"),
			"A draft Command mutation changed the committed Pending Command Batch."
		)
	_expect(batch.consume_once(), "The first Pending Command Batch consumption failed.")
	_expect(not batch.consume_once(), "A Pending Command Batch executed more than once.")
	_expect(batch.is_consumed(), "The consumed Pending Command Batch is not marked consumed.")
	var consumed_validation: GameStateValidationResult = GameStateValidator.validate(
		commit.candidate_state,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		definition.build_content_reference_catalog()
	)
	_expect(not consumed_validation.is_valid(), "Game State validation accepted a consumed Pending Command Batch.")
	_expect(
		consumed_validation.format_errors().contains("consumed"),
		"Game State validation did not identify a consumed Pending Command Batch."
	)


func _construct_core(
		definition: MarketingScenarioDefinition,
		state: GameState
	) -> SimulationCoreConstructionResult:
	var rule_registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	rule_registry.register_rule(NoOpRule.new())
	return SimulationCore.create(
		rule_registry,
		_build_content_registry(definition),
		SimulationStatePathRegistry.new(),
		SimulationEventRegistry.new(),
		GRAPH_ID,
		GRAPH_VERSION,
		state
	)


func _build_content_registry(definition: MarketingScenarioDefinition) -> SimulationContentRegistry:
	var registry: SimulationContentRegistry = definition.build_content_registry()
	_expect(
		registry.register_content(ACKNOWLEDGMENT_EVENT_TYPE),
		"The test content registry rejected the acknowledgment Attention Event type."
	)
	_expect(
		registry.register_attention_event_response_validator(
			AcknowledgmentAttentionEventResponseValidator.new(ACKNOWLEDGMENT_EVENT_TYPE)
		),
		"The test content registry rejected the acknowledgment response validator."
	)
	return registry


func _make_command(state: GameState, command_index: int, command_type_id: StringName) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = command_type_id
	return command


func _add_acknowledgment_event(state: GameState) -> AttentionEventState:
	var next_event_sequence: int = state.runtime_id_counters.next_sequence_by_entity_type[&"event"]
	var event: AttentionEventState = AttentionEventState.new()
	event.stable_id = StableIdentifier.format_runtime_identifier(&"event", next_event_sequence)
	event.event_type_id = ACKNOWLEDGMENT_EVENT_TYPE
	state.attention_events.append(event)
	var next_counters: Dictionary[StringName, int] = {}
	next_counters.assign(state.runtime_id_counters.next_sequence_by_entity_type)
	next_counters[&"event"] = next_event_sequence + 1
	state.runtime_id_counters.next_sequence_by_entity_type = next_counters
	return event


func _make_acknowledgment(event_id: StringName) -> AttentionEventResponse:
	var response: AttentionEventResponse = AttentionEventResponse.new()
	response.attention_event_id = event_id
	response.response_type_id = AcknowledgmentAttentionEventResponseValidator.ACKNOWLEDGMENT_RESPONSE_TYPE_ID
	return response


func _duplicate_state(state: GameState) -> GameState:
	var duplicated_resource: Resource = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	if duplicated_resource is GameState:
		return duplicated_resource
	_expect(false, "The test could not deep-copy Game State.")
	return null


func _has_plan_diagnostic(result: PlanValidationResult, code: StringName) -> bool:
	for diagnostic: SimulationDiagnostic in result.diagnostics:
		if diagnostic.code == code:
			return true
	return false


func _has_operation_diagnostic(result: SimulationOperationResult, code: StringName) -> bool:
	for diagnostic: SimulationDiagnostic in result.diagnostics:
		if diagnostic.code == code:
			return true
	return false


func _finish() -> void:
	if _failure_count > 0:
		printerr("PLAN_COMMITMENT_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=6" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
