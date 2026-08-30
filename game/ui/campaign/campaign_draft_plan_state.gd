class_name CampaignDraftPlanState
extends RefCounted

const DEFAULT_MODEL_DISPLAY_NAME: String = "Aperture"
const DEFAULT_MODEL_VERSION_LABEL: String = "2.0"
const DEFAULT_RELEASE_STRATEGY_ID: StringName = &"release_strategy.commercial_api"

var staged_project_ids: Dictionary[StringName, bool] = {}
var model_display_name: String = DEFAULT_MODEL_DISPLAY_NAME
var model_version_label: String = DEFAULT_MODEL_VERSION_LABEL
var acknowledged_attention_ids: Dictionary[StringName, bool] = {}


func _init() -> void:
	pass


func has_staged_project(project_id: StringName) -> bool:
	return staged_project_ids.has(project_id) and staged_project_ids[project_id]


func set_project_staged(project_id: StringName, staged: bool) -> void:
	if staged:
		staged_project_ids[project_id] = true
		return
	staged_project_ids.erase(project_id)


func acknowledge_attention(attention_event_id: StringName) -> void:
	acknowledged_attention_ids[attention_event_id] = true


func has_acknowledged_attention(attention_event_id: StringName) -> bool:
	return acknowledged_attention_ids.has(attention_event_id) and acknowledged_attention_ids[attention_event_id]


func clear_staging_after_advance() -> void:
	staged_project_ids.clear()
	acknowledged_attention_ids.clear()


func reset() -> void:
	staged_project_ids.clear()
	acknowledged_attention_ids.clear()
	model_display_name = DEFAULT_MODEL_DISPLAY_NAME
	model_version_label = DEFAULT_MODEL_VERSION_LABEL


func build_plan(state: GameState) -> Plan:
	var plan: Plan = Plan.new()
	if state == null:
		return plan
	var command_index: int = 0
	if state.company != null:
		if has_staged_project(CampaignCatalog.BUILD_LABORATORY_PROJECT_ID) and not state.company.projects.has(
			CampaignCatalog.BUILD_LABORATORY_PROJECT_ID
		):
			plan.commands.append(_build_lab_command(state, command_index))
			command_index += 1
		if has_staged_project(CampaignCatalog.RESEARCH_PROJECT_ID) and not state.company.projects.has(
			CampaignCatalog.RESEARCH_PROJECT_ID
		):
			plan.commands.append(_research_command(state, command_index))
			command_index += 1
		if has_staged_project(CampaignCatalog.SCALE_PROJECT_ID) and not state.company.projects.has(
			CampaignCatalog.SCALE_PROJECT_ID
		):
			plan.commands.append(_scale_command(state, command_index))
			command_index += 1
		if has_staged_project(CampaignCatalog.CODING_AGENT_PROJECT_ID) and not state.company.projects.has(
			CampaignCatalog.CODING_AGENT_PROJECT_ID
		):
			plan.commands.append(_coding_agent_command(state, command_index))
	for event: AttentionEventState in state.attention_events:
		if event == null:
			continue
		if not has_acknowledged_attention(event.stable_id):
			continue
		var response: AttentionEventResponse = AttentionEventResponse.new()
		response.attention_event_id = event.stable_id
		response.response_type_id = AcknowledgmentAttentionEventResponseValidator.ACKNOWLEDGMENT_RESPONSE_TYPE_ID
		plan.attention_event_responses.append(response)
	return plan


func _build_lab_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[ProjectDefinition.PAYLOAD_PROJECT_ID] = CampaignCatalog.BUILD_LABORATORY_PROJECT_ID
	command.payload = payload
	return command


func _research_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[ProjectDefinition.PAYLOAD_PROJECT_ID] = CampaignCatalog.RESEARCH_PROJECT_ID
	payload[ProjectDefinition.PAYLOAD_MODEL_DISPLAY_NAME] = model_display_name
	payload[ProjectDefinition.PAYLOAD_MODEL_VERSION_LABEL] = model_version_label
	payload[ProjectDefinition.PAYLOAD_RELEASE_STRATEGY_ID] = DEFAULT_RELEASE_STRATEGY_ID
	command.payload = payload
	return command


func _scale_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[ProjectDefinition.PAYLOAD_PROJECT_ID] = CampaignCatalog.SCALE_PROJECT_ID
	command.payload = payload
	return command


func _coding_agent_command(state: GameState, command_index: int) -> Command:
	var command: Command = _make_command(state, command_index)
	var payload: Dictionary[StringName, Variant] = {}
	payload[ProjectDefinition.PAYLOAD_PROJECT_ID] = CampaignCatalog.CODING_AGENT_PROJECT_ID
	payload[ProjectDefinition.PAYLOAD_SUPPORTING_MODEL_ID] = CampaignCatalog.STARTING_MODEL_ID
	command.payload = payload
	return command


func _make_command(state: GameState, command_index: int) -> Command:
	var command: Command = Command.new()
	command.stable_id = StableIdentifier.format_runtime_identifier(
		&"command",
		state.runtime_id_counters.next_sequence_by_entity_type[&"command"] + command_index
	)
	command.command_type_id = ProjectPlanValidator.START_COMMAND_TYPE
	return command
