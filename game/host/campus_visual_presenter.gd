class_name CampusVisualPresenter
extends Node

const CAMPUS_NODE_NAME: String = "CampusBlockout"
const GAMEPLAY_CAMERA_NAME: String = "GameplayCamera"
const LAB_STAGE_1_NAME: String = "LabStage1"
const LAB_STAGE_2_NAME: String = "LabStage2"
const COMPUTE_LINK_NAME: String = "ThirdPartyComputeLink"
const HQ_LABORATORY_SELECTABLE_PATH: String = "res://scenes/hq_laboratory_selectable.tscn"
const HQ_LABORATORY_SELECTABLE_NAME: String = "HqLaboratorySelectable"

var _compute_link: Node3D
var _last_mapping: CampusVisualMapping


func _ready() -> void:
	_build_compute_link()
	_ensure_hq_selectables()


func present_state(state: GameState) -> void:
	_last_mapping = CampusVisualMapping.from_state(state)
	_ensure_hq_selectables()
	_apply_laboratory(_last_mapping)
	# Scale presentation belongs to the Data Center World. HQ must not show a Compute link mass.
	if _compute_link != null:
		_compute_link.visible = false


func get_mapping() -> CampusVisualMapping:
	return _last_mapping


func is_compute_link_visible() -> bool:
	return _compute_link != null and _compute_link.visible


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
