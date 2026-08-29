extends SceneTree

const TEST_SUCCESS: String = "MARKETING_PLAY_MANAGEMENT_TEST_SUCCESS"
const BUILD_LAB_ID: StringName = &"project.campus.build_laboratory"
const RESEARCH_ID: StringName = &"project.research.frontier_model"
const SCALE_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_PROJECT_ID: StringName = &"project.application.coding_agent"

var _failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var forecast_host: MarketingPlayHost = _make_host()
	root.add_child(forecast_host)
	_verify_forecasts(forecast_host)
	forecast_host.queue_free()
	var rejection_host: MarketingPlayHost = _make_host()
	root.add_child(rejection_host)
	_verify_three_project_rejection(rejection_host)
	rejection_host.queue_free()
	var hybrid_host: MarketingPlayHost = _make_host()
	root.add_child(hybrid_host)
	_verify_hybrid_completion(hybrid_host)
	hybrid_host.queue_free()
	_finish()


func _verify_forecasts(host: MarketingPlayHost) -> void:
	var forecast_text: String = host.get_overlay().get_forecast_text()
	_expect(forecast_text.contains("Coding 80-84"), "The overlay does not present the Northstar coding projection.")
	_expect(forecast_text.contains("Reasoning 76-80"), "The overlay does not present the Northstar reasoning projection.")
	_expect(forecast_text.contains("Efficiency 70-74"), "The overlay does not present the Northstar efficiency projection.")


func _verify_three_project_rejection(host: MarketingPlayHost) -> void:
	host.get_overlay().set_research_selected(true)
	host.get_overlay().set_scale_selected(true)
	host.get_overlay().set_coding_agent_selected(true)
	var plan: Plan = host.get_overlay().build_plan(host.get_current_state())
	_expect(plan.commands.size() == 3, "The three-Project overlay Plan does not contain three Commands.")
	var result: SimulationOperationResult = host.advance_with_plan(plan)
	_expect(result.outcome == SimulationOperationOutcome.Type.REJECTED, "The three-Project Plan was not rejected.")
	_expect(host.get_current_state().calendar.current_month_step_index == 0, "A rejected Plan advanced time.")
	host.get_overlay().set_research_selected(false)
	host.get_overlay().set_scale_selected(false)
	host.get_overlay().set_coding_agent_selected(false)


func _verify_hybrid_completion(host: MarketingPlayHost) -> void:
	_complete_build_laboratory_on_host(host)
	host.get_overlay().set_research_selected(true)
	host.get_overlay().set_coding_agent_selected(true)
	host.get_overlay().set_model_identity("Aperture", "2.0")
	var lab_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(lab_created.succeeded(), "The hybrid laboratory session did not start.")
	if not lab_created.succeeded():
		return
	var lab: SimulationLabSession = lab_created.session
	_complete_build_laboratory_session(lab)
	lab.stage_command(_research_command(lab.get_state(), 0))
	lab.stage_command(_coding_command(lab.get_state(), 1))
	lab.commit_staged_plan()
	lab.advance_until_attention_required()
	var plan: Plan = host.get_overlay().build_plan(host.get_current_state())
	_expect(plan.commands.size() == 2, "The hybrid overlay Plan does not contain two Commands.")
	var advanced: SimulationOperationResult = host.advance_with_plan(plan)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The hybrid production Advance did not stop at the Attention Boundary."
	)
	_expect(host.get_current_state().company.projects.has(RESEARCH_ID), "The hybrid run is missing the Research Project.")
	_expect(
		host.get_current_state().company.projects.has(CODING_AGENT_PROJECT_ID),
		"The hybrid run is missing the Coding Agent Project."
	)
	_expect(not host.get_current_state().company.projects.has(SCALE_ID), "The hybrid run started the Scale Project.")
	_expect(
		var_to_bytes_with_objects(host.get_current_state())
		== var_to_bytes_with_objects(lab.get_state()),
		"The hybrid production run does not match the laboratory."
	)
	_expect(host.get_overlay().get_report_text().contains("quarterly_report.ending"), "The overlay does not present the ending report.")
	_expect(host.get_overlay().get_attention_text().contains("attention_event.quarter_boundary"), "The overlay does not present the Quarter Boundary Attention Event.")
	_expect(host.get_current_state().cash_ledger.calculate_balance_musd() == 14, "The hybrid ending Cash is incorrect.")


func _make_host() -> MarketingPlayHost:
	var host: MarketingPlayHost = MarketingPlayHost.new()
	host.name = "MarketingPlayHost"
	var overlay: MarketingPlayOverlay = MarketingPlayOverlay.new()
	overlay.name = "Overlay"
	host.add_child(overlay)
	return host


func _complete_build_laboratory_session(lab: SimulationLabSession) -> void:
	lab.stage_command(_build_lab_command(lab.get_state(), 0))
	lab.commit_staged_plan()
	lab.step_month()


func _complete_build_laboratory_on_host(host: MarketingPlayHost) -> void:
	host.get_overlay().set_build_laboratory_selected(true)
	var plan: Plan = host.get_overlay().build_plan(host.get_current_state())
	var commit: SimulationOperationResult = host.get_core().commit_plan(host.get_current_state(), plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The Build Laboratory Plan did not commit.")
	if not commit.has_candidate_state():
		return
	var stepped: SimulationOperationResult = host.get_core().step_month(commit.candidate_state)
	_expect(stepped.has_candidate_state(), "The Build Laboratory Month Step has no candidate Game State.")
	if not stepped.has_candidate_state():
		return
	host.get_game_state_service().publish_operation_result(stepped)
	host.get_overlay().set_build_laboratory_selected(false)
	host.refresh_presentation()


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


func _coding_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CODING_AGENT_PROJECT_ID
	payload[&"supporting_model_id"] = &"model.player.starting"
	command.payload = payload
	return command


func _finish() -> void:
	if _failure_count > 0:
		printerr("MARKETING_PLAY_MANAGEMENT_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=3" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
