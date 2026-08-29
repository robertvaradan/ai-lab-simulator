class_name CodingAgentMarket
extends RefCounted

const BASIS_POINTS_SCALE: int = 10000
const COMPANY_DEMAND_EFFECT_BASIS_POINTS: int = 10000
const TIER_LEADING: StringName = &"relevance_tier.leading"
const TIER_COMPETITIVE: StringName = &"relevance_tier.competitive"
const TIER_TRAILING: StringName = &"relevance_tier.trailing"
const MARKET_ID: StringName = &"market.coding_agent"
const RELEASED_STATE_ID: StringName = &"model_release_state.released"


static func technical_competitiveness(model_evaluation_points: int, frontier_evaluation_points: int) -> int:
	return model_evaluation_points - frontier_evaluation_points


static func technical_competitiveness_vector(
		evaluations: ModelEvaluationState,
		frontier: ModelEvaluationState
	) -> Vector3i:
	return Vector3i(
		technical_competitiveness(
			evaluations.coding_evaluation_points,
			frontier.coding_evaluation_points
		),
		technical_competitiveness(
			evaluations.reasoning_evaluation_points,
			frontier.reasoning_evaluation_points
		),
		technical_competitiveness(
			evaluations.efficiency_evaluation_points,
			frontier.efficiency_evaluation_points
		)
	)


static func calculate_demand(
		model: ModelState,
		market: MarketState,
		application: ApplicationState
	) -> CodingAgentDemandCalculation:
	var result: CodingAgentDemandCalculation = CodingAgentDemandCalculation.new()
	if model == null:
		result.diagnostic = _error(
			&"market.missing_supporting_model",
			"The Coding Agent supporting Model is missing."
		)
		return result
	if market == null:
		result.diagnostic = _error(&"market.missing_market", "The Coding Agent Market is missing.")
		return result
	if application == null:
		result.diagnostic = _error(
			&"market.missing_application",
			"The Coding Agent Application is missing."
		)
		return result
	if model.release_state_id != RELEASED_STATE_ID:
		result.diagnostic = _error(
			&"market.unreleased_supporting_model",
			"Unreleased Model %s must not support the Coding Agent." % model.stable_id
		)
		return result
	if model.evaluations == null:
		result.diagnostic = _error(
			&"market.missing_model_evaluations",
			"Model %s evaluations are missing." % model.stable_id
		)
		return result
	result.relevance_difference = (
		model.evaluations.coding_evaluation_points
		- market.customer_expectation_coding_evaluation_points
	)
	result.relevance_tier_id = _relevance_tier(result.relevance_difference)
	result.relevance_factor_basis_points = _relevance_factor(result.relevance_tier_id)
	result.pricing_power_musd_per_contract_month = _pricing_power(result.relevance_tier_id)
	if application.price_musd_per_contract_month > result.pricing_power_musd_per_contract_month:
		result.diagnostic = _error(
			&"market.price_exceeds_pricing_power",
			"Coding Agent price %d exceeds Model pricing power %d."
			% [
				application.price_musd_per_contract_month,
				result.pricing_power_musd_per_contract_month,
			]
		)
		return result
	result.price_factor_basis_points = BASIS_POINTS_SCALE
	var scale: int = BASIS_POINTS_SCALE * BASIS_POINTS_SCALE * BASIS_POINTS_SCALE
	var numerator: int = (
		market.possible_customer_contract_count
		* result.relevance_factor_basis_points
		* result.price_factor_basis_points
		* COMPANY_DEMAND_EFFECT_BASIS_POINTS
	)
	if numerator % scale != 0:
		result.diagnostic = _error(
			&"market.demand_not_whole",
			"Coding Agent demand %d / %d is not a whole number of contracts." % [numerator, scale]
		)
		return result
	var contract_count: int = numerator / scale
	result.customer_contract_count = contract_count
	result.revenue_musd = (
		result.customer_contract_count * application.price_musd_per_contract_month
	)
	result.inference_compute_unit_months = (
		result.customer_contract_count * model.inference_compute_unit_months_per_contract
	)
	result.succeeded = true
	return result


static func _relevance_tier(relevance_difference: int) -> StringName:
	if relevance_difference >= 0:
		return TIER_LEADING
	if relevance_difference >= -5:
		return TIER_COMPETITIVE
	return TIER_TRAILING


static func _relevance_factor(tier_id: StringName) -> int:
	match tier_id:
		TIER_LEADING:
			return 10000
		TIER_COMPETITIVE:
			return 7500
		_:
			return 5000


static func _pricing_power(tier_id: StringName) -> int:
	if tier_id == TIER_LEADING:
		return 2
	return 1


static func _error(code: StringName, message: String) -> SimulationDiagnostic:
	return SimulationDiagnostic.new(SimulationDiagnostic.Severity.ERROR, code, message)
