class_name SceneRouter
extends RefCounted

const INIT_PATH: String = "res://scenes/init.tscn"
const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const CAMPAIGN_PATH: String = "res://scenes/campaign.tscn"


static func go_to_main_menu(tree: SceneTree) -> void:
	_change_to(tree, MAIN_MENU_PATH)


static func go_to_campaign(tree: SceneTree) -> void:
	_change_to(tree, CAMPAIGN_PATH)


static func _change_to(tree: SceneTree, path: String) -> void:
	if tree == null:
		ServiceContract.fail("missing_scene_tree", "A scene change requires a SceneTree.")
		return
	if not ResourceLoader.exists(path):
		ServiceContract.fail("missing_scene", "The required scene is missing: %s" % path)
		return
	var err: Error = tree.change_scene_to_file(path)
	if err != OK:
		ServiceContract.fail(
			"scene_change_failed",
			"The scene change failed for %s with error %d." % [path, err]
		)
