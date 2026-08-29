# Marketing Scenario

## Authority

This specification owns the authored content and expected results for the Marketing Scenario.

This specification defines only the systems that the Marketing Scenario uses.

This specification does not define the complete production content catalog.

## Scenario identity

The Scenario identifier must be `scenario.marketing.first_quarter`.

The content version must be `1`.

The Scenario must use the Standard difficulty profile.

The Standard difficulty profile must not modify a numeric value in this Scenario.

The Scenario must not use random outcomes.

The Scenario must start in Planning State before Month Step 1.

The Scenario must end its first run after the Quarter Boundary that follows Month Step 3.

## Units

All authoritative numeric values in this Scenario must use integers.

Cash and ledger amounts must use `MUSD`.

One `MUSD` must represent one million United States dollars.

Time must use `month_step`.

Staff must use `person`.

Project capacity must use `project_team`.

Compute Capacity must use `compute_unit_month`.

Model evaluations and the technical frontier must use `evaluation_point`.

One evaluation value must be in the inclusive range from 0 through 100.

Public Trust and Government Trust must use `trust_point`.

One trust value must be in the inclusive range from 0 through 100.

Customer demand must use `contract`.

Application price must use `MUSD_per_contract_month`.

Relevance factors, price factors, and Company demand-effect factors must use `basis_point`.

Ten thousand basis points must equal the complete demand value.

## Starting Game State

The Cash opening balance must be 150 MUSD.

The Cash Ledger must contain no transactions.

The Company must have 40 persons.

The Company must have two project teams.

The Company must have 70 compute-unit-months of Compute Capacity.

The Company must receive this Compute Capacity from `contract.compute.standard`.

The standard compute contract must cost 4 MUSD in each Month Step.

The Company must have a Public Trust value of 55 trust points.

The Company must have a Government Trust value of 50 trust points.

The Company must have a fixed operating cost of 5 MUSD in each Month Step.

The Company must have no active Project.

The Company must have no Application.

The Company must have no customer contract.

The Company must have no Pending Command Batch.

The staged Plan must be empty.

The Company must have no unresolved Attention Event.

The Company must have no Notification.

### HQ Site

The HQ Site identifier must be `site.company.sf_campus`.

The HQ Site must contain `plot.campus.research`.

The HQ Site must not contain an Application Site Plot.

The HQ Site must not contain a Data Center Site Plot.

The starting research Site Plot state must be `site_plot_state.empty_plot`.

The first player construction step must start `project.campus.build_laboratory`.

`project.campus.build_laboratory` must cost 10 MUSD.

`project.campus.build_laboratory` must last 1 Month Step.

`project.campus.build_laboratory` completion must set `plot.campus.research` to `site_plot_state.compact_lab`.

Research, Scale, and Application Project starts must require completed `project.campus.build_laboratory`.

The Research Project state must control laboratory stage after the laboratory exists.

Scale presentation must use the Data Center World.

Application Projects must run at HQ.

Application Projects must not create a physical HQ building.

The presentation must not create a separate Site Plot state.

World navigation must follow `docs/presentation/world-map.md`.

### Starting player Model

The starting Model identifier must be `model.player.starting`.

The starting display name must be `Aperture`.

The starting version label must be `1.0`.

The Model must be released.

The Model must use `release_strategy.commercial_api`.

The commercial API Release Strategy must have no trust modifier in this Scenario.

The commercial API Release Strategy must have no Revenue modifier in this Scenario.

The commercial API Release Strategy must have no competitive-effect modifier in this Scenario.

The Model must have 72 coding evaluation points.

The Model must have 70 reasoning evaluation points.

The Model must have 76 efficiency evaluation points.

The Model training configuration must record 90 compute-unit-months.

The Model must require two compute-unit-months for each active customer contract.

## Starting World State

The Competitor identifier must be `competitor.northstar`.

The starting Competitor Stage must be `competitor_stage.northstar.announced`.

