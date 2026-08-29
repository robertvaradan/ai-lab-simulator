class_name ProjectPlanValidator
extends RefCounted

const START_COMMAND_TYPE: StringName = &"command.project.start"


static func validate_start_commands(
		state: GameState,
		commands: Array[Command],
		content_registry: SimulationContentRegistry,
		result: PlanValidationResult
	) -> void:
	var start_commands: Array[Command] = []
	for command: Command in commands:
		if command == null:
			continue
		if command.command_type_id != START_COMMAND_TYPE:
			continue
		start_commands.append(command)

	var planned_project_ids: Dictionary[StringName, bool] = {}
	var reserved_teams: int = ProjectCapacity.reserved_project_teams(state.company.projects)
	var reserved_compute: int = ProjectCapacity.reserved_compute_unit_months(state.company.projects)
	var planned_cost_musd: int = 0

	for command: Command in start_commands:
		var project_id: Variant = command.payload.get(ProjectDefinition.PAYLOAD_PROJECT_ID, null)
		if typeof(project_id) != TYPE_STRING_NAME:
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s must contain payload key project_id." % command.stable_id
			)
			continue
		var typed_project_id: StringName = StringName(str(project_id))
		if planned_project_ids.has(typed_project_id):
			result._add_rejection(
				&"plan.project_duplicate_start",
				"Plan Command %s starts Project %s more than once." % [command.stable_id, typed_project_id]
			)
		planned_project_ids[typed_project_id] = true
		if state.company.projects.has(typed_project_id):
			result._add_rejection(
				&"plan.project_already_exists",
				"Plan Command %s starts Project %s that already exists."
				% [command.stable_id, typed_project_id]
			)
		var definition: ProjectDefinition = content_registry.get_project_definition(typed_project_id)
		if definition == null:
			result._add_rejection(
				&"plan.project_unknown",
				"Plan Command %s starts unknown Project %s." % [command.stable_id, typed_project_id]
			)
			continue
		_validate_payload(command, definition, state, content_registry, result)
		_validate_prerequisites(command, definition, state, result)
		planned_cost_musd += definition.start_cost_musd
		reserved_teams += definition.reserved_project_teams
		reserved_compute += definition.reserved_compute_unit_months

	var cash_balance_musd: int = state.cash_ledger.calculate_balance_musd()
	if planned_cost_musd > cash_balance_musd:
		result._add_rejection(
			&"plan.project_cost_exceeds_cash",
			"The Plan Project start cost of %d MUSD exceeds Cash balance %d MUSD."
			% [planned_cost_musd, cash_balance_musd]
		)
	if reserved_teams > state.company.project_team_count:
		result._add_rejection(
			&"plan.project_teams_exceeded",
			"The Plan reserves %d project teams and the Company has %d project teams."
			% [reserved_teams, state.company.project_team_count]
		)
	if reserved_compute > state.company.compute_capacity_unit_months:
		result._add_rejection(
			&"plan.project_compute_exceeded",
			"The Plan reserves more Compute Capacity than the Company has as free Compute Capacity."
		)


