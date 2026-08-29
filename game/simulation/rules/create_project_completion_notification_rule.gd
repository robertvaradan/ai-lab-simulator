class_name CreateProjectCompletionNotificationRule
extends SimulationRule

const RULE_ID: StringName = &"rule.project.create_completion_notifications"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Create Project completion Notifications"
	phase_id = SimulationRulePhase.CREATE_ATTENTION_EVENTS
	execution_order = 20
	read_state_paths = [
		CanonicalSimulationStatePaths.CALENDAR_MONTH_STEP_INDEX,
		CanonicalSimulationStatePaths.COMPANY_PROJECTS,
		CanonicalSimulationStatePaths.NOTIFICATIONS,
		CanonicalSimulationStatePaths.RUNTIME_NOTIFICATION_SEQUENCE,
	]
	write_state_paths = [
		CanonicalSimulationStatePaths.NOTIFICATIONS,
		CanonicalSimulationStatePaths.RUNTIME_NOTIFICATION_SEQUENCE,
	]
	graph_group_id = &"rule_group.projects"
	specification_references = ["docs/marketing/marketing-scenario.md"]


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
	var notifications: Array[NotificationState] = context.read_notifications()
	if context.has_fault():
		return _failed_from_context(context)
	var sequence_result: SimulationIntegerResult = context.read_integer(
		CanonicalSimulationStatePaths.RUNTIME_NOTIFICATION_SEQUENCE
	)
	if not sequence_result.has_value:
		return SimulationRuleEvaluation.failed(sequence_result.diagnostic)
	var next_sequence: int = sequence_result.value
	var project_ids: Array[StringName] = []
	project_ids.assign(projects.keys())
	project_ids.sort()
	var created: bool = false
	for project_id: StringName in project_ids:
		var project: ProjectState = projects[project_id]
		if project == null:
			continue
		if project.status_id != ProjectState.STATUS_COMPLETED:
			continue
		if project.completed_month_step_index != month_result.value:
			continue
		var notification: NotificationState = NotificationState.new()
		notification.stable_id = StableIdentifier.format_runtime_identifier(&"notification", next_sequence)
		notification.notification_type_id = NotificationState.TYPE_PROJECT_COMPLETED
		notification.source_entity_id = project_id
		notifications.append(notification)
		next_sequence += 1
		created = true
	if not created:
		return SimulationRuleEvaluation.did_not_fire()
	if not context.write_integer(
		CanonicalSimulationStatePaths.RUNTIME_NOTIFICATION_SEQUENCE,
		next_sequence
	):
		return _failed_from_context(context)
	if not context.write_notifications(notifications):
		return _failed_from_context(context)
	return SimulationRuleEvaluation.fired()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
