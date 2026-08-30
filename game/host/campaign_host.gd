class_name CampaignHost
extends ServiceContext

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const GAMEPLAY_CAMERA_NAME: String = "GameplayCamera"
const CAMPUS_NODE_NAME: String = "CampusBlockout"
const DATA_CENTER_WORLD_NAME: String = "DataCenterWorld"
const GOVERNMENT_WORLD_NAME: String = "GovernmentWorld"

var _definition: MarketingScenarioDefinition
var _core: SimulationCore
var _game_state_service: GameStateService
var _advance_action: SimulationAdvanceAction
var _workspace: CampaignPanelWorkspace
var _presenter: CampusVisualPresenter
var _session: CampaignSessionState
var _ui_session: CampaignUiSessionState
var _draft: CampaignDraftPlanState
var _last_result: SimulationOperationResult
var _has_saved_framing: bool = false
var _saved_focus: Vector3 = Vector3.ZERO
var _saved_size: float = 20.0


func _register_services(provider: ServiceProvider) -> void:
	_session = CampaignSessionState.new()
	_ui_session = CampaignUiSessionState.new()
	_draft = CampaignDraftPlanState.new()
	_definition = MarketingScenarioFactory.load_definition(SCENARIO_PATH)
	if _definition == null:
		ServiceContract.fail("missing_marketing_scenario", "The Marketing Scenario definition did not load.")
		return
	var state_result: GameStateLoadResult = MarketingScenarioFactory.create_state(_definition)
	if not state_result.succeeded():
		ServiceContract.fail(
			"invalid_marketing_starting_state",
			"The Marketing Scenario starting Game State is invalid. %s" % state_result.format_errors()
		)
		return
	var construction: SimulationCoreConstructionResult = MarketingScenarioFactory.create_core(
		_definition,
		state_result.state
	)
	if not construction.succeeded():
		ServiceContract.fail(
			"invalid_marketing_simulation_core",
			"The Marketing Scenario Simulation Core did not construct. %s" % construction.format_diagnostics()
		)
		return
	_core = construction.core
	_game_state_service = GameStateService.new(
		self,
		state_result.state,
		_definition.stable_id,
		_definition.content_version,
		_definition.rule_graph_id,
		_definition.rule_graph_version,
		_definition.build_content_reference_catalog()
	)
	provider.provide(GameStateService, _game_state_service)
	_advance_action = SimulationAdvanceAction.new(_core, _game_state_service)


func _inject_services(provider: ServiceProvider) -> void:
	var resolved_service: Service = provider.resolve(GameStateService)
	_game_state_service = resolved_service as GameStateService


func _ready() -> void:
	_workspace = get_node_or_null("HudLayer/Overlay") as CampaignPanelWorkspace
	if _workspace == null:
		_workspace = get_node_or_null("Overlay") as CampaignPanelWorkspace
	if _workspace != null:
		_workspace.bind_host(self)
	_presenter = get_node_or_null("CampusVisualPresenter") as CampusVisualPresenter
	refresh_presentation()
	_connect_world_selectables()


func get_definition() -> MarketingScenarioDefinition:
	return _definition


func get_core() -> SimulationCore:
	return _core


func get_game_state_service() -> GameStateService:
	return _game_state_service


func get_session() -> CampaignSessionState:
	return _session


func get_ui_session() -> CampaignUiSessionState:
	return _ui_session


func get_draft() -> CampaignDraftPlanState:
	return _draft


func get_hud() -> CampaignPanelWorkspace:
	return _workspace


func get_workspace() -> CampaignPanelWorkspace:
	return _workspace


func get_presenter() -> CampusVisualPresenter:
	return _presenter


func get_last_result() -> SimulationOperationResult:
	return _last_result


func get_current_state() -> GameState:
	if _game_state_service == null:
		return null
	return _game_state_service.get_current_state()


func validate_draft_plan() -> PlanValidationResult:
	if _core == null or _draft == null:
		var empty: PlanValidationResult = PlanValidationResult.new()
		return empty
	var state: GameState = get_current_state()
	var plan: Plan = _draft.build_plan(state)
	return _core.validate_plan(state, plan)


func set_project_staged(project_id: StringName, staged: bool) -> void:
	if _session == null or _session.failed or _draft == null:
		return
	_draft.set_project_staged(project_id, staged)
	refresh_presentation()


