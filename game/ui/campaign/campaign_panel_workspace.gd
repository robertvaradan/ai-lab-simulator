class_name CampaignPanelWorkspace
extends Control

const OPEN_WORKBENCH_SEC: float = 0.28
const OPEN_MODAL_SEC: float = 0.28
const CYAN: Color = Color(0.24313726, 0.78431374, 0.7529412, 1.0)

var _host: CampaignHost
var _registry: CampaignPanelRegistry = CampaignPanelRegistry.new()
var _focus_stack: CampaignFocusStack = CampaignFocusStack.new()
var _company_status: CampaignCompanyStatus
var _action_bar: CampaignActionBar
var _bell_button: Button
var _menu_button: Button
var _bell_badge: Label
var _selection_layer: Control
var _selection_connector: Line2D
var _selected_world_selectable: CampaignWorldSelectable
var _context_card: CampaignContextCard
var _context_host: Control
var _workbench_host: Control
var _workbench_panel: PanelContainer
var _modal_host: Control
var _modal_dim: ColorRect
var _modal_center: CenterContainer
var _company_overview: CampaignCompanyOverviewPanel
var _plan_workbench: CampaignPlanWorkbench
var _timeline_panel: CampaignTimelinePanel
var _world_map: CampaignWorldMapPanel
var _pause_panel: CampaignPausePanel
var _fail_state: CampaignFailStatePanel
var _advance_transition: CampaignAdvanceTransitionPanel
var _data_center: DataCenterView
var _government: GovernmentPlaceholderView
var _active_workbench: Control
var _active_modal: Control
var _last_status_text: String = ""
var _last_attention_text: String = ""
var _last_report_text: String = ""
var _last_state_text: String = ""
var _last_lab_text: String = ""
var _pending_attention_after_advance: bool = false


func bind_host(host: CampaignHost) -> void:
	_host = host
	if _company_overview != null:
		_company_overview.bind_host(host)
	if _plan_workbench != null:
		_plan_workbench.bind_host(host)
	if _timeline_panel != null:
		_timeline_panel.bind_host(host)
	if _world_map != null:
		_world_map.bind_host(host)
	if _pause_panel != null:
		_pause_panel.bind_host(host)
	if _fail_state != null:
		_fail_state.bind_host(host)
	if _context_card != null:
		_context_card.bind_host(host)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_register_panels()
	_build_tree()
	if _host != null:
		bind_host(_host)
	set_process_unhandled_input(true)


func _process(_delta: float) -> void:
	if _context_card != null and _context_card.visible:
		_update_selection_graphics(true)


func open_workbench(panel_id: StringName, tab_id: StringName = &"") -> void:
	var definition: CampaignPanelDefinition = _registry.get_panel(panel_id)
	if definition == null:
		return
	if definition.surface_type != CampaignPanelDefinition.SURFACE_WORKBENCH:
		ServiceContract.fail("invalid_workbench", "Panel %s is not a Workbench." % String(panel_id))
		return
	_show_workbench(_panel_for_id(panel_id), panel_id, tab_id)


func show_context(
		entity_id: StringName,
		card_type: StringName,
		framing_target: Vector3 = Vector3.ZERO,
		framing_size: float = 18.0
	) -> void:
	if _context_card == null or _host == null:
		return
	var ui_session: CampaignUiSessionState = _host.get_ui_session()
	if ui_session != null:
		ui_session.set_world_selection(_host.get_active_world_id(), entity_id)
		ui_session.input_context = CampaignInputContext.UI
		ui_session.context_collapsed = false
	_selected_world_selectable = _find_world_selectable(entity_id)
	_context_card.present_context(entity_id, card_type, _host.get_current_state(), _host.get_definition())
	_context_host.visible = true
	_update_selection_graphics(true)
	_host.reframe_selection(framing_target, framing_size)
	_sync_compat_context_visibility()


func open_modal(panel_id: StringName) -> void:
	var definition: CampaignPanelDefinition = _registry.get_panel(panel_id)
	if definition == null:
		return
	if definition.surface_type != CampaignPanelDefinition.SURFACE_MODAL:
		ServiceContract.fail("invalid_modal", "Panel %s is not a Modal." % String(panel_id))
		return
	_show_modal(_panel_for_id(panel_id), panel_id)


