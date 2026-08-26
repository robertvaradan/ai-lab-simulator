class_name RandomDrawTraceRecord
extends SimulationTraceRecord

var rule_id: StringName:
	get:
		return _rule_id
var draw_id: StringName:
	get:
		return _draw_id
var minimum: int:
	get:
		return _minimum
var maximum: int:
	get:
		return _maximum
var value: int:
	get:
		return _value

var _rule_id: StringName
var _draw_id: StringName
var _minimum: int
var _maximum: int
var _value: int


func _init(
		p_sequence_index: int,
		p_rule_id: StringName,
		p_draw_id: StringName,
		p_minimum: int,
		p_maximum: int,
		p_value: int
	) -> void:
	super(p_sequence_index, Kind.RANDOM_DRAW)
	_rule_id = p_rule_id
	_draw_id = p_draw_id
	_minimum = p_minimum
	_maximum = p_maximum
	_value = p_value


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"rule_id"] = rule_id
	data[&"draw_id"] = draw_id
	data[&"minimum"] = minimum
	data[&"maximum"] = maximum
	data[&"value"] = value
	return data
