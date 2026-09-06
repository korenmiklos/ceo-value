---
type: operations
title: Setup and Dependencies
description: Documents environment requirements (Stata 18, Julia 1.10.4, Python 3.13), Stata package installation via install.do (reghdfe, estout, xt2treatments, e2frame), Julia environment defined in Project.toml (CSV, DataFrames, Graphs, LeaveOut, SparseArrays), Python dependencies in pyproject.toml, input data placement instructions, Makefile prerequisites, and LaTeX requirements for compiling the paper.
tags: [setup, dependencies, Stata, Julia, Python, environment, installation, Makefile, LaTeX]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-868b3402493aef58bb5db066
    resource: repo://.python-version
  - id: openwiki-source-0b4443606c794d02e5f3fdc1
    resource: repo://lib/util/install.do
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-5a45efb32d540f177b4fa9fc
    resource: repo://Manifest.toml
  - id: openwiki-source-668d3dee65423484e813acea
    resource: repo://papers/application/Makefile
  - id: openwiki-source-59f2f40c6cfbe469fc787915
    resource: repo://papers/econometrics/Makefile
  - id: openwiki-source-0f3c6735bbc40f4951ad2578
    resource: repo://Project.toml
  - id: openwiki-source-05ccef8d4cf1698187f20464
    resource: repo://pyproject.toml
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# Setup and Dependencies

## Overview

This project uses a polyglot toolchain: **Stata 18** for data processing and econometric estimation, **Julia 1.10.4** for graph/network analysis, and **Python 3.13** for auxiliary tooling. **GNU Make** orchestrates the entire pipeline. **LaTeX** (with packages `booktabs`, `graphicx`, `natbib`, `hyperref`) compiles the paper and slides.

All scripts must be run from the **project root directory** — relative file paths are used throughout.

---

## Environment Requirements

### Stata 18.0

All data processing, econometric estimation, and exhibit generation uses Stata. The code was last run with **Stata 18.0** (MP/flavor variant). Four community-contributed packages are required:

| Package | Version | Source | Purpose |
|---------|---------|--------|---------|
| `reghdfe` | 6.12.3 (08aug2023) | SSC | High-dimensional fixed-effects estimation |
| `estout` | 3.31 (26apr2022) | SSC | Regression table export to LaTeX |
| `xt2treatments` | 0.9.0 (19sep2025) | GitHub (`codedthinking/xt2treatments`) | Two-way fixed-effects event study |
| `e2frame` | 0.1.0 (21may2024) | GitHub (`codedthinking/e2frame`) | Frame-level utilities for Stata |

The installation script at `repo://lib/util/install.do`#L1-L10 automates the installation:

```stata
* packages from GitHub
foreach X in xt2treatments e2frame {
    net install `X', from(https://raw.githubusercontent.com/codedthinking/`X'/main/) replace
    which `X'
}

* packages from SSC
foreach X in reghdfe estout {
    ssc install `X', replace
    which `X'
}
```

Run once via Make:
```bash
make install
```

Or manually:
```bash
stata -b do lib/util/install.do
```

The Makefile target maps to `repo://Makefile`#L117-L118:
```makefile
install.log: lib/util/install.do
	$(STATA) $<
```

