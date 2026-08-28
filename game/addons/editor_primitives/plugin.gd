@tool
extends EditorPlugin

const GIZMO_PLUGIN_SCRIPT: GDScript = preload("res://addons/editor_primitives/box_outline_gizmo_plugin.gd")
const MESH_SCRIPT: GDScript = preload("res://primitives/box_outline_mesh.gd")
const NODE_SCRIPT: GDScript = preload("res://primitives/box_outline.gd")

var _gizmo_plugin: EditorNode3DGizmoPlugin
var _refreshing_gizmos: bool = false


func _enter_tree() -> void:
	var plugin_object: Object = GIZMO_PLUGIN_SCRIPT.new()
	if plugin_object is EditorNode3DGizmoPlugin:
		_gizmo_plugin = plugin_object
	if _gizmo_plugin == null:
		push_error("Editor Primitives failed to create the BoxOutline gizmo plugin.")
		return
	add_node_3d_gizmo_plugin(_gizmo_plugin)
	var icon_resource: Resource = load("res://addons/editor_primitives/icons/box_outline.svg")
	var icon_texture: Texture2D = icon_resource as Texture2D
	add_custom_type("BoxOutline", "MeshInstance3D", NODE_SCRIPT, icon_texture)
	var selection: EditorSelection = EditorInterface.get_selection()
	if not selection.selection_changed.is_connected(_refresh_selected_gizmos):
		selection.selection_changed.connect(_refresh_selected_gizmos)
	_refresh_selected_gizmos()


func _exit_tree() -> void:
	var selection: EditorSelection = EditorInterface.get_selection()
	if selection.selection_changed.is_connected(_refresh_selected_gizmos):
		selection.selection_changed.disconnect(_refresh_selected_gizmos)
	remove_custom_type("BoxOutline")
	if _gizmo_plugin != null:
		remove_node_3d_gizmo_plugin(_gizmo_plugin)
		_gizmo_plugin = null


func _refresh_selected_gizmos() -> void:
	if _refreshing_gizmos:
		return
	_refreshing_gizmos = true
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()
	for node: Node in selected_nodes:
		if not _node_needs_outline_gizmo(node):
			continue
		var node_3d: Node3D = node as Node3D
		if node_3d == null:
			continue
		node_3d.set_disable_gizmos(true)
		node_3d.set_disable_gizmos(false)
	_refreshing_gizmos = false


func _node_needs_outline_gizmo(node: Node) -> bool:
	if node is BoxOutline:
		return true
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance == null:
		return false
	if mesh_instance.mesh is BoxOutlineMesh:
		return true
	return mesh_instance.mesh != null and mesh_instance.mesh.get_script() == MESH_SCRIPT
