# This file preserves the one-time procedural source that created the initial scene.
# Runtime and editor workflows must use res://scenes/campus_blockout.tscn directly.
extends Node3D

const OUTPUT_RESOLUTION := Vector2i(1920, 1080)
const CAMERA_TARGET := Vector3(-2.5, 2.8, -0.5)
const CAMERA_POSITION := Vector3(46.5, 61.0, 50.0)
const CAMERA_SIZE := 50.0
const RESEARCH_OFFSET := Vector3(0.0, 0.0, -2.0)
const REFERENCE_IMAGE_RELATIVE_PATH := "../docs/concept-art/main-lab-site-context-v1.png"

var _materials: Dictionary[StringName, StandardMaterial3D] = {}
var _mesh_count: int = 0
var _light_count: int = 0
var _automated: bool = false
var _output_path: String = ""
var _bake_output_path: String = ""
var _fatal_triggered: bool = false


func _ready() -> void:
	_parse_arguments()
	if _fatal_triggered:
		return
	_validate_viewport()
	if _fatal_triggered:
		return
	_create_materials()
	_create_environment()
	_create_ground_and_roads()
	_create_site_boundaries()
	_create_parking_and_paths()
	_create_main_lab()
	_create_landscaping()
	_create_site_lights()
	_create_camera()
	print(
		"CAMPUS_BLOCKOUT_READY meshes=%d lights=%d camera_size=%.1f"
		% [_mesh_count, _light_count, CAMERA_SIZE]
	)
	if not _bake_output_path.is_empty():
		call_deferred("_bake_scene")
	elif _automated:
		call_deferred("_capture_blockout")


func _parse_arguments() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var argument_index: int = 0
	while argument_index < arguments.size():
		var argument: String = arguments[argument_index]
		if argument == "--render-blockout":
			_automated = true
		elif argument == "--bake-scene":
			if argument_index + 1 >= arguments.size():
				_fail("--bake-scene requires a res:// TSCN path.")
				return
			argument_index += 1
			_bake_output_path = arguments[argument_index]
		elif argument == "--output-path":
			if argument_index + 1 >= arguments.size():
				_fail("--output-path requires an absolute PNG path.")
				return
			argument_index += 1
			_output_path = arguments[argument_index]
		else:
			_fail("Unknown campus blockout argument: %s." % argument)
			return
		argument_index += 1
	if _automated:
		if _output_path.is_empty():
			_fail("Automated campus capture requires --output-path <absolute PNG path>.")
			return
		if not _output_path.is_absolute_path() or not _output_path.ends_with(".png"):
			_fail("--output-path must be an absolute PNG path: %s." % _output_path)
	if not _bake_output_path.is_empty():
		if not _bake_output_path.begins_with("res://") or not _bake_output_path.ends_with(".tscn"):
			_fail("--bake-scene must use a res:// TSCN path: %s." % _bake_output_path)


func _validate_viewport() -> void:
	var window: Window = get_window()
	window.size = OUTPUT_RESOLUTION
	get_viewport().msaa_3d = Viewport.MSAA_4X
	if window.size != OUTPUT_RESOLUTION:
		_fail("Campus blockout viewport must be %s, got %s." % [OUTPUT_RESOLUTION, window.size])


func _create_materials() -> void:
	_register_material(&"void", Color("0d2027"), 0.95, 0.0)
	_register_material(&"plinth", Color("152a31"), 0.82, 0.0)
	_register_material(&"grass", Color("304733"), 0.96, 0.0)
	_register_material(&"grass_mid", Color("384f34"), 0.97, 0.0)
	_register_material(&"grass_dark", Color("20372a"), 0.98, 0.0)
	_register_material(&"road", Color("171d20"), 0.91, 0.0)
	_register_material(&"road_edge", Color("343a39"), 0.9, 0.0)
	_register_material(&"marking", Color("88877e"), 0.84, 0.0)
	_register_material(&"concrete", Color("4f5a5b"), 0.93, 0.0)
	_register_material(&"concrete_light", Color("74766f"), 0.89, 0.0)
	_register_material(&"cream", Color("c4b496"), 0.9, 0.0)
	_register_material(&"cream_deep", Color("a89478"), 0.92, 0.0)
	_register_material(&"charcoal", Color("1a282e"), 0.72, 0.05)
	_register_material(&"roof", Color("2a3336"), 0.88, 0.02)
	_register_material(&"glass", Color("176f78"), 0.3, 0.1, Color("2a9a98"), 0.45)
	_register_material(&"glass_mid", Color("1e8088"), 0.28, 0.08, Color("34aaa8"), 0.35)
	_register_material(&"glass_light", Color("2e9890"), 0.26, 0.06, Color("48c0b4"), 0.55)
	_register_material(&"glass_dark", Color("134850"), 0.4, 0.1, Color("186068"), 0.18)
	_register_material(&"orange", Color("e05a32"), 0.7, 0.02)
	_register_material(&"orange_dark", Color("a04028"), 0.76, 0.0)
	_register_material(&"warm", Color("e0b070"), 0.55, 0.02, Color("ffc078"), 2.4)
	_register_material(&"cyan", Color("3ec8c0"), 0.3, 0.05, Color("5af0e4"), 1.1)
	_register_material(&"metal", Color("7a7d78"), 0.42, 0.62)
	_register_material(&"metal_dark", Color("20292c"), 0.39, 0.48)
	_register_material(&"trunk", Color("4b392b"), 0.98, 0.0)
	_register_material(&"tree_a", Color("264936"), 0.98, 0.0)
	_register_material(&"tree_b", Color("315b3d"), 0.98, 0.0)
	_register_material(&"car_dark", Color("252d32"), 0.5, 0.35)
	_register_material(&"car_green", Color("4a5940"), 0.55, 0.22)
	_register_material(&"car_gray", Color("55595a"), 0.52, 0.28)
	_register_material(&"tire", Color("111719"), 0.96, 0.0)


func _register_material(
	key: StringName,
	color: Color,
	roughness: float,
	metallic: float,
	emission_color: Color = Color(0.0, 0.0, 0.0, 1.0),
	emission_energy: float = 0.0
) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = emission_energy
	_materials[key] = material