func set_active_view(view_id: StringName) -> void:
	if _session == null or _session.failed:
		return
	_session.active_view_id = view_id
	if view_id == CampaignCatalog.VIEW_SKILL_TREE:
		_session.active_world_id = CampaignCatalog.WORLD_HQ
		if _workspace != null:
			_workspace.open_workbench(
				CampaignPanelDefinition.PANEL_PLAN,
				CampaignPanelDefinition.TAB_SKILL_TREE
			)
	refresh_presentation()


func set_active_world(world_id: StringName) -> void:
	if _session == null or _session.failed:
		return
	if not CampaignCatalog.is_valid_world_id(world_id):
		ServiceContract.fail("unknown_world", "The World %s is unknown." % String(world_id))
		return
	_has_saved_framing = false
	_session.active_world_id = world_id
	_session.active_view_id = CampaignCatalog.VIEW_CAMPUS
	_apply_active_world_visibility()
	if _workspace != null:
		if world_id == CampaignCatalog.WORLD_MAP:
			_workspace.open_workbench(CampaignPanelDefinition.PANEL_WORLD_MAP)
		else:
			_workspace.close_workbench_if(CampaignPanelDefinition.PANEL_WORLD_MAP)
			if world_id == CampaignCatalog.WORLD_DATA_CENTER:
				_select_or_show_context(
					CampaignWorldSelectable.ENTITY_DATA_CENTER_MARKER,
					CampaignWorldSelectable.CONTEXT_DATA_CENTER
				)
			elif world_id == CampaignCatalog.WORLD_GOVERNMENT:
				_select_or_show_context(
					CampaignWorldSelectable.ENTITY_GOVERNMENT_MARKER,
					CampaignWorldSelectable.CONTEXT_GOVERNMENT
				)
			elif world_id == CampaignCatalog.WORLD_HQ:
				_workspace.clear_context_if_world_entity()
	refresh_presentation()


func enter_world(world_id: StringName) -> void:
	if _session == null or _session.failed:
		return
	if not CampaignCatalog.is_valid_enterable_world_id(world_id):
		ServiceContract.fail("invalid_enterable_world", "The World %s is not enterable." % String(world_id))
		return
	set_active_world(world_id)


func get_active_world_id() -> StringName:
	if _session == null:
		return &""
	return _session.active_world_id


func unlock_skill(skill_id: StringName) -> bool:
	if _session == null or _session.failed:
		return false
	var skill: BootstrapUnlockDefinition = CampaignCatalog.skill_for_id(skill_id)
	if skill == null:
		ServiceContract.fail("unknown_skill", "The skill %s is unknown." % String(skill_id))
		return false
	if not _can_unlock(skill):
		return false
	_session.unlocked_skill_ids[skill_id] = true
	_session.research_points -= skill.cost_research_points
	refresh_presentation()
	return true


func can_unlock_skill(skill_id: StringName) -> bool:
	var skill: BootstrapUnlockDefinition = CampaignCatalog.skill_for_id(skill_id)
	if skill == null:
		return false
	return _can_unlock(skill)


func request_abandon() -> void:
	if _session == null or _session.failed:
		return
	_session.abandon_pending = true
	if _workspace != null:
		_workspace.open_modal(CampaignPanelDefinition.PANEL_FAIL_STATE)
	refresh_presentation()


func cancel_abandon() -> void:
	if _session == null:
		return
	_session.abandon_pending = false
	if _workspace != null:
		_workspace.back()
	refresh_presentation()


func confirm_abandon() -> void:
	_fail_campaign(CampaignCatalog.FAIL_ABANDONED)


func return_to_main_menu() -> void:
	SceneRouter.go_to_main_menu(get_tree())


func advance_from_hud() -> SimulationOperationResult:
	if _session != null and _session.failed:
		return _last_result
	var validation: PlanValidationResult = validate_draft_plan()
	if not validation.is_valid():
		refresh_presentation()
		return _last_result
	return advance_with_plan(_draft.build_plan(get_current_state()))


