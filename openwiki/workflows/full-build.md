---
type: workflow
title: Full Build and Make Workflow
description: End-to-end build orchestration via Make, covering the data pipeline, statistical analysis, exhibit generation, and LaTeX paper compilation for the CEO value research project.
tags: [make, build, pipeline, Stata, Julia, LaTeX]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-a2371d6362e5db4bc834ad03
    resource: repo://CLAUDE.md
  - id: openwiki-source-46db84383d79696b4d341df2
    resource: repo://lib/create/analysis-sample.do
  - id: openwiki-source-f85faafafeb554812fa0eed3
    resource: repo://lib/create/event_study_sample.do
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-668d3dee65423484e813acea
    resource: repo://papers/application/Makefile
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Full Build and Make Workflow

## Overview

The project uses **Make** as its build orchestrator. Two Makefiles collaborate to form the complete dependency graph:

- **`/Makefile`** (root): Owns the data-wrangling pipeline and core statistical estimation. It defines targets for processing raw inputs (`balance.dta`, `ceo-panel.dta`), constructing the analysis sample, generating placebo CEO transitions, running network analysis (Julia), and estimating manager fixed effects.
- **`/papers/application/Makefile`** (application): Owns the exhibit pipeline, figure generation, and LaTeX compilation. It depends on intermediate files produced by the root Makefile and adds table/figure creation and paper rendering.

The full build is triggered with `make all` from the `papers/application/` directory.

---

## Phony Targets

The application Makefile declares these phony targets:

| Target | Role |
|---|---|
| `all` | Complete build: data → analysis → report |
| `install` | Install Stata packages (run once) |
| `data` | Data-wrangling pipeline up to the connected component |
| `analysis` | Econometric estimation: surplus, manager value, event study, revenue function |
| `report` | Final LaTeX paper with all exhibits |
| `event_study` | Generate CSV files for event-study coefficients across all samples and outcomes |
| `extract` | Confidential data extracts for external analysis |

The root Makefile declares `data` as phony (a subset of the full data chain).

---

## End-to-End `make all` Flow

The dependency chain is:

```
all
  └── report (paper.pdf + figures)
        ├── paper.tex (source)
        ├── table/table1_panelAB.tex      ── table1.do → ../../temp/unfiltered.dta ...
        ├── table/table2_panelA.tex        ── table2.do → ../../temp/analysis-sample.dta
        ├── table/table2_panelB.tex        ── table2.do
        ├── table/table3.tex               ── table3.do → ../../temp/revenue_models.ster
        ├── table/tableA0.tex              ── tableA0.do → Bloom input data
        ├── table/tableA1.tex              ── tableA1.do → ../../temp/unfiltered.dta
        ├── table/tableA3.tex
        ├── table/tableA4.tex
        ├── figure/manager_skill_within.pdf  ── manager_value.do
        ├── figure/manager_skill_connected.pdf
        ├── figure/figure1.pdf             ── figure1.do → data/*_TFP.csv
        ├── figure/figure2.pdf             ── figure2.do
        └── figure/figure3.pdf             ── figure3.do → data/full_*.csv
```

The `data` target expands to:

```
data (phony)
  ├── ../../temp/unfiltered.dta
  │     └── unfiltered.do → temp/balance.dta + temp/ceo-panel.dta + utilities
  │            ├── temp/balance.dta ── balance.do → input/merleg-LTS-2023/balance/balance_sheet_80_22.dta
  │            └── temp/ceo-panel.dta ── ceo-panel.do → input/manager-db-ceo-panel/ceo-panel.dta
  │                    └── temp/intervals.dta ── intervals.do → input
  │                    └── temp/manager-firm-facts.dta, temp/manager-facts.dta ── manager-facts.do → input
  ├── ../../temp/analysis-sample.dta
  │     └── analysis-sample.do → temp/unfiltered.dta + filter.do
  ├── ../../temp/placebo.dta (legacy; the current system uses variation-placebo-sample variants)
  └── ../../temp/large_component_managers.csv
        └── connected_component.jl → temp/edgelist.csv
              └── edgelist.do → temp/analysis-sample.dta
```

The `analysis` target expands to:

```
analysis (phony)
  ├── ../../temp/surplus.dta ── surplus.do → temp/analysis-sample.dta
  ├── ../../temp/manager_value.dta
  │     └── manager_value.do → temp/analysis-sample.dta + temp/large_component_managers.csv + network-sample.do
  ├── ../../temp/event_study_panel_a.dta
  ├── ../../temp/event_study_panel_b.dta
  ├── ../../temp/event_study_moments.dta
  ├── ../../temp/revenue_models.ster ── revenue_function.do
  ├── bloom_autonomy_analysis.log ── bloom_autonomy_analysis.do
  └── table/atet_owner.tex, table/atet_manager.tex ── anova.do
```

