@tool
extends EditorPlugin

const GIZMO_PLUGIN_SCRIPT: GDScript = preload("res://addons/editor_primitives/box_outline_gizmo_plugin.gd")

var _gizmo_plugin: EditorNode3DGizmoPlugin


func _enter_tree() -> void:
	_gizmo_plugin = GIZMO_PLUGIN_SCRIPT.new() as EditorNode3DGizmoPlugin
	if _gizmo_plugin == null:
		return
	add_node_3d_gizmo_plugin(_gizmo_plugin)


func _exit_tree() -> void:
	if _gizmo_plugin == null:
		return
	remove_node_3d_gizmo_plugin(_gizmo_plugin)
	_gizmo_plugin = null
