---
type: architecture
title: Data Pipeline Architecture
description: End-to-end data flow mapping 10+ stages from raw balance sheet and CEO panel inputs through intermediate datasets to final estimation outputs, including Makefile targets, script locations, and file formats.
tags: [data-pipeline, data-flow, makefile, reproducibility]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-370ce04987186c8aa3a647f0
    resource: repo://doc/data-flow.md
  - id: openwiki-source-46db84383d79696b4d341df2
    resource: repo://lib/create/analysis-sample.do
  - id: openwiki-source-cbbdea468bbabc80cdc25e89
    resource: repo://lib/create/balance.do
  - id: openwiki-source-4449fa522ff800d1a56ff655
    resource: repo://lib/create/ceo-panel.do
  - id: openwiki-source-e6021cf24f8410c40aaf6ee1
    resource: repo://lib/create/connected_component.jl
  - id: openwiki-source-93335dee3bc8c938e1de8d74
    resource: repo://lib/create/edgelist.do
  - id: openwiki-source-f85faafafeb554812fa0eed3
    resource: repo://lib/create/event_study_sample.do
  - id: openwiki-source-b7cf126704af8528032e0799
    resource: repo://lib/create/intervals.do
  - id: openwiki-source-f0ae5c512fbda36029c85f72
    resource: repo://lib/create/network-sample.do
  - id: openwiki-source-35a7a12c9c57a0cfc575c422
    resource: repo://lib/create/unfiltered.do
  - id: openwiki-source-f626faeec630004c3392a141
    resource: repo://lib/estimate/event_study.do
  - id: openwiki-source-6c17ee820f3a743f1061bc3c
    resource: repo://lib/estimate/manager_value.do
  - id: openwiki-source-f4654182fa577f7165a11860
    resource: repo://lib/estimate/revenue_function.do
  - id: openwiki-source-e9e02b9d834f8e298693cb09
    resource: repo://lib/estimate/setup_event_study.do
  - id: openwiki-source-7e4320e30e1e1d1a93089417
    resource: repo://lib/util/filter.do
  - id: openwiki-source-5ad001584f1fe973e141a805
    resource: repo://lib/util/industry.do
  - id: openwiki-source-7d23136d63bcf19dc8ef8bd6
    resource: repo://lib/util/potholes.do
  - id: openwiki-source-39210005e2ad7196bdd39ec6
    resource: repo://lib/util/variables.do
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Data Pipeline Architecture

The CEO Value Research Project implements a multi-stage data pipeline (10+ stages) that transforms two raw input sources — Hungarian balance sheet records and a manager-firm-year CEO registry — into estimation-ready datasets for a placebo-controlled event study design. Every stage has a documented Makefile target, a dedicated creation script, and an intermediate file preserved as a `.PRECIOUS` artifact.

