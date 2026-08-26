extends SceneTree

const SCENARIO_PATH: String = "res://simulation/content/marketing_scenario.tres"
const VALID_SNAPSHOT_PATH: String = "user://ms1_01_publication_valid.tres"
const INVALID_SNAPSHOT_PATH: String = "user://ms1_01_publication_invalid.tres"
const TEST_SUCCESS: String = "GAME_STATE_PUBLICATION_TEST_SUCCESS"

var _failure_count: int = 0


class GameStateConsumer extends Node:
	var service: GameStateService
	var entered_with_service: bool = false

	func inject(game_state_service: GameStateService) -> void:
		service = game_state_service

	func _enter_tree() -> void:
		entered_with_service = service != null


class GameStateHostContext extends ServiceContext:
	var definition: MarketingScenarioDefinition
	var initial_state: GameState
	var service: GameStateService
	var consumer: GameStateConsumer

	func _init(scenario_definition: MarketingScenarioDefinition, starting_state: GameState) -> void:
		definition = scenario_definition
		initial_state = starting_state
		consumer = GameStateConsumer.new()
		consumer.name = "GameStateConsumer"
		add_child(consumer)

	func _register_services(provider: ServiceProvider) -> void:
		service = GameStateService.new(
			self,
			initial_state,
			definition.stable_id,
			definition.content_version,
			definition.rule_graph_id,
			definition.rule_graph_version,
			definition.build_content_reference_catalog()
		)
		provider.provide(GameStateService, service)

	func _inject_services(provider: ServiceProvider) -> void:
		var resolved_service: Service = provider.resolve(GameStateService)
		consumer.inject(resolved_service as GameStateService)


