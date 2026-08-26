class_name GameStateLoadResult
extends RefCounted

var state: GameState
var errors: Array[String] = []


func succeeded() -> bool:
	return state != null and errors.is_empty()


func add_error(message: String) -> void:
	errors.append(message)


func format_errors() -> String:
	return "\n".join(errors)