A detailed prose walkthrough of each stage appears in [`doc/data-flow.md`](repo://doc/data-flow.md).

---

## Raw Data Sources

| Source | Path | Contents |
|--------|------|----------|
| Balance Sheet | `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta` | Hungarian firm balance sheet records, 1980–2022: firm IDs, financial variables, ownership flags, industry codes |
| CEO Panel | `input/manager-db-ceo-panel/ceo-panel.dta` | Manager-firm-year registry with person IDs, firm IDs, CEO appointment tenures |
| Manager Facts | derived from CEO Panel | `temp/manager-facts.dta` (person-level: gender, birth year, Hungarian name flag) and `temp/manager-firm-facts.dta` (firm-person-level: manager category, ownership) |

**File format:** All raw inputs are Stata `.dta` binaries.

---

## Stage-by-Stage Pipeline

### Stage 1: Balance Sheet Processing

| Property | Value |
|----------|-------|
| **Make target** | `temp/balance.dta` |
| **Script** | [`lib/create/balance.do`](repo://lib/create/balance.do) |
| **Input** | `input/merleg-LTS-2023/balance/balance_sheet_80_22.dta` |
| **Format** | Stata `.dta` |

Steps:
1. Filter to years 1992–2022
2. Drop placeholder `frame_id` values; extract numeric firm ID from string prefix "ft"
3. Keep core dimensions (firm ID, year, industry codes, ownership flags) and facts (sales, export, employment, assets, tangible assets, materials, wagebill, personnel expenses, intangible assets)
4. Rename variables to standard names
5. Drop firm-years with missing core variables (sales, employment, tangible assets, materials, personnel expenses, assets)
6. Drop all firm-years before the first year with complete core data per firm
7. Encode remaining missing values as 0 for financial variables
8. Adjust employment (add 1, convert to integer)
9. Compute EBITDA (`sales - personnel_expenses - materials`) and capital stock (lagged assets if available, else `assets - EBITDA`)

### Stage 2: CEO Tenure Interval Cleaning

| Property | Value |
|----------|-------|
| **Make target** | `temp/intervals.dta` |
| **Script** | [`lib/create/intervals.do`](repo://lib/create/intervals.do) + [`lib/util/potholes.do`](repo://lib/util/potholes.do) |
| **Input** | `input/manager-db-ceo-panel/ceo-panel.dta` |
| **Format** | Stata `.dta` |

Steps:
1. Keep `frame_id_numeric`, `year`, `person_id`; drop duplicates and missing IDs
2. **Pothole filling**: fill 1–2 year gaps in CEO spells using [`lib/util/potholes.do`](repo://lib/util/potholes.do) by expanding rows, then assert no gaps ≤ 2 remain
3. Compute spell boundaries: collapse to `start_year` / `end_year` by firm-person-spell
4. Limit to firms with ≤ 12 CEO spells (`max_ceo_spells`)
5. Create all pairwise interval combinations per firm via `joinby`
6. Classify interval relations using **Allen's interval algebra** (13 relations: before, meets, overlaps, during, starts, finishes, equal, finished_by, contains, started_by, overlapped_by, met_by, after)
7. Clean overlapping/nested intervals: drop shorter intervals (≤ 2 years) when one contains/starts/finishes another; truncate overlapping intervals when overlap length ≤ 2 years
8. Merge modifications back, apply drops and truncations

### Stage 3: CEO Facts Extraction

| Property | Value |
|----------|-------|
| **Make target** | `temp/manager-firm-facts.dta`, `temp/manager-facts.dta` |
| **Script** | [`lib/create/manager-facts.do`](repo://lib/create/manager-facts.do) |
| **Input** | `input/manager-db-ceo-panel/ceo-panel.dta` |
| **Format** | Stata `.dta` |

Splits the raw CEO panel into two lookup tables:
- **Manager-firm facts** (`temp/manager-firm-facts.dta`): firm-person-level attributes (manager category, ownership)
- **Manager facts** (`temp/manager-facts.dta`): person-level attributes (male, birth_year, hungarian_name indicator)

### Stage 4: CEO Panel Construction

| Property | Value |
|----------|-------|
| **Make target** | `temp/ceo-panel.dta` |
| **Script** | [`lib/create/ceo-panel.do`](repo://lib/create/ceo-panel.do) |
| **Inputs** | `temp/intervals.dta`, `temp/manager-firm-facts.dta`, `temp/manager-facts.dta` |
| **Format** | Stata `.dta` |

Steps:
1. Expand intervals to firm-person-year panel (one row per year in each CEO spell)
2. Merge manager-firm facts and person-level facts
3. Create CEO transition indicators: `someone_enters` (year == start_year), `someone_exits` (year == end_year)
4. Create derived flags: `foreign_name` (1 - hungarian_name), `founder` (manager_category == 1)
5. Collapse to firm-year level: count CEOs (`n_ceo`), max flags (expat, founder, entry/exit), sum male CEO count
6. Compute lagged exit indicator and cumulative CEO spell counter
7. Keep firm-year panel with CEO spell, counts, and transition flags

### Stage 5: Merged Unfiltered Dataset

| Property | Value |
|----------|-------|
| **Make target** | `temp/unfiltered.dta` |
| **Script** | [`lib/create/unfiltered.do`](repo://lib/create/unfiltered.do) + [`lib/util/industry.do`](repo://lib/util/industry.do) + [`lib/util/variables.do`](repo://lib/util/variables.do) |
| **Inputs** | `temp/balance.dta`, `temp/ceo-panel.dta` |
| **Format** | Stata `.dta` |

Steps:
1. Merge balance sheet and CEO panel 1:1 on firm-year, keeping only matched observations
2. **Industry classification** ([`lib/util/industry.do`](repo://lib/util/industry.do)): map TEAOR08 1-digit codes to 7 sector categories (Agriculture, Mining, Manufacturing, Wholesale/Retail/Transport, Telecom/Business Services, Construction, Nontradable Services, Finance); fill missing with firm-mode industry
3. **Variable creation** ([`lib/util/variables.do`](repo://lib/util/variables.do)):
   - Log transformations: `lnK`, `lnA`, `lnR`, `lnEBITDA`, `lnL`, `lnM`, `lnWL`, `lnKL`, `lnRL`, `lnMR`, `lnYL`
   - Ratios: export share, intangible share, EBITDA share, ROA (winsorized at p1/p99)
   - Binary flags: exporter, has_intangible, exit
   - Firm-level aggregates: max employment, max CEO spell, early exporter, early size, max size
   - Firm age (capped at 20), cohort (3-year bins from 1989), quadratic terms
4. Drop firms that never report a CEO (`max_ceo_spell == 0`)

### Stage 6: Analysis Sample (with Variations)

| Property | Value |
|----------|-------|
| **Make target** | `temp/{variation}-analysis-sample.dta` for `variation` in `{full, size1, size2, size3, size4, pre2000, post2000}` |
| **Script** | [`lib/create/analysis-sample.do`](repo://lib/create/analysis-sample.do) + [`lib/util/filter.do`](repo://lib/util/filter.do) |
| **Input** | `temp/unfiltered.dta` |
| **Format** | Stata `.dta` |

The `analysis-sample.do` script takes a variation argument (e.g., `full`, `size1`, `pre2000`) and applies the corresponding filter from [`lib/util/filter.do`](repo://lib/util/filter.do). The **base filters** applied in all variations are:

1. Drop firm-years without a CEO (`ceo_spell == 0`)
2. Drop firms that ever have > 2 CEOs in a single year
3. Drop firms with > 12 CEO spells total
4. Drop firm-age 0 observations (incomplete first year)
5. Drop finance sector
6. Drop firms that never reach ≥ 3 employees

**Sample variations** (`lib/util/filter.do`, lines 1–13) further subset by:
- `full` — no additional restriction
- `size1`–`size4` — employment size bins (≤5, 5–10, 10–25, >25)
- `pre2000`, `post2000` — year cutoffs

### Stage 7: Firm-Manager Edgelist

| Property | Value |
|----------|-------|
| **Make target** | `temp/edgelist.csv` |
| **Script** | [`lib/create/edgelist.do`](repo://lib/create/edgelist.do) |
| **Inputs** | `temp/full-analysis-sample.dta`, `temp/intervals.dta` |
| **Format** | CSV (no header by default; two columns: `frame_id_numeric`, `person_id`) |

Steps:
1. Extract unique firm IDs from the `full` analysis sample
2. Extract unique firm-person pairs from `temp/intervals.dta`
3. Merge to restrict edgelist to firms in the analysis sample
4. Export delimited CSV

### Stage 8: Connected Component Analysis

| Property | Value |
|----------|-------|
| **Make target** | `temp/large_component_managers.csv` |
| **Script** | [`lib/create/connected_component.jl`](repo://lib/create/connected_component.jl) |
| **Input** | `temp/edgelist.csv` |
| **Format** | CSV (columns: `person_id`, `component_id`, `component_size`) |

Steps (Julia implementation):
1. Read bipartite firm-manager edgelist (drop rows with missing `person_id`)
2. Project bipartite graph to manager-manager network via shared firms:
   - Build sparse bipartite incidence matrix **B** (firms × managers)
   - Compute projection **P = B'B** (manager co-employment matrix)
   - Remove self-loops (diagonal)
3. Find connected components in projected graph
4. Filter components with ≥ 30 managers (`COMPONENT_SIZE_CUTOFF = 30`)
5. Sort components by size (descending), map indices back to original person IDs
6. Write CSV with `person_id`, `component_id`, `component_size`

A companion script, [`lib/create/leverage.jl`](repo://lib/create/leverage.jl), computes leverage centrality for each firm-manager edge in the giant component, producing `temp/edgelist_leverage.csv`.

### Stage 9: Manager Value Estimation

| Property | Value |
|----------|-------|
| **Make target** | `temp/manager_value.dta`, `temp/manager_value_spell.dta` |
| **Script** | [`lib/estimate/manager_value.do`](repo://lib/estimate/manager_value.do) + [`lib/create/network-sample.do`](repo://lib/create/network-sample.do) |
| **Inputs** | `temp/full-analysis-sample.dta`, `temp/intervals.dta`, `temp/large_component_managers.csv` |
| **Format** | Stata `.dta` |

Steps:
1. Expand intervals to firm-person-year panel; merge with analysis sample via `joinby`
2. Create connected component indicator ([`lib/create/network-sample.do`](repo://lib/create/network-sample.do)):
   - Import `large_component_managers.csv`, merge component IDs
   - Define `giant_component` (component_id == 1) and `connected_components` (size ≥ 30)
3. Compute **within-firm manager skill**: mean ROA by firm-person; subtract first CEO's within-firm skill; winsorize to [-1, 1]
4. Estimate two-way fixed effects model: `reghdfe ROA, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id)`
5. Normalize manager skill to giant component mean = 0
6. Generate skill distribution histograms (within-firm and connected component)
7. Outputs:
   - `temp/manager_value_spell.dta` — collapsed to spell-level: `manager_skill` by `frame_id_numeric`, `ceo_spell`
   - `temp/manager_value.dta` — collapsed to firm-person level: `firm_fixed_effect`, `manager_skill`, `component_id`, `component_size`

### Stage 10: Placebo Event Study Samples

| Property | Value |
|----------|-------|
| **Make target** | `temp/{variation}_placebo_{sample}.dta` for all `variation` × `sample` combinations |
| **Script** | [`lib/create/event_study_sample.do`](repo://lib/create/event_study_sample.do) |
| **Inputs** | `temp/{variation}-analysis-sample.dta`, `temp/intervals.dta`, `temp/manager_value.dta`, `temp/manager-facts.dta` |
| **Format** | Stata `.dta` |

Generates placebo-controlled event study datasets for 11 sample specifications: `full`, `one2one`, `twos`, `fnd2non`, `non2non`, `gender`, `nogender`, `gap`, `nogap`, `small`, `large`.

Steps:
1. Expand intervals to firm-person-year panel; merge analysis sample, manager value estimates, and manager facts
2. Restrict to firms with ≤ 2 CEOs; keep clean CEO changes only
3. Collapse to spell-level: mean manager skill, observation count, change year, window bounds
4. Drop spells with missing skill or insufficient observations
5. Keep only firms with consecutive spells (exclude single-spell firms)
6. Duplicate intermediate spells (before + after perspectives), reshape to wide format (spell 1 and spell 2 side-by-side)
7. Apply sample filter: `full`, `one2one` (single-CEO spells), `twos` (dual-CEO spells), `fnd2non` (founder to non-founder transitions), `non2non`, `gender`/`nogender`, `gap`/`nogap`
8. Assign unique `fake_id` to treated firms
9. **Build control pool**:
   - Collapse treated firms by matching strata (cohort, sector, max_size, window bounds, t0)
   - Compute sampling probability to achieve 10:1 control-to-treated ratio
   - Loop over cohorts; `joinby` matching strata to candidate control firms
   - Restrict to controls with windows weakly larger than event window
   - Sample controls with probability proportional to target ratio
   - Assign placebo change year by sampling t0 distribution from treated firms
   - Compute sampling weights (N_treated / n_control)
10. Append placebo firms to treated firms; verify balance
11. Compute pre/post window lengths (`T1`, `T2`)
12. Keep core variables: `fake_id`, `placebo`, `frame_id_numeric`, `window_start`, `change_year`, `ceo_spell`, `window_end`, `weight`

### Stage 11: Estimation Scripts

The final estimation stage consumes the placebo samples and analysis samples to produce results. Key scripts:

| Script | Purpose | Inputs |
|--------|---------|--------|
| [`lib/estimate/setup_event_study.do`](repo://lib/estimate/setup_event_study.do) | Loads placebo data, merges with analysis sample, assigns CEO spells, computes fake manager skill | `temp/{variation}-analysis-sample.dta`, `temp/{variation}_placebo_{sample}.dta` |
| [`lib/estimate/event_study.do`](repo://lib/estimate/event_study.do) | Runs `xt2denoise` event study estimation with denoised/naive coefficients, covariance, and variance decomposition | Output of `setup_event_study.do` |
| [`lib/estimate/event_study_atet.do`](repo://lib/estimate/event_study_atet.do) | ATET-focused event study variant with industry-year demeaning | Same as `event_study.do` |
| [`lib/estimate/revenue_function.do`](repo://lib/estimate/revenue_function.do) | Revenue function estimation (Issue #14 specifications): 6 models with varying fixed effects and controls | `temp/analysis-sample.dta` |
| [`lib/estimate/manager_value.do`](repo://lib/estimate/manager_value.do) | Manager value estimation (Stage 9 above) | Stage 6 & 8 outputs |
| [`lib/estimate/balance.do`](repo://lib/estimate/balance.do) | Balance estimation (alternative analysis) | `temp/full-analysis-sample.dta` |
| [`lib/test/placebo.do`](repo://lib/test/placebo.do) | Placebo test diagnostics | Placebo `.dta` files |

The Makefile target for the complete data pipeline is:

```makefile
data: temp/manager_value.dta \
    $(foreach sample, $(SAMPLES),$(foreach variation, $(ANALYSIS_VARIATIONS), temp/$(variation)_placebo_$(sample).dta))
```

Where `SAMPLES = {full, one2one, twos, fnd2non, non2non, gender, nogender, gap, nogap}` and `ANALYSIS_VARIATIONS = {full, size1, size2, size3, size4, pre2000, post2000}`.

---

## Dependency Graph

```mermaid
flowchart TB
    subgraph Raw["Raw Data Sources"]
        BS[balance_sheet_80_22.dta]
        CP[ceo-panel.dta]
    end

    subgraph Stage1["Stage 1: Balance Sheet"]
        B[temp/balance.dta]
    end

    subgraph Stage2["Stage 2: Intervals"]
        INT[temp/intervals.dta]
    end

    subgraph Stage3["Stage 3: Manager Facts"]
        MFF[temp/manager-firm-facts.dta]
        MF[temp/manager-facts.dta]
    end

    subgraph Stage4["Stage 4: CEO Panel"]
        CEO[temp/ceo-panel.dta]
    end

    subgraph Stage5["Stage 5: Merge + Variables"]
        UNF[temp/unfiltered.dta]
    end

    subgraph Stage6["Stage 6: Analysis Sample"]
        AS[temp/{variation}-analysis-sample.dta]
    end

    subgraph Stage7["Stage 7: Edgelist"]
        EL[temp/edgelist.csv]
    end

    subgraph Stage8["Stage 8: Connected Components"]
        CC[temp/large_component_managers.csv]
        LEV[temp/edgelist_leverage.csv]
    end

    subgraph Stage9["Stage 9: Manager Value"]
        MV[temp/manager_value.dta]
        MVS[temp/manager_value_spell.dta]
    end

    subgraph Stage10["Stage 10: Placebo Samples"]
        PS[temp/{variation}_placebo_{sample}.dta]
    end

    subgraph Stage11["Stage 11: Estimation"]
        ES[event_study.do / event_study_atet.do]
        RF[revenue_function.do]
        BAL[balance.do]
    end

    BS --> B
    CP --> INT
    CP --> MFF
    MFF --> CEO
    MF --> CEO
    INT --> CEO
    B --> UNF
    CEO --> UNF
    UNF --> AS
    INT --> EL
    AS --> EL
    EL --> CC
    EL --> LEV
    AS --> MV
    INT --> MV
    CC --> MV
    AS --> PS
    INT --> PS
    MV --> PS
    MF --> PS
    AS --> ES
    AS --> RF
    AS --> BAL
    PS --> ES
    MV --> ES
```

---

## Key Intermediate Files

| File | Format | Description | Generated By | Make Target |
|------|--------|-------------|--------------|-------------|
| `temp/balance.dta` | Stata `.dta` | Processed balance sheet with core financial variables | `balance.do` | `temp/balance.dta` |
| `temp/intervals.dta` | Stata `.dta` | Cleaned CEO tenure intervals with Allen interval algebra | `intervals.do` | `temp/intervals.dta` |
| `temp/manager-facts.dta` | Stata `.dta` | Person-level manager attributes | `manager-facts.do` | `temp/manager-facts.dta` |
| `temp/manager-firm-facts.dta` | Stata `.dta` | Firm-person-level manager attributes | `manager-facts.do` | `temp/manager-firm-facts.dta` |
| `temp/ceo-panel.dta` | Stata `.dta` | Firm-year CEO panel with spell counts and transitions | `ceo-panel.do` | `temp/ceo-panel.dta` |
| `temp/unfiltered.dta` | Stata `.dta` | Merged dataset with all variables, no sample restrictions | `unfiltered.do` | `temp/unfiltered.dta` |
| `temp/{variation}-analysis-sample.dta` | Stata `.dta` | Final analytical dataset with sample filters applied | `analysis-sample.do` | `temp/%-analysis-sample.dta` |
| `temp/edgelist.csv` | CSV | Bipartite firm-manager edgelist | `edgelist.do` | `temp/edgelist.csv` |
| `temp/large_component_managers.csv` | CSV | Managers in connected components (≥30 nodes) | `connected_component.jl` | `temp/large_component_managers.csv` |
| `temp/edgelist_leverage.csv` | CSV | Leverage centrality per firm-manager edge | `leverage.jl` | `temp/edgelist_leverage.csv` |
| `temp/manager_value.dta` | Stata `.dta` | Manager skill estimates (two-way FE) at firm-person level | `manager_value.do` | `temp/manager_value.dta` |
| `temp/manager_value_spell.dta` | Stata `.dta` | Manager skill at spell level | `manager_value.do` | `temp/manager_value_spell.dta` |
| `temp/revenue_models.ster` | Stata `.ster` | Stored revenue function estimates | `revenue_function.do` | `temp/revenue_models.ster` |
| `temp/{variation}_placebo_{sample}.dta` | Stata `.dta` | Placebo-controlled event study samples | `event_study_sample.do` | `temp/{variation}_placebo_{sample}.dta` |

---

## Precious Intermediate Preservation

The Makefile declares these intermediate files as `.PRECIOUS` to prevent `make` from automatically deleting them after downstream targets complete. The full list is defined in the `PRECIOUS_FILES` variable (Makefile, lines 24–29), covering all `.dta` and `.csv` intermediates across all sample/variation combinations.

---

## Runtime Parameters

The pipeline is parameterized by several constants that must remain consistent across stages:

| Parameter | Value | Defined In | Purpose |
|-----------|-------|------------|---------|
| `max_ceo_spells` | 12 | `intervals.do`, `filter.do` | Maximum CEO spells per firm |
| `max_ceos_per_year` | 2 | `filter.do` | Maximum CEOs per firm-year |
| `min_employment` | 3 | `filter.do` | Minimum employment threshold |
| `COMPONENT_SIZE_CUTOFF` | 30 | `connected_component.jl` | Minimum component size for analysis |
| `TARGET_N_CONTROL` | 10 | `event_study_sample.do` | Target control-to-treated ratio |
| `SEED` | 1391 | `event_study_sample.do` | Random seed for placebo sampling |
| `event_window_start` | -4 | `setup_event_study.do` | Event study pre-period window |
| `event_window_end` | 3 | `setup_event_study.do` | Event study post-period window |
| `baseline_year` | -1 | `setup_event_study.do` | Baseline event year |

For a full description of runtime parameters and their configuration, see [/openwiki/operations/runtime-parameters.md](/openwiki/operations/runtime-parameters.md).

---

## Related Pages

- [/openwiki/concepts/connected-network.md](/openwiki/concepts/connected-network.md) — Connected component graph concepts underlying the manager network projection
- [/openwiki/operations/runtime-parameters.md](/openwiki/operations/runtime-parameters.md) — Pipeline parameter configuration and consistency requirements
- [/openwiki/workflows/placebo-construction.md](/openwiki/workflows/placebo-construction.md) — Detailed placebo transition generation methodology
- [/openwiki/workflows/sampling-filtering.md](/openwiki/workflows/sampling-filtering.md) — Sample variation definitions and filtering criteria
