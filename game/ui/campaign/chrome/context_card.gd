class_name CampaignContextCard
extends PanelContainer

signal closed
signal primary_action_pressed(action_id: StringName)

const OPEN_DURATION_SEC: float = 0.24
const ROW_STAGGER_SEC: float = 0.035

var _host: CampaignHost
var _card_type: StringName = &""
var _entity_id: StringName = &""

@onready var _title_label: Label = $Margin/Layout/Header/TitleLabel
@onready var _close_button: Button = $Margin/Layout/Header/CloseButton
@onready var _body_label: Label = $Margin/Layout/BodyLabel
@onready var _rows: VBoxContainer = $Margin/Layout/Rows
@onready var _primary_button: Button = $Margin/Layout/PrimaryButton


func _ready() -> void:
	theme_type_variation = &"ContextCard"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(320.0, 0.0)
	if _close_button != null:
		_close_button.theme_type_variation = &"CloseAction"
		_close_button.icon = load(CampaignPresentationDefinition.ICON_X_OUTLINE_PATH) as Texture2D
		_close_button.expand_icon = true
		_close_button.pressed.connect(func() -> void: closed.emit())
	if _primary_button != null:
		_primary_button.theme_type_variation = &"PrimaryAction"
		_primary_button.pressed.connect(_on_primary_pressed)
	visible = false


func bind_host(host: CampaignHost) -> void:
	_host = host


func get_card_type() -> StringName:
	return _card_type


func get_entity_id() -> StringName:
	return _entity_id


func get_body_text() -> String:
	if _body_label == null:
		return ""
	return _body_label.text


func present_context(
		entity_id: StringName,
		card_type: StringName,
		state: GameState,
		definition: MarketingScenarioDefinition
	) -> void:
	_entity_id = entity_id
	_card_type = card_type
	_clear_rows()
	if _primary_button != null:
		_primary_button.visible = false
	match card_type:
		CampaignWorldSelectable.CONTEXT_LABORATORY:
			_present_laboratory(state)
		CampaignWorldSelectable.CONTEXT_DATA_CENTER:
			_present_data_center(state, definition)
		CampaignWorldSelectable.CONTEXT_GOVERNMENT:
			_present_government(state)
		_:
			if _title_label != null:
				_title_label.text = "Selection"
			if _body_label != null:
				_body_label.text = String(entity_id)
	_play_open()


func _present_laboratory(state: GameState) -> void:
	if _title_label != null:
		_title_label.text = "LABORATORY"
	var capacity: int = CampaignCatalog.laboratory_capacity_level(state)
	var stage_label: String = CampaignCatalog.laboratory_stage_label(state)
	var research_ready: bool = (
		state != null
		and state.company != null
		and state.company.projects.has(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID)
	)
	if _body_label != null:
		_body_label.text = "Laboratory capacity level %d.\n%s.\nThe visible campus is the authored campus blockout." % [
			capacity,
			stage_label,
		]
	_add_row("STAGE", stage_label.to_upper())
	_add_row("CAPACITY", str(capacity))
	_add_row("RESEARCH", "READY" if research_ready else "NOT READY")
	if _primary_button != null:
		_primary_button.text = "OPEN PROJECTS"
		_primary_button.visible = true


func _present_data_center(state: GameState, definition: MarketingScenarioDefinition) -> void:
	if _title_label != null:
		_title_label.text = "DATA CENTER"
	var lines: PackedStringArray = PackedStringArray()
	lines.append("This view is the reserved Scale slot.")
	lines.append("The Marketing Scenario does not construct an owned Data Center.")
	if state != null and state.company != null:
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
	if _body_label != null:
		_body_label.text = "\n".join(lines)


func _present_government(state: GameState) -> void:
	if _title_label != null:
		_title_label.text = "GOVERNMENT"
	var lines: PackedStringArray = PackedStringArray()
	lines.append("This view is the reserved regulation slot.")
	if TrustThreshold.is_government_active(state):
		lines.append("Government is active.")
		lines.append("Government hosts government and regulation presentation when that content exists.")
		lines.append("Government is not an HQ Site Plot.")
	else:
		lines.append("Government is inactive.")
		lines.append("Government starts after a released player Model reaches 90 evaluation points.")
	if _body_label != null:
		_body_label.text = "\n".join(lines)


func _add_row(label_text: String, value_text: String) -> void:
	if _rows == null:
		return
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 18)
	row.add_child(label)
	var value: Label = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(value)
	_rows.add_child(row)


func _clear_rows() -> void:
	if _rows == null:
		return
	for child: Node in _rows.get_children():
		child.queue_free()


func _play_open() -> void:
	visible = true
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, OPEN_DURATION_SEC)
	if _rows == null:
		return
	var delay: float = 0.0
	for child: Node in _rows.get_children():
		var row: Control = child as Control
		if row == null:
			continue
		row.modulate.a = 0.0
		var row_tween: Tween = create_tween()
		row_tween.tween_interval(delay)
		row_tween.tween_property(row, "modulate:a", 1.0, OPEN_DURATION_SEC)
		delay += ROW_STAGGER_SEC


func _on_primary_pressed() -> void:
	if _card_type == CampaignWorldSelectable.CONTEXT_LABORATORY:
		primary_action_pressed.emit(&"open_projects")
		return
	primary_action_pressed.emit(&"")
