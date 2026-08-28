class_name SimulationRuleGraphCompiler
extends RefCounted


static func compile_rule_graph(
		rule_registry: SimulationRuleRegistry,
		state_path_registry: SimulationStatePathRegistry,
		event_registry: SimulationEventRegistry,
		graph_id: StringName,
		graph_version: int,
		content_version: int
	) -> RuleGraphCompilationResult:
	var result: RuleGraphCompilationResult = RuleGraphCompilationResult.new()
	if rule_registry == null:
		_add_error(result, &"rule_graph.missing_rule_registry", "The Rule registry is missing.")
	if state_path_registry == null:
		_add_error(result, &"rule_graph.missing_state_path_registry", "The state-path registry is missing.")
	if event_registry == null:
		_add_error(result, &"rule_graph.missing_event_registry", "The event registry is missing.")
	if not result.diagnostics.is_empty():
		return result
	rule_registry.seal()
	state_path_registry.seal()
	event_registry.seal()
	if not StableIdentifier.is_valid(graph_id):
		_add_error(result, &"rule_graph.invalid_graph_id", "Rule Graph identifier %s is invalid." % graph_id)
	if graph_version < 1:
		_add_error(result, &"rule_graph.invalid_graph_version", "The Rule Graph version must be positive.")
	if content_version < 1:
		_add_error(result, &"rule_graph.invalid_content_version", "The content version must be positive.")
	result.diagnostics.append_array(rule_registry.get_diagnostics())
	result.diagnostics.append_array(state_path_registry.get_diagnostics())
	result.diagnostics.append_array(event_registry.get_diagnostics())

	var rules: Array[SimulationRule] = rule_registry.get_rules_in_registration_order()
	for path_id: StringName in state_path_registry.get_path_ids():
		var path: SimulationStatePath = state_path_registry.get_path(path_id)
		if not StableIdentifier.is_valid(path_id) or path == null or not path.is_valid_contract():
			_add_error(
				result,
				&"rule_graph.invalid_state_path",
				"State path %s has an invalid accessor contract." % path_id,
				&"",
				path_id
			)
	for rule: SimulationRule in rules:
		_validate_rule(rule, rule_registry, state_path_registry, event_registry, result)
	_validate_ambiguous_writes(rules, rule_registry, result)
	_validate_phase_order_dependencies(rules, rule_registry, result)
	if not result.diagnostics.is_empty():
		return result

	var ordered_rules: Array[SimulationRule] = _phase_ordered_rules(rules, rule_registry, result)
	if not result.diagnostics.is_empty():
		return result
	result.graph = CompiledRuleGraph.new(graph_id, graph_version, content_version, ordered_rules)
	return result


