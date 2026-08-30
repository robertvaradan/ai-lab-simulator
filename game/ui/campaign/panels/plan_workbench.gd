class_name CampaignPlanWorkbench
extends Control

var _host: CampaignHost
var _skill_tree: SkillTreeView
var _projects_tab: Button
var _skill_tab: Button
var _projects_scroll: ScrollContainer
var _projects_column: VBoxContainer
var _draft_label: Label
var _diagnostics_label: Label
var _model_name_edit: LineEdit
var _model_version_edit: LineEdit
var _project_checks: Dictionary[StringName, CheckBox] = {}
var _selected_project_id: StringName = &""


func bind_host(host: CampaignHost) -> void:
	_host = host
	if _skill_tree != null:
		_skill_tree.bind_host(host)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	if _host != null:
		bind_host(_host)


func get_skill_tree() -> SkillTreeView:
	return _skill_tree


func get_unlock_button(skill_id: StringName) -> Button:
	if _skill_tree == null:
		return null
	return _skill_tree.get_unlock_button(skill_id)


func set_active_tab(tab_id: StringName) -> void:
	var show_skill: bool = tab_id == CampaignPanelDefinition.TAB_SKILL_TREE
	if _skill_tree != null:
		_skill_tree.visible = show_skill
	if _projects_scroll != null:
		_projects_scroll.visible = not show_skill
	if _projects_tab != null:
		_projects_tab.disabled = not show_skill
	if _skill_tab != null:
		_skill_tab.disabled = show_skill


func cycle_tab(delta: int) -> void:
	if delta == 0:
		return
	var skill_visible: bool = _skill_tree != null and _skill_tree.visible
	if skill_visible:
		set_active_tab(CampaignPanelDefinition.TAB_PROJECTS)
	else:
		set_active_tab(CampaignPanelDefinition.TAB_SKILL_TREE)


func select_project(project_id: StringName) -> void:
	_selected_project_id = project_id
	_refresh_project_highlight()


func present_state(
		state: GameState,
		session: CampaignSessionState,
		definition: MarketingScenarioDefinition,
		validation: PlanValidationResult
	) -> void:
	if _skill_tree != null:
		_skill_tree.present_state(state, session)
	_sync_checks()
	_refresh_project_cards(state, definition)
	_refresh_draft_summary()
	_refresh_diagnostics(validation)


func _build() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "PlanPanel"
	panel.theme_type_variation = &"Workbench"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var title: Label = Label.new()
	title.text = "Plan"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	layout.add_child(tabs)
	_projects_tab = Button.new()
	_projects_tab.text = "Projects"
	_projects_tab.theme_type_variation = &"SegmentedNav"
	_projects_tab.custom_minimum_size = Vector2(140.0, 48.0)
	_projects_tab.pressed.connect(func() -> void: set_active_tab(CampaignPanelDefinition.TAB_PROJECTS))
	tabs.add_child(_projects_tab)
	_skill_tab = Button.new()
	_skill_tab.text = "Skill Tree"
	_skill_tab.theme_type_variation = &"SegmentedNav"
	_skill_tab.custom_minimum_size = Vector2(140.0, 48.0)
	_skill_tab.pressed.connect(func() -> void: set_active_tab(CampaignPanelDefinition.TAB_SKILL_TREE))
	tabs.add_child(_skill_tab)
	_projects_scroll = ScrollContainer.new()
	_projects_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_projects_scroll)
	_projects_column = VBoxContainer.new()
	_projects_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_projects_column.add_theme_constant_override("separation", 12)
	_projects_scroll.add_child(_projects_column)
	_draft_label = Label.new()
	_draft_label.name = "DraftSummary"
	_draft_label.add_theme_font_size_override("font_size", 18)
	_draft_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_draft_label)
	_diagnostics_label = Label.new()
	_diagnostics_label.name = "Diagnostics"
	_diagnostics_label.add_theme_font_size_override("font_size", 18)
	_diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_diagnostics_label)
	_skill_tree = SkillTreeView.new()
	_skill_tree.name = "SkillTreeView"
	_skill_tree.visible = false
	_skill_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_skill_tree)
	set_active_tab(CampaignPanelDefinition.TAB_PROJECTS)


func _refresh_project_cards(state: GameState, definition: MarketingScenarioDefinition) -> void:
	if _projects_column == null:
		return
	for child: Node in _projects_column.get_children():
		child.queue_free()
	_project_checks.clear()
	_model_name_edit = null
	_model_version_edit = null
	var research_ids: Array[StringName] = []
	research_ids.append(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID)
	research_ids.append(CampaignCatalog.RESEARCH_PROJECT_ID)
	_add_group("Research", research_ids, state, definition)
	var scale_ids: Array[StringName] = []
	scale_ids.append(CampaignCatalog.SCALE_PROJECT_ID)
	_add_group("Scale", scale_ids, state, definition)
	var application_ids: Array[StringName] = []
	application_ids.append(CampaignCatalog.CODING_AGENT_PROJECT_ID)
	_add_group("Applications", application_ids, state, definition)


func _add_group(
		title_text: String,
		project_ids: Array[StringName],
		state: GameState,
		definition: MarketingScenarioDefinition
	) -> void:
	var heading: Label = Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 18)
	_projects_column.add_child(heading)
	for project_id: StringName in project_ids:
		_projects_column.add_child(_make_project_card(project_id, state, definition))