func back() -> void:
	if _active_modal != null and _active_modal.visible:
		if _active_modal == _fail_state and _host != null:
			var session: CampaignSessionState = _host.get_session()
			if session != null and session.failed:
				return
		_hide_modal()
		return
	if _active_workbench != null and _workbench_host.visible:
		_hide_workbench()
		return
	if _context_card != null and _context_card.visible:
		_hide_context()
		return
	open_modal(CampaignPanelDefinition.PANEL_PAUSE)


func present() -> void:
	if _host == null:
		return
	present_state(
		_host.get_current_state(),
		_host.get_last_result(),
		_host.get_definition(),
		_host.get_session()
	)


func present_state(
		state: GameState,
		last_result: SimulationOperationResult,
		definition: MarketingScenarioDefinition,
		session: CampaignSessionState
	) -> void:
	if session == null:
		return
	var validation: PlanValidationResult = null
	if _host != null:
		validation = _host.validate_draft_plan()
	if _company_status != null:
		_company_status.present_state(state)
	if _action_bar != null:
		_action_bar.present(session, validation)
	_update_status_texts(state, last_result, session)
	if _company_overview != null:
		_company_overview.present_state(state, session)
	if _plan_workbench != null:
		_plan_workbench.present_state(state, session, definition, validation)
	if _timeline_panel != null:
		var ui_session: CampaignUiSessionState = null
		if _host != null:
			ui_session = _host.get_ui_session()
		_timeline_panel.present_state(state, ui_session)
		_last_attention_text = _timeline_panel.get_attention_text()
		_last_report_text = _timeline_panel.get_report_text()
	if _data_center != null:
		_data_center.present_state(state, definition)
	if _government != null:
		_government.present_state(state)
	if _fail_state != null:
		_fail_state.present_session(state, session)
	_sync_surface_visibility(session)
	_update_bell_badge(state)
	if session.failed or session.abandon_pending:
		if _active_modal != _fail_state or not _modal_host.visible:
			open_modal(CampaignPanelDefinition.PANEL_FAIL_STATE)


func play_advance_transition(model: CampaignAdvanceTransitionModel) -> void:
	if model == null or _advance_transition == null:
		return
	_pending_attention_after_advance = model.attention_boundary
	open_modal(CampaignPanelDefinition.PANEL_ADVANCE_TRANSITION)
	_advance_transition.play(model)


func close_workbench_if(panel_id: StringName) -> void:
	if _active_workbench == null:
		return
	if _panel_for_id(panel_id) == _active_workbench:
		_hide_workbench()


func clear_context_if_world_entity() -> void:
	if _context_card == null or not _context_card.visible:
		return
	var card_type: StringName = _context_card.get_card_type()
	if (
		card_type == CampaignWorldSelectable.CONTEXT_DATA_CENTER
		or card_type == CampaignWorldSelectable.CONTEXT_GOVERNMENT
	):
		_hide_context()


func get_fail_state() -> CampaignFailStatePanel:
	return _fail_state


func get_skill_tree() -> SkillTreeView:
	if _plan_workbench == null:
		return null
	return _plan_workbench.get_skill_tree()


func get_data_center() -> DataCenterView:
	return _data_center


func get_world_map() -> CampaignWorldMapPanel:
	return _world_map


func get_government() -> GovernmentPlaceholderView:
	return _government


func get_context_card() -> CampaignContextCard:
	return _context_card


func get_advance_button() -> Button:
	if _action_bar == null:
		return null
	return _action_bar.get_advance_button()


func get_status_text() -> String:
	return _last_status_text


func get_attention_text() -> String:
	return _last_attention_text


func get_report_text() -> String:
	return _last_report_text


func get_state_text() -> String:
	return _last_state_text


func get_lab_text() -> String:
	return _last_lab_text


func set_build_laboratory_selected(selected: bool) -> void:
	if _host != null:
		_host.set_project_staged(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID, selected)


func set_research_selected(selected: bool) -> void:
	if _host != null:
		_host.set_project_staged(CampaignCatalog.RESEARCH_PROJECT_ID, selected)


func set_scale_selected(selected: bool) -> void:
	if _host != null:
		_host.set_project_staged(CampaignCatalog.SCALE_PROJECT_ID, selected)


func set_coding_agent_selected(selected: bool) -> void:
	if _host != null:
		_host.set_project_staged(CampaignCatalog.CODING_AGENT_PROJECT_ID, selected)


func set_model_identity(display_name: String, version_label: String) -> void:
	if _host == null or _host.get_draft() == null:
		return
	_host.get_draft().model_display_name = display_name
	_host.get_draft().model_version_label = version_label


