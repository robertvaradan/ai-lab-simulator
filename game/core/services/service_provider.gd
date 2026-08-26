class_name ServiceProvider
extends RefCounted

var _context: ServiceContext
var _services: Dictionary[GDScript, Service] = {}
var _registration_order: Array[GDScript] = []
var _is_sealed: bool = false
var _is_disposed: bool = false


func _init(context: ServiceContext) -> void:
	if context == null:
		ServiceContract.fail("missing_provider_context", "A service provider must have an owning service context.")
		return
	_context = context


func provide(service_type: GDScript, implementation: Service) -> void:
	if _is_disposed:
		ServiceContract.fail("provider_disposed", "A disposed provider must not accept a service.")
		return
	if _is_sealed:
		ServiceContract.fail("provide_after_seal", "A sealed provider must not accept a service.")
		return
	if service_type == null:
		ServiceContract.fail("missing_service_type", "A service registration must have a GDScript type.")
		return
	if implementation == null:
		ServiceContract.fail("missing_implementation", "A service registration must have an implementation.")
		return
	if _services.has(service_type):
		ServiceContract.fail("duplicate_registration", "A service type must have exactly one registration.")
		return
	if not is_instance_of(implementation, service_type):
		ServiceContract.fail("wrong_implementation_type", "A service implementation must match its registration type.")
		return
	if implementation.get_context() != _context:
		ServiceContract.fail("wrong_service_context", "A service and its provider must have the same context.")
		return

	_services[service_type] = implementation
	_registration_order.append(service_type)


func seal() -> void:
	if _is_disposed:
		ServiceContract.fail("provider_disposed", "A disposed provider must not be sealed.")
		return
	if _is_sealed:
		ServiceContract.fail("duplicate_seal", "A service provider must be sealed exactly once.")
		return
	_is_sealed = true


func resolve(service_type: GDScript) -> Service:
	if _is_disposed:
		ServiceContract.fail("provider_disposed", "A disposed provider must not resolve a service.")
		return null
	if not _is_sealed:
		ServiceContract.fail("resolve_before_seal", "A provider must be sealed before it resolves a service.")
		return null
	if service_type == null:
		ServiceContract.fail("missing_service_type", "A service resolution must have a GDScript type.")
		return null
	if not _services.has(service_type):
		ServiceContract.fail("missing_registration", "The requested service type must have an exact registration.")
		return null
	return _services[service_type]


func dispose() -> void:
	if _is_disposed:
		ServiceContract.fail("duplicate_disposal", "A service provider must be disposed exactly once.")
		return
	if not _is_sealed:
		ServiceContract.fail("dispose_before_seal", "A provider must be sealed before it is disposed.")
		return

	_is_disposed = true
	for registration_index: int in range(_registration_order.size() - 1, -1, -1):
		var service_type: GDScript = _registration_order[registration_index]
		var implementation: Service = _services[service_type]
		implementation._dispose_from_provider()

	_services.clear()
	_registration_order.clear()


func is_sealed() -> bool:
	return _is_sealed


func is_disposed() -> bool:
	return _is_disposed
