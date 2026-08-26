class_name SimulationContentRegistry
extends RefCounted

var scenario_id: StringName:
	get:
		return _scenario_id
var content_version: int:
	get:
		return _content_version

var _scenario_id: StringName
var _content_version: int
var _content_ids: Dictionary[StringName, bool] = {}
var _command_type_ids: Dictionary[StringName, bool] = {}
var _attention_event_response_validators: Dictionary[StringName, AttentionEventResponseValidator] = {}
var _diagnostics: Array[SimulationDiagnostic] = []
var _is_sealed: bool = false


func _init(p_scenario_id: StringName, p_content_version: int) -> void:
	_scenario_id = p_scenario_id
	_content_version = p_content_version


func register_content(content_id: StringName) -> bool:
	if _is_sealed:
		_add_error(&"content_registry.sealed", "The content registry is sealed.")
		return false
	if not StableIdentifier.is_valid(content_id):
		_add_error(
			&"content_registry.invalid_content_id",
			"Content identifier %s is invalid." % content_id
		)
		return false
	if _content_ids.has(content_id):
		_add_error(
			&"content_registry.duplicate_content_id",
			"Content identifier %s is duplicated." % content_id
		)
		return false
	_content_ids[content_id] = true
	return true


func register_command_type(command_type_id: StringName) -> bool:
	if _is_sealed:
		_add_error(&"content_registry.sealed", "The content registry is sealed.")
		return false
	if not StableIdentifier.is_valid(command_type_id):
		_add_error(
			&"content_registry.invalid_command_type_id",
			"Command type identifier %s is invalid." % command_type_id
		)
		return false
	if not _content_ids.has(command_type_id):
		_add_error(
			&"content_registry.unknown_command_type_id",
			"Command type identifier %s is not registered content." % command_type_id
		)
		return false
	if _command_type_ids.has(command_type_id):
		_add_error(
			&"content_registry.duplicate_command_type_id",
			"Command type identifier %s is duplicated." % command_type_id
		)
		return false
	_command_type_ids[command_type_id] = true
	return true


func register_attention_event_response_validator(
		validator: AttentionEventResponseValidator
	) -> bool:
	if _is_sealed:
		_add_error(&"content_registry.sealed", "The content registry is sealed.")
		return false
	if validator == null:
		_add_error(
			&"content_registry.missing_attention_response_validator",
			"The Attention Event response validator is missing."
		)
		return false
	if not StableIdentifier.is_valid(validator.event_type_id):
		_add_error(
			&"content_registry.invalid_attention_event_type_id",
			"Attention Event type identifier %s is invalid." % validator.event_type_id
		)
		return false
	if not StableIdentifier.is_valid(validator.response_type_id):
		_add_error(
			&"content_registry.invalid_attention_response_type_id",
			"Attention Event response type identifier %s is invalid." % validator.response_type_id
		)
		return false
	if not _content_ids.has(validator.event_type_id):
		_add_error(
			&"content_registry.unknown_attention_event_type_id",
			"Attention Event type identifier %s is not registered content."
			% validator.event_type_id
		)
		return false
	if _attention_event_response_validators.has(validator.event_type_id):
		_add_error(
			&"content_registry.duplicate_attention_response_validator",
			"Attention Event type %s has more than one response validator."
			% validator.event_type_id
		)
		return false
	_attention_event_response_validators[validator.event_type_id] = validator
	return true


func seal() -> void:
	_is_sealed = true


func is_sealed() -> bool:
	return _is_sealed


func build_content_catalog() -> Dictionary[StringName, bool]:
	var catalog: Dictionary[StringName, bool] = {}
	catalog.assign(_content_ids)
	return catalog


func has_command_type(command_type_id: StringName) -> bool:
	return _command_type_ids.has(command_type_id)


func get_command_type_ids() -> Array[StringName]:
	var command_type_ids: Array[StringName] = []
	command_type_ids.assign(_command_type_ids.keys())
	command_type_ids.sort()
	return command_type_ids


func get_attention_event_response_validator(
		event_type_id: StringName
	) -> AttentionEventResponseValidator:
	return _attention_event_response_validators.get(event_type_id)


func get_diagnostics() -> Array[SimulationDiagnostic]:
	var diagnostics: Array[SimulationDiagnostic] = []
	diagnostics.assign(_diagnostics)
	return diagnostics


func _add_error(code: StringName, message: String) -> void:
	_diagnostics.append(
		SimulationDiagnostic.new(SimulationDiagnostic.Severity.ERROR, code, message)
	)
