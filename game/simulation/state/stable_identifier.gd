class_name StableIdentifier
extends RefCounted


static func is_valid(identifier: StringName) -> bool:
	var text: String = String(identifier)
	if text.is_empty():
		return false
	var segments: PackedStringArray = text.split(".")
	if segments.size() < 2:
		return false
	for segment: String in segments:
		if not _is_valid_segment(segment):
			return false
	return true


static func format_runtime_identifier(entity_type: StringName, sequence: int) -> StringName:
	var entity_type_text: String = String(entity_type)
	if not is_valid_entity_type(entity_type):
		push_error("Runtime entity type is invalid: %s" % entity_type_text)
		return &""
	if sequence < 1:
		push_error("Runtime identifier sequence must be greater than zero.")
		return &""
	return StringName("%s.runtime.id_%06d" % [entity_type_text, sequence])


static func is_valid_entity_type(entity_type: StringName) -> bool:
	return _is_valid_segment(String(entity_type))


static func _is_valid_segment(segment: String) -> bool:
	if segment.is_empty() or not _is_lower_ascii_letter(segment.unicode_at(0)):
		return false
	for index: int in range(1, segment.length()):
		var character: int = segment.unicode_at(index)
		if not _is_lower_ascii_letter(character) and not _is_ascii_digit(character) and character != 95:
			return false
	return true


static func _is_lower_ascii_letter(character: int) -> bool:
	return character >= 97 and character <= 122


static func _is_ascii_digit(character: int) -> bool:
	return character >= 48 and character <= 57
