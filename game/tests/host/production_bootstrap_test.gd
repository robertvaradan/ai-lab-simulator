extends SceneTree

const TEST_SUCCESS: String = "PRODUCTION_BOOTSTRAP_TEST_SUCCESS"

var _failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_verify_scenes()
	_verify_sdf_contract()
	var host: CampaignHost = _make_host()
	root.add_child(host)
	_verify_host_ready(host)
	_verify_opening_path_and_advance(host)
	_verify_skill_and_tech(host)
	_verify_data_center(host)
	_verify_fail_state(host)
	host.queue_free()
	_finish()


func _verify_scenes() -> void:
	var init_scene: PackedScene = load("res://scenes/init.tscn") as PackedScene
	_expect(init_scene != null, "The init scene did not load.")
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn") as PackedScene
	_expect(menu_scene != null, "The Main Menu scene did not load.")
	var campaign_scene: PackedScene = load("res://scenes/campaign.tscn") as PackedScene
	_expect(campaign_scene != null, "The campaign scene did not load.")
	var campaign_text: String = FileAccess.get_file_as_string("res://scenes/campaign.tscn")
	_expect(campaign_text.contains("sdf_campus_presenter.gd"), "The campaign scene does not use the SDF presenter.")
	_expect(not campaign_text.contains("campus_blockout"), "The campaign scene instances the mesh campus blockout.")
	var menu: MainMenu = menu_scene.instantiate() as MainMenu
	_expect(menu != null, "The Main Menu root is not MainMenu.")
	root.add_child(menu)
	_expect(menu.get_start_button() != null, "The Main Menu has no Start button.")
	_expect(menu.get_start_button().text == "Start", "The Main Menu Start label is incorrect.")
	menu.queue_free()


func _verify_sdf_contract() -> void:
	_expect(
		SdfCampusPresenter.OUTPUT_SIZE == Vector2i(1920, 1080),
		"The campaign SDF output size is not 1920x1080."
	)
	var starting: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(starting.succeeded(), "The starting laboratory session did not start.")
	if not starting.succeeded():
		return
	_expect(
		SdfCampusPresenter.state_name_from_game_state(starting.session.get_state()) == &"growth",
		"The starting campaign SDF state is not growth."
	)
	var scale_session: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(scale_session.succeeded(), "The Scale laboratory session did not start.")
	if not scale_session.succeeded():
		return
	var lab: SimulationLabSession = scale_session.session
	lab.stage_command(_scale_command(lab.get_state(), 0))
	lab.commit_staged_plan()
	lab.step_month()
	_expect(
		SdfCampusPresenter.state_name_from_game_state(lab.get_state()) == &"overload",
		"The burst compute contract did not select the overload SDF state."
	)
	var empty_session: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(empty_session.succeeded(), "The empty-plan laboratory session did not start.")
	if not empty_session.succeeded():
		return
	var empty_lab: SimulationLabSession = empty_session.session
	empty_lab.commit_staged_plan()
	empty_lab.advance_until_attention_required()
	_expect(
		SdfCampusPresenter.state_name_from_game_state(empty_lab.get_state()) == &"scrutiny",
		"The Northstar release did not select the scrutiny SDF state."
	)


func _verify_host_ready(host: CampaignHost) -> void:
	_expect(host.get_core() != null, "The campaign host has no Simulation Core.")
	_expect(host.get_current_state() != null, "The campaign host has no Game State.")
	_expect(host.get_hud() != null, "The campaign host has no HUD.")
	_expect(host.get_session() != null, "The campaign host has no session.")
	_expect(not host.get_session().has_chosen_path(), "The campaign host chose a path before Path Select.")
	_expect(host.get_hud().get_path_select() != null, "The HUD has no Path Select view.")
	_expect(host.get_hud().get_path_select().visible, "Path Select is hidden after the scenario loads.")
	_expect(
		host.get_current_state().calendar.current_month_step_index == 0,
		"The campaign host did not load the starting Month Step."
	)


