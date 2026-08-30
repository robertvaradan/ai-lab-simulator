extends Node

const CAMPAIGN_SCENE_PATH: String = "res://scenes/campaign.tscn"
const OUTPUT_ROOT_RELATIVE: String = "evidence/panel_system"
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720)]

var _host: CampaignHost
var _output_root: String = ""
var _fatal: bool = false
var _warmup_frames: int = 8


func _ready() -> void:
	_parse_arguments()
	if _fatal:
		return
	call_deferred("_run_capture")


func _parse_arguments() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index < arguments.size():
		var argument: String = arguments[index]
		if argument == "--output-root":
			if index + 1 >= arguments.size():
				_fail("--output-root requires an absolute directory path.")
				return
			index += 1
			_output_root = arguments[index]
		elif argument == "--render-panel-system":
			pass
		else:
			_fail("Unknown panel system capture argument: %s." % argument)
			return
		index += 1
	if _output_root.is_empty():
		_output_root = ProjectSettings.globalize_path("res://") + OUTPUT_ROOT_RELATIVE
	if not _output_root.is_absolute_path():
		_fail("--output-root must be absolute: %s." % _output_root)


func _run_capture() -> void:
	DirAccess.make_dir_recursive_absolute(_output_root)
	var packed: PackedScene = load(CAMPAIGN_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Campaign scene did not load.")
		return
	_host = packed.instantiate() as CampaignHost
	if _host == null:
		_fail("Campaign scene root is not CampaignHost.")
		return
	add_child(_host)
	await get_tree().process_frame
	print("PANEL_SYSTEM_CAPTURE_SCENE_LOADED")
	for resolution: Vector2i in RESOLUTIONS:
		await _capture_resolution(resolution)
	print("PANEL_SYSTEM_CAPTURE_SUCCESS root=%s" % _output_root)
	get_tree().quit(0)


func _capture_resolution(resolution: Vector2i) -> void:
	var window: Window = get_window()
	window.mode = Window.MODE_WINDOWED
	window.size = resolution
	UiScale.apply_to_window(window)
	await _wait_frames(_warmup_frames)
	var folder: String = "%s/%dx%d" % [_output_root, resolution.x, resolution.y]
	DirAccess.make_dir_recursive_absolute(folder)
	await _capture_named(folder, "hq_base", func() -> void:
		_host.set_active_world(CampaignCatalog.WORLD_HQ)
		_host.refresh_presentation()
	)
	await _capture_named(folder, "laboratory_context", func() -> void:
		_host.set_active_world(CampaignCatalog.WORLD_HQ)
		var selectable: CampaignWorldSelectable = _host.find_child("HqLaboratorySelectable", true, false) as CampaignWorldSelectable
		if selectable == null:
			selectable = _find_selectable_by_id(&"entity.hq.laboratory")
		if selectable != null:
			_host.select_world_selectable(selectable)
		else:
			_host.get_workspace().show_context(&"entity.hq.laboratory", &"context.laboratory")
	)
	await _capture_named(folder, "plan", func() -> void:
		_host.get_workspace().open_workbench(CampaignPanelDefinition.PANEL_PLAN, CampaignPanelDefinition.TAB_PROJECTS)
	)
	await _capture_named(folder, "skill_tree", func() -> void:
		_host.get_workspace().open_workbench(CampaignPanelDefinition.PANEL_PLAN, CampaignPanelDefinition.TAB_SKILL_TREE)
	)
	await _capture_named(folder, "timeline", func() -> void:
		_host.get_workspace().open_workbench(CampaignPanelDefinition.PANEL_TIMELINE)
	)
	await _capture_named(folder, "world_map", func() -> void:
		_host.get_workspace().open_workbench(CampaignPanelDefinition.PANEL_WORLD_MAP)
	)
	await _capture_named(folder, "data_center", func() -> void:
		_host.set_active_world(CampaignCatalog.WORLD_DATA_CENTER)
	)
	await _capture_named(folder, "government", func() -> void:
		_host.set_active_world(CampaignCatalog.WORLD_GOVERNMENT)
	)
	await _capture_named(folder, "pause", func() -> void:
		_host.set_active_world(CampaignCatalog.WORLD_HQ)
		_host.get_workspace().open_modal(CampaignPanelDefinition.PANEL_PAUSE)
	)
	await _capture_named(folder, "fail_state", func() -> void:
		_host.get_workspace().back()
		_host.request_abandon()
	)
	_host.cancel_abandon()
	await _capture_named(folder, "advance_transition", func() -> void:
		var previous_load: GameStateLoadResult = MarketingScenarioFactory.create_state(_host.get_definition())
		var model: CampaignAdvanceTransitionModel = CampaignAdvanceTransitionModel.new()
		if previous_load.succeeded():
			model = CampaignAdvanceTransitionModel.compile(
				previous_load.state,
				_host.get_current_state(),
				_host.get_last_result() if _host.get_last_result() != null else _synthetic_result()
			)
		_host.get_workspace().play_advance_transition(model)
	)


func _capture_named(folder: String, name: String, setup: Callable) -> void:
	setup.call()
	await _wait_frames(_warmup_frames)
	var image: Image = get_viewport().get_texture().get_image()
	var path: String = "%s/%s.png" % [folder, name]
	var error: Error = image.save_png(path)
	if error != OK:
		_fail("Failed to save capture %s with error %d." % [path, error])
		return
	print("PANEL_SYSTEM_CAPTURE_WRITTEN path=%s" % path)


func _find_selectable_by_id(entity_id: StringName) -> CampaignWorldSelectable:
	var nodes: Array[Node] = _host.find_children("*", "Area3D", true, false)
	for node: Node in nodes:
		var selectable: CampaignWorldSelectable = node as CampaignWorldSelectable
		if selectable != null and selectable.entity_id == entity_id:
			return selectable
	return null


func _synthetic_result() -> SimulationOperationResult:
	var trace: SimulationTrace = SimulationTrace.new(&"panel_system.capture", 0)
	return SimulationOperationResult.new(
		SimulationOperationOutcome.Type.COMPLETED,
		_host.get_current_state(),
		trace,
		[]
	)


func _wait_frames(count: int) -> void:
	var remaining: int = count
	while remaining > 0:
		await get_tree().process_frame
		remaining -= 1


func _fail(message: String) -> void:
	_fatal = true
	printerr(message)
	get_tree().quit(1)
