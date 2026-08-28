@tool
extends EditorPlugin

const BOX_GIZMO_SCRIPT: GDScript = preload("res://addons/editor_primitives/box_outline_gizmo_plugin.gd")
const CYLINDER_GIZMO_SCRIPT: GDScript = preload("res://addons/editor_primitives/cylinder_outline_gizmo_plugin.gd")
const BOX_MESH_SCRIPT: GDScript = preload("res://primitives/box_outline_mesh.gd")
const CYLINDER_MESH_SCRIPT: GDScript = preload("res://primitives/cylinder_outline_mesh.gd")
const BOX_NODE_SCRIPT: GDScript = preload("res://primitives/box_outline.gd")
const CYLINDER_NODE_SCRIPT: GDScript = preload("res://primitives/cylinder_outline.gd")

var _gizmo_plugins: Array[EditorNode3DGizmoPlugin] = []
var _refreshing_gizmos: bool = false


func _enter_tree() -> void:
	_register_gizmo(BOX_GIZMO_SCRIPT, "BoxOutline")
	_register_gizmo(CYLINDER_GIZMO_SCRIPT, "CylinderOutline")
	_register_custom_type("BoxOutline", BOX_NODE_SCRIPT, "res://addons/editor_primitives/icons/box_outline.svg")
	_register_custom_type(
		"CylinderOutline",
		CYLINDER_NODE_SCRIPT,
		"res://addons/editor_primitives/icons/cylinder_outline.svg"
	)
	var selection: EditorSelection = EditorInterface.get_selection()
	if not selection.selection_changed.is_connected(_refresh_selected_gizmos):
		selection.selection_changed.connect(_refresh_selected_gizmos)
	_refresh_selected_gizmos()


func _exit_tree() -> void:
	var selection: EditorSelection = EditorInterface.get_selection()
	if selection.selection_changed.is_connected(_refresh_selected_gizmos):
		selection.selection_changed.disconnect(_refresh_selected_gizmos)
	remove_custom_type("CylinderOutline")
	remove_custom_type("BoxOutline")
	for plugin: EditorNode3DGizmoPlugin in _gizmo_plugins:
		remove_node_3d_gizmo_plugin(plugin)
	_gizmo_plugins.clear()


func _register_gizmo(script: GDScript, label: String) -> void:
	var plugin_object: Object = script.new()
	if plugin_object is EditorNode3DGizmoPlugin:
		var plugin: EditorNode3DGizmoPlugin = plugin_object
		_gizmo_plugins.append(plugin)
		add_node_3d_gizmo_plugin(plugin)
		return
	push_error("Editor Primitives failed to create the %s gizmo plugin." % label)


func _register_custom_type(type_name: String, node_script: GDScript, icon_path: String) -> void:
	var icon_resource: Resource = load(icon_path)
	var icon_texture: Texture2D = icon_resource as Texture2D
	add_custom_type(type_name, "MeshInstance3D", node_script, icon_texture)


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
	if node is CylinderOutline:
		return true
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance == null:
		return false
	if mesh_instance.mesh is BoxOutlineMesh:
		return true
	if mesh_instance.mesh is CylinderOutlineMesh:
		return true
	if mesh_instance.mesh == null:
		return false
	var mesh_script: Variant = mesh_instance.mesh.get_script()
	return mesh_script == BOX_MESH_SCRIPT or mesh_script == CYLINDER_MESH_SCRIPT