func _create_environment() -> void:
	RenderingServer.set_default_clear_color(Color("0d2027"))
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("0d2027")
	environment.background_energy_multiplier = 0.45
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("6d8790")
	environment.ambient_light_energy = 0.39
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.94
	environment.ssao_enabled = true
	environment.ssao_radius = 2.4
	environment.ssao_intensity = 2.8
	environment.ssao_power = 1.35
	environment.glow_enabled = true
	environment.glow_intensity = 0.82
	environment.glow_strength = 0.75
	environment.glow_bloom = 0.08

	var world_environment := WorldEnvironment.new()
	world_environment.name = "CampusEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "WarmKey"
	key_light.light_color = Color("f2d6b0")
	key_light.light_energy = 1.02
	key_light.rotation_degrees = Vector3(-52.0, -42.0, 0.0)
	key_light.shadow_enabled = true
	key_light.light_angular_distance = 3.5
	key_light.directional_shadow_max_distance = 90.0
	add_child(key_light)
	_light_count += 1

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "CoolFill"
	fill_light.light_color = Color("7fb6c3")
	fill_light.light_energy = 0.36
	fill_light.rotation_degrees = Vector3(-37.0, 132.0, 0.0)
	fill_light.shadow_enabled = false
	add_child(fill_light)
	_light_count += 1


func _create_ground_and_roads() -> void:
	var ground := Node3D.new()
	ground.name = "GroundAndRoads"
	add_child(ground)

	_add_box(ground, "VoidBase", Vector3(-2.0, -1.55, -4.0), Vector3(52.0, 1.0, 46.0), &"void")
	_add_box(ground, "SitePlinth", Vector3(-2.0, -0.95, -4.0), Vector3(52.0, 0.55, 46.0), &"plinth")
	_add_box(ground, "GrassPlot", Vector3(-2.0, -0.57, -4.0), Vector3(50.0, 0.25, 44.0), &"grass")

	_add_box(ground, "FrontRoad", Vector3(0.0, -0.37, 23.2), Vector3(66.0, 0.28, 7.0), &"road")
	_add_box(ground, "RightRoad", Vector3(27.6, -0.37, -4.0), Vector3(7.0, 0.28, 55.0), &"road")
	_add_box(ground, "FrontCurb", Vector3(-1.6, -0.12, 19.45), Vector3(52.0, 0.22, 0.55), &"road_edge")
	_add_box(ground, "RightCurb", Vector3(23.85, -0.12, -4.0), Vector3(0.55, 0.22, 44.8), &"road_edge")
	_add_box(ground, "FrontWalk", Vector3(-1.6, -0.03, 18.7), Vector3(52.0, 0.14, 1.1), &"concrete")
	_add_box(ground, "RightWalk", Vector3(23.1, -0.03, -4.0), Vector3(1.1, 0.14, 44.8), &"concrete")

	for line_index: int in range(8):
		_add_box(
			ground,
			"FrontLaneMark_%02d" % line_index,
			Vector3(-27.0 + float(line_index) * 8.0, -0.18, 23.2),
			Vector3(3.2, 0.04, 0.12),
			&"marking"
		)
	for line_index: int in range(7):
		_add_box(
			ground,
			"RightLaneMark_%02d" % line_index,
			Vector3(27.6, -0.18, -28.0 + float(line_index) * 8.0),
			Vector3(0.12, 0.04, 3.2),
			&"marking"
		)

	for stripe_index: int in range(7):
		_add_box(
			ground,
			"CrosswalkStripe_%02d" % stripe_index,
			Vector3(-11.6 + float(stripe_index) * 0.72, -0.16, 20.2),
			Vector3(0.38, 0.05, 2.0),
			&"marking"
		)


func _create_site_boundaries() -> void:
	var boundaries := Node3D.new()
	boundaries.name = "SiteBoundaries"
	add_child(boundaries)

	_add_box(boundaries, "BackWall", Vector3(-2.0, 0.18, -26.6), Vector3(50.8, 1.05, 0.5), &"concrete_light")
	_add_box(boundaries, "LeftWallBack", Vector3(-27.1, 0.18, -16.5), Vector3(0.5, 1.05, 20.0), &"concrete_light")
	_add_box(boundaries, "LeftWallFront", Vector3(-27.1, 0.18, 7.5), Vector3(0.5, 1.05, 21.0), &"concrete_light")
	_add_box(boundaries, "RightWallBack", Vector3(23.1, 0.18, -20.0), Vector3(0.5, 1.05, 13.0), &"concrete_light")
	_add_box(boundaries, "RightWallFront", Vector3(23.1, 0.18, 6.5), Vector3(0.5, 1.05, 23.0), &"concrete_light")
	_add_box(boundaries, "FrontWallLeft", Vector3(-20.5, 0.18, 18.1), Vector3(12.5, 1.05, 0.5), &"concrete_light")
	_add_box(boundaries, "FrontWallRight", Vector3(10.5, 0.18, 18.1), Vector3(25.0, 1.05, 0.5), &"concrete_light")

	var post_positions: Array[Vector3] = [
		Vector3(-27.1, 0.6, -26.6),
		Vector3(23.1, 0.6, -26.6),
		Vector3(-27.1, 0.6, 18.1),
		Vector3(23.1, 0.6, 18.1),
		Vector3(-14.2, 0.6, 18.1),
		Vector3(-2.0, 0.6, 18.1),
		Vector3(23.1, 0.6, -13.5),
		Vector3(23.1, 0.6, -6.5),
	]
	for post_index: int in range(post_positions.size()):
		_add_box(
			boundaries,
			"WallPost_%02d" % post_index,
			post_positions[post_index],
			Vector3(0.85, 1.4, 0.85),
			&"concrete_light"
		)

	# Left-wall vehicle gate at the parking entrance.
	_add_box(boundaries, "GatePostLeft", Vector3(-27.0, 1.15, -5.8), Vector3(0.85, 2.6, 0.85), &"concrete_light")
	_add_box(boundaries, "GatePostRight", Vector3(-27.0, 1.15, -1.2), Vector3(0.85, 2.6, 0.85), &"concrete_light")
	_add_box(boundaries, "GateTop", Vector3(-27.0, 2.35, -3.5), Vector3(0.7, 0.32, 5.2), &"metal_dark")
	for bar_index: int in range(9):
		_add_box(
			boundaries,
			"GateBar_%02d" % bar_index,
			Vector3(-26.95, 1.2, -5.5 + float(bar_index) * 0.5),
			Vector3(0.14, 2.15, 0.14),
			&"metal_dark"
		)


