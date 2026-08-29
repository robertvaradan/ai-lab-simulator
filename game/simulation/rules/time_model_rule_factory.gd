class_name TimeModelRuleFactory
extends RefCounted


static func create_registry() -> SimulationRuleRegistry:
	var registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	registry.register_rule(OpenMonthStepRule.new())
	registry.register_rule(ConsumePendingCommandBatchRule.new())
	registry.register_rule(PostCommittedProjectCostsRule.new())
	registry.register_rule(AdvanceActiveProjectsRule.new())
	registry.register_rule(ResolveProjectCompletionsRule.new())
	registry.register_rule(CreateQuarterBoundaryAttentionRule.new())
	registry.register_rule(CreateProjectCompletionNotificationRule.new())
	registry.register_rule(CloseMonthStepRule.new())
	return registry
