"""Reusable Geometry Nodes groups for the campus authoring file."""

from __future__ import annotations

import math

import bpy


def fail(message: str) -> None:
    raise RuntimeError(f"ASSET_PIPELINE_ERROR: {message}")


MODIFIER_GROUP_NAMES = (
    "ALS_ShadeContract",
    "ALS_MassBlock",
    "ALS_WindowRhythm",
    "ALS_CurtainWall",
    "ALS_RibbonWindow",
    "ALS_CoolingStack",
    "ALS_HvacBank",
    "ALS_PipeRun",
    "ALS_Skylight",
    "ALS_Entrance",
    "ALS_AccentColumn",
    "ALS_SitePad",
    "ALS_BollardRun",
    "ALS_HedgeRun",
    "ALS_Planter",
    "ALS_PlazaMark",
    "ALS_FenceRun",
    "ALS_Tree",
    "ALS_StatusPylon",
    "ALS_ScanArch",
)

CYLINDER_SIDES = 32
PIPE_SIDES = 16


def _new_group(name: str) -> bpy.types.GeometryNodeTree:
    existing = bpy.data.node_groups.get(name)
    if existing is not None:
        existing.nodes.clear()
        for item in list(existing.interface.items_tree):
            existing.interface.remove(item)
        existing.is_modifier = True
        existing.use_fake_user = True
        return existing
    group = bpy.data.node_groups.new(name, "GeometryNodeTree")
    group.is_modifier = True
    group.use_fake_user = True
    return group


def _input(
    group: bpy.types.GeometryNodeTree,
    name: str,
    socket_type: str,
    default: object | None = None,
    min_value: float | None = None,
    max_value: float | None = None,
) -> bpy.types.NodeTreeInterfaceSocket:
    item = group.interface.new_socket(name=name, in_out="INPUT", socket_type=socket_type)
    if default is not None and hasattr(item, "default_value"):
        item.default_value = default
    if min_value is not None and hasattr(item, "min_value"):
        item.min_value = min_value
    if max_value is not None and hasattr(item, "max_value"):
        item.max_value = max_value
    return item


def _output_geometry(group: bpy.types.GeometryNodeTree) -> None:
    group.interface.new_socket(name="Geometry", in_out="OUTPUT", socket_type="NodeSocketGeometry")


def _io(group: bpy.types.GeometryNodeTree) -> tuple[bpy.types.Node, bpy.types.Node]:
    node_in = group.nodes.new("NodeGroupInput")
    node_out = group.nodes.new("NodeGroupOutput")
    node_in.location = (-1100, 0)
    node_out.location = (1400, 0)
    return node_in, node_out


def _math(group: bpy.types.GeometryNodeTree, operation: str) -> bpy.types.Node:
    node = group.nodes.new("ShaderNodeMath")
    node.operation = operation
    return node


def _int_math(group: bpy.types.GeometryNodeTree, operation: str) -> bpy.types.Node:
    node = group.nodes.new("FunctionNodeIntegerMath")
    node.operation = operation
    return node


def _combine(group: bpy.types.GeometryNodeTree) -> bpy.types.Node:
    return group.nodes.new("ShaderNodeCombineXYZ")


def _join(group: bpy.types.GeometryNodeTree) -> bpy.types.Node:
    return group.nodes.new("GeometryNodeJoinGeometry")


def _set_material(group: bpy.types.GeometryNodeTree) -> bpy.types.Node:
    return group.nodes.new("GeometryNodeSetMaterial")


def _transform(group: bpy.types.GeometryNodeTree) -> bpy.types.Node:
    return group.nodes.new("GeometryNodeTransform")


def _cube(group: bpy.types.GeometryNodeTree) -> bpy.types.Node:
    return group.nodes.new("GeometryNodeMeshCube")


def _cylinder(group: bpy.types.GeometryNodeTree, vertices: int) -> bpy.types.Node:
    node = group.nodes.new("GeometryNodeMeshCylinder")
    node.inputs["Vertices"].default_value = vertices
    return node


def _line(group: bpy.types.GeometryNodeTree) -> bpy.types.Node:
    node = group.nodes.new("GeometryNodeMeshLine")
    node.mode = "OFFSET"
    node.count_mode = "TOTAL"
    return node


def _instances(group: bpy.types.GeometryNodeTree) -> tuple[bpy.types.Node, bpy.types.Node]:
    inst = group.nodes.new("GeometryNodeInstanceOnPoints")
    realize = group.nodes.new("GeometryNodeRealizeInstances")
    group.links.new(inst.outputs["Instances"], realize.inputs["Geometry"])
    return inst, realize


def _euler_rotation(group: bpy.types.GeometryNodeTree, x: float, y: float, z: float) -> bpy.types.Node:
    combine = _combine(group)
    combine.inputs["X"].default_value = x
    combine.inputs["Y"].default_value = y
    combine.inputs["Z"].default_value = z
    convert = group.nodes.new("FunctionNodeEulerToRotation")
    group.links.new(combine.outputs["Vector"], convert.inputs["Euler"])
    return convert


def build_shade_contract() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_ShadeContract")
    _input(group, "Geometry", "NodeSocketGeometry")
    _input(group, "Angle", "NodeSocketFloat", 30.0, 1.0, 80.0)
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    face_smooth = nodes.new("GeometryNodeSetShadeSmooth")
    face_smooth.domain = "FACE"
    face_smooth.inputs["Shade Smooth"].default_value = True
    to_radians = _math(group, "RADIANS")
    edge_angle = nodes.new("GeometryNodeInputMeshEdgeAngle")
    compare = nodes.new("FunctionNodeCompare")
    compare.data_type = "FLOAT"
    compare.operation = "GREATER_THAN"
    edge_sharp = nodes.new("GeometryNodeSetShadeSmooth")
    edge_sharp.domain = "EDGE"
    edge_sharp.inputs["Shade Smooth"].default_value = False
    normals = nodes.new("GeometryNodeSetMeshNormal")
    normals.mode = "SHARPNESS"
    normals.inputs["Remove Custom"].default_value = True

    links.new(node_in.outputs["Geometry"], face_smooth.inputs["Mesh"])
    links.new(node_in.outputs["Angle"], to_radians.inputs[0])
    links.new(edge_angle.outputs["Unsigned Angle"], compare.inputs[0])
    links.new(to_radians.outputs["Value"], compare.inputs[1])
    links.new(face_smooth.outputs["Mesh"], edge_sharp.inputs["Mesh"])
    links.new(compare.outputs["Result"], edge_sharp.inputs["Selection"])
    links.new(edge_sharp.outputs["Mesh"], normals.inputs["Mesh"])
    links.new(normals.outputs["Mesh"], node_out.inputs["Geometry"])
    return group