static func _validate_payload(
		command: Command,
		definition: ProjectDefinition,
		state: GameState,
		content_registry: SimulationContentRegistry,
		result: PlanValidationResult
	) -> void:
	var required_keys: Dictionary[StringName, bool] = {}
	for required_key: StringName in definition.required_payload_keys:
		required_keys[required_key] = true
		if not command.payload.has(required_key):
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s is missing payload key %s." % [command.stable_id, required_key]
			)
	var payload_keys: Array[StringName] = []
	payload_keys.assign(command.payload.keys())
	payload_keys.sort()
	for payload_key: StringName in payload_keys:
		if not required_keys.has(payload_key):
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s has unknown payload key %s." % [command.stable_id, payload_key]
			)
	if command.payload.has(ProjectDefinition.PAYLOAD_PROJECT_ID):
		var project_id: Variant = command.payload[ProjectDefinition.PAYLOAD_PROJECT_ID]
		if project_id != definition.stable_id:
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s project_id %s does not match Project %s."
				% [command.stable_id, project_id, definition.stable_id]
			)
	if command.payload.has(ProjectDefinition.PAYLOAD_MODEL_DISPLAY_NAME):
		if typeof(command.payload[ProjectDefinition.PAYLOAD_MODEL_DISPLAY_NAME]) != TYPE_STRING:
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s model_display_name must be a string." % command.stable_id
			)
		elif str(command.payload[ProjectDefinition.PAYLOAD_MODEL_DISPLAY_NAME]).is_empty():
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s model_display_name is missing." % command.stable_id
			)
	if command.payload.has(ProjectDefinition.PAYLOAD_MODEL_VERSION_LABEL):
		if typeof(command.payload[ProjectDefinition.PAYLOAD_MODEL_VERSION_LABEL]) != TYPE_STRING:
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s model_version_label must be a string." % command.stable_id
			)
		elif str(command.payload[ProjectDefinition.PAYLOAD_MODEL_VERSION_LABEL]).is_empty():
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s model_version_label is missing." % command.stable_id
			)
	if command.payload.has(ProjectDefinition.PAYLOAD_RELEASE_STRATEGY_ID):
		if typeof(command.payload[ProjectDefinition.PAYLOAD_RELEASE_STRATEGY_ID]) != TYPE_STRING_NAME:
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s release_strategy_id must be a stable identifier." % command.stable_id
			)
		else:
			var release_strategy_id: StringName = StringName(str(command.payload[ProjectDefinition.PAYLOAD_RELEASE_STRATEGY_ID]))
			if not content_registry.build_content_catalog().has(release_strategy_id):
				result._add_rejection(
					&"plan.project_release_strategy_unknown",
					"Plan Command %s Release Strategy %s is unknown."
					% [command.stable_id, release_strategy_id]
				)
	if command.payload.has(ProjectDefinition.PAYLOAD_SUPPORTING_MODEL_ID):
		if typeof(command.payload[ProjectDefinition.PAYLOAD_SUPPORTING_MODEL_ID]) != TYPE_STRING_NAME:
			result._add_rejection(
				&"plan.project_payload_invalid",
				"Plan Command %s supporting_model_id must be a stable identifier." % command.stable_id
			)
		else:
			var supporting_model_id: StringName = StringName(str(command.payload[ProjectDefinition.PAYLOAD_SUPPORTING_MODEL_ID]))
			if not state.company.models.has(supporting_model_id):
				result._add_rejection(
					&"plan.project_supporting_model_unknown",
					"Plan Command %s supporting Model %s does not exist."
					% [command.stable_id, supporting_model_id]
				)
			else:
				var supporting_model: ModelState = state.company.models[supporting_model_id]
				if supporting_model.release_state_id != &"model_release_state.released":
					result._add_rejection(
						&"plan.project_supporting_model_unreleased",
						"Plan Command %s supporting Model %s is not released."
						% [command.stable_id, supporting_model_id]
					)


static func _validate_prerequisites(
		command: Command,
		definition: ProjectDefinition,
		state: GameState,
		result: PlanValidationResult
	) -> void:
	for prerequisite_id: StringName in definition.prerequisite_project_ids:
		if not state.company.projects.has(prerequisite_id):
			result._add_rejection(
				&"plan.project_prerequisite_missing",
				"Plan Command %s requires completed Project %s." % [command.stable_id, prerequisite_id]
			)
			continue
		var prerequisite: ProjectState = state.company.projects[prerequisite_id]
		if prerequisite.status_id != ProjectState.STATUS_COMPLETED:
			result._add_rejection(
				&"plan.project_prerequisite_incomplete",
				"Plan Command %s requires completed Project %s." % [command.stable_id, prerequisite_id]
			)
