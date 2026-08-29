#!/usr/bin/env python3
"""Compile strict Markdown game-flow maps into one self-contained HTML viewer."""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ID_PATTERN = re.compile(r"^[a-z][a-z0-9-]*$")
LEAF_STATUSES = {"NONE", "PARTIAL", "COMPLETE"}
NODE_COLUMNS = [
    "ID", "Label", "Kind", "Status", "Subgraph", "Marketing Slice",
    "Specification References", "Implementation Evidence",
    "Verification Evidence", "Description",
]
EDGE_COLUMNS = ["From", "To", "Label"]
METADATA_KEYS = {"Graph ID", "Title", "Root Node"}


class CompileError(Exception):
    """A source map violates the compiler contract."""


@dataclass
class Node:
    node_id: str
    label: str
    kind: str
    declared_status: str
    subgraph: str | None
    marketing_slice: bool
    references: list[str]
    implementation: list[str]
    verification: list[str]
    description: str
    status: str = ""


@dataclass
class Graph:
    graph_id: str
    title: str
    root: str
    nodes: dict[str, Node]
    edges: list[tuple[str, str, str]]
    source: Path


def split_row(line: str) -> list[str]:
    value = line.strip()
    if not value.startswith("|") or not value.endswith("|"):
        raise CompileError(f"Malformed table row: {line.rstrip()}")
    return [cell.strip() for cell in value[1:-1].split("|")]


def parse_table(lines: list[str], heading: str, source: Path) -> tuple[list[str], list[list[str]]]:
    marker = f"## {heading}"
    try:
        start = lines.index(marker) + 1
    except ValueError as exc:
        raise CompileError(f"{source}: missing '{marker}'") from exc
    while start < len(lines) and not lines[start].strip():
        start += 1
    if start + 1 >= len(lines):
        raise CompileError(f"{source}: '{heading}' table is incomplete")
    headers = split_row(lines[start])
    separator = split_row(lines[start + 1])
    if len(separator) != len(headers) or not all(re.fullmatch(r":?-{3,}:?", cell) for cell in separator):
        raise CompileError(f"{source}: '{heading}' has an invalid separator row")
    rows: list[list[str]] = []
    index = start + 2
    while index < len(lines) and lines[index].strip().startswith("|"):
        row = split_row(lines[index])
        if len(row) != len(headers):
            raise CompileError(f"{source}:{index + 1}: expected {len(headers)} cells, found {len(row)}")
        rows.append(row)
        index += 1
    if not rows:
        raise CompileError(f"{source}: '{heading}' must contain data")
    return headers, rows


def list_cell(value: str) -> list[str]:
    if value == "-":
        return []
    items = [item.strip() for item in value.split(";")]
    if any(not item for item in items):
        raise CompileError(f"Malformed semicolon-separated list '{value}'")
    return items