func _verify_opening_path_and_advance(host: CampaignHost) -> void:
	host.select_opening_path(CampaignCatalog.PATH_RESEARCH)
	_expect(host.get_session().has_chosen_path(), "The campaign host did not record the opening path.")
	_expect(
		host.get_session().has_staged_project(CampaignCatalog.RESEARCH_PROJECT_ID),
		"The Research path did not stage the Research Project."
	)
	_expect(not host.get_hud().get_path_select().visible, "Path Select remains visible after the path is chosen.")
	_expect(host.get_hud().get_lab_text().contains("Laboratory capacity level 2"), "The HUD does not show laboratory capacity.")
	_expect(host.get_hud().get_lab_text().contains("authored SDF campus"), "The HUD does not name the authored SDF campus.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_OPS_REVIEW), "Operations Review was available in Month Step 0.")
	var result: SimulationOperationResult = host.advance_from_hud()
	_expect(
		result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The Research path Advance did not stop at the Attention Boundary."
	)
	_expect(host.get_current_state().calendar.current_month_step_index == 3, "The campaign Advance did not end at Month Step 3.")
	_expect(
		host.get_current_state().company.projects.has(CampaignCatalog.RESEARCH_PROJECT_ID),
		"The Research path did not start the Research Project."
	)
	_expect(host.get_hud().get_attention_text().contains("attention_event.quarter_boundary"), "The HUD does not present the Quarter Boundary.")
	_expect(host.get_hud().get_status_text() == "Attention is required.", "The HUD status is incorrect after Advance.")


func _verify_skill_and_tech(host: CampaignHost) -> void:
	_expect(host.get_session().has_skill(CampaignCatalog.SKILL_RESEARCH_FOCUS), "The Research path did not unlock Research Focus.")
	_expect(host.can_unlock_skill(CampaignCatalog.SKILL_OPS_REVIEW), "Operations Review stayed locked after a new Month Step.")
	_expect(host.can_unlock_tech(CampaignCatalog.TECH_EVAL_HARNESS), "Evaluation Harness is locked while Cash is sufficient.")
	_expect(not host.can_unlock_tech(CampaignCatalog.TECH_SERVING_QUEUE), "Serving Queue did not require the Evaluation Harness.")
	_expect(host.unlock_tech(CampaignCatalog.TECH_EVAL_HARNESS), "Evaluation Harness did not unlock.")
	_expect(host.get_session().has_tech(CampaignCatalog.TECH_EVAL_HARNESS), "The session did not record the Evaluation Harness.")
	_expect(
		CampaignCatalog.cash_balance_musd(host.get_current_state()) == 58,
		"A tech unlock changed Cash."
	)
	_expect(host.can_unlock_tech(CampaignCatalog.TECH_SERVING_QUEUE), "Serving Queue stayed locked after its prerequisite.")
	host.set_active_view(CampaignCatalog.VIEW_SKILL_TREE)
	_expect(host.get_hud().get_skill_tree().visible, "The skill tree view did not open.")
	host.set_active_view(CampaignCatalog.VIEW_TECH_TREE)
	_expect(host.get_hud().get_tech_tree().visible, "The tech tree view did not open.")


func _verify_data_center(host: CampaignHost) -> void:
	host.set_active_view(CampaignCatalog.VIEW_DATA_CENTER)
	_expect(host.get_hud().get_data_center().visible, "The Data Center view did not open.")
	var body: String = host.get_hud().get_data_center().get_body_text()
	_expect(body.contains("reserved Scale slot"), "The Data Center view does not name the reserved slot.")
	_expect(body.contains("contract.compute.standard"), "The Data Center view does not list the standard compute contract.")


func _verify_fail_state(host: CampaignHost) -> void:
	host.request_abandon()
	_expect(host.get_session().abandon_pending, "Abandon did not require confirmation.")
	_expect(host.get_hud().get_fail_state().visible, "The fail-state view did not open for confirmation.")
	host.cancel_abandon()
	_expect(not host.get_session().abandon_pending, "Cancel did not clear the abandon request.")
	host.request_abandon()
	host.confirm_abandon()
	_expect(host.get_session().failed, "Confirm abandon did not end the campaign.")
	_expect(host.get_session().fail_reason_id == CampaignCatalog.FAIL_ABANDONED, "The fail reason is incorrect.")
	_expect(host.get_hud().get_fail_state().visible, "The fail-state view is hidden after the campaign ends.")
	_expect(
		host.get_hud().get_fail_state().get_reason_text().contains("abandoned"),
		"The fail-state view does not show the abandon reason."
	)
	var blocked: SimulationOperationResult = host.advance_from_hud()
	_expect(
		blocked == host.get_last_result(),
		"Advance after failure replaced the last result."
	)
	_expect(host.get_current_state().calendar.current_month_step_index == 3, "Advance after failure progressed time.")


func _make_host() -> CampaignHost:
	var host: CampaignHost = CampaignHost.new()
	host.name = "CampaignHost"
	var overlay: CampaignHud = CampaignHud.new()
	overlay.name = "Overlay"
	host.add_child(overlay)
	return host


func _scale_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CampaignCatalog.SCALE_PROJECT_ID
	command.payload = payload
	return command


func _finish() -> void:
	if _failure_count > 0:
		printerr("PRODUCTION_BOOTSTRAP_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=6" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
