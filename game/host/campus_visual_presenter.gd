class_name CampusVisualPresenter
extends Node

const CAMPUS_NODE_NAME: String = "CampusBlockout"
const GAMEPLAY_CAMERA_NAME: String = "GameplayCamera"
const LAB_STAGE_1_NAME: String = "LabStage1"
const LAB_STAGE_2_NAME: String = "LabStage2"
const COMPUTE_LINK_NAME: String = "ThirdPartyComputeLink"
const COMPETITOR_PANEL_NAME: String = "CompetitorPanel"
const HQ_LABORATORY_SELECTABLE_PATH: String = "res://scenes/hq_laboratory_selectable.tscn"
const HQ_LABORATORY_SELECTABLE_NAME: String = "HqLaboratorySelectable"
const COMPETITOR_SELECTABLE_PATH: String = "res://scenes/hq_competitor_selectable.tscn"
const COMPETITOR_SELECTABLE_NAME: String = "HqCompetitorSelectable"
const PANEL_WIDTH_PX: float = 360.0

var _compute_link: Node3D
var _competitor_root: Control
var _competitor_label: Label
var _last_mapping: CampusVisualMapping


func _ready() -> void:
	_build_compute_link()
	_build_competitor_presentation()
	_ensure_hq_selectables()


func present_state(state: GameState) -> void:
	_last_mapping = CampusVisualMapping.from_state(state)
	_ensure_hq_selectables()
	_apply_laboratory(_last_mapping)
	_apply_competitor_marker(_last_mapping)
	# Scale presentation belongs to the Data Center World. HQ must not show a Compute link mass.
	if _compute_link != null:
		_compute_link.visible = false
	# Competitor presentation is a World selectable Context Card. Do not auto-show a fixed panel.
	if _competitor_root != null:
		_competitor_root.visible = false
	if _competitor_label != null:
		_competitor_label.text = _last_mapping.competitor_presentation_text


func get_mapping() -> CampusVisualMapping:
	return _last_mapping


func is_compute_link_visible() -> bool:
	return _compute_link != null and _compute_link.visible


func is_competitor_presentation_visible() -> bool:
	return _competitor_root != null and _competitor_root.visible


func get_competitor_presentation_text() -> String:
	if _competitor_label == null:
		return ""
	return _competitor_label.text


func set_campus_world_visible(visible: bool) -> void:
	var campus: Node3D = _campus_node() as Node3D
	if campus != null:
		campus.visible = visible
	var camera: Camera3D = null
	if campus != null:
		camera = campus.get_node_or_null(GAMEPLAY_CAMERA_NAME) as Camera3D
	if camera != null:
		camera.current = visible
		var isometric_camera: IsometricCamera = camera as IsometricCamera
		if isometric_camera != null:
			isometric_camera.input_enabled = visible
	if _competitor_root != null and not visible:
		_competitor_root.visible = false


func get_visible_laboratory_node_name() -> String:
	var campus: Node = _campus_node()
	if campus == null:
		return ""
	var stage_two: Node3D = campus.get_node_or_null(LAB_STAGE_2_NAME) as Node3D
	if stage_two != null and stage_two.visible:
		return LAB_STAGE_2_NAME
	var stage_one: Node3D = campus.get_node_or_null(LAB_STAGE_1_NAME) as Node3D
	if stage_one != null and stage_one.visible:
		return LAB_STAGE_1_NAME
	return ""


func _campus_node() -> Node:
	var host: Node = get_parent()
	if host == null:
		return null
	return host.get_node_or_null(CAMPUS_NODE_NAME)


func _ensure_hq_selectables() -> void:
	var campus: Node = _campus_node()
	if campus == null:
		return
	_instance_campus_child(
		campus,
		HQ_LABORATORY_SELECTABLE_NAME,
		HQ_LABORATORY_SELECTABLE_PATH,
		"missing_hq_laboratory_selectable",
		"The HQ laboratory selectable scene did not load: %s" % HQ_LABORATORY_SELECTABLE_PATH
	)
	_instance_campus_child(
		campus,
		COMPETITOR_SELECTABLE_NAME,
		COMPETITOR_SELECTABLE_PATH,
		"missing_hq_competitor_selectable",
		"The HQ Competitor selectable scene did not load: %s" % COMPETITOR_SELECTABLE_PATH
	)
	var competitor: Node3D = campus.get_node_or_null(COMPETITOR_SELECTABLE_NAME) as Node3D
	if competitor != null and _last_mapping == null:
		competitor.visible = false


