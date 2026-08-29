class_name ResolveProjectCompletionsRule
extends SimulationRule

const RULE_ID: StringName = &"rule.project.resolve_completions"
const EVENT_ID: StringName = &"event.project.completed"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Resolve Project completions"
	phase_id = SimulationRulePhase.RESOLVE_PROJECT_COMPLETIONS
	execution_order = 10
	read_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.COMPANY_PROJECTS,
		CanonicalSimulationStatePaths.COMPANY_MODELS,
		CanonicalSimulationStatePaths.COMPANY_APPLICATIONS,
		CanonicalSimulationStatePaths.COMPANY_CONTRACTS,
		CanonicalSimulationStatePaths.COMPANY_COMPUTE_CAPACITY,
	]
	write_state_paths = [
		CanonicalSimulationStatePaths.COMPANY_PROJECTS,
		CanonicalSimulationStatePaths.COMPANY_MODELS,
		CanonicalSimulationStatePaths.COMPANY_APPLICATIONS,
		CanonicalSimulationStatePaths.COMPANY_CONTRACTS,
		CanonicalSimulationStatePaths.COMPANY_COMPUTE_CAPACITY,
	]
	emitted_event_ids = [EVENT_ID]
	graph_group_id = &"rule_group.projects"
	specification_references = [
		"docs/marketing/marketing-scenario.md",
		"docs/simulation/time-model.md",
	]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var month_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX
	)
	if not month_result.has_value:
		return SimulationRuleEvaluation.failed(month_result.diagnostic)
	var projects: Dictionary[StringName, ProjectState] = {}
	projects.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_PROJECTS))
	if context.has_fault():
		return _failed_from_context(context)
	var models: Dictionary[StringName, ModelState] = {}
	models.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_MODELS))
	if context.has_fault():
		return _failed_from_context(context)
	var applications: Dictionary[StringName, ApplicationState] = {}
	applications.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_APPLICATIONS))
	if context.has_fault():
		return _failed_from_context(context)
	var contracts: Dictionary[StringName, ContractState] = {}
	contracts.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_CONTRACTS))
	if context.has_fault():
		return _failed_from_context(context)
	var compute_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.COMPANY_COMPUTE_CAPACITY
	)
	if not compute_result.has_value:
		return SimulationRuleEvaluation.failed(compute_result.diagnostic)
	var compute_capacity: int = compute_result.value
	var project_ids: Array[StringName] = []
	project_ids.assign(projects.keys())
	project_ids.sort()
	var completed: bool = false
	for project_id: StringName in project_ids:
		var project: ProjectState = projects[project_id]
		if project == null or not project.is_active():
			continue
		if project.remaining_month_steps > 0:
			continue
		var definition: ProjectDefinition = context.get_project_definition(project.content_definition_id)
		if definition == null:
			return _failed_from_context(context)
		var effect_diagnostic: SimulationDiagnostic = _apply_completion_effect(
			definition,
			project,
			models,
			applications,
			contracts
		)
		if effect_diagnostic != null:
			return SimulationRuleEvaluation.failed(effect_diagnostic)
		if definition.completion_effect_id == ProjectDefinition.EFFECT_BURST_COMPUTE:
			compute_capacity += definition.completed_contract_compute_unit_months
		project.status_id = ProjectState.STATUS_COMPLETED
		project.reserved_project_teams = 0
		project.reserved_compute_unit_months = 0
		project.completed_month_step_index = month_result.value
		var payload: Dictionary[StringName, Variant] = {
			&"project_id": project_id,
			&"month_step_index": month_result.value,
			&"completion_effect_id": definition.completion_effect_id,
		}
		if not context.emit_event(EVENT_ID, payload):
			return _failed_from_context(context)
		completed = true
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_PROJECTS, projects):
		return _failed_from_context(context)
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_MODELS, models):
		return _failed_from_context(context)
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_APPLICATIONS, applications):
		return _failed_from_context(context)
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_CONTRACTS, contracts):
		return _failed_from_context(context)
	if not context.write_integer(CanonicalSimulationStatePaths.COMPANY_COMPUTE_CAPACITY, compute_capacity):
		return _failed_from_context(context)
	if completed:
		return SimulationRuleEvaluation.fired()
	return SimulationRuleEvaluation.did_not_fire()


