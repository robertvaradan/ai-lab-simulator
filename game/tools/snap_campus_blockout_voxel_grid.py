#!/usr/bin/env python3
"""One-shot helper: snap campus_blockout.tscn PrimitiveMesh sizes and node origins to 0.2 m voxels."""

from __future__ import annotations

import math
import re
import sys
from pathlib import Path

VOXEL = 0.2
HALF = VOXEL * 0.5
EPS = 1e-9
SKIP_BASIS_NAMES = {"WarmKey", "CoolFill", "GameplayCamera"}


def fmt(value: float) -> str:
	value = float(value)
	if abs(value) < EPS:
		return "0"
	rounded = round(round(value / HALF) * HALF, 10)
	if abs(rounded - round(rounded)) < 1e-8:
		return str(int(round(rounded)))
	tenths = round(rounded * 10.0)
	if abs(rounded * 10.0 - tenths) < 1e-6:
		return f"{rounded:.1f}"
	return f"{rounded:.6g}"


def snap_scalar(value: float) -> float:
	return round(value / VOXEL) * VOXEL


def snap_positive(value: float) -> float:
	snapped = round(value / VOXEL) * VOXEL
	if snapped < VOXEL - EPS:
		return VOXEL
	return snapped


def snap_interval(center: float, size: float) -> tuple[float, float]:
	"""Snap extents to the voxel grid. Keep at least one voxel of size."""
	size = max(abs(size), VOXEL)
	mn = center - size * 0.5
	mx = center + size * 0.5
	mn_s = snap_scalar(mn)
	mx_s = snap_scalar(mx)
	if mx_s <= mn_s + EPS:
		# Place one voxel with its center nearest the original center.
		cell = math.floor(center / VOXEL)
		mn_s = cell * VOXEL
		mx_s = mn_s + VOXEL
		# If center is in the upper half of the cell, keep that cell; else already correct.
		if center - mn_s >= VOXEL * 0.5 and abs(center - (mn_s + VOXEL)) < abs(center - (mn_s + HALF)):
			pass
	return (mn_s + mx_s) * 0.5, mx_s - mn_s


def fmt_vector3(x: float, y: float, z: float) -> str:
	return f"Vector3({fmt(x)}, {fmt(y)}, {fmt(z)})"


def basis_scale_and_rotation(basis: list[float]) -> tuple[tuple[float, float, float], bool]:
	bx = math.sqrt(basis[0] ** 2 + basis[3] ** 2 + basis[6] ** 2)
	by = math.sqrt(basis[1] ** 2 + basis[4] ** 2 + basis[7] ** 2)
	bz = math.sqrt(basis[2] ** 2 + basis[5] ** 2 + basis[8] ** 2)
	pure_scale = (
		abs(basis[1]) < 1e-5
		and abs(basis[2]) < 1e-5
		and abs(basis[3]) < 1e-5
		and abs(basis[5]) < 1e-5
		and abs(basis[6]) < 1e-5
		and abs(basis[7]) < 1e-5
	)
	return (bx, by, bz), pure_scale


def fmt_basis_origin(basis: list[float], origin: tuple[float, float, float]) -> str:
	cleaned: list[str] = []
	for value in basis:
		if abs(value) < 1e-6:
			cleaned.append("0")
		elif abs(abs(value) - 1.0) < 1e-5:
			cleaned.append("1" if value > 0 else "-1")
		else:
			cleaned.append(f"{value:.8g}")
	ox, oy, oz = origin
	return "Transform3D(" + ", ".join(cleaned) + f", {fmt(ox)}, {fmt(oy)}, {fmt(oz)})"