func advance_with_plan(plan: Plan) -> SimulationOperationResult:
	if _session != null and _session.failed:
		return _last_result
	var previous: GameState = get_current_state()
	_last_result = _advance_action.execute(plan)
	if (
		_last_result != null
		and (
			_last_result.outcome == SimulationOperationOutcome.Type.COMPLETED
			or _last_result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED
		)
	):
		_award_research_points()
		if _draft != null:
			_draft.clear_staging_after_advance()
		if CampaignCatalog.cash_balance_musd(get_current_state()) <= 0:
			_fail_campaign(CampaignCatalog.FAIL_CASH_EXHAUSTED)
			return _last_result
		var model: CampaignAdvanceTransitionModel = CampaignAdvanceTransitionModel.compile(
			previous,
			get_current_state(),
			_last_result
		)
		if _workspace != null:
			_workspace.play_advance_transition(model)
	refresh_presentation()
	return _last_result


func reframe_selection(target: Vector3, size_value: float) -> void:
	var camera: IsometricCamera = _gameplay_camera()
	if camera == null:
		return
	if not _has_saved_framing:
		_saved_focus = camera.capture_framing_focus()
		_saved_size = camera.capture_framing_size()
		_has_saved_framing = true
	camera.animate_framing(target, size_value, 0.3)
	_set_camera_input_enabled(false)


func restore_framing() -> void:
	var camera: IsometricCamera = _gameplay_camera()
	if camera == null:
		return
	if _has_saved_framing:
		camera.animate_framing(_saved_focus, _saved_size, 0.3)
		_has_saved_framing = false
	_set_camera_input_enabled(_ui_session == null or _ui_session.input_context == CampaignInputContext.WORLD)


func select_world_selectable(selectable: CampaignWorldSelectable) -> void:
	if selectable == null or _session == null or _session.failed:
		return
	if _ui_session != null:
		_ui_session.set_world_selection(_session.active_world_id, selectable.entity_id)
		_ui_session.input_context = CampaignInputContext.UI
	if _workspace != null:
		_workspace.show_context(
			selectable.entity_id,
			selectable.context_card_type,
			selectable.framing_target,
			selectable.framing_size
		)
	else:
		reframe_selection(selectable.framing_target, selectable.framing_size)
		_set_camera_input_enabled(false)


func cycle_world_selection(delta: int) -> void:
	if _session == null or _session.failed:
		return
	var items: Array[CampaignWorldSelectable] = _collect_active_selectables()
	if items.is_empty():
		return
	var current_id: StringName = &""
	if _ui_session != null:
		current_id = _ui_session.get_world_selection(_session.active_world_id)
	var index: int = -1
	for item_index: int in items.size():
		if items[item_index].entity_id == current_id:
			index = item_index
			break
	var next_index: int = 0
	if index < 0:
		if delta < 0:
			next_index = items.size() - 1
		else:
			next_index = 0
	else:
		next_index = (index + delta) % items.size()
		if next_index < 0:
			next_index += items.size()
	select_world_selectable(items[next_index])


func refresh_presentation() -> void:
	_award_research_points()
	var state: GameState = get_current_state()
	if _workspace != null:
		_workspace.present_state(state, _last_result, _definition, _session)
	_apply_active_world_visibility()
	if _presenter != null:
		_presenter.present_state(state)
	_connect_world_selectables()


func _award_research_points() -> void:
	if _session == null:
		return
	var completed_ids: Array[StringName] = CampaignCatalog.completed_research_project_ids(
		get_current_state(),
		_definition
	)
	for project_id: StringName in completed_ids:
		if _session.awarded_research_project_ids.has(project_id) and _session.awarded_research_project_ids[project_id]:
			continue
		_session.awarded_research_project_ids[project_id] = true
		_session.research_points += CampaignCatalog.RESEARCH_POINTS_PER_RESEARCH_PROJECT


func _can_unlock(item: BootstrapUnlockDefinition) -> bool:
	if _session == null or _session.failed:
		return false
	if _session.has_skill(item.stable_id):
		return false
	if _session.research_points < item.cost_research_points:
		return false
	for prerequisite_id: StringName in item.prerequisite_ids:
		if not _session.has_skill(prerequisite_id):
			return false
	return true


func _fail_campaign(reason_id: StringName) -> void:
	if _session == null:
		return
	_session.failed = true
	_session.fail_reason_id = reason_id
	_session.abandon_pending = false
	if _workspace != null:
		_workspace.open_modal(CampaignPanelDefinition.PANEL_FAIL_STATE)
	refresh_presentation()


