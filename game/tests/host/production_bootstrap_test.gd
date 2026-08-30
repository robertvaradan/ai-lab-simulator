extends SceneTree

const TEST_SUCCESS: String = "PRODUCTION_BOOTSTRAP_TEST_SUCCESS"

var _failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_verify_scenes()
	_verify_ui_scale_contract()
	_verify_campaign_campus()
	var host: CampaignHost = _make_host()
	root.add_child(host)
	_verify_host_ready(host)
	_verify_project_stage_and_advance(host)
	_verify_skill_tree(host)
	_verify_data_center(host)
	_verify_world_map(host)
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
	_expect(campaign_text.contains("campus_blockout.tscn"), "The campaign scene does not instance the campus blockout.")
	_expect(campaign_text.contains("campus_visual_presenter.gd"), "The campaign scene does not use the campus visual presenter.")
	_expect(not campaign_text.contains("sdf_campus_presenter.gd"), "The campaign scene still uses the SDF presenter.")
	var menu: MainMenu = menu_scene.instantiate() as MainMenu
	_expect(menu != null, "The Main Menu root is not MainMenu.")
	root.add_child(menu)
	_expect(menu.get_start_button() != null, "The Main Menu has no Start button.")
	_expect(menu.get_start_button().text == "Start", "The Main Menu Start label is incorrect.")
	menu.queue_free()


func _verify_ui_scale_contract() -> void:
	_expect(
		is_equal_approx(UiScale.readable_content_scale_factor(Vector2i(1512, 982), Vector2i(1920, 1080)), 1920.0 / 1512.0),
		"A Window smaller than the design viewport did not raise the content-scale factor."
	)
	_expect(
		is_equal_approx(UiScale.readable_content_scale_factor(Vector2i(2560, 1440), Vector2i(1920, 1080)), 1.0),
		"A Window larger than the design viewport changed the content-scale factor."
	)


func _verify_campaign_campus() -> void:
	var packed: PackedScene = load("res://scenes/campaign.tscn") as PackedScene
	_expect(packed != null, "The campaign scene did not load for campus verification.")
	if packed == null:
		return
	var host: CampaignHost = packed.instantiate() as CampaignHost
	_expect(host != null, "The campaign scene root is not CampaignHost.")
	if host == null:
		return
	root.add_child(host)
	var campus: Node3D = host.get_node_or_null("CampusBlockout") as Node3D
	_expect(campus != null, "The campaign host has no campus blockout.")
	var presenter: CampusVisualPresenter = host.get_presenter()
	_expect(presenter != null, "The campaign host has no campus visual presenter.")
	var camera: Camera3D = null
	if campus != null:
		camera = campus.get_node_or_null("GameplayCamera") as Camera3D
	_expect(camera != null, "The campus blockout has no gameplay camera.")
	if presenter != null:
		_expect(
			presenter.get_visible_laboratory_node_name() == "",
			"Month 1 showed a laboratory stage on the campaign campus."
		)
	_complete_build_laboratory_on_host(host)
	if presenter != null:
		_expect(
			presenter.get_visible_laboratory_node_name() == "LabStage1",
			"Build Laboratory completion did not show laboratory stage 1."
		)
	host.set_active_world(CampaignCatalog.WORLD_DATA_CENTER)
	if campus != null:
		_expect(not campus.visible, "The campus blockout stayed visible outside HQ.")
	if camera != null:
		_expect(not camera.current, "The campus camera stayed current outside HQ.")
	host.enter_world(CampaignCatalog.WORLD_HQ)
	if campus != null:
		_expect(campus.visible, "The campus blockout stayed hidden after HQ entry.")
	if camera != null:
		_expect(camera.current, "The campus camera stayed inactive after HQ entry.")
	host.queue_free()