func build_plan(state: GameState) -> Plan:
	if _host == null or _host.get_draft() == null:
		return Plan.new()
	return _host.get_draft().build_plan(state)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed(&"campaign_back") or event.is_action_pressed(&"ui_cancel") or (
		event is InputEventKey
		and (event as InputEventKey).pressed
		and (event as InputEventKey).keycode == KEY_ESCAPE
	):
		back()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"campaign_menu"):
		open_modal(CampaignPanelDefinition.PANEL_PAUSE)
		get_viewport().set_input_as_handled()
		return
	if _host == null:
		return
	if _active_modal != null and _modal_host.visible:
		return
	if event.is_action_pressed(&"campaign_tab_next") or event.is_action_pressed(&"campaign_tab_prev"):
		if _workbench_host.visible and _active_workbench == _plan_workbench and _plan_workbench != null:
			var tab_delta: int = 1 if event.is_action_pressed(&"campaign_tab_next") else -1
			_plan_workbench.cycle_tab(tab_delta)
			var tab_session: CampaignUiSessionState = _host.get_ui_session()
			if tab_session != null:
				tab_session.active_tab_id = (
					CampaignPanelDefinition.TAB_SKILL_TREE
					if _plan_workbench.get_skill_tree() != null and _plan_workbench.get_skill_tree().visible
					else CampaignPanelDefinition.TAB_PROJECTS
				)
			get_viewport().set_input_as_handled()
		return
	if _workbench_host.visible:
		return
	if event.is_action_pressed(&"campaign_cycle_next"):
		_host.cycle_world_selection(1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"campaign_cycle_prev"):
		_host.cycle_world_selection(-1)
		get_viewport().set_input_as_handled()
		return
	var ui_session: CampaignUiSessionState = _host.get_ui_session()
	if (
		event.is_action_pressed(&"campaign_accept")
		and (ui_session == null or ui_session.input_context == CampaignInputContext.WORLD)
	):
		_host.cycle_world_selection(1)
		get_viewport().set_input_as_handled()


func _register_panels() -> void:
	for definition: CampaignPanelDefinition in CampaignPanelDefinition.known_panels():
		_registry.register(definition)


