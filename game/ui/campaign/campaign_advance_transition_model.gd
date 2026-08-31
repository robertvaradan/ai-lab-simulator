class_name CampaignAdvanceTransitionModel
extends RefCounted

var month_steps: Array[CampaignAdvanceMonthStep] = []
var cash_before_musd: int = 0
var cash_after_musd: int = 0
var project_changes: PackedStringArray = PackedStringArray()
var new_event_ids: Array[StringName] = []
var world_change_lines: PackedStringArray = PackedStringArray()
var attention_boundary: bool = false


func _init() -> void:
	pass


static func compile(
		previous: GameState,
		published: GameState,
		result: SimulationOperationResult
	) -> CampaignAdvanceTransitionModel:
	if previous == null or published == null or result == null:
		ServiceContract.fail(
			"missing_advance_transition_source",
			"An Advance transition model must have previous state, published state, and a Simulation Operation Result."
		)
		return CampaignAdvanceTransitionModel.new()
	if previous.calendar == null or published.calendar == null:
		ServiceContract.fail(
			"missing_advance_calendar",
			"An Advance transition model must have calendar state."
		)
		return CampaignAdvanceTransitionModel.new()
	if previous.company == null or published.company == null:
		ServiceContract.fail(
			"missing_advance_company",
			"An Advance transition model must have company state."
		)
		return CampaignAdvanceTransitionModel.new()
	var model: CampaignAdvanceTransitionModel = CampaignAdvanceTransitionModel.new()
	model.cash_before_musd = CampaignCatalog.cash_balance_musd(previous)
	model.cash_after_musd = CampaignCatalog.cash_balance_musd(published)
	model.attention_boundary = result.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED
	_fill_month_steps(model, previous, published)
	_fill_project_changes(model, previous, published)
	_fill_new_event_ids(model, previous, published)
	_fill_world_change_lines(model, previous, published)
	return model


static func _fill_month_steps(
		model: CampaignAdvanceTransitionModel,
		previous: GameState,
		published: GameState
	) -> void:
	var start_index: int = previous.calendar.current_month_step_index + 1
	var end_index: int = published.calendar.current_month_step_index
	for index: int in range(start_index, end_index + 1):
		var step: CampaignAdvanceMonthStep = CampaignAdvanceMonthStep.new()
		step.month_step_index = index
		step.quarter_index = (index + 2) / 3
		model.month_steps.append(step)


static func _fill_project_changes(
		model: CampaignAdvanceTransitionModel,
		previous: GameState,
		published: GameState
	) -> void:
	var project_ids: Array[StringName] = []
	var seen: Dictionary[StringName, bool] = {}
	for project_id: StringName in previous.company.projects.keys():
		if seen.has(project_id):
			continue
		seen[project_id] = true
		project_ids.append(project_id)
	for project_id: StringName in published.company.projects.keys():
		if seen.has(project_id):
			continue
		seen[project_id] = true
		project_ids.append(project_id)
	project_ids.sort()
	for project_id: StringName in project_ids:
		var previous_project: ProjectState = null
		if previous.company.projects.has(project_id):
			previous_project = previous.company.projects[project_id]
		var published_project: ProjectState = null
		if published.company.projects.has(project_id):
			published_project = published.company.projects[project_id]
		if previous_project == null and published_project != null:
			model.project_changes.append("The Project %s started." % String(project_id))
		if (
			published_project != null
			and published_project.status_id == ProjectState.STATUS_COMPLETED
			and (previous_project == null or previous_project.status_id != ProjectState.STATUS_COMPLETED)
		):
			model.project_changes.append("The Project %s completed." % String(project_id))


static func _fill_new_event_ids(
		model: CampaignAdvanceTransitionModel,
		previous: GameState,
		published: GameState
	) -> void:
	var previous_ids: Dictionary[StringName, bool] = {}
	for event: AttentionEventState in previous.attention_events:
		if event == null:
			continue
		previous_ids[event.stable_id] = true
	for notification: NotificationState in previous.notifications:
		if notification == null:
			continue
		previous_ids[notification.stable_id] = true
	var appeared: Array[StringName] = []
	for event: AttentionEventState in published.attention_events:
		if event == null:
			continue
		if previous_ids.has(event.stable_id):
			continue
		appeared.append(event.stable_id)
	for notification: NotificationState in published.notifications:
		if notification == null:
			continue
		if previous_ids.has(notification.stable_id):
			continue
		appeared.append(notification.stable_id)
	appeared.sort()
	model.new_event_ids.assign(appeared)


static func _fill_world_change_lines(
		model: CampaignAdvanceTransitionModel,
		previous: GameState,
		published: GameState
	) -> void:
	var previous_label: String = CampaignCatalog.laboratory_stage_label(previous)
	var published_label: String = CampaignCatalog.laboratory_stage_label(published)
	if previous_label != published_label:
		model.world_change_lines.append(
			"The laboratory changed from %s to %s." % [previous_label, published_label]
		)
	var previous_mapping: CampusVisualMapping = CampusVisualMapping.from_state(previous)
	var published_mapping: CampusVisualMapping = CampusVisualMapping.from_state(published)
	if not previous_mapping.compute_link_visible and published_mapping.compute_link_visible:
		model.world_change_lines.append("The Third-Party Compute link appeared.")
	if not previous_mapping.competitor_release_visible and published_mapping.competitor_release_visible:
		model.world_change_lines.append("The Northstar Flagship release resolved.")
