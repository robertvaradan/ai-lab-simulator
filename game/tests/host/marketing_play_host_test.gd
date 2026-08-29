extends SceneTree

const TEST_SUCCESS: String = "MARKETING_PLAY_HOST_TEST_SUCCESS"

var _failure_count: int = 0


func _initialize() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var host: MarketingPlayHost = MarketingPlayHost.new()
	host.name = "MarketingPlayHost"
	var overlay: MarketingPlayOverlay = MarketingPlayOverlay.new()
	overlay.name = "Overlay"
	host.add_child(overlay)
	root.add_child(host)
	_verify_host_ready(host)
	_verify_empty_plan_matches_laboratory(host)
	_verify_presentation(host)
	host.queue_free()
	_finish()


func _verify_host_ready(host: MarketingPlayHost) -> void:
	_expect(host.get_core() != null, "The production host has no Simulation Core.")
	_expect(host.get_game_state_service() != null, "The production host has no Game State service.")
	_expect(host.get_current_state() != null, "The production host has no Game State.")
	_expect(host.get_overlay() != null, "The production host has no overlay.")
	_expect(host.get_current_state().calendar.current_month_step_index == 0, "The production host did not load the starting Month Step.")
	_expect(host.get_overlay().get_report_text().contains("quarterly_report.opening"), "The overlay does not present the opening Quarterly Report.")


func _verify_empty_plan_matches_laboratory(host: MarketingPlayHost) -> void:
	var lab_created: SimulationLabSessionResult = SimulationLabSession.create_marketing_scenario()
	_expect(lab_created.succeeded(), "The comparison laboratory session did not start:\n%s" % lab_created.format_diagnostics())
	if not lab_created.succeeded():
		return
	var lab: SimulationLabSession = lab_created.session
	lab.commit_staged_plan()
	lab.advance_until_attention_required()
	var plan: Plan = host.get_overlay().build_plan(host.get_current_state())
	_expect(plan.commands.is_empty(), "The MS3-01 overlay staged Project Commands.")
	var advanced: SimulationOperationResult = host.advance_with_plan(plan)
	_expect(
		advanced.outcome == SimulationOperationOutcome.Type.DECISION_REQUIRED,
		"The production Advance did not stop at the Attention Boundary."
	)
	_expect(host.get_current_state().calendar.current_month_step_index == 3, "The production Advance did not end at Month Step 3.")
	_expect(
		var_to_bytes_with_objects(host.get_current_state())
		== var_to_bytes_with_objects(lab.get_state()),
		"The production host and laboratory produced different Game State for the empty Plan."
	)
	_expect(
		host.get_current_state().cash_ledger.calculate_balance_musd()
		== lab.get_cash_ledger().calculate_balance_musd(),
		"The production host and laboratory produced different Cash."
	)


func _verify_presentation(host: MarketingPlayHost) -> void:
	_expect(host.get_overlay().get_attention_text().contains("attention_event.quarter_boundary"), "The overlay does not present the Quarter Boundary Attention Event.")
	_expect(host.get_overlay().get_report_text().contains("quarterly_report.ending"), "The overlay does not present the ending Quarterly Report.")
	_expect(host.get_overlay().get_status_text() == "Attention is required.", "The overlay status is incorrect after Advance.")
	_expect(host.get_current_state().quarterly_reports.size() == 2, "The production host did not keep both Quarterly Reports.")


func _finish() -> void:
	if _failure_count > 0:
		printerr("MARKETING_PLAY_HOST_TEST_FAILURE count=%d" % _failure_count)
		quit(1)
		return
	print("%s cases=3" % TEST_SUCCESS)
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failure_count += 1
	push_error(message)
