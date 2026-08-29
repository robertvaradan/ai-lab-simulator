class_name MarketingPlayOverlay
extends Control

const PANEL_WIDTH_PX: float = 460.0
const RESEARCH_ID: StringName = &"project.research.frontier_model"
const SCALE_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_PROJECT_ID: StringName = &"project.application.coding_agent"
const STARTING_MODEL_ID: StringName = &"model.player.starting"

var _host: MarketingPlayHost
var _status_label: Label
var _state_label: Label
var _forecast_label: Label
var _attention_label: Label
var _report_label: Label
var _advance_button: Button
var _research_check: CheckBox
var _scale_check: CheckBox
var _coding_check: CheckBox
var _model_name_edit: LineEdit
var _model_version_edit: LineEdit
var _last_attention_text: String = ""
var _last_report_text: String = ""
var _last_forecast_text: String = ""


func bind_host(host: MarketingPlayHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_panel()


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
		if _research_check != null and _research_check.button_pressed and not state.company.projects.has(RESEARCH_ID):
			plan.commands.append(_research_command(state, command_index))
			command_index += 1
		if _scale_check != null and _scale_check.button_pressed and not state.company.projects.has(SCALE_ID):
			plan.commands.append(_scale_command(state, command_index))
			command_index += 1
		if _coding_check != null and _coding_check.button_pressed and not state.company.projects.has(CODING_AGENT_PROJECT_ID):
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
		definition: MarketingScenarioDefinition
	) -> void:
	if _state_label == null:
		return
	if state == null:
		_state_label.text = "Game State is missing."
		return
	var cash_balance_musd: int = 0
	if state.cash_ledger != null:
		cash_balance_musd = state.cash_ledger.calculate_balance_musd()
	_state_label.text = "Month Step %d\nQuarter %d\nCash %d MUSD" % [
		state.calendar.current_month_step_index,
		state.calendar.current_quarter_index,
		cash_balance_musd,
	]
	_last_forecast_text = _format_forecasts(state)
	_forecast_label.text = _last_forecast_text
	_last_attention_text = _format_attention(state)
	_attention_label.text = _last_attention_text
	_last_report_text = _format_report(state, definition)
	_report_label.text = _last_report_text
	if last_result == null:
		_status_label.text = "Ready."
	elif last_result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED:
		_status_label.text = "Attention is required."
	elif last_result.outcome == SimulationOperationOutcome.Type.COMPLETED:
		_status_label.text = "Advance completed."
	elif last_result.outcome == SimulationOperationOutcome.Type.REJECTED:
		_status_label.text = "Advance rejected."
	else:
		_status_label.text = "Advance faulted."
	if _advance_button != null:
		_advance_button.disabled = false


func get_attention_text() -> String:
	return _last_attention_text


func get_report_text() -> String:
	return _last_report_text


func get_forecast_text() -> String:
	return _last_forecast_text


func get_status_text() -> String:
	if _status_label == null:
		return ""
	return _status_label.text


func _build_panel() -> void:
	var panel: Panel = Panel.new()
	panel.name = "ManagementPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 16.0
	panel.offset_top = 16.0
	panel.offset_right = PANEL_WIDTH_PX
	panel.offset_bottom = -16.0
	add_child(panel)
	var outer: VBoxContainer = VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 16.0
	outer.offset_top = 16.0
	outer.offset_right = -16.0
	outer.offset_bottom = -16.0
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	scroll.add_child(layout)
	var title: Label = Label.new()
	title.text = "Company Campus"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(title)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status_label)
	_state_label = Label.new()
	_state_label.name = "StateLabel"
	_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_state_label)
	var project_title: Label = Label.new()
	project_title.text = "Projects"
	layout.add_child(project_title)
	_research_check = CheckBox.new()
	_research_check.name = "ResearchCheck"
	_research_check.text = "Research Frontier Model"
	layout.add_child(_research_check)
	_model_name_edit = LineEdit.new()
	_model_name_edit.name = "ModelNameEdit"
	_model_name_edit.placeholder_text = "Model display name"
	_model_name_edit.text = "Aperture"
	layout.add_child(_model_name_edit)
	_model_version_edit = LineEdit.new()
	_model_version_edit.name = "ModelVersionEdit"
	_model_version_edit.placeholder_text = "Model version"
	_model_version_edit.text = "2.0"
	layout.add_child(_model_version_edit)
	_scale_check = CheckBox.new()
	_scale_check.name = "ScaleCheck"
	_scale_check.text = "Scale Burst Compute"
	layout.add_child(_scale_check)
	_coding_check = CheckBox.new()
	_coding_check.name = "CodingAgentCheck"
	_coding_check.text = "Coding Agent Application"
	layout.add_child(_coding_check)
	var forecast_title: Label = Label.new()
	forecast_title.text = "Projected Evaluation Ranges"
	layout.add_child(forecast_title)
	_forecast_label = Label.new()
	_forecast_label.name = "ForecastLabel"
	_forecast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_forecast_label)
	var attention_title: Label = Label.new()
	attention_title.text = "Attention Events"
	layout.add_child(attention_title)
	_attention_label = Label.new()
	_attention_label.name = "AttentionLabel"
	_attention_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_attention_label)
	var report_title: Label = Label.new()
	report_title.text = "Quarterly Report"
	layout.add_child(report_title)
	_report_label = Label.new()
	_report_label.name = "ReportLabel"
	_report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_report_label)
	_advance_button = Button.new()
	_advance_button.name = "AdvanceButton"
	_advance_button.text = "Advance"
	_advance_button.pressed.connect(_on_advance_pressed)
	outer.add_child(_advance_button)


func _on_advance_pressed() -> void:
	if _host == null:
		return
	_host.advance_from_overlay()


func _research_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = RESEARCH_ID
	payload[&"model_display_name"] = _model_name_edit.text if _model_name_edit != null else "Aperture"
	payload[&"model_version_label"] = _model_version_edit.text if _model_version_edit != null else "2.0"
	payload[&"release_strategy_id"] = &"release_strategy.commercial_api"
	command.payload = payload
	return command


func _scale_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = SCALE_ID
	command.payload = payload
	return command


func _coding_agent_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CODING_AGENT_PROJECT_ID
	payload[&"supporting_model_id"] = STARTING_MODEL_ID
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


func _format_forecasts(state: GameState) -> String:
	if state.quarterly_reports.is_empty():
		return "None."
	var report: QuarterlyReportState = state.quarterly_reports[state.quarterly_reports.size() - 1]
	if report == null or report.competitor_forecasts.is_empty():
		return "None."
	var forecast: CompetitorForecast = report.competitor_forecasts[0]
	if forecast == null:
		return "None."
	return "Northstar Q%d\nCoding %d-%d\nReasoning %d-%d\nEfficiency %d-%d" % [
		forecast.known_release_quarter_index,
		forecast.projected_coding_evaluation_min,
		forecast.projected_coding_evaluation_max,
		forecast.projected_reasoning_evaluation_min,
		forecast.projected_reasoning_evaluation_max,
		forecast.projected_efficiency_evaluation_min,
		forecast.projected_efficiency_evaluation_max,
	]


func _format_report(state: GameState, _definition: MarketingScenarioDefinition) -> String:
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
