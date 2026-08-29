class_name CampusVisualMapping
extends RefCounted

const RESEARCH_PROJECT_ID: StringName = &"project.research.frontier_model"
const BURST_CONTRACT_ID: StringName = &"contract.compute.burst"
const NORTHSTAR_ID: StringName = &"competitor.northstar"
const RELEASED_STAGE_ID: StringName = &"competitor_stage.northstar.flagship_released"
const FLAGSHIP_MODEL_ID: StringName = &"model.competitor.northstar.flagship"
const RESEARCH_PLOT_ID: StringName = &"plot.campus.research"
const HQ_SITE_ID: StringName = &"site.company.sf_campus"
const EMPTY_PLOT_STATE: StringName = &"site_plot_state.empty_plot"
const COMPACT_LAB_STATE: StringName = &"site_plot_state.compact_lab"
const LAB_STAGE_1_PATH: String = "res://scenes/lab_stage_1.tscn"
const LAB_STAGE_2_PATH: String = "res://scenes/lab_stage_2.tscn"

var laboratory_scene_path: String = ""
var compute_link_visible: bool = false
var competitor_release_visible: bool = false
var competitor_presentation_text: String = ""


static func from_state(state: GameState) -> CampusVisualMapping:
	var mapping: CampusVisualMapping = CampusVisualMapping.new()
	if state == null:
		return mapping
	var plot_state: StringName = _research_plot_state(state)
	if plot_state == EMPTY_PLOT_STATE or plot_state == &"":
		mapping.laboratory_scene_path = ""
	elif _research_project_completed(state):
		mapping.laboratory_scene_path = LAB_STAGE_2_PATH
	else:
		mapping.laboratory_scene_path = LAB_STAGE_1_PATH
	mapping.compute_link_visible = _burst_contract_present(state)
	mapping.competitor_release_visible = _northstar_flagship_released(state)
	mapping.competitor_presentation_text = _competitor_text(state, mapping.competitor_release_visible)
	return mapping


func has_empty_plot() -> bool:
	return laboratory_scene_path.is_empty()


func uses_developed_laboratory() -> bool:
	return laboratory_scene_path == LAB_STAGE_2_PATH


func uses_compact_laboratory() -> bool:
	return laboratory_scene_path == LAB_STAGE_1_PATH


static func _research_plot_state(state: GameState) -> StringName:
	if state.company == null:
		return &""
	if not state.company.sites.has(HQ_SITE_ID):
		return &""
	var site: SiteState = state.company.sites[HQ_SITE_ID]
	if site == null or not site.site_plots.has(RESEARCH_PLOT_ID):
		return &""
	var plot: SitePlotState = site.site_plots[RESEARCH_PLOT_ID]
	if plot == null:
		return &""
	return plot.state_id


static func _research_project_completed(state: GameState) -> bool:
	if state.company == null:
		return false
	if not state.company.projects.has(RESEARCH_PROJECT_ID):
		return false
	var project: ProjectState = state.company.projects[RESEARCH_PROJECT_ID]
	if project == null:
		return false
	return project.status_id == ProjectState.STATUS_COMPLETED


static func _burst_contract_present(state: GameState) -> bool:
	if state.company == null:
		return false
	return state.company.contracts.has(BURST_CONTRACT_ID)


static func _northstar_flagship_released(state: GameState) -> bool:
	if state.world == null:
		return false
	if not state.world.competitors.has(NORTHSTAR_ID):
		return false
	var competitor: CompetitorState = state.world.competitors[NORTHSTAR_ID]
	if competitor == null:
		return false
	return competitor.stage_id == RELEASED_STAGE_ID


static func _competitor_text(state: GameState, released: bool) -> String:
	if not released:
		return ""
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Northstar Flagship")
	lines.append("Released")
	if state.world != null and state.world.models.has(FLAGSHIP_MODEL_ID):
		var model: ModelState = state.world.models[FLAGSHIP_MODEL_ID]
		if model != null and model.evaluations != null:
			lines.append("Coding %d" % model.evaluations.coding_evaluation_points)
			lines.append("Reasoning %d" % model.evaluations.reasoning_evaluation_points)
			lines.append("Efficiency %d" % model.evaluations.efficiency_evaluation_points)
	return "\n".join(lines)
