class_name GovernmentPlaceholderView
extends Control

var _body: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel: Panel = CampaignChrome.make_panel("GovernmentPanel")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -380.0
	panel.offset_top = -240.0
	panel.offset_right = 380.0
	panel.offset_bottom = 240.0
	add_child(panel)
	var layout: VBoxContainer = CampaignChrome.make_column("GovernmentLayout")
	panel.add_child(layout)
	var title: Label = Label.new()
	title.text = "Government"
	CampaignChrome.apply_heading(title)
	layout.add_child(title)
	_body = Label.new()
	_body.name = "GovernmentBody"
	CampaignChrome.apply_body(_body)
	_body.text = "\n".join(PackedStringArray([
		"This view is the reserved regulation slot.",
		"Government hosts government and regulation presentation when that content exists.",
		"Government is not an HQ Site Plot.",
	]))
	layout.add_child(_body)


func get_body_text() -> String:
	if _body == null:
		return ""
	return _body.text
