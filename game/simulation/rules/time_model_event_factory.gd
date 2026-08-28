class_name TimeModelEventFactory
extends RefCounted

const QUARTER_BOUNDARY_EVENT: StringName = &"event.attention.quarter_boundary"


static func create_registry() -> SimulationEventRegistry:
	var registry: SimulationEventRegistry = SimulationEventRegistry.new()
	registry.register_event(QUARTER_BOUNDARY_EVENT)
	return registry
