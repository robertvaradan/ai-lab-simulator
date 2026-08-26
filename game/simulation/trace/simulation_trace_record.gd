class_name SimulationTraceRecord
extends RefCounted

enum Kind {
	RULE_EVALUATION,
	CONDITION,
	STATE_READ,
	STATE_WRITE,
	EVENT_EMISSION,
	LEDGER_ACTIVITY,
	RANDOM_DRAW,
	CONTRACT_FAULT,
	PLAN_COMMITMENT,
}

var sequence_index: int:
	get:
		return _sequence_index
var kind: Kind:
	get:
		return _kind

var _sequence_index: int
var _kind: Kind
var _is_sealed: bool = false


func _init(p_sequence_index: int, p_kind: Kind) -> void:
	_sequence_index = p_sequence_index
	_kind = p_kind


func to_dictionary() -> Dictionary[StringName, Variant]:
	return {
		&"sequence_index": sequence_index,
		&"kind": kind,
	}


func _seal_record() -> void:
	_is_sealed = true


func is_sealed() -> bool:
	return _is_sealed
