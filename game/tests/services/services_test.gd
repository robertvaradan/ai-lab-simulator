extends SceneTree

const TEST_SUCCESS: String = "SERVICES_TEST_SUCCESS"
const NEGATIVE_ACCEPTED: String = "SERVICES_TEST_NEGATIVE_CASE_ACCEPTED"

var _failure_count: int = 0


class FirstTestService extends Service:
	var _events: Array[String]

	func _init(context: ServiceContext, events: Array[String]) -> void:
		super(context)
		_events = events

	func _on_dispose() -> void:
		_events.append("dispose_first")


class SecondTestService extends Service:
	var _events: Array[String]

	func _init(context: ServiceContext, events: Array[String]) -> void:
		super(context)
		_events = events

	func _on_dispose() -> void:
		_events.append("dispose_second")


class TestConsumer extends Node:
	var _events: Array[String]
	var injected_service: FirstTestService

	func _init(events: Array[String]) -> void:
		_events = events

	func inject(service: FirstTestService) -> void:
		injected_service = service
		_events.append("inject")

	func _enter_tree() -> void:
		if injected_service == null:
			_events.append("consumer_entered_without_injection")
		else:
			_events.append("consumer_ready")


class TestServiceContext extends ServiceContext:
	var events: Array[String]
	var first_service: FirstTestService
	var second_service: SecondTestService
	var consumer: TestConsumer
	var provider_was_sealed_during_injection: bool = false

	func _init(shared_events: Array[String]) -> void:
		events = shared_events
		consumer = TestConsumer.new(events)
		consumer.name = "TestConsumer"
		add_child(consumer)

	func _register_services(provider: ServiceProvider) -> void:
		events.append("register")
		first_service = FirstTestService.new(self, events)
		second_service = SecondTestService.new(self, events)
		provider.provide(FirstTestService, first_service)
		provider.provide(SecondTestService, second_service)

	func _inject_services(provider: ServiceProvider) -> void:
		events.append("inject_hook")
		provider_was_sealed_during_injection = provider.is_sealed()
		var resolved_service: Service = provider.resolve(FirstTestService)
		consumer.inject(resolved_service as FirstTestService)


class EmptyServiceContext extends ServiceContext:
	func _register_services(_provider: ServiceProvider) -> void:
		pass

	func _inject_services(_provider: ServiceProvider) -> void:
		pass


func _initialize() -> void:
	call_deferred("_run_selected_case")


func _run_selected_case() -> void:
	var test_case: String = _get_test_case()
	if test_case == "positive":
		_run_positive_case()
		return
	_run_negative_case(test_case)


func _get_test_case() -> String:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 2 or arguments[0] != "--case":
		printerr("Expected test arguments: --case <name>")
		quit(2)
		return ""
	return arguments[1]


func _run_positive_case() -> void:
	var events: Array[String] = []
	var context: TestServiceContext = TestServiceContext.new(events)
	context.name = "TestServiceContext"
	root.add_child(context)

	_expect(context.provider_was_sealed_during_injection, "The provider was not sealed before injection.")
	_expect(context.first_service.get_context() == context, "The service does not own its context reference.")
	_expect(context.consumer.injected_service == context.first_service, "The consumer did not receive the registered service.")
	_expect(
		events == ["register", "inject_hook", "inject", "consumer_ready"],
		"Registration and injection did not finish before consumer readiness."
	)

	root.remove_child(context)
	_expect(context.first_service.is_disposed(), "The first service was not disposed.")
	_expect(context.second_service.is_disposed(), "The second service was not disposed.")
	_expect(
		events.slice(events.size() - 2) == ["dispose_second", "dispose_first"],
		"Services were not disposed in reverse registration order."
	)
	context.free()

	if _failure_count > 0:
		printerr("SERVICES_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=1" % TEST_SUCCESS)
	quit(0)


func _run_negative_case(test_case: String) -> void:
	var first_events: Array[String] = []
	var second_events: Array[String] = []
	var first_context: EmptyServiceContext = EmptyServiceContext.new()
	var second_context: EmptyServiceContext = EmptyServiceContext.new()
	var provider: ServiceProvider = ServiceProvider.new(first_context)
	var first_service: FirstTestService = FirstTestService.new(first_context, first_events)
	var second_service: SecondTestService = SecondTestService.new(first_context, first_events)

	match test_case:
		"duplicate_registration":
			provider.provide(FirstTestService, first_service)
			provider.provide(FirstTestService, first_service)
		"missing_registration":
			provider.seal()
			provider.resolve(FirstTestService)
		"wrong_implementation_type":
			provider.provide(FirstTestService, second_service)
		"wrong_service_context":
			var foreign_service: FirstTestService = FirstTestService.new(second_context, second_events)
			provider.provide(FirstTestService, foreign_service)
		"resolve_before_seal":
			provider.provide(FirstTestService, first_service)
			provider.resolve(FirstTestService)
		"provide_after_seal":
			provider.seal()
			provider.provide(FirstTestService, first_service)
		_:
			printerr("Unknown negative service test case: %s" % test_case)
			quit(2)
			return

	printerr("%s case=%s" % [NEGATIVE_ACCEPTED, test_case])
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
