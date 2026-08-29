extends SceneTree

const TEST_SUCCESS: String = "DECISION_HOST_TEST_SUCCESS"
const SCENE_PATH: String = "res://tools/decision_host/decision_host.tscn"
const RESEARCH_ID: StringName = &"project.research.frontier_model"
const SCALE_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_PROJECT_ID: StringName = &"project.application.coding_agent"

var _failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_verify_catalog_rejects_extra_command_type()
	_verify_catalog_rejects_unknown_payload_key()
	_verify_scene_has_no_campus()
	var construction_host: DecisionHost = _make_host()
	root.add_child(construction_host)
	_verify_registry_controls(construction_host)
	construction_host.queue_free()
	var empty_host: DecisionHost = _make_host()
	root.add_child(empty_host)
	_verify_empty_plan_matches_laboratory(empty_host)
	empty_host.queue_free()
	var rejection_host: DecisionHost = _make_host()
	root.add_child(rejection_host)
	_verify_three_project_rejection(rejection_host)
	rejection_host.queue_free()
	var hybrid_host: DecisionHost = _make_host()
	root.add_child(hybrid_host)
	_verify_hybrid_matches_laboratory(hybrid_host)
	hybrid_host.queue_free()
	_finish()


func _verify_catalog_rejects_extra_command_type() -> void:
	var registry: SimulationContentRegistry = SimulationContentRegistry.new(&"scenario.marketing", 1)
	_expect(registry.register_content(&"command.project.start"), "The start Command type content did not register.")
	_expect(registry.register_command_type(&"command.project.start"), "The start Command type did not register.")
	_expect(registry.register_content(&"command.test.extra"), "The extra Command type content did not register.")
	_expect(registry.register_command_type(&"command.test.extra"), "The extra Command type did not register.")
	var diagnostics: Array[SimulationDiagnostic] = DecisionHostCatalog.validate(registry)
	_expect(not diagnostics.is_empty(), "An extra Command type passed Decision Host construction.")
	if not diagnostics.is_empty():
		_expect(
			diagnostics[0].code == &"decision_host.unsupported_command_type",
			"The extra Command type did not report decision_host.unsupported_command_type."
		)


func _verify_catalog_rejects_unknown_payload_key() -> void:
	var registry: SimulationContentRegistry = SimulationContentRegistry.new(&"scenario.marketing", 1)
	_expect(registry.register_content(&"command.project.start"), "The start Command type content did not register.")
	_expect(registry.register_command_type(&"command.project.start"), "The start Command type did not register.")
	_expect(registry.register_content(&"project.test.extra"), "The extra Project content did not register.")
	var definition: ProjectDefinition = ProjectDefinition.new()
	definition.stable_id = &"project.test.extra"
	definition.required_payload_keys = [&"project_id", &"payload.unknown"]
	_expect(registry.register_project_definition(definition), "The extra Project definition did not register.")
	var diagnostics: Array[SimulationDiagnostic] = DecisionHostCatalog.validate(registry)
	_expect(not diagnostics.is_empty(), "An unknown payload key passed Decision Host construction.")
	if not diagnostics.is_empty():
		_expect(
			diagnostics[0].code == &"decision_host.unsupported_payload_key",
			"The unknown payload key did not report decision_host.unsupported_payload_key."
		)


func _verify_scene_has_no_campus() -> void:
	var packed_resource: Resource = load(SCENE_PATH)
	_expect(packed_resource is PackedScene, "The Decision Host scene did not load.")
	if not packed_resource is PackedScene:
		return
	var packed_scene: PackedScene = packed_resource
	var scene_root: Node = packed_scene.instantiate()
	_expect(scene_root != null, "The Decision Host scene did not instantiate.")
	if scene_root == null:
		return
	_expect(
		scene_root.get_node_or_null("CampusBlockout") == null,
		"The Decision Host scene instances CampusBlockout."
	)
	scene_root.free()


func _verify_registry_controls(host: DecisionHost) -> void:
	_expect(host.get_core() != null, "The Decision Host has no Simulation Core.")
	_expect(host.get_view() != null, "The Decision Host has no view.")
	var registry_ids: Array[StringName] = host.get_core().get_content_registry().get_project_ids()
	var presented_ids: Array[StringName] = host.get_view().get_presented_project_ids()
	_expect(presented_ids == registry_ids, "The Decision Host did not present one control per registered Project.")
	_expect(presented_ids.size() == 3, "The Marketing Scenario Decision Host did not present three Projects.")


