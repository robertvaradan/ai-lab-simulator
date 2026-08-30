class_name CampaignCatalog
extends RefCounted

const BUILD_LABORATORY_PROJECT_ID: StringName = &"project.campus.build_laboratory"
const RESEARCH_PROJECT_ID: StringName = &"project.research.frontier_model"
const SCALE_PROJECT_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_PROJECT_ID: StringName = &"project.application.coding_agent"
const STARTING_MODEL_ID: StringName = &"model.player.starting"

const VIEW_CAMPUS: StringName = &"view.campus"
const VIEW_DATA_CENTER: StringName = &"view.data_center"
const VIEW_SKILL_TREE: StringName = &"view.skill_tree"

const WORLD_MAP: StringName = &"world.map"
const WORLD_HQ: StringName = &"world.hq"
const WORLD_DATA_CENTER: StringName = &"world.data_center"
const WORLD_GOVERNMENT: StringName = &"world.government"

const BRANCH_RESEARCH: StringName = &"research"
const BRANCH_SCALE: StringName = &"scale"
const BRANCH_APPLICATION: StringName = &"application"

const RESEARCH_POINTS_PER_RESEARCH_PROJECT: int = 4

const SKILL_RESEARCH_METHODS: StringName = &"skill.research.methods"
const SKILL_RESEARCH_EVAL_LOOP: StringName = &"skill.research.eval_loop"
const SKILL_RESEARCH_FRONTIER_PUSH: StringName = &"skill.research.frontier_push"
const SKILL_SCALE_BURST_BUY: StringName = &"skill.scale.burst_buy"
const SKILL_SCALE_REGION_PLAN: StringName = &"skill.scale.region_plan"
const SKILL_SCALE_OWNED_SITES: StringName = &"skill.scale.owned_sites"
const SKILL_APPLICATION_AGENT_PACK: StringName = &"skill.application.agent_pack"
const SKILL_APPLICATION_PRODUCT_LINE: StringName = &"skill.application.product_line"
const SKILL_APPLICATION_ROBOTS: StringName = &"skill.application.robots"

const FAIL_ABANDONED: StringName = &"fail.abandoned"
const FAIL_CASH_EXHAUSTED: StringName = &"fail.cash_exhausted"


static func skill_definitions() -> Array[BootstrapUnlockDefinition]:
	var skills: Array[BootstrapUnlockDefinition] = []
	skills.append(
		_unlock(
			SKILL_RESEARCH_METHODS,
			"Prototype Methods",
			"This skill belongs to the Research branch.",
			BRANCH_RESEARCH,
			1,
			[]
		)
	)
	skills.append(
		_unlock(
			SKILL_RESEARCH_EVAL_LOOP,
			"Eval Loop",
			"This skill belongs to the Research branch. It requires Prototype Methods.",
			BRANCH_RESEARCH,
			1,
			[SKILL_RESEARCH_METHODS]
		)
	)
	skills.append(
		_unlock(
			SKILL_RESEARCH_FRONTIER_PUSH,
			"Frontier Push",
			"This skill belongs to the Research branch. It requires Eval Loop.",
			BRANCH_RESEARCH,
			2,
			[SKILL_RESEARCH_EVAL_LOOP]
		)
	)
	skills.append(
		_unlock(
			SKILL_SCALE_BURST_BUY,
			"Burst Contracts",
			"This skill belongs to the Scale branch.",
			BRANCH_SCALE,
			1,
			[]
		)
	)
	skills.append(
		_unlock(
			SKILL_SCALE_REGION_PLAN,
			"Region Plan",
			"This skill belongs to the Scale branch. It requires Burst Contracts.",
			BRANCH_SCALE,
			1,
			[SKILL_SCALE_BURST_BUY]
		)
	)
	skills.append(
		_unlock(
			SKILL_SCALE_OWNED_SITES,
			"Owned Sites",
			"This skill belongs to the Scale branch. It requires Region Plan.",
			BRANCH_SCALE,
			2,
			[SKILL_SCALE_REGION_PLAN]
		)
	)
	skills.append(
		_unlock(
			SKILL_APPLICATION_AGENT_PACK,
			"Agent Pack",
			"This skill belongs to the Application branch.",
			BRANCH_APPLICATION,
			1,
			[]
		)
	)
	skills.append(
		_unlock(
			SKILL_APPLICATION_PRODUCT_LINE,
			"Product Line",
			"This skill belongs to the Application branch. It requires Agent Pack.",
			BRANCH_APPLICATION,
			1,
			[SKILL_APPLICATION_AGENT_PACK]
		)
	)
	skills.append(
		_unlock(
			SKILL_APPLICATION_ROBOTS,
			"Robot Assistants",
			"This skill belongs to the Application branch. It requires Product Line.",
			BRANCH_APPLICATION,
			2,
			[SKILL_APPLICATION_PRODUCT_LINE]
		)
	)
	return skills


