class_name AdvanceActiveProjectsRule
extends SimulationRule

const RULE_ID: StringName = &"rule.project.advance_active_projects"
const EVENT_ID: StringName = &"event.project.advanced"


func _init() -> void:
	stable_id = RULE_ID
	display_name = "Advance active Projects"
	phase_id = SimulationRulePhase.ADVANCE_ACTIVE_PROJECTS
	execution_order = 10
	read_state_paths = [CanonicalSimulationStatePaths.COMPANY_PROJECTS]
	write_state_paths = [CanonicalSimulationStatePaths.COMPANY_PROJECTS]
	emitted_event_ids = [EVENT_ID]
	graph_group_id = &"rule_group.projects"
	specification_references = ["docs/simulation/time-model.md"]


func evaluate(context: SimulationContext) -> SimulationRuleEvaluation:
	var projects: Dictionary[StringName, ProjectState] = {}
	projects.assign(context.read_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_PROJECTS))
	if context.has_fault():
		return _failed_from_context(context)
	var project_ids: Array[StringName] = []
	project_ids.assign(projects.keys())
	project_ids.sort()
	var advanced: bool = false
	for project_id: StringName in project_ids:
		var project: ProjectState = projects[project_id]
		if project == null or not project.is_active():
			continue
		if project.remaining_month_steps < 1:
			return SimulationRuleEvaluation.failed(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"rule.project.active_without_remaining_duration",
					"Active Project %s has no remaining Month Steps." % project_id,
					stable_id,
					CanonicalSimulationStatePaths.COMPANY_PROJECTS
				)
			)
		project.remaining_month_steps -= 1
		var payload: Dictionary[StringName, Variant] = {
			&"project_id": project_id,
			&"remaining_month_steps": project.remaining_month_steps,
		}
		if not context.emit_event(EVENT_ID, payload):
			return _failed_from_context(context)
		advanced = true
	if not context.write_resource_dictionary(CanonicalSimulationStatePaths.COMPANY_PROJECTS, projects):
		return _failed_from_context(context)
	if advanced:
		return SimulationRuleEvaluation.fired()
	return SimulationRuleEvaluation.did_not_fire()


func _failed_from_context(context: SimulationContext) -> SimulationRuleEvaluation:
	var diagnostics: Array[SimulationDiagnostic] = context.get_diagnostics()
	return SimulationRuleEvaluation.failed(diagnostics[diagnostics.size() - 1])
