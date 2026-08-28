@tool
class_name CylinderOutline
extends MeshInstance3D

const SPECIFICATION_REFERENCE: String = "docs/tools/editor-primitives.md"


func _init() -> void:
	mesh = CylinderOutlineMesh.new()
