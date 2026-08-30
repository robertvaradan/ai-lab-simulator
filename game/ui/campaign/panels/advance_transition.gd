class_name CampaignAdvanceTransitionPanel
extends Control

signal finished

const STEP_DURATION_SEC: float = 0.45
const FINAL_DURATION_SEC: float = 0.5

var _body: Label
var _playing: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func play(model: CampaignAdvanceTransitionModel) -> void:
	if _body == null:
		finished.emit()
		return
	_playing = true
	visible = true
	_body.text = "Advancing..."
	var tween: Tween = create_tween()
	for step: CampaignAdvanceMonthStep in model.month_steps:
		var line: String = "Quarter %d · Month Step %d" % [step.quarter_index, step.month_step_index]
		tween.tween_callback(_set_body.bind(line))
		tween.tween_interval(STEP_DURATION_SEC)
	var summary: PackedStringArray = PackedStringArray()
	summary.append("Cash %d MUSD -> %d MUSD" % [model.cash_before_musd, model.cash_after_musd])
	for change: String in model.project_changes:
		summary.append(change)
	for world_line: String in model.world_change_lines:
		summary.append(world_line)
	for event_id: StringName in model.new_event_ids:
		summary.append("New event %s" % String(event_id))
	tween.tween_callback(_set_body.bind("\n".join(summary)))
	tween.tween_interval(FINAL_DURATION_SEC)
	tween.tween_callback(_on_finished)


func _build() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"Modal"
	panel.custom_minimum_size = Vector2(640.0, 320.0)
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	_body = Label.new()
	_body.name = "AdvanceBody"
	_body.add_theme_font_size_override("font_size", 18)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(_body)


func _set_body(text: String) -> void:
	if _body != null:
		_body.text = text


func _on_finished() -> void:
	_playing = false
	visible = false
	finished.emit()
