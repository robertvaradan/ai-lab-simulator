class_name CampaignWorldSelectable
extends Area3D

const CONTEXT_LABORATORY: StringName = &"context.laboratory"
const CONTEXT_DATA_CENTER: StringName = &"context.data_center"
const CONTEXT_GOVERNMENT: StringName = &"context.government"
const CONTEXT_COMPETITOR: StringName = &"context.competitor"

const ENTITY_HQ_LABORATORY: StringName = &"entity.hq.laboratory"
const ENTITY_DATA_CENTER_MARKER: StringName = &"entity.data_center.marker"
const ENTITY_GOVERNMENT_MARKER: StringName = &"entity.government.marker"
const ENTITY_COMPETITOR_NORTHSTAR: StringName = &"entity.competitor.northstar"

signal selected(selectable: CampaignWorldSelectable)

@export var entity_id: StringName = &""
@export var context_card_type: StringName = &""
@export var selection_order: int = 0
@export var framing_target: Vector3 = Vector3.ZERO
@export var framing_size: float = 20.0
@export var outline_points: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	input_ray_pickable = true
	input_event.connect(_on_input_event)


func get_outline_points() -> PackedVector3Array:
	return outline_points


func _on_input_event(
		_camera: Node,
		event: InputEvent,
		_event_position: Vector3,
		_normal: Vector3,
		_shape_idx: int
	) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if not mouse.pressed:
		return
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	selected.emit(self)
