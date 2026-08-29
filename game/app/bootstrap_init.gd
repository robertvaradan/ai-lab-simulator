extends Node


func _ready() -> void:
	SceneRouter.go_to_main_menu(get_tree())