func _create_parking_and_paths() -> void:
	var circulation := Node3D.new()
	circulation.name = "ParkingAndPaths"
	add_child(circulation)

	_add_box(circulation, "ParkingLot", Vector3(-19.0, -0.17, -2.0), Vector3(15.0, 0.16, 26.0), &"road")
	_add_box(circulation, "EntryDrive", Vector3(-9.0, -0.17, 10.5), Vector3(20.0, 0.16, 5.4), &"road")
	_add_box(circulation, "ServiceDrive", Vector3(-22.5, -0.17, -11.5), Vector3(10.0, 0.16, 6.5), &"road")
	_add_box(circulation, "FrontLoopRoad", Vector3(-3.0, -0.17, 15.7), Vector3(36.0, 0.16, 5.4), &"road")
	_add_box(circulation, "BuildingApron", Vector3(2.5, -0.05, 2.8), Vector3(28.0, 0.18, 11.5), &"concrete")
	for tile_column: int in range(10):
		_add_box(
			circulation,
			"PlazaTileColumn_%02d" % tile_column,
			Vector3(-9.5 + float(tile_column) * 2.8, 0.055, 2.5),
			Vector3(0.05, 0.025, 10.5),
			&"road_edge"
		)
	for tile_row: int in range(5):
		_add_box(
			circulation,
			"PlazaTileRow_%02d" % tile_row,
			Vector3(2.5, 0.055, -1.8 + float(tile_row) * 2.3),
			Vector3(27.0, 0.025, 0.05),
			&"road_edge"
		)
	_add_box(circulation, "RightWalkway", Vector3(16.0, -0.05, 1.0), Vector3(3.5, 0.18, 12.0), &"concrete")
	_add_box(circulation, "RearWalkway", Vector3(0.0, -0.05, -13.0), Vector3(32.0, 0.18, 2.2), &"concrete")

	for parking_index: int in range(8):
		var parking_z: float = -9.0 + float(parking_index) * 2.4
		_add_box(
			circulation,
			"ParkingLineLeft_%02d" % parking_index,
			Vector3(-23.0, -0.05, parking_z),
			Vector3(5.4, 0.04, 0.1),
			&"marking"
		)
		_add_box(
			circulation,
			"ParkingLineRight_%02d" % parking_index,
			Vector3(-15.5, -0.05, parking_z),
			Vector3(5.4, 0.04, 0.1),
			&"marking"
		)
	_add_box(circulation, "ParkingCenterLine", Vector3(-19.25, -0.05, -0.5), Vector3(0.1, 0.04, 20.0), &"marking")
	_add_box(circulation, "ParkingHedgeStrip", Vector3(-19.25, 0.35, -0.5), Vector3(0.75, 0.7, 19.0), &"grass_dark")
	_add_box(circulation, "ParkingEdgeHedge", Vector3(-11.5, 0.35, 0.5), Vector3(0.7, 0.7, 20.0), &"grass_dark")
	_add_box(circulation, "ParkingBackHedge", Vector3(-19.0, 0.35, -14.0), Vector3(12.0, 0.7, 0.7), &"grass_dark")

	_create_car(circulation, "CarA", Vector3(-22.5, 0.42, -6.0), 0.0, &"car_dark")
	_create_car(circulation, "CarB", Vector3(-16.0, 0.42, -3.0), 180.0, &"car_gray")
	_create_car(circulation, "CarC", Vector3(-22.5, 0.42, 2.0), 0.0, &"car_dark")
	_create_car(circulation, "CarD", Vector3(-16.0, 0.42, 5.5), 180.0, &"car_gray")
	_create_car(circulation, "CarE", Vector3(-8.0, 0.42, 10.5), 90.0, &"car_green")
	_create_car(circulation, "CarF", Vector3(-0.5, 0.42, 15.6), 90.0, &"car_gray")

	for step_index: int in range(8):
		var step_depth: float = 0.5
		var step_y: float = 0.06 + float(step_index) * 0.12
		var step_z: float = 7.2 - float(step_index) * step_depth
		_add_box(
			circulation,
			"EntryStep_%02d" % step_index,
			Vector3(0.05, step_y, step_z),
			Vector3(4.0, 0.16, step_depth + 0.06),
			&"concrete_light"
		)

	_create_planter(circulation, "EntryPlanterLeft", Vector3(-4.8, 0.15, 5.8), Vector3(2.8, 0.55, 2.4))
	_create_planter(circulation, "EntryPlanterRight", Vector3(5.2, 0.15, 6.2), Vector3(2.8, 0.55, 2.4))

	# Separate grass pad to the right of the wing, matching the reference site mark.
	_add_box(circulation, "ActivityGrassCut", Vector3(20.8, -0.35, -12.0), Vector3(7.0, 0.12, 7.5), &"grass_mid")
	_add_box(circulation, "ActivityPad", Vector3(20.8, 0.12, -12.0), Vector3(6.0, 0.4, 6.5), &"concrete")
	_add_outline(circulation, "ActivityPadOutline", Vector3(20.8, 0.36, -12.0), Vector2(5.0, 5.4), &"cyan", 0.14)
	_create_planter(circulation, "PlazaPlanterA", Vector3(9.0, 0.15, 5.0), Vector3(2.8, 0.55, 2.3))
	_create_planter(circulation, "PlazaPlanterB", Vector3(13.5, 0.15, 5.2), Vector3(3.0, 0.55, 2.4))
	_create_planter(circulation, "LoopIslandA", Vector3(-9.0, 0.12, 15.8), Vector3(4.2, 0.5, 2.6))
	_create_planter(circulation, "LoopIslandB", Vector3(6.5, 0.12, 15.8), Vector3(4.8, 0.5, 2.6))


func _create_main_lab() -> void:
	var lab := Node3D.new()
	lab.name = "MainLab"
	add_child(lab)

	_add_box(lab, "Foundation", Vector3(3.0, 0.18, -3.0), Vector3(28.0, 0.7, 18.0), &"concrete_light")
	_create_tower(lab)
	_create_research_block(lab)
	_create_right_wing(lab)
	_create_roof_equipment(lab)
	_create_entry(lab)


