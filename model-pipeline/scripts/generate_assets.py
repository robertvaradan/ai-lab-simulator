"""Deterministically generate and export the AI Lab campus kit with Blender 5.1."""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy


EXPECTED_STATES = ["growth", "overload", "scrutiny"]
EXPECTED_FAMILIES = ["lab_core", "compute", "research_talent"]
VALID_PREFIXES = ("Base__", "Growth__", "Overload__", "Scrutiny__")
REQUIRED_MANIFEST_FIELDS = {
    "schema_version", "asset_id", "family", "footprint", "location_role", "state_layers",
    "lod_policy", "collision_type", "material_budget", "source_file", "export_file",
    "generator", "required_blender",
}


def fail(message: str) -> None:
    raise RuntimeError(f"ASSET_PIPELINE_ERROR: {message}")


def parse_repo_root() -> Path:
    if "--" not in sys.argv:
        fail("expected Blender arguments after '--': --repo-root <path>")
    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) != 2 or args[0] != "--repo-root":
        fail(f"expected exactly '--repo-root <path>', received: {args}")
    root = Path(args[1]).resolve()
    if not (root / "game" / "project.godot").is_file():
        fail(f"repo root does not contain game/project.godot: {root}")
    return root


def load_json(path: Path) -> dict:
    if not path.is_file():
        fail(f"required JSON file is missing: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"could not read valid JSON from {path}: {exc}")


def validate_manifest(manifest: dict) -> None:
    missing = sorted(REQUIRED_MANIFEST_FIELDS - manifest.keys())
    if missing:
        fail(f"manifest is missing required fields: {', '.join(missing)}")
    if manifest["schema_version"] != 1:
        fail(f"schema_version must be 1, got {manifest['schema_version']!r}")
    if manifest["state_layers"] != EXPECTED_STATES:
        fail(f"state_layers must be exactly {EXPECTED_STATES}, got {manifest['state_layers']!r}")
    if manifest["family"] != EXPECTED_FAMILIES:
        fail(f"family must be exactly {EXPECTED_FAMILIES}, got {manifest['family']!r}")
    if manifest["source_file"] != "source/campus_modular_kit.blend":
        fail(f"unexpected source_file ownership: {manifest['source_file']!r}")
    if manifest["export_file"] != "game/assets/generated/campus_modular_kit.glb":
        fail(f"unexpected export_file ownership: {manifest['export_file']!r}")
    if manifest["generator"] != "model-pipeline/scripts/generate_assets.py":
        fail(f"unexpected generator ownership: {manifest['generator']!r}")
    if manifest["required_blender"] != "5.1":
        fail(f"required_blender must be '5.1', got {manifest['required_blender']!r}")
    if manifest["collision_type"] != "none_render_proof":
        fail(f"prototype collision_type must be 'none_render_proof', got {manifest['collision_type']!r}")
    budget = manifest["material_budget"]
    if budget != {"max_materials": 10, "painted_textures": 0}:
        fail(f"material_budget must remain {{max_materials: 10, painted_textures: 0}}, got {budget!r}")
    footprint = manifest["footprint"]
    for field in ("width_m", "depth_m", "height_m"):
        if not isinstance(footprint.get(field), (int, float)) or footprint[field] <= 0:
            fail(f"footprint.{field} must be a positive number")


def validate_blender_version() -> None:
    actual = f"{bpy.app.version[0]}.{bpy.app.version[1]}"
    if actual != "5.1":
        fail(f"this generator is pinned to Blender 5.1, running {bpy.app.version_string}")


def hex_rgba(value: str) -> tuple[float, float, float, float]:
    if not isinstance(value, str) or len(value) != 7 or not value.startswith("#"):
        fail(f"palette color must be #RRGGBB, got {value!r}")
    try:
        return tuple(int(value[index : index + 2], 16) / 255.0 for index in (1, 3, 5)) + (1.0,)
    except ValueError:
        fail(f"palette color must be hexadecimal, got {value!r}")


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(collection):
            collection.remove(block)


def make_material(
    name: str,
    color: str,
    *,
    metallic: float = 0.0,
    roughness: float = 0.7,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    rgba = hex_rgba(color)
    material.diffuse_color = rgba
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled is None:
        fail(f"Blender 5.1 Principled BSDF node is missing for material {name}")
    principled.inputs["Base Color"].default_value = rgba
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if emission_strength > 0.0:
        principled.inputs["Emission Color"].default_value = rgba
        principled.inputs["Emission Strength"].default_value = emission_strength
    return material


def assign_metadata(obj: bpy.types.Object, name: str, material: bpy.types.Material, asset_id: str) -> None:
    obj.name = name
    obj.data.name = f"{name}__Mesh"
    obj.data.materials.append(material)
    obj["asset_id"] = asset_id
    obj["state_layer"] = name.split("__", 1)[0].lower()
    obj["generated_by"] = "model-pipeline/scripts/generate_assets.py"


def apply_bevel(obj: bpy.types.Object, width: float, segments: int = 2) -> None:
    if width <= 0.0:
        return
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    modifier = obj.modifiers.new(name="DeterministicBevel", type="BEVEL")
    modifier.width = width
    modifier.segments = segments
    modifier.limit_method = "ANGLE"
    bpy.ops.object.modifier_apply(modifier=modifier.name)


def add_box(
    name: str,
    location: tuple[float, float, float],
    size: tuple[float, float, float],
    material: bpy.types.Material,
    asset_id: str,
    *,
    bevel: float = 0.12,
    rotation_z: float = 0.0,
) -> bpy.types.Object:
    if min(size) <= 0.0:
        fail(f"box dimensions must be positive for {name}: {size}")
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=(0.0, 0.0, rotation_z))
    obj = bpy.context.object
    obj.scale = (size[0] / 2.0, size[1] / 2.0, size[2] / 2.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_metadata(obj, name, material, asset_id)
    apply_bevel(obj, min(bevel, min(size) * 0.2))
    return obj


def add_cylinder(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    material: bpy.types.Material,
    asset_id: str,
    *,
    vertices: int = 12,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    assign_metadata(obj, name, material, asset_id)
    apply_bevel(obj, min(0.08, radius * 0.2))
    return obj


def add_cone(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    material: bpy.types.Material,
    asset_id: str,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=radius, radius2=radius * 0.3, depth=depth, location=location)
    obj = bpy.context.object
    assign_metadata(obj, name, material, asset_id)
    apply_bevel(obj, 0.05)
    return obj


def build_lab_core(materials: dict[str, bpy.types.Material], asset_id: str) -> None:
    cream, coral, glass, metal = (materials[key] for key in ("cream", "coral", "glass", "metal"))
    add_box("Base__LabCore__Foundation", (-9.0, 0.0, 0.55), (8.4, 7.0, 1.1), materials["concrete"], asset_id, bevel=0.2)
    add_box("Base__LabCore__WestWing", (-11.3, 0.3, 2.55), (3.2, 5.8, 4.0), cream, asset_id, bevel=0.28)
    add_box("Base__LabCore__EastWing", (-6.7, 0.3, 2.55), (3.2, 5.8, 4.0), cream, asset_id, bevel=0.28)
    add_box("Base__LabCore__CoreTower", (-9.0, 0.65, 3.7), (3.0, 4.7, 6.3), coral, asset_id, bevel=0.34)
    add_box("Base__LabCore__AtriumGlass", (-9.0, -2.05, 3.15), (2.25, 0.32, 4.75), glass, asset_id, bevel=0.08)
    add_box("Base__LabCore__EntryCanopy", (-9.0, -3.2, 1.75), (3.8, 1.15, 0.32), metal, asset_id, bevel=0.08)
    add_box("Base__LabCore__RoofBridge", (-9.0, 0.0, 5.35), (6.5, 1.1, 0.38), metal, asset_id, bevel=0.1)
    for index, x_pos in enumerate((-12.2, -11.3, -10.4, -7.6, -6.7, -5.8)):
        add_box(f"Base__LabCore__Window_{index:02d}", (x_pos, -2.63, 2.75), (0.56, 0.18, 1.65), glass, asset_id, bevel=0.03)
    for index, x_pos in enumerate((-10.95, -7.05)):
        add_cylinder(f"Base__LabCore__RoofVent_{index:02d}", (x_pos, 0.55, 5.0), 0.47, 1.15, metal, asset_id, vertices=10)


def build_compute(materials: dict[str, bpy.types.Material], asset_id: str) -> None:
    add_box("Base__Compute__Foundation", (0.0, 0.0, 0.5), (8.2, 6.6, 1.0), materials["concrete"], asset_id, bevel=0.18)
    add_box("Base__Compute__MainMass", (0.0, 0.35, 3.0), (7.4, 5.6, 5.0), materials["metal"], asset_id, bevel=0.3)
    add_box("Base__Compute__ServiceSpine", (0.0, 2.65, 3.4), (5.7, 0.55, 4.2), materials["coral"], asset_id, bevel=0.12)
    add_box("Base__Compute__FrontRibbon", (0.0, -2.52, 3.15), (6.4, 0.22, 1.3), materials["glass"], asset_id, bevel=0.06)
    for index, x_pos in enumerate((-3.05, -2.05, -1.0, 0.0, 1.0, 2.05, 3.05)):
        add_box(f"Base__Compute__FacadeRib_{index:02d}", (x_pos, -2.72, 3.15), (0.18, 0.25, 2.2), materials["concrete"], asset_id, bevel=0.025)
    for index, x_pos in enumerate((-2.35, 0.0, 2.35)):
        add_cylinder(f"Base__Compute__CoolingTower_{index:02d}", (x_pos, 0.65, 6.05), 0.72, 1.55, materials["concrete"], asset_id, vertices=10)
        add_cylinder(f"Base__Compute__CoolingCap_{index:02d}", (x_pos, 0.65, 6.88), 0.88, 0.2, materials["metal"], asset_id, vertices=10)
    add_box("Base__Compute__StatusRail", (0.0, -2.82, 4.9), (5.4, 0.14, 0.18), materials["growth_light"], asset_id, bevel=0.03)


def build_research(materials: dict[str, bpy.types.Material], asset_id: str) -> None:
    add_box("Base__Research__Foundation", (9.0, 0.0, 0.5), (8.4, 6.8, 1.0), materials["concrete"], asset_id, bevel=0.18)
    add_box("Base__Research__LowerTerrace", (8.5, 0.25, 1.8), (7.2, 5.9, 2.6), materials["cream"], asset_id, bevel=0.3)
    add_box("Base__Research__MiddleTerrace", (9.2, 0.55, 3.45), (5.6, 5.0, 2.3), materials["cream"], asset_id, bevel=0.28)
    add_box("Base__Research__UpperStudio", (9.9, 0.9, 5.1), (4.0, 4.0, 2.0), materials["coral"], asset_id, bevel=0.3)
    add_box("Base__Research__LowerGlass", (8.5, -2.76, 1.95), (5.9, 0.2, 1.25), materials["glass"], asset_id, bevel=0.04)
    add_box("Base__Research__MiddleGlass", (9.2, -2.0, 3.55), (4.4, 0.2, 1.05), materials["glass"], asset_id, bevel=0.04)
    add_box("Base__Research__UpperGlass", (9.9, -1.18, 5.2), (2.9, 0.2, 0.9), materials["glass"], asset_id, bevel=0.04)
    add_box("Base__Research__TerracePlanter", (11.7, -1.8, 4.05), (1.2, 1.5, 0.42), materials["vegetation"], asset_id, bevel=0.1)
    for index, x_pos in enumerate((6.15, 7.1, 8.05, 9.0, 9.95, 10.9)):
        add_box(f"Base__Research__WindowMullion_{index:02d}", (x_pos, -2.89, 1.95), (0.12, 0.12, 1.4), materials["metal"], asset_id, bevel=0.015)


def build_growth_layer(materials: dict[str, bpy.types.Material], asset_id: str) -> None:
    add_box("Growth__LabCore__ExpansionPod", (-13.55, 1.45, 1.55), (2.0, 2.4, 2.1), materials["cream"], asset_id, bevel=0.3)
    add_box("Growth__LabCore__ExpansionGlass", (-13.55, 0.2, 1.6), (1.25, 0.16, 1.15), materials["glass"], asset_id, bevel=0.03)
    add_box("Growth__Compute__NewCapacityPod", (3.75, 1.25, 1.5), (2.1, 2.5, 2.0), materials["metal"], asset_id, bevel=0.25)
    add_box("Growth__Compute__CapacityLight", (3.75, -0.03, 1.65), (1.25, 0.14, 0.22), materials["growth_light"], asset_id, bevel=0.03)
    add_box("Growth__Research__OpenStudio", (12.7, 1.45, 2.0), (1.8, 2.5, 2.6), materials["cream"], asset_id, bevel=0.28)
    add_box("Growth__Research__StudioLight", (12.7, 0.12, 2.05), (1.0, 0.12, 0.26), materials["growth_light"], asset_id, bevel=0.03)
    for index, (x_pos, y_pos) in enumerate(((-13.3, -2.8), (-4.0, -2.9), (4.3, -2.9), (13.1, -2.6), (6.0, 2.8))):
        add_cylinder(f"Growth__Campus__TreeTrunk_{index:02d}", (x_pos, y_pos, 0.8), 0.12, 1.1, materials["metal"], asset_id, vertices=8)
        add_cone(f"Growth__Campus__TreeCrown_{index:02d}", (x_pos, y_pos, 1.75), 0.7, 1.45, materials["vegetation"], asset_id)
    for index, x_pos in enumerate((-9.0, 0.0, 9.0)):
        add_box(f"Growth__Campus__StatusPylon_{index:02d}", (x_pos, -3.85, 1.15), (0.28, 0.28, 1.9), materials["growth_light"], asset_id, bevel=0.06)


def build_overload_layer(materials: dict[str, bpy.types.Material], asset_id: str) -> None:
    for index, x_pos in enumerate((-11.5, -9.0, -6.5)):
        add_cylinder(f"Overload__LabCore__HotVent_{index:02d}", (x_pos, 2.4, 5.65), 0.28, 1.65, materials["overload_light"], asset_id, vertices=10)
    for index, x_pos in enumerate((-2.8, -1.4, 0.0, 1.4, 2.8)):
        add_cylinder(f"Overload__Compute__EmergencyCooler_{index:02d}", (x_pos, -1.2, 6.1), 0.35, 1.5, materials["overload_light"], asset_id, vertices=10)
    add_cylinder("Overload__Compute__HotPipe", (0.0, -3.05, 2.1), 0.2, 6.2, materials["overload_light"], asset_id, vertices=10, rotation=(0.0, math.pi / 2.0, 0.0))
    add_cylinder("Overload__Research__ServicePipe", (12.25, 0.4, 2.8), 0.24, 4.2, materials["overload_light"], asset_id, vertices=10)
    for index, x_pos in enumerate((-12.5, -4.2, 4.2, 12.5)):
        add_box(f"Overload__Campus__WarningBeacon_{index:02d}", (x_pos, -3.75, 0.95), (0.42, 0.42, 1.45), materials["warning_light"], asset_id, bevel=0.08)
        add_box(f"Overload__Campus__WarningCap_{index:02d}", (x_pos, -3.75, 1.78), (0.58, 0.58, 0.22), materials["overload_light"], asset_id, bevel=0.08)


def build_scrutiny_layer(materials: dict[str, bpy.types.Material], asset_id: str) -> None:
    for index, x_pos in enumerate(range(-14, 15, 2)):
        add_box(f"Scrutiny__Campus__FencePost_{index:02d}", (float(x_pos), -4.15, 0.95), (0.16, 0.16, 1.65), materials["metal"], asset_id, bevel=0.025)
    add_box("Scrutiny__Campus__FenceRailLow", (0.0, -4.15, 0.62), (28.2, 0.12, 0.12), materials["metal"], asset_id, bevel=0.02)
    add_box("Scrutiny__Campus__FenceRailHigh", (0.0, -4.15, 1.25), (28.2, 0.12, 0.12), materials["metal"], asset_id, bevel=0.02)
    add_box("Scrutiny__Campus__Checkpoint", (0.0, -4.0, 1.2), (2.7, 1.4, 2.0), materials["concrete"], asset_id, bevel=0.25)
    add_box("Scrutiny__Campus__CheckpointGlass", (0.0, -4.74, 1.3), (1.55, 0.12, 0.9), materials["glass"], asset_id, bevel=0.03)
    for index, x_pos in enumerate((-9.0, 0.0, 9.0)):
        add_box(f"Scrutiny__Campus__ScanPostLeft_{index:02d}", (x_pos - 1.0, -3.55, 1.55), (0.22, 0.22, 2.6), materials["scrutiny_light"], asset_id, bevel=0.04)
        add_box(f"Scrutiny__Campus__ScanPostRight_{index:02d}", (x_pos + 1.0, -3.55, 1.55), (0.22, 0.22, 2.6), materials["scrutiny_light"], asset_id, bevel=0.04)
        add_box(f"Scrutiny__Campus__ScanHeader_{index:02d}", (x_pos, -3.55, 2.8), (2.2, 0.22, 0.22), materials["scrutiny_light"], asset_id, bevel=0.04)


def count_painted_texture_images() -> int:
    texture_images: set[int] = set()
    for material in bpy.data.materials:
        if material.node_tree is None:
            continue
        for node in material.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image is not None:
                texture_images.add(node.image.as_pointer())
    return len(texture_images)


def validate_scene(manifest: dict) -> None:
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not mesh_objects:
        fail("generator produced no mesh objects")
    invalid_names = sorted(obj.name for obj in mesh_objects if not obj.name.startswith(VALID_PREFIXES))
    if invalid_names:
        fail(f"objects violate the state-layer naming API: {invalid_names}")
    for prefix in VALID_PREFIXES:
        if not any(obj.name.startswith(prefix) for obj in mesh_objects):
            fail(f"required object layer is empty: {prefix}")
    for subject in ("LabCore", "Compute", "Research"):
        if not any(obj.name.startswith(f"Base__{subject}__") for obj in mesh_objects):
            fail(f"base kit is missing required subject: {subject}")
    if len(bpy.data.materials) > manifest["material_budget"]["max_materials"]:
        fail(f"material count {len(bpy.data.materials)} exceeds budget {manifest['material_budget']['max_materials']}")
    texture_count = count_painted_texture_images()
    if texture_count != manifest["material_budget"]["painted_textures"]:
        fail(f"painted texture count {texture_count} violates zero-texture contract")


def main() -> None:
    validate_blender_version()
    repo_root = parse_repo_root()
    pipeline_root = repo_root / "model-pipeline"
    manifest = load_json(pipeline_root / "manifest" / "assets.json")
    palette = load_json(pipeline_root / "config" / "palette.json")
    validate_manifest(manifest)

    required_palette = {
        "architecture_cream", "architecture_coral", "concrete_shadow", "metal_dark", "glass_teal",
        "vegetation", "growth_emissive", "overload_emissive", "warning_emissive", "scrutiny_emissive",
    }
    if set(palette) != required_palette:
        fail(f"palette keys must be exactly {sorted(required_palette)}, got {sorted(palette)}")

    clear_scene()
    materials = {
        "cream": make_material("Architecture_Cream", palette["architecture_cream"], roughness=0.72),
        "coral": make_material("Architecture_Coral", palette["architecture_coral"], roughness=0.68),
        "concrete": make_material("Concrete_Shadow", palette["concrete_shadow"], roughness=0.86),
        "metal": make_material("Metal_Dark", palette["metal_dark"], metallic=0.72, roughness=0.38),
        "glass": make_material("Glass_Teal", palette["glass_teal"], metallic=0.12, roughness=0.16),
        "vegetation": make_material("Vegetation", palette["vegetation"], roughness=0.9),
        "growth_light": make_material("Status_Growth", palette["growth_emissive"], roughness=0.22, emission_strength=4.0),
        "overload_light": make_material("Status_Overload", palette["overload_emissive"], roughness=0.22, emission_strength=5.0),
        "warning_light": make_material("Status_Warning", palette["warning_emissive"], roughness=0.25, emission_strength=4.0),
        "scrutiny_light": make_material("Status_Scrutiny", palette["scrutiny_emissive"], roughness=0.2, emission_strength=4.5),
    }

    asset_id = manifest["asset_id"]
    build_lab_core(materials, asset_id)
    build_compute(materials, asset_id)
    build_research(materials, asset_id)
    build_growth_layer(materials, asset_id)
    build_overload_layer(materials, asset_id)
    build_scrutiny_layer(materials, asset_id)
    validate_scene(manifest)

    scene = bpy.context.scene
    scene["asset_id"] = asset_id
    scene["manifest_schema_version"] = manifest["schema_version"]
    scene["state_layers"] = ",".join(manifest["state_layers"])
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    source_path = pipeline_root / manifest["source_file"]
    export_path = repo_root / manifest["export_file"]
    source_path.parent.mkdir(parents=True, exist_ok=True)
    export_path.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.save_as_mainfile(filepath=str(source_path))
    bpy.ops.export_scene.gltf(filepath=str(export_path), export_format="GLB", export_apply=True, export_extras=True)

    if not source_path.is_file() or source_path.stat().st_size < 100_000:
        fail(f"generated Blender source is missing or implausibly small: {source_path}")
    if not export_path.is_file() or export_path.stat().st_size < 20_000:
        fail(f"generated GLB is missing or implausibly small: {export_path}")

    mesh_count = sum(1 for obj in bpy.context.scene.objects if obj.type == "MESH")
    print(
        "PIPELINE_SUCCESS "
        f"asset_id={asset_id} meshes={mesh_count} materials={len(bpy.data.materials)} "
        f"painted_textures={count_painted_texture_images()} blend={source_path} glb={export_path}"
    )


if __name__ == "__main__":
    main()
