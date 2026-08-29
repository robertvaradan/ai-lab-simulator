class_name MarketingScenarioDefinition
extends Resource

@export var schema_version: int = -1
@export var content_version: int = -1
@export var rule_graph_id: StringName = &""
@export var rule_graph_version: int = -1
@export var stable_id: StringName = &""
@export var difficulty_profile_id: StringName = &""
@export var specification_reference: String = ""
@export var starting_game_state: GameState
@export var available_project_ids: Array[StringName] = []
@export var project_definitions: Array[ProjectDefinition] = []
@export var command_type_ids: Array[StringName] = []
@export var content_reference_ids: Array[StringName] = []


func _init() -> void:
	pass


func build_content_reference_catalog() -> Dictionary[StringName, bool]:
	var catalog: Dictionary[StringName, bool] = {}
	for identifier: StringName in content_reference_ids:
		catalog[identifier] = true
	return catalog


func build_content_registry() -> SimulationContentRegistry:
	var registry: SimulationContentRegistry = SimulationContentRegistry.new(stable_id, content_version)
	for identifier: StringName in content_reference_ids:
		registry.register_content(identifier)
	for command_type_id: StringName in command_type_ids:
		registry.register_command_type(command_type_id)
	for project_definition: ProjectDefinition in project_definitions:
		registry.register_project_definition(project_definition)
	registry.register_attention_event_response_validator(
		AcknowledgmentAttentionEventResponseValidator.new(
			CreateQuarterBoundaryAttentionRule.EVENT_TYPE_ID
		)
	)
	return registry