func _instance_campus_child(
		campus: Node,
		node_name: String,
		scene_path: String,
		fail_code: String,
		fail_message: String
	) -> void:
	if campus.get_node_or_null(node_name) != null:
		return
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		ServiceContract.fail(fail_code, fail_message)
		return
	var instanced: Node = packed.instantiate()
	instanced.name = node_name
	campus.add_child(instanced)


func _apply_competitor_marker(mapping: CampusVisualMapping) -> void:
	var campus: Node = _campus_node()
	if campus == null:
		return
	var marker: Node3D = campus.get_node_or_null(COMPETITOR_SELECTABLE_NAME) as Node3D
	if marker == null:
		return
	var show_marker: bool = mapping.competitor_release_visible
	marker.visible = show_marker
	var selectable: CampaignWorldSelectable = marker as CampaignWorldSelectable
	if selectable != null:
		selectable.input_ray_pickable = show_marker
		selectable.collision_layer = 1 if show_marker else 0


func _apply_laboratory(mapping: CampusVisualMapping) -> void:
	var campus: Node = _campus_node()
	if campus == null:
		return
	var use_empty: bool = mapping.has_empty_plot()
	var use_developed: bool = mapping.uses_developed_laboratory()
	var stage_two: Node3D = campus.get_node_or_null(LAB_STAGE_2_NAME) as Node3D
	if use_developed and stage_two == null:
		var packed: PackedScene = load(CampusVisualMapping.LAB_STAGE_2_PATH) as PackedScene
		if packed == null:
			ServiceContract.fail(
				"missing_lab_stage_2",
				"The developed laboratory scene did not load: %s" % CampusVisualMapping.LAB_STAGE_2_PATH
			)
			return
		var instanced: Node = packed.instantiate()
		stage_two = instanced as Node3D
		if stage_two == null:
			ServiceContract.fail(
				"invalid_lab_stage_2",
				"The developed laboratory scene root is not a Node3D."
			)
			return
		stage_two.name = LAB_STAGE_2_NAME
		campus.add_child(stage_two)
	var stage_one: Node3D = campus.get_node_or_null(LAB_STAGE_1_NAME) as Node3D
	if stage_one != null:
		stage_one.visible = not use_empty and not use_developed
	if stage_two != null:
		stage_two.visible = not use_empty and use_developed


func _build_compute_link() -> void:
	_compute_link = Node3D.new()
	_compute_link.name = COMPUTE_LINK_NAME
	_compute_link.visible = false
	add_child(_compute_link)
	var cyan_material: Material = load("res://materials/cyan.tres") as Material
	var metal_material: Material = load("res://materials/metal.tres") as Material
	if cyan_material == null or metal_material == null:
		ServiceContract.fail(
			"missing_compute_link_material",
			"The Third-Party Compute link materials did not load."
		)
		return
	_add_box(
		_compute_link,
		"LinkPad",
		Vector3(14.0, 0.2, 10.0),
		Vector3(4.0, 0.4, 4.0),
		metal_material
	)
	_add_box(
		_compute_link,
		"LinkPylon",
		Vector3(14.0, 2.2, 10.0),
		Vector3(0.8, 4.0, 0.8),
		cyan_material
	)
	_add_box(
		_compute_link,
		"LinkSpan",
		Vector3(7.0, 3.8, 5.0),
		Vector3(14.0, 0.4, 0.4),
		cyan_material
	)


func _add_box(
		parent: Node3D,
		node_name: String,
		origin: Vector3,
		size: Vector3,
		material: Material
	) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.position = origin
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)


func _build_competitor_presentation() -> void:
	_competitor_root = Control.new()
	_competitor_root.name = "CompetitorPresentation"
	_competitor_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_competitor_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_competitor_root.visible = false
	add_child(_competitor_root)
	var panel: Panel = Panel.new()
	panel.name = COMPETITOR_PANEL_NAME
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_right = -16.0
	panel.offset_left = -PANEL_WIDTH_PX
	panel.offset_top = 16.0
	panel.offset_bottom = -16.0
	_competitor_root.add_child(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 16.0
	layout.offset_top = 16.0
	layout.offset_right = -16.0
	layout.offset_bottom = -16.0
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	var title: Label = Label.new()
	title.text = "Competitor Release"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(title)
	_competitor_label = Label.new()
	_competitor_label.name = "CompetitorLabel"
	_competitor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_competitor_label)
