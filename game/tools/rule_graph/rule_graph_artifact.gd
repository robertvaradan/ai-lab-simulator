class_name RuleGraphArtifact
extends RefCounted

const SCHEMA_VERSION: int = 1
const KIND_RULE: StringName = &"node.rule"
const KIND_STATE_PATH: StringName = &"node.state_path"
const KIND_EVENT: StringName = &"node.event"
const KIND_PROJECT: StringName = &"node.project"
const EDGE_READ: StringName = &"edge.read"
const EDGE_WRITE: StringName = &"edge.write"
const EDGE_EMITS: StringName = &"edge.emits"
const EDGE_CONSUMES: StringName = &"edge.consumes"
const EDGE_ORDER: StringName = &"edge.order"

var graph_id: StringName = &""
var graph_version: int = -1
var content_version: int = -1
var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []


func to_canonical_dictionary() -> Dictionary:
	var data: Dictionary = {}
	data["schema_version"] = SCHEMA_VERSION
	data["graph_id"] = String(graph_id)
	data["graph_version"] = graph_version
	data["content_version"] = content_version
	var exported_nodes: Array = []
	for node: Dictionary in nodes:
		exported_nodes.append(node.duplicate(true))
	data["nodes"] = exported_nodes
	var exported_edges: Array = []
	for edge: Dictionary in edges:
		exported_edges.append(edge.duplicate(true))
	data["edges"] = exported_edges
	return data


func to_json_text() -> String:
	return JSON.stringify(to_canonical_dictionary(), "\t")


func write_json(path: String) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(to_json_text())
	file.close()
	return OK
