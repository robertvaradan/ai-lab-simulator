class_name CampaignSessionState
extends RefCounted

var staged_project_ids: Dictionary[StringName, bool] = {}
var unlocked_skill_ids: Dictionary[StringName, bool] = {}
var unlocked_tech_ids: Dictionary[StringName, bool] = {}
var skill_unlock_month_by_id: Dictionary[StringName, int] = {}
var active_view_id: StringName = CampaignCatalog.VIEW_CAMPUS
var active_world_id: StringName = CampaignCatalog.WORLD_HQ
var failed: bool = false
var fail_reason_id: StringName = &""
var abandon_pending: bool = false


func _init() -> void:
	pass


func has_skill(skill_id: StringName) -> bool:
	return unlocked_skill_ids.has(skill_id) and unlocked_skill_ids[skill_id]


func has_tech(tech_id: StringName) -> bool:
	return unlocked_tech_ids.has(tech_id) and unlocked_tech_ids[tech_id]


func has_staged_project(project_id: StringName) -> bool:
	return staged_project_ids.has(project_id) and staged_project_ids[project_id]


func unlocked_skill_in_month(month_step_index: int) -> bool:
	for skill_id: StringName in skill_unlock_month_by_id:
		if skill_unlock_month_by_id[skill_id] == month_step_index:
			return true
	return false
