class_name CampaignHud
extends Control

var _host: CampaignHost
var _fail_state: FailStateView
var _skill_tree: SkillTreeView
var _data_center: DataCenterView
var _world_map: WorldMapView
var _government: GovernmentPlaceholderView
var _play_root: Control
var _status_label: Label
var _state_label: Label
var _lab_label: Label
var _attention_label: Label
var _report_label: Label
var _advance_button: Button
var _abandon_button: Button
var _build_lab_check: CheckBox
var _research_check: CheckBox
var _scale_check: CheckBox
var _coding_check: CheckBox
var _model_name_edit: LineEdit
var _model_version_edit: LineEdit
var _view_buttons: Dictionary[StringName, Button] = {}
var _last_status_text: String = ""
var _last_attention_text: String = ""
var _last_report_text: String = ""


func bind_host(host: CampaignHost) -> void:
	_host = host
	if _fail_state != null:
		_fail_state.bind_host(host)
	if _skill_tree != null:
		_skill_tree.bind_host(host)
	if _world_map != null:
		_world_map.bind_host(host)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	if _host != null:
		bind_host(_host)


func get_fail_state() -> FailStateView:
	return _fail_state


func get_skill_tree() -> SkillTreeView:
	return _skill_tree


func get_data_center() -> DataCenterView:
	return _data_center


func get_world_map() -> WorldMapView:
	return _world_map


func get_government() -> GovernmentPlaceholderView:
	return _government


func get_advance_button() -> Button:
	return _advance_button


func get_status_text() -> String:
	return _last_status_text


func get_attention_text() -> String:
	return _last_attention_text


func get_report_text() -> String:
	return _last_report_text


func get_state_text() -> String:
	if _state_label == null:
		return ""
	return _state_label.text


func get_lab_text() -> String:
	if _lab_label == null:
		return ""
	return _lab_label.text


func set_build_laboratory_selected(selected: bool) -> void:
	if _build_lab_check != null:
		_build_lab_check.button_pressed = selected


func set_research_selected(selected: bool) -> void:
	if _research_check != null:
		_research_check.button_pressed = selected


func set_scale_selected(selected: bool) -> void:
	if _scale_check != null:
		_scale_check.button_pressed = selected


func set_coding_agent_selected(selected: bool) -> void:
	if _coding_check != null:
		_coding_check.button_pressed = selected


func set_model_identity(display_name: String, version_label: String) -> void:
	if _model_name_edit != null:
		_model_name_edit.text = display_name
	if _model_version_edit != null:
		_model_version_edit.text = version_label


func build_plan(state: GameState) -> Plan:
	var plan: Plan = Plan.new()
	if state == null:
		return plan
	var command_index: int = 0
	if state.company != null:
		if (
			_build_lab_check != null
			and _build_lab_check.button_pressed
			and not state.company.projects.has(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID)
		):
			plan.commands.append(_build_lab_command(state, command_index))
			command_index += 1
		if _research_check != null and _research_check.button_pressed and not state.company.projects.has(CampaignCatalog.RESEARCH_PROJECT_ID):
			plan.commands.append(_research_command(state, command_index))
			command_index += 1
		if _scale_check != null and _scale_check.button_pressed and not state.company.projects.has(CampaignCatalog.SCALE_PROJECT_ID):
			plan.commands.append(_scale_command(state, command_index))
			command_index += 1
		if _coding_check != null and _coding_check.button_pressed and not state.company.projects.has(CampaignCatalog.CODING_AGENT_PROJECT_ID):
			plan.commands.append(_coding_agent_command(state, command_index))
	for event: AttentionEventState in state.attention_events:
		if event == null:
			continue
		var response: AttentionEventResponse = AttentionEventResponse.new()
		response.attention_event_id = event.stable_id
		response.response_type_id = AcknowledgmentAttentionEventResponseValidator.ACKNOWLEDGMENT_RESPONSE_TYPE_ID
		plan.attention_event_responses.append(response)
	return plan