func _verify_host_ready(host: CampaignHost) -> void:
	_expect(host.get_core() != null, "The campaign host has no Simulation Core.")
	_expect(host.get_current_state() != null, "The campaign host has no Game State.")
	_expect(host.get_hud() != null, "The campaign host has no HUD.")
	_expect(host.get_session() != null, "The campaign host has no session.")
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_HQ, "The campaign did not start in HQ.")
	_expect(host.get_hud().get_advance_button() != null, "The HUD has no Advance button.")
	_expect(not host.get_hud().get_advance_button().disabled, "Advance is disabled after the scenario loads.")
	_expect(not host.get_hud().get_fail_state().visible, "The fail-state view is visible after the scenario loads.")
	_expect(host.get_hud().get_lab_text().contains("Laboratory capacity level 2"), "The HUD does not show laboratory capacity.")
	_expect(host.get_hud().get_lab_text().contains("authored campus blockout"), "The HUD does not name the authored campus blockout.")
	_expect(not host.get_session().has_staged_project(CampaignCatalog.RESEARCH_PROJECT_ID), "The campaign host staged a Project before Plan controls.")
	_expect(host.get_session().research_points == 0, "The campaign did not start with 0 research points.")
	_expect(not host.get_session().has_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods was unlocked before a skill unlock.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods was available with 0 research points.")
	_expect(host.get_hud().get_state_text().contains("Research points 0"), "The HUD does not show the research-point balance.")
	_expect(not host.get_hud().get_state_text().contains("Public Trust"), "The HUD presented Public Trust before the threshold.")
	_expect(not host.get_hud().get_state_text().contains("Government Trust"), "The HUD presented Government Trust before the threshold.")
	_expect(
		host.get_current_state().calendar.current_month_step_index == 0,
		"The campaign host did not load the starting Month Step."
	)
	var window: Window = host.get_window()
	if window != null:
		UiScale.apply_to_window(window)
		_expect(
			window.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,
			"The campaign Window disabled canvas content scale."
		)
		_expect(
			window.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND,
			"The campaign Window content-scale aspect is incorrect."
		)


func _verify_project_stage_and_advance(host: CampaignHost) -> void:
	_complete_build_laboratory_on_host(host)
	_expect(host.get_current_state().calendar.current_month_step_index == 1, "The Build Laboratory Advance did not end at Month Step 1.")
	_expect(
		host.get_current_state().company.projects.has(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID),
		"The staged Build Laboratory Plan did not start the laboratory Project."
	)
	host.set_project_staged(CampaignCatalog.RESEARCH_PROJECT_ID, true)
	_expect(
		host.get_session().has_staged_project(CampaignCatalog.RESEARCH_PROJECT_ID),
		"set_project_staged did not stage the Research Project."
	)
	_expect(not host.get_session().has_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Staging a Project unlocked Prototype Methods.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods unlocked without research points.")
	var result: SimulationOperationResult = host.advance_from_hud()
	_expect(
		result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The staged Research Advance did not stop at the Attention Boundary."
	)
	_expect(host.get_current_state().calendar.current_month_step_index == 3, "The campaign Advance did not end at Month Step 3.")
	_expect(
		host.get_current_state().company.projects.has(CampaignCatalog.RESEARCH_PROJECT_ID),
		"The staged Research Plan did not start the Research Project."
	)
	_expect(host.get_hud().get_attention_text().contains("attention_event.quarter_boundary"), "The HUD does not present the Quarter Boundary.")
	_expect(host.get_hud().get_status_text() == "Attention is required.", "The HUD status is incorrect after Advance.")


func _verify_skill_tree(host: CampaignHost) -> void:
	_expect(not host.get_session().has_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods was granted without a skill unlock.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods unlocked without research points.")
	var cash_before: int = CampaignCatalog.cash_balance_musd(host.get_current_state())
	host.get_session().research_points = 1
	_expect(host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods stayed locked after research points were granted.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_EVAL_LOOP), "Eval Loop did not require Prototype Methods.")
	_expect(host.unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods did not unlock.")
	_expect(host.get_session().has_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "The session did not record Prototype Methods.")
	_expect(host.get_session().research_points == 0, "The unlock did not spend the research-point cost.")
	_expect(
		CampaignCatalog.cash_balance_musd(host.get_current_state()) == cash_before,
		"A skill unlock changed Cash."
	)
	host.set_active_view(CampaignCatalog.VIEW_SKILL_TREE)
	_expect(host.get_hud().get_skill_tree().visible, "The skill tree view did not open.")
	_expect(
		host.get_hud().get_skill_tree().get_unlock_button(CampaignCatalog.SKILL_RESEARCH_METHODS) != null,
		"The skill tree has no Prototype Methods control."
	)


func _verify_data_center(host: CampaignHost) -> void:
	host.set_active_world(CampaignCatalog.WORLD_DATA_CENTER)
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_DATA_CENTER, "set_active_world did not enter Data Center.")
	_expect(host.get_hud().get_data_center().visible, "The Data Center view did not open.")
	var body: String = host.get_hud().get_data_center().get_body_text()
	_expect(body.contains("reserved Scale slot"), "The Data Center view does not name the reserved slot.")
	_expect(body.contains("contract.compute.standard"), "The Data Center view does not list the standard compute contract.")


func _verify_world_map(host: CampaignHost) -> void:
	_expect(CampaignCatalog.is_valid_enterable_world_id(CampaignCatalog.WORLD_HQ), "HQ is not an enterable World.")
	_expect(
		CampaignCatalog.is_valid_enterable_world_id(CampaignCatalog.WORLD_DATA_CENTER),
		"Data Center is not an enterable World."
	)
	_expect(
		CampaignCatalog.is_valid_enterable_world_id(CampaignCatalog.WORLD_GOVERNMENT),
		"Government is not an enterable World."
	)
	_expect(not CampaignCatalog.is_valid_enterable_world_id(CampaignCatalog.WORLD_MAP), "The World map is enterable.")
	_expect(CampaignCatalog.is_valid_world_id(CampaignCatalog.WORLD_MAP), "The World map ID is invalid.")
	_expect(CampaignCatalog.world_display_name(CampaignCatalog.WORLD_HQ) == "HQ", "HQ display name is incorrect.")
	_expect(
		CampaignCatalog.world_display_name(CampaignCatalog.WORLD_DATA_CENTER) == "Data Center",
		"Data Center display name is incorrect."
	)
	_expect(
		CampaignCatalog.world_display_name(CampaignCatalog.WORLD_GOVERNMENT) == "Government",
		"Government display name is incorrect."
	)
	host.set_active_world(CampaignCatalog.WORLD_MAP)
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_MAP, "set_active_world did not open the World map.")
	_expect(host.get_hud().get_world_map().visible, "The World map view did not open.")
	_expect(not host.get_hud().get_data_center().visible, "The Data Center view stayed open on the World map.")
	_expect(not host.get_hud().get_government().visible, "The Government view stayed open on the World map.")
	_expect(host.get_hud().get_world_map().get_hq_button() != null, "The World map has no HQ button.")
	_expect(host.get_hud().get_world_map().get_data_center_button() != null, "The World map has no Data Center button.")
	_expect(host.get_hud().get_world_map().get_government_button() != null, "The World map has no Government button.")
	host.get_hud().get_world_map().get_hq_button().pressed.emit()
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_HQ, "The HQ map button did not enter HQ.")
	_expect(not host.get_hud().get_world_map().visible, "The World map stayed open after HQ entry.")
	host.set_active_world(CampaignCatalog.WORLD_MAP)
	host.get_hud().get_world_map().get_government_button().pressed.emit()
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_GOVERNMENT, "The Government map button did not enter Government.")
	_expect(host.get_hud().get_government().visible, "The Government view did not open.")
	_expect(
		host.get_hud().get_government().get_body_text().contains("regulation"),
		"The Government view does not name the reserved regulation slot."
	)
	_expect(
		host.get_hud().get_government().get_body_text().contains("Government is inactive."),
		"The Government view does not state that Government is inactive."
	)
	host.set_active_view(CampaignCatalog.VIEW_SKILL_TREE)
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_HQ, "The skill tree did not force HQ.")
	_expect(host.get_hud().get_skill_tree().visible, "The skill tree view did not open from Government.")
	_expect(not host.get_hud().get_government().visible, "The Government view stayed open on the skill tree.")
	host.set_active_world(CampaignCatalog.WORLD_MAP)
	host.get_hud().get_world_map().get_data_center_button().pressed.emit()
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_DATA_CENTER, "The Data Center map button did not enter Data Center.")
	_expect(host.get_hud().get_data_center().visible, "The Data Center view did not open from the World map.")
	host.enter_world(CampaignCatalog.WORLD_HQ)
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_HQ, "enter_world did not return to HQ.")
	_expect(not host.get_hud().get_world_map().visible, "The World map stayed open after enter_world.")
	_expect(not host.get_hud().get_data_center().visible, "The Data Center view stayed open after enter_world.")


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


func _complete_build_laboratory_on_host(host: CampaignHost) -> void:
	host.set_project_staged(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID, true)
	var plan: Plan = host.get_hud().build_plan(host.get_current_state())
	var commit: SimulationOperationResult = host.get_core().commit_plan(host.get_current_state(), plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "The Build Laboratory Plan did not commit.")
	if not commit.has_candidate_state():
		return
	var stepped: SimulationOperationResult = host.get_core().step_month(commit.candidate_state)
	_expect(stepped.has_candidate_state(), "The Build Laboratory Month Step has no candidate Game State.")
	if not stepped.has_candidate_state():
		return
	host.get_game_state_service().publish_operation_result(stepped)
	host.set_project_staged(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID, false)
	host.refresh_presentation()


func _finish() -> void:
	if _failure_count > 0:
		printerr("PRODUCTION_BOOTSTRAP_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=8" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