def parse_graph(source: Path) -> Graph:
    lines = source.read_text(encoding="utf-8").splitlines()
    headings = [lines.index(f"## {name}") if f"## {name}" in lines else -1 for name in ("Metadata", "Nodes", "Edges")]
    if -1 not in headings and headings != sorted(headings):
        raise CompileError(f"{source}: Metadata, Nodes, and Edges sections are out of order")
    metadata_headers, metadata_rows = parse_table(lines, "Metadata", source)
    if metadata_headers != ["Key", "Value"]:
        raise CompileError(f"{source}: Metadata columns must be 'Key | Value'")
    metadata: dict[str, str] = {}
    for key, value in metadata_rows:
        if key in metadata:
            raise CompileError(f"{source}: duplicate metadata key '{key}'")
        metadata[key] = value
    if set(metadata) != METADATA_KEYS:
        raise CompileError(f"{source}: metadata keys must be {sorted(METADATA_KEYS)}")
    graph_id = metadata["Graph ID"]
    if not ID_PATTERN.fullmatch(graph_id):
        raise CompileError(f"{source}: invalid graph ID '{graph_id}'")

    node_headers, node_rows = parse_table(lines, "Nodes", source)
    if node_headers != NODE_COLUMNS:
        raise CompileError(f"{source}: Nodes columns must be exactly {NODE_COLUMNS}")
    nodes: dict[str, Node] = {}
    for row in node_rows:
        values = dict(zip(NODE_COLUMNS, row))
        node_id = values["ID"]
        if not ID_PATTERN.fullmatch(node_id):
            raise CompileError(f"{source}: invalid node ID '{node_id}'")
        if node_id in nodes:
            raise CompileError(f"{source}: duplicate node ID '{node_id}'")
        kind = values["Kind"]
        status = values["Status"]
        if kind not in {"LEAF", "BRANCH", "SUBGRAPH"}:
            raise CompileError(f"{source}: node '{node_id}' has invalid kind '{kind}'")
        if kind == "LEAF" and status not in LEAF_STATUSES:
            raise CompileError(f"{source}: leaf '{node_id}' must use NONE, PARTIAL, or COMPLETE")
        if kind != "LEAF" and status != "DERIVED":
            raise CompileError(f"{source}: {kind.lower()} node '{node_id}' must use DERIVED")
        subgraph = None if values["Subgraph"] == "-" else values["Subgraph"]
        if (kind == "SUBGRAPH") != (subgraph is not None):
            raise CompileError(f"{source}: node '{node_id}' has an invalid Subgraph value")
        marketing = values["Marketing Slice"]
        if marketing not in {"YES", "NO"}:
            raise CompileError(f"{source}: node '{node_id}' must declare Marketing Slice as YES or NO")
        references = list_cell(values["Specification References"])
        implementation = list_cell(values["Implementation Evidence"])
        verification = list_cell(values["Verification Evidence"])
        if not references:
            raise CompileError(f"{source}: node '{node_id}' has no specification reference")
        if status in {"PARTIAL", "COMPLETE"} and not implementation:
            raise CompileError(f"{source}: {status} leaf '{node_id}' has no implementation evidence")
        if status == "COMPLETE" and not verification:
            raise CompileError(f"{source}: COMPLETE leaf '{node_id}' has no verification evidence")
        if status == "NONE" and (implementation or verification):
            raise CompileError(f"{source}: NONE leaf '{node_id}' must not declare evidence")
        if status == "PARTIAL" and verification:
            raise CompileError(f"{source}: PARTIAL leaf '{node_id}' must not declare verification evidence")
        if kind != "LEAF" and (implementation or verification):
            raise CompileError(f"{source}: derived node '{node_id}' must not declare evidence")
        if not values["Label"] or not values["Description"]:
            raise CompileError(f"{source}: node '{node_id}' must have a label and description")
        nodes[node_id] = Node(
            node_id, values["Label"], kind, status, subgraph,
            marketing == "YES", references, implementation, verification,
            values["Description"], status if kind == "LEAF" else "",
        )

    edge_headers, edge_rows = parse_table(lines, "Edges", source)
    if edge_headers != EDGE_COLUMNS:
        raise CompileError(f"{source}: Edges columns must be exactly {EDGE_COLUMNS}")
    edges: list[tuple[str, str, str]] = []
    seen_edges: set[tuple[str, str]] = set()
    for source_id, target_id, label in edge_rows:
        if source_id not in nodes or target_id not in nodes:
            raise CompileError(f"{source}: edge '{source_id}' -> '{target_id}' refers to an unknown node")
        if source_id == target_id or (source_id, target_id) in seen_edges:
            raise CompileError(f"{source}: invalid or duplicate edge '{source_id}' -> '{target_id}'")
        if not label:
            raise CompileError(f"{source}: edge '{source_id}' -> '{target_id}' has no label")
        seen_edges.add((source_id, target_id))
        edges.append((source_id, target_id, label))
    if metadata["Root Node"] not in nodes:
        raise CompileError(f"{source}: root node '{metadata['Root Node']}' does not exist")
    return Graph(graph_id, metadata["Title"], metadata["Root Node"], nodes, edges, source)


