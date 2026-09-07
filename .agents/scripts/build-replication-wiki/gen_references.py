#!/usr/bin/env python3
"""Regenerate OKF evidence reference documents under .agents/dna/references/.
All content is derived from existing files and exact source line slices.
"""
import hashlib
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path("/Users/koren/Tresorit/Mac/projects/ceo-value")
DNA = ROOT / ".agents" / "dna"
REFS = DNA / "references"
NOW = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def sha256_of(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def ascii_strip(s): return "".join(ch for ch in s if ord(ch) < 128)

def read_lines(path, start, end):
    lines = path.read_text(keepends=True).splitlines(True)
    return "".join(lines[start-1:end])

def parse_frontmatter(path):
    title = desc = ""
    if path.exists():
        txt = path.read_text()
        m = re.search(r"^title:\s*(.+)$", txt, re.M)
        if m: title = ascii_strip(m.group(1)).strip()
        m = re.search(r"^description:\s*(.+)$", txt, re.M)
        if m: desc = ascii_strip(m.group(1)).strip()
    return title, desc

def parse_notes(path):
    if not path.exists(): return []
    txt = path.read_text()
    if "## Notes" not in txt: return []
    notes_txt = txt.split("## Notes", 1)[1]
    out = []
    for line in notes_txt.splitlines():
        line = ascii_strip(line).strip()
        if line.startswith("- "): out.append(line[2:])
    return out

def parse_ranges(path:
    heads = []
    if not path.exists(): return heads
    for line in path.read_text().splitlines():
        clean = ascii_strip(line)
        m = re.match(r"^### Lines\s+(\d+)\s*-\s*(\d+)(?::\s*(.*))?$", clean)
        if m:
            label = ascii_strip(m.group(3) or "").strip()
            heads.append((int(m.group(1)), int(m.group(2), label))
    return heads

SPEC = {
    "code/analysis_sample_do.md": "lib/create/analysis-sample.do",
    "code/balance_do.md": "lib/create/balance.do",
    "code/bloom_autonomy_do.md": "lib/estimate/bloom_autonomy_analysis.do",
    "code/ceo_panel_do.md": "lib/create/ceo-panel.do",
    "code/connected_component_jl.md": "lib/create/connected_component.jl",
    "code/edgelist_do.md": "lib/create/edgelist.do",
    "code/event_study_atet_do.md": "lib/estimate/event_study_atet.do",
    "code/event_study_do.md": "lib/estimate/event_study.do",
    "code/event_study_sample_do.md": "lib/create/event_study_sample.do",
    "code/extract_do.md": "lib/create/extract.do",
    "code/filter_do.md": "lib/util/filter.do",
    "code/industry_do.md": "lib/util/industry.do",
    "code/intervals_do.md": "lib/create/intervals.do",
    "code/leverage_jl.md": "lib/create/leverage.jl",
    "code/manager_facts_do.md": "lib/create/manager-facts.do",
    "code/manager_value_do.md": "lib/estimate/manager_value.do",
    "code/montecarlo_do.md": "lib/create/montecarlo.do",
    "code/network_sample_do.md": "lib/create/network-sample.do",
    "code/potholes_do.md": "lib/util/potholes.do",
    "code/revenue_function_do.md": "lib/estimate/revenue_function.do",
    "code/setup_event_study_do.md": "lib/estimate/setup_event_study.do",
    "code/unfiltered_do.md": "lib/create/unfiltered.do",
    "code/variables_do.md": "lib/util/variables.do",
    "code/xt2var_do.md": "lib/estimate/xt2var.do",
    "makefile_application.md": "papers/application/Makefile",
    "makefile_econometrics.md": "papers/econometrics/Makefile",
    "makefile_main.md": "Makefile",
    "paper_application.md": "papers/application/paper.tex",
    "paper_econometrics.md": "papers/econometrics/paper_july2026.tex",
    "data_flow.md": "doc/data-flow.md",
    "estimation_doc.md": "doc/estimation.md",
    "readme.md": "README.md",
    "results/table2_result.md": "papers/application/table/table2.tex",
    "results/tableA1_result.md": "papers/application/table/tableA1.tex",
    "results/tableA3_result.md": "papers/application/table/tableA3.tex",
    "results/tableA4_result.md": "papers/application/table/tableA4.tex",
    "results/table_r2s_full.md": "papers/econometrics/table/r2s_full.tex",
}

def write_reference(name, src_rel, kind="lines"):
    out = REFS / name
    src = ROOT / src_rel
    sha = sha256_of(src)
    title, desc = parse_frontmatter(out)
    notes = parse_notes(out)
    body = "---\ntype: Reference\n"
    body += f"title: {title or name}\n"
    body += f"description: {desc or 'Evidence reference for ' + str(name)}\n"
    body += "status: draft\ngenerated:\n  by: build-replication-wiki\n"
    body += f"  at: {NOW}\n---\n\n"
    body += f"# {title or name}\n\n## Source\n\n"
    body += f"- Path: `{src_rel}`\n- SHA-256: `{sha}`\n- Inspected: exact line slices below\n\n"
    if kind == "full":
        body += "## Excerpt\n\n### Full file verbatim\n```text\n"
        body += src.read_text().rstrip("\n") + "\n```\n\n"
    else:
        ranges = parse_ranges(out)
        if not ranges:
            ranges = [(1, len(src.read_text().splitlines()), "")]
        body += "## Excerpts\n\n"
        for start,end,label in ranges:
            body += f"### Lines {start}-{end}"
            if label: body += f": {label}"
            body += "\n```text\n" + read_lines(src,start,end) + "```\n\n"
    if notes:
        body += "## Notes\n\n" + "\n".join(f"- {n}" for n in notes) + "\n"
    out.write_text(body)
    print(f"wrote {name}")

def write_panels():
    out = REFS / "results" / "table1_panels.md"
    pa = ROOT / "papers/application/table/table1_panelA.tex"
    pb = ROOT / "papers/application/table/table1_panelB.tex"
    title, desc = parse_frontmatter(out)
    notes = parse_notes(out)
    body = "---\ntype: Reference\n"
    body += f"title: {title or 'Table 1 panels'}\n"
    body += f"description: {desc or 'Evidence from papers/application/table/table1_panelA.tex and panelB.tex.'}\n"
    body += "status: draft\ngenerated:\n  by: build-replication-wiki\n"
    body += f"  at: {NOW}\n---\n\n# {title or 'Table 1 panels'}\n\n## Sources\n\n"
    body += f"- Path: `papers/application/table/table1_panelA.tex`\n- SHA-256: `{sha256_of(pa)}`\n- Inspected: full file\n\n"
    body += f"- Path: `papers/application/table/table1_panelB.tex`\n- SHA-256: `{sha256_of(pb)}`\n- Inspected: full file\n\n## Excerpts\n\n"
    body += "### Panel A verbatim\n```text\n" + pa.read_text().rstrip("\n") + "\n```\n\n"
    body += "### Panel B verbatim\n```text\n" + pb.read_text().rstrip("\n") + "\n```\n\n"
    if notes:
        body += "## Notes\n\n" + "\n".join(f"- {n}" for n in notes) + "\n"
    out.write_text(body)
    print("wrote results/table1_panels.md")

LOGS = [
    ("analysis-sample.log", [(25,25, (81,81, (125,125, (128,128, (133,133, (153,153, (175,175, (198,198]]],
    ("event_study_sample.log", [(25,25, (85,85]]],
    ("edgelist.log", [(65,65, (69,70]]],
    ("manager_value.log", [(404,404, (413,413, (416,416]]],
]

def write_logs():
    out = REFS / "logs.md"
    title, desc = parse_frontmatter(out)
    notes = parse_notes(out)
    body = "---\ntype: Reference\n"
    body += f"title: {title or 'Stata execution logs'}\n"
    body += f"description: {desc or 'Evidence from root Stata batch logs.'}\n"
    body += "status: draft\ngenerated:\n  by: build-replication-wiki\n"
    body += f"  at: {NOW}\n---\n\n# {title or 'Stata execution logs'}\n\n## Sources\n\n"
    body += "- analysis-sample.log (analysis-sample.do run)\n- event_study_sample.log (event_study_sample.do run)\n- edgelist.log (edgelist.do run)\n- manager_value.log (manager_value.do run)\n\n"
    for rel, ranges in LOGS:
        path = ROOT / rel
        body += f"### {rel} (observed run)\n\n- Path: `{rel}`\n- SHA-256: `{sha256_of(path)}`\n\n```text\n"
        for start,end in ranges:
            body += read_lines(path,start,end)
        body += "```\n\n"
    if notes:
        body += "## Notes\n\n" + "\n".join(f"- {n}" for n in notes) + "\n"
    out.write_text(body)
    print("wrote logs.md")

def main():
    for name, src in SPEC.items():
        kind = "full" if name.startswith("results/") and name != "results/table1_panels.md" else "lines"
        if name == "results/table1_panels.md":
            write_panels()
        else:
            write_reference(name, src, kind)

    write_logs()
    print("done")

if __name__ == "__main__":
    main()