def snap_origin_for_box(
	origin: tuple[float, float, float],
	box_size: tuple[float, float, float],
	basis: list[float],
) -> tuple[float, float, float]:
	ox, oy, oz = origin
	x_axis = (basis[0], basis[3], basis[6])
	y_axis = (basis[1], basis[4], basis[7])
	z_axis = (basis[2], basis[5], basis[8])
	sx = math.sqrt(x_axis[0] ** 2 + x_axis[1] ** 2 + x_axis[2] ** 2) or 1.0
	sy = math.sqrt(y_axis[0] ** 2 + y_axis[1] ** 2 + y_axis[2] ** 2) or 1.0
	sz = math.sqrt(z_axis[0] ** 2 + z_axis[1] ** 2 + z_axis[2] ** 2) or 1.0
	world_half = [0.0, 0.0, 0.0]
	for local_size, axis in (
		(box_size[0] * sx, x_axis),
		(box_size[1] * sy, y_axis),
		(box_size[2] * sz, z_axis),
	):
		length = math.sqrt(axis[0] ** 2 + axis[1] ** 2 + axis[2] ** 2) or 1.0
		unit = (axis[0] / length, axis[1] / length, axis[2] / length)
		half = local_size * 0.5
		world_half[0] += abs(unit[0]) * half
		world_half[1] += abs(unit[1]) * half
		world_half[2] += abs(unit[2]) * half
	nox, _ = snap_interval(ox, world_half[0] * 2.0)
	noy, _ = snap_interval(oy, world_half[1] * 2.0)
	noz, _ = snap_interval(oz, world_half[2] * 2.0)
	return nox, noy, noz