func _create_tower(parent: Node3D) -> void:
	# Tall glass tower with a thick cream L-frame matching the reference.
	_add_box(parent, "TowerBody", Vector3(-5.0, 7.2, -3.6), Vector3(9.2, 14.0, 8.8), &"charcoal")

	# Cream L-frame only: left pier + top beam + thin roof parapet. Glass dominates.
	_add_box(parent, "TowerCreamLeftPier", Vector3(-9.55, 7.3, 1.0), Vector3(1.7, 14.6, 2.4), &"cream")
	_add_box(parent, "TowerCreamLeftWall", Vector3(-9.7, 7.3, -3.4), Vector3(1.5, 14.6, 6.2), &"cream")
	_add_box(parent, "TowerCreamTopBeam", Vector3(-4.9, 14.35, 1.5), Vector3(9.0, 1.25, 1.4), &"cream")
	_add_box(parent, "TowerCreamCorner", Vector3(-9.4, 14.35, 1.5), Vector3(2.0, 1.25, 1.4), &"cream")
	_add_box(parent, "TowerCreamBase", Vector3(-5.0, 0.48, 1.5), Vector3(8.6, 0.7, 1.1), &"cream_deep")

	_add_box(parent, "TowerFrontGlass", Vector3(-4.8, 7.1, 1.4), Vector3(7.6, 12.4, 0.18), &"glass")
	for panel_column: int in range(5):
		for panel_row: int in range(7):
			var panel_material: StringName = &"glass"
			var panel_pattern: int = (panel_column * 3 + panel_row) % 6
			if panel_pattern == 1 or panel_pattern == 4:
				panel_material = &"glass_mid"
			elif panel_pattern == 2:
				panel_material = &"glass_light"
			_add_box(
				parent,
				"TowerGlassPanel_%02d_%02d" % [panel_column, panel_row],
				Vector3(-7.6 + float(panel_column) * 1.5, 1.7 + float(panel_row) * 1.75, 1.5),
				Vector3(1.3, 1.55, 0.05),
				panel_material
			)

	for column_index: int in range(6):
		var column_x: float = -8.35 + float(column_index) * 1.5
		_add_box(
			parent,
			"TowerFrontMullion_%02d" % column_index,
			Vector3(column_x, 7.1, 1.52),
			Vector3(0.11, 12.6, 0.12),
			&"metal_dark"
		)
	for row_index: int in range(7):
		var row_y: float = 1.65 + float(row_index) * 1.75
		_add_box(
			parent,
			"TowerFrontBand_%02d" % row_index,
			Vector3(-4.8, row_y, 1.54),
			Vector3(7.7, 0.11, 0.12),
			&"metal_dark"
		)
		_add_box(
			parent,
			"InteriorFloor_%02d" % row_index,
			Vector3(-4.7, row_y + 0.48, 1.15),
			Vector3(7.2, 0.1, 0.22),
			&"warm"
		)

	# Narrow orange vertical bay between tower and research wing.
	_add_box(parent, "OrangeCore", Vector3(0.2, 6.9, 0.2), Vector3(1.25, 13.0, 2.5), &"orange_dark")
	_add_box(parent, "OrangeFace", Vector3(0.2, 7.0, 2.0), Vector3(1.1, 13.2, 0.42), &"orange")
	_add_box(parent, "OrangePierLeft", Vector3(-0.25, 7.0, 1.95), Vector3(0.35, 13.2, 0.5), &"orange")
	_add_box(parent, "OrangePierRight", Vector3(0.65, 7.0, 1.95), Vector3(0.35, 13.2, 0.5), &"orange")
	_add_box(parent, "OrangeHeader", Vector3(0.2, 13.5, 1.95), Vector3(1.25, 0.55, 0.55), &"orange")

	_add_box(parent, "TowerRoof", Vector3(-5.0, 15.1, -3.2), Vector3(9.4, 0.4, 8.4), &"roof")
	_add_box(parent, "TowerRoofParapetFront", Vector3(-5.0, 15.45, 0.8), Vector3(8.6, 0.5, 0.55), &"cream")
	_add_box(parent, "TowerRoofParapetBack", Vector3(-5.0, 15.45, -7.0), Vector3(8.6, 0.5, 0.55), &"cream")
	_add_box(parent, "TowerRoofParapetLeft", Vector3(-9.4, 15.45, -3.1), Vector3(0.55, 0.5, 7.8), &"cream")
	_add_box(parent, "TowerRoofParapetRight", Vector3(-0.6, 15.45, -3.1), Vector3(0.55, 0.5, 7.8), &"cream")
	_add_box(parent, "TowerRoofInset", Vector3(-5.0, 15.35, -3.2), Vector3(7.2, 0.16, 6.2), &"metal_dark")
	_add_box(parent, "TowerRoofDeck", Vector3(-5.0, 15.4, -3.2), Vector3(6.0, 0.1, 4.8), &"concrete_light")


func _create_research_block(parent: Node3D) -> void:
	var research_root := Node3D.new()
	research_root.name = "ResearchOffset"
	research_root.position = RESEARCH_OFFSET
	parent.add_child(research_root)
	_add_box(research_root, "ResearchBody", Vector3(6.8, 4.6, -3.2), Vector3(12.8, 8.8, 10.5), &"charcoal")
	_add_box(research_root, "ResearchFrontGlass", Vector3(6.8, 4.1, 2.1), Vector3(12.0, 4.2, 0.18), &"glass")
	_add_box(research_root, "ResearchSideGlass", Vector3(13.15, 4.1, -3.0), Vector3(0.18, 4.2, 9.0), &"glass_dark")
	_add_box(research_root, "ResearchFrontLowerBand", Vector3(6.8, 2.2, 2.22), Vector3(12.4, 0.4, 0.32), &"metal_dark")
	_add_box(research_root, "ResearchFrontUpperBand", Vector3(6.8, 6.0, 2.22), Vector3(12.4, 0.4, 0.32), &"metal_dark")
	for column_index: int in range(7):
		_add_box(
			research_root,
			"ResearchMullion_%02d" % column_index,
			Vector3(1.2 + float(column_index) * 1.65, 4.1, 2.22),
			Vector3(0.12, 4.3, 0.12),
			&"metal_dark"
		)
	for row_index: int in range(2):
		_add_box(
			research_root,
			"ResearchWarmBand_%02d" % row_index,
			Vector3(6.8, 3.1 + float(row_index) * 2.0, 1.95),
			Vector3(11.4, 0.08, 0.12),
			&"warm"
		)
	_add_box(research_root, "ResearchRoof", Vector3(6.8, 9.15, -3.2), Vector3(13.6, 0.45, 11.2), &"roof")
	_add_box(research_root, "ResearchParapetFront", Vector3(6.8, 9.5, 2.05), Vector3(13.4, 0.55, 0.55), &"cream")
	_add_box(research_root, "ResearchParapetRight", Vector3(13.3, 9.5, -3.2), Vector3(0.55, 0.55, 10.8), &"cream")
	_add_box(research_root, "ResearchParapetBack", Vector3(6.8, 9.5, -8.5), Vector3(13.4, 0.55, 0.55), &"cream")
	_add_box(research_root, "ResearchParapetLeft", Vector3(0.5, 9.5, -3.2), Vector3(0.55, 0.55, 10.8), &"cream")
	_add_box(research_root, "ResearchCreamFrontEdge", Vector3(12.5, 4.2, 2.15), Vector3(1.0, 6.5, 0.7), &"cream")
	_add_box(research_root, "ResearchCreamSideEdge", Vector3(13.3, 4.2, 0.5), Vector3(0.7, 6.5, 3.5), &"cream")


