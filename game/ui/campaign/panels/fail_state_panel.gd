class_name CampaignFailStatePanel
extends Control

var _host: CampaignHost
var _reason_label: Label
var _confirm_button: Button
var _cancel_button: Button
var _menu_button: Button


func bind_host(host: CampaignHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func get_reason_text() -> String:
	if _reason_label == null:
		return ""
	return _reason_label.text


func get_confirm_button() -> Button:
	return _confirm_button


func get_cancel_button() -> Button:
	return _cancel_button


func get_menu_button() -> Button:
	return _menu_button


func present_session(state: GameState, session: CampaignSessionState) -> void:
	if session == null or _reason_label == null:
		return
	var cash_musd: int = CampaignCatalog.cash_balance_musd(state)
	var month_step: int = 0
	if state != null and state.calendar != null:
		month_step = state.calendar.current_month_step_index
	if session.failed:
		_reason_label.text = "%s\nMonth Step %d.\nCash %d MUSD." % [
			CampaignCatalog.fail_reason_text(session.fail_reason_id),
			month_step,
			cash_musd,
		]
		_confirm_button.visible = false
		_cancel_button.visible = false
		_menu_button.visible = true
		return
	if session.abandon_pending:
		_reason_label.text = "Abandon the campaign?\nMonth Step %d.\nCash %d MUSD." % [
			month_step,
			cash_musd,
		]
		_confirm_button.visible = true
		_cancel_button.visible = true
		_menu_button.visible = false
		return
	_reason_label.text = ""


func _build() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "FailStatePanel"
	panel.theme_type_variation = &"Modal"
	panel.custom_minimum_size = Vector2(560.0, 280.0)
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.name = "FailStateLayout"
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var title: Label = Label.new()
	title.text = "Campaign ended"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	_reason_label = Label.new()
	_reason_label.name = "ReasonLabel"
	_reason_label.add_theme_font_size_override("font_size", 18)
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_reason_label)
	_confirm_button = Button.new()
	_confirm_button.name = "ConfirmAbandonButton"
	_confirm_button.text = "Confirm abandon"
	_confirm_button.theme_type_variation = &"DestructiveAction"
	_confirm_button.custom_minimum_size = Vector2(0.0, 48.0)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	layout.add_child(_confirm_button)
	_cancel_button = Button.new()
	_cancel_button.name = "CancelAbandonButton"
	_cancel_button.text = "Cancel"
	_cancel_button.theme_type_variation = &"SecondaryAction"
	_cancel_button.custom_minimum_size = Vector2(0.0, 48.0)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	layout.add_child(_cancel_button)
	_menu_button = Button.new()
	_menu_button.name = "ReturnToMenuButton"
	_menu_button.text = "Return to Main Menu"
	_menu_button.theme_type_variation = &"SecondaryAction"
	_menu_button.custom_minimum_size = Vector2(0.0, 48.0)
	_menu_button.visible = false
	_menu_button.pressed.connect(_on_menu_pressed)
	layout.add_child(_menu_button)


func _on_confirm_pressed() -> void:
	if _host != null:
		_host.confirm_abandon()


func _on_cancel_pressed() -> void:
	if _host != null:
		_host.cancel_abandon()


func _on_menu_pressed() -> void:
	if _host != null:
		_host.return_to_main_menu()