func _verify_empty_plan_matches_laboratory(host: DecisionHost) -> void:
	var lab_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(lab_created.succeeded(), "The empty-plan laboratory session did not start.")
	if not lab_created.succeeded():
		return
	var lab: SimulationLabSession = lab_created.session
	lab.commit_staged_plan()
	lab.advance_until_attention_required()
	var plan: Plan = host.get_view().build_plan(host.get_current_state())
	_expect(plan.commands.is_empty(), "The empty Decision Host Plan staged Project Commands.")
	var advanced: SimulationOperationResult = host.advance_with_plan(plan)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The empty Decision Host Advance did not stop at the Attention Boundary."
	)
	_expect(
		var_to_bytes_with_objects(host.get_current_state())
		== var_to_bytes_with_objects(lab.get_state()),
		"The empty Decision Host run does not match the laboratory Game State."
	)
	_expect(
		host.get_current_state().cash_ledger.calculate_balance_musd()
		== lab.get_cash_ledger().calculate_balance_musd(),
		"The empty Decision Host run does not match the laboratory Cash."
	)
	_expect(
		host.get_view().get_inspect_text().contains(String(OpenMonthStepRule.RULE_ID)),
		"The Decision Host inspect text is missing last-Advance Rule statuses."
	)
	_expect(
		host.get_view().get_inspect_text().contains("fired")
		or host.get_view().get_inspect_text().contains("did_not_fire"),
		"The Decision Host inspect text is missing Rule evaluation status words."
	)
	_expect(
		host.get_view().get_inspect_text().contains("MUSD"),
		"The Decision Host inspect text is missing Cash Ledger lines."
	)


func _verify_three_project_rejection(host: DecisionHost) -> void:
	host.get_view().set_project_selected(RESEARCH_ID, true)
	host.get_view().set_project_selected(SCALE_ID, true)
	host.get_view().set_project_selected(CODING_AGENT_PROJECT_ID, true)
	var plan: Plan = host.get_view().build_plan(host.get_current_state())
	_expect(plan.commands.size() == 3, "The three-Project Decision Host Plan does not contain three Commands.")
	var result: SimulationOperationResult = host.advance_with_plan(plan)
	_expect(result.outcome == SimulationOperationOutcome.Type.REJECTED, "The three-Project Plan was not rejected.")
	_expect(host.get_current_state().calendar.current_month_step_index == 0, "A rejected Plan advanced time.")
	_expect(not result.diagnostics.is_empty(), "The rejected Plan has no diagnostics.")
	_expect(
		host.get_view().get_diagnostics_text() != "None."
		and host.get_view().get_status_text() == "Advance rejected.",
		"The Decision Host did not present rejection diagnostics."
	)


func _verify_hybrid_matches_laboratory(host: DecisionHost) -> void:
	host.get_view().set_project_selected(RESEARCH_ID, true)
	host.get_view().set_project_selected(CODING_AGENT_PROJECT_ID, true)
	host.get_view().set_model_identity(RESEARCH_ID, "Aperture", "2.0")
	var lab_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(lab_created.succeeded(), "The hybrid laboratory session did not start.")
	if not lab_created.succeeded():
		return
	var lab: SimulationLabSession = lab_created.session
	lab.stage_command(_research_command(lab.get_state(), 0))
	lab.stage_command(_coding_command(lab.get_state(), 1))
	lab.commit_staged_plan()
	lab.advance_until_attention_required()
	var plan: Plan = host.get_view().build_plan(host.get_current_state())
	_expect(plan.commands.size() == 2, "The hybrid Decision Host Plan does not contain two Commands.")
	_expect(_plan_uses_hidden_defaults(plan), "The hybrid Decision Host Plan does not use Marketing Play hidden defaults.")
	var advanced: SimulationOperationResult = host.advance_with_plan(plan)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The hybrid Decision Host Advance did not stop at the Attention Boundary."
	)
	_expect(
		var_to_bytes_with_objects(host.get_current_state())
		== var_to_bytes_with_objects(lab.get_state()),
		"The hybrid Decision Host run does not match the laboratory Game State."
	)
	_expect(host.get_current_state().cash_ledger.calculate_balance_musd() == 36, "The hybrid ending Cash is incorrect.")
	_expect(
		host.get_view().get_inspect_text().contains("remaining_month_steps"),
		"The hybrid Decision Host inspect text is missing Project remaining duration."
	)


func _plan_uses_hidden_defaults(plan: Plan) -> bool:
	var saw_release_strategy: bool = false
	var saw_supporting_model: bool = false
	for command: Command in plan.commands:
		if command == null:
			continue
		if command.payload.has(&"release_strategy_id"):
			saw_release_strategy = true
			if command.payload[&"release_strategy_id"] != DecisionHostCatalog.HIDDEN_RELEASE_STRATEGY_VALUE:
				return false
		if command.payload.has(&"supporting_model_id"):
			saw_supporting_model = true
			if command.payload[&"supporting_model_id"] != DecisionHostCatalog.HIDDEN_SUPPORTING_MODEL_VALUE:
				return false
	return saw_release_strategy and saw_supporting_model


func _research_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = RESEARCH_ID
	payload[&"model_display_name"] = "Aperture"
	payload[&"model_version_label"] = "2.0"
	payload[&"release_strategy_id"] = DecisionHostCatalog.HIDDEN_RELEASE_STRATEGY_VALUE
	command.payload = payload
	return command


func _coding_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = CODING_AGENT_PROJECT_ID
	payload[&"supporting_model_id"] = DecisionHostCatalog.HIDDEN_SUPPORTING_MODEL_VALUE
	command.payload = payload
	return command


func _make_host() -> DecisionHost:
	var host: DecisionHost = DecisionHost.new()
	host.name = "DecisionHost"
	var view: DecisionHostView = DecisionHostView.new()
	view.name = "View"
	host.add_child(view)
	return host


func _finish() -> void:
	if _failure_count > 0:
		printerr("DECISION_HOST_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=6" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
