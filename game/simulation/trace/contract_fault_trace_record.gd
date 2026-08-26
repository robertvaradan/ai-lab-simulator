class_name ContractFaultTraceRecord
extends SimulationTraceRecord

var diagnostic_code: StringName:
	get:
		return _diagnostic_code

var _diagnostic_code: StringName


func _init(p_sequence_index: int, p_diagnostic_code: StringName) -> void:
	super(p_sequence_index, Kind.CONTRACT_FAULT)
	_diagnostic_code = p_diagnostic_code


func to_dictionary() -> Dictionary[StringName, Variant]:
	var data: Dictionary[StringName, Variant] = super.to_dictionary()
	data[&"diagnostic_code"] = diagnostic_code
	return data
