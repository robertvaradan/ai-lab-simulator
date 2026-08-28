class_name SimulationRulePhase
extends RefCounted

const OPEN_MONTH_STEP: StringName = &"rule_phase.open_month_step"
const CONSUME_PENDING_COMMAND_BATCH: StringName = &"rule_phase.consume_pending_command_batch"
const POST_COMMITTED_COSTS: StringName = &"rule_phase.post_committed_costs"
const ADVANCE_ACTIVE_PROJECTS: StringName = &"rule_phase.advance_active_projects"
const RESOLVE_PROJECT_COMPLETIONS: StringName = &"rule_phase.resolve_project_completions"
const ADVANCE_COMPETITORS: StringName = &"rule_phase.advance_competitors"
const RESOLVE_MARKET_CHANGES: StringName = &"rule_phase.resolve_market_changes"
const RESOLVE_CONTRACTS_REVENUE_OPERATING_COSTS: StringName = (
	&"rule_phase.resolve_contracts_revenue_operating_costs"
)
const RESOLVE_TRUST_AND_GOVERNMENT: StringName = &"rule_phase.resolve_trust_and_government"
const EVALUATE_LOSS_CONDITIONS: StringName = &"rule_phase.evaluate_loss_conditions"
const CREATE_ATTENTION_EVENTS: StringName = &"rule_phase.create_attention_events"
const CLOSE_MONTH_STEP: StringName = &"rule_phase.close_month_step"


static func canonical_phase_ids() -> Array[StringName]:
	return [
		OPEN_MONTH_STEP,
		CONSUME_PENDING_COMMAND_BATCH,
		POST_COMMITTED_COSTS,
		ADVANCE_ACTIVE_PROJECTS,
		RESOLVE_PROJECT_COMPLETIONS,
		ADVANCE_COMPETITORS,
		RESOLVE_MARKET_CHANGES,
		RESOLVE_CONTRACTS_REVENUE_OPERATING_COSTS,
		RESOLVE_TRUST_AND_GOVERNMENT,
		EVALUATE_LOSS_CONDITIONS,
		CREATE_ATTENTION_EVENTS,
		CLOSE_MONTH_STEP,
	]


static func index_of(phase_id: StringName) -> int:
	return canonical_phase_ids().find(phase_id)


static func is_canonical(phase_id: StringName) -> bool:
	return index_of(phase_id) >= 0
