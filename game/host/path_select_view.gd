class_name PathSelectView
extends Control

var _host: CampaignHost
var _selected_path_id: StringName = &""
var _status_label: Label
var _continue_button: Button
var _path_buttons: Dictionary[StringName, Button] = {}


func bind_host(host: CampaignHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func get_continue_button() -> Button:
	return _continue_button


func get_selected_path_id() -> StringName:
	return _selected_path_id


func get_path_button(path_id: StringName) -> Button:
	if not _path_buttons.has(path_id):
		return null
	return _path_buttons[path_id]


func present_state(state: GameState, definition: MarketingScenarioDefinition) -> void:
	if _status_label == null:
		return
	var cash_musd: int = CampaignCatalog.cash_balance_musd(state)
	var teams: int = 0
	if state != null and state.company != null:
		teams = state.company.project_team_count
	_status_label.text = "The Marketing Scenario is loaded. Cash %d MUSD. Project teams %d." % [
		cash_musd,
		teams,
	]
	for path: BootstrapPathDefinition in CampaignCatalog.opening_paths():
		if not _path_buttons.has(path.stable_id):
			continue
		var button: Button = _path_buttons[path.stable_id]
		if button == null:
			continue
		var project: ProjectDefinition = CampaignCatalog.find_project(definition, path.project_id)
		var cost_text: String = "Cost unknown"
		var duration_text: String = ""
		if project != null:
			cost_text = "%d MUSD" % project.start_cost_musd
			duration_text = "%d Month Steps" % project.duration_month_steps
		button.text = "%s\n%s\n%s. %s." % [path.display_name, path.summary, cost_text, duration_text]


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	var dim_color: Color = CampaignChrome.VOID_BASE
	dim_color.a = 0.92
	dim.color = dim_color
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: Panel = CampaignChrome.make_panel("PathSelectPanel")
	panel.custom_minimum_size = Vector2(980.0, 620.0)
	center.add_child(panel)
	var layout: VBoxContainer = CampaignChrome.make_column("PathSelectLayout")
	panel.add_child(layout)
	var title: Label = Label.new()
	title.text = "Choose the opening path"
	CampaignChrome.apply_title(title)
	layout.add_child(title)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	CampaignChrome.apply_body(_status_label)
	layout.add_child(_status_label)
	var cards: HBoxContainer = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(cards)
	for path: BootstrapPathDefinition in CampaignCatalog.opening_paths():
		var button: Button = Button.new()
		button.name = "%sButton" % String(path.stable_id).replace(".", "_")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_path_pressed.bind(path.stable_id))
		cards.add_child(button)
		_path_buttons[path.stable_id] = button
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Continue"
	_continue_button.disabled = true
	_continue_button.custom_minimum_size = Vector2(0.0, 44.0)
	_continue_button.pressed.connect(_on_continue_pressed)
	layout.add_child(_continue_button)


func _on_path_pressed(path_id: StringName) -> void:
	_selected_path_id = path_id
	if _continue_button != null:
		_continue_button.disabled = false


func _on_continue_pressed() -> void:
	if _host == null or _selected_path_id == &"":
		return
	_host.select_opening_path(_selected_path_id)
