class_name CampaignSessionState
extends RefCounted

var staged_project_ids: Dictionary[StringName, bool] = {}
var unlocked_skill_ids: Dictionary[StringName, bool] = {}
var research_points: int = 0
var awarded_research_project_ids: Dictionary[StringName, bool] = {}
var active_view_id: StringName = CampaignCatalog.VIEW_CAMPUS
var active_world_id: StringName = CampaignCatalog.WORLD_HQ
var failed: bool = false
var fail_reason_id: StringName = &""
var abandon_pending: bool = false


func _init() -> void:
	pass


func has_skill(skill_id: StringName) -> bool:
	return unlocked_skill_ids.has(skill_id) and unlocked_skill_ids[skill_id]


func has_staged_project(project_id: StringName) -> bool:
	return staged_project_ids.has(project_id) and staged_project_ids[project_id]
