extends Node


func _ready() -> void:
	var window: Window = get_window()
	UiScale.apply_to_window(window)
	if window != null and not window.size_changed.is_connected(_on_window_size_changed):
		window.size_changed.connect(_on_window_size_changed)


func _exit_tree() -> void:
	var window: Window = get_window()
	if window != null and window.size_changed.is_connected(_on_window_size_changed):
		window.size_changed.disconnect(_on_window_size_changed)


func _on_window_size_changed() -> void:
	UiScale.apply_to_window(get_window())