func present_state(
		state: GameState,
		last_result: SimulationOperationResult,
		definition: MarketingScenarioDefinition,
		session: CampaignSessionState
	) -> void:
	if _state_label == null or session == null:
		return
	_sync_project_checks(session)
	_fail_state.present_session(state, session)
	_fail_state.visible = session.failed or session.abandon_pending
	_play_root.visible = not session.failed and not session.abandon_pending
	if state == null:
		_state_label.text = "Game State is missing."
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
	_state_label.text = "\n".join(state_lines)
	_lab_label.text = "Laboratory capacity level %d.\n%s.\nThe visible campus is the authored campus blockout." % [
		CampaignCatalog.laboratory_capacity_level(state),
		CampaignCatalog.laboratory_stage_label(state),
	]
	_last_attention_text = _format_attention(state)
	_attention_label.text = _last_attention_text
	_last_report_text = _format_report(state)
	_report_label.text = _last_report_text
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
	_status_label.text = _last_status_text
	if _advance_button != null:
		_advance_button.disabled = session.failed
	_skill_tree.present_state(state, session)
	_data_center.present_state(state, definition)
	_government.present_state(state)
	_apply_world_and_view(session)


func _build() -> void:
	_play_root = Control.new()
	_play_root.name = "PlayRoot"
	_play_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play_root.visible = false
	add_child(_play_root)
	_build_left_panel()
	_build_right_panel()
	_build_view_bar()
	_skill_tree = SkillTreeView.new()
	_skill_tree.name = "SkillTreeView"
	_skill_tree.visible = false
	_play_root.add_child(_skill_tree)
	_data_center = DataCenterView.new()
	_data_center.name = "DataCenterView"
	_data_center.visible = false
	_play_root.add_child(_data_center)
	_world_map = WorldMapView.new()
	_world_map.name = "WorldMapView"
	_world_map.visible = false
	_play_root.add_child(_world_map)
	_government = GovernmentPlaceholderView.new()
	_government.name = "GovernmentPlaceholderView"
	_government.visible = false
	_play_root.add_child(_government)
	_fail_state = FailStateView.new()
	_fail_state.name = "FailStateView"
	_fail_state.visible = false
	add_child(_fail_state)


func _build_left_panel() -> void:
	var panel: Panel = CampaignChrome.make_panel("ManagementPanel")
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 16.0
	panel.offset_top = 16.0
	panel.offset_right = CampaignChrome.PANEL_WIDTH_PX
	panel.offset_bottom = -72.0
	_play_root.add_child(panel)
	var outer: VBoxContainer = CampaignChrome.make_column("ManagementLayout")
	panel.add_child(outer)
	var title: Label = Label.new()
	title.text = "Company Campus"
	CampaignChrome.apply_heading(title)
	outer.add_child(title)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	CampaignChrome.apply_body(_status_label)
	outer.add_child(_status_label)
	_state_label = Label.new()
	_state_label.name = "StateLabel"
	CampaignChrome.apply_body(_state_label)
	outer.add_child(_state_label)
	_lab_label = Label.new()
	_lab_label.name = "LabLabel"
	CampaignChrome.apply_body(_lab_label)
	outer.add_child(_lab_label)
	var project_title: Label = Label.new()
	project_title.text = "Projects"
	CampaignChrome.apply_heading(project_title)
	outer.add_child(project_title)
	_build_lab_check = CheckBox.new()
	_build_lab_check.name = "BuildLaboratoryCheck"
	_build_lab_check.text = "Build Laboratory"
	_build_lab_check.toggled.connect(_on_build_lab_toggled)
	outer.add_child(_build_lab_check)
	_research_check = CheckBox.new()
	_research_check.name = "ResearchCheck"
	_research_check.text = "Research Frontier Model"
	_research_check.toggled.connect(_on_research_toggled)
	outer.add_child(_research_check)
	_model_name_edit = LineEdit.new()
	_model_name_edit.name = "ModelNameEdit"
	_model_name_edit.placeholder_text = "Model display name"
	_model_name_edit.text = "Aperture"
	outer.add_child(_model_name_edit)
	_model_version_edit = LineEdit.new()
	_model_version_edit.name = "ModelVersionEdit"
	_model_version_edit.placeholder_text = "Model version"
	_model_version_edit.text = "2.0"
	outer.add_child(_model_version_edit)
	_scale_check = CheckBox.new()
	_scale_check.name = "ScaleCheck"
	_scale_check.text = "Scale Burst Compute"
	_scale_check.toggled.connect(_on_scale_toggled)
	outer.add_child(_scale_check)
	_coding_check = CheckBox.new()
	_coding_check.name = "CodingAgentCheck"
	_coding_check.text = "Coding Agent Application"
	_coding_check.toggled.connect(_on_coding_toggled)
	outer.add_child(_coding_check)
	_advance_button = Button.new()
	_advance_button.name = "AdvanceButton"
	_advance_button.text = "Advance"
	_advance_button.pressed.connect(_on_advance_pressed)
	outer.add_child(_advance_button)
	_abandon_button = Button.new()
	_abandon_button.name = "AbandonButton"
	_abandon_button.text = "Abandon campaign"
	_abandon_button.pressed.connect(_on_abandon_pressed)
	outer.add_child(_abandon_button)


