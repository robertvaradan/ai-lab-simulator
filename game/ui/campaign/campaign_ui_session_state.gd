class_name CampaignUiSessionState
extends RefCounted

var active_workbench_id: StringName = &""
var active_tab_id: StringName = &""
var selected_entity_by_world: Dictionary[StringName, StringName] = {}
var read_timeline_ids: Dictionary[StringName, bool] = {}
var context_collapsed: bool = false
var workbench_collapsed: bool = false
var focus_restore_path: NodePath = NodePath()
var input_context: StringName = CampaignInputContext.WORLD


func _init() -> void:
	pass


func reset() -> void:
	active_workbench_id = &""
	active_tab_id = &""
	selected_entity_by_world.clear()
	read_timeline_ids.clear()
	context_collapsed = false
	workbench_collapsed = false
	focus_restore_path = NodePath()
	input_context = CampaignInputContext.WORLD


func mark_timeline_read(timeline_id: StringName) -> void:
	read_timeline_ids[timeline_id] = true


func is_timeline_read(timeline_id: StringName) -> bool:
	return read_timeline_ids.has(timeline_id) and read_timeline_ids[timeline_id]


func set_world_selection(world_id: StringName, entity_id: StringName) -> void:
	if entity_id == &"":
		selected_entity_by_world.erase(world_id)
		return
	selected_entity_by_world[world_id] = entity_id


func get_world_selection(world_id: StringName) -> StringName:
	if not selected_entity_by_world.has(world_id):
		return &""
	return selected_entity_by_world[world_id]
