---
type: architecture
title: Data and Analysis Pipeline
description: Documents the end-to-end data flow, Makefile dependency graph, script ordering, and temp-file handoffs across three Stata layers (create, estimate, exhibit) and the Julia network layer for the CEO value placebo-controlled event study project.
tags: [architecture, data-pipeline, makefile, stata, julia, placebo]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-a2371d6362e5db4bc834ad03
    resource: repo://CLAUDE.md
  - id: openwiki-source-370ce04987186c8aa3a647f0
    resource: repo://doc/data-flow.md
  - id: openwiki-source-46db84383d79696b4d341df2
    resource: repo://lib/create/analysis-sample.do
  - id: openwiki-source-e6021cf24f8410c40aaf6ee1
    resource: repo://lib/create/connected_component.jl
  - id: openwiki-source-f85faafafeb554812fa0eed3
    resource: repo://lib/create/event_study_sample.do
  - id: openwiki-source-b7cf126704af8528032e0799
    resource: repo://lib/create/intervals.do
  - id: openwiki-source-f626faeec630004c3392a141
    resource: repo://lib/estimate/event_study.do
  - id: openwiki-source-6c17ee820f3a743f1061bc3c
    resource: repo://lib/estimate/manager_value.do
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-668d3dee65423484e813acea
    resource: repo://papers/application/Makefile
  - id: openwiki-source-4a4d757d5400909561472f45
    resource: repo://papers/application/MIGRATION_NOTES.md
  - id: openwiki-source-59f2f40c6cfbe469fc787915
    resource: repo://papers/econometrics/Makefile
  - id: openwiki-source-23775c3de52f3ab95a13cb8b
    resource: repo://README.md
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# Data and Analysis Pipeline

This page documents the end-to-end data processing and analysis pipeline for the CEO value research project. The pipeline spans three Stata layers (create, estimate, exhibit), a Julia network-analysis layer, and two LaTeX-compiled papers. The Makefile orchestrates all steps with precise dependency tracking using pattern rules and cross-joined variable wildcards.

## Overview

The pipeline transforms raw Hungarian administrative data (balance sheets + CEO registry) into cleaned analysis samples, estimates manager fixed effects via two-way panel models, constructs placebo CEO transitions for identification, runs placebo-controlled event studies, and produces publication-quality tables and figures. A Julia graph-analysis step identifies the largest connected component of managers to address limited-mobility bias in the two-way fixed effects estimation.

Two papers share the same core `lib/` library:

- **`papers/application/`** — The main application paper using the placebo design. Its Makefile references `../../lib/` (shared code) while paper-specific exhibits live in `src/exhibit/`.
- **`papers/econometrics/`** — The econometric methods paper with additional Monte Carlo simulations. Its Makefile links to `../../lib/` for shared estimators (`event_study.do`, `setup_event_study.do`, `xt2var.do`) while Monte Carlo generators live in `src/montecarlo/` and exhibits in `src/exhibit/`.

## Directory Layout and the `code/` Convention

All processing scripts live under `lib/`, organized by function:

| Directory | Purpose | Language |
|-----------|---------|----------|
| `lib/create/` | Data wrangling, cleaning, sample construction | Stata (`.do`), Julia (`.jl`) |
| `lib/estimate/` | Econometric estimation and event study | Stata (`.do`) |
| `lib/util/` | Utility includes (industry codes, variable construction, filters) | Stata (`.do`) |
| `lib/test/` | Unit and integration tests | Stata (`.do`), Julia (`.jl`) |
| `lib/KSS/` | KSS (Koren-Szilagyi-Szoke) methodology code | Mixed |
| `papers/application/src/exhibit/` | Paper-specific table/figure generators | Stata (`.do`) |
| `papers/econometrics/src/exhibit/` | Econometrics paper exhibits | Stata (`.do`) |
| `papers/econometrics/src/montecarlo/` | Monte Carlo DGP specifications | Stata (`.do`) |

