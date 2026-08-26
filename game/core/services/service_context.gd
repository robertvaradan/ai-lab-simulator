@abstract
class_name ServiceContext
extends Node

var _service_provider: ServiceProvider


func _enter_tree() -> void:
	if _service_provider != null:
		ServiceContract.fail("active_provider_on_enter", "A service context must not have an active provider when it enters the tree.")
		return
	_service_provider = ServiceProvider.new(self)
	_register_services(_service_provider)
	_service_provider.seal()
	_inject_services(_service_provider)


func _exit_tree() -> void:
	if _service_provider == null:
		ServiceContract.fail("missing_provider_on_exit", "A service context must have a provider when it exits the tree.")
		return
	_service_provider.dispose()
	_service_provider = null


@abstract
func _register_services(provider: ServiceProvider) -> void


@abstract
func _inject_services(provider: ServiceProvider) -> void
