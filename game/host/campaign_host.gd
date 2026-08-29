class_name CampaignHost
extends ServiceContext

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"

var _definition: MarketingScenarioDefinition
var _core: SimulationCore
var _game_state_service: GameStateService
var _advance_action: SimulationAdvanceAction
var _hud: CampaignHud
var _presenter: SdfCampusPresenter
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
	_presenter = get_node_or_null("SdfCampusPresenter") as SdfCampusPresenter
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


func get_presenter() -> SdfCampusPresenter:
	return _presenter


func get_last_result() -> SimulationOperationResult:
	return _last_result


func get_current_state() -> GameState:
	if _game_state_service == null:
		return null
	return _game_state_service.get_current_state()


func select_opening_path(path_id: StringName) -> void:
	if _session == null or _session.failed:
		return
	var path: BootstrapPathDefinition = CampaignCatalog.path_for_id(path_id)
	if path == null:
		ServiceContract.fail("unknown_opening_path", "The opening path %s is unknown." % String(path_id))
		return
	_session.opening_path_id = path_id
	_session.staged_project_ids[path.project_id] = true
	var skill_id: StringName = CampaignCatalog.skill_id_for_path(path_id)
	if skill_id != &"":
		_session.unlocked_skill_ids[skill_id] = true
		_session.skill_unlock_month_by_id[skill_id] = get_current_state().calendar.current_month_step_index
	refresh_presentation()


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
	refresh_presentation()


func unlock_skill(skill_id: StringName) -> bool:
	if _session == null or _session.failed:
		return false
	var skill: BootstrapUnlockDefinition = CampaignCatalog.skill_for_id(skill_id)
	if skill == null:
		ServiceContract.fail("unknown_skill", "The skill %s is unknown." % String(skill_id))
		return false
	if not _can_unlock(skill, true):
		return false
	var state: GameState = get_current_state()
	_session.unlocked_skill_ids[skill_id] = true
	_session.skill_unlock_month_by_id[skill_id] = state.calendar.current_month_step_index
	if skill.staged_project_id != &"":
		_session.staged_project_ids[skill.staged_project_id] = true
	refresh_presentation()
	return true


func unlock_tech(tech_id: StringName) -> bool:
	if _session == null or _session.failed:
		return false
	var tech: BootstrapUnlockDefinition = CampaignCatalog.tech_for_id(tech_id)
	if tech == null:
		ServiceContract.fail("unknown_tech", "The tech item %s is unknown." % String(tech_id))
		return false
	if not _can_unlock(tech, false):
		return false
	_session.unlocked_tech_ids[tech_id] = true
	refresh_presentation()
	return true


func can_unlock_skill(skill_id: StringName) -> bool:
	var skill: BootstrapUnlockDefinition = CampaignCatalog.skill_for_id(skill_id)
	if skill == null:
		return false
	return _can_unlock(skill, true)


func can_unlock_tech(tech_id: StringName) -> bool:
	var tech: BootstrapUnlockDefinition = CampaignCatalog.tech_for_id(tech_id)
	if tech == null:
		return false
	return _can_unlock(tech, false)


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
		and CampaignCatalog.cash_balance_musd(get_current_state()) <= 0
	):
		_fail_campaign(CampaignCatalog.FAIL_CASH_EXHAUSTED)
		return _last_result
	refresh_presentation()
	return _last_result


func refresh_presentation() -> void:
	var state: GameState = get_current_state()
	if _hud != null:
		_hud.present_state(state, _last_result, _definition, _session)
	if _presenter != null:
		_presenter.present_state(state)


func _can_unlock(item: BootstrapUnlockDefinition, is_skill: bool) -> bool:
	if _session == null or not _session.has_chosen_path() or _session.failed:
		return false
	var state: GameState = get_current_state()
	if state == null or state.calendar == null:
		return false
	if is_skill and _session.has_skill(item.stable_id):
		return false
	if not is_skill and _session.has_tech(item.stable_id):
		return false
	if CampaignCatalog.cash_balance_musd(state) < item.cost_musd:
		return false
	if state.calendar.current_month_step_index < item.required_month_step_index:
		return false
	if is_skill and _session.unlocked_skill_in_month(state.calendar.current_month_step_index):
		return false
	for prerequisite_id: StringName in item.prerequisite_ids:
		if is_skill and not _session.has_skill(prerequisite_id):
			return false
		if not is_skill and not _session.has_tech(prerequisite_id):
			return false
	return true


func _fail_campaign(reason_id: StringName) -> void:
	if _session == null:
		return
	_session.failed = true
	_session.fail_reason_id = reason_id
	_session.abandon_pending = false
	refresh_presentation()
