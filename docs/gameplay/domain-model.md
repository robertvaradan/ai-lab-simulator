# Domain model

This specification defines approved game terms.

An implementation must use these terms consistently.

## Plan and Command

A Plan is one ordered set of player Commands.

A Command is one requested state change.

A Command must have a stable type identifier.

A Command must contain all required input values.

A committed Plan becomes one Pending Command Batch.

A Month Step must consume a Pending Command Batch no more than once.

## Company

The Company is the organization that the player controls.

The Company owns Cash, Sites, Projects, staff, Models, Applications, and contracts.

The Company has a Public Trust value.

The Company has a Government Trust value.

## Strategic Domains

Research is work that improves Model methods, efficiency, capability, safety, or foresight.

Scale is work that increases or improves Compute Capacity.

Applications are products or services that use one or more Models.

Research, Scale, and Applications are the three Strategic Domains.

The three Strategic Domains must share resources and prerequisites.

## Model

A Model is a trained AI artifact.

A Model must have a stable identifier.

The player must set the display name of each player Model.

The player must set the version label of each player Model.

The stable identifier must not depend on the display name or version label.

A Model must record its training configuration.

A Model must record its capability values.

A Model peak evaluation is the highest of its coding, reasoning, and efficiency evaluation points.

A Model must record its Compute cost.

A released Model must record its Release Strategy.

A Model can support more than one Application.

An Application must reference at least one compatible Model.

## Application

An Application is a customer-facing use of a Model.

An Application can create contracts and Revenue.

An Application can include software, services, agents, or physical systems.

Robots are a possible late-game Application category.

Robots are not part of the first implementation scope.

## Project

A Project is committed work that resolves over one or more Month Steps.

A Project must have a stable identifier.

A Project must have a start condition.

A Project must have a cost schedule.

A Project must have a duration in whole months for the first implementation.

A Project must have one or more completion effects.

A Research Project belongs to Research.

A Scale Project belongs to Scale.

An Application Project belongs to Applications.

## World, Site, and Site Plot

A World is a selectable campaign location on the World map.

The campaign Worlds are HQ, Data Center, and Government.

World navigation must follow `docs/presentation/world-map.md`.

A Site is a visible location inside one World.

A Site Plot is a predetermined upgrade location in a Site.

A Site Plot can contain one compatible Site Upgrade.

HQ is the Company headquarters World.

HQ must host Research Projects and Application Projects.

HQ must not present an Application as a Site building.

Data Center is a separate World that supplies Compute Capacity presentation.

Data Center must not appear as an HQ Site Plot.

Data Center must not simulate internal Data Center operation in the first implementation.

Government is a separate World for government and regulation presentation.

Government must not appear as an HQ Site Plot.

Third-Party Compute is Compute Capacity that an external provider supplies.

Third-Party Compute must have a higher ongoing cost than equivalent owned capacity.

Third-Party Compute can provide capacity before the Company owns a Data Center.

Third-Party Compute presentation must use the Data Center World.

## Competitor

A Competitor is an authored external AI company.

A Competitor must use preset Competitor Stages.

A Competitor does not use the complete player rule set.

A Competitor Stage can release a Model, change prices, change Market Demand, or create an Attention Event.

Competitor actions must put the player at risk of losing technical or market position.

## Market

Market Demand is external demand for Applications and Model capabilities.

Market Demand is World State.

Market Demand must not be an allocatable player resource.

Customer demand, contracts, prices, and Revenue must derive from World State and Company State.

The game must not use Adoption as a primary Strategic Domain or allocatable resource.

## Trust

Public Trust represents broad public confidence in the Company.

Government Trust represents government confidence in the Company.

Trust can affect contracts, regulation events, and project options.

Trust must not replace explicit causal events.

Public Trust becomes active when any released player Model peak evaluation is 80 or more.

Government Trust becomes active when any released player Model peak evaluation is 90 or more.

Inactive trust must not apply mechanical effects.

## Research points

Research points are the skill-tree spend resource.

The campaign session stores the research-point balance for the simple skill tree.

The campaign starts with 0 research points.

A completed Research Project grants research points.

The skill tree owns the spend rules in `docs/gameplay/skill-tree.md`.

## Cash, Revenue, and cost

Cash is the Company ledger balance.

Revenue is a positive ledger transaction.

A cost is a negative ledger transaction.

All Cash changes must create immutable ledger transactions.

## Release Strategy

A Release Strategy defines how the Company releases one Model.

A Release Strategy must apply to one release.

A Release Strategy must not define a permanent company class.

A Release Strategy can change Revenue potential, Public Trust, Government Trust, and competitive effects.

Open Weights is a candidate Release Strategy.

The exact Open Weights effects are not yet canonical.
