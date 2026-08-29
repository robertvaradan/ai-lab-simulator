from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "compile-game-flow.py"
SPEC = importlib.util.spec_from_file_location("compile_game_flow", SCRIPT)
assert SPEC and SPEC.loader
compiler = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = compiler
SPEC.loader.exec_module(compiler)


def map_text(graph_id: str = "test-graph", subgraph: str = "-") -> str:
    subgraph_row = "| linked | Linked graph | SUBGRAPH | DERIVED | child-graph | YES | docs/spec.md | - | - | Open the linked graph. |\n" if subgraph != "-" else ""
    subgraph_edge = "| root | linked | links |\n" if subgraph != "-" else ""
    return f"""# Test graph

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | {graph_id} |
| Title | Test graph |
| Root Node | root |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| root | Root | BRANCH | DERIVED | - | NO | docs/spec.md | - | - | Root node. |
| complete-leaf | Complete leaf | LEAF | COMPLETE | - | YES | docs/spec.md | src/implementation.txt | tests/verification.txt | Complete behavior. |
| none-leaf | None leaf | LEAF | NONE | - | NO | docs/spec.md | - | - | Remaining behavior. |
{subgraph_row}
## Edges

| From | To | Label |
| --- | --- | --- |
| root | complete-leaf | contains |
| complete-leaf | none-leaf | continues |
{subgraph_edge}"""


def child_map() -> str:
    return """# Child graph

## Metadata

| Key | Value |
| --- | --- |
| Graph ID | child-graph |
| Title | Child graph |
| Root Node | child-root |

## Nodes

| ID | Label | Kind | Status | Subgraph | Marketing Slice | Specification References | Implementation Evidence | Verification Evidence | Description |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| child-root | Child root | BRANCH | DERIVED | - | YES | docs/spec.md | - | - | Child root. |
| partial-leaf | Partial leaf | LEAF | PARTIAL | - | YES | docs/spec.md | src/implementation.txt | - | Partial behavior. |

## Edges

| From | To | Label |
| --- | --- | --- |
| child-root | partial-leaf | contains |
"""


class CompilerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.maps = self.root / "docs" / "game-flow"
        self.maps.mkdir(parents=True)
        (self.root / "docs/spec.md").write_text("# Specification\n", encoding="utf-8")
        (self.root / "src").mkdir()
        (self.root / "src/implementation.txt").write_text("implementation\n", encoding="utf-8")
        (self.root / "tests").mkdir()
        (self.root / "tests/verification.txt").write_text("verification\n", encoding="utf-8")
        backlog = self.root / "docs/implementation/marketing-slice-backlog.md"
        backlog.parent.mkdir()
        backlog.write_text("\n".join(
            f"### MS1-{index:02d}: Task {index}\n\nStatus: `{'DONE' if index <= 7 else 'BLOCKED'}`\n"
            for index in range(1, 21)
        ), encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def write_map(self, text: str, name: str = "map.md") -> Path:
        path = self.maps / name
        path.write_text(text, encoding="utf-8")
        return path

    def test_valid_compile_is_self_contained_and_reports_backlog(self) -> None:
        self.write_map(map_text())
        output = self.root / "out/index.html"
        compiler.compile_maps(self.maps, output)
        rendered = output.read_text(encoding="utf-8")
        self.assertIn("Marketing backlog: 7 DONE / 20 total = 35%", rendered)
        self.assertIn("window.GAME_FLOW_DATA=", rendered)
        self.assertNotIn("<link ", rendered)
        self.assertNotIn("<script src=", rendered)

    def test_status_derivation_and_metrics_include_linked_subgraph(self) -> None:
        self.write_map(map_text(subgraph="child-graph"), "main.md")
        self.write_map(child_map(), "child.md")
        parsed = {}
        for path in sorted(self.maps.glob("*.md")):
            graph = compiler.parse_graph(path)
            parsed[graph.graph_id] = graph
        compiler.validate_paths(parsed, self.root)
        compiler.validate_and_derive(parsed)
        payload = compiler.graph_payload(parsed, {"done": 7, "total": 20, "percent": 35})
        main = payload["graphs"]["test-graph"]
        linked = next(node for node in main["nodes"] if node["id"] == "linked")
        self.assertEqual("PARTIAL", linked["status"])
        self.assertEqual("PARTIAL", main["status"])
        self.assertEqual({"implemented": 2, "complete": 1, "total": 3}, main["metrics"])

    def test_output_is_byte_identical(self) -> None:
        self.write_map(map_text())
        first = self.root / "first.html"
        second = self.root / "second.html"
        compiler.compile_maps(self.maps, first)
        compiler.compile_maps(self.maps, second)
        self.assertEqual(first.read_bytes(), second.read_bytes())

    def test_valid_cyclic_flow_compiles_with_bounded_viewer_layout(self) -> None:
        cyclic = map_text().replace(
            "| complete-leaf | none-leaf | continues |",
            "| complete-leaf | none-leaf | continues |\n| none-leaf | complete-leaf | returns to |",
        )
        self.write_map(cyclic)
        output = self.root / "cyclic.html"
        compiler.compile_maps(self.maps, output)
        rendered = output.read_text(encoding="utf-8")
        self.assertIn("if(level[e.to]===undefined)", rendered)
        self.assertNotIn("level[e.to]<next", rendered)
        self.assertIn("none-leaf", rendered)

    def test_viewer_has_status_body_colors_and_label_wrapping(self) -> None:
        self.write_map(map_text())
        output = self.root / "viewer.html"
        compiler.compile_maps(self.maps, output)
        rendered = output.read_text(encoding="utf-8")
        self.assertIn(".node.NONE rect{fill:var(--none-body)", rendered)
        self.assertIn(".node.PARTIAL rect{fill:var(--partial-body)", rendered)
        self.assertIn(".node.COMPLETE rect{fill:var(--complete-body)", rendered)
        self.assertIn("function wrapLabel(s,max=24)", rendered)
        self.assertIn('class=\"node-label\"', rendered)
        self.assertIn("remainder.slice(0,max-1)", rendered)

    def test_invalid_contracts_fail_clearly(self) -> None:
        cases = {
            "bad ID": ("test-graph", "bad root"),
            "leaf status": ("COMPLETE | - | YES", "DERIVED | - | YES"),
            "implementation evidence": ("src/implementation.txt | tests/verification.txt", "- | tests/verification.txt"),
            "unknown node": ("complete-leaf | none-leaf", "complete-leaf | missing-leaf"),
            "unknown subgraph": ("| root | Root | BRANCH", "| root | Root | SUBGRAPH"),
        }
        for name, (old, new) in cases.items():
            with self.subTest(name=name):
                for path in self.maps.glob("*.md"):
                    path.unlink()
                text = map_text().replace(old, new, 1)
                self.write_map(text)
                with self.assertRaises(compiler.CompileError):
                    compiler.compile_maps(self.maps, self.root / "invalid.html")

    def test_missing_local_evidence_path_fails(self) -> None:
        self.write_map(map_text().replace("src/implementation.txt", "src/missing.txt"))
        with self.assertRaisesRegex(compiler.CompileError, "missing local evidence path"):
            compiler.compile_maps(self.maps, self.root / "invalid.html")


if __name__ == "__main__":
    unittest.main()
