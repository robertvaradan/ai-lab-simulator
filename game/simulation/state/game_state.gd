class_name GameState
extends Resource

@export var schema_version: int = -1
@export var content_version: int = -1
@export var rule_graph_id: StringName = &""
@export var rule_graph_version: int = -1
@export var scenario_id: StringName = &""
@export var calendar: CalendarState
@export var company: CompanyState
@export var world: WorldState
@export var cash_ledger: CashLedgerState
@export var pending_command_batch: PendingCommandBatchState
@export var attention_events: Array[AttentionEventState] = []
@export var notifications: Array[NotificationState] = []
@export var random_generator_state: RandomGeneratorState
@export var runtime_id_counters: RuntimeIdCountersState


func _init() -> void:
	pass