---

## Data Wrangling Detail (Root Makefile)

### Input Data

Two proprietary Hungarian administrative datasets (not included in the repository):

- `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta` — balance sheet data (Mérleg LTS)
- `input/manager-db-ceo-panel/ceo-panel.dta` — CEO registry (Cégjegyzék LTS)

### Core Data Targets

| Target | Script | Dependencies | Description |
|---|---|---|---|
| `temp/balance.dta` | `lib/create/balance.do` | Raw balance sheet input | Cleans balance sheets, applies time range 1992–2022 |
| `temp/manager-facts.dta`, `temp/manager-firm-facts.dta` | `lib/create/manager-facts.do` | CEO panel input | Lookup tables for manager characteristics |
| `temp/intervals.dta` | `lib/create/intervals.do` | CEO panel input + `potholes.do` | Cleaned CEO tenure intervals |
| `temp/ceo-panel.dta` | `lib/create/ceo-panel.do` | CEO panel + intervals + manager facts | Firm-person-year CEO panel |
| `temp/unfiltered.dta` | `lib/create/unfiltered.do` | `balance.dta` + `ceo-panel.dta` + all `util/*.do` | Merged dataset with industry classification and derived variables |
| `temp/<variation>-analysis-sample.dta` | `lib/create/analysis-sample.do` | `temp/unfiltered.dta` + `lib/util/filter.do` | Applies sample restrictions; pattern rule accepts `full`, `pre2000`, `post2000`, `size1`–`size4` |
| `temp/edgelist.csv` | `lib/create/edgelist.do` | `temp/full-analysis-sample.dta` | Firm-manager edgelist (frame_id_numeric, person_id) |
| `temp/large_component_managers.csv` | `lib/create/connected_component.jl` (Julia) | `temp/edgelist.csv` | Largest connected component of managers via bipartite graph projection |
| `temp/edgelist_leverage.csv` | `lib/create/leverage.jl` (Julia) | `temp/edgelist.csv` | Leverage of each firm-manager edge in the giant component |

### Placebo Transition Targets

Placebo CEO transitions are generated via a `$(foreach)` macro. The Makefile defines a template `GEN_PLACEBO` and instantiates it for every combination of:

- **Analysis variations**: `full`, `size1`, `size2`, `size3`, `size4`, `pre2000`, `post2000`
- **Samples**: `full`, `one2one`, `twos`, `fnd2non`, `non2non`, `gender`, `nogender`, `gap`, `nogap`

Each target `temp/<variation>_placebo_<sample>.dta` depends on `lib/create/event_study_sample.do` and the corresponding analysis-sample and manager_value files. The rule passes both the variation and sample as positional arguments to Stata.

These 56+ placebo files are marked `.PRECIOUS` to prevent Make from cleaning them after intermediate build steps.

---

## Statistical Analysis

| Target | Script | Dependencies | Description |
|---|---|---|---|
| `temp/manager_value.dta` | `lib/estimate/manager_value.do` | `full-analysis-sample.dta` + `large_component_managers.csv`+ `network-sample.do` | Manager fixed effects, variance decomposition, within-firm and cross-section skill distributions |
| `balance.log` | `lib/estimate/balance.do` | `full-analysis-sample.dta` + `network-sample.do` | Balance estimation (alternative analysis) |
| `output/test/placebo_test.log` | `lib/test/placebo.do` | `output/test/placebo.dta` | Placebo test validation |

In the application Makefile, additional targets cover `surplus.dta`, `revenue_models.ster`, event study panels, ANOVA tables, and Bloom autonomy analysis.

---

## Exhibit Targets (Tables and Figures)

### Tables

| Target (in `table/`) | Script | Dependencies |
|---|---|---|
| `table1_panelAB.tex` | `src/exhibit/table1.do` | `../../temp/unfiltered.dta`, `../../temp/analysis-sample.dta`, `../../temp/large_component_managers.csv` |
| `table2_panelA.tex`, `table2_panelB.tex` | `src/exhibit/table2.do` | `../../temp/analysis-sample.dta` |
| `table3.tex` | `src/exhibit/table3.do` | `../../temp/revenue_models.ster`, `../../temp/analysis-sample.dta`, `../../temp/large_component_managers.csv` |
| `tableA0.tex` | `src/exhibit/tableA0.do` | Bloom et al. (2012) replication data |
| `tableA1.tex` | `src/exhibit/tableA1.do` | `../../temp/unfiltered.dta`, `../../temp/analysis-sample.dta` |
| `atet_owner.tex`, `atet_manager.tex` | `lib/estimate/anova.do` | `../../temp/surplus.dta`, `../../temp/analysis-sample.dta` |

