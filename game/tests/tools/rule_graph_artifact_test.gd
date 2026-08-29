extends SceneTree

const TEST_SUCCESS: String = "RULE_GRAPH_ARTIFACT_TEST_SUCCESS"

var _failure_count: int = 0


func _initialize() -> void:
	_verify_marketing_artifact()
	_verify_invalid_graph_fails()
	_finish()


func _verify_marketing_artifact() -> void:
	var result: RuleGraphArtifactResult = RuleGraphArtifactCompiler.compile_marketing_scenario()
	_expect(result.succeeded(), "The Marketing Scenario Rule Graph artifact did not compile:\n%s" % result.format_diagnostics())
	if not result.succeeded():
		return
	var artifact: RuleGraphArtifact = result.artifact
	_expect(artifact.graph_id == &"rule_graph.marketing.first_quarter", "The artifact graph identifier is incorrect.")
	_expect(artifact.graph_version == 1, "The artifact graph version is incorrect.")
	_expect(artifact.content_version >= 1, "The artifact content version is missing.")
	_expect(_has_node(artifact, String(OpenMonthStepRule.RULE_ID), String(RuleGraphArtifact.KIND_RULE)), "The artifact is missing the Open Month Step Rule node.")
	_expect(
		_has_node(artifact, String(CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX), String(RuleGraphArtifact.KIND_STATE_PATH)),
		"The artifact is missing the calendar Month Step state-path node."
	)
	_expect(
		_has_node(artifact, String(TimeModelEventFactory.QUARTER_BOUNDARY_EVENT), String(RuleGraphArtifact.KIND_EVENT)),
		"The artifact is missing the Quarter Boundary event node."
	)
	_expect(
		_has_node(artifact, "project.campus.build_laboratory", String(RuleGraphArtifact.KIND_PROJECT)),
		"The artifact is missing the Build Laboratory Project node."
	)
	_expect(
		_has_node(artifact, "project.research.frontier_model", String(RuleGraphArtifact.KIND_PROJECT)),
		"The artifact is missing the Research Project node."
	)
	_expect(
		_has_edge(
			artifact,
			String(OpenMonthStepRule.RULE_ID),
			String(CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX),
			String(RuleGraphArtifact.EDGE_WRITE)
		),
		"The artifact is missing the Open Month Step write edge."
	)
	_expect(
		_has_edge(
			artifact,
			String(CreateQuarterBoundaryAttentionRule.RULE_ID),
			String(TimeModelEventFactory.QUARTER_BOUNDARY_EVENT),
			String(RuleGraphArtifact.EDGE_EMITS)
		),
		"The artifact is missing the Quarter Boundary emit edge."
	)
	var json_text: String = artifact.to_json_text()
	_expect(not json_text.contains("func "), "The artifact JSON contains copied Rule function text.")
	_expect(not json_text.contains("evaluate("), "The artifact JSON contains copied Rule evaluator text.")
	_expect(json_text.contains("schema_version"), "The artifact JSON is missing the schema version.")
	_expect(json_text.contains("specification_references"), "The artifact JSON is missing specification references.")


func _verify_invalid_graph_fails() -> void:
	var rule_registry: SimulationRuleRegistry = SimulationRuleRegistry.new()
	var invalid_rule: SimulationRule = SimulationRule.new()
	invalid_rule.stable_id = &"rule.test.invalid_graph"
	invalid_rule.display_name = "Invalid graph Rule"
	invalid_rule.phase_id = SimulationRulePhase.CLOSE_MONTH_STEP
	invalid_rule.execution_order = 10
	invalid_rule.graph_group_id = &"rule_group.test"
	rule_registry.register_rule(invalid_rule)
	var compilation: RuleGraphCompilationResult = SimulationRuleGraphCompiler.compile_rule_graph(
		rule_registry,
		CanonicalSimulationStatePaths.create_registry(),
		TimeModelEventFactory.create_registry(),
		&"rule_graph.test.invalid",
		1,
		1
	)
	_expect(not compilation.succeeded(), "An invalid Rule Graph compiled.")
	_expect(compilation.graph == null, "An invalid Rule Graph produced graph data.")


func _has_node(artifact: RuleGraphArtifact, node_id: String, kind: String) -> bool:
	for node: Dictionary in artifact.nodes:
		if str(node["id"]) == node_id and str(node["kind"]) == kind:
			return true
	return false


func _has_edge(artifact: RuleGraphArtifact, from_id: String, to_id: String, kind: String) -> bool:
	for edge: Dictionary in artifact.edges:
		if str(edge["from"]) == from_id and str(edge["to"]) == to_id and str(edge["kind"]) == kind:
			return true
	return false


func _finish() -> void:
	if _failure_count > 0:
		printerr("RULE_GRAPH_ARTIFACT_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=2" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
