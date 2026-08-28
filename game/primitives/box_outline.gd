@tool
class_name BoxOutline
extends MeshInstance3D

const SPECIFICATION_REFERENCE: String = "docs/tools/editor-primitives.md"


func _init() -> void:
	mesh = BoxOutlineMesh.new()
