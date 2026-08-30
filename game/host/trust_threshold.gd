class_name TrustThreshold
extends RefCounted

const PUBLIC_TRUST_PEAK_EVALUATION_POINTS: int = 80
const GOVERNMENT_PEAK_EVALUATION_POINTS: int = 90
const RELEASED_STATE_ID: StringName = &"model_release_state.released"


static func peak_evaluation(model: ModelState) -> int:
	if model == null or model.evaluations == null:
		return 0
	return maxi(
		model.evaluations.coding_evaluation_points,
		maxi(
			model.evaluations.reasoning_evaluation_points,
			model.evaluations.efficiency_evaluation_points
		)
	)


static func best_released_player_peak(state: GameState) -> int:
	if state == null or state.company == null:
		return 0
	var best_peak: int = 0
	for model_id: StringName in state.company.models:
		var model: ModelState = state.company.models[model_id]
		if model == null:
			continue
		if model.release_state_id != RELEASED_STATE_ID:
			continue
		best_peak = maxi(best_peak, peak_evaluation(model))
	return best_peak


static func is_public_trust_active(state: GameState) -> bool:
	return best_released_player_peak(state) >= PUBLIC_TRUST_PEAK_EVALUATION_POINTS


static func is_government_active(state: GameState) -> bool:
	return best_released_player_peak(state) >= GOVERNMENT_PEAK_EVALUATION_POINTS
