class_name SkillTreeView
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


func get_unlock_button(skill_id: StringName) -> Button:
	if not _unlock_buttons.has(skill_id):
		return null
	return _unlock_buttons[skill_id]


func present_state(state: GameState, session: CampaignSessionState) -> void:
	if _layout == null or session == null:
		return
	for skill: BootstrapUnlockDefinition in CampaignCatalog.skill_definitions():
		if not _unlock_buttons.has(skill.stable_id):
			continue
		var button: Button = _unlock_buttons[skill.stable_id]
		if button == null:
			continue
		var unlocked: bool = session.has_skill(skill.stable_id)
		var available: bool = _host != null and _host.can_unlock_skill(skill.stable_id)
		if unlocked:
			button.text = "%s  Unlocked" % skill.display_name
			button.disabled = true
		else:
			button.text = "%s  %d MUSD" % [skill.display_name, skill.cost_musd]
			button.disabled = not available
		button.tooltip_text = _skill_reason(skill, state, session, unlocked, available)


func _build() -> void:
	var panel: Panel = CampaignChrome.make_panel("SkillTreePanel")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -380.0
	panel.offset_top = -280.0
	panel.offset_right = 380.0
	panel.offset_bottom = 280.0
	add_child(panel)
	_layout = CampaignChrome.make_column("SkillTreeLayout")
	panel.add_child(_layout)
	var title: Label = Label.new()
	title.text = "Skill tree"
	CampaignChrome.apply_heading(title)
	_layout.add_child(title)
	var summary: Label = Label.new()
	summary.text = "The player can unlock one skill in each Month Step. A domain skill stages a Project. Other skills do not change Cash."
	CampaignChrome.apply_body(summary)
	_layout.add_child(summary)
	for skill: BootstrapUnlockDefinition in CampaignCatalog.skill_definitions():
		var button: Button = Button.new()
		button.name = "%sButton" % String(skill.stable_id).replace(".", "_")
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_unlock_pressed.bind(skill.stable_id))
		_layout.add_child(button)
		_unlock_buttons[skill.stable_id] = button


func _on_unlock_pressed(skill_id: StringName) -> void:
	if _host == null:
		return
	_host.unlock_skill(skill_id)


func _skill_reason(
		skill: BootstrapUnlockDefinition,
		state: GameState,
		session: CampaignSessionState,
		unlocked: bool,
		available: bool
	) -> String:
	if unlocked:
		return skill.summary
	if available:
		return skill.summary
	if state == null or state.calendar == null:
		return "Game State is missing."
	if CampaignCatalog.cash_balance_musd(state) < skill.cost_musd:
		return "Cash is below %d MUSD." % skill.cost_musd
	if state.calendar.current_month_step_index < skill.required_month_step_index:
		return "This skill opens after Month Step %d." % skill.required_month_step_index
	if session.unlocked_skill_in_month(state.calendar.current_month_step_index):
		return "The player already unlocked one skill in this Month Step."
	return skill.summary
