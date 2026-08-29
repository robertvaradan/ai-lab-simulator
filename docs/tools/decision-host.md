# Decision Host

## Purpose

The Decision Host must let a developer click through the inspect, Plan, Advance, and attention loop.

The Decision Host must use the public Simulation Core operations.

The Decision Host must not include the Company Campus.

The Decision Host must not include the SDF proof.

The Decision Host must not include Simulation Laboratory Policies.

The Decision Host must not include Simulation Laboratory replay.

The Decision Host must not include the Rule Graph view.

## Build boundary

The Decision Host must exist outside production runtime code.

`game/tools/decision_host` must own the Decision Host.

Production exports must exclude the Decision Host.

Production exports must include the same Simulation Core and content registry that the Decision Host uses.

The default editor Run scene must be the production init scene.

## Host contract

The Decision Host is a Simulation Host.

The Decision Host must own one `GameStateService` through its `ServiceContext`.

The Decision Host must call `SimulationAdvanceAction` for Advance.

The Decision Host must not publish an intermediate `commit_plan` candidate.

The Decision Host must not duplicate a game rule.

The Decision Host must not repair an invalid Simulation Core result.

The Decision Host must not reuse `MarketingPlayOverlay`.

## Scenario

The Decision Host must load the Marketing Scenario.

The Decision Host must not present a Scenario picker.

## Control catalog

The Decision Host must present registered player actions from the content registry.

The Decision Host must not hard-code Marketing Scenario Project identifiers in the view.

The presented Command type must be `command.project.start`.

The visible payload keys must be `project_id`, `model_display_name`, and `model_version_label`.

The approved hidden default keys must be `release_strategy_id` and `supporting_model_id`.

The hidden `release_strategy_id` value must be `release_strategy.commercial_api`.

The hidden `supporting_model_id` value must be `model.player.starting`.

Session construction must fail when the content registry has a Command type that the Decision Host cannot present.

Session construction must fail when a Project requires a payload key that is not visible and is not an approved hidden default.

The Decision Host must not skip an unknown Command type.

A new Command type or payload key must update this specification and add a control.

## Plan and Advance

The Decision Host must keep the draft Plan outside Game State.

The Decision Host must build one Plan from the selected Project controls.

The Decision Host must skip a Project start Command when that Project already exists on the Company.

The Decision Host must attach one acknowledgment response for each pending Attention Event.

Illegal Plans must stay selectable.

Advance must return `REJECTED` when the Plan is invalid.

The Decision Host must show the rejection diagnostics.

The Decision Host must not disable an illegal control before Advance.

The window must stay open after Advance.

The player can stage another Plan after an Attention Boundary.

## Presentation

The Decision Host must show status, Month Step, Quarter, and Cash.

The Decision Host must show Projected Evaluation Ranges.

The Decision Host must show Attention Events.

The Decision Host must show the latest Quarterly Report.

The Decision Host must show Advance diagnostics.

The Decision Host must show Cash Ledger lines.

The Decision Host must show remaining Month Steps for each Company Project.

The Decision Host must show Rule evaluation statuses from the last Advance.

The last Advance must include the `commit_plan` trace and the `advance_until_attention_required` trace from that click.

The Decision Host must not show a session-history picker.

The Decision Host must not show a Month Step picker.

A Rule evaluation status must be `fired`, `did_not_fire`, or `failed`.

The Decision Host must read Rule evaluation status from `RuleEvaluationTraceRecord`.

The Decision Host must not call the laboratory Rule Graph classifier.

## Launch

One windowed command must open `res://tools/decision_host/decision_host.tscn`.

The command must use the canonical Godot executable.

The command must keep the window open.

The command must not use `--headless`.

The command must not wrap the human launch in Xvfb.

A Linux host without `DISPLAY` must fail.

## Verification

One headless command must run the Decision Host tests.
