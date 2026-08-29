class_name DecisionHostView
extends Control

const TITLE_FONT_SIZE: int = 32
const HEADER_FONT_SIZE: int = 22
const SECTION_FONT_SIZE: int = 20
const BODY_FONT_SIZE: int = 18
const LIST_FONT_SIZE: int = 16
const TEXT_COLOR: Color = Color(0.96, 0.96, 0.94, 1.0)
const MUTED_TEXT_COLOR: Color = Color(0.78, 0.80, 0.82, 1.0)
const PANEL_COLOR: Color = Color(0.16, 0.17, 0.20, 1.0)
const BACKGROUND_COLOR: Color = Color(0.09, 0.10, 0.12, 1.0)

var _host: DecisionHost
var _project_layout: VBoxContainer
var _status_label: Label
var _state_label: Label
var _forecast_label: Label
var _attention_label: Label
var _report_label: Label
var _diagnostics_label: Label
var _ledger_label: Label
var _projects_label: Label
var _rules_label: Label
var _rules_list: ItemList
var _ledger_list: ItemList
var _remaining_list: ItemList
var _advance_button: Button
var _project_checks: Dictionary[StringName, CheckBox] = {}
var _model_name_edits: Dictionary[StringName, LineEdit] = {}
var _model_version_edits: Dictionary[StringName, LineEdit] = {}
var _last_forecast_text: String = ""
var _last_attention_text: String = ""
var _last_report_text: String = ""
var _last_inspect_text: String = ""


func bind_host(host: DecisionHost) -> void:
	_host = host
	_rebuild_project_controls()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_theme()
	_build_chrome()


func set_project_selected(project_id: StringName, selected: bool) -> void:
	if not _project_checks.has(project_id):
		return
	_project_checks[project_id].button_pressed = selected


func set_model_identity(project_id: StringName, display_name: String, version_label: String) -> void:
	if _model_name_edits.has(project_id):
		_model_name_edits[project_id].text = display_name
	if _model_version_edits.has(project_id):
		_model_version_edits[project_id].text = version_label


func get_presented_project_ids() -> Array[StringName]:
	var project_ids: Array[StringName] = []
	project_ids.assign(_project_checks.keys())
	project_ids.sort()
	return project_ids


func get_status_text() -> String:
	if _status_label == null:
		return ""
	return _status_label.text


func get_forecast_text() -> String:
	return _last_forecast_text


func get_attention_text() -> String:
	return _last_attention_text


func get_report_text() -> String:
	return _last_report_text


func get_inspect_text() -> String:
	return _last_inspect_text


func get_diagnostics_text() -> String:
	if _diagnostics_label == null:
		return ""
	return _diagnostics_label.text


