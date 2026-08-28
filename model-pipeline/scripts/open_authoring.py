"""Open the campus authoring file with the kit add-on registered and tools synced."""

from __future__ import annotations

import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import export_assets


def parse_repo_root() -> Path:
    if "--" not in sys.argv:
        export_assets.fail("expected Blender arguments after '--': --repo-root <path>")
    args = sys.argv[sys.argv.index("--") + 1 :]
    repo_root: Path | None = None
    index = 0
    while index < len(args):
        if args[index] == "--repo-root" and index + 1 < len(args):
            repo_root = Path(args[index + 1]).resolve()
            index += 2
            continue
        export_assets.fail(f"unexpected argument: {args[index]}")
    if repo_root is None:
        export_assets.fail("expected '--repo-root <path>'")
    if not (repo_root / "game" / "project.godot").is_file():
        export_assets.fail(f"repo root does not contain game/project.godot: {repo_root}")
    return repo_root


def register_addon(pipeline_root: Path) -> None:
    addons = str(pipeline_root / "addons")
    if addons not in sys.path:
        sys.path.insert(0, addons)
    import als_campus_kit

    if not hasattr(bpy.types, "ALS_PT_campus_kit"):
        als_campus_kit.register()


def main() -> None:
    export_assets.validate_blender_version()
    repo_root = parse_repo_root()
    pipeline_root = repo_root / "model-pipeline"
    manifest = export_assets.load_json(pipeline_root / "manifest" / "assets.json")
    export_assets.validate_manifest(manifest)
    source_path = pipeline_root / manifest["source_file"]
    current = Path(bpy.data.filepath).resolve() if bpy.data.filepath else None
    if current != source_path.resolve():
        export_assets.open_authoring_file(source_path)
    register_addon(pipeline_root)
    removed = export_assets.sync_tools(source_path, manifest)
    export_assets.apply_authoring_defaults()
    print(
        "PIPELINE_AUTHOR_READY "
        f"asset_id={manifest['asset_id']} meshes={len(export_assets.mesh_objects())} "
        f"trees_removed={removed} blend={source_path}"
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        sys.exit(1)
