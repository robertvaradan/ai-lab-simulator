class_name CampaignTimelinePanel
extends Control

var _host: CampaignHost
var _list: VBoxContainer
var _detail: Label
var _attention_text: String = ""
var _report_text: String = ""
var _items: Array[CampaignTimelineItem] = []


func bind_host(host: CampaignHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func get_attention_text() -> String:
	return _attention_text


func get_report_text() -> String:
	return _report_text


func focus_first_attention() -> void:
	for item: CampaignTimelineItem in _items:
		if item.is_attention:
			_focus_item(item)
			return


func present_state(state: GameState, ui_session: CampaignUiSessionState) -> void:
	_attention_text = _format_attention(state)
	_report_text = _format_report(state)
	_rebuild_items(state, ui_session)


func _build() -> void:
	var panel: PanelContainer = PanelContainer.new()
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
	var layout: HBoxContainer = HBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	layout.add_child(left)
	var title: Label = Label.new()
	title.text = "Timeline"
	title.add_theme_font_size_override("font_size", 28)
	left.add_child(title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	_detail = Label.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 18)
	layout.add_child(_detail)


func _rebuild_items(state: GameState, ui_session: CampaignUiSessionState) -> void:
	_items.clear()
	if _list == null:
		return
	for child: Node in _list.get_children():
		child.queue_free()
	if state == null:
		return
	var draft: CampaignDraftPlanState = null
	if _host != null:
		draft = _host.get_draft()
	var attention_index: int = 0
	for event: AttentionEventState in state.attention_events:
		if event == null:
			continue
		var attention_item: CampaignTimelineItem = CampaignTimelineItem.new()
		attention_item.stable_id = event.stable_id
		attention_item.label = "%s (%s)" % [String(event.stable_id), String(event.event_type_id)]
		attention_item.detail = "Attention Event %s\nType %s" % [String(event.stable_id), String(event.event_type_id)]
		attention_item.is_attention = true
		attention_item.sort_key = attention_index
		attention_item.pinned = draft == null or not draft.has_acknowledged_attention(event.stable_id)
		_items.append(attention_item)
		attention_index += 1
	var notification_index: int = 0
	for notification: NotificationState in state.notifications:
		if notification == null:
			continue
		var notification_item: CampaignTimelineItem = CampaignTimelineItem.new()
		notification_item.stable_id = notification.stable_id
		notification_item.label = String(notification.stable_id)
		notification_item.detail = "Notification %s" % String(notification.stable_id)
		notification_item.is_attention = false
		notification_item.sort_key = notification_index
		notification_item.pinned = false
		_items.append(notification_item)
		notification_index += 1
	for report: QuarterlyReportState in state.quarterly_reports:
		if report == null:
			continue
		var report_item: CampaignTimelineItem = CampaignTimelineItem.new()
		report_item.stable_id = report.stable_id
		report_item.label = "Quarterly Report %s" % String(report.stable_id)
		report_item.detail = _format_report_item(report)
		report_item.is_attention = false
		report_item.sort_key = report.month_step_index
		report_item.pinned = false
		_items.append(report_item)
	var mapping: CampusVisualMapping = CampusVisualMapping.from_state(state)
	if mapping.competitor_release_visible:
		var competitor_item: CampaignTimelineItem = CampaignTimelineItem.new()
		competitor_item.stable_id = &"timeline.competitor.northstar_flagship"
		competitor_item.label = "Northstar Flagship release"
		competitor_item.detail = mapping.competitor_presentation_text
		competitor_item.is_attention = false
		competitor_item.sort_key = 0
		if state.calendar != null:
			competitor_item.sort_key = state.calendar.current_month_step_index
		competitor_item.pinned = false
		_items.append(competitor_item)
	_items.sort_custom(_sort_items)
	for item: CampaignTimelineItem in _items:
		var button: Button = Button.new()
		button.text = item.label
		button.custom_minimum_size = Vector2(0.0, 48.0)
		button.theme_type_variation = &"SecondaryAction"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if ui_session != null and ui_session.is_timeline_read(item.stable_id):
			button.modulate = Color(0.85, 0.85, 0.85, 1.0)
		button.pressed.connect(_on_item_pressed.bind(item))
		button.focus_entered.connect(_on_item_focused.bind(item))
		_list.add_child(button)


func _sort_items(a: CampaignTimelineItem, b: CampaignTimelineItem) -> bool:
	if a.pinned != b.pinned:
		return a.pinned
	if a.sort_key != b.sort_key:
		return a.sort_key > b.sort_key
	return String(a.stable_id) < String(b.stable_id)


func _on_item_pressed(item: CampaignTimelineItem) -> void:
	_focus_item(item)


func _on_item_focused(item: CampaignTimelineItem) -> void:
	_focus_item(item)


func _focus_item(item: CampaignTimelineItem) -> void:
	if item == null:
		return
	if _detail != null:
		_detail.text = item.detail
	if _host == null:
		return
	var ui_session: CampaignUiSessionState = _host.get_ui_session()
	if ui_session != null:
		ui_session.mark_timeline_read(item.stable_id)
	if item.is_attention:
		var draft: CampaignDraftPlanState = _host.get_draft()
		if draft != null:
			draft.acknowledge_attention(item.stable_id)
		_host.refresh_presentation()


func _format_attention(state: GameState) -> String:
	if state == null or state.attention_events.is_empty():
		return "None."
	var lines: PackedStringArray = PackedStringArray()
	for event: AttentionEventState in state.attention_events:
		if event == null:
			continue
		lines.append("%s (%s)" % [String(event.stable_id), String(event.event_type_id)])
	return "\n".join(lines)


func _format_report(state: GameState) -> String:
	if state == null or state.quarterly_reports.is_empty():
		return "None."
	var report: QuarterlyReportState = state.quarterly_reports[state.quarterly_reports.size() - 1]
	return _format_report_item(report)


func _format_report_item(report: QuarterlyReportState) -> String:
	if report == null:
		return "None."
	return "Kind %s\nMonth Step %d\nCash %d MUSD\nCompetitor %s" % [
		String(report.report_kind_id),
		report.month_step_index,
		report.cash_balance_musd,
		String(report.competitor_stage_id),
	]