func _build_right_panel() -> void:
	var panel: Panel = CampaignChrome.make_panel("ReportPanel")
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_right = -16.0
	panel.offset_left = -CampaignChrome.PANEL_WIDTH_PX
	panel.offset_top = 16.0
	panel.offset_bottom = -72.0
	_play_root.add_child(panel)
	var layout: VBoxContainer = CampaignChrome.make_column("ReportLayout")
	panel.add_child(layout)
	var attention_title: Label = Label.new()
	attention_title.text = "Attention Events"
	CampaignChrome.apply_heading(attention_title)
	layout.add_child(attention_title)
	_attention_label = Label.new()
	_attention_label.name = "AttentionLabel"
	CampaignChrome.apply_body(_attention_label)
	layout.add_child(_attention_label)
	var report_title: Label = Label.new()
	report_title.text = "Quarterly Report"
	CampaignChrome.apply_heading(report_title)
	layout.add_child(report_title)
	_report_label = Label.new()
	_report_label.name = "ReportLabel"
	CampaignChrome.apply_body(_report_label)
	layout.add_child(_report_label)


func _build_view_bar() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.name = "ViewBar"
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 16.0
	bar.offset_right = -16.0
	bar.offset_top = -60.0
	bar.offset_bottom = -16.0
	bar.add_theme_constant_override("separation", 8)
	_play_root.add_child(bar)
	_add_world_button(bar, CampaignCatalog.WORLD_MAP, "World Map")
	_add_world_button(bar, CampaignCatalog.WORLD_HQ, "HQ")
	_add_world_button(bar, CampaignCatalog.WORLD_DATA_CENTER, "Data Center")
	_add_view_button(bar, CampaignCatalog.VIEW_SKILL_TREE, "Skill Tree")


func _add_view_button(bar: HBoxContainer, view_id: StringName, label: String) -> void:
	var button: Button = Button.new()
	button.name = "%sButton" % String(view_id).replace(".", "_")
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_view_pressed.bind(view_id))
	bar.add_child(button)
	_view_buttons[view_id] = button


func _add_world_button(bar: HBoxContainer, world_id: StringName, label: String) -> void:
	var button: Button = Button.new()
	button.name = "%sButton" % String(world_id).replace(".", "_")
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_world_pressed.bind(world_id))
	bar.add_child(button)
	_view_buttons[world_id] = button


