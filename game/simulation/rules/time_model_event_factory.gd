class_name TimeModelEventFactory
extends RefCounted

const QUARTER_BOUNDARY_EVENT: StringName = &"event.attention.quarter_boundary"


static func create_registry() -> SimulationEventRegistry:
	var registry: SimulationEventRegistry = SimulationEventRegistry.new()
	registry.register_event(QUARTER_BOUNDARY_EVENT)
	registry.register_event(PostCommittedProjectCostsRule.EVENT_ID)
	registry.register_event(AdvanceActiveProjectsRule.EVENT_ID)
	registry.register_event(ResolveProjectCompletionsRule.EVENT_ID)
	registry.register_event(AdvanceCompetitorsRule.EVENT_ID)
	registry.register_event(PostOperatingCostRule.EVENT_ID)
	registry.register_event(PostComputeContractCostsRule.EVENT_ID)
	registry.register_event(PostApplicationRevenueRule.EVENT_ID)
	registry.register_event(CreateQuarterlyReportRule.EVENT_ID)
	return registry
