class_name SkillTreeView
extends Control

var _host: CampaignHost
var _layout: VBoxContainer
var _balance_label: Label
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
	if _balance_label != null:
		_balance_label.text = "Research points %d" % session.research_points
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
			button.text = "%s  %d RP" % [skill.display_name, skill.cost_research_points]
			button.disabled = not available
		button.tooltip_text = _skill_reason(skill, session, unlocked, available)


func _build() -> void:
	var panel: Panel = CampaignChrome.make_panel("SkillTreePanel")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -500.0
	panel.offset_top = -280.0
	panel.offset_right = 500.0
	panel.offset_bottom = 280.0
	add_child(panel)
	_layout = CampaignChrome.make_column("SkillTreeLayout")
	panel.add_child(_layout)
	var title: Label = Label.new()
	title.text = "Skill tree"
	CampaignChrome.apply_heading(title)
	_layout.add_child(title)
	_balance_label = Label.new()
	_balance_label.name = "ResearchPointsLabel"
	_balance_label.text = "Research points 0"
	CampaignChrome.apply_body(_balance_label)
	_layout.add_child(_balance_label)
	var summary: Label = Label.new()
	summary.text = "The player spends research points on one tree. A completed Research Project grants 4 research points."
	CampaignChrome.apply_body(summary)
	_layout.add_child(summary)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.name = "SkillTreeBranches"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	_layout.add_child(columns)
	columns.add_child(_make_branch_column("Research", CampaignCatalog.BRANCH_RESEARCH))
	columns.add_child(_make_branch_column("Scale", CampaignCatalog.BRANCH_SCALE))
	columns.add_child(_make_branch_column("Applications", CampaignCatalog.BRANCH_APPLICATION))


func _make_branch_column(title: String, branch_id: StringName) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "%sColumn" % String(branch_id)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	var heading: Label = Label.new()
	heading.text = title
	CampaignChrome.apply_heading(heading)
	column.add_child(heading)
	for skill: BootstrapUnlockDefinition in CampaignCatalog.skill_definitions():
		if skill.branch_id != branch_id:
			continue
		var button: Button = Button.new()
		button.name = "%sButton" % String(skill.stable_id).replace(".", "_")
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_unlock_pressed.bind(skill.stable_id))
		column.add_child(button)
		_unlock_buttons[skill.stable_id] = button
	return column


func _on_unlock_pressed(skill_id: StringName) -> void:
	if _host == null:
		return
	_host.unlock_skill(skill_id)


func _skill_reason(
		skill: BootstrapUnlockDefinition,
		session: CampaignSessionState,
		unlocked: bool,
		available: bool
	) -> String:
	if unlocked or available:
		return skill.summary
	if session.research_points < skill.cost_research_points:
		return "Research points are below %d." % skill.cost_research_points
	for prerequisite_id: StringName in skill.prerequisite_ids:
		if not session.has_skill(prerequisite_id):
			return "This skill requires %s." % String(prerequisite_id)
	return skill.summary