def validate_paths(graphs: dict[str, Graph], root: Path) -> None:
    for graph in graphs.values():
        for node in graph.nodes.values():
            for reference in node.references:
                path = reference.split("#", 1)[0]
                if not path or not (root / path).is_file():
                    raise CompileError(f"{graph.source}: node '{node.node_id}' has missing specification reference '{reference}'")
            for evidence in node.implementation + node.verification:
                if "#" in evidence:
                    raise CompileError(f"{graph.source}: evidence path must not contain an anchor: '{evidence}'")
                if not (root / evidence).is_file():
                    raise CompileError(f"{graph.source}: node '{node.node_id}' has missing local evidence path '{evidence}'")


def validate_and_derive(graphs: dict[str, Graph]) -> None:
    for graph in graphs.values():
        for node in graph.nodes.values():
            if node.subgraph and node.subgraph not in graphs:
                raise CompileError(f"{graph.source}: node '{node.node_id}' refers to unknown subgraph '{node.subgraph}'")

    dependency_state: dict[str, int] = {}

    def validate_dependencies(graph_id: str) -> None:
        if dependency_state.get(graph_id) == 1:
            raise CompileError(f"Subgraph cycle detected at graph '{graph_id}'")
        if dependency_state.get(graph_id) == 2:
            return
        dependency_state[graph_id] = 1
        for node in graphs[graph_id].nodes.values():
            if node.subgraph:
                validate_dependencies(node.subgraph)
        dependency_state[graph_id] = 2

    for graph_id in graphs:
        validate_dependencies(graph_id)

    def collect_leaves(graph_id: str, start_id: str) -> set[tuple[str, str]]:
        graph = graphs[graph_id]
        found: set[tuple[str, str]] = set()
        visited: set[str] = set()
        stack = [start_id]
        while stack:
            node_id = stack.pop()
            if node_id in visited:
                continue
            visited.add(node_id)
            node = graph.nodes[node_id]
            if node.kind == "LEAF":
                found.add((graph_id, node_id))
            elif node.kind == "SUBGRAPH":
                target = graphs[node.subgraph or ""]
                found.update(collect_leaves(target.graph_id, target.root))
            stack.extend(target for source, target, _ in graph.edges if source == node_id)
        return found

    for graph in graphs.values():
        reachable: set[str] = set()
        stack = [graph.root]
        while stack:
            node_id = stack.pop()
            if node_id in reachable:
                continue
            reachable.add(node_id)
            stack.extend(target for source, target, _ in graph.edges if source == node_id)
        orphaned = sorted(set(graph.nodes) - reachable)
        if orphaned:
            raise CompileError(f"{graph.source}: nodes are not reachable from root: {', '.join(orphaned)}")
        for node in graph.nodes.values():
            if node.kind == "LEAF":
                continue
            leaves = collect_leaves(graph.graph_id, node.node_id)
            if not leaves:
                raise CompileError(f"{graph.source}: derived node '{node.node_id}' has no leaf descendants")
            statuses = [graphs[gid].nodes[nid].status for gid, nid in leaves]
            if all(value == "NONE" for value in statuses):
                node.status = "NONE"
            elif all(value == "COMPLETE" for value in statuses):
                node.status = "COMPLETE"
            else:
                node.status = "PARTIAL"


def parse_backlog(root: Path) -> dict[str, int]:
    path = root / "docs/implementation/marketing-slice-backlog.md"
    if not path.is_file():
        raise CompileError(f"Missing Marketing Slice backlog '{path}'")
    text = path.read_text(encoding="utf-8")
    tasks = re.findall(r"^### (MS\d+-\d+):", text, re.MULTILINE)
    statuses = re.findall(r"^Status: `(OPEN|BLOCKED|ACTIVE|DONE)`$", text, re.MULTILINE)
    if not tasks or len(tasks) != len(statuses):
        raise CompileError(f"{path}: each MS task must have one valid Status")
    done = sum(status == "DONE" for status in statuses)
    return {"done": done, "total": len(tasks), "percent": round(done * 100 / len(tasks))}


