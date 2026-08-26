# Services and dependency injection

This document is the canonical service and dependency-injection contract.

## Service contract

- A service must extend `Service`.
- A service must be a `RefCounted` object.
- A service must not be a `Node`.
- A service must have one owning `ServiceContext`.
- A service must keep the owning context for its full lifetime.
- A service can implement `_on_dispose()` for cleanup.
- A service must not dispose itself.

## Provider contract

- Each `ServiceContext` must own one active `ServiceProvider`.
- The provider must register a service with an explicit `GDScript` type.
- The service implementation must have the registered type.
- The service implementation must belong to the provider context.
- Each service type must have exactly one registration.
- The provider must use exact type keys.
- The provider must not search for a base type.
- The provider must not search for an implementation type.
- The provider must reject registration after it is sealed.
- The provider must reject resolution before it is sealed.
- The provider must fail when an exact registration does not exist.
- The provider must not provide optional resolution.
- The provider must dispose services in reverse registration order.
- The provider must dispose each service exactly once.

## Context contract

- A concrete composition root must extend `ServiceContext`.
- The composition root must register all services in `_register_services()`.
- The composition root must inject all consumers in `_inject_services()`.
- The context must seal the provider after registration.
- The context must inject consumers after the provider is sealed.
- The context must complete injection before its child nodes enter the scene tree.
- The context must use typed parameters for each consumer injection method.
- The context must dispose its provider when it exits the scene tree.

## Game State service contract

- Each Simulation Host `ServiceContext` must register one `GameStateService`.
- `GameStateService` must own one `GameStateEcho`.
- `GameStateService` must own the current committed Game State through `GameStateEcho`.
- `GameStateService` must validate each candidate Game State before publication.
- `GameStateService` must not publish an invalid Game State.
- `GameStateService` must not publish a failed snapshot load.
- `GameStateService` must publish a Simulation Core candidate only from a `COMPLETED` or `DECISION_REQUIRED` result.
- `GameStateService` must not publish a Simulation Core candidate from a `REJECTED` or `FAULTED` result.
- A production Advance action must not publish the intermediate candidate from `commit_plan`.
- A production Advance action must publish only its final candidate Game State.
- Authoritative Game State fields must remain normal typed `Resource` data.
- Authoritative Game State fields must not be Echo objects.

## Failure contract

- Each service contract failure must report a stable failure code.
- Each service contract failure must terminate the Godot process.
- A service contract failure must have the `SERVICE_CONTRACT_FAILURE` prefix.

## Prohibited mechanisms

- The implementation must not use a global service registry.
- The implementation must not use an Autoload service provider.
- The implementation must not search the scene tree for a provider.
- The implementation must not traverse ancestors for a provider.
- The implementation must not inject fields through dynamic reflection.
- The implementation must not use a service-locator fallback.
- The implementation must not use a missing-provider default.
- The implementation must not continue after a provider contract failure.

## Verification

- The service tests must use the standard non-.NET Godot 4.7 runtime.
- The service tests must reject a Mono or .NET runtime.
- The service tests must verify registration before injection.
- The service tests must verify injection before consumer readiness.
- The service tests must verify context ownership.
- The service tests must verify reverse disposal order.
- The service tests must verify strict provider failures.

Run this command from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\services-test.ps1
```
