class_name TechTreeView
extends Control

var _host: CampaignHost
var _layout: VBoxContainer
var _unlock_buttons: Dictionary[StringName, Button] = {}


func bind_host(host: CampaignHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func get_unlock_button(tech_id: StringName) -> Button:
	if not _unlock_buttons.has(tech_id):
		return null
	return _unlock_buttons[tech_id]


func present_state(state: GameState, session: CampaignSessionState) -> void:
	if _layout == null or session == null:
		return
	for tech: BootstrapUnlockDefinition in CampaignCatalog.tech_definitions():
		if not _unlock_buttons.has(tech.stable_id):
			continue
		var button: Button = _unlock_buttons[tech.stable_id]
		if button == null:
			continue
		var unlocked: bool = session.has_tech(tech.stable_id)
		var available: bool = _host != null and _host.can_unlock_tech(tech.stable_id)
		if unlocked:
			button.text = "%s  Unlocked" % tech.display_name
			button.disabled = true
		else:
			button.text = "%s  %d MUSD" % [tech.display_name, tech.cost_musd]
			button.disabled = not available
		button.tooltip_text = _tech_reason(tech, state, session, unlocked, available)


func _build() -> void:
	var panel: Panel = CampaignChrome.make_panel("TechTreePanel")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -380.0
	panel.offset_top = -280.0
	panel.offset_right = 380.0
	panel.offset_bottom = 280.0
	add_child(panel)
	_layout = CampaignChrome.make_column("TechTreeLayout")
	panel.add_child(_layout)
	var title: Label = Label.new()
	title.text = "Tech tree"
	CampaignChrome.apply_heading(title)
	_layout.add_child(title)
	var summary: Label = Label.new()
	summary.text = "Proof items. Cash must meet the cost. The unlock does not spend Cash. A later Command must own the spend."
	CampaignChrome.apply_body(summary)
	_layout.add_child(summary)
	for tech: BootstrapUnlockDefinition in CampaignCatalog.tech_definitions():
		var button: Button = Button.new()
		button.name = "%sButton" % String(tech.stable_id).replace(".", "_")
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_unlock_pressed.bind(tech.stable_id))
		_layout.add_child(button)
		_unlock_buttons[tech.stable_id] = button


func _on_unlock_pressed(tech_id: StringName) -> void:
	if _host == null:
		return
	_host.unlock_tech(tech_id)


func _tech_reason(
		tech: BootstrapUnlockDefinition,
		state: GameState,
		session: CampaignSessionState,
		unlocked: bool,
		available: bool
	) -> String:
	if unlocked or available:
		return tech.summary
	if state == null:
		return "Game State is missing."
	if CampaignCatalog.cash_balance_musd(state) < tech.cost_musd:
		return "Cash is below %d MUSD." % tech.cost_musd
	for prerequisite_id: StringName in tech.prerequisite_ids:
		if not session.has_tech(prerequisite_id):
			return "This item requires %s." % String(prerequisite_id)
	return tech.summary