class PublicationListener extends RefCounted:
	var notification_count: int = 0
	var current_state: GameState
	var previous_state: GameState

	func on_game_state_changed(replacement: GameState, previous: GameState) -> void:
		notification_count += 1
		current_state = replacement
		previous_state = previous


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_remove_test_file(VALID_SNAPSHOT_PATH)
	_remove_test_file(INVALID_SNAPSHOT_PATH)

	var definition: MarketingScenarioDefinition = MarketingScenarioFactory.load_definition(SCENARIO_PATH)
	_expect(definition != null, "The Marketing Scenario definition did not load.")
	if definition == null:
		_finish()
		return
	var initial_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	_expect(initial_result.succeeded(), "The initial Game State was not created.")
	if not initial_result.succeeded():
		_finish()
		return

	var context: GameStateHostContext = GameStateHostContext.new(definition, initial_result.state)
	context.name = "GameStateHostContext"
	root.add_child(context)
	_expect(context.consumer.entered_with_service, "GameStateService was not injected before consumer entry.")
	_expect(context.consumer.service == context.service, "The consumer did not receive GameStateService.")

	var service: GameStateService = context.service
	var echo: GameStateEcho = service.get_game_state_echo()
	var listener: PublicationListener = PublicationListener.new()
	echo.game_state_changed.connect(listener.on_game_state_changed)
	_expect(echo.is_initialized(), "GameStateEcho did not accept the valid initial Game State.")
	_expect(echo.get_current_state() == initial_result.state, "GameStateEcho does not hold the initial Game State.")
	_expect(not echo.has_previous_state(), "GameStateEcho has a previous state before a replacement.")
	_expect(echo.get_previous_state() == null, "GameStateEcho exposes a previous state before a replacement.")
	_expect(listener.notification_count == 0, "Listener connection caused an implicit initial notification.")

	var null_publication: GameStateValidationResult = service.publish_operation_result(null)
	_expect(not null_publication.is_valid(), "GameStateService accepted a missing operation result.")
	var rejected_publication: GameStateValidationResult = service.publish_operation_result(
		_new_failed_operation_result(SimulationOperationOutcome.Type.REJECTED)
	)
	_expect(not rejected_publication.is_valid(), "GameStateService published a REJECTED result.")
	var faulted_publication: GameStateValidationResult = service.publish_operation_result(
		_new_failed_operation_result(SimulationOperationOutcome.Type.FAULTED)
	)
	_expect(not faulted_publication.is_valid(), "GameStateService published a FAULTED result.")
	var inconsistent_result: SimulationOperationResult = SimulationOperationResult.new(
		SimulationOperationOutcome.Type.REJECTED,
		initial_result.state,
		SimulationTrace.new(&"operation.test.inconsistent_publication", 0),
		_new_operation_diagnostics(&"operation.test.inconsistent_publication")
	)
	var inconsistent_publication: GameStateValidationResult = service.publish_operation_result(
		inconsistent_result
	)
	_expect(not inconsistent_publication.is_valid(), "GameStateService published an inconsistent result.")
	_expect(listener.notification_count == 0, "A failed operation result notified a listener.")

	var invalid_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	invalid_result.state.schema_version = 2
	var invalid_publication: GameStateValidationResult = service.publish_operation_result(
		_new_success_operation_result(
			SimulationOperationOutcome.Type.COMPLETED,
			invalid_result.state,
			&"operation.test.invalid_candidate"
		)
	)
	_expect(not invalid_publication.is_valid(), "GameStateService accepted an invalid Game State.")
	_expect(echo.get_current_state() == initial_result.state, "An invalid replacement changed the current Game State.")
	_expect(not echo.has_previous_state(), "An invalid replacement created a previous Game State.")
	_expect(listener.notification_count == 0, "An invalid replacement notified a listener.")

	var replacement_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	var replacement_state: GameState = replacement_result.state
	replacement_state.company.models[&"model.player.starting"].display_name = "Keystone"
	var publication: GameStateValidationResult = service.publish_operation_result(
		_new_success_operation_result(
			SimulationOperationOutcome.Type.COMPLETED,
			replacement_state,
			&"operation.test.completed_publication"
		)
	)
	_expect(publication.is_valid(), "GameStateService rejected a valid replacement:\n%s" % publication.format_errors())
	_expect(echo.get_current_state() == replacement_state, "GameStateEcho did not publish the replacement.")
	_expect(echo.has_previous_state(), "GameStateEcho did not record a previous state.")
	_expect(echo.get_previous_state() == initial_result.state, "GameStateEcho recorded the wrong previous state.")
	_expect(listener.notification_count == 1, "A valid replacement did not notify exactly once.")
	_expect(listener.current_state == replacement_state, "The listener did not receive the complete replacement.")
	_expect(listener.previous_state == initial_result.state, "The listener did not receive the previous state.")
	_expect(
		listener.current_state.company.models[&"model.player.starting"].display_name == "Keystone",
		"The listener observed an incomplete replacement Game State."
	)

	var same_instance_publication: GameStateValidationResult = service.publish_operation_result(
		_new_success_operation_result(
			SimulationOperationOutcome.Type.COMPLETED,
			replacement_state,
			&"operation.test.same_instance_publication"
		)
	)
	_expect(not same_instance_publication.is_valid(), "GameStateService accepted the current instance as a replacement.")
	_expect(listener.notification_count == 1, "A same-instance replacement notified a listener.")

	var decision_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	var decision_state: GameState = decision_result.state
	decision_state.company.models[&"model.player.starting"].display_name = "Decision"
	var decision_publication: GameStateValidationResult = service.publish_operation_result(
		_new_success_operation_result(
			SimulationOperationOutcome.Type.DECISION_REQUIRED,
			decision_state,
			&"operation.test.decision_publication"
		)
	)
	_expect(decision_publication.is_valid(), "GameStateService rejected a DECISION_REQUIRED result.")
	_expect(echo.get_current_state() == decision_state, "The DECISION_REQUIRED result was not published.")
	_expect(echo.get_previous_state() == replacement_state, "The DECISION_REQUIRED publication has the wrong previous state.")
	_expect(listener.notification_count == 2, "The DECISION_REQUIRED publication did not notify exactly once.")

	_verify_snapshot_publication(definition, service, echo, listener, decision_state)

	root.remove_child(context)
	context.free()
	_finish()