func _apply_completion_effect(
		definition: ProjectDefinition,
		project: ProjectState,
		models: Dictionary[StringName, ModelState],
		applications: Dictionary[StringName, ApplicationState],
		contracts: Dictionary[StringName, ContractState]
	) -> SimulationDiagnostic:
	match definition.completion_effect_id:
		ProjectDefinition.EFFECT_RESEARCH_MODEL:
			return _create_research_model(definition, project, models)
		ProjectDefinition.EFFECT_BURST_COMPUTE:
			return _create_burst_contract(definition, contracts)
		ProjectDefinition.EFFECT_CODING_AGENT:
			return _create_coding_agent(definition, project, models, applications)
		_:
			return SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"rule.project.unknown_completion_effect",
				"Project %s has unknown completion effect %s."
				% [project.stable_id, definition.completion_effect_id],
				stable_id,
				CanonicalSimulationStatePaths.COMPANY_PROJECTS
			)


func _create_research_model(
		definition: ProjectDefinition,
		project: ProjectState,
		models: Dictionary[StringName, ModelState]
	) -> SimulationDiagnostic:
	if models.has(definition.completed_model_id):
		return SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"rule.project.completed_model_exists",
			"Completed Model %s already exists." % definition.completed_model_id,
			stable_id,
			CanonicalSimulationStatePaths.COMPANY_MODELS
		)
	var display_name: String = str(project.start_payload[ProjectDefinition.PAYLOAD_MODEL_DISPLAY_NAME])
	var version_label: String = str(project.start_payload[ProjectDefinition.PAYLOAD_MODEL_VERSION_LABEL])
	var release_strategy_id: StringName = StringName(str(project.start_payload[ProjectDefinition.PAYLOAD_RELEASE_STRATEGY_ID]))
	var evaluations: ModelEvaluationState = ModelEvaluationState.new()
	evaluations.coding_evaluation_points = definition.completed_model_coding_evaluation_points
	evaluations.reasoning_evaluation_points = definition.completed_model_reasoning_evaluation_points
	evaluations.efficiency_evaluation_points = definition.completed_model_efficiency_evaluation_points
	var model: ModelState = ModelState.new()
	model.stable_id = definition.completed_model_id
	model.display_name = display_name
	model.version_label = version_label
	model.release_state_id = &"model_release_state.released"
	model.release_strategy_id = release_strategy_id
	model.evaluations = evaluations
	model.training_compute_unit_months = project.reserved_compute_unit_months
	model.inference_compute_unit_months_per_contract = (
		definition.completed_model_inference_compute_unit_months_per_contract
	)
	models[model.stable_id] = model
	return null


func _create_burst_contract(
		definition: ProjectDefinition,
		contracts: Dictionary[StringName, ContractState]
	) -> SimulationDiagnostic:
	if contracts.has(definition.completed_contract_id):
		return SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"rule.project.completed_contract_exists",
			"Completed contract %s already exists." % definition.completed_contract_id,
			stable_id,
			CanonicalSimulationStatePaths.COMPANY_CONTRACTS
		)
	var contract: ContractState = ContractState.new()
	contract.stable_id = definition.completed_contract_id
	contract.content_definition_id = definition.completed_contract_id
	contract.status_id = &"contract_state.active"
	contracts[contract.stable_id] = contract
	return null


func _create_coding_agent(
		definition: ProjectDefinition,
		project: ProjectState,
		models: Dictionary[StringName, ModelState],
		applications: Dictionary[StringName, ApplicationState]
	) -> SimulationDiagnostic:
	if applications.has(definition.completed_application_id):
		return SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"rule.project.completed_application_exists",
			"Completed Application %s already exists." % definition.completed_application_id,
			stable_id,
			CanonicalSimulationStatePaths.COMPANY_APPLICATIONS
		)
	var supporting_model_id: StringName = StringName(str(project.start_payload[ProjectDefinition.PAYLOAD_SUPPORTING_MODEL_ID]))
	if not models.has(supporting_model_id):
		return SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			&"rule.project.supporting_model_missing",
			"Coding Agent supporting Model %s does not exist." % supporting_model_id,
			stable_id,
			CanonicalSimulationStatePaths.COMPANY_MODELS
		)
	var application: ApplicationState = ApplicationState.new()
	application.stable_id = definition.completed_application_id
	application.content_definition_id = definition.completed_application_id
	application.status_id = ApplicationState.STATUS_ACTIVE
	application.supporting_model_id = supporting_model_id
	application.price_musd_per_contract_month = (
		definition.completed_application_price_musd_per_contract_month
	)
	application.active_customer_contract_count = 0
	applications[application.stable_id] = application
	return null


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
