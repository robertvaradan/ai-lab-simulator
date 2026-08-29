class_name CampusVisualMapping
extends RefCounted

const RESEARCH_PROJECT_ID: StringName = &"project.research.frontier_model"
const BURST_CONTRACT_ID: StringName = &"contract.compute.burst"
const NORTHSTAR_ID: StringName = &"competitor.northstar"
const RELEASED_STAGE_ID: StringName = &"competitor_stage.northstar.flagship_released"
const FLAGSHIP_MODEL_ID: StringName = &"model.competitor.northstar.flagship"
const LAB_STAGE_1_PATH: String = "res://scenes/lab_stage_1.tscn"
const LAB_STAGE_2_PATH: String = "res://scenes/lab_stage_2.tscn"

var laboratory_scene_path: String = LAB_STAGE_1_PATH
var compute_link_visible: bool = false
var competitor_release_visible: bool = false
var competitor_presentation_text: String = ""


static func from_state(state: GameState) -> CampusVisualMapping:
	var mapping: CampusVisualMapping = CampusVisualMapping.new()
	if state == null:
		return mapping
	if _research_project_completed(state):
		mapping.laboratory_scene_path = LAB_STAGE_2_PATH
	mapping.compute_link_visible = _burst_contract_present(state)
	mapping.competitor_release_visible = _northstar_flagship_released(state)
	mapping.competitor_presentation_text = _competitor_text(state, mapping.competitor_release_visible)
	return mapping


func uses_developed_laboratory() -> bool:
	return laboratory_scene_path == LAB_STAGE_2_PATH


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