**Important:** Many documents (README, CLAUDE.md, SUMMARIZE.md) refer to `code/` as shorthand for `lib/`. After the monorepo migration documented in `papers/application/MIGRATION_NOTES.md`, what was `code/` became `../../lib/` relative to each paper directory. On the actual filesystem, there is no `code/` directory at the root — scripts live under `lib/`. When reading references to `code/create/balance.do`, read it as `lib/create/balance.do`.

## Makefile Architecture

### Root Makefile (`/Makefile`)

The root Makefile drives the full data pipeline. It defines three cartesian-product variables that the build system cross-joins via `foreach` and `eval` to generate build rules:

```makefile
ANALYSIS_VARIATIONS := full size1 size2 size3 size4 pre2000 post2000
SAMPLES := full one2one twos fnd2non non2non gender nogender gap nogap
OUTCOMES := lnK lnWL lnM has_intangible
```

These variables control which analysis variations, sample restrictions, and outcome variables the pipeline processes. The total cross product is large — each placebo DTA file and each event study CSV occupies one cell of the `ANALYSIS_VARIATIONS × SAMPLES` matrix.

Key pattern rules:

- **Analysis sample pattern rule** (`temp/%-analysis-sample.dta`): Takes any `ANALYSIS_VARIATIONS` value as the `%` stem and invokes `analysis-sample.do` with that variation as an argument. The `filter.do` utility applies the corresponding sample restrictions.
- **Placebo generation** (`GEN_PLACEBO` template): Cross-joins every `ANALYSIS_VARIATION` with every `SAMPLE`, generating `temp/{variation}_placebo_{sample}.dta` from `event_study_sample.do`.
- The `make data` target builds `temp/manager_value.dta` plus the full cross product of placebo samples.

### Paper Makefiles

- **`papers/application/Makefile`**: Extends the root pipeline with paper-specific figure/table generation. Adds its own `SAMPLES` (`full fnd2non non2non post2004`) and `OUTCOMES` (`TFP lnK lnWL lnM has_intangible`). All Stata commands `cd ../..` to run from project root.
- **`papers/econometrics/Makefile`**: Has its own `SAMPLES`, `OUTCOMES`, `VARIATIONS`, and `FIXED_EFFECTS` sets with a more extensive `foreach` cross join. Adds Monte Carlo scenarios (`MC_SCENARIOS`). Calls `../../lib/estimate/event_study.do` with `montecarlo` as the sample argument.

## End-to-End Data Flow

<!-- openwiki: mermaid parse failed and this diagram was converted to a text fence so it does not break rendering. Fix the diagram source and restore the mermaid fence. Parser error: Heuristic: an unescaped angle bracket inside a label breaks rendering; rephrase the label. -->
```text
flowchart TD
    RAW_BAL["Raw Balance Sheet<br/>input/merleg-LTS-2023/balance/balance_sheet_80_22.dta"]
    RAW_CEO["Raw CEO Panel<br/>input/manager-db-ceo-panel/ceo-panel.dta"]
    INT["temp/intervals.dta<br/>Cleaned tenure intervals"]
    BAL["temp/balance.dta<br/>Processed balance sheet"]
    CEO_PANEL["temp/ceo-panel.dta<br/>Firm-year CEO panel"]
    UNF["temp/unfiltered.dta<br/>Merged unfiltered data"]
    AS["temp/{variation}-analysis-sample.dta<br/>Analysis sample"]
    EDGE["temp/edgelist.csv<br/>Firm-manager edgelist"]
    GC["temp/large_component_managers.csv<br/>Giant component"]
    MV["temp/manager_value.dta<br/>Manager FE estimates"]
    PLACEBO["temp/{variation}_placebo_{sample}.dta<br/>Placebo event study sample"]
    ES["output/event_study/{sample}_{outcome}.csv<br/>Event study coefficients"]
    TABLES["output/table/*.tex<br/>LaTeX tables"]
    FIGURES["output/figure/*.pdf<br/>Publication figures"]
    PAPER["output/paper.pdf<br/>Final compiled paper"]

    RAW_BAL -->|lib/create/balance.do| BAL
    RAW_CEO -->|lib/create/intervals.do| INT
    INT -->|lib/create/ceo-panel.do| CEO_PANEL
    RAW_CEO -->|lib/create/manager-facts.do| MF["temp/manager-facts.dta"]
    MF --> CEO_PANEL
    BAL -->|lib/create/unfiltered.do| UNF
    CEO_PANEL --> UNF
    UNF -->|lib/create/analysis-sample.do| AS
    AS -->|lib/create/edgelist.do| EDGE
    EDGE -->|lib/create/connected_component.jl| GC
    AS -->|lib/estimate/manager_value.do| MV
    GC --> MV
    AS -->|lib/create/event_study_sample.do| PLACEBO
    MV --> PLACEBO
    PLACEBO -->|lib/estimate/event_study.do| ES
    ES -->|src/exhibit/figure*.do| FIGURES
    MV -->|src/exhibit/table*.do| TABLES
    TABLES -->|LaTeX| PAPER
    FIGURES -->|LaTeX| PAPER
```

