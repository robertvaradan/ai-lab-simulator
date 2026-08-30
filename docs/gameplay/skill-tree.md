# Skill tree

## Authority

This specification owns the simple campaign skill tree.

This specification does not close the complete Research, Scale, or Application content graphs.

Fake skills in this catalog are placeholders. A later change must replace them with production content.

## Purpose

The player spends research points on one skill tree.

The tree has three branches:

- Research
- Scale
- Applications

A skill unlock must advance one of those branches.

The campaign must present one skill tree surface.

The campaign must not present a separate tech tree.

## Research points

Research points are the skill-tree spend resource.

The campaign session must store the research-point balance.

The campaign must start with 0 research points.

A completed Research Project must grant 4 research points.

A Research Project is a Project whose completion effect is `project_completion.research_model`.

The host must grant those points once for each completed Research Project.

The host must not grant points again for the same Project.

A skill unlock must subtract the skill cost from the research-point balance.

A skill unlock must not change Cash.

A skill unlock must not write Game State.

## Skill definition

Each skill must have a stable identifier.

Each skill must have a display name.

Each skill must have a summary.

Each skill must belong to one branch.

Each skill must have a research-point cost of 1 or more.

A skill can list prerequisite skill identifiers.

A skill must not use Cash as its unlock cost.

A skill must not use elapsed Month Steps as its only requirement.

## Unlock rules

The player can unlock a skill during Planning.

The player must not unlock a skill after campaign failure.

The host must reject an unlock when the skill is already unlocked.

The host must reject an unlock when the research-point balance is below the skill cost.

The host must reject an unlock when a prerequisite skill is not unlocked.

The skill tree must disable a control when the unlock is not available.

## Fake catalog

The first catalog must contain these placeholder skills.

### Research branch

| Stable ID | Display name | Cost | Prerequisites |
| --- | --- | --- | --- |
| skill.research.methods | Prototype Methods | 1 | none |
| skill.research.eval_loop | Eval Loop | 1 | skill.research.methods |
| skill.research.frontier_push | Frontier Push | 2 | skill.research.eval_loop |

### Scale branch

| Stable ID | Display name | Cost | Prerequisites |
| --- | --- | --- | --- |
| skill.scale.burst_buy | Burst Contracts | 1 | none |
| skill.scale.region_plan | Region Plan | 1 | skill.scale.burst_buy |
| skill.scale.owned_sites | Owned Sites | 2 | skill.scale.region_plan |

### Application branch

| Stable ID | Display name | Cost | Prerequisites |
| --- | --- | --- | --- |
| skill.application.agent_pack | Agent Pack | 1 | none |
| skill.application.product_line | Product Line | 1 | skill.application.agent_pack |
| skill.application.robots | Robot Assistants | 2 | skill.application.product_line |

A fake skill must not stage a Project.

A fake skill must not change Site Plots.

A fake skill must not change Models, Applications, or contracts.

## Presentation

The skill tree view must show the research-point balance.

The skill tree view must group skills by branch.

The skill tree view must show Unlocked on an unlocked skill.

The skill tree view must show the research-point cost on a locked skill.

The HUD state panel must show the research-point balance.

The view bar must present one Skill Tree control.

The view bar must not present a Tech Tree control.

The skill tree view must force HQ as the active World.

## Verification

Automated tests must reject an unlock when research points are below the cost.

Automated tests must reject an unlock when a prerequisite is missing.

Automated tests must subtract the skill cost after a valid unlock.

Automated tests must grant 4 research points after one Research Project completes.

Automated tests must verify the skill tree view opens from the campaign HUD.
