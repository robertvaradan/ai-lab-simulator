class_name GameStateValidationResult
extends RefCounted

var errors: Array[String] = []


func is_valid() -> bool:
	return errors.is_empty()


func add_error(message: String) -> void:
	errors.append(message)


func format_errors() -> String:
	return "\n".join(errors)
