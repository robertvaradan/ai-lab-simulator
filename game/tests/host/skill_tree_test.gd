extends SceneTree

const TEST_SUCCESS: String = "SKILL_TREE_TEST_SUCCESS"

var _failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_verify_catalog()
	_verify_unlock_gating()
	_verify_research_point_grant()
	_verify_trust_thresholds()
	_verify_skill_tree_view()
	_finish()


func _verify_catalog() -> void:
	var skills: Array[BootstrapUnlockDefinition] = CampaignCatalog.skill_definitions()
	_expect(skills.size() == 9, "The skill catalog does not contain nine skills.")
	_expect(
		CampaignCatalog.RESEARCH_POINTS_PER_RESEARCH_PROJECT == 4,
		"A completed Research Project does not grant 4 research points."
	)
	var methods: BootstrapUnlockDefinition = CampaignCatalog.skill_for_id(CampaignCatalog.SKILL_RESEARCH_METHODS)
	_expect(methods != null, "Prototype Methods is missing.")
	if methods != null:
		_expect(methods.branch_id == CampaignCatalog.BRANCH_RESEARCH, "Prototype Methods is not a Research skill.")
		_expect(methods.cost_research_points == 1, "Prototype Methods does not cost 1 research point.")
	var robots: BootstrapUnlockDefinition = CampaignCatalog.skill_for_id(CampaignCatalog.SKILL_APPLICATION_ROBOTS)
	_expect(robots != null, "Robot Assistants is missing.")
	if robots != null:
		_expect(robots.branch_id == CampaignCatalog.BRANCH_APPLICATION, "Robot Assistants is not an Application skill.")
		_expect(robots.cost_research_points == 2, "Robot Assistants does not cost 2 research points.")
		_expect(
			robots.prerequisite_ids.has(CampaignCatalog.SKILL_APPLICATION_PRODUCT_LINE),
			"Robot Assistants does not require Product Line."
		)


func _verify_unlock_gating() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	_expect(host.get_session().research_points == 0, "The session did not start at 0 research points.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods unlocked with 0 research points.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_EVAL_LOOP), "Eval Loop unlocked without its prerequisite.")
	var cash_before: int = CampaignCatalog.cash_balance_musd(host.get_current_state())
	host.get_session().research_points = 1
	_expect(host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods stayed locked after 1 research point.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_EVAL_LOOP), "Eval Loop ignored Prototype Methods.")
	_expect(host.unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "Prototype Methods did not unlock.")
	_expect(host.get_session().research_points == 0, "The unlock did not subtract 1 research point.")
	_expect(
		CampaignCatalog.cash_balance_musd(host.get_current_state()) == cash_before,
		"A skill unlock changed Cash."
	)
	_expect(not host.unlock_skill(CampaignCatalog.SKILL_RESEARCH_METHODS), "The host unlocked Prototype Methods twice.")
	host.get_session().research_points = 1
	_expect(host.unlock_skill(CampaignCatalog.SKILL_RESEARCH_EVAL_LOOP), "Eval Loop did not unlock after its prerequisite.")
	_expect(host.get_session().research_points == 0, "Eval Loop did not spend 1 research point.")
	_expect(not host.can_unlock_skill(CampaignCatalog.SKILL_RESEARCH_FRONTIER_PUSH), "Frontier Push unlocked with 0 research points.")
	host.get_session().research_points = 2
	_expect(host.unlock_skill(CampaignCatalog.SKILL_RESEARCH_FRONTIER_PUSH), "Frontier Push did not unlock.")
	_expect(host.get_session().research_points == 0, "Frontier Push did not spend 2 research points.")
	host.queue_free()


func _verify_research_point_grant() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	var state: GameState = host.get_current_state()
	_expect(host.get_session().research_points == 0, "The grant test did not start at 0 research points.")
	var completed: Array[StringName] = CampaignCatalog.completed_research_project_ids(state, host.get_definition())
	_expect(completed.is_empty(), "The starting state already has a completed Research Project.")
	var project: ProjectState = ProjectState.new()
	project.stable_id = CampaignCatalog.RESEARCH_PROJECT_ID
	project.content_definition_id = CampaignCatalog.RESEARCH_PROJECT_ID
	project.status_id = ProjectState.STATUS_COMPLETED
	state.company.projects[project.stable_id] = project
	host.refresh_presentation()
	_expect(host.get_session().research_points == 4, "A completed Research Project did not grant 4 research points.")
	host.refresh_presentation()
	_expect(host.get_session().research_points == 4, "The host granted research points twice for one Project.")
	host.queue_free()


