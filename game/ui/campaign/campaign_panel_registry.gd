class_name CampaignPanelRegistry
extends RefCounted

var _definitions: Dictionary[StringName, CampaignPanelDefinition] = {}


func _init() -> void:
	pass


func register(definition: CampaignPanelDefinition) -> void:
	if definition == null:
		ServiceContract.fail("missing_panel_definition", "A panel registration must have a definition.")
		return
	if definition.stable_id == &"":
		ServiceContract.fail("missing_panel_id", "A panel definition must have a stable identifier.")
		return
	if _definitions.has(definition.stable_id):
		ServiceContract.fail(
			"duplicate_panel",
			"The panel %s is already registered." % String(definition.stable_id)
		)
		return
	_definitions[definition.stable_id] = definition


func get_panel(stable_id: StringName) -> CampaignPanelDefinition:
	if not _definitions.has(stable_id):
		ServiceContract.fail("unknown_panel", "The panel %s is unknown." % String(stable_id))
		return null
	return _definitions[stable_id]


func has(stable_id: StringName) -> bool:
	return _definitions.has(stable_id)
