class_name CampaignCatalog
extends RefCounted

const PATH_RESEARCH: StringName = &"path.research"
const PATH_SCALE: StringName = &"path.scale"
const PATH_APPLICATIONS: StringName = &"path.applications"

const RESEARCH_PROJECT_ID: StringName = &"project.research.frontier_model"
const SCALE_PROJECT_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_PROJECT_ID: StringName = &"project.application.coding_agent"
const STARTING_MODEL_ID: StringName = &"model.player.starting"

const VIEW_CAMPUS: StringName = &"view.campus"
const VIEW_DATA_CENTER: StringName = &"view.data_center"
const VIEW_SKILL_TREE: StringName = &"view.skill_tree"
const VIEW_TECH_TREE: StringName = &"view.tech_tree"

const SKILL_RESEARCH_FOCUS: StringName = &"skill.research.focus"
const SKILL_SCALE_FOCUS: StringName = &"skill.scale.focus"
const SKILL_APPLICATION_FOCUS: StringName = &"skill.application.focus"
const SKILL_OPS_REVIEW: StringName = &"skill.ops.review"
const SKILL_SAFETY_REVIEW: StringName = &"skill.safety.review"

const TECH_EVAL_HARNESS: StringName = &"tech.eval_harness"
const TECH_DATASET_CLEAN: StringName = &"tech.dataset_clean"
const TECH_SERVING_QUEUE: StringName = &"tech.serving_queue"
const TECH_TEAM_CAPACITY: StringName = &"tech.team_capacity"

const FAIL_ABANDONED: StringName = &"fail.abandoned"
const FAIL_CASH_EXHAUSTED: StringName = &"fail.cash_exhausted"


static func opening_paths() -> Array[BootstrapPathDefinition]:
	var paths: Array[BootstrapPathDefinition] = []
	paths.append(
		_path(
			PATH_RESEARCH,
			"Research",
			"Train the next Model version. This path upgrades the visible laboratory when the Project completes.",
			RESEARCH_PROJECT_ID
		)
	)
	paths.append(
		_path(
			PATH_SCALE,
			"Scale",
			"Buy burst Third-Party Compute. This path fills the Data Center slot with more capacity.",
			SCALE_PROJECT_ID
		)
	)
	paths.append(
		_path(
			PATH_APPLICATIONS,
			"Applications",
			"Ship a Coding Agent. This path turns the starting Model into Revenue.",
			CODING_AGENT_PROJECT_ID
		)
	)
	return paths


static func skill_definitions() -> Array[BootstrapUnlockDefinition]:
	var skills: Array[BootstrapUnlockDefinition] = []
	skills.append(
		_unlock(
			SKILL_RESEARCH_FOCUS,
			"Research Focus",
			"Stage the Research Project.",
			0,
			0,
			[],
			RESEARCH_PROJECT_ID
		)
	)
	skills.append(
		_unlock(
			SKILL_SCALE_FOCUS,
			"Scale Focus",
			"Stage the Scale Project.",
			0,
			0,
			[],
			SCALE_PROJECT_ID
		)
	)
	skills.append(
		_unlock(
			SKILL_APPLICATION_FOCUS,
			"Application Focus",
			"Stage the Coding Agent Project.",
			0,
			0,
			[],
			CODING_AGENT_PROJECT_ID
		)
	)
	skills.append(
		_unlock(
			SKILL_OPS_REVIEW,
			"Operations Review",
			"Proof skill. The unlock does not change Cash.",
			10,
			1,
			[],
			&""
		)
	)
	skills.append(
		_unlock(
			SKILL_SAFETY_REVIEW,
			"Safety Review",
			"Proof skill. This skill requires Operations Review.",
			10,
			1,
			[SKILL_OPS_REVIEW],
			&""
		)
	)
	return skills


static func tech_definitions() -> Array[BootstrapUnlockDefinition]:
	var techs: Array[BootstrapUnlockDefinition] = []
	techs.append(
		_unlock(
			TECH_EVAL_HARNESS,
			"Evaluation Harness",
			"Proof item. Cash must meet the cost. The unlock does not spend Cash.",
			15,
			0,
			[],
			&""
		)
	)
	techs.append(
		_unlock(
			TECH_DATASET_CLEAN,
			"Dataset Clean-up",
			"Proof item. Cash must meet the cost. The unlock does not spend Cash.",
			20,
			0,
			[],
			&""
		)
	)
	techs.append(
		_unlock(
			TECH_SERVING_QUEUE,
			"Serving Queue",
			"Proof item. This item requires the Evaluation Harness.",
			25,
			0,
			[TECH_EVAL_HARNESS],
			&""
		)
	)
	techs.append(
		_unlock(
			TECH_TEAM_CAPACITY,
			"Expand Team Capacity",
			"Proof item for a later hire-team Command. Laboratory capacity still follows project teams.",
			40,
			0,
			[],
			&""
		)
	)
	return techs


static func path_for_id(path_id: StringName) -> BootstrapPathDefinition:
	for path: BootstrapPathDefinition in opening_paths():
		if path.stable_id == path_id:
			return path
	return null


static func skill_for_id(skill_id: StringName) -> BootstrapUnlockDefinition:
	for skill: BootstrapUnlockDefinition in skill_definitions():
		if skill.stable_id == skill_id:
			return skill
	return null


static func tech_for_id(tech_id: StringName) -> BootstrapUnlockDefinition:
	for tech: BootstrapUnlockDefinition in tech_definitions():
		if tech.stable_id == tech_id:
			return tech
	return null


static func skill_id_for_path(path_id: StringName) -> StringName:
	if path_id == PATH_RESEARCH:
		return SKILL_RESEARCH_FOCUS
	if path_id == PATH_SCALE:
		return SKILL_SCALE_FOCUS
	if path_id == PATH_APPLICATIONS:
		return SKILL_APPLICATION_FOCUS
	return &""


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
	if CampusVisualMapping.from_state(state).uses_developed_laboratory():
		return "Developed laboratory"
	return "Compact laboratory"


static func fail_reason_text(reason_id: StringName) -> String:
	if reason_id == FAIL_ABANDONED:
		return "The player abandoned the campaign."
	if reason_id == FAIL_CASH_EXHAUSTED:
		return "Cash reached 0 MUSD or less."
	return "The campaign ended."


static func _path(
		stable_id: StringName,
		display_name: String,
		summary: String,
		project_id: StringName
	) -> BootstrapPathDefinition:
	var path: BootstrapPathDefinition = BootstrapPathDefinition.new()
	path.stable_id = stable_id
	path.display_name = display_name
	path.summary = summary
	path.project_id = project_id
	return path


static func _unlock(
		stable_id: StringName,
		display_name: String,
		summary: String,
		cost_musd: int,
		required_month_step_index: int,
		prerequisite_ids: Array[StringName],
		staged_project_id: StringName
	) -> BootstrapUnlockDefinition:
	var item: BootstrapUnlockDefinition = BootstrapUnlockDefinition.new()
	item.stable_id = stable_id
	item.display_name = display_name
	item.summary = summary
	item.cost_musd = cost_musd
	item.required_month_step_index = required_month_step_index
	item.prerequisite_ids = prerequisite_ids
	item.staged_project_id = staged_project_id
	return item