def main() -> int:
	path = Path(__file__).resolve().parents[1] / "scenes" / "campus_blockout.tscn"
	if len(sys.argv) > 1:
		path = Path(sys.argv[1])
	text = path.read_text()
	box_sizes: dict[str, tuple[float, float, float]] = {}

	def replace_box(match: re.Match[str]) -> str:
		mesh_id = match.group(1)
		x, y, z = (float(value) for value in match.group(2).split(","))
		sx, sy, sz = snap_positive(x), snap_positive(y), snap_positive(z)
		box_sizes[mesh_id] = (sx, sy, sz)
		return f'[sub_resource type="BoxMesh" id="{mesh_id}"]\nsize = {fmt_vector3(sx, sy, sz)}'

	text = re.sub(
		r'\[sub_resource type="BoxMesh" id="([^"]+)"\]\nsize = Vector3\(([^)]+)\)',
		replace_box,
		text,
	)

	def replace_cylinder(match: re.Match[str]) -> str:
		mesh_id = match.group(1)
		body = match.group(2)
		top = float(re.search(r"top_radius = ([^\n]+)", body).group(1))
		bottom = float(re.search(r"bottom_radius = ([^\n]+)", body).group(1))
		height = float(re.search(r"height = ([^\n]+)", body).group(1))
		body2 = re.sub(r"top_radius = [^\n]+", f"top_radius = {fmt(snap_positive(top))}", body, count=1)
		body2 = re.sub(
			r"bottom_radius = [^\n]+",
			f"bottom_radius = {fmt(snap_positive(bottom))}",
			body2,
			count=1,
		)
		body2 = re.sub(r"height = [^\n]+", f"height = {fmt(snap_positive(height))}", body2, count=1)
		return f'[sub_resource type="CylinderMesh" id="{mesh_id}"]\n{body2}'

	text = re.sub(
		r'\[sub_resource type="CylinderMesh" id="([^"]+)"\]\n((?:(?!\[sub_resource|\[node).*\n)*)',
		replace_cylinder,
		text,
	)

	def replace_sphere(match: re.Match[str]) -> str:
		mesh_id = match.group(1)
		body = match.group(2)
		radius = float(re.search(r"radius = ([^\n]+)", body).group(1))
		radius_s = snap_positive(radius)
		body2 = re.sub(r"radius = [^\n]+", f"radius = {fmt(radius_s)}", body, count=1)
		height_match = re.search(r"height = ([^\n]+)", body)
		if height_match:
			height = float(height_match.group(1))
			height_s = snap_positive(height)
			if abs(height - 2.0 * radius) <= 0.35:
				height_s = snap_positive(2.0 * radius_s)
			body2 = re.sub(r"height = [^\n]+", f"height = {fmt(height_s)}", body2, count=1)
		return f'[sub_resource type="SphereMesh" id="{mesh_id}"]\n{body2}'

	text = re.sub(
		r'\[sub_resource type="SphereMesh" id="([^"]+)"\]\n((?:(?!\[sub_resource|\[node).*\n)*)',
		replace_sphere,
		text,
	)

	stats = {"transform_edits": 0}
	node_blocks = list(re.finditer(r'(\[node name="[^"]+"[^\]]*\]\n)((?:(?!\[node).*\n)*)', text))
	out_parts: list[str] = []
	last = 0

	for match in node_blocks:
		header = match.group(1)
		body = match.group(2)
		name_match = re.search(r'name="([^"]+)"', header)
		name = name_match.group(1) if name_match else ""
		mesh_match = re.search(r'mesh = SubResource\("(BoxMesh_[^"]+)"\)', body)
		box_size = box_sizes.get(mesh_match.group(1)) if mesh_match else None

		def repl_transform(transform_match: re.Match[str], node_name: str = name, size=box_size) -> str:
			values = [float(item.strip()) for item in transform_match.group(1).split(",")]
			if len(values) != 12:
				return transform_match.group(0)
			basis = values[:9]
			origin = (values[9], values[10], values[11])
			ox, oy, oz = origin

			if node_name in SKIP_BASIS_NAMES:
				if node_name == "GameplayCamera":
					nox, noy, noz = snap_scalar(ox), snap_scalar(oy), snap_scalar(oz)
					if (nox, noy, noz) != (ox, oy, oz):
						stats["transform_edits"] += 1
					basis_text = ", ".join(f"{value:.8g}" if abs(value) >= 1e-8 else "0" for value in basis)
					return f"transform = Transform3D({basis_text}, {fmt(nox)}, {fmt(noy)}, {fmt(noz)})"
				return transform_match.group(0)

			# Keep authored scale and rotation. Only snap translation.
			_, pure_scale = basis_scale_and_rotation(basis)
			new_basis = basis[:]
			if size is not None:
				nox, noy, noz = snap_origin_for_box(origin, size, basis)
			elif pure_scale:
				nox, noy, noz = snap_scalar(ox), snap_scalar(oy), snap_scalar(oz)
			else:
				nox, noy, noz = snap_scalar(ox), snap_scalar(oy), snap_scalar(oz)

			if (nox, noy, noz) != (ox, oy, oz) or new_basis != basis:
				stats["transform_edits"] += 1
			return "transform = " + fmt_basis_origin(new_basis, (nox, noy, noz))

		new_body = re.sub(r"transform = Transform3D\(([^)]+)\)", repl_transform, body, count=1)
		out_parts.append(text[last : match.start()])
		out_parts.append(header)
		out_parts.append(new_body)
		last = match.end()

	out_parts.append(text[last:])
	new_text = "".join(out_parts)
	path.write_text(new_text)

	size_values = [
		float(value)
		for size_text in re.findall(r"size = Vector3\(([^)]+)\)", new_text)
		for value in size_text.split(",")
	]
	off_sizes = [value for value in size_values if abs(value / VOXEL - round(value / VOXEL)) > 1e-6]
	origins: list[float] = []
	for transform_text in re.findall(r"Transform3D\(([^)]+)\)", new_text):
		parts = [float(item.strip()) for item in transform_text.split(",")]
		if len(parts) == 12:
			origins.extend(parts[9:12])
	# Odd voxel spans place centers on half-voxels (multiples of 0.1).
	off_pos = [value for value in origins if abs(value / HALF - round(value / HALF)) > 1e-5]

	print(f"path={path}")
	print(f"voxel={VOXEL}")
	print(f"box_meshes={len(box_sizes)}")
	print(f"transform_edits={stats['transform_edits']}")
	print(f"size_components_off_grid={len(off_sizes)}")
	print(f"positions_off_half_voxel={len(off_pos)}")
	if off_sizes[:8]:
		print(f"sample_off_sizes={off_sizes[:8]}")
	if off_pos[:8]:
		print(f"sample_off_positions={off_pos[:8]}")
	print("VOXEL_SNAP_SUCCESS")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
