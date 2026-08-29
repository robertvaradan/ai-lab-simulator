class_name WorldMapView
extends Control

var _host: CampaignHost
var _hq_button: Button
var _data_center_button: Button
var _government_button: Button


func bind_host(host: CampaignHost) -> void:
	_host = host


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func get_hq_button() -> Button:
	return _hq_button


func get_data_center_button() -> Button:
	return _data_center_button


func get_government_button() -> Button:
	return _government_button


func _build() -> void:
	var panel: Panel = CampaignChrome.make_panel("WorldMapPanel")
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -380.0
	panel.offset_top = -280.0
	panel.offset_right = 380.0
	panel.offset_bottom = 280.0
	add_child(panel)
	var layout: VBoxContainer = CampaignChrome.make_column("WorldMapLayout")
	panel.add_child(layout)
	var title: Label = Label.new()
	title.text = "World Map"
	CampaignChrome.apply_heading(title)
	layout.add_child(title)
	var summary: Label = Label.new()
	summary.text = "Select one World to enter it."
	CampaignChrome.apply_body(summary)
	layout.add_child(summary)
	var map_layout: VBoxContainer = VBoxContainer.new()
	map_layout.name = "WorldAdjacency"
	map_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	map_layout.add_theme_constant_override("separation", 8)
	layout.add_child(map_layout)
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.name = "DataCenterRow"
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_data_center_button = _make_world_button(CampaignCatalog.WORLD_DATA_CENTER)
	top_row.add_child(_data_center_button)
	map_layout.add_child(top_row)
	var vertical_link: Label = Label.new()
	vertical_link.name = "VerticalLink"
	vertical_link.text = "|"
	vertical_link.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CampaignChrome.apply_body(vertical_link)
	map_layout.add_child(vertical_link)
	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.name = "HqGovernmentRow"
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 8)
	_hq_button = _make_world_button(CampaignCatalog.WORLD_HQ)
	bottom_row.add_child(_hq_button)
	var horizontal_link: Label = Label.new()
	horizontal_link.name = "HorizontalLink"
	horizontal_link.text = "--"
	horizontal_link.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CampaignChrome.apply_body(horizontal_link)
	bottom_row.add_child(horizontal_link)
	_government_button = _make_world_button(CampaignCatalog.WORLD_GOVERNMENT)
	bottom_row.add_child(_government_button)
	map_layout.add_child(bottom_row)


func _make_world_button(world_id: StringName) -> Button:
	var button: Button = Button.new()
	button.name = "%sButton" % String(world_id).replace(".", "_")
	button.text = CampaignCatalog.world_display_name(world_id)
	button.pressed.connect(_on_world_pressed.bind(world_id))
	return button


func _on_world_pressed(world_id: StringName) -> void:
	if _host == null:
		return
	_host.enter_world(world_id)
