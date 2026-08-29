class_name CodingAgentDemandCalculation
extends RefCounted

var succeeded: bool = false
var diagnostic: SimulationDiagnostic
var relevance_difference: int = 0
var relevance_tier_id: StringName = &""
var relevance_factor_basis_points: int = 0
var pricing_power_musd_per_contract_month: int = 0
var price_factor_basis_points: int = 0
var customer_contract_count: int = 0
var revenue_musd: int = 0
var inference_compute_unit_months: int = 0