func _create_right_wing(parent: Node3D) -> void:
	var wing_root := Node3D.new()
	wing_root.name = "RightWingOffset"
	wing_root.position.z = -8.8
	parent.add_child(wing_root)
	_add_box(wing_root, "RightWingBody", Vector3(13.5, 3.3, -0.8), Vector3(8.4, 6.2, 11.0), &"charcoal")
	_add_box(wing_root, "RightWingFrontGlass", Vector3(13.5, 3.15, 4.75), Vector3(7.0, 4.4, 0.18), &"glass")
	_add_box(wing_root, "RightWingSideGlass", Vector3(17.75, 3.15, -0.8), Vector3(0.18, 4.4, 10.2), &"glass_mid")
	_add_box(wing_root, "RightWingRoof", Vector3(13.5, 6.55, -0.8), Vector3(9.0, 0.42, 11.6), &"roof")

	# Thick cream U-frame around front and side glass.
	_add_box(wing_root, "WingFrameLeft", Vector3(9.7, 3.3, 4.9), Vector3(1.2, 6.6, 1.2), &"cream")
	_add_box(wing_root, "WingFrameRight", Vector3(17.3, 3.3, 4.9), Vector3(1.2, 6.6, 1.2), &"cream")
	_add_box(wing_root, "WingFrameTop", Vector3(13.5, 6.4, 4.9), Vector3(8.8, 1.1, 1.2), &"cream")
	_add_box(wing_root, "WingSideFrameTop", Vector3(18.0, 6.4, -0.8), Vector3(1.1, 1.1, 11.4), &"cream")
	_add_box(wing_root, "WingSideFrameEnd", Vector3(18.0, 3.3, -6.0), Vector3(1.1, 6.6, 1.2), &"cream")
	_add_box(wing_root, "WingSideFrameFront", Vector3(18.0, 3.3, 4.9), Vector3(1.1, 6.6, 1.2), &"cream")
	_add_box(wing_root, "WingCreamBase", Vector3(13.5, 0.5, 4.9), Vector3(8.6, 0.6, 1.0), &"cream_deep")
	_add_box(wing_root, "WingRoofParapetFront", Vector3(13.5, 6.9, 4.7), Vector3(9.0, 0.4, 0.7), &"cream")
	_add_box(wing_root, "WingRoofParapetSide", Vector3(17.9, 6.9, -0.8), Vector3(0.7, 0.4, 11.2), &"cream")

	for front_column: int in range(5):
		_add_box(
			wing_root,
			"WingFrontMullion_%02d" % front_column,
			Vector3(10.5 + float(front_column) * 1.5, 3.15, 4.86),
			Vector3(0.12, 4.5, 0.12),
			&"metal_dark"
		)
	_add_box(wing_root, "WingFrontBand", Vector3(13.5, 3.15, 4.88), Vector3(7.0, 0.12, 0.12), &"metal_dark")
	for side_column: int in range(6):
		_add_box(
			wing_root,
			"WingSideMullion_%02d" % side_column,
			Vector3(17.86, 3.15, -5.2 + float(side_column) * 1.7),
			Vector3(0.12, 4.5, 0.12),
			&"metal_dark"
		)

	_add_box(wing_root, "SkylightBase", Vector3(13.8, 6.95, -1.8), Vector3(3.0, 0.32, 2.4), &"cream_deep")
	_add_outline(wing_root, "SkylightGlow", Vector3(13.8, 7.15, -1.8), Vector2(2.2, 1.6), &"cyan", 0.1)
	_add_box(wing_root, "SkylightCenter", Vector3(13.8, 7.14, -1.8), Vector3(1.8, 0.1, 1.15), &"glass_light")
	_add_box(wing_root, "WingDoor", Vector3(10.1, 1.5, 4.95), Vector3(1.1, 2.35, 0.14), &"glass")
	_add_box(wing_root, "WingCanopy", Vector3(10.1, 3.0, 5.5), Vector3(2.8, 0.32, 1.35), &"metal_dark")


func _create_roof_equipment(parent: Node3D) -> void:
	var equipment_root := Node3D.new()
	equipment_root.name = "RoofEquipmentOffset"
	equipment_root.position = RESEARCH_OFFSET
	parent.add_child(equipment_root)
	_add_box(equipment_root, "HvacPlatform", Vector3(6.2, 9.45, -3.8), Vector3(8.8, 0.45, 6.2), &"metal")
	_add_box(equipment_root, "HvacServiceCore", Vector3(5.8, 9.85, -3.8), Vector3(6.5, 0.4, 2.6), &"metal_dark")
	for vent_index: int in range(3):
		var vent_x: float = 3.4 + float(vent_index) * 2.55
		_add_cylinder(
			equipment_root,
			"CoolingRing_%02d" % vent_index,
			Vector3(vent_x, 10.35, -2.5),
			0.88,
			0.65,
			&"metal",
			16
		)
		_add_cylinder(
			equipment_root,
			"CoolingFan_%02d" % vent_index,
			Vector3(vent_x, 10.7, -2.5),
			0.56,
			0.12,
			&"metal_dark",
			12
		)
		for blade_index: int in range(4):
			_add_box(
				equipment_root,
				"CoolingBlade_%02d_%02d" % [vent_index, blade_index],
				Vector3(vent_x, 10.8, -2.5),
				Vector3(0.88, 0.08, 0.12),
				&"metal_dark",
				float(blade_index) * 45.0
			)
	for duct_index: int in range(4):
		_add_box(
			equipment_root,
			"RoofDuct_%02d" % duct_index,
			Vector3(3.2 + float(duct_index) * 1.85, 9.9, -5.0),
			Vector3(1.3, 0.6, 0.75),
			&"metal"
		)


