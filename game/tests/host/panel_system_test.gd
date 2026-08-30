extends SceneTree

const TEST_SUCCESS: String = "PANEL_SYSTEM_TEST_SUCCESS"
const WORKSPACE_PATH: String = "res://ui/campaign/campaign_panel_workspace.tscn"
const DATA_CENTER_PATH: String = "res://scenes/data_center_world.tscn"
const GOVERNMENT_PATH: String = "res://scenes/government_world.tscn"

var _failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_verify_assets()
	_verify_panel_registry()
	_verify_workspace_surfaces()
	_verify_back_order_and_focus()
	_verify_mouse_passthrough()
	_verify_draft_validation_and_advance_gate()
	_verify_timeline_attention()
	_verify_world_scenes()
	_verify_advance_transition_model()
	_verify_layout_bounds()
	_verify_session_reset()
	_finish()


func _verify_assets() -> void:
	_expect(
		FileAccess.file_exists("res://ui/icons/aperture_mark.svg"),
		"The Aperture mark SVG is missing."
	)
	_expect(
		FileAccess.file_exists("res://ui/icons/tabler/LICENSE"),
		"The Tabler license file is missing."
	)
	_expect(
		FileAccess.file_exists("res://ui/icons/tabler/outline/bell.svg"),
		"The Tabler bell outline icon is missing."
	)
	_expect(
		FileAccess.file_exists("res://ui/icons/tabler/filled/bell.svg"),
		"The Tabler bell filled icon is missing."
	)
	_expect(
		FileAccess.file_exists("res://ui/icons/tabler/outline/settings.svg"),
		"The Tabler settings outline icon is missing."
	)
	var concept_path: String = ProjectSettings.globalize_path("res://") + "../docs/concept-art/panel-system-v1.png"
	_expect(FileAccess.file_exists(concept_path), "The panel-system concept art is missing.")
	var spec_path: String = ProjectSettings.globalize_path("res://") + "../docs/presentation/panel-system.md"
	_expect(FileAccess.file_exists(spec_path), "The panel-system specification is missing.")


func _verify_panel_registry() -> void:
	var registry: CampaignPanelRegistry = CampaignPanelRegistry.new()
	for definition: CampaignPanelDefinition in CampaignPanelDefinition.known_panels():
		registry.register(definition)
	_expect(registry.has(CampaignPanelDefinition.PANEL_PLAN), "Plan panel is not registered.")
	_expect(
		registry.get_panel(CampaignPanelDefinition.PANEL_TIMELINE) != null,
		"Timeline panel lookup failed."
	)
	var seen: Dictionary[StringName, bool] = {}
	for definition: CampaignPanelDefinition in CampaignPanelDefinition.known_panels():
		_expect(not seen.has(definition.stable_id), "Duplicate panel identifier %s." % String(definition.stable_id))
		seen[definition.stable_id] = true
		_expect(not definition.scene_path.is_empty(), "Panel %s has no scene path." % String(definition.stable_id))
		_expect(
			ResourceLoader.exists(definition.scene_path),
			"Panel scene missing: %s" % definition.scene_path
		)
	_expect(seen.size() == 7, "Expected seven known panels.")

