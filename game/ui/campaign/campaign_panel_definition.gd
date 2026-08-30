class_name CampaignPanelDefinition
extends RefCounted

const PANEL_COMPANY_OVERVIEW: StringName = &"panel.company_overview"
const PANEL_PLAN: StringName = &"panel.plan"
const PANEL_TIMELINE: StringName = &"panel.timeline"
const PANEL_WORLD_MAP: StringName = &"panel.world_map"
const PANEL_PAUSE: StringName = &"panel.pause"
const PANEL_FAIL_STATE: StringName = &"panel.fail_state"
const PANEL_ADVANCE_TRANSITION: StringName = &"panel.advance_transition"

const SURFACE_WORLD: StringName = &"surface.world"
const SURFACE_CHROME: StringName = &"surface.chrome"
const SURFACE_CONTEXT: StringName = &"surface.context"
const SURFACE_WORKBENCH: StringName = &"surface.workbench"
const SURFACE_MODAL: StringName = &"surface.modal"

const TAB_PROJECTS: StringName = &"tab.projects"
const TAB_SKILL_TREE: StringName = &"tab.skill_tree"

const SCENE_COMPANY_OVERVIEW: String = "res://ui/campaign/panels/company_overview.tscn"
const SCENE_PLAN: String = "res://ui/campaign/panels/plan_workbench.tscn"
const SCENE_TIMELINE: String = "res://ui/campaign/panels/timeline_panel.tscn"
const SCENE_WORLD_MAP: String = "res://ui/campaign/panels/world_map_panel.tscn"
const SCENE_PAUSE: String = "res://ui/campaign/panels/pause.tscn"
const SCENE_FAIL_STATE: String = "res://ui/campaign/panels/fail_state_panel.tscn"
const SCENE_ADVANCE_TRANSITION: String = "res://ui/campaign/panels/advance_transition.tscn"

var stable_id: StringName = &""
var scene_path: String = ""
var surface_type: StringName = &""
var initial_focus_path: NodePath = NodePath()
var permitted_tabs: Array[StringName] = []
var permitted_worlds: Array[StringName] = []


func _init() -> void:
	pass


static func company_overview() -> CampaignPanelDefinition:
	return _make(
		PANEL_COMPANY_OVERVIEW,
		SCENE_COMPANY_OVERVIEW,
		SURFACE_WORKBENCH,
		NodePath(),
		_empty_ids(),
		_empty_ids()
	)


static func plan() -> CampaignPanelDefinition:
	var tabs: Array[StringName] = _empty_ids()
	tabs.append(TAB_PROJECTS)
	tabs.append(TAB_SKILL_TREE)
	return _make(
		PANEL_PLAN,
		SCENE_PLAN,
		SURFACE_WORKBENCH,
		NodePath(),
		tabs,
		_empty_ids()
	)


static func timeline() -> CampaignPanelDefinition:
	return _make(
		PANEL_TIMELINE,
		SCENE_TIMELINE,
		SURFACE_WORKBENCH,
		NodePath(),
		_empty_ids(),
		_empty_ids()
	)


static func world_map() -> CampaignPanelDefinition:
	return _make(
		PANEL_WORLD_MAP,
		SCENE_WORLD_MAP,
		SURFACE_WORKBENCH,
		NodePath(),
		_empty_ids(),
		_empty_ids()
	)


static func pause() -> CampaignPanelDefinition:
	return _make(
		PANEL_PAUSE,
		SCENE_PAUSE,
		SURFACE_MODAL,
		NodePath(),
		_empty_ids(),
		_empty_ids()
	)


static func fail_state() -> CampaignPanelDefinition:
	return _make(
		PANEL_FAIL_STATE,
		SCENE_FAIL_STATE,
		SURFACE_MODAL,
		NodePath(),
		_empty_ids(),
		_empty_ids()
	)


static func advance_transition() -> CampaignPanelDefinition:
	return _make(
		PANEL_ADVANCE_TRANSITION,
		SCENE_ADVANCE_TRANSITION,
		SURFACE_MODAL,
		NodePath(),
		_empty_ids(),
		_empty_ids()
	)


static func known_panels() -> Array[CampaignPanelDefinition]:
	var panels: Array[CampaignPanelDefinition] = []
	panels.append(company_overview())
	panels.append(plan())
	panels.append(timeline())
	panels.append(world_map())
	panels.append(pause())
	panels.append(fail_state())
	panels.append(advance_transition())
	return panels


static func _make(
		p_stable_id: StringName,
		p_scene_path: String,
		p_surface_type: StringName,
		p_initial_focus_path: NodePath,
		p_permitted_tabs: Array[StringName],
		p_permitted_worlds: Array[StringName]
	) -> CampaignPanelDefinition:
	var definition: CampaignPanelDefinition = CampaignPanelDefinition.new()
	definition.stable_id = p_stable_id
	definition.scene_path = p_scene_path
	definition.surface_type = p_surface_type
	definition.initial_focus_path = p_initial_focus_path
	definition.permitted_tabs.assign(p_permitted_tabs)
	definition.permitted_worlds.assign(p_permitted_worlds)
	return definition


static func _empty_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	return ids