def build_mass_block() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_MassBlock")
    _input(group, "Size", "NodeSocketVector", (2.0, 2.0, 2.0), 0.05, 64.0)
    _input(group, "Inset", "NodeSocketFloat", 0.0, 0.0, 8.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    separate = nodes.new("ShaderNodeSeparateXYZ")
    inset_span = _math(group, "MULTIPLY")
    inset_span.inputs[1].default_value = 2.0
    sub_x = _math(group, "MAXIMUM")
    shrink_x = _math(group, "SUBTRACT")
    shrink_y = _math(group, "SUBTRACT")
    max_y = _math(group, "MAXIMUM")
    combine = _combine(group)
    cube = _cube(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Size"], separate.inputs[0])
    links.new(node_in.outputs["Inset"], inset_span.inputs[0])
    links.new(separate.outputs["X"], shrink_x.inputs[0])
    links.new(inset_span.outputs["Value"], shrink_x.inputs[1])
    links.new(separate.outputs["Y"], shrink_y.inputs[0])
    links.new(inset_span.outputs["Value"], shrink_y.inputs[1])
    sub_x.inputs[1].default_value = 0.05
    max_y.inputs[1].default_value = 0.05
    links.new(shrink_x.outputs["Value"], sub_x.inputs[0])
    links.new(shrink_y.outputs["Value"], max_y.inputs[0])
    links.new(sub_x.outputs["Value"], combine.inputs["X"])
    links.new(max_y.outputs["Value"], combine.inputs["Y"])
    links.new(separate.outputs["Z"], combine.inputs["Z"])
    links.new(combine.outputs["Vector"], cube.inputs["Size"])
    links.new(cube.outputs["Mesh"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_window_rhythm() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_WindowRhythm")
    _input(group, "Count", "NodeSocketInt", 6, 1, 64)
    _input(group, "Spacing", "NodeSocketFloat", 1.0, 0.05, 32.0)
    _input(group, "Width", "NodeSocketFloat", 0.5, 0.02, 8.0)
    _input(group, "Depth", "NodeSocketFloat", 0.18, 0.02, 8.0)
    _input(group, "Height", "NodeSocketFloat", 1.6, 0.02, 16.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    count_minus = _int_math(group, "SUBTRACT")
    count_minus.inputs[1].default_value = 1
    span = _math(group, "MULTIPLY")
    half = _math(group, "MULTIPLY")
    half.inputs[1].default_value = -0.5
    start = _combine(group)
    offset = _combine(group)
    pane = _combine(group)
    line = _line(group)
    cube = _cube(group)
    inst, realize = _instances(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Count"], count_minus.inputs[0])
    links.new(count_minus.outputs["Value"], span.inputs[0])
    links.new(node_in.outputs["Spacing"], span.inputs[1])
    links.new(span.outputs["Value"], half.inputs[0])
    links.new(half.outputs["Value"], start.inputs["X"])
    links.new(node_in.outputs["Spacing"], offset.inputs["X"])
    links.new(node_in.outputs["Width"], pane.inputs["X"])
    links.new(node_in.outputs["Depth"], pane.inputs["Y"])
    links.new(node_in.outputs["Height"], pane.inputs["Z"])
    links.new(node_in.outputs["Count"], line.inputs["Count"])
    links.new(start.outputs["Vector"], line.inputs["Start Location"])
    links.new(offset.outputs["Vector"], line.inputs["Offset"])
    links.new(pane.outputs["Vector"], cube.inputs["Size"])
    links.new(line.outputs["Mesh"], inst.inputs["Points"])
    links.new(cube.outputs["Mesh"], inst.inputs["Instance"])
    links.new(realize.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_curtain_wall() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_CurtainWall")
    _input(group, "Width", "NodeSocketFloat", 4.0, 0.4, 32.0)
    _input(group, "Height", "NodeSocketFloat", 4.5, 0.4, 24.0)
    _input(group, "Depth", "NodeSocketFloat", 0.22, 0.04, 2.0)
    _input(group, "Columns", "NodeSocketInt", 3, 1, 16)
    _input(group, "Rows", "NodeSocketInt", 2, 1, 16)
    _input(group, "Frame", "NodeSocketFloat", 0.08, 0.02, 0.6)
    _input(group, "Brace", "NodeSocketBool", True)
    _input(group, "GlassMaterial", "NodeSocketMaterial")
    _input(group, "FrameMaterial", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    glass_size = _combine(group)
    glass = _cube(group)
    glass_mat = _set_material(group)
    half_w = _math(group, "MULTIPLY")
    half_w.inputs[1].default_value = 0.5
    half_h = _math(group, "MULTIPLY")
    half_h.inputs[1].default_value = 0.5
    neg_half_w = _math(group, "MULTIPLY")
    neg_half_w.inputs[1].default_value = -1.0
    neg_half_h = _math(group, "MULTIPLY")
    neg_half_h.inputs[1].default_value = -1.0
    cols_plus = _int_math(group, "ADD")
    cols_plus.inputs[1].default_value = 1
    rows_plus = _int_math(group, "ADD")
    rows_plus.inputs[1].default_value = 1
    spacing_x = _math(group, "DIVIDE")
    spacing_z = _math(group, "DIVIDE")
    start_x = _math(group, "ADD")
    start_z = _math(group, "ADD")
    start_v = _combine(group)
    start_h = _combine(group)
    offset_v = _combine(group)
    offset_h = _combine(group)
    mullion_v = _combine(group)
    mullion_h = _combine(group)
    v_cube = _cube(group)
    h_cube = _cube(group)
    v_line = _line(group)
    h_line = _line(group)
    v_inst, v_realize = _instances(group)
    h_inst, h_realize = _instances(group)
    frame_join = _join(group)
    frame_mat = _set_material(group)
    p1 = _combine(group)
    p2 = _combine(group)
    p3 = _combine(group)
    p4 = _combine(group)
    brace_a = nodes.new("GeometryNodeCurvePrimitiveLine")
    brace_a.mode = "POINTS"
    brace_b = nodes.new("GeometryNodeCurvePrimitiveLine")
    brace_b.mode = "POINTS"
    profile = nodes.new("GeometryNodeCurvePrimitiveCircle")
    profile.mode = "RADIUS"
    profile.inputs["Resolution"].default_value = 8
    half_frame = _math(group, "MULTIPLY")
    half_frame.inputs[1].default_value = 0.45
    mesh_a = nodes.new("GeometryNodeCurveToMesh")
    mesh_b = nodes.new("GeometryNodeCurveToMesh")
    braces = _join(group)
    brace_switch = nodes.new("GeometryNodeSwitch")
    brace_switch.input_type = "GEOMETRY"
    joined = _join(group)

    links.new(node_in.outputs["Width"], glass_size.inputs["X"])
    links.new(node_in.outputs["Depth"], glass_size.inputs["Y"])
    links.new(node_in.outputs["Height"], glass_size.inputs["Z"])
    links.new(glass_size.outputs["Vector"], glass.inputs["Size"])
    links.new(glass.outputs["Mesh"], glass_mat.inputs["Geometry"])
    links.new(node_in.outputs["GlassMaterial"], glass_mat.inputs["Material"])
    links.new(node_in.outputs["Width"], half_w.inputs[0])
    links.new(node_in.outputs["Height"], half_h.inputs[0])
    links.new(half_w.outputs["Value"], neg_half_w.inputs[0])
    links.new(half_h.outputs["Value"], neg_half_h.inputs[0])
    links.new(node_in.outputs["Columns"], cols_plus.inputs[0])
    links.new(node_in.outputs["Rows"], rows_plus.inputs[0])
    links.new(node_in.outputs["Width"], spacing_x.inputs[0])
    links.new(cols_plus.outputs["Value"], spacing_x.inputs[1])
    links.new(node_in.outputs["Height"], spacing_z.inputs[0])
    links.new(rows_plus.outputs["Value"], spacing_z.inputs[1])
    links.new(neg_half_w.outputs["Value"], start_x.inputs[0])
    links.new(spacing_x.outputs["Value"], start_x.inputs[1])
    links.new(neg_half_h.outputs["Value"], start_z.inputs[0])
    links.new(spacing_z.outputs["Value"], start_z.inputs[1])
    links.new(start_x.outputs["Value"], start_v.inputs["X"])
    links.new(start_z.outputs["Value"], start_h.inputs["Z"])
    links.new(spacing_x.outputs["Value"], offset_v.inputs["X"])
    links.new(spacing_z.outputs["Value"], offset_h.inputs["Z"])
    links.new(node_in.outputs["Frame"], mullion_v.inputs["X"])
    links.new(node_in.outputs["Depth"], mullion_v.inputs["Y"])
    links.new(node_in.outputs["Height"], mullion_v.inputs["Z"])
    links.new(node_in.outputs["Width"], mullion_h.inputs["X"])
    links.new(node_in.outputs["Depth"], mullion_h.inputs["Y"])
    links.new(node_in.outputs["Frame"], mullion_h.inputs["Z"])
    links.new(node_in.outputs["Columns"], v_line.inputs["Count"])
    links.new(start_v.outputs["Vector"], v_line.inputs["Start Location"])
    links.new(offset_v.outputs["Vector"], v_line.inputs["Offset"])
    links.new(node_in.outputs["Rows"], h_line.inputs["Count"])
    links.new(start_h.outputs["Vector"], h_line.inputs["Start Location"])
    links.new(offset_h.outputs["Vector"], h_line.inputs["Offset"])
    links.new(mullion_v.outputs["Vector"], v_cube.inputs["Size"])
    links.new(mullion_h.outputs["Vector"], h_cube.inputs["Size"])
    links.new(v_line.outputs["Mesh"], v_inst.inputs["Points"])
    links.new(v_cube.outputs["Mesh"], v_inst.inputs["Instance"])
    links.new(h_line.outputs["Mesh"], h_inst.inputs["Points"])
    links.new(h_cube.outputs["Mesh"], h_inst.inputs["Instance"])
    links.new(node_in.outputs["Frame"], half_frame.inputs[0])
    links.new(half_frame.outputs["Value"], profile.inputs["Radius"])
    links.new(neg_half_w.outputs["Value"], p1.inputs["X"])
    links.new(neg_half_h.outputs["Value"], p1.inputs["Z"])
    links.new(half_w.outputs["Value"], p2.inputs["X"])
    links.new(half_h.outputs["Value"], p2.inputs["Z"])
    links.new(neg_half_w.outputs["Value"], p3.inputs["X"])
    links.new(half_h.outputs["Value"], p3.inputs["Z"])
    links.new(half_w.outputs["Value"], p4.inputs["X"])
    links.new(neg_half_h.outputs["Value"], p4.inputs["Z"])
    links.new(p1.outputs["Vector"], brace_a.inputs["Start"])
    links.new(p2.outputs["Vector"], brace_a.inputs["End"])
    links.new(p3.outputs["Vector"], brace_b.inputs["Start"])
    links.new(p4.outputs["Vector"], brace_b.inputs["End"])
    links.new(brace_a.outputs["Curve"], mesh_a.inputs["Curve"])
    links.new(brace_b.outputs["Curve"], mesh_b.inputs["Curve"])
    links.new(profile.outputs["Curve"], mesh_a.inputs["Profile Curve"])
    links.new(profile.outputs["Curve"], mesh_b.inputs["Profile Curve"])
    links.new(mesh_a.outputs["Mesh"], braces.inputs["Geometry"])
    links.new(mesh_b.outputs["Mesh"], braces.inputs["Geometry"])
    links.new(node_in.outputs["Brace"], brace_switch.inputs["Switch"])
    links.new(braces.outputs["Geometry"], brace_switch.inputs["True"])
    links.new(v_realize.outputs["Geometry"], frame_join.inputs["Geometry"])
    links.new(h_realize.outputs["Geometry"], frame_join.inputs["Geometry"])
    links.new(brace_switch.outputs["Output"], frame_join.inputs["Geometry"])
    links.new(frame_join.outputs["Geometry"], frame_mat.inputs["Geometry"])
    links.new(node_in.outputs["FrameMaterial"], frame_mat.inputs["Material"])
    links.new(glass_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(frame_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_ribbon_window() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_RibbonWindow")
    _input(group, "Length", "NodeSocketFloat", 6.0, 0.4, 32.0)
    _input(group, "Height", "NodeSocketFloat", 1.1, 0.1, 8.0)
    _input(group, "Depth", "NodeSocketFloat", 0.16, 0.02, 2.0)
    _input(group, "Mullions", "NodeSocketInt", 7, 1, 32)
    _input(group, "MullionWidth", "NodeSocketFloat", 0.08, 0.02, 1.0)
    _input(group, "GlassMaterial", "NodeSocketMaterial")
    _input(group, "FrameMaterial", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    glass_size = _combine(group)
    glass = _cube(group)
    glass_mat = _set_material(group)
    plus = _int_math(group, "ADD")
    plus.inputs[1].default_value = 1
    spacing = _math(group, "DIVIDE")
    half = _math(group, "MULTIPLY")
    half.inputs[1].default_value = -0.5
    start_x = _math(group, "ADD")
    start = _combine(group)
    offset = _combine(group)
    bar = _combine(group)
    cube = _cube(group)
    line = _line(group)
    inst, realize = _instances(group)
    frame_mat = _set_material(group)
    joined = _join(group)

    links.new(node_in.outputs["Length"], glass_size.inputs["X"])
    links.new(node_in.outputs["Depth"], glass_size.inputs["Y"])
    links.new(node_in.outputs["Height"], glass_size.inputs["Z"])
    links.new(glass_size.outputs["Vector"], glass.inputs["Size"])
    links.new(glass.outputs["Mesh"], glass_mat.inputs["Geometry"])
    links.new(node_in.outputs["GlassMaterial"], glass_mat.inputs["Material"])
    links.new(node_in.outputs["Mullions"], plus.inputs[0])
    links.new(node_in.outputs["Length"], spacing.inputs[0])
    links.new(plus.outputs["Value"], spacing.inputs[1])
    links.new(node_in.outputs["Length"], half.inputs[0])
    links.new(half.outputs["Value"], start_x.inputs[0])
    links.new(spacing.outputs["Value"], start_x.inputs[1])
    links.new(start_x.outputs["Value"], start.inputs["X"])
    links.new(spacing.outputs["Value"], offset.inputs["X"])
    links.new(node_in.outputs["MullionWidth"], bar.inputs["X"])
    links.new(node_in.outputs["Depth"], bar.inputs["Y"])
    links.new(node_in.outputs["Height"], bar.inputs["Z"])
    links.new(node_in.outputs["Mullions"], line.inputs["Count"])
    links.new(start.outputs["Vector"], line.inputs["Start Location"])
    links.new(offset.outputs["Vector"], line.inputs["Offset"])
    links.new(bar.outputs["Vector"], cube.inputs["Size"])
    links.new(line.outputs["Mesh"], inst.inputs["Points"])
    links.new(cube.outputs["Mesh"], inst.inputs["Instance"])
    links.new(realize.outputs["Geometry"], frame_mat.inputs["Geometry"])
    links.new(node_in.outputs["FrameMaterial"], frame_mat.inputs["Material"])
    links.new(glass_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(frame_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_cooling_stack() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_CoolingStack")
    _input(group, "Radius", "NodeSocketFloat", 0.5, 0.05, 8.0)
    _input(group, "Height", "NodeSocketFloat", 1.4, 0.05, 16.0)
    _input(group, "CapScale", "NodeSocketFloat", 1.2, 1.0, 3.0)
    _input(group, "CapHeight", "NodeSocketFloat", 0.2, 0.02, 4.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    cap_radius = _math(group, "MULTIPLY")
    half_height = _math(group, "MULTIPLY")
    half_height.inputs[1].default_value = 0.5
    half_cap = _math(group, "MULTIPLY")
    half_cap.inputs[1].default_value = 0.5
    cap_z = _math(group, "ADD")
    cap_offset = _combine(group)
    body = _cylinder(group, CYLINDER_SIDES)
    cap = _cylinder(group, CYLINDER_SIDES)
    move_cap = _transform(group)
    joined = _join(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Radius"], body.inputs["Radius"])
    links.new(node_in.outputs["Height"], body.inputs["Depth"])
    links.new(node_in.outputs["Radius"], cap_radius.inputs[0])
    links.new(node_in.outputs["CapScale"], cap_radius.inputs[1])
    links.new(cap_radius.outputs["Value"], cap.inputs["Radius"])
    links.new(node_in.outputs["CapHeight"], cap.inputs["Depth"])
    links.new(node_in.outputs["Height"], half_height.inputs[0])
    links.new(node_in.outputs["CapHeight"], half_cap.inputs[0])
    links.new(half_height.outputs["Value"], cap_z.inputs[0])
    links.new(half_cap.outputs["Value"], cap_z.inputs[1])
    links.new(cap_z.outputs["Value"], cap_offset.inputs["Z"])
    links.new(cap.outputs["Mesh"], move_cap.inputs["Geometry"])
    links.new(cap_offset.outputs["Vector"], move_cap.inputs["Translation"])
    links.new(body.outputs["Mesh"], joined.inputs["Geometry"])
    links.new(move_cap.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_hvac_bank() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_HvacBank")
    _input(group, "Size", "NodeSocketVector", (2.4, 1.4, 0.85), 0.2, 16.0)
    _input(group, "FanCount", "NodeSocketInt", 3, 1, 8)
    _input(group, "FanRadius", "NodeSocketFloat", 0.28, 0.05, 2.0)
    _input(group, "HousingMaterial", "NodeSocketMaterial")
    _input(group, "FanMaterial", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    housing = _cube(group)
    housing_mat = _set_material(group)
    separate = nodes.new("ShaderNodeSeparateXYZ")
    plus = _int_math(group, "ADD")
    plus.inputs[1].default_value = 1
    spacing = _math(group, "DIVIDE")
    half_x = _math(group, "MULTIPLY")
    half_x.inputs[1].default_value = -0.5
    start_x = _math(group, "ADD")
    half_z = _math(group, "MULTIPLY")
    half_z.inputs[1].default_value = 0.5
    fan_lift = _math(group, "ADD")
    fan_lift.inputs[1].default_value = 0.04
    start = _combine(group)
    offset = _combine(group)
    fan_move = _combine(group)
    fan = _cylinder(group, CYLINDER_SIDES)
    fan.inputs["Depth"].default_value = 0.1
    move_fan = _transform(group)
    line = _line(group)
    inst, realize = _instances(group)
    fan_mat = _set_material(group)
    joined = _join(group)

    links.new(node_in.outputs["Size"], housing.inputs["Size"])
    links.new(housing.outputs["Mesh"], housing_mat.inputs["Geometry"])
    links.new(node_in.outputs["HousingMaterial"], housing_mat.inputs["Material"])
    links.new(node_in.outputs["Size"], separate.inputs[0])
    links.new(node_in.outputs["FanCount"], plus.inputs[0])
    links.new(separate.outputs["X"], spacing.inputs[0])
    links.new(plus.outputs["Value"], spacing.inputs[1])
    links.new(separate.outputs["X"], half_x.inputs[0])
    links.new(half_x.outputs["Value"], start_x.inputs[0])
    links.new(spacing.outputs["Value"], start_x.inputs[1])
    links.new(separate.outputs["Z"], half_z.inputs[0])
    links.new(half_z.outputs["Value"], fan_lift.inputs[0])
    links.new(start_x.outputs["Value"], start.inputs["X"])
    links.new(spacing.outputs["Value"], offset.inputs["X"])
    links.new(fan_lift.outputs["Value"], fan_move.inputs["Z"])
    links.new(node_in.outputs["FanRadius"], fan.inputs["Radius"])
    links.new(fan.outputs["Mesh"], move_fan.inputs["Geometry"])
    links.new(fan_move.outputs["Vector"], move_fan.inputs["Translation"])
    links.new(node_in.outputs["FanCount"], line.inputs["Count"])
    links.new(start.outputs["Vector"], line.inputs["Start Location"])
    links.new(offset.outputs["Vector"], line.inputs["Offset"])
    links.new(line.outputs["Mesh"], inst.inputs["Points"])
    links.new(move_fan.outputs["Geometry"], inst.inputs["Instance"])
    links.new(realize.outputs["Geometry"], fan_mat.inputs["Geometry"])
    links.new(node_in.outputs["FanMaterial"], fan_mat.inputs["Material"])
    links.new(housing_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(fan_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_pipe_run() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_PipeRun")
    _input(group, "Length", "NodeSocketFloat", 3.2, 0.4, 24.0)
    _input(group, "Radius", "NodeSocketFloat", 0.09, 0.02, 1.0)
    _input(group, "Count", "NodeSocketInt", 3, 1, 8)
    _input(group, "Spacing", "NodeSocketFloat", 0.22, 0.05, 2.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    count_minus = _int_math(group, "SUBTRACT")
    count_minus.inputs[1].default_value = 1
    span = _math(group, "MULTIPLY")
    half = _math(group, "MULTIPLY")
    half.inputs[1].default_value = -0.5
    start = _combine(group)
    offset = _combine(group)
    pipe = _cylinder(group, PIPE_SIDES)
    rotate = _transform(group)
    rotation = _euler_rotation(group, 0.0, math.pi / 2.0, 0.0)
    line = _line(group)
    inst, realize = _instances(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Count"], count_minus.inputs[0])
    links.new(count_minus.outputs["Value"], span.inputs[0])
    links.new(node_in.outputs["Spacing"], span.inputs[1])
    links.new(span.outputs["Value"], half.inputs[0])
    links.new(half.outputs["Value"], start.inputs["Y"])
    links.new(node_in.outputs["Spacing"], offset.inputs["Y"])
    links.new(node_in.outputs["Radius"], pipe.inputs["Radius"])
    links.new(node_in.outputs["Length"], pipe.inputs["Depth"])
    links.new(pipe.outputs["Mesh"], rotate.inputs["Geometry"])
    links.new(rotation.outputs["Rotation"], rotate.inputs["Rotation"])
    links.new(node_in.outputs["Count"], line.inputs["Count"])
    links.new(start.outputs["Vector"], line.inputs["Start Location"])
    links.new(offset.outputs["Vector"], line.inputs["Offset"])
    links.new(line.outputs["Mesh"], inst.inputs["Points"])
    links.new(rotate.outputs["Geometry"], inst.inputs["Instance"])
    links.new(realize.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_skylight() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_Skylight")
    _input(group, "Width", "NodeSocketFloat", 1.4, 0.3, 8.0)
    _input(group, "Depth", "NodeSocketFloat", 1.4, 0.3, 8.0)
    _input(group, "Height", "NodeSocketFloat", 0.18, 0.04, 1.5)
    _input(group, "Frame", "NodeSocketFloat", 0.08, 0.02, 0.4)
    _input(group, "GlassMaterial", "NodeSocketMaterial")
    _input(group, "FrameMaterial", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    frame_span = _math(group, "MULTIPLY")
    frame_span.inputs[1].default_value = 2.0
    inner_w = _math(group, "SUBTRACT")
    inner_d = _math(group, "SUBTRACT")
    glass_h = _math(group, "MULTIPLY")
    glass_h.inputs[1].default_value = 0.45
    frame_size = _combine(group)
    glass_size = _combine(group)
    frame = _cube(group)
    glass = _cube(group)
    frame_mat = _set_material(group)
    glass_mat = _set_material(group)
    joined = _join(group)

    links.new(node_in.outputs["Frame"], frame_span.inputs[0])
    links.new(node_in.outputs["Width"], inner_w.inputs[0])
    links.new(frame_span.outputs["Value"], inner_w.inputs[1])
    links.new(node_in.outputs["Depth"], inner_d.inputs[0])
    links.new(frame_span.outputs["Value"], inner_d.inputs[1])
    links.new(node_in.outputs["Height"], glass_h.inputs[0])
    links.new(node_in.outputs["Width"], frame_size.inputs["X"])
    links.new(node_in.outputs["Depth"], frame_size.inputs["Y"])
    links.new(node_in.outputs["Height"], frame_size.inputs["Z"])
    links.new(inner_w.outputs["Value"], glass_size.inputs["X"])
    links.new(inner_d.outputs["Value"], glass_size.inputs["Y"])
    links.new(glass_h.outputs["Value"], glass_size.inputs["Z"])
    links.new(frame_size.outputs["Vector"], frame.inputs["Size"])
    links.new(glass_size.outputs["Vector"], glass.inputs["Size"])
    links.new(frame.outputs["Mesh"], frame_mat.inputs["Geometry"])
    links.new(node_in.outputs["FrameMaterial"], frame_mat.inputs["Material"])
    links.new(glass.outputs["Mesh"], glass_mat.inputs["Geometry"])
    links.new(node_in.outputs["GlassMaterial"], glass_mat.inputs["Material"])
    links.new(frame_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(glass_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_entrance() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_Entrance")
    _input(group, "Width", "NodeSocketFloat", 2.4, 0.6, 12.0)
    _input(group, "StepCount", "NodeSocketInt", 3, 1, 12)
    _input(group, "StepDepth", "NodeSocketFloat", 0.32, 0.1, 1.5)
    _input(group, "StepHeight", "NodeSocketFloat", 0.16, 0.05, 0.5)
    _input(group, "AwningDepth", "NodeSocketFloat", 1.1, 0.2, 4.0)
    _input(group, "AwningThickness", "NodeSocketFloat", 0.12, 0.04, 0.6)
    _input(group, "StairMaterial", "NodeSocketMaterial")
    _input(group, "AwningMaterial", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    step_size = _combine(group)
    step = _cube(group)
    half_h = _math(group, "MULTIPLY")
    half_h.inputs[1].default_value = 0.5
    lift = _combine(group)
    move_step = _transform(group)
    start = _combine(group)
    offset = _combine(group)
    line = _line(group)
    inst, realize = _instances(group)
    stair_mat = _set_material(group)
    awning_size = _combine(group)
    awning = _cube(group)
    steps_h = _math(group, "MULTIPLY")
    awning_z = _math(group, "ADD")
    half_awn = _math(group, "MULTIPLY")
    half_awn.inputs[1].default_value = -0.5
    awning_off = _combine(group)
    move_awning = _transform(group)
    awning_mat = _set_material(group)
    joined = _join(group)

    links.new(node_in.outputs["Width"], step_size.inputs["X"])
    links.new(node_in.outputs["StepDepth"], step_size.inputs["Y"])
    links.new(node_in.outputs["StepHeight"], step_size.inputs["Z"])
    links.new(step_size.outputs["Vector"], step.inputs["Size"])
    links.new(node_in.outputs["StepHeight"], half_h.inputs[0])
    links.new(half_h.outputs["Value"], lift.inputs["Z"])
    links.new(step.outputs["Mesh"], move_step.inputs["Geometry"])
    links.new(lift.outputs["Vector"], move_step.inputs["Translation"])
    links.new(node_in.outputs["StepDepth"], offset.inputs["Y"])
    links.new(node_in.outputs["StepHeight"], offset.inputs["Z"])
    links.new(node_in.outputs["StepCount"], line.inputs["Count"])
    links.new(start.outputs["Vector"], line.inputs["Start Location"])
    links.new(offset.outputs["Vector"], line.inputs["Offset"])
    links.new(line.outputs["Mesh"], inst.inputs["Points"])
    links.new(move_step.outputs["Geometry"], inst.inputs["Instance"])
    links.new(realize.outputs["Geometry"], stair_mat.inputs["Geometry"])
    links.new(node_in.outputs["StairMaterial"], stair_mat.inputs["Material"])
    links.new(node_in.outputs["Width"], awning_size.inputs["X"])
    links.new(node_in.outputs["AwningDepth"], awning_size.inputs["Y"])
    links.new(node_in.outputs["AwningThickness"], awning_size.inputs["Z"])
    links.new(awning_size.outputs["Vector"], awning.inputs["Size"])
    links.new(node_in.outputs["StepCount"], steps_h.inputs[0])
    links.new(node_in.outputs["StepHeight"], steps_h.inputs[1])
    links.new(steps_h.outputs["Value"], awning_z.inputs[0])
    links.new(node_in.outputs["AwningThickness"], awning_z.inputs[1])
    links.new(node_in.outputs["AwningDepth"], half_awn.inputs[0])
    links.new(half_awn.outputs["Value"], awning_off.inputs["Y"])
    links.new(awning_z.outputs["Value"], awning_off.inputs["Z"])
    links.new(awning.outputs["Mesh"], move_awning.inputs["Geometry"])
    links.new(awning_off.outputs["Vector"], move_awning.inputs["Translation"])
    links.new(move_awning.outputs["Geometry"], awning_mat.inputs["Geometry"])
    links.new(node_in.outputs["AwningMaterial"], awning_mat.inputs["Material"])
    links.new(stair_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(awning_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_accent_column() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_AccentColumn")
    _input(group, "Radius", "NodeSocketFloat", 0.22, 0.05, 2.0)
    _input(group, "Height", "NodeSocketFloat", 4.8, 0.4, 16.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    body = _cylinder(group, CYLINDER_SIDES)
    half = _math(group, "MULTIPLY")
    half.inputs[1].default_value = 0.5
    lift = _combine(group)
    move = _transform(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Radius"], body.inputs["Radius"])
    links.new(node_in.outputs["Height"], body.inputs["Depth"])
    links.new(node_in.outputs["Height"], half.inputs[0])
    links.new(half.outputs["Value"], lift.inputs["Z"])
    links.new(body.outputs["Mesh"], move.inputs["Geometry"])
    links.new(lift.outputs["Vector"], move.inputs["Translation"])
    links.new(move.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_site_pad() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_SitePad")
    _input(group, "Size", "NodeSocketVector", (12.0, 10.0, 0.45), 0.4, 64.0)
    _input(group, "DivisionsX", "NodeSocketInt", 6, 2, 24)
    _input(group, "DivisionsY", "NodeSocketInt", 5, 2, 24)
    _input(group, "Groove", "NodeSocketFloat", 0.03, 0.005, 0.2)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    slab = _cube(group)
    separate = nodes.new("ShaderNodeSeparateXYZ")
    verts_x = _int_math(group, "ADD")
    verts_x.inputs[1].default_value = 1
    verts_y = _int_math(group, "ADD")
    verts_y.inputs[1].default_value = 1
    grid = nodes.new("GeometryNodeMeshGrid")
    to_curve = nodes.new("GeometryNodeMeshToCurve")
    profile = nodes.new("GeometryNodeCurvePrimitiveCircle")
    profile.mode = "RADIUS"
    profile.inputs["Resolution"].default_value = 6
    grooves = nodes.new("GeometryNodeCurveToMesh")
    half_z = _math(group, "MULTIPLY")
    half_z.inputs[1].default_value = 0.5
    groove_z = _math(group, "ADD")
    groove_z.inputs[1].default_value = 0.004
    groove_off = _combine(group)
    move_grooves = _transform(group)
    joined = _join(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Size"], slab.inputs["Size"])
    links.new(node_in.outputs["Size"], separate.inputs[0])
    links.new(separate.outputs["X"], grid.inputs["Size X"])
    links.new(separate.outputs["Y"], grid.inputs["Size Y"])
    links.new(node_in.outputs["DivisionsX"], verts_x.inputs[0])
    links.new(node_in.outputs["DivisionsY"], verts_y.inputs[0])
    links.new(verts_x.outputs["Value"], grid.inputs["Vertices X"])
    links.new(verts_y.outputs["Value"], grid.inputs["Vertices Y"])
    links.new(grid.outputs["Mesh"], to_curve.inputs["Mesh"])
    links.new(node_in.outputs["Groove"], profile.inputs["Radius"])
    links.new(to_curve.outputs["Curve"], grooves.inputs["Curve"])
    links.new(profile.outputs["Curve"], grooves.inputs["Profile Curve"])
    links.new(separate.outputs["Z"], half_z.inputs[0])
    links.new(half_z.outputs["Value"], groove_z.inputs[0])
    links.new(groove_z.outputs["Value"], groove_off.inputs["Z"])
    links.new(grooves.outputs["Mesh"], move_grooves.inputs["Geometry"])
    links.new(groove_off.outputs["Vector"], move_grooves.inputs["Translation"])
    links.new(slab.outputs["Mesh"], joined.inputs["Geometry"])
    links.new(move_grooves.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_bollard_run() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_BollardRun")
    _input(group, "Count", "NodeSocketInt", 4, 1, 32)
    _input(group, "Spacing", "NodeSocketFloat", 1.4, 0.2, 8.0)
    _input(group, "Height", "NodeSocketFloat", 0.55, 0.1, 2.5)
    _input(group, "Radius", "NodeSocketFloat", 0.08, 0.02, 0.4)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    count_minus = _int_math(group, "SUBTRACT")
    count_minus.inputs[1].default_value = 1
    span = _math(group, "MULTIPLY")
    half = _math(group, "MULTIPLY")
    half.inputs[1].default_value = -0.5
    start = _combine(group)
    offset = _combine(group)
    body = _cylinder(group, PIPE_SIDES)
    half_h = _math(group, "MULTIPLY")
    half_h.inputs[1].default_value = 0.5
    lift = _combine(group)
    move = _transform(group)
    line = _line(group)
    inst, realize = _instances(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Count"], count_minus.inputs[0])
    links.new(count_minus.outputs["Value"], span.inputs[0])
    links.new(node_in.outputs["Spacing"], span.inputs[1])
    links.new(span.outputs["Value"], half.inputs[0])
    links.new(half.outputs["Value"], start.inputs["X"])
    links.new(node_in.outputs["Spacing"], offset.inputs["X"])
    links.new(node_in.outputs["Radius"], body.inputs["Radius"])
    links.new(node_in.outputs["Height"], body.inputs["Depth"])
    links.new(node_in.outputs["Height"], half_h.inputs[0])
    links.new(half_h.outputs["Value"], lift.inputs["Z"])
    links.new(body.outputs["Mesh"], move.inputs["Geometry"])
    links.new(lift.outputs["Vector"], move.inputs["Translation"])
    links.new(node_in.outputs["Count"], line.inputs["Count"])
    links.new(start.outputs["Vector"], line.inputs["Start Location"])
    links.new(offset.outputs["Vector"], line.inputs["Offset"])
    links.new(line.outputs["Mesh"], inst.inputs["Points"])
    links.new(move.outputs["Geometry"], inst.inputs["Instance"])
    links.new(realize.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_hedge_run() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_HedgeRun")
    _input(group, "Length", "NodeSocketFloat", 6.0, 0.4, 32.0)
    _input(group, "Width", "NodeSocketFloat", 0.45, 0.1, 4.0)
    _input(group, "Height", "NodeSocketFloat", 0.55, 0.1, 3.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    size = _combine(group)
    cube = _cube(group)
    half = _math(group, "MULTIPLY")
    half.inputs[1].default_value = 0.5
    lift = _combine(group)
    move = _transform(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Length"], size.inputs["X"])
    links.new(node_in.outputs["Width"], size.inputs["Y"])
    links.new(node_in.outputs["Height"], size.inputs["Z"])
    links.new(size.outputs["Vector"], cube.inputs["Size"])
    links.new(node_in.outputs["Height"], half.inputs[0])
    links.new(half.outputs["Value"], lift.inputs["Z"])
    links.new(cube.outputs["Mesh"], move.inputs["Geometry"])
    links.new(lift.outputs["Vector"], move.inputs["Translation"])
    links.new(move.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_planter() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_Planter")
    _input(group, "Size", "NodeSocketFloat", 1.1, 0.3, 6.0)
    _input(group, "Height", "NodeSocketFloat", 0.45, 0.1, 2.0)
    _input(group, "Wall", "NodeSocketFloat", 0.08, 0.02, 0.4)
    _input(group, "BoxMaterial", "NodeSocketMaterial")
    _input(group, "SoilMaterial", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    box_size = _combine(group)
    wall_span = _math(group, "MULTIPLY")
    wall_span.inputs[1].default_value = 2.0
    inner = _math(group, "SUBTRACT")
    soil_h = _math(group, "MULTIPLY")
    soil_h.inputs[1].default_value = 0.35
    soil_size = _combine(group)
    box = _cube(group)
    soil = _cube(group)
    half_h = _math(group, "MULTIPLY")
    half_h.inputs[1].default_value = 0.5
    box_lift = _combine(group)
    soil_z = _math(group, "ADD")
    soil_off = _combine(group)
    move_box = _transform(group)
    move_soil = _transform(group)
    box_mat = _set_material(group)
    soil_mat = _set_material(group)
    joined = _join(group)

    links.new(node_in.outputs["Size"], box_size.inputs["X"])
    links.new(node_in.outputs["Size"], box_size.inputs["Y"])
    links.new(node_in.outputs["Height"], box_size.inputs["Z"])
    links.new(node_in.outputs["Wall"], wall_span.inputs[0])
    links.new(node_in.outputs["Size"], inner.inputs[0])
    links.new(wall_span.outputs["Value"], inner.inputs[1])
    links.new(node_in.outputs["Height"], soil_h.inputs[0])
    links.new(inner.outputs["Value"], soil_size.inputs["X"])
    links.new(inner.outputs["Value"], soil_size.inputs["Y"])
    links.new(soil_h.outputs["Value"], soil_size.inputs["Z"])
    links.new(box_size.outputs["Vector"], box.inputs["Size"])
    links.new(soil_size.outputs["Vector"], soil.inputs["Size"])
    links.new(node_in.outputs["Height"], half_h.inputs[0])
    links.new(half_h.outputs["Value"], box_lift.inputs["Z"])
    links.new(soil_h.outputs["Value"], soil_z.inputs[0])
    links.new(half_h.outputs["Value"], soil_z.inputs[1])
    links.new(soil_z.outputs["Value"], soil_off.inputs["Z"])
    links.new(box.outputs["Mesh"], move_box.inputs["Geometry"])
    links.new(box_lift.outputs["Vector"], move_box.inputs["Translation"])
    links.new(soil.outputs["Mesh"], move_soil.inputs["Geometry"])
    links.new(soil_off.outputs["Vector"], move_soil.inputs["Translation"])
    links.new(move_box.outputs["Geometry"], box_mat.inputs["Geometry"])
    links.new(node_in.outputs["BoxMaterial"], box_mat.inputs["Material"])
    links.new(move_soil.outputs["Geometry"], soil_mat.inputs["Geometry"])
    links.new(node_in.outputs["SoilMaterial"], soil_mat.inputs["Material"])
    links.new(box_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(soil_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_plaza_mark() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_PlazaMark")
    _input(group, "Width", "NodeSocketFloat", 3.6, 0.6, 24.0)
    _input(group, "Depth", "NodeSocketFloat", 2.4, 0.6, 24.0)
    _input(group, "LineWidth", "NodeSocketFloat", 0.08, 0.02, 0.5)
    _input(group, "Height", "NodeSocketFloat", 0.04, 0.01, 0.3)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    half_w = _math(group, "MULTIPLY")
    half_w.inputs[1].default_value = 0.5
    half_d = _math(group, "MULTIPLY")
    half_d.inputs[1].default_value = 0.5
    neg_w = _math(group, "MULTIPLY")
    neg_w.inputs[1].default_value = -1.0
    neg_d = _math(group, "MULTIPLY")
    neg_d.inputs[1].default_value = -1.0
    ns_size = _combine(group)
    ew_size = _combine(group)
    north = _combine(group)
    south = _combine(group)
    east = _combine(group)
    west = _combine(group)
    ns = _cube(group)
    ew = _cube(group)
    move_n = _transform(group)
    move_s = _transform(group)
    move_e = _transform(group)
    move_w = _transform(group)
    joined = _join(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Width"], half_w.inputs[0])
    links.new(node_in.outputs["Depth"], half_d.inputs[0])
    links.new(half_w.outputs["Value"], neg_w.inputs[0])
    links.new(half_d.outputs["Value"], neg_d.inputs[0])
    links.new(node_in.outputs["Width"], ns_size.inputs["X"])
    links.new(node_in.outputs["LineWidth"], ns_size.inputs["Y"])
    links.new(node_in.outputs["Height"], ns_size.inputs["Z"])
    links.new(node_in.outputs["LineWidth"], ew_size.inputs["X"])
    links.new(node_in.outputs["Depth"], ew_size.inputs["Y"])
    links.new(node_in.outputs["Height"], ew_size.inputs["Z"])
    links.new(half_d.outputs["Value"], north.inputs["Y"])
    links.new(neg_d.outputs["Value"], south.inputs["Y"])
    links.new(half_w.outputs["Value"], east.inputs["X"])
    links.new(neg_w.outputs["Value"], west.inputs["X"])
    links.new(ns_size.outputs["Vector"], ns.inputs["Size"])
    links.new(ew_size.outputs["Vector"], ew.inputs["Size"])
    links.new(ns.outputs["Mesh"], move_n.inputs["Geometry"])
    links.new(ns.outputs["Mesh"], move_s.inputs["Geometry"])
    links.new(ew.outputs["Mesh"], move_e.inputs["Geometry"])
    links.new(ew.outputs["Mesh"], move_w.inputs["Geometry"])
    links.new(north.outputs["Vector"], move_n.inputs["Translation"])
    links.new(south.outputs["Vector"], move_s.inputs["Translation"])
    links.new(east.outputs["Vector"], move_e.inputs["Translation"])
    links.new(west.outputs["Vector"], move_w.inputs["Translation"])
    links.new(move_n.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(move_s.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(move_e.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(move_w.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_fence_run() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_FenceRun")
    _input(group, "Length", "NodeSocketFloat", 28.0, 1.0, 128.0)
    _input(group, "Spacing", "NodeSocketFloat", 2.0, 0.2, 16.0)
    _input(group, "Height", "NodeSocketFloat", 1.65, 0.2, 8.0)
    _input(group, "PostSize", "NodeSocketFloat", 0.16, 0.04, 2.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    div = _math(group, "DIVIDE")
    to_int = nodes.new("FunctionNodeFloatToInt")
    to_int.rounding_mode = "ROUND"
    count = _int_math(group, "ADD")
    count.inputs[1].default_value = 1
    half_len = _math(group, "MULTIPLY")
    half_len.inputs[1].default_value = -0.5
    start = _combine(group)
    offset = _combine(group)
    post_size = _combine(group)
    half_h = _math(group, "MULTIPLY")
    half_h.inputs[1].default_value = 0.5
    post_lift = _combine(group)
    rail_size = _combine(group)
    rail_low_z = _combine(group)
    rail_high_z = _combine(group)
    line = _line(group)
    post = _cube(group)
    lift_post = _transform(group)
    inst, realize = _instances(group)
    rail_low = _cube(group)
    rail_high = _cube(group)
    move_low = _transform(group)
    move_high = _transform(group)
    joined = _join(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Length"], div.inputs[0])
    links.new(node_in.outputs["Spacing"], div.inputs[1])
    links.new(div.outputs["Value"], to_int.inputs["Float"])
    links.new(to_int.outputs["Integer"], count.inputs[0])
    links.new(node_in.outputs["Length"], half_len.inputs[0])
    links.new(half_len.outputs["Value"], start.inputs["X"])
    links.new(node_in.outputs["Spacing"], offset.inputs["X"])
    links.new(node_in.outputs["PostSize"], post_size.inputs["X"])
    links.new(node_in.outputs["PostSize"], post_size.inputs["Y"])
    links.new(node_in.outputs["Height"], post_size.inputs["Z"])
    links.new(node_in.outputs["Height"], half_h.inputs[0])
    links.new(half_h.outputs["Value"], post_lift.inputs["Z"])
    links.new(count.outputs["Value"], line.inputs["Count"])
    links.new(start.outputs["Vector"], line.inputs["Start Location"])
    links.new(offset.outputs["Vector"], line.inputs["Offset"])
    links.new(post_size.outputs["Vector"], post.inputs["Size"])
    links.new(post.outputs["Mesh"], lift_post.inputs["Geometry"])
    links.new(post_lift.outputs["Vector"], lift_post.inputs["Translation"])
    links.new(line.outputs["Mesh"], inst.inputs["Points"])
    links.new(lift_post.outputs["Geometry"], inst.inputs["Instance"])
    links.new(node_in.outputs["Length"], rail_size.inputs["X"])
    links.new(node_in.outputs["PostSize"], rail_size.inputs["Y"])
    links.new(node_in.outputs["PostSize"], rail_size.inputs["Z"])
    rail_low_z.inputs["Z"].default_value = 0.55
    rail_high_z.inputs["Z"].default_value = 1.15
    links.new(rail_size.outputs["Vector"], rail_low.inputs["Size"])
    links.new(rail_size.outputs["Vector"], rail_high.inputs["Size"])
    links.new(rail_low.outputs["Mesh"], move_low.inputs["Geometry"])
    links.new(rail_high.outputs["Mesh"], move_high.inputs["Geometry"])
    links.new(rail_low_z.outputs["Vector"], move_low.inputs["Translation"])
    links.new(rail_high_z.outputs["Vector"], move_high.inputs["Translation"])
    links.new(realize.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(move_low.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(move_high.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_tree() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_Tree")
    _input(group, "TrunkRadius", "NodeSocketFloat", 0.12, 0.02, 2.0)
    _input(group, "TrunkHeight", "NodeSocketFloat", 1.1, 0.2, 8.0)
    _input(group, "CrownRadius", "NodeSocketFloat", 0.7, 0.1, 8.0)
    _input(group, "CrownHeight", "NodeSocketFloat", 1.45, 0.2, 8.0)
    _input(group, "TrunkMaterial", "NodeSocketMaterial")
    _input(group, "CrownMaterial", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    half_trunk = _math(group, "MULTIPLY")
    half_trunk.inputs[1].default_value = 0.5
    half_crown = _math(group, "MULTIPLY")
    half_crown.inputs[1].default_value = 0.5
    crown_z = _math(group, "ADD")
    trunk_offset = _combine(group)
    crown_offset = _combine(group)
    trunk = _cylinder(group, 24)
    crown = nodes.new("GeometryNodeMeshCone")
    crown.inputs["Vertices"].default_value = 24
    move_trunk = _transform(group)
    move_crown = _transform(group)
    trunk_mat = _set_material(group)
    crown_mat = _set_material(group)
    joined = _join(group)
    crown_top = _math(group, "MULTIPLY")
    crown_top.inputs[1].default_value = 0.3

    links.new(node_in.outputs["TrunkRadius"], trunk.inputs["Radius"])
    links.new(node_in.outputs["TrunkHeight"], trunk.inputs["Depth"])
    links.new(node_in.outputs["CrownRadius"], crown.inputs["Radius Bottom"])
    links.new(node_in.outputs["CrownRadius"], crown_top.inputs[0])
    links.new(crown_top.outputs["Value"], crown.inputs["Radius Top"])
    links.new(node_in.outputs["CrownHeight"], crown.inputs["Depth"])
    links.new(node_in.outputs["TrunkHeight"], half_trunk.inputs[0])
    links.new(half_trunk.outputs["Value"], trunk_offset.inputs["Z"])
    links.new(node_in.outputs["CrownHeight"], half_crown.inputs[0])
    links.new(node_in.outputs["TrunkHeight"], crown_z.inputs[0])
    links.new(half_crown.outputs["Value"], crown_z.inputs[1])
    links.new(crown_z.outputs["Value"], crown_offset.inputs["Z"])
    links.new(trunk.outputs["Mesh"], move_trunk.inputs["Geometry"])
    links.new(trunk_offset.outputs["Vector"], move_trunk.inputs["Translation"])
    links.new(crown.outputs["Mesh"], move_crown.inputs["Geometry"])
    links.new(crown_offset.outputs["Vector"], move_crown.inputs["Translation"])
    links.new(move_trunk.outputs["Geometry"], trunk_mat.inputs["Geometry"])
    links.new(node_in.outputs["TrunkMaterial"], trunk_mat.inputs["Material"])
    links.new(move_crown.outputs["Geometry"], crown_mat.inputs["Geometry"])
    links.new(node_in.outputs["CrownMaterial"], crown_mat.inputs["Material"])
    links.new(trunk_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(crown_mat.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_status_pylon() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_StatusPylon")
    _input(group, "Width", "NodeSocketFloat", 0.28, 0.04, 4.0)
    _input(group, "Height", "NodeSocketFloat", 1.9, 0.2, 8.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    size = _combine(group)
    cube = _cube(group)
    set_material = _set_material(group)
    links.new(node_in.outputs["Width"], size.inputs["X"])
    links.new(node_in.outputs["Width"], size.inputs["Y"])
    links.new(node_in.outputs["Height"], size.inputs["Z"])
    links.new(size.outputs["Vector"], cube.inputs["Size"])
    links.new(cube.outputs["Mesh"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_scan_arch() -> bpy.types.GeometryNodeTree:
    group = _new_group("ALS_ScanArch")
    _input(group, "Width", "NodeSocketFloat", 2.0, 0.4, 16.0)
    _input(group, "Height", "NodeSocketFloat", 2.6, 0.4, 16.0)
    _input(group, "PostSize", "NodeSocketFloat", 0.22, 0.04, 2.0)
    _input(group, "Material", "NodeSocketMaterial")
    _output_geometry(group)
    nodes = group.nodes
    links = group.links
    node_in, node_out = _io(group)

    half_w = _math(group, "MULTIPLY")
    half_w.inputs[1].default_value = 0.5
    neg_w = _math(group, "MULTIPLY")
    neg_w.inputs[1].default_value = -1.0
    post_size = _combine(group)
    header_size = _combine(group)
    left = _combine(group)
    right = _combine(group)
    header_z = _math(group, "MULTIPLY")
    header_z.inputs[1].default_value = 0.5
    header_off = _combine(group)
    post = _cube(group)
    header = _cube(group)
    move_left = _transform(group)
    move_right = _transform(group)
    move_header = _transform(group)
    joined = _join(group)
    set_material = _set_material(group)

    links.new(node_in.outputs["Width"], half_w.inputs[0])
    links.new(half_w.outputs["Value"], neg_w.inputs[0])
    links.new(node_in.outputs["PostSize"], post_size.inputs["X"])
    links.new(node_in.outputs["PostSize"], post_size.inputs["Y"])
    links.new(node_in.outputs["Height"], post_size.inputs["Z"])
    links.new(node_in.outputs["Width"], header_size.inputs["X"])
    links.new(node_in.outputs["PostSize"], header_size.inputs["Y"])
    links.new(node_in.outputs["PostSize"], header_size.inputs["Z"])
    links.new(neg_w.outputs["Value"], left.inputs["X"])
    links.new(half_w.outputs["Value"], right.inputs["X"])
    links.new(node_in.outputs["Height"], header_z.inputs[0])
    links.new(header_z.outputs["Value"], header_off.inputs["Z"])
    links.new(post_size.outputs["Vector"], post.inputs["Size"])
    links.new(header_size.outputs["Vector"], header.inputs["Size"])
    links.new(post.outputs["Mesh"], move_left.inputs["Geometry"])
    links.new(post.outputs["Mesh"], move_right.inputs["Geometry"])
    links.new(header.outputs["Mesh"], move_header.inputs["Geometry"])
    links.new(left.outputs["Vector"], move_left.inputs["Translation"])
    links.new(right.outputs["Vector"], move_right.inputs["Translation"])
    links.new(header_off.outputs["Vector"], move_header.inputs["Translation"])
    links.new(move_left.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(move_right.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(move_header.outputs["Geometry"], joined.inputs["Geometry"])
    links.new(joined.outputs["Geometry"], set_material.inputs["Geometry"])
    links.new(node_in.outputs["Material"], set_material.inputs["Material"])
    links.new(set_material.outputs["Geometry"], node_out.inputs["Geometry"])
    return group


def build_all_node_groups() -> dict[str, bpy.types.GeometryNodeTree]:
    groups = {
        "ALS_ShadeContract": build_shade_contract(),
        "ALS_MassBlock": build_mass_block(),
        "ALS_WindowRhythm": build_window_rhythm(),
        "ALS_CurtainWall": build_curtain_wall(),
        "ALS_RibbonWindow": build_ribbon_window(),
        "ALS_CoolingStack": build_cooling_stack(),
        "ALS_HvacBank": build_hvac_bank(),
        "ALS_PipeRun": build_pipe_run(),
        "ALS_Skylight": build_skylight(),
        "ALS_Entrance": build_entrance(),
        "ALS_AccentColumn": build_accent_column(),
        "ALS_SitePad": build_site_pad(),
        "ALS_BollardRun": build_bollard_run(),
        "ALS_HedgeRun": build_hedge_run(),
        "ALS_Planter": build_planter(),
        "ALS_PlazaMark": build_plaza_mark(),
        "ALS_FenceRun": build_fence_run(),
        "ALS_Tree": build_tree(),
        "ALS_StatusPylon": build_status_pylon(),
        "ALS_ScanArch": build_scan_arch(),
    }
    missing = [name for name in MODIFIER_GROUP_NAMES if name not in groups]
    if missing:
        fail(f"node group bootstrap did not create: {missing}")
    return groups
