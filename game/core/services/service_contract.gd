@abstract
class_name ServiceContract
extends RefCounted

const FAILURE_PREFIX: String = "SERVICE_CONTRACT_FAILURE"


static func fail(code: String, message: String) -> void:
	var failure_message: String = "%s code=%s message=%s" % [FAILURE_PREFIX, code, message]
	push_error(failure_message)
	OS.crash(failure_message)
