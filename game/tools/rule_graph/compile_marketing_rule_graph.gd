extends SceneTree

const SUCCESS_MARKER: String = "RULE_GRAPH_COMPILE_SUCCESS"
const OUTPUT_PATH: String = "user://generated/rule_graph.marketing.first_quarter.json"


func _initialize() -> void:
	var result: RuleGraphArtifactResult = RuleGraphArtifactCompiler.compile_marketing_scenario()
	if not result.succeeded():
		printerr("RULE_GRAPH_COMPILE_FAILURE\n%s" % result.format_diagnostics())
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://generated"))
	var write_error: Error = result.artifact.write_json(OUTPUT_PATH)
	if write_error != OK:
		printerr("RULE_GRAPH_COMPILE_FAILURE write error=%d" % write_error)
		quit(1)
		return
	print(
		"%s graph_id=%s graph_version=%d content_version=%d nodes=%d edges=%d path=%s"
		% [
			SUCCESS_MARKER,
			result.artifact.graph_id,
			result.artifact.graph_version,
			result.artifact.content_version,
			result.artifact.nodes.size(),
			result.artifact.edges.size(),
			OUTPUT_PATH,
		]
	)
	quit(0)