### Figures

| Target (in `figure/`) | Script | Dependencies |
|---|---|---|
| `figure1.pdf` | `src/exhibit/figure1.do` | `data/fnd2non_TFP.csv`, `data/non2non_TFP.csv`, `data/full_TFP.csv`, `data/post2004_TFP.csv` |
| `figure2.pdf` | `src/exhibit/figure2.do` | Same event study CSV files |
| `figure3.pdf` | `src/exhibit/figure3.do` | `data/full_lnK.csv`, `data/full_has_intangible.csv`, `data/full_lnM.csv`, `data/full_lnWL.csv` |
| `manager_skill_within.pdf`, `manager_skill_connected.pdf` | `lib/estimate/manager_value.do` | Generated during the analysis phase |

### Event Study CSV Generation

The event study coefficient CSVs (e.g., `data/full_TFP.csv`) are produced via a generated pattern rule inside the application Makefile:

```
data/%_<outcome>.csv: ../../lib/estimate/event_study.do ...
    mkdir -p data
    ln -sf ../../temp/placebo_$*.dta data/placebo_$*.dta
    cd ../.. && $(STATA) "papers/application/lib/estimate/event_study.do $* <outcome>"
    rm -f data/placebo_$*.dta
```

This is instantiated for every combination of sample (`full`, `fnd2non`, `non2non`, `post2004`) and outcome (`TFP`, `lnK`, `lnWL`, `lnM`, `has_intangible`) via a `$(foreach)` loop.

---

## Report (LaTeX Paper Compilation)

The `report` target depends on `paper.pdf`, which is compiled with:

```
paper.pdf: paper.tex ../../lib/references.bib <all table .tex files> <all figure .pdf files>
    pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex
```

This means LaTeX compilation only runs after all prerequisites (tables, figures) are up to date. The bibliography (`lib/references.bib`) is included in the dependency list so `bibtex` re-runs when citations change.

---

## Precious Files

The `$(PRECIOUS_FILES)` list in both Makefiles prevents Make from deleting computationally expensive intermediates after a build completes. Files covered include:

**Root Makefile (expanded `PRECIOUS`)**

- `temp/balance.dta`, `temp/ceo-panel.dta`, `temp/intervals.dta`, `temp/unfiltered.dta`
- All `temp/<variation>-analysis-sample.dta` (7 variations)
- `temp/edgelist.csv`, `temp/large_component_managers.csv`, `temp/edgelist_leverage.csv`
- `temp/manager_value.dta`, `temp/manager_value_spell.dta`, `temp/revenue_models.ster`
- All `temp/<variation>_placebo_<sample>.dta` (7 × 9 = 63 files)

**Application Makefile (expanded `PRECIOUS`)**

- `../../temp/balance.dta`, `../../temp/ceo-panel.dta`, `../../temp/unfiltered.dta`
- `../../temp/analysis-sample.dta`, `../../temp/placebo.dta`, `../../temp/edgelist.csv`
- `../../temp/large_component_managers.csv`, `../../temp/surplus.dta`
- `../../temp/manager_value.dta`, `../../temp/revenue_models.ster`
- `../../temp/placebo_<sample>.dta` (4 samples)

---

## Common Workflows

### Incremental Build (Individual Leaf Targets)

```bash
# Rebuild a single data file
make ../../temp/balance.dta

# Rebuild a single exhibit table
make table/table3.tex

# Rebuild a figure
make figure/figure2.pdf

# Re-run only the event study for one sample and outcome
make data/fnd2non_TFP.csv

# Re-run manager value estimation (after data changes)
make ../../temp/manager_value.dta

# Recompile the paper only (if exhibits are already present)
make paper.pdf
```

### Full Rebuild

```bash
# From papers/application/:
make all          # Full build: data → analysis → report (~2–4 hours)
make all -j2      # Parallel build where dependencies permit
make clean        # Destructive: removes all intermediates (defined in WARP.md)
```

### Stata Log Inspection

Every Stata invocation writes a `.log` file. These are the primary troubleshooting resource:

- `balance.log`, `ceo-panel.log`, `unfiltered.log`: Data processing logs
- `analysis-sample.log`: Sample restriction logs
- `manager_value.log`: Manager skill estimation
- `event_study.log`, `event_study_sample.log`: Placebo event study
- `edgelist.log`: Network edgelist export
- `surplus.log`, `revenue_function.log`: Revenue function estimation

When a target fails, the corresponding `.log` file contains the Stata error message and the line number where execution stopped.

### Stata Package Installation (First Run)

```bash
make install
# or
stata -b do lib/util/install.do
```

