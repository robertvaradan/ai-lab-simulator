class_name CampaignHost
extends ServiceContext

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"

var _definition: MarketingScenarioDefinition
var _core: SimulationCore
var _game_state_service: GameStateService
var _advance_action: SimulationAdvanceAction
var _hud: CampaignHud
var _presenter: CampusVisualPresenter
var _session: CampaignSessionState
var _last_result: SimulationOperationResult


func _register_services(provider: ServiceProvider) -> void:
	_session = CampaignSessionState.new()
	_definition = MarketingScenarioFactory.load_definition(SCENARIO_PATH)
	if _definition == null:
		ServiceContract.fail("missing_marketing_scenario", "The Marketing Scenario definition did not load.")
		return
	var state_result: GameStateLoadResult = MarketingScenarioFactory.create_state(_definition)
	if not state_result.succeeded():
		ServiceContract.fail(
			"invalid_marketing_starting_state",
			"The Marketing Scenario starting Game State is invalid. %s" % state_result.format_errors()
		)
		return
	var construction: SimulationCoreConstructionResult = MarketingScenarioFactory.create_core(
		_definition,
		state_result.state
	)
	if not construction.succeeded():
		ServiceContract.fail(
			"invalid_marketing_simulation_core",
			"The Marketing Scenario Simulation Core did not construct. %s" % construction.format_diagnostics()
		)
		return
	_core = construction.core
	_game_state_service = GameStateService.new(
		self,
		state_result.state,
		_definition.stable_id,
		_definition.content_version,
		_definition.rule_graph_id,
		_definition.rule_graph_version,
		_definition.build_content_reference_catalog()
	)
	provider.provide(GameStateService, _game_state_service)
	_advance_action = SimulationAdvanceAction.new(_core, _game_state_service)


func _inject_services(provider: ServiceProvider) -> void:
	var resolved_service: Service = provider.resolve(GameStateService)
	_game_state_service = resolved_service as GameStateService


func _ready() -> void:
	_hud = get_node_or_null("HudLayer/Overlay") as CampaignHud
	if _hud == null:
		_hud = get_node_or_null("Overlay") as CampaignHud
	if _hud != null:
		_hud.bind_host(self)
	_presenter = get_node_or_null("CampusVisualPresenter") as CampusVisualPresenter
	refresh_presentation()


func get_definition() -> MarketingScenarioDefinition:
	return _definition


func get_core() -> SimulationCore:
	return _core


func get_game_state_service() -> GameStateService:
	return _game_state_service


func get_session() -> CampaignSessionState:
	return _session


func get_hud() -> CampaignHud:
	return _hud


func get_presenter() -> CampusVisualPresenter:
	return _presenter


func get_last_result() -> SimulationOperationResult:
	return _last_result


func get_current_state() -> GameState:
	if _game_state_service == null:
		return null
	return _game_state_service.get_current_state()


func set_project_staged(project_id: StringName, staged: bool) -> void:
	if _session == null or _session.failed:
		return
	if staged:
		_session.staged_project_ids[project_id] = true
	else:
		_session.staged_project_ids.erase(project_id)
	refresh_presentation()


func set_active_view(view_id: StringName) -> void:
	if _session == null or _session.failed:
		return
	_session.active_view_id = view_id
	if view_id == CampaignCatalog.VIEW_SKILL_TREE:
		_session.active_world_id = CampaignCatalog.WORLD_HQ
	refresh_presentation()


func set_active_world(world_id: StringName) -> void:
	if _session == null or _session.failed:
		return
	if not CampaignCatalog.is_valid_world_id(world_id):
		ServiceContract.fail("unknown_world", "The World %s is unknown." % String(world_id))
		return
	_session.active_world_id = world_id
	_session.active_view_id = CampaignCatalog.VIEW_CAMPUS
	refresh_presentation()


func enter_world(world_id: StringName) -> void:
	if _session == null or _session.failed:
		return
	if not CampaignCatalog.is_valid_enterable_world_id(world_id):
		ServiceContract.fail("invalid_enterable_world", "The World %s is not enterable." % String(world_id))
		return
	set_active_world(world_id)


func get_active_world_id() -> StringName:
	if _session == null:
		return &""
	return _session.active_world_id


func unlock_skill(skill_id: StringName) -> bool:
	if _session == null or _session.failed:
		return false
	var skill: BootstrapUnlockDefinition = CampaignCatalog.skill_for_id(skill_id)
	if skill == null:
		ServiceContract.fail("unknown_skill", "The skill %s is unknown." % String(skill_id))
		return false
	if not _can_unlock(skill):
		return false
	_session.unlocked_skill_ids[skill_id] = true
	_session.research_points -= skill.cost_research_points
	refresh_presentation()
	return true


func can_unlock_skill(skill_id: StringName) -> bool:
	var skill: BootstrapUnlockDefinition = CampaignCatalog.skill_for_id(skill_id)
	if skill == null:
		return false
	return _can_unlock(skill)


func request_abandon() -> void:
	if _session == null or _session.failed:
		return
	_session.abandon_pending = true
	refresh_presentation()


func cancel_abandon() -> void:
	if _session == null:
		return
	_session.abandon_pending = false
	refresh_presentation()


func confirm_abandon() -> void:
	_fail_campaign(CampaignCatalog.FAIL_ABANDONED)


func return_to_main_menu() -> void:
	SceneRouter.go_to_main_menu(get_tree())


func advance_from_hud() -> SimulationOperationResult:
	if _hud == null:
		return null
	return advance_with_plan(_hud.build_plan(get_current_state()))


func advance_with_plan(plan: Plan) -> SimulationOperationResult:
	if _session != null and _session.failed:
		return _last_result
	_last_result = _advance_action.execute(plan)
	if (
		_last_result != null
		and (
			_last_result.outcome == SimulationOperationOutcome.Type.COMPLETED
			or _last_result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED
		)
	):
		_award_research_points()
		if CampaignCatalog.cash_balance_musd(get_current_state()) <= 0:
			_fail_campaign(CampaignCatalog.FAIL_CASH_EXHAUSTED)
			return _last_result
	refresh_presentation()
	return _last_result


func refresh_presentation() -> void:
	_award_research_points()
	var state: GameState = get_current_state()
	if _hud != null:
		_hud.present_state(state, _last_result, _definition, _session)
	if _presenter == null:
		return
	var in_hq: bool = _session != null and _session.active_world_id == CampaignCatalog.WORLD_HQ
	_presenter.set_campus_world_visible(in_hq)
	if in_hq:
		_presenter.present_state(state)


func _award_research_points() -> void:
	if _session == null:
		return
	var completed_ids: Array[StringName] = CampaignCatalog.completed_research_project_ids(
		get_current_state(),
		_definition
	)
	for project_id: StringName in completed_ids:
		if _session.awarded_research_project_ids.has(project_id) and _session.awarded_research_project_ids[project_id]:
			continue
		_session.awarded_research_project_ids[project_id] = true
		_session.research_points += CampaignCatalog.RESEARCH_POINTS_PER_RESEARCH_PROJECT


func _can_unlock(item: BootstrapUnlockDefinition) -> bool:
	if _session == null or _session.failed:
		return false
	if _session.has_skill(item.stable_id):
		return false
	if _session.research_points < item.cost_research_points:
		return false
	for prerequisite_id: StringName in item.prerequisite_ids:
		if not _session.has_skill(prerequisite_id):
			return false
	return true


func _fail_campaign(reason_id: StringName) -> void:
	if _session == null:
		return
	_session.failed = true
	_session.fail_reason_id = reason_id
	_session.abandon_pending = false
	refresh_presentation()