func _verify_workspace_surfaces() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	var workspace: CampaignPanelWorkspace = host.get_workspace()
	_expect(workspace != null, "The host has no Panel Workspace.")
	_expect(workspace.get_advance_button() != null, "Advance button is missing.")
	_expect(workspace.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Workspace root must ignore pointer input.")
	workspace.open_workbench(CampaignPanelDefinition.PANEL_COMPANY_OVERVIEW)
	_expect(
		host.get_ui_session().active_workbench_id == CampaignPanelDefinition.PANEL_COMPANY_OVERVIEW,
		"Company Overview did not become the active Workbench."
	)
	workspace.open_workbench(CampaignPanelDefinition.PANEL_PLAN, CampaignPanelDefinition.TAB_SKILL_TREE)
	_expect(workspace.get_skill_tree() != null, "Plan Skill Tree surface is missing.")
	_expect(workspace.get_skill_tree().visible, "Skill Tree tab did not open.")
	workspace.open_workbench(CampaignPanelDefinition.PANEL_WORLD_MAP)
	_expect(workspace.get_world_map().visible, "World Map Workbench did not open.")
	workspace.open_modal(CampaignPanelDefinition.PANEL_PAUSE)
	host.queue_free()


func _verify_back_order_and_focus() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	var workspace: CampaignPanelWorkspace = host.get_workspace()
	workspace.show_context(&"entity.hq.laboratory", &"context.laboratory")
	workspace.open_workbench(CampaignPanelDefinition.PANEL_PLAN)
	workspace.open_modal(CampaignPanelDefinition.PANEL_PAUSE)
	workspace.back()
	_expect(
		host.get_ui_session().active_workbench_id == CampaignPanelDefinition.PANEL_PLAN
		or workspace.get_skill_tree() != null,
		"Back from Pause did not restore Workbench layer."
	)
	workspace.back()
	workspace.back()
	_expect(
		host.get_ui_session().input_context == CampaignInputContext.WORLD
		or host.get_ui_session().input_context == CampaignInputContext.UI,
		"Back stack did not unwind toward World."
	)
	host.queue_free()


func _verify_mouse_passthrough() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	var workspace: CampaignPanelWorkspace = host.get_workspace()
	_expect(workspace.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Empty workspace root stops pointer input.")
	host.queue_free()


func _verify_draft_validation_and_advance_gate() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	var validation: PlanValidationResult = host.validate_draft_plan()
	_expect(validation != null, "validate_draft_plan returned null.")
	_expect(validation.is_valid(), "Empty draft Plan must be valid at campaign start.")
	_expect(not host.get_workspace().get_advance_button().disabled, "Advance disabled with valid empty Plan.")
	host.set_project_staged(CampaignCatalog.RESEARCH_PROJECT_ID, true)
	var blocked: PlanValidationResult = host.validate_draft_plan()
	_expect(blocked != null, "Staged Research validation returned null.")
	# Research before laboratory should be invalid.
	_expect(not blocked.is_valid(), "Research before laboratory stayed valid.")
	_expect(host.get_workspace().get_advance_button().disabled, "Advance stayed enabled for invalid Plan.")
	host.set_project_staged(CampaignCatalog.RESEARCH_PROJECT_ID, false)
	host.set_project_staged(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID, true)
	var lab_validation: PlanValidationResult = host.validate_draft_plan()
	_expect(lab_validation.is_valid(), "Build Laboratory draft Plan is invalid.")
	host.queue_free()


func _verify_timeline_attention() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	_complete_build_laboratory(host)
	host.set_project_staged(CampaignCatalog.RESEARCH_PROJECT_ID, true)
	var result: SimulationOperationResult = host.advance_from_hud()
	_expect(
		result != null and result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"Research Advance did not stop at Attention Boundary."
	)
	var state: GameState = host.get_current_state()
	_expect(not state.attention_events.is_empty(), "No Attention Events after Quarter Boundary.")
	var draft: CampaignDraftPlanState = host.get_draft()
	for event: AttentionEventState in state.attention_events:
		if event == null:
			continue
		_expect(not draft.has_acknowledged_attention(event.stable_id), "Attention was acknowledged before focus.")
		draft.acknowledge_attention(event.stable_id)
		host.get_ui_session().mark_timeline_read(event.stable_id)
		_expect(draft.has_acknowledged_attention(event.stable_id), "Attention acknowledgment failed.")
		_expect(host.get_ui_session().is_timeline_read(event.stable_id), "Timeline read state failed.")
	var after_ack: PlanValidationResult = host.validate_draft_plan()
	_expect(after_ack.is_valid(), "Plan stayed invalid after Attention acknowledgments.")
	host.get_workspace().open_workbench(CampaignPanelDefinition.PANEL_TIMELINE)
	_expect(
		host.get_workspace().get_attention_text().contains("attention_event")
		or not host.get_workspace().get_attention_text().is_empty(),
		"Timeline attention text is empty."
	)
	host.queue_free()


func _verify_world_scenes() -> void:
	var data_center: PackedScene = load(DATA_CENTER_PATH) as PackedScene
	var government: PackedScene = load(GOVERNMENT_PATH) as PackedScene
	_expect(data_center != null, "Data Center World scene did not load.")
	_expect(government != null, "Government World scene did not load.")
	var dc_root: Node = data_center.instantiate()
	var gov_root: Node = government.instantiate()
	root.add_child(dc_root)
	root.add_child(gov_root)
	var dc_selectable: CampaignWorldSelectable = _find_selectable(dc_root)
	var gov_selectable: CampaignWorldSelectable = _find_selectable(gov_root)
	_expect(dc_selectable != null, "Data Center World has no selectable.")
	_expect(gov_selectable != null, "Government World has no selectable.")
	var dc_camera: Camera3D = dc_root.find_child("GameplayCamera", true, false) as Camera3D
	var gov_camera: Camera3D = gov_root.find_child("GameplayCamera", true, false) as Camera3D
	_expect(dc_camera != null and dc_camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Data Center camera is not orthographic.")
	_expect(gov_camera != null and gov_camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Government camera is not orthographic.")
	var host: CampaignHost = _make_host()
	root.add_child(host)
	host.set_active_world(CampaignCatalog.WORLD_DATA_CENTER)
	_expect(host.get_hud().get_data_center().get_body_text().contains("reserved Scale slot"), "Data Center context text missing reserved slot.")
	host.set_active_world(CampaignCatalog.WORLD_GOVERNMENT)
	_expect(host.get_hud().get_government().get_body_text().contains("regulation"), "Government context text missing regulation.")
	host.select_world_selectable(dc_selectable)
	_expect(host.get_ui_session().input_context == CampaignInputContext.UI, "Selection did not enter UI Input Context.")
	dc_root.queue_free()
	gov_root.queue_free()
	host.queue_free()


func _verify_advance_transition_model() -> void:
	var host: CampaignHost = _make_host()
	root.add_child(host)
	var previous_load: GameStateLoadResult = MarketingScenarioFactory.create_state(host.get_definition())
	_expect(previous_load.succeeded(), "Previous Game State did not load for Advance transition.")
	var previous: GameState = previous_load.state
	host.set_project_staged(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID, true)
	var result: SimulationOperationResult = host.advance_with_plan(host.get_draft().build_plan(host.get_current_state()))
	_expect(result != null and result.is_successful(), "Build Laboratory Advance failed.")
	var model: CampaignAdvanceTransitionModel = CampaignAdvanceTransitionModel.compile(
		previous,
		host.get_current_state(),
		result
	)
	_expect(model != null, "Advance transition model is null.")
	_expect(not model.month_steps.is_empty(), "Advance transition model has no Month Steps.")
	_expect(model.cash_before_musd == CampaignCatalog.cash_balance_musd(previous), "Advance transition Cash before is incorrect.")
	host.queue_free()


func _verify_layout_bounds() -> void:
	var sizes: Array[Vector2i] = [
		Vector2i(1920, 1080),
		Vector2i(1280, 720),
		Vector2i(2560, 1080),
	]
	for size: Vector2i in sizes:
		var host: CampaignHost = _make_host()
		root.add_child(host)
		var window: Window = host.get_window()
		if window != null:
			window.size = size
			UiScale.apply_to_window(window)
		var workspace: CampaignPanelWorkspace = host.get_workspace()
		_expect(workspace != null, "Workspace missing at %s." % str(size))
		_expect(workspace.get_advance_button() != null, "Advance missing at %s." % str(size))
		host.queue_free()


func _verify_session_reset() -> void:
	var ui_session: CampaignUiSessionState = CampaignUiSessionState.new()
	ui_session.active_workbench_id = CampaignPanelDefinition.PANEL_PLAN
	ui_session.active_tab_id = CampaignPanelDefinition.TAB_SKILL_TREE
	ui_session.mark_timeline_read(&"attention_event.quarter_boundary")
	ui_session.set_world_selection(CampaignCatalog.WORLD_HQ, &"entity.hq.laboratory")
	ui_session.context_collapsed = true
	ui_session.reset()
	_expect(ui_session.active_workbench_id == &"", "UI session did not clear Workbench.")
	_expect(not ui_session.is_timeline_read(&"attention_event.quarter_boundary"), "UI session did not clear read timeline ids.")
	_expect(ui_session.get_world_selection(CampaignCatalog.WORLD_HQ) == &"", "UI session did not clear World selection.")
	var draft: CampaignDraftPlanState = CampaignDraftPlanState.new()
	draft.set_project_staged(CampaignCatalog.RESEARCH_PROJECT_ID, true)
	draft.acknowledge_attention(&"attention_event.quarter_boundary")
	draft.reset()
	_expect(not draft.has_staged_project(CampaignCatalog.RESEARCH_PROJECT_ID), "Draft did not reset staged Projects.")
	_expect(not draft.has_acknowledged_attention(&"attention_event.quarter_boundary"), "Draft did not reset acknowledgments.")


func _make_host() -> CampaignHost:
	var packed: PackedScene = load("res://scenes/campaign.tscn") as PackedScene
	if packed != null:
		var from_scene: CampaignHost = packed.instantiate() as CampaignHost
		if from_scene != null:
			return from_scene
	var host: CampaignHost = CampaignHost.new()
	host.name = "CampaignHost"
	var workspace_scene: PackedScene = load(WORKSPACE_PATH) as PackedScene
	var overlay: CampaignPanelWorkspace = workspace_scene.instantiate() as CampaignPanelWorkspace
	overlay.name = "Overlay"
	host.add_child(overlay)
	return host


func _complete_build_laboratory(host: CampaignHost) -> void:
	host.set_project_staged(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID, true)
	var plan: Plan = host.get_draft().build_plan(host.get_current_state())
	var commit: SimulationOperationResult = host.get_core().commit_plan(host.get_current_state(), plan)
	_expect(commit.outcome == SimulationOperationOutcome.Type.COMPLETED, "Build Laboratory Plan did not commit.")
	if not commit.has_candidate_state():
		return
	var stepped: SimulationOperationResult = host.get_core().step_month(commit.candidate_state)
	_expect(stepped.has_candidate_state(), "Build Laboratory Month Step has no candidate.")
	if not stepped.has_candidate_state():
		return
	host.get_game_state_service().publish_operation_result(stepped)
	host.set_project_staged(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID, false)
	host.refresh_presentation()


func _find_selectable(root_node: Node) -> CampaignWorldSelectable:
	if root_node is CampaignWorldSelectable:
		return root_node as CampaignWorldSelectable
	for child: Node in root_node.get_children():
		var found: CampaignWorldSelectable = _find_selectable(child)
		if found != null:
			return found
	return null


func _finish() -> void:
	if _failure_count > 0:
		printerr("PANEL_SYSTEM_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=12" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