func _apply_world_and_view(session: CampaignSessionState) -> void:
	var overlay: bool = session.active_view_id == CampaignCatalog.VIEW_SKILL_TREE
	_world_map.visible = session.active_world_id == CampaignCatalog.WORLD_MAP and not overlay
	_data_center.visible = session.active_world_id == CampaignCatalog.WORLD_DATA_CENTER and not overlay
	_government.visible = session.active_world_id == CampaignCatalog.WORLD_GOVERNMENT and not overlay
	_skill_tree.visible = session.active_view_id == CampaignCatalog.VIEW_SKILL_TREE


func _sync_project_checks(session: CampaignSessionState) -> void:
	if _build_lab_check != null:
		_build_lab_check.set_pressed_no_signal(
			session.has_staged_project(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID)
		)
	if _research_check != null:
		_research_check.set_pressed_no_signal(session.has_staged_project(CampaignCatalog.RESEARCH_PROJECT_ID))
	if _scale_check != null:
		_scale_check.set_pressed_no_signal(session.has_staged_project(CampaignCatalog.SCALE_PROJECT_ID))
	if _coding_check != null:
		_coding_check.set_pressed_no_signal(session.has_staged_project(CampaignCatalog.CODING_AGENT_PROJECT_ID))


func _on_build_lab_toggled(pressed: bool) -> void:
	if _host != null:
		_host.set_project_staged(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID, pressed)


func _on_research_toggled(pressed: bool) -> void:
	if _host != null:
		_host.set_project_staged(CampaignCatalog.RESEARCH_PROJECT_ID, pressed)


func _on_scale_toggled(pressed: bool) -> void:
	if _host != null:
		_host.set_project_staged(CampaignCatalog.SCALE_PROJECT_ID, pressed)


func _on_coding_toggled(pressed: bool) -> void:
	if _host != null:
		_host.set_project_staged(CampaignCatalog.CODING_AGENT_PROJECT_ID, pressed)


func _on_view_pressed(view_id: StringName) -> void:
	if _host != null:
		_host.set_active_view(view_id)


func _on_world_pressed(world_id: StringName) -> void:
	if _host != null:
		_host.set_active_world(world_id)


func _on_advance_pressed() -> void:
	if _host != null:
		_host.advance_from_hud()


func _on_abandon_pressed() -> void:
	if _host != null:
		_host.request_abandon()


func _build_lab_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CampaignCatalog.BUILD_LABORATORY_PROJECT_ID
	command.payload = payload
	return command


func _research_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CampaignCatalog.RESEARCH_PROJECT_ID
	payload[&"model_display_name"] = _model_name_edit.text if _model_name_edit != null else "Aperture"
	payload[&"model_version_label"] = _model_version_edit.text if _model_version_edit != null else "2.0"
	payload[&"release_strategy_id"] = &"release_strategy.commercial_api"
	command.payload = payload
	return command


func _scale_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CampaignCatalog.SCALE_PROJECT_ID
	command.payload = payload
	return command


func _coding_agent_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CampaignCatalog.CODING_AGENT_PROJECT_ID
	payload[&"supporting_model_id"] = CampaignCatalog.STARTING_MODEL_ID
	command.payload = payload
	return command


func _make_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	return command


func _format_attention(state: GameState) -> String:
	if state.attention_events.is_empty():
		return "None."
	var lines: PackedStringArray = PackedStringArray()
	for event: AttentionEventState in state.attention_events:
		if event == null:
			continue
		lines.append("%s (%s)" % [String(event.stable_id), String(event.event_type_id)])
	return "\n".join(lines)


func _format_report(state: GameState) -> String:
	if state.quarterly_reports.is_empty():
		return "None."
	var report: QuarterlyReportState = state.quarterly_reports[state.quarterly_reports.size() - 1]
	if report == null:
		return "None."
	return "Kind %s\nMonth Step %d\nCash %d MUSD\nCompetitor %s" % [
		String(report.report_kind_id),
		report.month_step_index,
		report.cash_balance_musd,
		String(report.competitor_stage_id),
	]