func _create_entry(parent: Node3D) -> void:
	_add_box(parent, "EntryVestibule", Vector3(0.2, 1.75, 2.6), Vector3(1.3, 2.9, 1.7), &"orange_dark")
	_add_box(parent, "EntryDoor", Vector3(0.2, 1.5, 3.5), Vector3(0.95, 2.3, 0.14), &"glass")
	_add_box(parent, "EntryCanopy", Vector3(0.2, 3.4, 3.95), Vector3(2.5, 0.32, 1.45), &"metal_dark")
	var entry_light := OmniLight3D.new()
	entry_light.name = "EntryGlow"
	entry_light.position = Vector3(0.2, 1.15, 5.0)
	entry_light.light_color = Color("ee8845")
	entry_light.light_energy = 2.6
	entry_light.omni_range = 7.0
	entry_light.light_size = 1.8
	entry_light.shadow_enabled = false
	parent.add_child(entry_light)
	_light_count += 1


func _create_landscaping() -> void:
	var landscaping := Node3D.new()
	landscaping.name = "Landscaping"
	add_child(landscaping)
	var ground_patches: Array[Vector4] = [
		Vector4(-19.0, -21.5, 12.0, 8.0),
		Vector4(13.0, -21.5, 15.0, 8.0),
		Vector4(18.5, 9.5, 7.5, 5.5),
		Vector4(-8.5, 12.0, 10.0, 3.5),
		Vector4(10.0, -14.0, 8.0, 5.0),
	]
	for patch_index: int in range(ground_patches.size()):
		var patch: Vector4 = ground_patches[patch_index]
		_add_box(
			landscaping,
			"GrassPatch_%02d" % patch_index,
			Vector3(patch.x, -0.39, patch.y),
			Vector3(patch.z, 0.05, patch.w),
			&"grass_mid",
			-8.0 + float(patch_index) * 5.0
		)

	var hedge_lines: Array[Vector4] = [
		Vector4(-17.5, -25.0, 18.0, 0.7),
		Vector4(-16.5, 12.5, 16.0, 0.7),
		Vector4(9.0, 12.5, 22.0, 0.7),
		Vector4(21.5, -8.0, 0.7, 14.0),
		Vector4(-25.0, -10.0, 0.7, 14.0),
		Vector4(-11.0, -8.0, 9.0, 0.7),
		Vector4(10.0, 10.2, 14.0, 0.7),
		Vector4(-22.5, 8.5, 8.0, 0.65),
	]
	for hedge_index: int in range(hedge_lines.size()):
		var hedge: Vector4 = hedge_lines[hedge_index]
		_add_box(
			landscaping,
			"Hedge_%02d" % hedge_index,
			Vector3(hedge.x, 0.4, hedge.y),
			Vector3(hedge.z, 0.8, hedge.w),
			&"grass_dark"
		)

	# Front sidewalk tree strip matches the reference road edge.
	_add_box(landscaping, "FrontSidewalkStrip", Vector3(-2.0, 0.22, 17.6), Vector3(48.0, 0.4, 1.6), &"grass_dark")
	for hedge_slot: int in range(10):
		_add_box(
			landscaping,
			"FrontHedgeSlot_%02d" % hedge_slot,
			Vector3(-24.0 + float(hedge_slot) * 5.0, 0.45, 17.6),
			Vector3(3.2, 0.7, 1.1),
			&"grass_dark"
		)

	var tree_positions: Array[Vector3] = [
		Vector3(-23.5, 0.0, -23.5),
		Vector3(-17.5, 0.0, -23.3),
		Vector3(-10.0, 0.0, -23.6),
		Vector3(-2.0, 0.0, -23.4),
		Vector3(7.0, 0.0, -23.2),
		Vector3(15.5, 0.0, -23.4),
		Vector3(20.5, 0.0, -19.5),
		Vector3(20.8, 0.0, -12.0),
		Vector3(20.5, 0.0, -3.0),
		Vector3(20.2, 0.0, 6.0),
		Vector3(20.0, 0.0, 12.0),
		Vector3(12.5, 0.0, 11.5),
		Vector3(5.5, 0.0, 11.3),
		Vector3(-2.5, 0.0, 11.2),
		Vector3(-14.5, 0.0, 11.8),
		Vector3(-23.5, 0.0, 11.5),
		Vector3(-24.0, 0.0, 4.5),
		Vector3(-24.0, 0.0, -2.5),
		Vector3(-23.5, 0.0, -10.0),
		Vector3(-16.0, 0.0, -17.5),
		Vector3(14.5, 0.0, -16.5),
		Vector3(-12.0, 0.0, -10.0),
		Vector3(20.0, -0.1, 17.6),
		Vector3(14.0, -0.1, 17.6),
		Vector3(8.0, -0.1, 17.6),
		Vector3(2.0, -0.1, 17.6),
		Vector3(-4.0, -0.1, 17.6),
		Vector3(-10.0, -0.1, 17.6),
		Vector3(-16.0, -0.1, 17.6),
		Vector3(-22.0, -0.1, 17.6),
	]
	for tree_index: int in range(tree_positions.size()):
		var tree_scale: float = 0.88 + float(tree_index % 4) * 0.07
		if tree_index % 3 == 0:
			_create_round_tree(
				landscaping,
				"Tree_%02d" % tree_index,
				tree_positions[tree_index],
				tree_scale
			)
		else:
			_create_tree(
				landscaping,
				"Tree_%02d" % tree_index,
				tree_positions[tree_index],
				tree_scale
			)

	_create_tree(landscaping, "PlanterTreeLeft", Vector3(-4.8, 0.65, 5.8), 0.62)
	_create_tree(landscaping, "PlanterTreeRight", Vector3(5.2, 0.65, 6.2), 0.62)
	_create_round_tree(landscaping, "PlazaTreeA", Vector3(9.0, 0.65, 5.0), 0.58)
	_create_tree(landscaping, "PlazaTreeB", Vector3(13.5, 0.65, 5.2), 0.6)
	_create_round_tree(landscaping, "LoopTreeA", Vector3(-9.0, 0.6, 15.8), 0.65)
	_create_tree(landscaping, "LoopTreeB", Vector3(6.5, 0.6, 15.8), 0.68)


func _create_site_lights() -> void:
	var lighting := Node3D.new()
	lighting.name = "SiteLights"
	add_child(lighting)

	var light_positions: Array[Vector3] = [
		Vector3(-24.0, 0.0, 17.2),
		Vector3(-16.0, 0.0, 17.2),
		Vector3(-8.0, 0.0, 17.2),
		Vector3(0.0, 0.0, 17.2),
		Vector3(8.0, 0.0, 17.2),
		Vector3(16.0, 0.0, 17.2),
		Vector3(21.2, 0.0, 10.0),
		Vector3(21.2, 0.0, 0.0),
		Vector3(-21.0, 0.0, -5.0),
		Vector3(-12.0, 0.0, 11.0),
	]
	for light_index: int in range(light_positions.size()):
		_create_street_light(lighting, "SiteLight_%02d" % light_index, light_positions[light_index])


