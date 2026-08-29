class_name RuleGraphArtifactCompiler
extends RefCounted

const DEFAULT_SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"


static func compile_marketing_scenario(path: String = DEFAULT_SCENARIO_PATH) -> RuleGraphArtifactResult:
	var result: RuleGraphArtifactResult = RuleGraphArtifactResult.new()
	var definition: MarketingScenarioDefinition = MarketingScenarioFactory.load_definition(path)
	if definition == null:
		result.diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule_graph_artifact.missing_scenario",
				"The Marketing Scenario definition did not load: %s" % path
			)
		)
		return result
	var content_registry: SimulationContentRegistry = definition.build_content_registry()
	var rule_registry: SimulationRuleRegistry = TimeModelRuleFactory.create_registry()
	var state_path_registry: SimulationStatePathRegistry = CanonicalSimulationStatePaths.create_registry()
	var event_registry: SimulationEventRegistry = TimeModelEventFactory.create_registry()
	var compilation: RuleGraphCompilationResult = SimulationRuleGraphCompiler.compile_rule_graph(
		rule_registry,
		state_path_registry,
		event_registry,
		definition.rule_graph_id,
		definition.rule_graph_version,
		definition.content_version
	)
	if not compilation.succeeded():
		result.diagnostics.append_array(compilation.diagnostics)
		return result
	result.artifact = _build_artifact(
		compilation.graph,
		state_path_registry,
		event_registry,
		content_registry
	)
	return result


static func _build_artifact(
		graph: CompiledRuleGraph,
		state_path_registry: SimulationStatePathRegistry,
		event_registry: SimulationEventRegistry,
		content_registry: SimulationContentRegistry
	) -> RuleGraphArtifact:
	var artifact: RuleGraphArtifact = RuleGraphArtifact.new()
	artifact.graph_id = graph.graph_id
	artifact.graph_version = graph.graph_version
	artifact.content_version = graph.content_version
	var ordered_rules: Array[SimulationRule] = graph.ordered_rules
	for rule: SimulationRule in ordered_rules:
		var node: Dictionary = {
			"id": String(rule.stable_id),
			"kind": String(RuleGraphArtifact.KIND_RULE),
			"display_name": rule.display_name,
			"phase_id": String(rule.phase_id),
			"execution_order": rule.execution_order,
			"graph_group_id": String(rule.graph_group_id),
			"specification_references": rule.specification_references.duplicate(),
		}
		artifact.nodes.append(node)
	for path_id: StringName in state_path_registry.get_path_ids():
		var path_node: Dictionary = {
			"id": String(path_id),
			"kind": String(RuleGraphArtifact.KIND_STATE_PATH),
		}
		artifact.nodes.append(path_node)
	for event_id: StringName in event_registry.get_event_ids():
		var event_node: Dictionary = {
			"id": String(event_id),
			"kind": String(RuleGraphArtifact.KIND_EVENT),
		}
		artifact.nodes.append(event_node)
	for project_id: StringName in content_registry.get_project_ids():
		var project_node: Dictionary = {
			"id": String(project_id),
			"kind": String(RuleGraphArtifact.KIND_PROJECT),
		}
		artifact.nodes.append(project_node)
	for rule: SimulationRule in ordered_rules:
		for path_id: StringName in rule.read_state_paths:
			artifact.edges.append(_edge(rule.stable_id, path_id, RuleGraphArtifact.EDGE_READ))
		for path_id: StringName in rule.write_state_paths:
			artifact.edges.append(_edge(rule.stable_id, path_id, RuleGraphArtifact.EDGE_WRITE))
		for event_id: StringName in rule.emitted_event_ids:
			artifact.edges.append(_edge(rule.stable_id, event_id, RuleGraphArtifact.EDGE_EMITS))
		for event_id: StringName in rule.consumed_event_ids:
			artifact.edges.append(_edge(event_id, rule.stable_id, RuleGraphArtifact.EDGE_CONSUMES))
		for dependency_id: StringName in rule.order_after_rule_ids:
			artifact.edges.append(_edge(dependency_id, rule.stable_id, RuleGraphArtifact.EDGE_ORDER))
	return artifact


static func _edge(from_id: StringName, to_id: StringName, kind: StringName) -> Dictionary:
	return {
		"from": String(from_id),
		"to": String(to_id),
		"kind": String(kind),
	}
