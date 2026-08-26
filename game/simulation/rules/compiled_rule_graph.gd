class_name CompiledRuleGraph
extends RefCounted

var graph_id: StringName:
	get:
		return _graph_id
var graph_version: int:
	get:
		return _graph_version
var content_version: int:
	get:
		return _content_version
var ordered_rules: Array[SimulationRule]:
	get:
		var rules: Array[SimulationRule] = []
		rules.assign(_ordered_rules)
		return rules

var _graph_id: StringName
var _graph_version: int
var _content_version: int
var _ordered_rules: Array[SimulationRule] = []


func _init(
		p_graph_id: StringName,
		p_graph_version: int,
		p_content_version: int,
		p_ordered_rules: Array[SimulationRule]
	) -> void:
	_graph_id = p_graph_id
	_graph_version = p_graph_version
	_content_version = p_content_version
	_ordered_rules.assign(p_ordered_rules)
