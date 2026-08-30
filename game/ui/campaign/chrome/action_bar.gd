class_name CampaignActionBar
extends Control

signal world_map_pressed
signal world_pressed
signal plan_pressed
signal advance_pressed

@onready var _world_map_button: Button = $Bar/WorldMapButton
@onready var _world_button: Button = $Bar/WorldButton
@onready var _plan_button: Button = $Bar/PlanButton
@onready var _advance_button: Button = $Bar/AdvanceButton
@onready var _reason_label: Label = $ReasonLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _world_map_button != null:
		_world_map_button.theme_type_variation = &"SegmentedNav"
		_world_map_button.pressed.connect(_on_world_map_pressed)
		_set_button_icon(_world_map_button, CampaignPresentationDefinition.ICON_WORLD_OUTLINE_PATH)
	if _world_button != null:
		_world_button.theme_type_variation = &"SegmentedNav"
		_world_button.pressed.connect(_on_world_pressed)
		_set_button_icon(_world_button, CampaignPresentationDefinition.ICON_BUILDING_OUTLINE_PATH)
	if _plan_button != null:
		_plan_button.theme_type_variation = &"SegmentedNav"
		_plan_button.pressed.connect(_on_plan_pressed)
		_set_button_icon(_plan_button, CampaignPresentationDefinition.ICON_CLIPBOARD_LIST_OUTLINE_PATH)
	if _advance_button != null:
		_advance_button.theme_type_variation = &"PrimaryAction"
		_advance_button.pressed.connect(_on_advance_pressed)
		_set_button_icon(_advance_button, CampaignPresentationDefinition.ICON_CHEVRONS_RIGHT_OUTLINE_PATH)
	if _reason_label != null:
		_reason_label.visible = false


func get_advance_button() -> Button:
	return _advance_button


func present(
		session: CampaignSessionState,
		validation: PlanValidationResult
	) -> void:
	if session == null:
		return
	if _world_button != null:
		_world_button.text = CampaignCatalog.world_display_name(session.active_world_id).to_upper()
		if session.active_world_id == CampaignCatalog.WORLD_DATA_CENTER:
			_set_button_icon(_world_button, CampaignPresentationDefinition.ICON_SERVER_OUTLINE_PATH)
		elif session.active_world_id == CampaignCatalog.WORLD_GOVERNMENT:
			_set_button_icon(_world_button, CampaignPresentationDefinition.ICON_BUILDING_BANK_OUTLINE_PATH)
		else:
			_set_button_icon(_world_button, CampaignPresentationDefinition.ICON_BUILDING_OUTLINE_PATH)
	var first_reason: String = ""
	var is_valid: bool = true
	if validation != null:
		is_valid = validation.is_valid()
		if not is_valid:
			var diagnostics: Array[SimulationDiagnostic] = validation.diagnostics
			if not diagnostics.is_empty() and diagnostics[0] != null:
				first_reason = diagnostics[0].message
	if _advance_button != null:
		_advance_button.disabled = session.failed or not is_valid
	if _reason_label != null:
		_reason_label.text = first_reason
		_reason_label.visible = not first_reason.is_empty()


func _set_button_icon(button: Button, path: String) -> void:
	if button == null:
		return
	button.icon = load(path) as Texture2D
	button.expand_icon = true


func _on_world_map_pressed() -> void:
	world_map_pressed.emit()


func _on_world_pressed() -> void:
	world_pressed.emit()


func _on_plan_pressed() -> void:
	plan_pressed.emit()


func _on_advance_pressed() -> void:
	advance_pressed.emit()