func _create_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "GameplayCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	camera.near = 0.5
	camera.far = 140.0
	camera.position = CAMERA_POSITION
	add_child(camera)
	camera.look_at(CAMERA_TARGET, Vector3.UP)
	camera.current = true

	var attributes := CameraAttributesPractical.new()
	attributes.dof_blur_amount = 0.018
	attributes.dof_blur_far_enabled = true
	attributes.dof_blur_far_distance = 83.0
	attributes.dof_blur_far_transition = 18.0
	camera.attributes = attributes


func _create_planter(parent: Node3D, name_value: String, position_value: Vector3, size_value: Vector3) -> void:
	_add_box(parent, "%sBase" % name_value, position_value, size_value, &"concrete_light")
	_add_box(
		parent,
		"%sSoil" % name_value,
		position_value + Vector3(0.0, size_value.y * 0.55, 0.0),
		Vector3(size_value.x - 0.45, 0.18, size_value.z - 0.45),
		&"grass_dark"
	)


func _create_tree(parent: Node3D, name_value: String, position_value: Vector3, scale_value: float) -> void:
	var tree_root := Node3D.new()
	tree_root.name = name_value
	tree_root.position = position_value
	tree_root.scale = Vector3.ONE * scale_value
	parent.add_child(tree_root)
	_add_cylinder(tree_root, "Trunk", Vector3(0.0, 1.15, 0.0), 0.28, 2.3, &"trunk", 8)
	_add_cone(tree_root, "LowerCrown", Vector3(0.0, 2.7, 0.0), 1.28, 2.7, &"tree_a", 8)
	_add_cone(tree_root, "MiddleCrown", Vector3(0.0, 3.65, 0.0), 1.02, 2.3, &"tree_b", 8)
	_add_cone(tree_root, "UpperCrown", Vector3(0.0, 4.45, 0.0), 0.72, 1.8, &"tree_a", 8)


func _create_round_tree(parent: Node3D, name_value: String, position_value: Vector3, scale_value: float) -> void:
	var tree_root := Node3D.new()
	tree_root.name = name_value
	tree_root.position = position_value
	tree_root.scale = Vector3.ONE * scale_value
	parent.add_child(tree_root)
	_add_cylinder(tree_root, "Trunk", Vector3(0.0, 1.1, 0.0), 0.3, 2.2, &"trunk", 8)
	_add_sphere(tree_root, "CrownCenter", Vector3(0.0, 3.35, 0.0), 1.35, 1.05, &"tree_a")
	_add_sphere(tree_root, "CrownLeft", Vector3(-0.72, 3.15, 0.1), 0.95, 1.0, &"tree_b")
	_add_sphere(tree_root, "CrownRight", Vector3(0.75, 3.2, -0.1), 0.9, 1.08, &"tree_a")
	_add_sphere(tree_root, "CrownTop", Vector3(0.05, 4.25, 0.0), 0.85, 1.0, &"tree_b")


func _create_car(
	parent: Node3D,
	name_value: String,
	position_value: Vector3,
	rotation_y_degrees: float,
	material_key: StringName
) -> void:
	var car_root := Node3D.new()
	car_root.name = name_value
	car_root.position = position_value
	car_root.rotation_degrees.y = rotation_y_degrees
	parent.add_child(car_root)
	_add_box(car_root, "Body", Vector3(0.0, 0.0, 0.0), Vector3(1.85, 0.55, 3.5), material_key)
	_add_box(car_root, "Cabin", Vector3(0.0, 0.48, -0.15), Vector3(1.55, 0.62, 1.8), &"glass_dark")
	_add_box(car_root, "FrontLight", Vector3(0.0, 0.05, 1.78), Vector3(1.25, 0.16, 0.08), &"warm")
	for wheel_x: float in [-0.94, 0.94]:
		for wheel_z: float in [-1.08, 1.08]:
			_add_box(
				car_root,
				"Wheel_%s_%s" % [str(wheel_x), str(wheel_z)],
				Vector3(wheel_x, -0.16, wheel_z),
				Vector3(0.18, 0.38, 0.58),
				&"tire"
			)


func _create_street_light(parent: Node3D, name_value: String, position_value: Vector3) -> void:
	var light_root := Node3D.new()
	light_root.name = name_value
	light_root.position = position_value
	parent.add_child(light_root)
	_add_cylinder(light_root, "Post", Vector3(0.0, 1.8, 0.0), 0.09, 3.6, &"metal", 8)
	_add_box(light_root, "Arm", Vector3(0.38, 3.55, 0.0), Vector3(0.85, 0.1, 0.1), &"metal")
	_add_box(light_root, "Fixture", Vector3(0.78, 3.47, 0.0), Vector3(0.42, 0.16, 0.28), &"warm")
	var light := OmniLight3D.new()
	light.name = "WarmPool"
	light.position = Vector3(0.78, 3.25, 0.0)
	light.light_color = Color("ffc98c")
	light.light_energy = 5.2
	light.omni_range = 7.8
	light.light_size = 1.1
	light.shadow_enabled = false
	light_root.add_child(light)
	_light_count += 1


func _add_outline(
	parent: Node3D,
	name_value: String,
	position_value: Vector3,
	size_value: Vector2,
	material_key: StringName,
	thickness: float
) -> void:
	_add_box(
		parent,
		"%sFront" % name_value,
		position_value + Vector3(0.0, 0.0, size_value.y * 0.5),
		Vector3(size_value.x, 0.08, thickness),
		material_key
	)
	_add_box(
		parent,
		"%sBack" % name_value,
		position_value - Vector3(0.0, 0.0, size_value.y * 0.5),
		Vector3(size_value.x, 0.08, thickness),
		material_key
	)
	_add_box(
		parent,
		"%sLeft" % name_value,
		position_value - Vector3(size_value.x * 0.5, 0.0, 0.0),
		Vector3(thickness, 0.08, size_value.y),
		material_key
	)
	_add_box(
		parent,
		"%sRight" % name_value,
		position_value + Vector3(size_value.x * 0.5, 0.0, 0.0),
		Vector3(thickness, 0.08, size_value.y),
		material_key
	)


