class_name SimulationRuleRegistry
extends RefCounted

var _rules_by_id: Dictionary[StringName, SimulationRule] = {}
var _registration_order: Array[SimulationRule] = []
var _diagnostics: Array[SimulationDiagnostic] = []
var _is_sealed: bool = false


func register_rule(rule: SimulationRule) -> bool:
	if _is_sealed:
		_add_error(&"rule_registry.sealed", "The Rule registry is sealed.")
		return false
	if rule == null:
		_add_error(&"rule_registry.missing_rule", "A registered Rule is missing.")
		return false
	if _rules_by_id.has(rule.stable_id):
		_add_error(
			&"rule_registry.duplicate_rule_id",
			"Rule identifier %s is duplicated." % rule.stable_id,
			rule.stable_id
		)
		return false
	_rules_by_id[rule.stable_id] = rule
	_registration_order.append(rule)
	return true


func seal() -> void:
	if _is_sealed:
		return
	for rule: SimulationRule in _registration_order:
		rule._seal_metadata()
	_is_sealed = true


func is_sealed() -> bool:
	return _is_sealed


func get_rule(rule_id: StringName) -> SimulationRule:
	return _rules_by_id.get(rule_id)


func get_rules_in_registration_order() -> Array[SimulationRule]:
	var rules: Array[SimulationRule] = []
	rules.assign(_registration_order)
	return rules


func get_diagnostics() -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	diagnostics.assign(_diagnostics)
	return diagnostics


func _add_error(code: StringName, message: String, rule_id: StringName = &"") -> void:
	_diagnostics.append(
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			code,
			message,
			rule_id
		)
	)
