class_name DecisionHostCatalog
extends RefCounted

const SPECIFICATION_REFERENCE: String = "docs/tools/decision-host.md"
const PRESENTED_COMMAND_TYPE: StringName = &"command.project.start"
const VISIBLE_PROJECT_ID: StringName = &"project_id"
const VISIBLE_MODEL_DISPLAY_NAME: StringName = &"model_display_name"
const VISIBLE_MODEL_VERSION_LABEL: StringName = &"model_version_label"
const HIDDEN_RELEASE_STRATEGY_KEY: StringName = &"release_strategy_id"
const HIDDEN_SUPPORTING_MODEL_KEY: StringName = &"supporting_model_id"
const HIDDEN_RELEASE_STRATEGY_VALUE: StringName = &"release_strategy.commercial_api"
const HIDDEN_SUPPORTING_MODEL_VALUE: StringName = &"model.player.starting"
const DEFAULT_MODEL_DISPLAY_NAME: String = "Aperture"
const DEFAULT_MODEL_VERSION_LABEL: String = "2.0"


static func visible_payload_keys() -> Dictionary[StringName, bool]:
	var keys: Dictionary[StringName, bool] = {}
	keys[VISIBLE_PROJECT_ID] = true
	keys[VISIBLE_MODEL_DISPLAY_NAME] = true
	keys[VISIBLE_MODEL_VERSION_LABEL] = true
	return keys


static func hidden_default_keys() -> Dictionary[StringName, bool]:
	var keys: Dictionary[StringName, bool] = {}
	keys[HIDDEN_RELEASE_STRATEGY_KEY] = true
	keys[HIDDEN_SUPPORTING_MODEL_KEY] = true
	return keys


static func validate(content_registry: SimulationContentRegistry) -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	if content_registry == null:
		diagnostics.append(
			SimulationDiagnostic.new(
				SimulationDiagnostic.Severity.ERROR,
				&"decision_host.missing_content_registry",
				"The Decision Host content registry is missing."
			)
		)
		return diagnostics
	var visible_keys: Dictionary[StringName, bool] = visible_payload_keys()
	var hidden_keys: Dictionary[StringName, bool] = hidden_default_keys()
	for command_type_id: StringName in content_registry.get_command_type_ids():
		if command_type_id != PRESENTED_COMMAND_TYPE:
			diagnostics.append(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"decision_host.unsupported_command_type",
					"The Decision Host cannot present Command type %s." % command_type_id
				)
			)
	for project_id: StringName in content_registry.get_project_ids():
		var definition: ProjectDefinition = content_registry.get_project_definition(project_id)
		if definition == null:
			diagnostics.append(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"decision_host.missing_project_definition",
					"Project %s has no definition." % project_id
				)
			)
			continue
		for payload_key: StringName in definition.required_payload_keys:
			if visible_keys.has(payload_key) or hidden_keys.has(payload_key):
				continue
			diagnostics.append(
				SimulationDiagnostic.new(
					SimulationDiagnostic.Severity.ERROR,
					&"decision_host.unsupported_payload_key",
					"Project %s requires payload key %s that the Decision Host cannot present."
					% [project_id, payload_key]
				)
			)
	return diagnostics
