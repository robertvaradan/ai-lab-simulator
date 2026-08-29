class_name DataCenterView
extends Control

var _body: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel: Panel = CampaignChrome.make_panel("DataCenterPanel")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -380.0
	panel.offset_top = -240.0
	panel.offset_right = 380.0
	panel.offset_bottom = 240.0
	add_child(panel)
	var layout: VBoxContainer = CampaignChrome.make_column("DataCenterLayout")
	panel.add_child(layout)
	var title: Label = Label.new()
	title.text = "Data Center"
	CampaignChrome.apply_heading(title)
	layout.add_child(title)
	_body = Label.new()
	_body.name = "DataCenterBody"
	CampaignChrome.apply_body(_body)
	layout.add_child(_body)


func get_body_text() -> String:
	if _body == null:
		return ""
	return _body.text


func present_state(state: GameState, definition: MarketingScenarioDefinition) -> void:
	if _body == null:
		return
	if state == null or state.company == null:
		_body.text = "Game State is missing."
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append("This view is the reserved Scale slot.")
	lines.append("The Marketing Scenario does not construct an owned Data Center.")
	lines.append("Compute Capacity %d compute-unit-months." % state.company.compute_capacity_unit_months)
	if state.company.contracts.is_empty():
		lines.append("No compute contract is active.")
	else:
		var contract_ids: Array[StringName] = state.company.contracts.keys()
		contract_ids.sort()
		for contract_id: StringName in contract_ids:
			var contract: ContractState = state.company.contracts[contract_id]
			if contract == null:
				continue
			var content: ContractDefinition = CampaignCatalog.find_contract(
				definition,
				contract.content_definition_id
			)
			var cost_text: String = "cost unknown"
			if content != null:
				cost_text = "%d MUSD each Month Step" % content.monthly_cost_musd
			lines.append("%s. %s. %s." % [
				String(contract.stable_id),
				String(contract.status_id),
				cost_text,
			])
	_body.text = "\n".join(lines)