The starting technical frontier must be 74 coding evaluation points.

The starting technical frontier must be 72 reasoning evaluation points.

The starting technical frontier must be 74 efficiency evaluation points.

The Coding Agent Market Demand must contain 12 possible customer contracts.

The starting Coding Agent customer expectation must be 70 coding evaluation points.

The reference Coding Agent price must be 1 MUSD per contract-month.

The starting World State must contain no World Models.

The World State must contain no active government condition.

## Available Projects

The Scenario must contain exactly one authored Project in each Strategic Domain.

The Project start Command type identifier must be `command.project.start`.

The complete Plan must pass validation before a Project starts.

Plan validation must include all Project start Commands in the Plan.

Each active Project must reserve one project team while it is active.

Free project teams must equal the Company project-team count minus the reserved project teams of active Projects.

The Plan must not reserve more project teams than the Company has as free project teams.

Free Compute Capacity must equal the Company Compute Capacity minus the reserved Compute Capacity of active Projects.

The Plan must not reserve more Compute Capacity than the Company has as free Compute Capacity.

The Plan must not contain more Project start costs than the current Cash balance can pay.

Plan validation must not count future Revenue as current Cash.

The Plan must not start the same Project more than once.

The Project start cost must create one ledger transaction during the committed-cost phase.

The Company must not start all three Projects in one Plan.

The project-team limit must cause this restriction.

### Research Project

The Research Project identifier must be `project.research.frontier_model`.

The Project must cost 65 MUSD when it starts.

The Project duration must be three Month Steps.

The Project must reserve one project team while it is active.

The Project must reserve 30 compute-unit-months while it is active.

The start Command must contain a Model display name.

The start Command must contain a Model version label.

The start Command must contain a Release Strategy identifier.

The baseline Model display name must be `Aperture`.

The baseline Model version label must be `2.0`.

The baseline Release Strategy must be `release_strategy.commercial_api`.

Project completion must create and release `model.player.research_output`.

The completed Model must have 84 coding evaluation points.

The completed Model must have 79 reasoning evaluation points.

The completed Model must have 80 efficiency evaluation points.

The completed Model training configuration must record the Project compute reservation.

The completed Model must require two compute-unit-months for each active customer contract.

The preselected Release Strategy must prevent a separate Release Strategy decision at completion.

### Scale Project

The Scale Project identifier must be `project.scale.burst_compute`.

The Project must cost 30 MUSD when it starts.

The Project duration must be one Month Step.

The Project must reserve one project team while it is active.

Project completion must create `contract.compute.burst`.

The burst compute contract must add 60 compute-unit-months of Compute Capacity.

The burst compute contract must cost 8 MUSD in each Month Step.

The first burst compute contract cost must occur in the completion Month Step.

The completed contract must remain active at the ending Quarter Boundary.

### Coding Agent Project

The Coding Agent Project identifier must be `project.application.coding_agent`.

The Project must cost 40 MUSD when it starts.

The Project duration must be two Month Steps.

The Project must reserve one project team while it is active.

The Project must reserve 10 compute-unit-months while it is active.

The start Command must identify one released player Model.

The baseline start Command must identify `model.player.starting`.

Project completion must create `application.player.coding_agent`.

The Coding Agent must reference the Model from the start Command.

The Coding Agent price must be 1 MUSD per contract-month.

The Coding Agent price must not change during the first scenario run.

The Coding Agent must create customer contracts during the Revenue phase.

The Coding Agent must not change its supporting Model without a later explicit Command.

## Competitor release

The opening Quarterly Report must identify the first Quarter Boundary as the release time for the next Northstar flagship Model.

The projected coding evaluation range must be 80 through 84 evaluation points.

The projected reasoning evaluation range must be 76 through 80 evaluation points.

The projected efficiency evaluation range must be 70 through 74 evaluation points.

The projection must not show the actual values before the release.

