from __future__ import annotations

bl_info = {
    "name": "ALS Campus Kit",
    "author": "AI Lab Simulator",
    "version": (1, 0, 0),
    "blender": (5, 1, 0),
    "location": "View3D > Sidebar > ALS",
    "description": "Place Geometry Nodes campus pieces and sync node groups from the repository.",
    "category": "Object",
}

import sys
from pathlib import Path

import bpy
from bpy.props import BoolProperty, EnumProperty, PointerProperty, StringProperty


def fail(message: str) -> None:
    raise RuntimeError(f"ASSET_PIPELINE_ERROR: {message}")


def pipeline_root() -> Path:
    root = Path(__file__).resolve().parents[2]
    scripts = root / "scripts"
    if not (scripts / "node_groups.py").is_file():
        fail("ALS Campus Kit must load from model-pipeline/addons. Open the kit with scripts/open-campus-kit.")
    return root


def ensure_scripts_path() -> Path:
    scripts = pipeline_root() / "scripts"
    path = str(scripts)
    if path not in sys.path:
        sys.path.insert(0, path)
    return scripts


def load_pipeline():
    ensure_scripts_path()
    import export_assets
    import kit_catalog
    import node_groups

    return export_assets, kit_catalog, node_groups


def collection_for(layer: str, subject: str) -> str:
    _export_assets, kit_catalog, _node_groups = load_pipeline()
    mapping = kit_catalog.LAYER_COLLECTIONS[layer]
    if layer == "Base":
        return mapping[subject]
    return mapping


def next_object_name(prefix: str, subject: str, stem: str) -> str:
    base = f"{prefix}{subject}__{stem}"
    if bpy.data.objects.get(base) is None:
        return base
    index = 0
    while bpy.data.objects.get(f"{base}_{index:02d}") is not None:
        index += 1
    return f"{base}_{index:02d}"


def next_lab_stage_name(stem: str) -> str:
    base = stem if stem.startswith("Lab") else f"Lab{stem}"
    if bpy.data.objects.get(base) is None:
        return base
    index = 0
    while bpy.data.objects.get(f"{base}_{index:02d}") is not None:
        index += 1
    return f"{base}_{index:02d}"


def material_for_role(role: str, primary: bpy.types.Material | None, secondary: bpy.types.Material | None) -> bpy.types.Material:
    _export_assets, kit_catalog, _node_groups = load_pipeline()
    if role == "primary" and primary is not None:
        return primary
    if role == "secondary" and secondary is not None:
        return secondary
    name = kit_catalog.MATERIAL_ROLES[role]
    material = bpy.data.materials.get(name)
    if material is None:
        fail(f"authoring file is missing material {name}")
    return material


class ALS_OT_sync_node_groups(bpy.types.Operator):
    bl_idname = "als.sync_node_groups"
    bl_label = "Sync Node Groups"
    bl_description = "Rebuild ALS Geometry Nodes groups from the repository scripts without deleting campus objects"

    def execute(self, context):
        export_assets, _kit_catalog, node_groups = load_pipeline()
        snapshots = []
        for obj in export_assets.mesh_objects():
            for modifier in obj.modifiers:
                if modifier.type != "NODES":
                    continue
                group_name, values = export_assets.snapshot_modifier(modifier)
                snapshots.append((obj.name, modifier.name, group_name, values))
        node_groups.build_all_node_groups()
        removed = export_assets.remove_authored_trees()
        for obj_name, modifier_name, group_name, values in snapshots:
            obj = bpy.data.objects.get(obj_name)
            if obj is None:
                continue
            modifier = obj.modifiers.get(modifier_name)
            if modifier is None or modifier.type != "NODES" or group_name is None:
                continue
            group = bpy.data.node_groups.get(group_name)
            if group is None:
                self.report({"ERROR"}, f"{obj_name} references missing group {group_name}")
                return {"CANCELLED"}
            modifier.node_group = group
            export_assets.restore_modifier(obj_name, modifier, values)
        for obj in export_assets.mesh_objects():
            export_assets.harden_bevels(obj)
            export_assets.ensure_shade_modifier(obj)
        export_assets.refresh_authoring_labels({"exports": export_assets.EXPECTED_EXPORTS})
        self.report({"INFO"}, f"Synced node groups. Removed {removed} tree object(s).")
        return {"FINISHED"}


