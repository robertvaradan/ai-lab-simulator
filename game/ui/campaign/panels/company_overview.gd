class_name CampaignCompanyOverviewPanel
extends Control

var _host: CampaignHost

@onready var _body: Label = $Panel/Margin/Layout/BodyLabel


func bind_host(host: CampaignHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)


func present_state(state: GameState, session: CampaignSessionState) -> void:
	if _body == null or state == null or state.company == null or session == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Teams %d" % state.company.project_team_count)
	lines.append("Capacity level %d" % CampaignCatalog.laboratory_capacity_level(state))
	lines.append("Research points %d" % session.research_points)
	lines.append("Active Projects")
	if state.company.projects.is_empty():
		lines.append("- None")
	else:
		var project_ids: Array[StringName] = state.company.projects.keys()
		project_ids.sort()
		for project_id: StringName in project_ids:
			var project: ProjectState = state.company.projects[project_id]
			if project == null:
				continue
			lines.append("- %s (%s)" % [String(project.stable_id), String(project.status_id)])
	lines.append("Models")
	if state.company.models.is_empty():
		lines.append("- None")
	else:
		var model_ids: Array[StringName] = state.company.models.keys()
		model_ids.sort()
		for model_id: StringName in model_ids:
			var model: ModelState = state.company.models[model_id]
			if model == null:
				continue
			lines.append("- %s %s" % [model.display_name, model.version_label])
	lines.append("Contracts")
	if state.company.contracts.is_empty():
		lines.append("- None")
	else:
		var contract_ids: Array[StringName] = state.company.contracts.keys()
		contract_ids.sort()
		for contract_id: StringName in contract_ids:
			lines.append("- %s" % String(contract_id))
	if TrustThreshold.is_public_trust_active(state):
		lines.append("Public Trust %d" % state.company.public_trust_points)
	if TrustThreshold.is_government_active(state):
		lines.append("Government Trust %d" % state.company.government_trust_points)
	_body.text = "\n".join(lines)