The Competitor Stage must change to `competitor_stage.northstar.flagship_released` during the Advance Competitors phase of Month Step 3.

The release event identifier must be `event.competitor.northstar_flagship_release`.

The released Competitor Model identifier must be `model.competitor.northstar.flagship`.

The released Competitor Model must live in World State.

The released Competitor Model display name must be `Northstar Flagship`.

The released Competitor Model version label must be `1.0`.

The released Competitor Model Release Strategy must be `release_strategy.commercial_api`.

The released Competitor Model training Compute Capacity must be 0 compute-unit-months.

The released Competitor Model inference Compute Capacity must be 0 compute-unit-months for each contract.

The actual Competitor Model must have 82 coding evaluation points.

The actual Competitor Model must have 78 reasoning evaluation points.

The actual Competitor Model must have 72 efficiency evaluation points.

The release must set each technical-frontier value to the larger of its current value and the applicable actual evaluation value.

A player Model must not change the technical frontier in this Scenario.

The release must change the Coding Agent customer expectation from 70 to 80 coding evaluation points.

The release event must be the causal input for both World State changes.

The release must not create an Attention Event.

The release must not create a Notification.

## Derived market effects

Model technical competitiveness for one evaluation dimension must equal the Model evaluation value minus the applicable technical-frontier value.

Coding Agent market relevance must use the coding evaluation value of its supporting Model.

An unreleased Model must not have a market relevance tier.

An unreleased Model must not support the Coding Agent.

The current customer expectation must represent Market Demand and the best released competing offer in this Scenario.

The relevance difference must equal the supporting Model coding evaluation value minus the current Coding Agent customer expectation.

A relevance difference of zero or more must produce a leading relevance tier.

A relevance difference from negative five through negative one must produce a competitive relevance tier.

A relevance difference of negative six or less must produce a trailing relevance tier.

A leading relevance tier must use a relevance factor of 10,000 basis points.

A competitive relevance tier must use a relevance factor of 7,500 basis points.

A trailing relevance tier must use a relevance factor of 5,000 basis points.

The Model pricing power must be 2 MUSD per contract-month for a leading relevance tier.

The Model pricing power must be 1 MUSD per contract-month for a competitive or trailing relevance tier.

The Coding Agent price factor must be 10,000 basis points when its price does not exceed the supporting Model pricing power.

The Scenario must use a Company demand-effect factor of 10,000 basis points.

Application customer demand must equal Market Demand multiplied by the relevance factor, price factor, and Company demand-effect factor.

Application customer demand must divide that product by 10,000 cubed.

The calculation must use integer arithmetic.

The Scenario values must produce a whole number of contracts.

Application Revenue must equal customer contracts multiplied by Application price.

Application compute use must equal customer contracts multiplied by the supporting Model compute cost.

Application compute use must not reduce Company Compute Capacity.

A Rule must not write technical competitiveness, market relevance, pricing power, or customer demand as Game State.

The Revenue Rule must write the resolved customer-contract count on the Application.

If Application price exceeds Model pricing power, the Revenue Rule must fault.

The Simulation Trace must connect the Competitor release event to the changed customer expectation, market relevance, customer demand, and Revenue.

The Revenue event payload must include the supporting Model, the current customer expectation, the resolved demand, and the Revenue amount.

The Month Step must not contain a Resolve Market changes Rule in this Scenario.

## Month Step effects

The fixed Company operating cost must create one ledger transaction in each Month Step.

Each active compute contract cost must create one ledger transaction in each applicable Month Step.

Operating cost, compute-contract cost, and Application Revenue must post during the Resolve contracts, Revenue, and operating costs phase.

The Coding Agent must create one Revenue transaction in each Month Step in which it is active during the Revenue phase.

The Coding Agent Project must complete before the Revenue phase of Month Step 2.

The Coding Agent must create 12 MUSD of Revenue in Month Step 2.

The Competitor release must reduce the Coding Agent demand to six contracts in Month Step 3 when the Coding Agent uses `model.player.starting`.

