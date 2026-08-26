class_name CompanyState
extends Resource

@export var sites: Dictionary[StringName, SiteState] = {}
@export var staff_person_count: int = -1
@export var project_team_count: int = -1
@export var compute_capacity_unit_months: int = -1
@export var fixed_operating_cost_musd_per_month_step: int = -1
@export var projects: Dictionary[StringName, ProjectState] = {}
@export var models: Dictionary[StringName, ModelState] = {}
@export var applications: Dictionary[StringName, ApplicationState] = {}
@export var contracts: Dictionary[StringName, ContractState] = {}
@export var public_trust_points: int = -1
@export var government_trust_points: int = -1


func _init() -> void:
	pass
