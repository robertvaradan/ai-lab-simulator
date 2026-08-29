extends SceneTree

const SUCCESS_MARKER: String = "SIMULATION_LAB_RUN_SUCCESS"


func _initialize() -> void:
	var created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	if not created.succeeded():
		printerr("SIMULATION_LAB_RUN_FAILURE\n%s" % created.format_diagnostics())
		quit(1)
		return
	var session: SimulationLabSession = created.session
	var commit: SimulationOperationResult = session.commit_staged_plan()
	if commit.outcome != SimulationOperationOutcome.Type.COMPLETED:
		printerr("SIMULATION_LAB_RUN_FAILURE commit failed")
		quit(1)
		return
	var advanced: SimulationOperationResult = session.advance_until_attention_required()
	if advanced.outcome != SimulationOperationOutcome.Type.DECISION_REQUIRED:
		printerr("SIMULATION_LAB_RUN_FAILURE advance outcome=%s" % advanced.outcome)
		quit(1)
		return
	var replay: SimulationLabReplayResult = session.replay_exported_operations()
	if not replay.succeeded():
		printerr("SIMULATION_LAB_RUN_FAILURE replay\n%s" % replay.format_diagnostics())
		quit(1)
		return
	print(
		"%s month=%d cash=%d traces=%d"
		% [
			SUCCESS_MARKER,
			session.get_state().calendar.current_month_step_index,
			session.get_cash_ledger().calculate_balance_musd(),
			session.get_traces().size(),
		]
	)
	quit(0)
