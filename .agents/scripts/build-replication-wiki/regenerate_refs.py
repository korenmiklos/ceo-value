#!/usr/bin/env python3
# Minimal regenerator: emits exact source slices only.
import hashlib
import re
from pathlib import Path

ROOT = Path("/Users/koren/Tresorit/Mac/projects/ceo-value")
REFS = ROOT / ".agents" / "dna" / "references"
NOW = "2026-09-07T09:44:50Z"

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def clean(s):
    return "".join(ch for ch in s if ord(ch) < 128)

def get_lines(p):
    return p.read_text().splitlines()

def get_ranges(p):
    out = []
    if not p.exists():
        return out
    for ln in get_lines(p):
        c = clean(ln)
        m = re.match(r"### Lines\s+(\d+)\s*-\s*(\d+)", c)
        if m:
            out.append((int(m.group(1)), int(m.group(2))))
    return out

def get_title(p):
    if not p.exists():
        return ""
    for ln in get_lines(p):
        if clean(ln).startswith("title:"):
            return clean(ln)[6:].strip()
    return ""

def get_desc(p):
    if not p.exists():
        return ""
    for ln in get_lines(p):
        if clean(ln).startswith("description:"):
            return clean(ln)[12:].strip()
    return ""

def get_notes(p):
    out = []
    if not p.exists():
        return out
    txt = p.read_text()
    if "## Notes" not in txt:
        return out
    part = txt.split("## Notes", 1)[1]
    for ln in part.splitlines():
        c = clean(ln).strip()
        if c.startswith("- "):
            out.append(c[2:])
    return out

def write_ref(name, src_rel, full=False):
    p = REFS / name
    src = ROOT / src_rel
    b = []
    b.append("---")
    b.append("type: Reference")
    b.append("title: " + (get_title(p) or name))
    b.append("description: " + (get_desc(p) or "Evidence reference for " + name))
    b.append("status: draft")
    b.append("generated:")
    b.append("  by: build-replication-wiki")
    b.append("  at: " + NOW)
    b.append("---")
    b.append("")
    b.append("# " + (get_title(p) or name))
    b.append("")
    b.append("## Source")
    b.append("")
    b.append("- Path: `" + src_rel + "`")
    b.append("- SHA-256: `" + sha(src) + "`")
    b.append("- Inspected: exact source slices below")
    b.append("")
    if full:
        b.append("## Excerpt")
        b.append("")
        b.append("### Full file verbatim")
        b.append("```text")
        b.extend(get_lines(src))
        b.append("```")
    else:
        b.append("## Excerpts")
        b.append("")
        for a, z in get_ranges(p):
            b.append("### Lines " + str(a) + "-" + str(z))
            b.append("```text")
            b.extend(get_lines(src)[a-1:z])
            b.append("```")
            b.append("")
    nts = get_notes(p)
    if nts:
        b.append("## Notes")
        b.append("")
        for n in nts:
            b.append("- " + n)
        b.append("")
    p.write_text("\n".join(b))
    print("wrote " + name)

# plain slice specs
SPEC = {
    "code/balance_do.md": "lib/create/balance.do",
    "code/intervals_do.md": "lib/create/intervals.do",
    "code/ceo_panel_do.md": "lib/create/ceo-panel.do",
    "code/unfiltered_do.md": "lib/create/unfiltered.do",
    "code/filter_do.md": "lib/util/filter.do",
    "code/variables_do.md": "lib/util/variables.do",
    "code/industry_do.md": "lib/util/industry.do",
    "code/potholes_do.md": "lib/util/potholes.do",
    "code/analysis_sample_do.md": "lib/create/analysis-sample.do",
    "code/edgelist_do.md": "lib/create/edgelist.do",
    "code/network_sample_do.md": "lib/create/network-sample.do",
    "code/manager_facts_do.md": "lib/create/manager-facts.do",
    "code/connected_component_jl.md": "lib/create/connected_component.jl",
    "code/leverage_jl.md": "lib/create/leverage.jl",
    "code/event_study_sample_do.md": "lib/create/event_study_sample.do",
    "code/manager_value_do.md": "lib/estimate/manager_value.do",
    "code/revenue_function_do.md": "lib/estimate/revenue_function.do",
    "code/setup_event_study_do.md": "lib/estimate/setup_event_study.do",
    "code/event_study_do.md": "lib/estimate/event_study.do",
    "code/event_study_atet_do.md": "lib/estimate/event_study_atet.do",
    "code/xt2var_do.md": "lib/estimate/xt2var.do",
    "code/extract_do.md": "lib/create/extract.do",
    "code/montecarlo_do.md": "lib/create/montecarlo.do",
    "code/bloom_autonomy_do.md": "lib/estimate/bloom_autonomy_analysis.do",
    "makefile_main.md": "Makefile",
    "makefile_application.md": "papers/application/Makefile",
    "makefile_econometrics.md": "papers/econometrics/Makefile",
    "paper_application.md": "papers/application/paper.tex",
    "paper_econometrics.md": "papers/econometrics/paper_july2026.tex",
    "data_flow.md": "doc/data-flow.md",
    "estimation_doc.md": "doc/estimation.md",
    "readme.md": "README.md",
}

