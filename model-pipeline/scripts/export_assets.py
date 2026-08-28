"""Bootstrap and export the one-file Blender campus library."""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import node_groups
import kit_catalog


EXPECTED_STATES = ["growth", "overload", "scrutiny"]
EXPECTED_FAMILIES = ["lab_core", "compute", "research_talent"]
EXPECTED_EXPORTS = [
    {"id": "lab_stage1", "collection": "Export__LabStage1", "layer": "base", "export_file": "game/assets/generated/lab_stage1.glb"},
    {"id": "compute", "collection": "Export__Compute", "layer": "base", "export_file": "game/assets/generated/compute.glb"},
    {"id": "research", "collection": "Export__Research", "layer": "base", "export_file": "game/assets/generated/research.glb"},
    {"id": "growth", "collection": "Export__Growth", "layer": "growth", "export_file": "game/assets/generated/growth.glb"},
    {"id": "overload", "collection": "Export__Overload", "layer": "overload", "export_file": "game/assets/generated/overload.glb"},
    {"id": "scrutiny", "collection": "Export__Scrutiny", "layer": "scrutiny", "export_file": "game/assets/generated/scrutiny.glb"},
]
LAB_STAGE_COLLECTION = "Export__LabStage1"
STATE_NAME_PREFIXES = ("Growth__", "Overload__", "Scrutiny__")
LAYER_PREFIX = {
    "base": "Base__",
    "growth": "Growth__",
    "overload": "Overload__",
    "scrutiny": "Scrutiny__",
}
REQUIRED_MANIFEST_FIELDS = {
    "schema_version",
    "asset_id",
    "family",
    "footprint",
    "location_role",
    "state_layers",
    "lod_policy",
    "collision_type",
    "material_budget",
    "source_file",
    "catalog_file",
    "exports",
    "generator",
    "required_blender",
}
REQUIRED_PALETTE = {
    "architecture_cream",
    "architecture_coral",
    "concrete_shadow",
    "metal_dark",
    "glass_teal",
    "vegetation",
    "growth_emissive",
    "overload_emissive",
    "warning_emissive",
    "scrutiny_emissive",
}
MIN_BLEND_BYTES = 80_000
MIN_GLB_BYTES = 1_500
SHADE_GROUP = "ALS_ShadeContract"
SHADE_MODIFIER = "ALS_Shade"
TREE_GROUP = "ALS_Tree"
SHADE_ANGLE = 30.0
LABEL_COLLECTION = "Authoring__Labels"
LABEL_PREFIX = "Guide__"


def fail(message: str) -> None:
    raise RuntimeError(f"ASSET_PIPELINE_ERROR: {message}")


def parse_cli() -> tuple[Path, str]:
    if "--" not in sys.argv:
        fail("expected Blender arguments after '--': --repo-root <path> --mode <bootstrap|export|sync-tools>")
    args = sys.argv[sys.argv.index("--") + 1 :]
    repo_root: Path | None = None
    mode: str | None = None
    index = 0
    while index < len(args):
        if args[index] == "--repo-root" and index + 1 < len(args):
            repo_root = Path(args[index + 1]).resolve()
            index += 2
            continue
        if args[index] == "--mode" and index + 1 < len(args):
            mode = args[index + 1]
            index += 2
            continue
        fail(f"unexpected argument: {args[index]}")
    if repo_root is None or mode is None:
        fail("expected '--repo-root <path> --mode <bootstrap|export|sync-tools>'")
    if mode not in ("bootstrap", "export", "sync-tools"):
        fail(f"mode must be 'bootstrap', 'export', or 'sync-tools', got {mode!r}")
    if not (repo_root / "game" / "project.godot").is_file():
        fail(f"repo root does not contain game/project.godot: {repo_root}")
    return repo_root, mode


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
    if manifest["schema_version"] != 2:
        fail(f"schema_version must be 2, got {manifest['schema_version']!r}")
    if manifest["state_layers"] != EXPECTED_STATES:
        fail(f"state_layers must be exactly {EXPECTED_STATES}, got {manifest['state_layers']!r}")
    if manifest["family"] != EXPECTED_FAMILIES:
        fail(f"family must be exactly {EXPECTED_FAMILIES}, got {manifest['family']!r}")
    if manifest["source_file"] != "source/campus_modular_kit.blend":
        fail(f"unexpected source_file ownership: {manifest['source_file']!r}")
    if manifest["catalog_file"] != "game/assets/generated/asset_catalog.json":
        fail(f"unexpected catalog_file ownership: {manifest['catalog_file']!r}")
    if manifest["generator"] != "model-pipeline/scripts/export_assets.py":
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
    exports = manifest["exports"]
    if exports != EXPECTED_EXPORTS:
        fail(f"exports must be exactly the six campus collections, got {exports!r}")