func _gameplay_camera() -> IsometricCamera:
	var world_root: Node = _active_world_root()
	if world_root == null:
		return null
	return world_root.get_node_or_null(GAMEPLAY_CAMERA_NAME) as IsometricCamera


func _set_camera_input_enabled(enabled: bool) -> void:
	var camera: IsometricCamera = _gameplay_camera()
	if camera != null:
		camera.input_enabled = enabled


func _apply_active_world_visibility() -> void:
	var world_id: StringName = &""
	if _session != null:
		world_id = _session.active_world_id
	var in_hq: bool = world_id == CampaignCatalog.WORLD_HQ
	var world_input: bool = _ui_session == null or _ui_session.input_context == CampaignInputContext.WORLD
	if _presenter != null:
		_presenter.set_campus_world_visible(in_hq)
	_set_world_active(get_node_or_null(CAMPUS_NODE_NAME), in_hq, world_input)
	_set_world_active(
		get_node_or_null(DATA_CENTER_WORLD_NAME),
		world_id == CampaignCatalog.WORLD_DATA_CENTER,
		world_input
	)
	_set_world_active(
		get_node_or_null(GOVERNMENT_WORLD_NAME),
		world_id == CampaignCatalog.WORLD_GOVERNMENT,
		world_input
	)


func _set_world_active(world_root: Node, active: bool, world_input: bool) -> void:
	if world_root == null:
		return
	var node_3d: Node3D = world_root as Node3D
	if node_3d != null:
		node_3d.visible = active
	var camera: Camera3D = world_root.get_node_or_null(GAMEPLAY_CAMERA_NAME) as Camera3D
	if camera == null:
		return
	camera.current = active
	var isometric_camera: IsometricCamera = camera as IsometricCamera
	if isometric_camera != null:
		isometric_camera.input_enabled = active and world_input


func _active_world_root() -> Node:
	if _session == null:
		return null
	match _session.active_world_id:
		CampaignCatalog.WORLD_HQ:
			return get_node_or_null(CAMPUS_NODE_NAME)
		CampaignCatalog.WORLD_DATA_CENTER:
			return get_node_or_null(DATA_CENTER_WORLD_NAME)
		CampaignCatalog.WORLD_GOVERNMENT:
			return get_node_or_null(GOVERNMENT_WORLD_NAME)
		_:
			return null


func _select_or_show_context(entity_id: StringName, card_type: StringName) -> void:
	var selectable: CampaignWorldSelectable = _find_selectable(entity_id)
	if selectable != null:
		select_world_selectable(selectable)
		return
	if _workspace != null:
		_workspace.show_context(entity_id, card_type)


func _on_world_selectable_selected(selectable: CampaignWorldSelectable) -> void:
	select_world_selectable(selectable)


func _connect_world_selectables() -> void:
	var nodes: Array[Node] = find_children("*", "Area3D", true, false)
	for node: Node in nodes:
		var selectable: CampaignWorldSelectable = node as CampaignWorldSelectable
		if selectable == null:
			continue
		if not selectable.selected.is_connected(_on_world_selectable_selected):
			selectable.selected.connect(_on_world_selectable_selected)


func _find_selectable(entity_id: StringName) -> CampaignWorldSelectable:
	var nodes: Array[Node] = find_children("*", "Area3D", true, false)
	for node: Node in nodes:
		var selectable: CampaignWorldSelectable = node as CampaignWorldSelectable
		if selectable == null:
			continue
		if selectable.entity_id == entity_id:
			return selectable
	return null


func _collect_active_selectables() -> Array[CampaignWorldSelectable]:
	var items: Array[CampaignWorldSelectable] = []
	var world_root: Node = _active_world_root()
	if world_root == null:
		return items
	var nodes: Array[Node] = world_root.find_children("*", "Area3D", true, false)
	var root_selectable: CampaignWorldSelectable = world_root as CampaignWorldSelectable
	if root_selectable != null:
		nodes.insert(0, root_selectable)
	for node: Node in nodes:
		var selectable: CampaignWorldSelectable = node as CampaignWorldSelectable
		if selectable == null:
			continue
		if not selectable.is_visible_in_tree():
			continue
		items.append(selectable)
	items.sort_custom(_compare_selection_order)
	return items


func _compare_selection_order(left: CampaignWorldSelectable, right: CampaignWorldSelectable) -> bool:
	return left.selection_order < right.selection_order


