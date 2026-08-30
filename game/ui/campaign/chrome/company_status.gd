class_name CampaignCompanyStatus
extends PanelContainer

signal activated

@onready var _company_label: Label = $Margin/Row/TextColumn/CompanyLabel
@onready var _meta_label: Label = $Margin/Row/TextColumn/MetaLabel
@onready var _mark: TextureRect = $Margin/Row/Mark


func _ready() -> void:
	theme_type_variation = &"StatusPanel"
	custom_minimum_size = Vector2(0.0, 48.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	if _mark != null:
		_mark.texture = load(CampaignPresentationDefinition.COMPANY_MARK_PATH) as Texture2D
	if _company_label != null:
		_company_label.text = CampaignPresentationDefinition.COMPANY_DISPLAY_NAME


func present_state(state: GameState) -> void:
	if _meta_label == null or state == null or state.calendar == null:
		return
	var cash_musd: int = CampaignCatalog.cash_balance_musd(state)
	_meta_label.text = "Q%d · MONTH %d  |  $%dM" % [
		state.calendar.current_quarter_index,
		state.calendar.current_month_step_index,
		cash_musd,
	]


func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	activated.emit()