func _build_tree() -> void:
	var chrome: Control = Control.new()
	chrome.name = "ChromeLayer"
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(chrome)
	var status_packed: PackedScene = load("res://ui/campaign/chrome/company_status.tscn") as PackedScene
	_company_status = status_packed.instantiate() as CampaignCompanyStatus
	_company_status.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_company_status.position = Vector2(24.0, 24.0)
	_company_status.activated.connect(_on_company_status_activated)
	chrome.add_child(_company_status)
	var top_right: HBoxContainer = HBoxContainer.new()
	top_right.name = "TopRightActions"
	top_right.mouse_filter = Control.MOUSE_FILTER_STOP
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -140.0
	top_right.offset_top = 24.0
	top_right.offset_right = -24.0
	top_right.offset_bottom = 72.0
	top_right.add_theme_constant_override("separation", 8)
	chrome.add_child(top_right)
	var bell_wrap: Control = Control.new()
	bell_wrap.custom_minimum_size = Vector2(48.0, 48.0)
	top_right.add_child(bell_wrap)
	_bell_button = Button.new()
	_bell_button.name = "BellButton"
	_bell_button.theme_type_variation = &"SquareIconAction"
	_bell_button.custom_minimum_size = Vector2(48.0, 48.0)
	_bell_button.icon = load(CampaignPresentationDefinition.ICON_BELL_OUTLINE_PATH) as Texture2D
	_bell_button.expand_icon = true
	_bell_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bell_button.pressed.connect(_on_bell_pressed)
	bell_wrap.add_child(_bell_button)
	_bell_badge = Label.new()
	_bell_badge.name = "BellBadge"
	_bell_badge.visible = false
	_bell_badge.add_theme_font_size_override("font_size", 12)
	_bell_badge.position = Vector2(30.0, 0.0)
	bell_wrap.add_child(_bell_badge)
	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.theme_type_variation = &"SquareIconAction"
	_menu_button.custom_minimum_size = Vector2(48.0, 48.0)
	_menu_button.icon = load(CampaignPresentationDefinition.ICON_SETTINGS_OUTLINE_PATH) as Texture2D
	_menu_button.expand_icon = true
	_menu_button.pressed.connect(_on_menu_pressed)
	top_right.add_child(_menu_button)
	var action_packed: PackedScene = load("res://ui/campaign/chrome/action_bar.tscn") as PackedScene
	_action_bar = action_packed.instantiate() as CampaignActionBar
	_action_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_action_bar.offset_top = -96.0
	_action_bar.world_map_pressed.connect(_on_world_map_pressed)
	_action_bar.world_pressed.connect(_on_world_pressed)
	_action_bar.plan_pressed.connect(_on_plan_pressed)
	_action_bar.advance_pressed.connect(_on_advance_pressed)
	chrome.add_child(_action_bar)
	_selection_layer = Control.new()
	_selection_layer.name = "SelectionLayer"
	_selection_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_selection_layer)
	_selection_connector = Line2D.new()
	_selection_connector.name = "SelectionConnector"
	_selection_connector.width = 2.0
	_selection_connector.default_color = CYAN
	_selection_connector.visible = false
	_selection_layer.add_child(_selection_connector)
	_context_host = Control.new()
	_context_host.name = "ContextCardHost"
	_context_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_context_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_context_host)
	var context_packed: PackedScene = load("res://ui/campaign/chrome/context_card.tscn") as PackedScene
	_context_card = context_packed.instantiate() as CampaignContextCard
	_context_card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_context_card.offset_left = -360.0
	_context_card.offset_top = -160.0
	_context_card.offset_right = -24.0
	_context_card.offset_bottom = 160.0
	_context_card.closed.connect(_on_context_closed)
	_context_card.primary_action_pressed.connect(_on_context_primary)
	_context_host.add_child(_context_card)
	_data_center = DataCenterView.new()
	_data_center.name = "DataCenterView"
	_data_center.visible = false
	_context_host.add_child(_data_center)
	_government = GovernmentPlaceholderView.new()
	_government.name = "GovernmentPlaceholderView"
	_government.visible = false
	_context_host.add_child(_government)
	_workbench_host = Control.new()
	_workbench_host.name = "WorkbenchHost"
	_workbench_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_workbench_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_workbench_host.offset_left = 120.0
	_workbench_host.offset_top = 96.0
	_workbench_host.offset_right = -120.0
	_workbench_host.offset_bottom = -120.0
	_workbench_host.visible = false
	add_child(_workbench_host)
	_workbench_panel = PanelContainer.new()
	_workbench_panel.name = "WorkbenchFrame"
	_workbench_panel.theme_type_variation = &"Workbench"
	_workbench_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_workbench_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_workbench_host.add_child(_workbench_panel)
	_company_overview = _instance_panel(CampaignPanelDefinition.SCENE_COMPANY_OVERVIEW) as CampaignCompanyOverviewPanel
	_plan_workbench = _instance_panel(CampaignPanelDefinition.SCENE_PLAN) as CampaignPlanWorkbench
	_timeline_panel = _instance_panel(CampaignPanelDefinition.SCENE_TIMELINE) as CampaignTimelinePanel
	_world_map = _instance_panel(CampaignPanelDefinition.SCENE_WORLD_MAP) as CampaignWorldMapPanel
	for panel: Control in [_company_overview, _plan_workbench, _timeline_panel, _world_map]:
		if panel == null:
			continue
		panel.visible = false
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_workbench_panel.add_child(panel)
	_modal_host = Control.new()
	_modal_host.name = "ModalHost"
	_modal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_host.visible = false
	add_child(_modal_host)
	_modal_dim = ColorRect.new()
	_modal_dim.name = "ModalDim"
	_modal_dim.color = Color(0.050980393, 0.1254902, 0.15294118, 0.72)
	_modal_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_host.add_child(_modal_dim)
	_modal_center = CenterContainer.new()
	_modal_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_host.add_child(_modal_center)
	_pause_panel = _instance_panel(CampaignPanelDefinition.SCENE_PAUSE) as CampaignPausePanel
	_fail_state = _instance_panel(CampaignPanelDefinition.SCENE_FAIL_STATE) as CampaignFailStatePanel
	_advance_transition = _instance_panel(CampaignPanelDefinition.SCENE_ADVANCE_TRANSITION) as CampaignAdvanceTransitionPanel
	for modal: Control in [_pause_panel, _fail_state, _advance_transition]:
		if modal == null:
			continue
		modal.visible = false
		modal.custom_minimum_size = Vector2(640.0, 360.0)
		_modal_center.add_child(modal)
	if _advance_transition != null:
		_advance_transition.finished.connect(_on_advance_transition_finished)