static func skill_for_id(skill_id: StringName) -> BootstrapUnlockDefinition:
	for skill: BootstrapUnlockDefinition in skill_definitions():
		if skill.stable_id == skill_id:
			return skill
	return null


static func completed_research_project_ids(
		state: GameState,
		definition: MarketingScenarioDefinition
	) -> Array[StringName]:
	var ids: Array[StringName] = []
	if state == null or state.company == null:
		return ids
	var project_ids: Array[StringName] = state.company.projects.keys()
	project_ids.sort()
	for project_id: StringName in project_ids:
		var project: ProjectState = state.company.projects[project_id]
		if project == null:
			continue
		if project.status_id != ProjectState.STATUS_COMPLETED:
			continue
		var project_definition: ProjectDefinition = find_project(definition, project.content_definition_id)
		if project_definition == null:
			continue
		if project_definition.completion_effect_id != ProjectDefinition.EFFECT_RESEARCH_MODEL:
			continue
		ids.append(project.stable_id)
	return ids


static func find_project(
		definition: MarketingScenarioDefinition,
		project_id: StringName
	) -> ProjectDefinition:
	if definition == null:
		return null
	for project: ProjectDefinition in definition.project_definitions:
		if project != null and project.stable_id == project_id:
			return project
	return null


static func find_contract(
		definition: MarketingScenarioDefinition,
		contract_id: StringName
	) -> ContractDefinition:
	if definition == null:
		return null
	for contract: ContractDefinition in definition.contract_definitions:
		if contract != null and contract.stable_id == contract_id:
			return contract
	return null


static func cash_balance_musd(state: GameState) -> int:
	if state == null or state.cash_ledger == null:
		return 0
	return state.cash_ledger.calculate_balance_musd()


static func laboratory_capacity_level(state: GameState) -> int:
	if state == null or state.company == null:
		return 1
	return maxi(1, state.company.project_team_count)


static func laboratory_stage_label(state: GameState) -> String:
	var mapping: CampusVisualMapping = CampusVisualMapping.from_state(state)
	if mapping.has_empty_plot():
		return "Empty plot"
	if mapping.uses_developed_laboratory():
		return "Developed laboratory"
	return "Compact laboratory"


static func is_valid_enterable_world_id(world_id: StringName) -> bool:
	return (
		world_id == WORLD_HQ
		or world_id == WORLD_DATA_CENTER
		or world_id == WORLD_GOVERNMENT
	)


static func is_valid_world_id(world_id: StringName) -> bool:
	return world_id == WORLD_MAP or is_valid_enterable_world_id(world_id)


static func world_display_name(world_id: StringName) -> String:
	if world_id == WORLD_MAP:
		return "World Map"
	if world_id == WORLD_HQ:
		return "HQ"
	if world_id == WORLD_DATA_CENTER:
		return "Data Center"
	if world_id == WORLD_GOVERNMENT:
		return "Government"
	return ""


static func fail_reason_text(reason_id: StringName) -> String:
	if reason_id == FAIL_ABANDONED:
		return "The player abandoned the campaign."
	if reason_id == FAIL_CASH_EXHAUSTED:
		return "Cash reached 0 MUSD or less."
	return "The campaign ended."


static func _unlock(
		stable_id: StringName,
		display_name: String,
		summary: String,
		branch_id: StringName,
		cost_research_points: int,
		prerequisite_ids: Array[StringName]
	) -> BootstrapUnlockDefinition:
	var item: BootstrapUnlockDefinition = BootstrapUnlockDefinition.new()
	item.stable_id = stable_id
	item.display_name = display_name
	item.summary = summary
	item.branch_id = branch_id
	item.cost_research_points = cost_research_points
	item.prerequisite_ids = prerequisite_ids
	return item