def graph_payload(graphs: dict[str, Graph], backlog: dict[str, int]) -> dict[str, object]:
    payload_graphs: dict[str, object] = {}
    for graph_id in sorted(graphs):
        graph = graphs[graph_id]
        root_node = graph.nodes[graph.root]
        # Metrics count recursive leaf descendants. Derivation already stores aggregate counts only internally,
        # so collect unique leaf identities here to avoid double-counting convergent edges.
        leaves: set[tuple[str, str]] = set()

        visited: set[tuple[str, str]] = set()

        def collect(gid: str, nid: str) -> None:
            key = (gid, nid)
            if key in visited:
                return
            visited.add(key)
            node = graphs[gid].nodes[nid]
            if node.kind == "LEAF":
                leaves.add((gid, nid))
            elif node.kind == "SUBGRAPH":
                target = graphs[node.subgraph or ""]
                collect(target.graph_id, target.root)
            for source, target, _ in graphs[gid].edges:
                if source == nid:
                    collect(gid, target)

        collect(graph_id, graph.root)
        payload_graphs[graph_id] = {
            "id": graph_id,
            "title": graph.title,
            "root": graph.root,
            "status": root_node.status,
            "metrics": {
                "implemented": sum(graphs[gid].nodes[nid].status != "NONE" for gid, nid in leaves),
                "complete": sum(graphs[gid].nodes[nid].status == "COMPLETE" for gid, nid in leaves),
                "total": len(leaves),
            },
            "nodes": [
                {
                    "id": node.node_id, "label": node.label, "kind": node.kind,
                    "status": node.status, "subgraph": node.subgraph,
                    "marketing": node.marketing_slice, "references": node.references,
                    "implementation": node.implementation, "verification": node.verification,
                    "description": node.description,
                }
                for node in graph.nodes.values()
            ],
            "edges": [{"from": source, "to": target, "label": label} for source, target, label in graph.edges],
        }
    return {"schemaVersion": 1, "defaultGraph": "core-loop" if "core-loop" in graphs else sorted(graphs)[0], "backlog": backlog, "graphs": payload_graphs}


CSS = r"""
:root{color-scheme:dark;--bg:#0b0f14;--panel:#121821;--line:#354052;--text:#eef4ed;--muted:#9aa8b8;--none:#aeb7c2;--none-body:#3c4652;--partial:#64df8f;--partial-body:#174d2d;--complete:#b1f7c5;--complete-body:#21683d;--accent:#66d9ef;--marketing:#f0b95a}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:14px/1.45 system-ui,sans-serif}header{padding:18px 22px;border-bottom:1px solid #273140;background:#0f151d}.top{display:flex;gap:16px;align-items:center;flex-wrap:wrap}h1{font-size:20px;margin:0}.backlog{margin-left:auto;color:var(--marketing)}.toolbar{display:flex;gap:10px;align-items:center;margin-top:14px;flex-wrap:wrap}button,select{background:#1b2531;color:var(--text);border:1px solid #3b4a5d;border-radius:6px;padding:7px 10px}label{color:var(--muted)}main{display:grid;grid-template-columns:minmax(0,1fr) 330px;height:calc(100vh - 118px)}#canvasWrap{overflow:auto;position:relative}#canvasWrap.fit svg{width:100%!important;height:100%!important}svg{min-width:100%;min-height:100%}.edge{stroke:var(--line);stroke-width:2;fill:none;marker-end:url(#arrow)}.edge-label{fill:var(--muted);font-size:11px}.node{cursor:pointer}.node rect{stroke-width:2;rx:8}.node.NONE rect{fill:var(--none-body);stroke:var(--none)}.node.PARTIAL rect{fill:var(--partial-body);stroke:var(--partial)}.node.COMPLETE rect{fill:var(--complete-body);stroke:var(--complete)}.node.marketing rect{stroke-dasharray:6 3}.noMarketing .node.marketing rect{stroke-dasharray:none}.noMarketing .marketing-dot{display:none}.node.filtered{display:none}.node text{fill:var(--text);font-size:13px}.node .badge{font-size:10px;font-weight:700}.node.NONE .badge{fill:var(--none)}.node.PARTIAL .badge{fill:var(--partial)}.node.COMPLETE .badge{fill:var(--complete)}.marketing-dot{fill:var(--marketing)}aside{border-left:1px solid #273140;background:var(--panel);padding:18px;overflow:auto}aside h2{font-size:17px;margin-top:0}.muted{color:var(--muted)}.status{display:inline-block;border:1px solid currentColor;border-radius:999px;padding:2px 7px;font-size:11px}.path{font-family:ui-monospace,monospace;font-size:12px;overflow-wrap:anywhere}.path a{color:var(--accent)}ul{padding-left:18px}.metrics{color:var(--muted)}#crumbs button{border:0;background:none;padding:0;color:var(--accent)}@media(max-width:800px){main{grid-template-columns:1fr;height:auto}#canvasWrap{height:65vh}aside{border-left:0;border-top:1px solid #273140}}
"""