func _instance_panel(path: String) -> Control:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		ServiceContract.fail("missing_panel_scene", "The panel scene did not load: %s" % path)
		return null
	return packed.instantiate() as Control


func _panel_for_id(panel_id: StringName) -> Control:
	match panel_id:
		CampaignPanelDefinition.PANEL_COMPANY_OVERVIEW:
			return _company_overview
		CampaignPanelDefinition.PANEL_PLAN:
			return _plan_workbench
		CampaignPanelDefinition.PANEL_TIMELINE:
			return _timeline_panel
		CampaignPanelDefinition.PANEL_WORLD_MAP:
			return _world_map
		CampaignPanelDefinition.PANEL_PAUSE:
			return _pause_panel
		CampaignPanelDefinition.PANEL_FAIL_STATE:
			return _fail_state
		CampaignPanelDefinition.PANEL_ADVANCE_TRANSITION:
			return _advance_transition
		_:
			return null


func _show_workbench(panel: Control, panel_id: StringName, tab_id: StringName) -> void:
	if panel == null:
		return
	for child: Node in _workbench_panel.get_children():
		var control: Control = child as Control
		if control != null:
			control.visible = false
	panel.visible = true
	_active_workbench = panel
	_workbench_host.visible = true
	_workbench_host.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_workbench_host, "modulate:a", 1.0, OPEN_WORKBENCH_SEC)
	if panel == _plan_workbench:
		var resolved_tab: StringName = tab_id
		if resolved_tab == &"":
			resolved_tab = CampaignPanelDefinition.TAB_PROJECTS
		_plan_workbench.set_active_tab(resolved_tab)
	if _host != null:
		var ui_session: CampaignUiSessionState = _host.get_ui_session()
		if ui_session != null:
			ui_session.active_workbench_id = panel_id
			ui_session.active_tab_id = tab_id
			ui_session.input_context = CampaignInputContext.UI
			ui_session.workbench_collapsed = false
	_sync_compat_context_visibility()


func _hide_workbench() -> void:
	_workbench_host.visible = false
	if _active_workbench != null:
		_active_workbench.visible = false
	_active_workbench = null
	if _host != null:
		var ui_session: CampaignUiSessionState = _host.get_ui_session()
		if ui_session != null:
			ui_session.active_workbench_id = &""
			ui_session.active_tab_id = &""
			if _context_card == null or not _context_card.visible:
				ui_session.input_context = CampaignInputContext.WORLD
		var session: CampaignSessionState = _host.get_session()
		if session != null and session.active_view_id == CampaignCatalog.VIEW_SKILL_TREE:
			session.active_view_id = CampaignCatalog.VIEW_CAMPUS
		if session != null and session.active_world_id == CampaignCatalog.WORLD_MAP:
			session.active_world_id = CampaignCatalog.WORLD_HQ
	_sync_compat_context_visibility()


func _show_modal(panel: Control, panel_id: StringName) -> void:
	if panel == null:
		return
	for child: Node in _modal_center.get_children():
		var control: Control = child as Control
		if control != null:
			control.visible = false
	panel.visible = true
	_active_modal = panel
	_modal_host.visible = true
	_modal_host.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(_modal_host, "modulate:a", 1.0, OPEN_MODAL_SEC)
	if _host != null:
		var ui_session: CampaignUiSessionState = _host.get_ui_session()
		if ui_session != null:
			ui_session.input_context = CampaignInputContext.MODAL
	if panel == _fail_state and _host != null:
		_fail_state.present_session(_host.get_current_state(), _host.get_session())


func _hide_modal() -> void:
	_modal_host.visible = false
	if _active_modal != null:
		_active_modal.visible = false
	_active_modal = null
	if _host != null:
		var ui_session: CampaignUiSessionState = _host.get_ui_session()
		if ui_session != null:
			if _workbench_host.visible or (_context_card != null and _context_card.visible):
				ui_session.input_context = CampaignInputContext.UI
			else:
				ui_session.input_context = CampaignInputContext.WORLD