func _verify_snapshot_publication(
		definition: MarketingScenarioDefinition,
		service: GameStateService,
		echo: GameStateEcho,
		listener: PublicationListener,
		previous_committed_state: GameState
	) -> void:
	var notification_count_before: int = listener.notification_count
	var invalid_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	invalid_result.state.schema_version = 2
	var raw_save_error: Error = ResourceSaver.save(invalid_result.state, INVALID_SNAPSHOT_PATH)
	_expect(raw_save_error == OK, "The invalid publication fixture could not be saved.")
	if raw_save_error == OK:
		var invalid_load: GameStateLoadResult = service.load_snapshot(INVALID_SNAPSHOT_PATH)
		_expect(not invalid_load.succeeded(), "GameStateService loaded an incompatible snapshot.")
		_expect(echo.get_current_state() == previous_committed_state, "A failed load replaced the current Game State.")
		_expect(listener.notification_count == notification_count_before, "A failed load notified a listener.")

	var loaded_state_result: GameStateLoadResult = MarketingScenarioFactory.create_state(definition)
	loaded_state_result.state.company.models[&"model.player.starting"].display_name = "Atlas"
	var save_result: GameStateSaveResult = GameStateSnapshotStore.save_snapshot(
		loaded_state_result.state,
		VALID_SNAPSHOT_PATH,
		definition.stable_id,
		definition.content_version,
		definition.rule_graph_id,
		definition.rule_graph_version,
		definition.build_content_reference_catalog()
	)
	_expect(save_result.succeeded(), "The valid publication fixture could not be saved.")
	if save_result.succeeded():
		var valid_load: GameStateLoadResult = service.load_snapshot(VALID_SNAPSHOT_PATH)
		_expect(valid_load.succeeded(), "GameStateService rejected a valid snapshot:\n%s" % valid_load.format_errors())
		_expect(echo.get_current_state() == valid_load.state, "The valid loaded Game State was not published.")
		_expect(echo.get_previous_state() == previous_committed_state, "The loaded replacement recorded the wrong previous state.")
		_expect(
			listener.notification_count == notification_count_before + 1,
			"The loaded replacement did not notify exactly once."
		)
		_expect(listener.current_state == valid_load.state, "The listener did not receive the loaded replacement.")
		_expect(
			listener.current_state.company.models[&"model.player.starting"].display_name == "Atlas",
			"The listener did not observe the complete loaded Game State."
		)


func _new_success_operation_result(
		outcome: SimulationOperationOutcome.Type,
		candidate_state: GameState,
		operation_id: StringName
	) -> SimulationOperationResult:
	var diagnostics: Array[SimulationDiagnostic] = []
	return SimulationOperationResult.new(
		outcome,
		candidate_state,
		SimulationTrace.new(operation_id, 0),
		diagnostics
	)


func _new_failed_operation_result(
		outcome: SimulationOperationOutcome.Type
	) -> SimulationOperationResult:
	var operation_id: StringName = &"operation.test.rejected_publication"
	if outcome == SimulationOperationOutcome.Type.FAULTED:
		operation_id = &"operation.test.faulted_publication"
	return SimulationOperationResult.new(
		outcome,
		null,
		SimulationTrace.new(operation_id, 0),
		_new_operation_diagnostics(operation_id)
	)


func _new_operation_diagnostics(code: StringName) -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = [
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			code,
			"The test operation did not complete."
		),
	]
	return diagnostics


func _remove_test_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var remove_error: Error = DirAccess.remove_absolute(absolute_path)
	if remove_error != OK:
		_expect(false, "The test file could not be removed: %s" % path)


func _finish() -> void:
	_remove_test_file(VALID_SNAPSHOT_PATH)
	_remove_test_file(INVALID_SNAPSHOT_PATH)
	if _failure_count > 0:
		printerr("GAME_STATE_PUBLICATION_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=1" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
