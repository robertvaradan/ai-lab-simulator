class_name MarketingPlayHost
extends ServiceContext

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"

var _definition: MarketingScenarioDefinition
var _core: SimulationCore
var _game_state_service: GameStateService
var _advance_action: SimulationAdvanceAction
var _overlay: MarketingPlayOverlay
var _last_result: SimulationOperationResult


func _register_services(provider: ServiceProvider) -> void:
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
	_overlay = get_node_or_null("Overlay") as MarketingPlayOverlay
	if _overlay != null:
		_overlay.bind_host(self)
	refresh_presentation()


func get_definition() -> MarketingScenarioDefinition:
	return _definition


func get_core() -> SimulationCore:
	return _core


func get_game_state_service() -> GameStateService:
	return _game_state_service


func get_advance_action() -> SimulationAdvanceAction:
	return _advance_action


func get_overlay() -> MarketingPlayOverlay:
	return _overlay


func get_last_result() -> SimulationOperationResult:
	return _last_result


func get_current_state() -> GameState:
	if _game_state_service == null:
		return null
	return _game_state_service.get_current_state()


func advance_with_plan(plan: Plan) -> SimulationOperationResult:
	_last_result = _advance_action.execute(plan)
	refresh_presentation()
	return _last_result


func advance_from_overlay() -> SimulationOperationResult:
	if _overlay == null:
		return null
	return advance_with_plan(_overlay.build_plan(get_current_state()))


func refresh_presentation() -> void:
	if _overlay == null:
		return
	_overlay.present_state(get_current_state(), _last_result, _definition)