func _hide_context() -> void:
	if _context_card != null:
		_context_card.visible = false
	_update_selection_graphics(false)
	_selected_world_selectable = null
	if _host != null:
		_host.restore_framing()
		var ui_session: CampaignUiSessionState = _host.get_ui_session()
		if ui_session != null:
			ui_session.set_world_selection(_host.get_active_world_id(), &"")
			if not _workbench_host.visible and _active_modal == null:
				ui_session.input_context = CampaignInputContext.WORLD
	_sync_compat_context_visibility()


func _sync_surface_visibility(session: CampaignSessionState) -> void:
	var skill_overlay: bool = session.active_view_id == CampaignCatalog.VIEW_SKILL_TREE
	if skill_overlay:
		if _plan_workbench == null or not _plan_workbench.visible or not _workbench_host.visible:
			open_workbench(CampaignPanelDefinition.PANEL_PLAN, CampaignPanelDefinition.TAB_SKILL_TREE)
		elif _plan_workbench != null:
			_plan_workbench.set_active_tab(CampaignPanelDefinition.TAB_SKILL_TREE)
	if session.active_world_id == CampaignCatalog.WORLD_MAP and not skill_overlay:
		if _world_map == null or not _world_map.visible or not _workbench_host.visible:
			open_workbench(CampaignPanelDefinition.PANEL_WORLD_MAP)
	if _world_map != null:
		_world_map.visible = session.active_world_id == CampaignCatalog.WORLD_MAP and not skill_overlay and _workbench_host.visible
	if _data_center != null:
		_data_center.visible = session.active_world_id == CampaignCatalog.WORLD_DATA_CENTER and not skill_overlay
	if _government != null:
		_government.visible = session.active_world_id == CampaignCatalog.WORLD_GOVERNMENT and not skill_overlay
	var skill_tree: SkillTreeView = get_skill_tree()
	if skill_tree != null:
		skill_tree.visible = skill_overlay and _workbench_host.visible
	_sync_compat_context_visibility()


func _sync_compat_context_visibility() -> void:
	pass


func _update_selection_graphics(enabled: bool) -> void:
	if _selection_connector == null:
		return
	_selection_connector.visible = false
	if not enabled or _selected_world_selectable == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var card_center: Vector2 = _context_card.get_global_rect().get_center()
	var source_screen: Vector2 = _project_highlight_right_edge(camera)
	if not source_screen.is_finite():
		return
	_selection_connector.points = PackedVector2Array([
		_to_selection_layer_point(source_screen),
		_to_selection_layer_point(card_center),
	])
	_selection_connector.visible = true


func _find_world_selectable(entity_id: StringName) -> CampaignWorldSelectable:
	if _host == null:
		return null
	var nodes: Array[Node] = _host.find_children("*", "Area3D", true, false)
	for node: Node in nodes:
		var selectable: CampaignWorldSelectable = node as CampaignWorldSelectable
		if selectable == null:
			continue
		if selectable.entity_id == entity_id:
			return selectable
	return null


func _project_highlight_right_edge(camera: Camera3D) -> Vector2:
	var highlight: MeshInstance3D = _selected_world_selectable.get_node_or_null("Outline") as MeshInstance3D
	if highlight == null or highlight.mesh == null:
		return Vector2.INF
	var bounds: AABB = highlight.get_aabb()
	var minimum: Vector3 = bounds.position
	var maximum: Vector3 = bounds.end
	var corners: Array[Vector3] = [
		Vector3(minimum.x, minimum.y, minimum.z),
		Vector3(maximum.x, minimum.y, minimum.z),
		Vector3(maximum.x, minimum.y, maximum.z),
		Vector3(minimum.x, minimum.y, maximum.z),
		Vector3(minimum.x, maximum.y, minimum.z),
		Vector3(maximum.x, maximum.y, minimum.z),
		Vector3(maximum.x, maximum.y, maximum.z),
		Vector3(minimum.x, maximum.y, maximum.z),
	]
	var edge_sum: Vector2 = Vector2.ZERO
	var edge_count: int = 0
	var rightmost_x: float = -INF
	for corner: Vector3 in corners:
		var world_point: Vector3 = highlight.global_transform * corner
		if camera.is_position_behind(world_point):
			continue
		var screen_point: Vector2 = camera.unproject_position(world_point)
		if screen_point.x > rightmost_x + 0.1:
			rightmost_x = screen_point.x
			edge_sum = screen_point
			edge_count = 1
		elif absf(screen_point.x - rightmost_x) <= 0.1:
			edge_sum += screen_point
			edge_count += 1
	if edge_count == 0:
		return Vector2.INF
	return edge_sum / float(edge_count)