class ALS_OT_add_piece(bpy.types.Operator):
    bl_idname = "als.add_piece"
    bl_label = "Add Campus Piece"
    bl_description = "Add one Geometry Nodes campus piece at the 3D cursor"

    piece_id: StringProperty(name="Piece", default="mass_block")

    def execute(self, context):
        export_assets, kit_catalog, _node_groups = load_pipeline()
        piece = next((item for item in kit_catalog.PIECES if item["id"] == self.piece_id), None)
        if piece is None:
            self.report({"ERROR"}, f"Unknown piece {self.piece_id}")
            return {"CANCELLED"}
        group = bpy.data.node_groups.get(piece["group"])
        if group is None:
            self.report({"ERROR"}, f"{piece['group']} is missing. Run Sync Node Groups.")
            return {"CANCELLED"}
        scene = context.scene
        layer = scene.als_layer
        subject = scene.als_subject
        collection_name = collection_for(layer, subject)
        collection = bpy.data.collections.get(collection_name)
        if collection is None:
            self.report({"ERROR"}, f"Export collection is missing: {collection_name}")
            return {"CANCELLED"}
        params = dict(piece["defaults"])
        for socket_name, role in piece["material_sockets"].items():
            params[socket_name] = material_for_role(role, scene.als_material_primary, scene.als_material_secondary)
        if layer == "Base" and subject == "LabStage1":
            name = next_lab_stage_name(piece["stem"])
        else:
            name = next_object_name(f"{layer}__", subject, piece["stem"])
        location = tuple(scene.cursor.location)
        obj = export_assets.add_gn_object(
            name,
            collection,
            group,
            params,
            location,
            scene.get("asset_id", "campus_modular_kit"),
            bevel=float(piece["bevel"]),
        )
        export_assets.refresh_authoring_labels({"exports": export_assets.EXPECTED_EXPORTS})
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        context.view_layer.objects.active = obj
        self.report({"INFO"}, f"Added {obj.name}")
        return {"FINISHED"}


class ALS_PT_campus_kit(bpy.types.Panel):
    bl_label = "Campus Kit"
    bl_idname = "ALS_PT_campus_kit"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "ALS"

    def draw(self, context):
        layout = self.layout
        scene = context.scene
        layout.prop(scene, "als_layer")
        layout.prop(scene, "als_subject")
        layout.prop(scene, "als_material_primary")
        layout.prop(scene, "als_material_secondary")
        layout.prop(scene, "als_show_labels")
        layout.operator("als.sync_node_groups", text="Refresh tools from repo", icon="FILE_REFRESH")
        _export_assets, kit_catalog, _node_groups = load_pipeline()
        current_category = ""
        for piece in kit_catalog.PIECES:
            if piece["category"] != current_category:
                current_category = piece["category"]
                layout.separator()
                layout.label(text=current_category)
            operator = layout.operator("als.add_piece", text=piece["label"])
            operator.piece_id = piece["id"]
        layout.separator()
        layout.label(text="Do not place trees in campus collections.")
        layout.label(text="Place trees later with scatter.")


classes = (ALS_OT_sync_node_groups, ALS_OT_add_piece, ALS_PT_campus_kit)


def _update_label_visibility(scene: bpy.types.Scene, _context: bpy.types.Context) -> None:
    collection = bpy.data.collections.get("Authoring__Labels")
    if collection is not None:
        collection.hide_viewport = not scene.als_show_labels


def register():
    for cls in classes:
        bpy.utils.register_class(cls)
    bpy.types.Scene.als_layer = EnumProperty(
        name="Layer",
        items=(
            ("Base", "Base", "Persistent campus kit"),
            ("Growth", "Growth", "Growth dressing"),
            ("Overload", "Overload", "Overload dressing"),
            ("Scrutiny", "Scrutiny", "Scrutiny dressing"),
        ),
        default="Base",
    )
    bpy.types.Scene.als_subject = EnumProperty(
        name="Subject",
        items=(
            ("LabStage1", "Lab Stage 1", "Export__LabStage1 when Layer is Base"),
            ("Compute", "Compute", "Export__Compute when Layer is Base"),
            ("Research", "Research", "Export__Research when Layer is Base"),
        ),
        default="LabStage1",
    )
    bpy.types.Scene.als_material_primary = PointerProperty(name="Primary Material", type=bpy.types.Material)
    bpy.types.Scene.als_material_secondary = PointerProperty(name="Secondary Material", type=bpy.types.Material)
    bpy.types.Scene.als_show_labels = BoolProperty(
        name="Show Labels",
        default=True,
        update=_update_label_visibility,
    )


def unregister():
    del bpy.types.Scene.als_layer
    del bpy.types.Scene.als_subject
    del bpy.types.Scene.als_material_primary
    del bpy.types.Scene.als_material_secondary
    del bpy.types.Scene.als_show_labels
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