FULL = {
    "results/table2_result.md": "papers/application/table/table2.tex",
    "results/tableA1_result.md": "papers/application/table/tableA1.tex",
    "results/tableA3_result.md": "papers/application/table/tableA3.tex",
    "results/tableA4_result.md": "papers/application/table/tableA4.tex",
    "results/table_r2s_full.md": "papers/econometrics/table/r2s_full.tex",
}

for name, src in SPEC.items():
    write_ref(name, src)

for name, src in FULL.items():
    write_ref(name, src, full=True)

# panels
p = REFS / "results" / "table1_panels.md"
pa = ROOT / "papers/application/table/table1_panelA.tex"
pb = ROOT / "papers/application/table/table1_panelB.tex"
b = []
b.append("---")
b.append("type: Reference")
b.append("title: " + (get_title(p) or "Table 1 panels"))
b.append("description: " + (get_desc(p) or "Evidence from table1_panelA.tex and panelB.tex"))
b.append("status: draft")
b.append("generated:")
b.append("  by: build-replication-wiki")
b.append("  at: " + NOW)
b.append("---")
b.append("")
b.append("# " + (get_title(p) or "Table 1 panels"))
b.append("")
b.append("## Sources")
b.append("")
b.append("- Path: `papers/application/table/table1_panelA.tex`")
b.append("- SHA-256: `" + sha(pa) + "`")
b.append("")
b.append("- Path: `papers/application/table/table1_panelB.tex`")
b.append("- SHA-256: `" + sha(pb) + "`")
b.append("")
b.append("## Excerpts")
b.append("")
b.append("### Panel A verbatim")
b.append("```text")
b.extend(get_lines(pa))
b.append("```")
b.append("")
b.append("### Panel B verbatim")
b.append("```text")
b.extend(get_lines(pb))
b.append("```")
nts = get_notes(p)
if nts:
    b.append("## Notes")
    b.append("")
    for n in nts:
        b.append("- " + n)
    b.append("")
p.write_text("\n".join(b))
print("wrote results/table1_panels.md")

# logs
p = REFS / "logs.md"
LOGS = [
    ("analysis-sample.log", [25, 81, 125, 128, 133, 153, 175, 198]),
    ("event_study_sample.log", [25, 85]),
    ("edgelist.log", [65,  69,  70]),
    ("manager_value.log", [404, 413, 416]),
]
b = []
b.append("---")
b.append("type: Reference")
b.append("title: " + (get_title(p) or "Stata execution logs"))
b.append("description: " + (get_desc(p) or "Evidence from root Stata batch logs"))
b.append("status: draft")
b.append("generated:")
b.append("  by: build-replication-wiki")
b.append("  at: " + NOW)
b.append("---")
b.append("")
b.append("# " + (get_title(p) or "Stata execution logs"))
b.append("")
it = 0
for rel, ls in LOGS:
    it +=  1
    b.append("### " + rel + " (observed run)")
    b.append("")
    b.append("- Path: `" + rel + "`")
    b.append("- SHA-256: `" + sha(ROOT / rel) + "`")
    b.append("")
    b.append("```text")
    src = get_lines(ROOT / rel)
    for a in ls:
        b.append(src[a-1])
    b.append("```")
    b.append("")
nts = get_notes(p)
if nts:
    b.append("## Notes")
    b.append("")
    for n in nts:
        b.append("- " + n)
    b.append("")
p.write_text("\n".join(b))
print("wrote logs.md")
print("done")