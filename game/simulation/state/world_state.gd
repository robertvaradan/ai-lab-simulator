class_name WorldState
extends Resource

@export var competitors: Dictionary[StringName, CompetitorState] = {}
@export var models: Dictionary[StringName, ModelState] = {}
@export var technical_frontier: ModelEvaluationState
@export var markets: Dictionary[StringName, MarketState] = {}
@export var active_government_condition_ids: Dictionary[StringName, bool] = {}


func _init() -> void:
	pass
