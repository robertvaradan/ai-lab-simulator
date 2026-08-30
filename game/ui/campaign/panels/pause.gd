class_name CampaignPausePanel
extends Control

var _host: CampaignHost


func bind_host(host: CampaignHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"Modal"
	panel.custom_minimum_size = Vector2(420.0, 240.0)
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var title: Label = Label.new()
	title.text = "Pause"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	var resume_button: Button = Button.new()
	resume_button.name = "ResumeButton"
	resume_button.text = "Resume"
	resume_button.theme_type_variation = &"SecondaryAction"
	resume_button.custom_minimum_size = Vector2(0.0, 48.0)
	resume_button.pressed.connect(_on_resume_pressed)
	layout.add_child(resume_button)
	var abandon_button: Button = Button.new()
	abandon_button.name = "AbandonButton"
	abandon_button.text = "Abandon campaign"
	abandon_button.theme_type_variation = &"DestructiveAction"
	abandon_button.custom_minimum_size = Vector2(0.0, 48.0)
	abandon_button.pressed.connect(_on_abandon_pressed)
	layout.add_child(abandon_button)


func _on_resume_pressed() -> void:
	if _host != null and _host.get_workspace() != null:
		_host.get_workspace().back()


func _on_abandon_pressed() -> void:
	if _host != null:
		_host.request_abandon()