func build_plan(state: GameState) -> Plan:
	var plan: Plan = Plan.new()
	if state == null or _host == null or _host.get_core() == null:
		return plan
	var registry: SimulationContentRegistry = _host.get_core().get_content_registry()
	var command_index: int = 0
	for project_id: StringName in _presented_project_ids(registry):
		if not _project_checks.has(project_id):
			continue
		if not _project_checks[project_id].button_pressed:
			continue
		if state.company != null and state.company.projects.has(project_id):
			continue
		var definition: ProjectDefinition = registry.get_project_definition(project_id)
		if definition == null:
			continue
		plan.commands.append(_project_start_command(state, command_index, definition))
		command_index += 1
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
		last_advance_traces: Array[SimulationTrace]
	) -> void:
	if _state_label == null:
		return
	if state == null:
		_state_label.text = "Game State is missing."
		return
	var cash_balance_musd: int = 0
	if state.cash_ledger != null:
		cash_balance_musd = state.cash_ledger.calculate_balance_musd()
	_state_label.text = "Month Step %d    Quarter %d    Cash %d MUSD" % [
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
	_diagnostics_label.text = _format_diagnostics(last_result)
	var ledger_text: String = _format_ledger(state)
	var project_text: String = _format_project_remaining(state)
	var rules_text: String = _format_rule_statuses(last_advance_traces)
	_ledger_label.text = ledger_text
	_projects_label.text = project_text
	_rules_label.text = rules_text
	_fill_list(_rules_list, rules_text)
	_fill_list(_ledger_list, ledger_text)
	_fill_list(_remaining_list, project_text)
	_last_inspect_text = "%s\n%s\n%s" % [rules_text, ledger_text, project_text]
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


func _build_chrome() -> void:
	var background: ColorRect = ColorRect.new()
	background.name = "Background"
	background.color = BACKGROUND_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var root_layout: VBoxContainer = VBoxContainer.new()
	root_layout.add_theme_constant_override("separation", 16)
	margin.add_child(root_layout)
	var header: VBoxContainer = VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	root_layout.add_child(header)
	var title: Label = Label.new()
	title.text = "Decision Host"
	_style_label(title, TITLE_FONT_SIZE, TEXT_COLOR)
	header.add_child(title)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_style_label(_status_label, HEADER_FONT_SIZE, TEXT_COLOR)
	header.add_child(_status_label)
	_state_label = Label.new()
	_state_label.name = "StateLabel"
	_style_label(_state_label, HEADER_FONT_SIZE, MUTED_TEXT_COLOR)
	header.add_child(_state_label)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	root_layout.add_child(columns)
	var plan_column: VBoxContainer = _make_column("PlanColumn")
	plan_column.add_child(_section_title("Projects"))
	_project_layout = VBoxContainer.new()
	_project_layout.name = "ProjectLayout"
	_project_layout.add_theme_constant_override("separation", 12)
	plan_column.add_child(_project_layout)
	_advance_button = Button.new()
	_advance_button.name = "AdvanceButton"
	_advance_button.text = "Advance"
	_advance_button.custom_minimum_size = Vector2(0.0, 52.0)
	_advance_button.pressed.connect(_on_advance_pressed)
	plan_column.add_child(_advance_button)
	columns.add_child(_wrap_column(plan_column))
	var result_column: VBoxContainer = _make_column("ResultColumn")
	result_column.add_child(_section_title("Projected Evaluation Ranges"))
	_forecast_label = _make_body_label("ForecastLabel")
	result_column.add_child(_forecast_label)
	result_column.add_child(_section_title("Attention Events"))
	_attention_label = _make_body_label("AttentionLabel")
	result_column.add_child(_attention_label)
	result_column.add_child(_section_title("Quarterly Report"))
	_report_label = _make_body_label("ReportLabel")
	result_column.add_child(_report_label)
	result_column.add_child(_section_title("Advance Diagnostics"))
	_diagnostics_label = _make_body_label("DiagnosticsLabel")
	result_column.add_child(_diagnostics_label)
	columns.add_child(_wrap_column(result_column))
	var inspect_column: VBoxContainer = _make_column("InspectColumn")
	inspect_column.add_child(_section_title("Rule Evaluations"))
	_rules_label = _make_body_label("RulesLabel")
	_rules_label.visible = false
	inspect_column.add_child(_rules_label)
	_rules_list = _make_item_list("RulesList")
	inspect_column.add_child(_rules_list)
	inspect_column.add_child(_section_title("Cash Ledger"))
	_ledger_label = _make_body_label("LedgerLabel")
	_ledger_label.visible = false
	inspect_column.add_child(_ledger_label)
	_ledger_list = _make_item_list("LedgerList")
	inspect_column.add_child(_ledger_list)
	inspect_column.add_child(_section_title("Project Remaining Duration"))
	_projects_label = _make_body_label("ProjectRemainingLabel")
	_projects_label.visible = false
	inspect_column.add_child(_projects_label)
	_remaining_list = _make_item_list("RemainingList")
	inspect_column.add_child(_remaining_list)
	columns.add_child(_wrap_column(inspect_column))


func _rebuild_project_controls() -> void:
	if _project_layout == null:
		return
	for child: Node in _project_layout.get_children():
		child.queue_free()
	_project_checks.clear()
	_model_name_edits.clear()
	_model_version_edits.clear()
	if _host == null or _host.get_core() == null:
		return
	var registry: SimulationContentRegistry = _host.get_core().get_content_registry()
	for project_id: StringName in _presented_project_ids(registry):
		var definition: ProjectDefinition = registry.get_project_definition(project_id)
		if definition == null:
			continue
		var row: VBoxContainer = VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var check: CheckBox = CheckBox.new()
		check.name = "%sCheck" % String(project_id)
		check.text = _project_display_name(project_id)
		row.add_child(check)
		_project_checks[project_id] = check
		if definition.required_payload_keys.has(DecisionHostCatalog.VISIBLE_MODEL_DISPLAY_NAME):
			var name_edit: LineEdit = LineEdit.new()
			name_edit.name = "%sModelName" % String(project_id)
			name_edit.placeholder_text = "Model display name"
			name_edit.text = DecisionHostCatalog.DEFAULT_MODEL_DISPLAY_NAME
			row.add_child(name_edit)
			_model_name_edits[project_id] = name_edit
		if definition.required_payload_keys.has(DecisionHostCatalog.VISIBLE_MODEL_VERSION_LABEL):
			var version_edit: LineEdit = LineEdit.new()
			version_edit.name = "%sModelVersion" % String(project_id)
			version_edit.placeholder_text = "Model version"
			version_edit.text = DecisionHostCatalog.DEFAULT_MODEL_VERSION_LABEL
			row.add_child(version_edit)
			_model_version_edits[project_id] = version_edit
		_project_layout.add_child(row)


func _presented_project_ids(registry: SimulationContentRegistry) -> Array[StringName]:
	var presented: Array[StringName] = []
	var seen: Dictionary[StringName, bool] = {}
	if _host != null and _host.get_definition() != null:
		for project_id: StringName in _host.get_definition().available_project_ids:
			if not registry.has_project_definition(project_id):
				continue
			presented.append(project_id)
			seen[project_id] = true
	for project_id: StringName in registry.get_project_ids():
		if seen.has(project_id):
			continue
		presented.append(project_id)
	return presented


func _project_start_command(
		state: GameState,
		command_index: int,
		definition: ProjectDefinition
	) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = DecisionHostCatalog.PRESENTED_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	for payload_key: StringName in definition.required_payload_keys:
		payload[payload_key] = _payload_value(definition.stable_id, payload_key)
	command.payload = payload
	return command


func _payload_value(project_id: StringName, payload_key: StringName) -> Variant:
	if payload_key == DecisionHostCatalog.VISIBLE_PROJECT_ID:
		return project_id
	if payload_key == DecisionHostCatalog.VISIBLE_MODEL_DISPLAY_NAME:
		if _model_name_edits.has(project_id):
			return _model_name_edits[project_id].text
		return DecisionHostCatalog.DEFAULT_MODEL_DISPLAY_NAME
	if payload_key == DecisionHostCatalog.VISIBLE_MODEL_VERSION_LABEL:
		if _model_version_edits.has(project_id):
			return _model_version_edits[project_id].text
		return DecisionHostCatalog.DEFAULT_MODEL_VERSION_LABEL
	if payload_key == DecisionHostCatalog.HIDDEN_RELEASE_STRATEGY_KEY:
		return DecisionHostCatalog.HIDDEN_RELEASE_STRATEGY_VALUE
	if payload_key == DecisionHostCatalog.HIDDEN_SUPPORTING_MODEL_KEY:
		return DecisionHostCatalog.HIDDEN_SUPPORTING_MODEL_VALUE
	return &""


func _on_advance_pressed() -> void:
	if _host == null:
		return
	_host.advance_from_view()


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


func _format_diagnostics(last_result: SimulationOperationResult) -> String:
	if last_result == null:
		return "None."
	if last_result.diagnostics.is_empty():
		return "None."
	var lines: PackedStringArray = PackedStringArray()
	for diagnostic: SimulationDiagnostic in last_result.diagnostics:
		if diagnostic == null:
			continue
		lines.append("%s %s" % [String(diagnostic.code), diagnostic.message])
	if lines.is_empty():
		return "None."
	return "\n".join(lines)


func _format_ledger(state: GameState) -> String:
	if state.cash_ledger == null or state.cash_ledger.transactions.is_empty():
		return "None."
	var lines: PackedStringArray = PackedStringArray()
	for transaction: LedgerTransactionState in state.cash_ledger.transactions:
		if transaction == null:
			continue
		lines.append(
			"Month %d    %s    %d MUSD    %s"
			% [
				transaction.month_step_index,
				_short_id(transaction.category_id),
				transaction.amount_musd,
				String(transaction.stable_id),
			]
		)
	if lines.is_empty():
		return "None."
	return "\n".join(lines)


func _format_project_remaining(state: GameState) -> String:
	if state.company == null or state.company.projects.is_empty():
		return "None."
	var project_ids: Array[StringName] = []
	project_ids.assign(state.company.projects.keys())
	project_ids.sort()
	var lines: PackedStringArray = PackedStringArray()
	for project_id: StringName in project_ids:
		var project: ProjectState = state.company.projects[project_id]
		if project == null:
			continue
		lines.append(
			"%s    remaining_month_steps=%d"
			% [_project_display_name(project_id), project.remaining_month_steps]
		)
	if lines.is_empty():
		return "None."
	return "\n".join(lines)


func _format_rule_statuses(traces: Array[SimulationTrace]) -> String:
	if traces.is_empty():
		return "None."
	var lines: PackedStringArray = PackedStringArray()
	for trace: SimulationTrace in traces:
		if trace == null:
			continue
		for record: SimulationTraceRecord in trace.get_records():
			if not record is RuleEvaluationTraceRecord:
				continue
			var rule_record: RuleEvaluationTraceRecord = record
			lines.append(
				"%s    %s" % [String(rule_record.rule_id), _rule_status_text(rule_record.status)]
			)
	if lines.is_empty():
		return "None."
	return "\n".join(lines)


func _rule_status_text(status: SimulationRuleEvaluation.Status) -> String:
	if status == SimulationRuleEvaluation.Status.FIRED:
		return "fired"
	if status == SimulationRuleEvaluation.Status.DID_NOT_FIRE:
		return "did_not_fire"
	return "failed"


func _apply_theme() -> void:
	var host_theme: Theme = Theme.new()
	host_theme.set_font_size("font_size", "Label", BODY_FONT_SIZE)
	host_theme.set_font_size("font_size", "CheckBox", BODY_FONT_SIZE)
	host_theme.set_font_size("font_size", "Button", HEADER_FONT_SIZE)
	host_theme.set_font_size("font_size", "LineEdit", BODY_FONT_SIZE)
	host_theme.set_font_size("font_size", "ItemList", LIST_FONT_SIZE)
	host_theme.set_color("font_color", "Label", TEXT_COLOR)
	host_theme.set_color("font_color", "CheckBox", TEXT_COLOR)
	host_theme.set_color("font_hover_color", "CheckBox", Color(1.0, 1.0, 1.0, 1.0))
	host_theme.set_color("font_pressed_color", "CheckBox", TEXT_COLOR)
	host_theme.set_color("font_color", "ItemList", TEXT_COLOR)
	theme = host_theme


func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _make_column(column_name: String) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = column_name
	column.add_theme_constant_override("separation", 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return column


func _wrap_column(column: VBoxContainer) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.content_margin_left = 16.0
	style.content_margin_top = 16.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", style)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	panel.add_child(scroll)
	return panel


func _make_item_list(list_name: String) -> ItemList:
	var list: ItemList = ItemList.new()
	list.name = list_name
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(0.0, 160.0)
	list.auto_height = false
	list.select_mode = ItemList.SELECT_SINGLE
	return list


func _fill_list(list: ItemList, text: String) -> void:
	if list == null:
		return
	list.clear()
	if text.is_empty():
		return
	for line: String in text.split("\n"):
		list.add_item(line, null, false)


func _project_display_name(project_id: StringName) -> String:
	var text: String = String(project_id)
	if text.begins_with("project."):
		text = text.substr(8)
	return text.replace("_", " ").replace(".", " · ")


func _short_id(identifier: StringName) -> String:
	var text: String = String(identifier)
	var last_dot: int = text.rfind(".")
	if last_dot < 0:
		return text
	return text.substr(last_dot + 1).replace("_", " ")


func _section_title(text: String) -> Label:
	var title: Label = Label.new()
	title.text = text
	_style_label(title, SECTION_FONT_SIZE, TEXT_COLOR)
	return title


func _make_body_label(node_name: String) -> Label:
	var body: Label = Label.new()
	body.name = node_name
	_style_label(body, BODY_FONT_SIZE, MUTED_TEXT_COLOR)
	return body
