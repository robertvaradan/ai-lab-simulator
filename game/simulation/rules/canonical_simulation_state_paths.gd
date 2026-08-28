class_name CanonicalSimulationStatePaths
extends RefCounted

const COMPANY_PUBLIC_TRUST_POINTS: StringName = &"state.company.public_trust_points"
const COMPANY_GOVERNMENT_TRUST_POINTS: StringName = &"state.company.government_trust_points"
const CASH_LEDGER_TRANSACTIONS: StringName = &"state.cash_ledger.transactions"
const CALENDAR_MONTH_STEP_INDEX: StringName = &"state.calendar.current_month_step_index"
const CALENDAR_QUARTER_INDEX: StringName = &"state.calendar.current_quarter_index"
const PENDING_COMMAND_BATCH: StringName = &"state.pending_command_batch"
const ATTENTION_EVENTS: StringName = &"state.attention_events"
const RUNTIME_EVENT_SEQUENCE: StringName = &"state.runtime_id_counters.event"


static func create_registry() -> SimulationStatePathRegistry:
	var registry: SimulationStatePathRegistry = SimulationStatePathRegistry.new()
	registry.register_path(
		SimulationStatePath.new(
			COMPANY_PUBLIC_TRUST_POINTS,
			SimulationStatePath.Accessor.COMPANY_PUBLIC_TRUST_POINTS,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			COMPANY_GOVERNMENT_TRUST_POINTS,
			SimulationStatePath.Accessor.COMPANY_GOVERNMENT_TRUST_POINTS,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			CASH_LEDGER_TRANSACTIONS,
			SimulationStatePath.Accessor.CASH_LEDGER_TRANSACTIONS,
			SimulationStatePath.ValueType.CASH_LEDGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			CALENDAR_MONTH_STEP_INDEX,
			SimulationStatePath.Accessor.CALENDAR_MONTH_STEP_INDEX,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			CALENDAR_QUARTER_INDEX,
			SimulationStatePath.Accessor.CALENDAR_QUARTER_INDEX,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			PENDING_COMMAND_BATCH,
			SimulationStatePath.Accessor.PENDING_COMMAND_BATCH,
			SimulationStatePath.ValueType.PENDING_COMMAND_BATCH
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			ATTENTION_EVENTS,
			SimulationStatePath.Accessor.ATTENTION_EVENTS,
			SimulationStatePath.ValueType.ATTENTION_EVENTS
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			RUNTIME_EVENT_SEQUENCE,
			SimulationStatePath.Accessor.RUNTIME_EVENT_SEQUENCE,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	return registry