static func _validate_rule(
		rule: SimulationRule,
		rule_registry: SimulationRuleRegistry,
		state_path_registry: SimulationStatePathRegistry,
		event_registry: SimulationEventRegistry,
		result: RuleGraphCompilationResult
	) -> void:
	if rule == null:
		_add_error(result, &"rule_graph.missing_rule", "The Rule registry contains a missing Rule.")
		return
	if not StableIdentifier.is_valid(rule.stable_id):
		_add_rule_error(result, &"rule_graph.invalid_rule_id", rule, "The Rule identifier is invalid.")
	if rule.display_name.is_empty():
		_add_rule_error(result, &"rule_graph.missing_display_name", rule, "The Rule display name is missing.")
	if not StableIdentifier.is_valid(rule.phase_id):
		_add_rule_error(result, &"rule_graph.invalid_phase_id", rule, "The Rule phase identifier is invalid.")
	elif not SimulationRulePhase.is_canonical(rule.phase_id):
		_add_rule_error(
			result,
			&"rule_graph.unknown_phase_id",
			rule,
			"Rule phase identifier %s is not a canonical Rule phase." % rule.phase_id
		)
	if rule.execution_order < 0 and rule.order_after_rule_ids.is_empty():
		_add_rule_error(
			result,
			&"rule_graph.missing_execution_order",
			rule,
			"The Rule must declare an execution order or an order dependency."
		)
	if not StableIdentifier.is_valid(rule.graph_group_id):
		_add_rule_error(result, &"rule_graph.invalid_graph_group", rule, "The Rule graph group is invalid.")
	if rule.specification_references.is_empty():
		_add_rule_error(
			result,
			&"rule_graph.missing_specification_reference",
			rule,
			"The Rule specification reference is missing."
		)
	for reference: String in rule.specification_references:
		if reference.is_empty():
			_add_rule_error(
				result,
				&"rule_graph.invalid_specification_reference",
				rule,
				"The Rule contains an empty specification reference."
			)
	_validate_unique_ids(rule.order_after_rule_ids, "order dependency", rule, result)
	_validate_unique_ids(rule.read_state_paths, "read state path", rule, result)
	_validate_unique_ids(rule.write_state_paths, "write state path", rule, result)
	_validate_unique_ids(rule.consumed_event_ids, "consumed event", rule, result)
	_validate_unique_ids(rule.emitted_event_ids, "emitted event", rule, result)
	_validate_unique_ids(rule.condition_ids, "condition", rule, result)
	for dependency_id: StringName in rule.order_after_rule_ids:
		if dependency_id == rule.stable_id:
			_add_rule_error(
				result, &"rule_graph.self_dependency", rule, "The Rule depends on itself."
			)
		elif rule_registry.get_rule(dependency_id) == null:
			_add_rule_error(
				result,
				&"rule_graph.missing_order_dependency",
				rule,
				"Order dependency %s does not exist." % dependency_id
			)
	for path_id: StringName in rule.read_state_paths:
		if not state_path_registry.has_path(path_id):
			_add_error(
				result,
				&"rule_graph.unknown_read_state_path",
				"Rule %s declares unknown read state path %s." % [rule.stable_id, path_id],
				rule.stable_id,
				path_id
			)
	for path_id: StringName in rule.write_state_paths:
		if not state_path_registry.has_path(path_id):
			_add_error(
				result,
				&"rule_graph.unknown_write_state_path",
				"Rule %s declares unknown write state path %s." % [rule.stable_id, path_id],
				rule.stable_id,
				path_id
			)
	for event_id: StringName in rule.consumed_event_ids:
		if not event_registry.has_event(event_id):
			_add_rule_error(
				result,
				&"rule_graph.unknown_consumed_event",
				rule,
				"Consumed event %s is unknown." % event_id
			)
	for event_id: StringName in rule.emitted_event_ids:
		if not event_registry.has_event(event_id):
			_add_rule_error(
				result,
				&"rule_graph.unknown_emitted_event",
				rule,
				"Emitted event %s is unknown." % event_id
			)


static func _validate_unique_ids(
		identifiers: Array[StringName],
		identifier_name: String,
		rule: SimulationRule,
		result: RuleGraphCompilationResult
	) -> void:
	var seen: Dictionary[StringName, bool] = {}
	for identifier: StringName in identifiers:
		if not StableIdentifier.is_valid(identifier):
			_add_rule_error(
				result,
				&"rule_graph.invalid_metadata_identifier",
				rule,
				"The %s identifier %s is invalid." % [identifier_name, identifier]
			)
		if seen.has(identifier):
			_add_rule_error(
				result,
				&"rule_graph.duplicate_metadata_identifier",
				rule,
				"The %s identifier %s is duplicated." % [identifier_name, identifier]
			)
		seen[identifier] = true


static func _validate_ambiguous_writes(
		rules: Array[SimulationRule],
		rule_registry: SimulationRuleRegistry,
		result: RuleGraphCompilationResult
	) -> void:
	for first_index: int in range(rules.size()):
		var first_rule: SimulationRule = rules[first_index]
		for second_index: int in range(first_index + 1, rules.size()):
			var second_rule: SimulationRule = rules[second_index]
			var shared_paths: Array[StringName] = []
			for path_id: StringName in first_rule.write_state_paths:
				if second_rule.write_state_paths.has(path_id):
					shared_paths.append(path_id)
			if shared_paths.is_empty():
				continue
			var first_phase_index: int = SimulationRulePhase.index_of(first_rule.phase_id)
			var second_phase_index: int = SimulationRulePhase.index_of(second_rule.phase_id)
			var ordered_by_phase: bool = (
				first_phase_index >= 0
				and second_phase_index >= 0
				and first_phase_index != second_phase_index
			)
			var explicitly_ordered: bool = (
				ordered_by_phase
				or (first_rule.execution_order >= 0
					and second_rule.execution_order >= 0
					and first_rule.execution_order != second_rule.execution_order)
				or _depends_on(first_rule, second_rule.stable_id, rule_registry, {})
				or _depends_on(second_rule, first_rule.stable_id, rule_registry, {})
			)
			if explicitly_ordered:
				continue
			shared_paths.sort()
			_add_error(
				result,
				&"rule_graph.ambiguous_same_path_write",
				"Rules %s and %s write state path %s without explicit order."
				% [first_rule.stable_id, second_rule.stable_id, shared_paths[0]],
				first_rule.stable_id,
				shared_paths[0]
			)


