extends SceneTree

const TEST_SUCCESS: String = "CAMPUS_VISUAL_PRESENTER_TEST_SUCCESS"
const RESEARCH_ID: StringName = &"project.research.frontier_model"
const SCALE_ID: StringName = &"project.scale.burst_compute"
const CODING_AGENT_PROJECT_ID: StringName = &"project.application.coding_agent"
const SITE_ID: StringName = &"site.company.sf_campus"
const RESEARCH_PLOT_ID: StringName = &"plot.campus.research"
const COMPUTE_PLOT_ID: StringName = &"plot.campus.compute_link"

var _failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_verify_starting_mapping()
	_verify_scale_mapping()
	_verify_empty_quarter_mapping()
	_verify_hybrid_mapping_and_plots()
	_verify_presenter_applies_mapping()
	_finish()


func _verify_starting_mapping() -> void:
	var lab_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(lab_created.succeeded(), "The starting laboratory session did not start.")
	if not lab_created.succeeded():
		return
	var mapping: CampusVisualMapping = CampusVisualMapping.from_state(lab_created.session.get_state())
	_expect(not mapping.uses_developed_laboratory(), "The starting campus uses the developed laboratory.")
	_expect(not mapping.compute_link_visible, "The starting campus shows the burst Compute link.")
	_expect(not mapping.competitor_release_visible, "The starting campus shows the Northstar release.")


func _verify_scale_mapping() -> void:
	var lab_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(lab_created.succeeded(), "The Scale laboratory session did not start.")
	if not lab_created.succeeded():
		return
	var lab: SimulationLabSession = lab_created.session
	lab.stage_command(_scale_command(lab.get_state(), 0))
	lab.commit_staged_plan()
	lab.step_month()
	var mapping: CampusVisualMapping = CampusVisualMapping.from_state(lab.get_state())
	_expect(mapping.compute_link_visible, "The completed Scale Project does not show the burst Compute link.")
	_expect(not mapping.uses_developed_laboratory(), "The Scale-only run swapped the laboratory stage.")
	_expect(not mapping.competitor_release_visible, "Month Step 1 showed the Northstar release.")
	_expect(
		lab.get_state().company.sites[SITE_ID].site_plots[COMPUTE_PLOT_ID].state_id
		== &"site_plot_state.no_link",
		"The presentation wrote a Compute-link Site Plot state."
	)


func _verify_empty_quarter_mapping() -> void:
	var lab_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(lab_created.succeeded(), "The empty-plan laboratory session did not start.")
	if not lab_created.succeeded():
		return
	var lab: SimulationLabSession = lab_created.session
	lab.commit_staged_plan()
	lab.advance_until_attention_required()
	var mapping: CampusVisualMapping = CampusVisualMapping.from_state(lab.get_state())
	_expect(mapping.competitor_release_visible, "The Quarter Boundary does not show the Northstar release.")
	_expect(mapping.competitor_presentation_text.contains("Northstar Flagship"), "The Competitor presentation is missing the Model name.")
	_expect(mapping.competitor_presentation_text.contains("Coding 82"), "The Competitor presentation is missing the actual coding evaluation.")
	_expect(mapping.competitor_presentation_text.contains("Reasoning 78"), "The Competitor presentation is missing the actual reasoning evaluation.")
	_expect(mapping.competitor_presentation_text.contains("Efficiency 72"), "The Competitor presentation is missing the actual efficiency evaluation.")
	_expect(not mapping.uses_developed_laboratory(), "The empty Plan swapped the laboratory stage.")
	_expect(not mapping.compute_link_visible, "The empty Plan showed the burst Compute link.")


func _verify_hybrid_mapping_and_plots() -> void:
	var lab_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(lab_created.succeeded(), "The hybrid laboratory session did not start.")
	if not lab_created.succeeded():
		return
	var lab: SimulationLabSession = lab_created.session
	lab.stage_command(_research_command(lab.get_state(), 0))
	lab.stage_command(_coding_command(lab.get_state(), 1))
	lab.commit_staged_plan()
	lab.advance_until_attention_required()
	var state: GameState = lab.get_state()
	var mapping: CampusVisualMapping = CampusVisualMapping.from_state(state)
	_expect(mapping.uses_developed_laboratory(), "The completed Research Project did not select laboratory stage 2.")
	_expect(mapping.competitor_release_visible, "The hybrid Quarter Boundary does not show the Northstar release.")
	_expect(not mapping.compute_link_visible, "The hybrid run showed the burst Compute link.")
	_expect(
		state.company.sites[SITE_ID].site_plots[RESEARCH_PLOT_ID].state_id
		== &"site_plot_state.compact_lab",
		"The presentation wrote a Research Site Plot state."
	)


func _verify_presenter_applies_mapping() -> void:
	var holder: Node = Node.new()
	holder.name = "MarketingPlayHost"
	var campus: Node3D = Node3D.new()
	campus.name = "CampusBlockout"
	var lab_stage_one: Node3D = Node3D.new()
	lab_stage_one.name = "LabStage1"
	campus.add_child(lab_stage_one)
	var presenter: CampusVisualPresenter = CampusVisualPresenter.new()
	presenter.name = "CampusVisualPresenter"
	holder.add_child(campus)
	holder.add_child(presenter)
	root.add_child(holder)
	var start_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(start_created.succeeded(), "The presenter starting session did not start.")
	if not start_created.succeeded():
		holder.queue_free()
		return
	presenter.present_state(start_created.session.get_state())
	_expect(presenter.get_visible_laboratory_node_name() == "LabStage1", "The starting presenter hid laboratory stage 1.")
	_expect(not presenter.is_compute_link_visible(), "The starting presenter showed the Compute link.")
	_expect(not presenter.is_competitor_presentation_visible(), "The starting presenter showed the Competitor release.")
	var hybrid_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(hybrid_created.succeeded(), "The presenter hybrid session did not start.")
	if not hybrid_created.succeeded():
		holder.queue_free()
		return
	var hybrid: SimulationLabSession = hybrid_created.session
	hybrid.stage_command(_research_command(hybrid.get_state(), 0))
	hybrid.stage_command(_coding_command(hybrid.get_state(), 1))
	hybrid.commit_staged_plan()
	hybrid.advance_until_attention_required()
	presenter.present_state(hybrid.get_state())
	_expect(presenter.get_visible_laboratory_node_name() == "LabStage2", "The hybrid presenter did not show laboratory stage 2.")
	_expect(not lab_stage_one.visible, "The hybrid presenter left laboratory stage 1 visible.")
	_expect(presenter.is_competitor_presentation_visible(), "The hybrid presenter hid the Competitor release.")
	_expect(
		presenter.get_competitor_presentation_text().contains("Coding 82"),
		"The hybrid presenter did not show the actual Northstar coding evaluation."
	)
	_expect(not presenter.is_compute_link_visible(), "The hybrid presenter showed the Compute link.")
	holder.queue_free()


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
	payload[&"release_strategy_id"] = &"release_strategy.commercial_api"
	command.payload = payload
	return command


func _scale_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	var payload: Dictionary[StringName, Variant] = {}
	payload[&"project_id"] = SCALE_ID
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
	payload[&"supporting_model_id"] = &"model.player.starting"
	command.payload = payload
	return command


func _finish() -> void:
	if _failure_count > 0:
		printerr("CAMPUS_VISUAL_PRESENTER_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=5" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
