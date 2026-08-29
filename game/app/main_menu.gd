class_name MainMenu
extends Control

const TITLE_TEXT: String = "AI Lab Simulator"
const START_TEXT: String = "Start"

var _start_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func get_start_button() -> Button:
	return _start_button


func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.name = "Background"
	background.color = CampaignChrome.VOID_BASE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 24)
	center.add_child(layout)
	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CampaignChrome.apply_title(title)
	layout.add_child(title)
	_start_button = Button.new()
	_start_button.name = "StartButton"
	_start_button.text = START_TEXT
	_start_button.custom_minimum_size = Vector2(280.0, 48.0)
	_start_button.pressed.connect(_on_start_pressed)
	layout.add_child(_start_button)


func _on_start_pressed() -> void:
	SceneRouter.go_to_campaign(get_tree())