static func _depends_on(
		rule: SimulationRule,
		target_rule_id: StringName,
		rule_registry: SimulationRuleRegistry,
		visited: Dictionary[StringName, bool]
	) -> bool:
	if rule == null or visited.has(rule.stable_id):
		return false
	visited[rule.stable_id] = true
	for dependency_id: StringName in rule.order_after_rule_ids:
		if dependency_id == target_rule_id:
			return true
		var dependency: SimulationRule = rule_registry.get_rule(dependency_id)
		if _depends_on(dependency, target_rule_id, rule_registry, visited):
			return true
	return false


static func _validate_phase_order_dependencies(
		rules: Array[SimulationRule],
		rule_registry: SimulationRuleRegistry,
		result: RuleGraphCompilationResult
	) -> void:
	for rule: SimulationRule in rules:
		var phase_index: int = SimulationRulePhase.index_of(rule.phase_id)
		if phase_index < 0:
			continue
		for dependency_id: StringName in rule.order_after_rule_ids:
			var dependency: SimulationRule = rule_registry.get_rule(dependency_id)
			if dependency == null:
				continue
			var dependency_phase_index: int = SimulationRulePhase.index_of(dependency.phase_id)
			if dependency_phase_index < 0:
				continue
			if dependency_phase_index > phase_index:
				_add_rule_error(
					result,
					&"rule_graph.phase_order_violation",
					rule,
					"Order dependency %s belongs to a later canonical Rule phase." % dependency_id
				)


static func _phase_ordered_rules(
		rules: Array[SimulationRule],
		rule_registry: SimulationRuleRegistry,
		result: RuleGraphCompilationResult
	) -> Array[SimulationRule]:
	var ordered: Array[SimulationRule] = []
	for phase_id: StringName in SimulationRulePhase.canonical_phase_ids():
		var bucket: Array[SimulationRule] = []
		for rule: SimulationRule in rules:
			if rule.phase_id == phase_id:
				bucket.append(rule)
		var phase_ordered: Array[SimulationRule] = _stable_topological_order(
			bucket,
			rule_registry,
			result
		)
		if not result.diagnostics.is_empty():
			return []
		ordered.append_array(phase_ordered)
	return ordered


static func _stable_topological_order(
		rules: Array[SimulationRule],
		rule_registry: SimulationRuleRegistry,
		result: RuleGraphCompilationResult
	) -> Array[SimulationRule]:
	var ordered: Array[SimulationRule] = []
	var remaining: Array[SimulationRule] = []
	remaining.assign(rules)
	while not remaining.is_empty():
		var selected_index: int = -1
		for index: int in range(remaining.size()):
			var candidate: SimulationRule = remaining[index]
			var dependencies_complete: bool = true
			for dependency_id: StringName in candidate.order_after_rule_ids:
				var dependency: SimulationRule = rule_registry.get_rule(dependency_id)
				if dependency == null:
					dependencies_complete = false
					break
				if dependency.phase_id != candidate.phase_id:
					continue
				if not _contains_rule(ordered, dependency_id):
					dependencies_complete = false
					break
			if not dependencies_complete:
				continue
			if selected_index < 0 or _comes_before(candidate, remaining[selected_index]):
				selected_index = index
		if selected_index < 0:
			_add_error(
				result,
				&"rule_graph.same_step_cycle",
				"The Rule Graph contains a same-step order dependency cycle."
			)
			return []
		ordered.append(remaining[selected_index])
		remaining.remove_at(selected_index)
	return ordered


static func _contains_rule(rules: Array[SimulationRule], rule_id: StringName) -> bool:
	for rule: SimulationRule in rules:
		if rule.stable_id == rule_id:
			return true
	return false


static func _comes_before(first: SimulationRule, second: SimulationRule) -> bool:
	var first_order: int = first.execution_order if first.execution_order >= 0 else 2147483647
	var second_order: int = second.execution_order if second.execution_order >= 0 else 2147483647
	if first_order != second_order:
		return first_order < second_order
	return String(first.stable_id) < String(second.stable_id)


static func _add_rule_error(
		result: RuleGraphCompilationResult,
		code: StringName,
		rule: SimulationRule,
		message: String
	) -> void:
	_add_error(result, code, "Rule %s: %s" % [rule.stable_id, message], rule.stable_id)


static func _add_error(
		result: RuleGraphCompilationResult,
		code: StringName,
		message: String,
		rule_id: StringName = &"",
		state_path: StringName = &""
	) -> void:
	result.diagnostics.append(
		SimulationDiagnostic.new(
			SimulationDiagnostic.Severity.ERROR,
			code,
			message,
			rule_id,
			state_path
		)
	)