This installs `reghdfe`, `estout`, `xt2treatments`, and `e2frame`.

---

## Tool Definitions

```makefile
STATA := stata-mp -b do      # Stata MP, batch mode
JULIA := julia --project=.   # Julia with project environment
LATEX := pdflatex            # LaTeX compiler
PANDOC := pandoc             # Document conversion (not used in default targets)
```

---

## Analysis and Sample Variations

### Analysis Variations (`ANALYSIS_VARIATIONS`)

Used to generate analysis-sample files and placebo variants for different subsets of the data:

| Variation | Description |
|---|---|
| `full` | Full sample (no time/size restriction beyond standard filters) |
| `size1` | Stratum 1 (smallest firms) |
| `size2` | Stratum 2 |
| `size3` | Stratum 3 |
| `size4` | Stratum 4 (largest firms) |
| `pre2000` | Observations before 2000 |
| `post2000` | Observations from 2000 onward |

### Samples (`SAMPLES`)

Used for placebo generation and event study:

| Sample | Definition |
|---|---|
| `full` | All spells meeting criteria |
| `one2one` | Exactly one CEO before and after transition |
| `twos` | Two CEOs on one or both sides |
| `fnd2non` | Founder CEO replaced by non-founder |
| `non2non` | Non-founder replaced by non-founder |
| `gender` | CEO gender changes between spells |
| `nogender` | CEO gender stays the same |
| `gap` | Age gap > 10 years between CEOs |
| `nogap` | Age gap ≤ 10 years between CEOs |

### Outcomes (`OUTCOMES`)

Used for event study coefficient CSV generation:

| Outcome | Description |
|---|---|
| `TFP` | Total factor productivity |
| `lnK` | Log capital |
| `lnWL` | Log wage bill |
| `lnM` | Log materials |
| `has_intangible` | Has intangible assets indicator |

---

## Dependency Chain Summary

<!-- openwiki: mermaid parse failed and this diagram was converted to a text fence so it does not break rendering. Fix the diagram source and restore the mermaid fence. Parser error: Heuristic: an unescaped angle bracket inside a label breaks rendering; rephrase the label. -->
```text
flowchart LR
    subgraph Input
        BS[balance_sheet_80_22.dta]
        CP[ceo-panel.dta]
    end

    subgraph Data
        BAL[balance.dta]
        INT[intervals.dta]
        MFF[manager-firm-facts.dta<br>manager-facts.dta]
        CEO[ceo-panel.dta]
        UNF[unfiltered.dta]
        AS[analysis-sample.dta]
        EDGE[edgelist.csv]
        CC[large_component_managers.csv]
        PL[placebo_*.dta]
    end

    subgraph Analysis
        SUR[surplus.dta]
        MV[manager_value.dta]
        REV[revenue_models.ster]
        ES[event_study panels]
    end

    subgraph Exhibits
        T[table *.tex]
        F[figure *.pdf]
    end

    subgraph Report
        PDF[paper.pdf]
    end

    BS --> BAL
    CP --> INT
    CP --> MFF
    BAL --> UNF
    CEO --> UNF
    INT --> CEO
    MFF --> CEO
    UNF --> AS
    AS --> EDGE
    EDGE --> CC
    AS --> MV
    CC --> MV
    AS --> SUR
    SUR --> MV
    AS --> REV
    MV --> PL
    AS --> PL
    AS --> T
    CC --> T
    SUR --> T
    REV --> T
    SUR --> F
    ES --> F
    PL --> F
    T --> PDF
    F --> PDF
```

---

## Troubleshooting

| Symptom | Likely Cause | Remedy |
|---|---|---|
| `make` error about missing `.dta` | Input data not placed in `input/` | Follow README instructions for data access |
| Stata log shows `file not found` | Incorrect working directory | Run `make` from project root or `papers/application/` |
| Stata `command not found` | Missing Stata package | Run `make install` first |
| Julia error in `connected_component.jl` | Missing package | Run `julia --project=. -e 'using Pkg; Pkg.instantiate()'` |
| LaTeX compilation fails | Missing table/figure file | Run `make analysis` before `make report` |
| Build interrupted; re-run is slow | Intermediate files may be inconsistent | Target specific leaf files, or clean and rebuild |
| `make` deletes intermediates | File not in `.PRECIOUS` | Check that the file is listed in `PRECIOUS_FILES` |
| Error: `confirm existence` in Stata | Invalid variation/sample argument | Verify the argument matches a known value in `ANALYSIS_VARIATIONS` or `SAMPLES` |

All Makefile rules must be executed from the **project root directory** (for root Makefile) or from **`papers/application/`** (for application Makefile). Inconsistent working directories are the most common cause of path-related failures.