### Step-by-Step Temp File Handoff

#### 1. Raw Inputs
Two proprietary Hungarian administrative datasets, not distributable:
- **`input/merleg-LTS-2023/balance/balance_sheet_80_22.dta`**: Firm balance sheets 1980-2022 (sales, employment, assets, materials, wagebill, etc.)
- **`input/manager-db-ceo-panel/ceo-panel.dta`**: CEO registry with person IDs, firm IDs, appointment years

#### 2. `temp/intervals.dta` — Cleaned CEO Tenure Intervals
**Script:** `lib/create/intervals.do` + `lib/util/potholes.do`

Cleans the raw CEO panel into non-overlapping tenure intervals:
- Fills 1-2 year gaps in CEO spells (`potholes.do` expands rows to connect broken series)
- Collapses to `(start_year, end_year)` interval boundaries per firm-person-spell
- Limits to firms with ≤ 12 CEO spells
- Applies Allen's interval algebra to classify relations (before, meets, overlaps, during, etc.)
- Drops short (≤2 year) nested intervals and truncates overlapping ones
- Output: cleaned spell boundaries used by every downstream step that needs `person_id`

#### 3. `temp/balance.dta` — Processed Balance Sheet
**Script:** `lib/create/balance.do`

- Filters to 1992-2022; drops placeholder firm IDs
- Drops firm-years missing core variables (sales, employment, tangible assets, materials, personnel expenses, assets)
- Drops all observations before each firm's first clean-data year
- Encodes remaining missing values as 0; adjusts employment (+1, integer)
- Computes EBITDA and capital stock (`L.assets` with fallback)
- Output: clean firm-year panel with financial variables ready for merging

#### 4. `temp/ceo-panel.dta` — Firm-Year CEO Panel
**Script:** `lib/create/ceo-panel.do`

- Expands `intervals.dta` to firm-person-year rows
- Merges manager facts (gender, manager category, nationality)
- Creates CEO transition indicators and CEO count variables
- Collapses to firm-year level: `n_ceo`, `ceo_spell`, founder/expat flags
- Output: firm-year panel with CEO structure variables

#### 5. `temp/unfiltered.dta` — Merged Dataset
**Script:** `lib/create/unfiltered.do` + `lib/util/industry.do`, `lib/util/variables.do`

- 1:1 merges `balance.dta` with `ceo-panel.dta` (matched firm-years only)
- Applies industry classification (7+1 sector categories from TEAOR08 codes)
- Creates derived variables (log transformations, ratios, binary flags, firm age, cohorts, quadratic terms)
- Drops firms without a CEO spell record
- Output: complete merged dataset before sample restrictions

#### 6. `temp/{variation}-analysis-sample.dta` — Final Analytical Sample
**Script:** `lib/create/analysis-sample.do` + `lib/util/filter.do`

The `%` wildcard matches any `ANALYSIS_VARIATIONS` value (`full`, `size1`, ..., `post2000`). The `filter.do` utility applies restrictions:
- Drops firm-years without a CEO
- Drops firms with > 2 simultaneous CEOs or > 12 total CEO spells
- Drops firm-age 0 (incomplete first year) and finance sector
- Drops firms that never reach ≥ 3 employees (`min_employment` threshold per variation)
- Output: the cleaned firm-year analytical sample for estimation

