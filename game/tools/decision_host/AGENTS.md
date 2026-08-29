# Decision Host contract

This directory owns the internal Decision Host.

- Follow `../../../docs/tools/decision-host.md`.
- Call the public Simulation Core operations.
- Do not implement game rules in this directory.
- Do not reuse `MarketingPlayOverlay`.
- Do not instance the Company Campus.
- Do not include Simulation Laboratory Policies, replay, or the Rule Graph view.
- Exclude this interface from production exports.
- Fail construction when the content registry has a Command type or payload key that this host cannot present.

Do not repair or replace an invalid Simulation Core result.