func _make_project_card(
		project_id: StringName,
		state: GameState,
		definition: MarketingScenarioDefinition
	) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = "%sCard" % String(project_id).replace(".", "_")
	card.theme_type_variation = &"Workbench"
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var check: CheckBox = CheckBox.new()
	check.name = "%sCheck" % String(project_id).replace(".", "_")
	check.text = _project_display_name(project_id)
	check.custom_minimum_size = Vector2(0.0, 48.0)
	var already_started: bool = (
		state != null
		and state.company != null
		and state.company.projects.has(project_id)
	)
	check.disabled = already_started
	var draft: CampaignDraftPlanState = null
	if _host != null:
		draft = _host.get_draft()
	check.set_pressed_no_signal(draft != null and draft.has_staged_project(project_id))
	check.toggled.connect(_on_project_toggled.bind(project_id))
	column.add_child(check)
	_project_checks[project_id] = check
	var project_def: ProjectDefinition = CampaignCatalog.find_project(definition, project_id)
	var details: Label = Label.new()
	details.add_theme_font_size_override("font_size", 18)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if project_def == null:
		details.text = "Project definition is missing."
	else:
		var prereq_text: String = "None"
		if not project_def.prerequisite_project_ids.is_empty():
			prereq_text = ", ".join(PackedStringArray(
				_string_names(project_def.prerequisite_project_ids)
			))
		var available_text: String = "Available"
		if already_started:
			available_text = "Already started"
		details.text = "Cost %d MUSD. Duration %d Month Steps. Capacity teams %d. Compute %d. Prerequisites %s. %s." % [
			project_def.start_cost_musd,
			project_def.duration_month_steps,
			project_def.reserved_project_teams,
			project_def.reserved_compute_unit_months,
			prereq_text,
			available_text,
		]
	column.add_child(details)
	if project_id == CampaignCatalog.RESEARCH_PROJECT_ID:
		_model_name_edit = LineEdit.new()
		_model_name_edit.placeholder_text = "Model display name"
		_model_name_edit.custom_minimum_size = Vector2(0.0, 48.0)
		_model_name_edit.text = (
			draft.model_display_name if draft != null else CampaignDraftPlanState.DEFAULT_MODEL_DISPLAY_NAME
		)
		_model_name_edit.text_changed.connect(_on_model_name_changed)
		column.add_child(_model_name_edit)
		_model_version_edit = LineEdit.new()
		_model_version_edit.placeholder_text = "Model version"
		_model_version_edit.custom_minimum_size = Vector2(0.0, 48.0)
		_model_version_edit.text = (
			draft.model_version_label if draft != null else CampaignDraftPlanState.DEFAULT_MODEL_VERSION_LABEL
		)
		_model_version_edit.text_changed.connect(_on_model_version_changed)
		column.add_child(_model_version_edit)
	if project_id == _selected_project_id:
		card.modulate = Color(0.85, 1.0, 1.0, 1.0)
	return card


func _string_names(ids: Array[StringName]) -> PackedStringArray:
	var values: PackedStringArray = PackedStringArray()
	for id_value: StringName in ids:
		values.append(String(id_value))
	return values


func _project_display_name(project_id: StringName) -> String:
	if project_id == CampaignCatalog.BUILD_LABORATORY_PROJECT_ID:
		return "Build Laboratory"
	if project_id == CampaignCatalog.RESEARCH_PROJECT_ID:
		return "Research Frontier Model"
	if project_id == CampaignCatalog.SCALE_PROJECT_ID:
		return "Scale Burst Compute"
	if project_id == CampaignCatalog.CODING_AGENT_PROJECT_ID:
		return "Coding Agent Application"
	return String(project_id)


func _sync_checks() -> void:
	var draft: CampaignDraftPlanState = null
	if _host != null:
		draft = _host.get_draft()
	for project_id: StringName in _project_checks.keys():
		var check: CheckBox = _project_checks[project_id]
		if check == null:
			continue
		check.set_pressed_no_signal(draft != null and draft.has_staged_project(project_id))


func _refresh_draft_summary() -> void:
	if _draft_label == null:
		return
	var draft: CampaignDraftPlanState = null
	if _host != null:
		draft = _host.get_draft()
	if draft == null:
		_draft_label.text = "Draft: none"
		return
	var staged: PackedStringArray = PackedStringArray()
	for project_id: StringName in draft.staged_project_ids.keys():
		if draft.has_staged_project(project_id):
			staged.append(String(project_id))
	staged.sort()
	if staged.is_empty():
		_draft_label.text = "Draft: none"
	else:
		_draft_label.text = "Draft Commands:\n- %s" % "\n- ".join(staged)


func _refresh_diagnostics(validation: PlanValidationResult) -> void:
	if _diagnostics_label == null:
		return
	if validation == null or validation.is_valid():
		_diagnostics_label.text = "Diagnostics: none"
		return
	_diagnostics_label.text = "Diagnostics:\n%s" % validation.format_diagnostics()


func _refresh_project_highlight() -> void:
	pass


func _on_project_toggled(pressed: bool, project_id: StringName) -> void:
	if _host != null:
		_host.set_project_staged(project_id, pressed)


func _on_model_name_changed(value: String) -> void:
	if _host == null or _host.get_draft() == null:
		return
	_host.get_draft().model_display_name = value


func _on_model_version_changed(value: String) -> void:
	if _host == null or _host.get_draft() == null:
		return
	_host.get_draft().model_version_label = value