def validate_blender_version() -> None:
    actual = f"{bpy.app.version[0]}.{bpy.app.version[1]}"
    if actual != "5.1":
        fail(f"this pipeline is pinned to Blender 5.1, running {bpy.app.version_string}")


def hex_rgba(value: str) -> tuple[float, float, float, float]:
    if not isinstance(value, str) or len(value) != 7 or not value.startswith("#"):
        fail(f"palette color must be #RRGGBB, got {value!r}")
    try:
        return tuple(int(value[index : index + 2], 16) / 255.0 for index in (1, 3, 5)) + (1.0,)
    except ValueError:
        fail(f"palette color must be hexadecimal, got {value!r}")


def clear_factory_data() -> None:
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for collection in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights, bpy.data.node_groups):
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


def make_materials(palette: dict[str, str]) -> dict[str, bpy.types.Material]:
    if set(palette) != REQUIRED_PALETTE:
        fail(f"palette keys must be exactly {sorted(REQUIRED_PALETTE)}, got {sorted(palette)}")
    return {
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


def make_export_collections() -> dict[str, bpy.types.Collection]:
    collections: dict[str, bpy.types.Collection] = {}
    scene_collection = bpy.context.scene.collection
    for entry in EXPECTED_EXPORTS:
        name = entry["collection"]
        collection = bpy.data.collections.new(name)
        scene_collection.children.link(collection)
        collections[name] = collection
    return collections


def set_modifier_input(modifier: bpy.types.NodesModifier, socket_name: str, value: object) -> None:
    group = modifier.node_group
    if group is None:
        fail("Geometry Nodes modifier has no node group")
    for item in group.interface.items_tree:
        if getattr(item, "in_out", None) != "INPUT":
            continue
        if getattr(item, "item_type", "SOCKET") not in ("SOCKET",):
            continue
        if item.name != socket_name:
            continue
        modifier[item.identifier] = value
        return
    fail(f"Geometry Nodes group {group.name} has no exposed input '{socket_name}'")


def input_sockets(group: bpy.types.GeometryNodeTree) -> list[bpy.types.NodeTreeInterfaceSocket]:
    sockets: list[bpy.types.NodeTreeInterfaceSocket] = []
    for item in group.interface.items_tree:
        if getattr(item, "in_out", None) != "INPUT":
            continue
        if getattr(item, "item_type", "SOCKET") not in ("SOCKET",):
            continue
        sockets.append(item)
    return sockets


def snapshot_value(value: object) -> object:
    if value is None or isinstance(value, (str, bytes, int, float, bool, bpy.types.ID)):
        return value
    if hasattr(value, "to_list"):
        return tuple(value.to_list())
    try:
        return tuple(value)
    except TypeError:
        return value


def snapshot_modifier(modifier: bpy.types.NodesModifier) -> tuple[str | None, dict[str, object]]:
    group = modifier.node_group
    values: dict[str, object] = {}
    if group is None:
        return None, values
    for item in input_sockets(group):
        if item.name == "Geometry":
            continue
        if item.identifier in modifier:
            values[item.name] = snapshot_value(modifier[item.identifier])
    return group.name, values


def restore_modifier(obj_name: str, modifier: bpy.types.NodesModifier, values: dict[str, object]) -> None:
    for socket_name, value in values.items():
        if socket_name == "Geometry":
            continue
        set_modifier_input(modifier, socket_name, value)


def require_shade_group() -> bpy.types.GeometryNodeTree:
    group = bpy.data.node_groups.get(SHADE_GROUP)
    if group is None:
        fail(f"{SHADE_GROUP} node group is missing")
    return group


def ensure_shade_modifier(obj: bpy.types.Object, angle: float = SHADE_ANGLE) -> None:
    group = require_shade_group()
    shade_mods = [
        modifier
        for modifier in obj.modifiers
        if modifier.type == "NODES" and modifier.node_group is not None and modifier.node_group.name == SHADE_GROUP
    ]
    if not shade_mods:
        modifier = obj.modifiers.new(name=SHADE_MODIFIER, type="NODES")
        modifier.node_group = group
        set_modifier_input(modifier, "Angle", angle)
    else:
        modifier = shade_mods[0]
        modifier.node_group = group
        for extra in shade_mods[1:]:
            obj.modifiers.remove(extra)
    index = 0
    for modifier_index, candidate in enumerate(obj.modifiers):
        if candidate == modifier:
            index = modifier_index
            break
    last_index = len(obj.modifiers) - 1
    if index != last_index:
        obj.modifiers.move(index, last_index)


def is_authored_tree(obj: bpy.types.Object) -> bool:
    for part in obj.name.split("__"):
        if part.startswith("Tree"):
            return True
    for modifier in obj.modifiers:
        if modifier.type == "NODES" and modifier.node_group is not None and modifier.node_group.name == TREE_GROUP:
            return True
    return False


def remove_authored_trees() -> int:
    removed = 0
    for obj in list(bpy.data.objects):
        if obj.type != "MESH":
            continue
        if not is_authored_tree(obj):
            continue
        bpy.data.objects.remove(obj, do_unlink=True)
        removed += 1
    return removed


def harden_bevels(obj: bpy.types.Object) -> None:
    for modifier in obj.modifiers:
        if modifier.type != "BEVEL":
            continue
        modifier.harden_normals = True
        if modifier.segments < 3:
            modifier.segments = 3


def is_authoring_label(obj: bpy.types.Object) -> bool:
    return bool(obj.get("als_authoring_label")) or obj.name.startswith(LABEL_PREFIX)


def label_collection() -> bpy.types.Collection:
    collection = bpy.data.collections.get(LABEL_COLLECTION)
    if collection is None:
        collection = bpy.data.collections.new(LABEL_COLLECTION)
        bpy.context.scene.collection.children.link(collection)
    collection.hide_render = True
    return collection


def evaluated_top_z(obj: bpy.types.Object) -> float:
    bpy.context.view_layer.update()
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    try:
        if not mesh.vertices:
            return 1.2
        return max(vertex.co.z for vertex in mesh.vertices)
    finally:
        evaluated.to_mesh_clear()


def configure_label_object(obj: bpy.types.Object, body: str, size: float) -> None:
    curve = obj.data
    curve.body = body
    curve.size = size
    curve.align_x = "CENTER"
    curve.align_y = "BOTTOM"
    curve.space_line = 1.05
    material = bpy.data.materials.get("Status_Growth")
    if material is not None:
        if len(curve.materials) == 0:
            curve.materials.append(material)
        else:
            curve.materials[0] = material
    obj.show_in_front = True
    obj.hide_render = True
    obj.hide_select = True
    obj.display_type = "SOLID"
    obj.color = (0.38, 1.0, 0.82, 1.0)
    obj["als_authoring_label"] = True
    obj.rotation_euler = (math.pi / 2.0, 0.0, 0.0)


def ensure_building_label(collection: bpy.types.Collection, title: str, body: str) -> bpy.types.Object:
    labels = label_collection()
    name = f"{LABEL_PREFIX}Building__{collection.name}"
    members = [obj for obj in collection.objects if obj.type == "MESH"]
    if not members:
        existing = bpy.data.objects.get(name)
        if existing is not None:
            bpy.data.objects.remove(existing, do_unlink=True)
        fail(f"building collection has no meshes to label: {collection.name}")
    label = bpy.data.objects.get(name)
    if label is None:
        curve = bpy.data.curves.new(f"{name}__Text", type="FONT")
        label = bpy.data.objects.new(name, curve)
        labels.objects.link(label)
    xs = [obj.location.x for obj in members]
    ys = [obj.location.y for obj in members]
    top = max(obj.location.z + evaluated_top_z(obj) for obj in members)
    configure_label_object(label, f"{title}\n{body}", 0.42)
    label.parent = None
    label.location = (sum(xs) / len(xs), min(ys) - 0.4, top + 0.8)
    return label


def refresh_authoring_labels(_manifest: dict) -> None:
    labels = label_collection()
    keep: set[str] = set()
    for collection_name, (title, body) in kit_catalog.BUILDING_LABELS.items():
        collection = bpy.data.collections.get(collection_name)
        if collection is None:
            fail(f"required building collection is missing: {collection_name}")
        keep.add(ensure_building_label(collection, title, body).name)
    for obj in list(labels.objects):
        if not is_authoring_label(obj):
            continue
        if obj.name in keep:
            continue
        bpy.data.objects.remove(obj, do_unlink=True)


def add_gn_object(
    name: str,
    collection: bpy.types.Collection,
    group: bpy.types.GeometryNodeTree,
    params: dict[str, object],
    location: tuple[float, float, float],
    asset_id: str,
    *,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    bevel: float = 0.0,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(f"{name}__Mesh")
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = rotation
    modifier = obj.modifiers.new(name="ALS_Geometry", type="NODES")
    modifier.node_group = group
    for socket_name, value in params.items():
        set_modifier_input(modifier, socket_name, value)
    if bevel > 0.0:
        bevel_mod = obj.modifiers.new(name="ALS_Bevel", type="BEVEL")
        bevel_mod.width = bevel
        bevel_mod.segments = 3
        bevel_mod.limit_method = "ANGLE"
        bevel_mod.harden_normals = True
    ensure_shade_modifier(obj)
    obj["asset_id"] = asset_id
    obj["state_layer"] = name.split("__", 1)[0].lower()
    obj["als_node_group"] = group.name
    return obj


def build_starter_campus(
    collections: dict[str, bpy.types.Collection],
    groups: dict[str, bpy.types.GeometryNodeTree],
    materials: dict[str, bpy.types.Material],
    asset_id: str,
) -> None:
    mass = groups["ALS_MassBlock"]
    windows = groups["ALS_WindowRhythm"]
    cooling = groups["ALS_CoolingStack"]
    fence = groups["ALS_FenceRun"]
    pylon = groups["ALS_StatusPylon"]
    arch = groups["ALS_ScanArch"]
    lab = collections[LAB_STAGE_COLLECTION]
    compute = collections["Export__Compute"]
    research = collections["Export__Research"]
    growth = collections["Export__Growth"]
    overload = collections["Export__Overload"]
    scrutiny = collections["Export__Scrutiny"]

    add_gn_object("LabBuildingPlatform", lab, mass, {"Size": (8.4, 7.0, 1.1), "Inset": 0.0, "Material": materials["concrete"]}, (-9.0, 0.0, 0.55), asset_id, bevel=0.2)
    add_gn_object("LabBuildingMain", lab, mass, {"Size": (6.4, 5.8, 4.8), "Inset": 0.0, "Material": materials["cream"]}, (-9.0, 0.3, 2.95), asset_id, bevel=0.28)
    add_gn_object("LabGlassStalk", lab, mass, {"Size": (2.25, 0.32, 4.75), "Inset": 0.0, "Material": materials["glass"]}, (-12.0, 0.5, 3.15), asset_id, bevel=0.08)
    add_gn_object("LabTop", lab, mass, {"Size": (4.8, 4.2, 1.2), "Inset": 0.0, "Material": materials["coral"]}, (-9.0, 0.2, 5.8), asset_id, bevel=0.2)
    add_gn_object("LabFan", lab, cooling, {"Radius": 0.47, "Height": 1.15, "CapScale": 1.0, "CapHeight": 0.08, "Material": materials["metal"]}, (-10.2, 0.55, 6.6), asset_id)
    add_gn_object("LabFan.001", lab, cooling, {"Radius": 0.47, "Height": 1.15, "CapScale": 1.0, "CapHeight": 0.08, "Material": materials["metal"]}, (-9.0, 0.55, 6.6), asset_id)
    add_gn_object("LabFan.002", lab, cooling, {"Radius": 0.47, "Height": 1.15, "CapScale": 1.0, "CapHeight": 0.08, "Material": materials["metal"]}, (-7.8, 0.55, 6.6), asset_id)

    add_gn_object("Base__Compute__Foundation", compute, mass, {"Size": (8.2, 6.6, 1.0), "Inset": 0.0, "Material": materials["concrete"]}, (0.0, 0.0, 0.5), asset_id, bevel=0.18)
    add_gn_object("Base__Compute__MainMass", compute, mass, {"Size": (7.4, 5.6, 5.0), "Inset": 0.0, "Material": materials["metal"]}, (0.0, 0.35, 3.0), asset_id, bevel=0.3)
    add_gn_object("Base__Compute__ServiceSpine", compute, mass, {"Size": (5.7, 0.55, 4.2), "Inset": 0.0, "Material": materials["coral"]}, (0.0, 2.65, 3.4), asset_id, bevel=0.12)
    add_gn_object("Base__Compute__FrontRibbon", compute, mass, {"Size": (6.4, 0.22, 1.3), "Inset": 0.0, "Material": materials["glass"]}, (0.0, -2.52, 3.15), asset_id, bevel=0.06)
    add_gn_object("Base__Compute__FacadeRibs", compute, windows, {"Count": 7, "Spacing": 1.02, "Width": 0.18, "Depth": 0.25, "Height": 2.2, "Material": materials["concrete"]}, (0.0, -2.72, 3.15), asset_id)
    add_gn_object("Base__Compute__Cooling_00", compute, cooling, {"Radius": 0.72, "Height": 1.55, "CapScale": 1.22, "CapHeight": 0.2, "Material": materials["concrete"]}, (-2.35, 0.65, 6.05), asset_id)
    add_gn_object("Base__Compute__Cooling_01", compute, cooling, {"Radius": 0.72, "Height": 1.55, "CapScale": 1.22, "CapHeight": 0.2, "Material": materials["concrete"]}, (0.0, 0.65, 6.05), asset_id)
    add_gn_object("Base__Compute__Cooling_02", compute, cooling, {"Radius": 0.72, "Height": 1.55, "CapScale": 1.22, "CapHeight": 0.2, "Material": materials["concrete"]}, (2.35, 0.65, 6.05), asset_id)
    add_gn_object("Base__Compute__StatusRail", compute, mass, {"Size": (5.4, 0.14, 0.18), "Inset": 0.0, "Material": materials["growth_light"]}, (0.0, -2.82, 4.9), asset_id, bevel=0.03)

    add_gn_object("Base__Research__Foundation", research, mass, {"Size": (8.4, 6.8, 1.0), "Inset": 0.0, "Material": materials["concrete"]}, (9.0, 0.0, 0.5), asset_id, bevel=0.18)
    add_gn_object("Base__Research__LowerTerrace", research, mass, {"Size": (7.2, 5.9, 2.6), "Inset": 0.0, "Material": materials["cream"]}, (8.5, 0.25, 1.8), asset_id, bevel=0.3)
    add_gn_object("Base__Research__MiddleTerrace", research, mass, {"Size": (5.6, 5.0, 2.3), "Inset": 0.0, "Material": materials["cream"]}, (9.2, 0.55, 3.45), asset_id, bevel=0.28)
    add_gn_object("Base__Research__UpperStudio", research, mass, {"Size": (4.0, 4.0, 2.0), "Inset": 0.0, "Material": materials["coral"]}, (9.9, 0.9, 5.1), asset_id, bevel=0.3)
    add_gn_object("Base__Research__LowerGlass", research, mass, {"Size": (5.9, 0.2, 1.25), "Inset": 0.0, "Material": materials["glass"]}, (8.5, -2.76, 1.95), asset_id, bevel=0.04)
    add_gn_object("Base__Research__Mullions", research, windows, {"Count": 6, "Spacing": 0.95, "Width": 0.12, "Depth": 0.12, "Height": 1.4, "Material": materials["metal"]}, (8.525, -2.89, 1.95), asset_id)
    add_gn_object("Base__Research__TerracePlanter", research, mass, {"Size": (1.2, 1.5, 0.42), "Inset": 0.0, "Material": materials["vegetation"]}, (11.7, -1.8, 4.05), asset_id, bevel=0.1)

    add_gn_object("Growth__Compute__NewCapacityPod", growth, mass, {"Size": (2.1, 2.5, 2.0), "Inset": 0.0, "Material": materials["metal"]}, (3.75, 1.25, 1.5), asset_id, bevel=0.25)
    add_gn_object("Growth__Research__OpenStudio", growth, mass, {"Size": (1.8, 2.5, 2.6), "Inset": 0.0, "Material": materials["cream"]}, (12.7, 1.45, 2.0), asset_id, bevel=0.28)
    for index, x_pos in enumerate((-9.0, 0.0, 9.0)):
        add_gn_object(f"Growth__Campus__StatusPylon_{index:02d}", growth, pylon, {"Width": 0.28, "Height": 1.9, "Material": materials["growth_light"]}, (x_pos, -3.85, 1.15), asset_id, bevel=0.06)

    for index, x_pos in enumerate((-11.5, -9.0, -6.5)):
        add_gn_object(f"Overload__LabCore__HotVent_{index:02d}", overload, cooling, {"Radius": 0.28, "Height": 1.65, "CapScale": 1.0, "CapHeight": 0.08, "Material": materials["overload_light"]}, (x_pos, 2.4, 5.65), asset_id)
    for index, x_pos in enumerate((-2.8, 0.0, 2.8)):
        add_gn_object(f"Overload__Compute__EmergencyCooler_{index:02d}", overload, cooling, {"Radius": 0.35, "Height": 1.5, "CapScale": 1.0, "CapHeight": 0.08, "Material": materials["overload_light"]}, (x_pos, -1.2, 6.1), asset_id)
    add_gn_object("Overload__Compute__HotPipe", overload, cooling, {"Radius": 0.2, "Height": 6.2, "CapScale": 1.0, "CapHeight": 0.05, "Material": materials["overload_light"]}, (0.0, -3.05, 2.1), asset_id, rotation=(0.0, math.pi / 2.0, 0.0))
    add_gn_object("Overload__Research__ServicePipe", overload, cooling, {"Radius": 0.24, "Height": 4.2, "CapScale": 1.0, "CapHeight": 0.05, "Material": materials["overload_light"]}, (12.25, 0.4, 2.8), asset_id)
    for index, x_pos in enumerate((-12.5, -4.2, 4.2, 12.5)):
        add_gn_object(f"Overload__Campus__WarningBeacon_{index:02d}", overload, pylon, {"Width": 0.42, "Height": 1.45, "Material": materials["warning_light"]}, (x_pos, -3.75, 0.95), asset_id, bevel=0.08)

    add_gn_object("Scrutiny__Campus__Fence", scrutiny, fence, {"Length": 28.2, "Spacing": 2.0, "Height": 1.65, "PostSize": 0.16, "Material": materials["metal"]}, (0.0, -4.15, 0.0), asset_id)
    add_gn_object("Scrutiny__Campus__Checkpoint", scrutiny, mass, {"Size": (2.7, 1.4, 2.0), "Inset": 0.0, "Material": materials["concrete"]}, (0.0, -4.0, 1.2), asset_id, bevel=0.25)
    add_gn_object("Scrutiny__Campus__CheckpointGlass", scrutiny, mass, {"Size": (1.55, 0.12, 0.9), "Inset": 0.0, "Material": materials["glass"]}, (0.0, -4.74, 1.3), asset_id, bevel=0.03)
    for index, x_pos in enumerate((-9.0, 0.0, 9.0)):
        add_gn_object(f"Scrutiny__Campus__ScanArch_{index:02d}", scrutiny, arch, {"Width": 2.0, "Height": 2.6, "PostSize": 0.22, "Material": materials["scrutiny_light"]}, (x_pos, -3.55, 1.55), asset_id)


REQUIRED_PALETTE_MATERIAL_NAMES = {
    "Architecture_Cream",
    "Architecture_Coral",
    "Concrete_Shadow",
    "Metal_Dark",
    "Glass_Teal",
    "Vegetation",
    "Status_Growth",
    "Status_Overload",
    "Status_Warning",
    "Status_Scrutiny",
}
MATERIAL_ALIASES = {
    "Concrete": "Concrete_Shadow",
    "Grass": "Vegetation",
    "Metal_Light": "Metal_Dark",
}


def normalize_materials_to_palette() -> int:
    remapped = 0
    for source_name, target_name in MATERIAL_ALIASES.items():
        source = bpy.data.materials.get(source_name)
        target = bpy.data.materials.get(target_name)
        if source is None:
            continue
        if target is None:
            fail(f"palette material is missing for alias {source_name} -> {target_name}")
        source.user_remap(target)
        bpy.data.materials.remove(source)
        remapped += 1
    orphan_names = sorted(
        material.name
        for material in bpy.data.materials
        if material.users == 0 and material.name not in REQUIRED_PALETTE_MATERIAL_NAMES
    )
    for name in orphan_names:
        material = bpy.data.materials.get(name)
        if material is not None:
            bpy.data.materials.remove(material)
            remapped += 1
    return remapped


def count_painted_texture_images() -> int:
    texture_images: set[int] = set()
    for material in bpy.data.materials:
        if material.node_tree is None:
            continue
        for node in material.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image is not None:
                texture_images.add(node.image.as_pointer())
    return len(texture_images)


def mesh_objects() -> list[bpy.types.Object]:
    return [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]


def validate_scene(manifest: dict) -> None:
    objects = mesh_objects()
    if not objects:
        fail("authoring file contains no mesh objects")
    exports_by_collection = {entry["collection"]: entry for entry in manifest["exports"]}
    for collection_name, entry in exports_by_collection.items():
        collection = bpy.data.collections.get(collection_name)
        if collection is None:
            fail(f"required export collection is missing: {collection_name}")
        members = [obj for obj in collection.objects if obj.type == "MESH"]
        if not members:
            fail(f"export collection is empty: {collection_name}")
        stray = sorted(obj.name for obj in collection.objects if obj.type != "MESH" or is_authoring_label(obj))
        if stray:
            fail(f"{collection_name} must contain only campus meshes: {stray}")
        prefix = LAYER_PREFIX[entry["layer"]]
        if collection_name == LAB_STAGE_COLLECTION:
            invalid = sorted(
                obj.name
                for obj in members
                if obj.name.startswith(STATE_NAME_PREFIXES) or obj.name.startswith("Base__")
            )
            if invalid:
                fail(
                    f"{collection_name} stage meshes must use plain names, "
                    f"not layer prefixes: {invalid}"
                )
        else:
            invalid = sorted(obj.name for obj in members if not obj.name.startswith(prefix))
            if invalid:
                fail(f"{collection_name} objects must start with {prefix}: {invalid}")
        trees = sorted(obj.name for obj in members if is_authored_tree(obj))
        if trees:
            fail(f"campus source must not contain tree objects: {trees}")
        for obj in members:
            if not obj.modifiers:
                fail(f"{obj.name} has no modifiers")
            last = obj.modifiers[-1]
            if last.type != "NODES" or last.node_group is None or last.node_group.name != SHADE_GROUP:
                fail(f"{obj.name} must end with {SHADE_GROUP}")
    missing_groups = [name for name in node_groups.MODIFIER_GROUP_NAMES if bpy.data.node_groups.get(name) is None]
    if missing_groups:
        fail(f"authoring file is missing node groups: {missing_groups}")
    lab_stage = bpy.data.collections.get(LAB_STAGE_COLLECTION)
    if lab_stage is None or not any(obj.type == "MESH" for obj in lab_stage.objects):
        fail(f"base kit is missing required lab stage collection: {LAB_STAGE_COLLECTION}")
    for subject in ("Compute", "Research"):
        if not any(obj.name.startswith(f"Base__{subject}__") for obj in objects):
            fail(f"base kit is missing required subject: {subject}")
    if len(bpy.data.materials) > manifest["material_budget"]["max_materials"]:
        fail(f"material count {len(bpy.data.materials)} exceeds budget {manifest['material_budget']['max_materials']}")
    texture_count = count_painted_texture_images()
    if texture_count != manifest["material_budget"]["painted_textures"]:
        fail(f"painted texture count {texture_count} violates zero-texture contract")


def collection_objects(collection: bpy.types.Collection) -> list[bpy.types.Object]:
    return [
        obj
        for obj in collection.all_objects
        if obj.type == "MESH" and not is_authoring_label(obj)
    ]


def export_collection(collection: bpy.types.Collection, export_path: Path) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    selected = collection_objects(collection)
    if not selected:
        fail(f"cannot export empty collection: {collection.name}")
    for obj in selected:
        obj.hide_set(False)
        obj.hide_viewport = False
        obj.hide_render = False
        obj.select_set(True)
    bpy.context.view_layer.objects.active = selected[0]
    export_path.parent.mkdir(parents=True, exist_ok=True)
    result = bpy.ops.export_scene.gltf(
        filepath=str(export_path),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_extras=True,
        export_cameras=False,
        export_lights=False,
    )
    if result != {"FINISHED"}:
        fail(f"glTF export failed for {collection.name}: {result}")
    if not export_path.is_file() or export_path.stat().st_size < MIN_GLB_BYTES:
        fail(f"generated GLB is missing or implausibly small: {export_path}")


def write_catalog(repo_root: Path, manifest: dict) -> Path:
    catalog_path = repo_root / manifest["catalog_file"]
    catalog_path.parent.mkdir(parents=True, exist_ok=True)
    assets = []
    for entry in manifest["exports"]:
        glb_name = Path(entry["export_file"]).name
        assets.append(
            {
                "id": entry["id"],
                "collection": entry["collection"],
                "layer": entry["layer"],
                "file": f"res://assets/generated/{glb_name}",
            }
        )
    payload = {
        "schema_version": 1,
        "source_file": f"model-pipeline/{manifest['source_file']}",
        "asset_id": manifest["asset_id"],
        "assets": assets,
    }
    catalog_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return catalog_path


def export_all(repo_root: Path, manifest: dict) -> list[Path]:
    bpy.context.view_layer.update()
    written: list[Path] = []
    for entry in manifest["exports"]:
        collection = bpy.data.collections.get(entry["collection"])
        if collection is None:
            fail(f"required export collection is missing: {entry['collection']}")
        export_path = repo_root / entry["export_file"]
        export_collection(collection, export_path)
        written.append(export_path)
    return written


def bootstrap(repo_root: Path, pipeline_root: Path, manifest: dict, palette: dict) -> Path:
    source_path = pipeline_root / manifest["source_file"]
    if source_path.is_file():
        fail(f"authoring file already exists; export instead of bootstrap: {source_path}")
    clear_factory_data()
    materials = make_materials(palette)
    groups = node_groups.build_all_node_groups()
    collections = make_export_collections()
    build_starter_campus(collections, groups, materials, manifest["asset_id"])
    refresh_authoring_labels(manifest)
    scene = bpy.context.scene
    scene["asset_id"] = manifest["asset_id"]
    scene["manifest_schema_version"] = manifest["schema_version"]
    scene["state_layers"] = ",".join(manifest["state_layers"])
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    validate_scene(manifest)
    source_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(source_path))
    if not source_path.is_file() or source_path.stat().st_size < MIN_BLEND_BYTES:
        fail(f"authoring Blender file is missing or implausibly small: {source_path}")
    return source_path


def sync_tools(source_path: Path, manifest: dict) -> int:
    snapshots: list[tuple[str, str, str | None, dict[str, object]]] = []
    for obj in mesh_objects():
        for modifier in obj.modifiers:
            if modifier.type != "NODES":
                continue
            group_name, values = snapshot_modifier(modifier)
            snapshots.append((obj.name, modifier.name, group_name, values))
    node_groups.build_all_node_groups()
    removed = remove_authored_trees()
    for obj_name, modifier_name, group_name, values in snapshots:
        obj = bpy.data.objects.get(obj_name)
        if obj is None:
            continue
        modifier = obj.modifiers.get(modifier_name)
        if modifier is None or modifier.type != "NODES":
            continue
        if group_name is None:
            continue
        group = bpy.data.node_groups.get(group_name)
        if group is None:
            fail(f"{obj_name} modifier {modifier_name} references missing group {group_name}")
        modifier.node_group = group
        restore_modifier(obj_name, modifier, values)
    for obj in mesh_objects():
        harden_bevels(obj)
        ensure_shade_modifier(obj)
        piece_group = ""
        for modifier in obj.modifiers:
            if modifier.type != "NODES" or modifier.node_group is None:
                continue
            if modifier.node_group.name == SHADE_GROUP:
                continue
            piece_group = modifier.node_group.name
            break
        obj["als_node_group"] = piece_group
    normalize_materials_to_palette()
    refresh_authoring_labels(manifest)
    validate_scene(manifest)
    bpy.ops.wm.save_mainfile()
    if not source_path.is_file() or source_path.stat().st_size < MIN_BLEND_BYTES:
        fail(f"authoring Blender file is missing or implausibly small: {source_path}")
    return removed


def apply_authoring_defaults() -> None:
    scene = bpy.context.scene
    if not hasattr(scene, "als_material_primary"):
        return
    if scene.als_material_primary is None:
        scene.als_material_primary = bpy.data.materials.get("Architecture_Cream")
    if scene.als_material_secondary is None:
        scene.als_material_secondary = bpy.data.materials.get("Metal_Dark")


def open_authoring_file(source_path: Path) -> None:
    if not source_path.is_file():
        fail(f"authoring file is missing; run bootstrap first: {source_path}")
    bpy.ops.wm.open_mainfile(filepath=str(source_path))


def main() -> None:
    validate_blender_version()
    repo_root, mode = parse_cli()
    pipeline_root = repo_root / "model-pipeline"
    manifest = load_json(pipeline_root / "manifest" / "assets.json")
    palette = load_json(pipeline_root / "config" / "palette.json")
    validate_manifest(manifest)
    source_path = pipeline_root / manifest["source_file"]

    if mode == "bootstrap":
        source_path = bootstrap(repo_root, pipeline_root, manifest, palette)
        print(f"PIPELINE_BOOTSTRAP_SUCCESS blend={source_path}")
        return

    open_authoring_file(source_path)
    if mode == "sync-tools":
        removed = sync_tools(source_path, manifest)
        print(
            "PIPELINE_SYNC_TOOLS_SUCCESS "
            f"asset_id={manifest['asset_id']} meshes={len(mesh_objects())} "
            f"trees_removed={removed} blend={source_path}"
        )
        return

    removed = sync_tools(source_path, manifest)
    written = export_all(repo_root, manifest)
    catalog_path = write_catalog(repo_root, manifest)
    print(
        "PIPELINE_EXPORT_SUCCESS "
        f"asset_id={manifest['asset_id']} meshes={len(mesh_objects())} "
        f"materials={len(bpy.data.materials)} painted_textures={count_painted_texture_images()} "
        f"trees_removed={removed} blend={source_path} catalog={catalog_path} glbs={len(written)}"
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