func _add_box(
	parent: Node3D,
	name_value: String,
	position_value: Vector3,
	size_value: Vector3,
	material_key: StringName,
	rotation_y_degrees: float = 0.0
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var instance := MeshInstance3D.new()
	instance.name = name_value
	instance.mesh = mesh
	instance.material_override = _materials[material_key]
	instance.position = position_value
	instance.rotation_degrees.y = rotation_y_degrees
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	_mesh_count += 1
	return instance


func _add_cylinder(
	parent: Node3D,
	name_value: String,
	position_value: Vector3,
	radius: float,
	height: float,
	material_key: StringName,
	radial_segments: int
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh.rings = 1
	var instance := MeshInstance3D.new()
	instance.name = name_value
	instance.mesh = mesh
	instance.material_override = _materials[material_key]
	instance.position = position_value
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	_mesh_count += 1
	return instance


func _add_cone(
	parent: Node3D,
	name_value: String,
	position_value: Vector3,
	radius: float,
	height: float,
	material_key: StringName,
	radial_segments: int
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh.rings = 1
	var instance := MeshInstance3D.new()
	instance.name = name_value
	instance.mesh = mesh
	instance.material_override = _materials[material_key]
	instance.position = position_value
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	_mesh_count += 1
	return instance


func _add_sphere(
	parent: Node3D,
	name_value: String,
	position_value: Vector3,
	radius: float,
	height_scale: float,
	material_key: StringName
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * height_scale
	mesh.radial_segments = 8
	mesh.rings = 4
	var instance := MeshInstance3D.new()
	instance.name = name_value
	instance.mesh = mesh
	instance.material_override = _materials[material_key]
	instance.position = position_value
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	_mesh_count += 1
	return instance


func _bake_scene() -> void:
	var baked_root := Node3D.new()
	baked_root.name = "CampusBlockout"
	var source_children: Array[Node] = []
	for child: Node in get_children():
		source_children.append(child)
	for child: Node in source_children:
		remove_child(child)
		baked_root.add_child(child)
		_assign_scene_owner(child, baked_root)
	var packed_scene := PackedScene.new()
	var pack_error: Error = packed_scene.pack(baked_root)
	if pack_error != OK:
		baked_root.free()
		_fail("Could not pack editable campus scene: error %d." % pack_error)
		return
	var save_error: Error = ResourceSaver.save(packed_scene, _bake_output_path)
	if save_error != OK:
		baked_root.free()
		_fail("Could not save editable campus scene '%s': error %d." % [_bake_output_path, save_error])
		return
	var scene_file := FileAccess.open(_bake_output_path, FileAccess.READ)
	if scene_file == null or scene_file.get_length() < 10000:
		baked_root.free()
		_fail("Editable campus scene is missing or implausibly small: %s." % _bake_output_path)
		return
	print(
		"CAMPUS_BLOCKOUT_BAKE_SUCCESS nodes=%d bytes=%d path=%s"
		% [baked_root.find_children("*", "Node", true, false).size() + 1, scene_file.get_length(), _bake_output_path]
	)
	baked_root.free()
	get_tree().quit(0)


func _assign_scene_owner(node: Node, scene_owner: Node) -> void:
	node.owner = scene_owner
	for child: Node in node.get_children():
		_assign_scene_owner(child, scene_owner)


func _capture_blockout() -> void:
	var output_directory: String = _output_path.get_base_dir()
	var make_error: Error = DirAccess.make_dir_recursive_absolute(output_directory)
	if make_error != OK:
		_fail("Could not create campus evidence directory '%s': error %d." % [output_directory, make_error])
		return
	for frame_index: int in range(18):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Campus blockout viewport returned an empty image.")
		return
	if image.get_size() != OUTPUT_RESOLUTION:
		_fail("Campus blockout capture must be %s, got %s." % [OUTPUT_RESOLUTION, image.get_size()])
		return
	var save_error: Error = image.save_png(_output_path)
	if save_error != OK:
		_fail("Could not save campus blockout PNG '%s': error %d." % [_output_path, save_error])
		return
	var output_file := FileAccess.open(_output_path, FileAccess.READ)
	if output_file == null or output_file.get_length() < 40000:
		_fail("Campus blockout PNG is missing or implausibly small: %s." % _output_path)
		return
	if not _save_reference_comparison(image):
		return
	print(
		"CAMPUS_BLOCKOUT_CAPTURE_SUCCESS size=%s bytes=%d path=%s"
		% [image.get_size(), output_file.get_length(), _output_path]
	)
	get_tree().quit(0)


func _save_reference_comparison(render_image: Image) -> bool:
	var project_root: String = ProjectSettings.globalize_path("res://")
	var reference_path: String = project_root.path_join(REFERENCE_IMAGE_RELATIVE_PATH).simplify_path()
	if not FileAccess.file_exists(reference_path):
		_fail("Campus blockout reference image is missing: %s." % reference_path)
		return false
	var reference_image: Image = Image.load_from_file(reference_path)
	if reference_image == null or reference_image.is_empty():
		_fail("Campus blockout reference image could not be loaded: %s." % reference_path)
		return false
	var reference_half: Image = reference_image.duplicate()
	var render_half: Image = render_image.duplicate()
	reference_half.convert(Image.FORMAT_RGBA8)
	render_half.convert(Image.FORMAT_RGBA8)
	reference_half.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	render_half.resize(960, 540, Image.INTERPOLATE_LANCZOS)
	var comparison_image := Image.create_empty(1920, 540, false, Image.FORMAT_RGBA8)
	comparison_image.fill(Color("0d2027"))
	var half_rect := Rect2i(Vector2i.ZERO, Vector2i(960, 540))
	comparison_image.blit_rect(reference_half, half_rect, Vector2i.ZERO)
	comparison_image.blit_rect(render_half, half_rect, Vector2i(960, 0))
	var comparison_path: String = "%s_comparison.png" % _output_path.get_basename()
	var comparison_error: Error = comparison_image.save_png(comparison_path)
	if comparison_error != OK:
		_fail("Could not save campus comparison PNG '%s': error %d." % [comparison_path, comparison_error])
		return false
	var comparison_file := FileAccess.open(comparison_path, FileAccess.READ)
	if comparison_file == null or comparison_file.get_length() < 40000:
		_fail("Campus comparison PNG is missing or implausibly small: %s." % comparison_path)
		return false
	print(
		"CAMPUS_BLOCKOUT_COMPARISON_SUCCESS size=%s bytes=%d path=%s"
		% [comparison_image.get_size(), comparison_file.get_length(), comparison_path]
	)
	return true


func _fail(message: String) -> void:
	if _fatal_triggered:
		return
	_fatal_triggered = true
	push_error("CAMPUS_BLOCKOUT_ERROR: %s" % message)
	printerr("CAMPUS_BLOCKOUT_ERROR: %s" % message)
	get_tree().quit(2)