where `STATA := stata-mp -b do` (defined at `repo://Makefile`#L7).

### Julia 1.10.4

Julia is used exclusively for graph/network analysis — bipartite firm-manager projection, connected component identification, and leverage computation. The code was last run with **Julia 1.10.4** (`repo://Manifest.toml`#L3).

**Project environment** defined in `repo://Project.toml`#L1-L7:

```toml
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
LeaveOut = "b3d5e7a1-4c62-4f8a-9e11-2a7c9f0d6e34"
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
```

| Package | UUID | Purpose |
|---------|------|---------|
| `CSV` | `336ed68f-...` | Reading/writing edgelist CSV files |
| `DataFrames` | `a93c6f00-...` | Tabular data handling for graph construction |
| `Graphs` | `86223c79-...` | Bipartite graph projection, connected components |
| `LeaveOut` | `b3d5e7a1-...` | Leave-out estimators (jackknife variance) |
| `SparseArrays` | `2f01184e-...` | Sparse matrix storage for large graphs |

The `Manifest.toml` pins exact versions (Julia version 1.10.4, project hash `4ae2bb845d99ccb8d1d3c5183a34d6759f9e88a8`).

Run Julia scripts from project root with `--project=.` flag:
```bash
julia --project=. lib/create/connected_component.jl
julia --project=. lib/create/leverage.jl
```

### Python 3.13

Python provides project tooling (not core analysis). Dependencies are defined in `repo://pyproject.toml`#L1-L9:

```toml
[project]
name = "ceo-value"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "openai>=2.44.0",
    "pydantic>=2.13.4",
    "pydantic-evals>=2.0.0",
    "pyyaml>=6.0",
]
```

The `.python-version` (`repo://.python-version`) specifies `3.13`. Install via `uv` or `pip`:
```bash
uv sync   # if using uv (recommended, uv.lock provided)
pip install -e .
```

### LaTeX

Paper compilation requires a standard LaTeX distribution (`pdflatex` + `bibtex`) with these packages:
- `booktabs` — publication-quality tables
- `graphicx` — figure inclusion
- `natbib` — bibliography styles
- `hyperref` — cross-references and links

The Makefile defines `LATEX := pdflatex` (`repo://Makefile`#L9). Compile sequence:
```bash
cd output && pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex
```

### GNU Make

GNU Make is the single orchestration layer. Three Makefiles exist, each with independent target trees:

| Makefile | Scope | Tool Definitions |
|----------|-------|------------------|
| `repo://Makefile` | Root data pipeline | `STATA := stata-mp -b do`, `JULIA := julia --project=.`, `LATEX := pdflatex` |
| `papers/application/Makefile` | Application paper build | `STATA := stata -b do`, `JULIA := julia --project=../..` |
| `papers/econometrics/Makefile` | Econometrics paper build | `STATA := stata-mp` (different syntax) |

The root Makefile marks costly intermediate files as `.PRECIOUS` (`repo://Makefile`#L24-L32) to prevent auto-deletion.

---

## Data Placement

The project requires two proprietary input datasets that **cannot be redistributed**. Place them as follows:

| Dataset | Expected Location | Format |
|---------|-------------------|--------|
| **Balance Sheet Data** (Merleg LTS) | `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta` | Stata `.dta` |
| **CEO Panel Data** (Cegjegyzek LTS) | `input/ceo-panel/ceo-panel.dta` | Stata `.dta` |

The README at `repo://README.md`#L145-L149 provides instructions:

> 1. **Obtain the data**: Contact Opten Zrt (commercial, ~10,000 EUR/year) or KRTK Adatbank (academic/replication).
> 2. **Place data files**:
>    - Place `balance_sheet_80_22.dta` in `input/merleg-LTS-2023/balance/`
>    - Place `ceo-panel.dta` in `input/ceo-panel/`

The `.gitignore` (`repo://.gitignore`#L1-L2) ignores the `input/` directory entirely — input data is never stored in the repository.

Alternative data sources include an `input/manager-db-ceo-panel/ceo-panel.dta` path used by some Makefile targets (`repo://Makefile`#L55, L90). Confirm which path your data provider supplies.

---

## Storage and Runtime

- **Storage**: 2–25 GB depending on input data size.
- **Runtime**: 2–8 hours on a standard (2024) desktop machine.
- **Full pipeline**: Executed with `make all` (from `papers/application/Makefile`).

---

## Verification

After setup, verify each component:

```bash
# Stata packages
stata -b do lib/util/install.do
# Check install.log for errors

# Julia environment
julia --project=. -e 'using Pkg; Pkg.status()'

# Python environment
python --version  # should show 3.13.x

# LaTeX
pdflatex --version
```

---

## Related Pages

- `/openwiki/operations/running.md` — Detailed Makefile targets and individual script invocations
- `/openwiki/concepts/data-sources.md` — Input data provenance and schema
- `/openwiki/integrations/external-tools.md` — Toolchain integration patterns