The Coding Agent must create 6 MUSD of Revenue in Month Step 3 in that state.

The first Quarter Boundary must be the only Attention Boundary in each baseline run.

Project completions before that boundary must create Notifications.

## Baseline scenario runs

A baseline scenario run must stage Plans in Month Step order.

A baseline scenario run must use `advance_until_attention_required` after each committed Plan that continues the run.

Each baseline scenario run must stop at the first Quarter Boundary.

Each baseline scenario run must start `project.campus.build_laboratory` in Month Step 0.

Each baseline scenario run must start its domain Project only after `project.campus.build_laboratory` completes.

### Research-first run

The Research-first run must start `project.campus.build_laboratory`, then `project.research.frontier_model`.

The run must end with a Cash balance of 48 MUSD.

The run must end with `plot.campus.research` in `site_plot_state.compact_lab`.

The run must report a Project cost Cash change of -75 MUSD.

The run must report a Company operating cost Cash change of -15 MUSD.

The run must report a standard compute-contract cost Cash change of -12 MUSD.

The Research Project must remain active at the first Quarter Boundary.

### Scale-first run

The Scale-first run must start `project.campus.build_laboratory`, then `project.scale.burst_compute`.

The run must end with a Cash balance of 67 MUSD.

The run must end with `contract.compute.burst` active.

The run must report a Project cost Cash change of -40 MUSD.

The run must report a Company operating cost Cash change of -15 MUSD.

The run must report a standard compute-contract cost Cash change of -12 MUSD.

The run must report a burst compute-contract cost Cash change of -16 MUSD.

The run must end with 130 compute-unit-months of Compute Capacity.

### Application-first run

The Application-first run must start `project.campus.build_laboratory`, then `project.application.coding_agent`.

The run must end with a Cash balance of 79 MUSD.

The run must end with `application.player.coding_agent` active.

The run must report a Project cost Cash change of -50 MUSD.

The run must report a Company operating cost Cash change of -15 MUSD.

The run must report a standard compute-contract cost Cash change of -12 MUSD.

The run must report an Application Revenue Cash change of 6 MUSD.

The Application must use `model.player.starting`.

Application presentation must not create an HQ Application building.

### Hybrid run

The hybrid run must start `project.campus.build_laboratory`, then `project.research.frontier_model` and `project.application.coding_agent`.

The run must end with a Cash balance of 14 MUSD.

The run must report a Project cost Cash change of -105 MUSD.

The run must report a Company operating cost Cash change of -15 MUSD.

The run must report a standard compute-contract cost Cash change of -12 MUSD.

The run must report an Application Revenue Cash change of 18 MUSD.

The run must end with `model.player.research_output` released.

The run must end with `application.player.coding_agent` active.

The Application must continue to use `model.player.starting`.

The Application must have six customer contracts.

The result must show that a new Model does not silently replace an Application dependency.

## Quarterly Reports

The opening Quarterly Report must derive from the complete starting Game State.

The opening Quarterly Report must show the Northstar release quarter and all projected evaluation ranges.

The ending Quarterly Report must derive from the authoritative ending state of its scenario run.

Each ending Quarterly Report must show its Cash change by ledger category.

Each ending Quarterly Report must show Project changes.

Each ending Quarterly Report must show Model and Application changes.

Each ending Quarterly Report must show the actual Northstar Model evaluations.

Each ending Quarterly Report must show the technical-frontier and customer-expectation changes.

Each ending Quarterly Report must show unchanged Public Trust and Government Trust values.

Report data must not create or change authoritative state.

## Excluded production decisions

The Scenario does not define additional Model evaluation dimensions.

The Scenario does not define additional Release Strategies.

The Scenario does not define other Application categories.

The Scenario does not define other Market Demand formulas.

The Scenario does not define Competitor behavior after the first Quarter Boundary.

The Scenario does not define trust changes.
