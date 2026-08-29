class_name RuleGraphTraceView
extends RefCounted

var month_step_index: int = -1
var rule_views: Array[RuleGraphTraceRuleView] = []


func get_rule_view(rule_id: StringName) -> RuleGraphTraceRuleView:
	for rule_view: RuleGraphTraceRuleView in rule_views:
		if rule_view.rule_id == rule_id:
			return rule_view
	return null
