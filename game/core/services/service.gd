@abstract
class_name Service
extends RefCounted

var _context: ServiceContext
var _is_disposed: bool = false


func _init(context: ServiceContext) -> void:
	if context == null:
		ServiceContract.fail("missing_service_context", "A service must have an owning service context.")
		return
	_context = context


func get_context() -> ServiceContext:
	return _context


func is_disposed() -> bool:
	return _is_disposed


func _dispose_from_provider() -> void:
	if _is_disposed:
		ServiceContract.fail("duplicate_service_disposal", "A service must be disposed exactly once by its provider.")
		return
	_is_disposed = true
	_on_dispose()


func _on_dispose() -> void:
	pass