JS = r"""
const D=window.GAME_FLOW_DATA,G=D.graphs;let current=D.defaultGraph,history=[current];
const svg=document.querySelector('svg'),details=document.querySelector('aside'),select=document.querySelector('#graphSelect');
for(const id of Object.keys(G)){const o=document.createElement('option');o.value=id;o.textContent=G[id].title;select.append(o)}
function esc(s){return s.replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}
function list(title,items){return `<h3>${title}</h3>${items.length?`<ul>${items.map(x=>`<li class="path"><a href="../../${esc(x)}">${esc(x)}</a></li>`).join('')}</ul>`:'<p class="muted">None</p>'}`}
function levels(g){const level={[g.root]:0},q=[g.root];for(let i=0;i<q.length;i++){const n=q[i];for(const e of g.edges.filter(x=>x.from===n)){if(level[e.to]===undefined){level[e.to]=level[n]+1;q.push(e.to)}}}return level}
function wrapLabel(s,max=24){if(s.length<=max)return[s];let cut=s.lastIndexOf(' ',max);if(cut<1)cut=max;const first=s.slice(0,cut).trim(),remainder=s.slice(cut).trim();return[first,remainder.length>max?remainder.slice(0,max-1).trimEnd()+'…':remainder]}
function render(){const g=G[current],lv=levels(g),groups={};g.nodes.forEach(n=>(groups[lv[n.id]??0]??=[]).push(n));Object.values(groups).forEach(a=>a.sort((a,b)=>a.id.localeCompare(b.id)));const pos={};for(const [l,a] of Object.entries(groups)){a.forEach((n,i)=>pos[n.id]={x:50+Number(l)*260,y:55+i*120})}const w=Math.max(700,...Object.values(pos).map(p=>p.x+230)),h=Math.max(480,...Object.values(pos).map(p=>p.y+96));svg.setAttribute('viewBox',`0 0 ${w} ${h}`);svg.style.width=`${w}px`;svg.style.height=`${h}px`;const hidden=new Set(g.nodes.filter(n=>(document.querySelector('#remaining').checked&&n.kind==='LEAF'&&n.status==='COMPLETE')||(document.querySelector('#marketingFilter').checked&&!n.marketing)).map(n=>n.id));let out='<defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#354052"/></marker></defs>';for(const e of g.edges){if(hidden.has(e.from)||hidden.has(e.to))continue;const a=pos[e.from],b=pos[e.to],x1=a.x+210,y1=a.y+38,x2=b.x,y2=b.y+38,m=(x1+x2)/2;out+=`<path class="edge" d="M${x1} ${y1} C${m} ${y1},${m} ${y2},${x2} ${y2}"/><text class="edge-label" x="${m-28}" y="${(y1+y2)/2-6}">${esc(e.label)}</text>`}for(const n of g.nodes){const p=pos[n.id],lines=wrapLabel(n.label),label=lines.map((line,i)=>`<tspan x="12" y="${19+i*16}">${esc(line)}</tspan>`).join('');out+=`<g class="node ${n.status} ${n.marketing?'marketing':''} ${hidden.has(n.id)?'filtered':''}" data-id="${n.id}" role="button" tabindex="0" aria-label="${esc(n.label)}" transform="translate(${p.x} ${p.y})"><title>${esc(n.label)}</title><rect width="210" height="76"/><text class="node-label">${label}</text><text class="badge" x="12" y="61">${n.status}${n.kind==='SUBGRAPH'?' · OPEN':''}</text>${n.marketing?'<circle class="marketing-dot" cx="192" cy="18" r="5"/>':''}</g>`}svg.innerHTML=out;svg.querySelectorAll('.node').forEach(el=>{const activate=()=>show(g.nodes.find(n=>n.id===el.dataset.id));el.onclick=activate;el.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();activate()}}});select.value=current;document.querySelector('#metrics').textContent=`Implemented ${g.metrics.implemented}/${g.metrics.total} · Complete ${g.metrics.complete}/${g.metrics.total}`;document.querySelector('#crumbs').innerHTML=history.map((id,i)=>`<button data-i="${i}">${esc(G[id].title)}</button>`).join(' › ');document.querySelectorAll('#crumbs button').forEach(b=>b.onclick=()=>{history=history.slice(0,Number(b.dataset.i)+1);current=history.at(-1);render()});show(g.nodes.find(n=>n.id===g.root))}
function show(n){details.innerHTML=`<h2>${esc(n.label)}</h2><p><span class="status">${n.status}</span>${n.marketing?' <span class="status">MARKETING SLICE</span>':''}</p><p>${esc(n.description)}</p>${n.subgraph?`<p><button id="openSubgraph">Open subgraph</button></p>`:''}${list('Specification references',n.references)}${list('Implementation evidence',n.implementation)}${list('Verification evidence',n.verification)}`;if(n.subgraph)document.querySelector('#openSubgraph').onclick=()=>{current=n.subgraph;history.push(current);render()}}
select.onchange=()=>{current=select.value;history=[current];render()};document.querySelector('#remaining').onchange=render;document.querySelector('#marketingFilter').onchange=render;document.querySelector('#marketingHighlight').onchange=e=>document.body.classList.toggle('noMarketing',!e.target.checked);document.querySelector('#fit').onclick=()=>{document.querySelector('#canvasWrap').classList.add('fit');document.querySelector('#canvasWrap').scrollTo(0,0)};render();
"""


