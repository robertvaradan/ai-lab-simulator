class_name CanonicalSimulationStatePaths
extends RefCounted

const COMPANY_PUBLIC_TRUST_POINTS: StringName = &"state.company.public_trust_points"
const COMPANY_GOVERNMENT_TRUST_POINTS: StringName = &"state.company.government_trust_points"
const COMPANY_PROJECT_TEAM_COUNT: StringName = &"state.company.project_team_count"
const COMPANY_COMPUTE_CAPACITY: StringName = &"state.company.compute_capacity_unit_months"
const COMPANY_PROJECTS: StringName = &"state.company.projects"
const COMPANY_MODELS: StringName = &"state.company.models"
const COMPANY_APPLICATIONS: StringName = &"state.company.applications"
const COMPANY_CONTRACTS: StringName = &"state.company.contracts"
const WORLD_COMPETITORS: StringName = &"state.world.competitors"
const WORLD_MODELS: StringName = &"state.world.models"
const WORLD_MARKETS: StringName = &"state.world.markets"
const WORLD_TECHNICAL_FRONTIER_CODING: StringName = (
	&"state.world.technical_frontier.coding_evaluation_points"
)
const WORLD_TECHNICAL_FRONTIER_REASONING: StringName = (
	&"state.world.technical_frontier.reasoning_evaluation_points"
)
const WORLD_TECHNICAL_FRONTIER_EFFICIENCY: StringName = (
	&"state.world.technical_frontier.efficiency_evaluation_points"
)
const CASH_LEDGER_TRANSACTIONS: StringName = &"state.cash_ledger.transactions"
const CALENDAR_MONTH_STEP_INDEX: StringName = &"state.calendar.current_month_step_index"
const CALENDAR_QUARTER_INDEX: StringName = &"state.calendar.current_quarter_index"
const PENDING_COMMAND_BATCH: StringName = &"state.pending_command_batch"
const ATTENTION_EVENTS: StringName = &"state.attention_events"
const NOTIFICATIONS: StringName = &"state.notifications"
const RUNTIME_EVENT_SEQUENCE: StringName = &"state.runtime_id_counters.event"
const RUNTIME_LEDGER_TRANSACTION_SEQUENCE: StringName = &"state.runtime_id_counters.ledger_transaction"
const RUNTIME_NOTIFICATION_SEQUENCE: StringName = &"state.runtime_id_counters.notification"


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
			COMPANY_PROJECT_TEAM_COUNT,
			SimulationStatePath.Accessor.COMPANY_PROJECT_TEAM_COUNT,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			COMPANY_COMPUTE_CAPACITY,
			SimulationStatePath.Accessor.COMPANY_COMPUTE_CAPACITY,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			COMPANY_PROJECTS,
			SimulationStatePath.Accessor.COMPANY_PROJECTS,
			SimulationStatePath.ValueType.RESOURCE_DICTIONARY
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			COMPANY_MODELS,
			SimulationStatePath.Accessor.COMPANY_MODELS,
			SimulationStatePath.ValueType.RESOURCE_DICTIONARY
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			COMPANY_APPLICATIONS,
			SimulationStatePath.Accessor.COMPANY_APPLICATIONS,
			SimulationStatePath.ValueType.RESOURCE_DICTIONARY
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			COMPANY_CONTRACTS,
			SimulationStatePath.Accessor.COMPANY_CONTRACTS,
			SimulationStatePath.ValueType.RESOURCE_DICTIONARY
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			WORLD_COMPETITORS,
			SimulationStatePath.Accessor.WORLD_COMPETITORS,
			SimulationStatePath.ValueType.RESOURCE_DICTIONARY
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			WORLD_MODELS,
			SimulationStatePath.Accessor.WORLD_MODELS,
			SimulationStatePath.ValueType.RESOURCE_DICTIONARY
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			WORLD_MARKETS,
			SimulationStatePath.Accessor.WORLD_MARKETS,
			SimulationStatePath.ValueType.RESOURCE_DICTIONARY
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			WORLD_TECHNICAL_FRONTIER_CODING,
			SimulationStatePath.Accessor.WORLD_TECHNICAL_FRONTIER_CODING,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			WORLD_TECHNICAL_FRONTIER_REASONING,
			SimulationStatePath.Accessor.WORLD_TECHNICAL_FRONTIER_REASONING,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			WORLD_TECHNICAL_FRONTIER_EFFICIENCY,
			SimulationStatePath.Accessor.WORLD_TECHNICAL_FRONTIER_EFFICIENCY,
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
			NOTIFICATIONS,
			SimulationStatePath.Accessor.NOTIFICATIONS,
			SimulationStatePath.ValueType.NOTIFICATIONS
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			RUNTIME_EVENT_SEQUENCE,
			SimulationStatePath.Accessor.RUNTIME_EVENT_SEQUENCE,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
			SimulationStatePath.Accessor.RUNTIME_LEDGER_TRANSACTION_SEQUENCE,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	registry.register_path(
		SimulationStatePath.new(
			RUNTIME_NOTIFICATION_SEQUENCE,
			SimulationStatePath.Accessor.RUNTIME_NOTIFICATION_SEQUENCE,
			SimulationStatePath.ValueType.INTEGER
		)
	)
	return registry
