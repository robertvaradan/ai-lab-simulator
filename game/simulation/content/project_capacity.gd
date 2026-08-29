class_name ProjectCapacity
extends RefCounted


static func reserved_project_teams(projects: Dictionary[StringName, ProjectState]) -> int:
	var reserved_teams: int = 0
	var project_ids: Array[StringName] = []
	project_ids.assign(projects.keys())
	project_ids.sort()
	for project_id: StringName in project_ids:
		var project: ProjectState = projects[project_id]
		if project == null or not project.is_active():
			continue
		reserved_teams += project.reserved_project_teams
	return reserved_teams


static func reserved_compute_unit_months(projects: Dictionary[StringName, ProjectState]) -> int:
	var reserved_compute: int = 0
	var project_ids: Array[StringName] = []
	project_ids.assign(projects.keys())
	project_ids.sort()
	for project_id: StringName in project_ids:
		var project: ProjectState = projects[project_id]
		if project == null or not project.is_active():
			continue
		reserved_compute += project.reserved_compute_unit_months
	return reserved_compute


static func free_project_teams(company: CompanyState) -> int:
	return company.project_team_count - reserved_project_teams(company.projects)


static func free_compute_unit_months(company: CompanyState) -> int:
	return company.compute_capacity_unit_months - reserved_compute_unit_months(company.projects)
