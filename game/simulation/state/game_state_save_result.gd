class_name GameStateSaveResult
extends RefCounted

var error_code: Error = OK
var errors: Array[String] = []


func succeeded() -> bool:
	return error_code == OK and errors.is_empty()


func add_error(message: String, code: Error = ERR_INVALID_DATA) -> void:
	errors.append(message)
	error_code = code


func format_errors() -> String:
	return "\n".join(errors)
