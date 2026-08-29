class_name AdvanceCompetitorsRule
extends SimulationRule

const RULE_ID: StringName = &"rule.competitor.advance"
const EVENT_ID: StringName = &"event.competitor.northstar_flagship_release"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Advance Competitors"
	phase_id = SimulationRulePhase.ADVANCE_COMPETITORS
	execution_order = 10
	read_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.WORLD_COMPETITORS,
		CanonicalSimulationStatePaths.WORLD_MODELS,
		CanonicalSimulationStatePaths.WORLD_MARKETS,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_CODING,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_REASONING,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_EFFICIENCY,
	]
	write_state_paths = [
		CanonicalSimulationStatePaths.WORLD_COMPETITORS,
		CanonicalSimulationStatePaths.WORLD_MODELS,
		CanonicalSimulationStatePaths.WORLD_MARKETS,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_CODING,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_REASONING,
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_EFFICIENCY,
	]
	emitted_event_ids = [EVENT_ID]
	graph_group_id = &"rule_group.competitors"
	specification_references = [
		"docs/marketing/marketing-scenario.md",
		"docs/simulation/time-model.md",
	]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	var competitor_ids: Array[StringName] = context.get_competitor_ids()
	if context.has_fault():
		return _failed_from_context(context)
	var pending_definitions: Array[CompetitorDefinition] = []
	for competitor_id: StringName in competitor_ids:
		var scheduled: CompetitorDefinition = context.get_competitor_definition(competitor_id)
		if scheduled == null:
			return _failed_from_context(context)
		if month_result.value == scheduled.release_month_step_index:
			pending_definitions.append(scheduled)
	if pending_definitions.is_empty():
		return SimulationRuleEvaluation.did_not_fire()
	var competitors: Dictionary[StringName, CompetitorState] = {}
	competitors.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.WORLD_COMPETITORS))
	if context.has_fault():
		return _failed_from_context(context)
	var world_models: Dictionary[StringName, ModelState] = {}
	world_models.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.WORLD_MODELS))
	if context.has_fault():
		return _failed_from_context(context)
	var markets: Dictionary[StringName, MarketState] = {}
	markets.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.WORLD_MARKETS))
	if context.has_fault():
		return _failed_from_context(context)
	var coding_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_CODING
	)
	if not coding_result.has_value:
		return SimulationRuleEvaluation.failed(coding_result.diagnostic)
	var reasoning_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_REASONING
	)
	if not reasoning_result.has_value:
		return SimulationRuleEvaluation.failed(reasoning_result.diagnostic)
	var efficiency_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_EFFICIENCY
	)
	if not efficiency_result.has_value:
		return SimulationRuleEvaluation.failed(efficiency_result.diagnostic)
	var frontier_coding: int = coding_result.value
	var frontier_reasoning: int = reasoning_result.value
	var frontier_efficiency: int = efficiency_result.value
	var released: bool = false
	for definition: CompetitorDefinition in pending_definitions:
		var competitor_id: StringName = definition.stable_id
		if not competitors.has(competitor_id):
			return SimulationRuleEvaluation.failed(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"rule.competitor.missing_state",
					"Competitor %s is missing from World State." % competitor_id,
					stable_id,
					CanonicalSimulationStatePaths.WORLD_COMPETITORS
				)
			)
		var competitor: CompetitorState = competitors[competitor_id]
		if competitor == null:
			return SimulationRuleEvaluation.failed(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"rule.competitor.missing_state",
					"Competitor %s is missing its state." % competitor_id,
					stable_id,
					CanonicalSimulationStatePaths.WORLD_COMPETITORS
				)
			)
		if competitor.stage_id != definition.announced_stage_id:
			continue
		var release_diagnostic: SimulationDiagnostic = _release_competitor(
			definition,
			competitor,
			world_models,
			markets
		)
		if release_diagnostic != null:
			return SimulationRuleEvaluation.failed(release_diagnostic)
		if definition.actual_coding_evaluation_points > frontier_coding:
			frontier_coding = definition.actual_coding_evaluation_points
		if definition.actual_reasoning_evaluation_points > frontier_reasoning:
			frontier_reasoning = definition.actual_reasoning_evaluation_points
		if definition.actual_efficiency_evaluation_points > frontier_efficiency:
			frontier_efficiency = definition.actual_efficiency_evaluation_points
		var payload: Dictionary[StringName, Variant] = {
			&"competitor_id": competitor_id,
			&"model_id": definition.released_model_id,
			&"month_step_index": month_result.value,
			&"actual_coding_evaluation_points": definition.actual_coding_evaluation_points,
			&"actual_reasoning_evaluation_points": definition.actual_reasoning_evaluation_points,
			&"actual_efficiency_evaluation_points": definition.actual_efficiency_evaluation_points,
			&"technical_frontier_coding_evaluation_points": frontier_coding,
			&"technical_frontier_reasoning_evaluation_points": frontier_reasoning,
			&"technical_frontier_efficiency_evaluation_points": frontier_efficiency,
			&"customer_expectation_coding_evaluation_points": (
				definition.released_customer_expectation_coding_evaluation_points
			),
		}
		if not context.emit_event(EVENT_ID, payload):
			return _failed_from_context(context)
		released = true
	if not released:
		return SimulationRuleEvaluation.did_not_fire()
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.WORLD_COMPETITORS, competitors):
		return _failed_from_context(context)
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.WORLD_MODELS, world_models):
		return _failed_from_context(context)
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.WORLD_MARKETS, markets):
		return _failed_from_context(context)
	if not context.write_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_CODING,
		frontier_coding
	):
		return _failed_from_context(context)
	if not context.write_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_REASONING,
		frontier_reasoning
	):
		return _failed_from_context(context)
	if not context.write_integer(
		CanonicalSimulationStatePaths.WORLD_TECHNICAL_FRONTIER_EFFICIENCY,
		frontier_efficiency
	):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _release_competitor(
		definition: CompetitorDefinition,
		competitor: CompetitorState,
		world_models: Dictionary[StringName, ModelState],
		markets: Dictionary[StringName, MarketState]
	) -> SimulationDiagnostic:
	if world_models.has(definition.released_model_id):
		return SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"rule.competitor.released_model_exists",
			"Competitor Model %s already exists." % definition.released_model_id,
			stable_id,
			CanonicalSimulationStatePaths.WORLD_MODELS
		)
	if not markets.has(definition.customer_expectation_market_id):
		return SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"rule.competitor.missing_market",
			"Market %s is missing from World State." % definition.customer_expectation_market_id,
			stable_id,
			CanonicalSimulationStatePaths.WORLD_MARKETS
		)
	var market: MarketState = markets[definition.customer_expectation_market_id]
	if market == null:
		return SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"rule.competitor.missing_market",
			"Market %s is missing its state." % definition.customer_expectation_market_id,
			stable_id,
			CanonicalSimulationStatePaths.WORLD_MARKETS
		)
	var evaluations: ModelEvaluationState = ModelEvaluationState.new()
	evaluations.coding_evaluation_points = definition.actual_coding_evaluation_points
	evaluations.reasoning_evaluation_points = definition.actual_reasoning_evaluation_points
	evaluations.efficiency_evaluation_points = definition.actual_efficiency_evaluation_points
	var model: ModelState = ModelState.new()
	model.stable_id = definition.released_model_id
	model.display_name = definition.released_model_display_name
	model.version_label = definition.released_model_version_label
	model.release_state_id = &"model_release_state.released"
	model.release_strategy_id = definition.released_model_release_strategy_id
	model.evaluations = evaluations
	model.training_compute_unit_months = definition.released_model_training_compute_unit_months
	model.inference_compute_unit_months_per_contract = (
		definition.released_model_inference_compute_unit_months_per_contract
	)
	world_models[model.stable_id] = model
	competitor.stage_id = definition.released_stage_id
	market.customer_expectation_coding_evaluation_points = (
		definition.released_customer_expectation_coding_evaluation_points
	)
	return null


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