func _to_selection_layer_point(screen_point: Vector2) -> Vector2:
	if _selection_layer == null:
		return screen_point
	return _selection_layer.get_global_transform().affine_inverse() * screen_point


func _update_status_texts(
		state: GameState,
		last_result: SimulationOperationResult,
		session: CampaignSessionState
	) -> void:
	if state == null:
		_last_state_text = "Game State is missing."
		return
	var cash_musd: int = CampaignCatalog.cash_balance_musd(state)
	var state_lines: PackedStringArray = PackedStringArray([
		"Month Step %d" % state.calendar.current_month_step_index,
		"Quarter %d" % state.calendar.current_quarter_index,
		"Cash %d MUSD" % cash_musd,
		"Research points %d" % session.research_points,
		"Project teams %d" % state.company.project_team_count,
	])
	if TrustThreshold.is_public_trust_active(state):
		state_lines.append("Public Trust %d" % state.company.public_trust_points)
	if TrustThreshold.is_government_active(state):
		state_lines.append("Government Trust %d" % state.company.government_trust_points)
	_last_state_text = "\n".join(state_lines)
	_last_lab_text = "Laboratory capacity level %d.\n%s.\nThe visible campus is the authored campus blockout." % [
		CampaignCatalog.laboratory_capacity_level(state),
		CampaignCatalog.laboratory_stage_label(state),
	]
	if last_result == null:
		_last_status_text = "Ready."
	elif last_result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED:
		_last_status_text = "Attention is required."
	elif last_result.outcome == SimulationOperationOutcome.Type.COMPLETED:
		_last_status_text = "Advance completed."
	elif last_result.outcome == SimulationOperationOutcome.Type.REJECTED:
		_last_status_text = "Advance rejected."
	else:
		_last_status_text = "Advance faulted."
	if session.failed:
		_last_status_text = CampaignCatalog.fail_reason_text(session.fail_reason_id)


func _update_bell_badge(state: GameState) -> void:
	if _bell_badge == null or state == null or _host == null:
		return
	var ui_session: CampaignUiSessionState = _host.get_ui_session()
	var unread: int = 0
	for event: AttentionEventState in state.attention_events:
		if event == null:
			continue
		if ui_session == null or not ui_session.is_timeline_read(event.stable_id):
			unread += 1
	for notification: NotificationState in state.notifications:
		if notification == null:
			continue
		if ui_session == null or not ui_session.is_timeline_read(notification.stable_id):
			unread += 1
	_bell_badge.visible = unread > 0
	_bell_badge.text = str(unread)


func _on_company_status_activated() -> void:
	open_workbench(CampaignPanelDefinition.PANEL_COMPANY_OVERVIEW)


func _on_bell_pressed() -> void:
	open_workbench(CampaignPanelDefinition.PANEL_TIMELINE)


func _on_menu_pressed() -> void:
	open_modal(CampaignPanelDefinition.PANEL_PAUSE)


func _on_world_map_pressed() -> void:
	if _host != null:
		_host.set_active_world(CampaignCatalog.WORLD_MAP)


func _on_world_pressed() -> void:
	if _host == null:
		return
	var session: CampaignSessionState = _host.get_session()
	if session == null:
		return
	if session.active_world_id == CampaignCatalog.WORLD_MAP:
		_host.enter_world(CampaignCatalog.WORLD_HQ)
		return
	_host.enter_world(session.active_world_id)


func _on_plan_pressed() -> void:
	open_workbench(CampaignPanelDefinition.PANEL_PLAN, CampaignPanelDefinition.TAB_PROJECTS)


func _on_advance_pressed() -> void:
	if _host != null:
		_host.advance_from_hud()


func _on_context_closed() -> void:
	_hide_context()


func _on_context_primary(action_id: StringName) -> void:
	if action_id == &"open_projects":
		open_workbench(CampaignPanelDefinition.PANEL_PLAN, CampaignPanelDefinition.TAB_PROJECTS)
		if _plan_workbench != null:
			_plan_workbench.select_project(CampaignCatalog.RESEARCH_PROJECT_ID)


func _on_advance_transition_finished() -> void:
	_hide_modal()
	if not _pending_attention_after_advance:
		return
	_pending_attention_after_advance = false
	open_workbench(CampaignPanelDefinition.PANEL_TIMELINE)
	if _timeline_panel != null:
		_timeline_panel.focus_first_attention()