#### 7. `temp/edgelist.csv` — Firm-Manager Bipartite Edgelist
**Script:** `lib/create/edgelist.do`

- Extracts unique firm IDs from the analysis sample
- Extracts unique firm-person pairs from `intervals.dta`
- Merges to restrict to analysis-sample firms
- Exports `frame_id_numeric, person_id` as CSV

#### 8. `temp/large_component_managers.csv` — Connected Component
**Script:** `lib/create/connected_component.jl` (Julia)

- Reads bipartite edgelist → builds sparse incidence matrix B (firms × managers)
- Projects to manager-manager co-employment graph (P = B'B)
- Finds connected components; filters to components with ≥ 30 managers
- Output: CSV with `person_id, component_id, component_size`

#### 9. `temp/manager_value.dta` — Manager Fixed Effects
**Script:** `lib/estimate/manager_value.do` + `lib/create/network-sample.do`

- Expands intervals to panel, joins with analysis sample
- Creates connected component indicator from the Julia output
- Computes within-firm manager skill (mean ROA by firm-person, demeaned by first CEO)
- Estimates two-way fixed effects: `reghdfe ROA, absorb(frame_id_numeric person_id)`
- Normalizes manager skill to giant component mean = 0
- Outputs both the firm-person level (`manager_value.dta`) and the spell-level version (`manager_value_spell.dta`)
- Generates skill distribution histograms

#### 10. `temp/{variation}_placebo_{sample}.dta` — Placebo Event Study Samples
**Script:** `lib/create/event_study_sample.do`

This is the methodological core of the placebo design. The script:
1. Merges manager skill estimates onto the firm-person-year panel
2. Restricts to firms with ≤ 2 CEOs with clean transitions
3. Collapses to spell-level, keeping consecutive-spell firms only
4. Defines sample filters via named macros (`full`, `fnd2non`, `non2non`, `one2one`, `twos`, `gap`, `nogap`, `gender`, `nogender`)
5. Builds a matched control pool using exact matching on `cohort, sector, max_size`, with 10:1 control-to-treated ratio target
6. Assigns placebo change years by sampling the treated firms' t0 distribution
7. Computes sampling weights (`N_treated / n_control`)
8. Produces output per `(variation, sample)` pair — each cell in the cross product

#### 11. Event Study Estimation (no persistent temp file)
**Script:** `lib/estimate/event_study.do` + `setup_event_study.do`

- Invoked from `papers/application/Makefile` or `papers/econometrics/Makefile`
- Passes `variation sample outcome fixed_effects montecarlo excessvariance` arguments
- Calls `xt2denoise` (the core Stata package for the denoised event study estimator)
- Outputs event study coefficient CSVs to `data/{sample}_{outcome}.csv` (application paper) or `data/{variation}_{sample}_{outcome}-{fixed_effect}.csv` (econometrics paper)

#### 12. Exhibits

Exhibit scripts read the event study CSVs and estimation outputs:

| Exhibit | Script | Dependencies |
|---------|--------|-------------|
| Table 1: Sample distribution | `src/exhibit/table1.do` | `unfiltered.dta`, `analysis-sample.dta`, `large_component_managers.csv` |
| Table 2: CEO patterns | `src/exhibit/table2.do` | `analysis-sample.dta` |
| Table 3: Revenue function | `src/exhibit/table3.do` | `revenue_models.ster`, `analysis-sample.dta`, `large_component_managers.csv` |
| Table A0: Bloom autonomy | `src/exhibit/tableA0.do` | External Bloom et al. replication data |
| Table A1: Industry statistics | `src/exhibit/tableA1.do` | `unfiltered.dta`, `analysis-sample.dta` |
| Figure 2: Event study by type | `src/exhibit/figure2.do` | `{sample}_TFP.csv` for fnd2non, non2non, full, post2004 |
| Figure 3: Event study outcomes | `src/exhibit/figure3.do` | `full_lnK.csv`, `full_has_intangible.csv`, `full_lnM.csv`, `full_lnWL.csv` |

## Dependency Graph Summary

<!-- openwiki: mermaid parse failed and this diagram was converted to a text fence so it does not break rendering. Fix the diagram source and restore the mermaid fence. Parser error: Heuristic: an unescaped angle bracket inside a label breaks rendering; rephrase the label. -->
```text
flowchart LR
    subgraph Raw["Raw Data"]
        R1["balance_sheet_80_22.dta"] --> B["balance.dta"]
        R2["ceo-panel.dta"] --> I["intervals.dta"]
        R2 --> MF["manager-facts.dta"]
    end

    subgraph Create["lib/create/ Data Wrangling"]
        I --> CP["ceo-panel.dta"]
        MF --> CP
        B --> U["unfiltered.dta"]
        CP --> U
        U --> AS["analysis-sample.dta<br/>(per variation)"]
    end

    subgraph Network["lib/create/ Network Analysis"]
        AS ==o E["edgelist.csv"]
        E --> GC["large_component_managers.csv<br/>(Julia)"]
    end

    subgraph Estimate["lib/estimate/ Estimation"]
        AS --> MV["manager_value.dta"]
        GC --> MV
        AS --> PL["placebo_samples.dta<br/>(per variation×sample)"]
        MV --> PL
        PL --> ES["event_study_outputs.csv<br/>(per sample×outcome)"]
    end

    subgraph Exhibit["src/exhibit/ Figures & Tables"]
        ES --> F2["Figure 2"]
        ES --> F3["Figure 3"]
        U --> T1["Table 1"]
        AS --> T2["Table 2"]
        MV --> SK["Skill histograms"]
    end

    subgraph Paper["LaTeX Compilation"]
        T1 --> PDF["paper.pdf"]
        T2 --> PDF
        F2 --> PDF
        F3 --> PDF
        SK --> PDF
    end
```

## Cross-Product Matrix Dimensions

The Makefile's `foreach` expansion creates build rules that scale combinatorially. The most important dimensions:

| Variable | Values | Count |
|----------|--------|-------|
| `ANALYSIS_VARIATIONS` | full, size1, size2, size3, size4, pre2000, post2000 | 7 |
| `SAMPLES` | full, one2one, twos, fnd2non, non2non, gender, nogender, gap, nogap | 9 |
| `OUTCOMES` (root Makefile) | lnK, lnWL, lnM, has_intangible | 4 |
| `OUTCOMES` (econometrics) | lnR, lnL, lnK, ROA, lnRL | 5 |
| Placebo DTA files | `ANALYSIS_VARIATIONS × SAMPLES` | 63 |
| Event study CSVs (application) | `SAMPLES × OUTCOMES` | 20 |

## Language Boundary

The pipeline crosses two language runtimes:

- **Stata 18.0**: All data processing, econometric estimation, event study, and exhibit generation. Required community-contributed packages: `reghdfe`, `estout`, `xt2treatments`, `e2frame`. Installed via `lib/util/install.do`.
- **Julia 1.10+**: Network analysis only. Packages: CSV, DataFrames, Graphs, SparseArrays. Scripts: `connected_component.jl`, `leverage.jl`. Both read from `temp/` and write back to `temp/`.

The boundary is maintained by Makefile dependencies — `temp/edgelist.csv` written by Stata, consumed by Julia; `temp/large_component_managers.csv` written by Julia, consumed by Stata.

## Key Design Invariants

1. **All scripts run from project root.** Relative paths like `temp/balance.dta` and `lib/create/balance.do` work only when the working directory is the repo root. Paper Makefiles `cd ../..` before invocation.

2. **Intermediate files are precious.** The root Makefile uses `.PRECIOUS:` to prevent `make` from deleting intermediate DTA files, since regeneration is costly (~2-4 hours total runtime).

3. **Person IDs live only in `intervals.dta`.** The firm-year panel datasets do not carry `person_id`; downstream scripts must re-expand intervals and join. This prevents accidental explosion of the firm-year panel when multiple CEOs share a year.

4. **`make data` is the full data pipeline entry point.** It produces `manager_value.dta` and all placebo samples. Paper exhibits and event study outputs require additional `make` invocations.

5. **Placebo construction is probabilistic.** `event_study_sample.do` uses random seed 1391 and sampling without replacement to draw control firms. Re-running with the same seed reproduces identical placebo assignments.
