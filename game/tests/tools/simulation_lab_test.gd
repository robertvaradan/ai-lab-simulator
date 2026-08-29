extends SceneTree

const SNAPSHOT_PATH: String = "user://ms2_01_lab_snapshot.tres"
const TEST_SUCCESS: String = "SIMULATION_LAB_TEST_SUCCESS"
const BUILD_LAB_ID: StringName = &"project.campus.build_laboratory"
const RESEARCH_ID: StringName = &"project.research.frontier_model"

var _failure_count: int = 0


func _initialize() -> void:
	_remove_test_file(SNAPSHOT_PATH)
	var created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(created.succeeded(), "The Simulation Laboratory session did not start:\n%s" % created.format_diagnostics())
	if not created.succeeded():
		_finish()
		return
	var session: SimulationLabSession = created.session
	_verify_starting_inspection(session)
	_verify_empty_plan_advance(session)
	_verify_snapshot(session)
	_verify_replay(session)
	_verify_research_run()
	_verify_replay_mismatch()
	_finish()


func _verify_starting_inspection(session: SimulationLabSession) -> void:
	_expect(session.get_core() != null, "The laboratory session has no Simulation Core.")
	_expect(session.get_state() != null, "The laboratory session has no Game State.")
	_expect(session.get_cash_ledger() != null, "The laboratory session has no Cash Ledger.")
	_expect(session.get_cash_ledger().calculate_balance_musd() == 150, "The starting Cash balance is incorrect.")
	_expect(session.get_state().calendar.current_month_step_index == 0, "The starting Month Step is incorrect.")
	_expect(session.get_traces().is_empty(), "The new laboratory session already has traces.")


func _verify_empty_plan_advance(session: SimulationLabSession) -> void:
	var validation: PlanValidationResult = session.validate_staged_plan()
	_expect(validation.is_valid(), "The empty laboratory Plan is invalid:\n%s" % validation.format_diagnostics())
	var commit: SimulationOperationResult = session.commit_staged_plan()
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The empty laboratory Plan did not commit.")
	var advanced: SimulationOperationResult = session.advance_until_attention_required()
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The laboratory advance did not stop at the Attention Boundary."
	)
	_expect(session.get_state().calendar.current_month_step_index == 3, "The laboratory advance did not end at Month Step 3.")
	_expect(session.get_cash_ledger().calculate_balance_musd() == 123, "The empty-plan laboratory Cash is incorrect.")
	_expect(session.get_traces().size() == 2, "The laboratory session did not record commit and advance traces.")
	_expect(session.get_exported_operations().size() == 2, "The laboratory session did not export commit and advance operations.")


func _verify_snapshot(session: SimulationLabSession) -> void:
	var save_result: GameStateSaveResult = session.save_snapshot(SNAPSHOT_PATH)
	_expect(save_result.succeeded(), "The laboratory snapshot save failed:\n%s" % save_result.format_errors())
	var restored: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(restored.succeeded(), "The snapshot laboratory session did not start.")
	if not restored.succeeded():
		return
	var load_result: GameStateLoadResult = restored.session.load_snapshot(SNAPSHOT_PATH)
	_expect(load_result.succeeded(), "The laboratory snapshot load failed:\n%s" % load_result.format_errors())
	_expect(
		var_to_bytes_with_objects(session.get_state())
		== var_to_bytes_with_objects(restored.session.get_state()),
		"The loaded laboratory snapshot does not match the saved Game State."
	)


func _verify_replay(session: SimulationLabSession) -> void:
	var replay: SimulationLabReplayResult = session.replay_exported_operations()
	_expect(replay.succeeded(), "The laboratory replay failed:\n%s" % replay.format_diagnostics())
	_expect(replay.matched, "The laboratory replay did not match.")
	if replay.session == null:
		return
	_expect(
		replay.session.get_cash_ledger().calculate_balance_musd() == 123,
		"The laboratory replay Cash is incorrect."
	)


func _verify_research_run() -> void:
	var created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(created.succeeded(), "The Research laboratory session did not start.")
	if not created.succeeded():
		return
	var session: SimulationLabSession = created.session
	_complete_build_laboratory(session)
	session.stage_command(_research_command(session.get_state(), 0))
	var commit: SimulationOperationResult = session.commit_staged_plan()
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The Research laboratory Plan did not commit.")
	var advanced: SimulationOperationResult = session.advance_until_attention_required()
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The Research laboratory advance did not stop at the Attention Boundary."
	)
	_expect(session.get_state().company.projects.has(RESEARCH_ID), "The Research Project is missing.")
	_expect(session.get_cash_ledger().calculate_balance_musd() == 48, "The Research-first laboratory Cash is incorrect.")
	var replay: SimulationLabReplayResult = session.replay_exported_operations()
	_expect(replay.succeeded(), "The Research laboratory replay failed:\n%s" % replay.format_diagnostics())


func _verify_replay_mismatch() -> void:
	var created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(created.succeeded(), "The mismatch laboratory session did not start.")
	if not created.succeeded():
		return
	var session: SimulationLabSession = created.session
	session.commit_staged_plan()
	session.advance_until_attention_required()
	var operations: Array[Dictionary] = session.get_exported_operations()
	_expect(operations.size() == 2, "The mismatch export does not contain two operations.")
	if operations.size() != 2:
		return
	operations.remove_at(1)
	var replay: SimulationLabReplayResult = session.replay_operations(operations)
	_expect(not replay.succeeded(), "A truncated laboratory replay succeeded.")
	_expect(not replay.matched, "A truncated laboratory replay reported a match.")


func _complete_build_laboratory(session: SimulationLabSession) -> void:
	session.stage_command(_build_lab_command(session.get_state(), 0))
	session.commit_staged_plan()
	session.step_month()


func _build_lab_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = BUILD_LAB_ID
	command.payload = payload
	return command


func _research_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = RESEARCH_ID
	payload[&"model_display_name"] = "Aperture"
	payload[&"model_version_label"] = "2.0"
	payload[&"release_strategy_id"] = &"release_strategy.commercial_api"
	command.payload = payload
	return command


func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	_remove_test_file(SNAPSHOT_PATH)
	if _failure_count > 0:
		printerr("SIMULATION_LAB_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=6" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