def render_html(payload: dict[str, object]) -> str:
    data = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).replace("</", "<\\/")
    backlog = payload["backlog"]
    assert isinstance(backlog, dict)
    return "<!doctype html>\n" + f"""<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Game Flow Progress</title><style>{CSS}</style></head><body><header><div class="top"><h1>Game Flow Progress</h1><span id="crumbs"></span><span class="backlog">Marketing backlog: {backlog['done']} DONE / {backlog['total']} total = {backlog['percent']}%</span></div><div class="toolbar"><select id="graphSelect" aria-label="Graph"></select><button id="fit">Fit to view</button><label><input id="remaining" type="checkbox"> Remaining work only</label><label><input id="marketingHighlight" type="checkbox" checked> Highlight Marketing Slice</label><label><input id="marketingFilter" type="checkbox"> Marketing Slice only</label><span class="metrics" id="metrics"></span></div></header><main><div id="canvasWrap"><svg role="img" aria-label="Game flow graph"></svg></div><aside><p class="muted">Select a node.</p></aside></main><script>window.GAME_FLOW_DATA={data};</script><script>{JS}</script></body></html>\n"""


def compile_maps(input_dir: Path, output_file: Path) -> None:
    if not input_dir.is_dir():
        raise CompileError(f"Input directory does not exist: {input_dir}")
    sources = sorted(input_dir.glob("*.md"))
    if not sources:
        raise CompileError(f"Input directory contains no Markdown maps: {input_dir}")
    graphs: dict[str, Graph] = {}
    for source in sources:
        graph = parse_graph(source)
        if graph.graph_id in graphs:
            raise CompileError(f"Duplicate graph ID '{graph.graph_id}'")
        graphs[graph.graph_id] = graph
    root = input_dir.resolve().parent.parent
    validate_paths(graphs, root)
    validate_and_derive(graphs)
    payload = graph_payload(graphs, parse_backlog(root))
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(render_html(payload), encoding="utf-8", newline="\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Directory that contains Markdown graph maps")
    parser.add_argument("--output", required=True, type=Path, help="Generated self-contained HTML file")
    args = parser.parse_args(argv)
    try:
        compile_maps(args.input, args.output)
    except (CompileError, OSError) as exc:
        print(f"game-flow compiler: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