func _verify_trust_thresholds() -> void:
	_expect(TrustThreshold.PUBLIC_TRUST_PEAK_EVALUATION_POINTS == 80, "The Public Trust threshold is not 80.")
	_expect(TrustThreshold.GOVERNMENT_PEAK_EVALUATION_POINTS == 90, "The Government threshold is not 90.")
	var host: CampaignHost = _make_host()
	root.add_child(host)
	var state: GameState = host.get_current_state()
	var starting: ModelState = state.company.models[CampaignCatalog.STARTING_MODEL_ID]
	_expect(TrustThreshold.peak_evaluation(starting) == 76, "Aperture 1.0 peak evaluation is not 76.")
	_expect(not TrustThreshold.is_public_trust_active(state), "Public Trust is active at campaign start.")
	_expect(not TrustThreshold.is_government_active(state), "Government is active at campaign start.")
	_expect(not host.get_hud().get_state_text().contains("Public Trust"), "The HUD showed Public Trust at start.")
	_expect(
		host.get_hud().get_government().get_body_text().contains("Government is inactive."),
		"The Government view does not state the inactive threshold."
	)
	state.company.models[&"model.player.threshold_public"] = _released_model(
		&"model.player.threshold_public",
		80,
		70,
		70
	)
	host.refresh_presentation()
	_expect(TrustThreshold.is_public_trust_active(state), "Public Trust did not activate at peak 80.")
	_expect(not TrustThreshold.is_government_active(state), "Government activated at peak 80.")
	_expect(host.get_hud().get_state_text().contains("Public Trust 55"), "The HUD did not present Public Trust after the threshold.")
	_expect(not host.get_hud().get_state_text().contains("Government Trust"), "The HUD presented Government Trust at peak 80.")
	state.company.models[&"model.player.threshold_government"] = _released_model(
		&"model.player.threshold_government",
		90,
		70,
		70
	)
	host.refresh_presentation()
	_expect(TrustThreshold.is_government_active(state), "Government did not activate at peak 90.")
	_expect(host.get_hud().get_state_text().contains("Government Trust 50"), "The HUD did not present Government Trust after the threshold.")
	_expect(
		host.get_hud().get_government().get_body_text().contains("Government is active."),
		"The Government view did not present the active state."
	)
	_expect(TrustThreshold.peak_evaluation(null) == 0, "A missing Model did not return peak 0.")
	host.queue_free()


func _verify_skill_tree_view() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	host.set_active_view(CampaignCatalog.VIEW_SKILL_TREE)
	_expect(host.get_active_world_id() == CampaignCatalog.WORLD_HQ, "The skill tree did not force HQ.")
	var view: SkillTreeView = host.get_hud().get_skill_tree()
	_expect(view != null, "The HUD has no skill tree view.")
	_expect(view.visible, "The skill tree view did not open.")
	_expect(view.get_unlock_button(CampaignCatalog.SKILL_RESEARCH_METHODS) != null, "Research has no Prototype Methods control.")
	_expect(view.get_unlock_button(CampaignCatalog.SKILL_SCALE_BURST_BUY) != null, "Scale has no Burst Contracts control.")
	_expect(view.get_unlock_button(CampaignCatalog.SKILL_APPLICATION_ROBOTS) != null, "Applications has no Robot Assistants control.")
	host.queue_free()


func _released_model(model_id: StringName, coding: int, reasoning: int, efficiency: int) -> ModelState:
	var model: ModelState = ModelState.new()
	model.stable_id = model_id
	model.display_name = "Threshold"
	model.version_label = "1.0"
	model.release_state_id = TrustThreshold.RELEASED_STATE_ID
	model.release_strategy_id = &"release_strategy.commercial_api"
	var evaluations: ModelEvaluationState = ModelEvaluationState.new()
	evaluations.coding_evaluation_points = coding
	evaluations.reasoning_evaluation_points = reasoning
	evaluations.efficiency_evaluation_points = efficiency
	model.evaluations = evaluations
	model.training_compute_unit_months = 1
	model.inference_compute_unit_months_per_contract = 1
	return model


func _make_host() -> CampaignHost:
	var host: CampaignHost = CampaignHost.new()
	host.name = "SkillTreeHost"
	var overlay: CampaignHud = CampaignHud.new()
	overlay.name = "Overlay"
	host.add_child(overlay)
	return host


func _finish() -> void:
	if _failure_count > 0:
		printerr("SKILL_TREE_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=5" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
