class_name MarketingPlayOverlay
extends Control

const PANEL_WIDTH_PX: float = 440.0

var _host: MarketingPlayHost
var _status_label: Label
var _state_label: Label
var _attention_label: Label
var _report_label: Label
var _advance_button: Button
var _last_attention_text: String = ""
var _last_report_text: String = ""


func bind_host(host: MarketingPlayHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_panel()


func build_plan(state: GameState) -> Plan:
	var plan: Plan = Plan.new()
	if state == null:
		return plan
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
	var layout: VBoxContainer = VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 16.0
	layout.offset_top = 16.0
	layout.offset_right = -16.0
	layout.offset_bottom = -16.0
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
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
	layout.add_child(_advance_button)


func _on_advance_pressed() -> void:
	if _host == null:
		return
	_host.advance_from_overlay()


func _format_attention(state: GameState) -> String:
	if state.attention_events.is_empty():
		return "None."
	var lines: PackedStringArray = PackedStringArray()
	for event: AttentionEventState in state.attention_events:
		if event == null:
			continue
		lines.append("%s (%s)" % [String(event.stable_id), String(event.event_type_id)])
	return "\n".join(lines)


func _format_report(state: GameState, _definition: MarketingScenarioDefinition) -> String:
	if state.quarterly_reports.is_empty():
		return "None."
	var report: QuarterlyReportState = state.quarterly_reports[state.quarterly_reports.size() - 1]
	if report == null:
		return "None."
	return "Kind %s\nMonth Step %d\nCash %d MUSD" % [
		String(report.report_kind_id),
		report.month_step_index,
		report.cash_balance_musd,
	]
