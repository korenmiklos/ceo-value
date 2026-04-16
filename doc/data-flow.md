# CEO Value Research Project - Data Flow Pipeline

## 1. Raw Data Sources

- **Balance Sheet Data** (`input/merleg-LTS-2023/balance/balance_sheet_80_22.dta`)
  - Hungarian firm balance sheet records, 1980–2022
  - Contains firm identifiers, financial variables, ownership flags, industry codes
- **CEO Panel Data** (`input/manager-db-ceo-panel/ceo-panel.dta`)
  - Manager-firm-year registry with person IDs and firm IDs
  - Tracks CEO appointments and tenures across firms


## 2. CEO Tenure Interval Cleaning (`temp/intervals.dta`)

- **Input**: Raw CEO panel (`ceo-panel.dta`)
- **Script**: `lib/create/intervals.do` (+ `lib/util/potholes.do`)
- **Data Wrangling Steps**:
  - Keep only `frame_id_numeric`, `year`, `person_id`; drop duplicates and missing IDs
  - Fill potholes of 1–2 years in CEO spells (gap-filling via `potholes.do`)
    - Expand rows to fill 1–2 year gaps within a firm-person series
    - Recompute spell boundaries after gap-filling
    - Assert no remaining gaps ≤ 2 years
  - Collapse to actual intervals: `(firstnm) start_year`, `(max) end_year` by firm-person-spell
  - Limit to firms with ≤ 12 CEO spells (`max_ceo_spells`)
  - Create all pairwise interval combinations per firm via `joinby`
  - Classify interval relations using Allen's interval algebra (13 relations: before, meets, overlaps, during, etc.)
  - Clean overlapping/nested intervals:
    - Drop shorter intervals (≤ 2 years) when one contains/starts/finishes another
    - Truncate overlapping intervals when overlap length ≤ 2 years
  - Merge modifications back to original clean intervals; apply drops and truncations
  - Save cleaned intervals to `temp/intervals.dta`

---

## 3. Balance Sheet Processing (`temp/balance.dta`)

- **Input**: Raw balance sheet data
- **Script**: `lib/create/balance.do`
- **Data Wrangling Steps**:
  - Filter to years 1992–2022
  - Drop placeholder `frame_id` values; extract numeric firm ID from string prefix ("ft")
  - Keep core dimensions: firm ID, original ID, found year, year, industry codes, ownership flags
  - Keep core facts: sales, export, employment, assets, tangible assets, materials, wagebill, personnel expenses, intangible assets
  - Rename variables to standard names (e.g., `sales_clean` → `sales`, `emp` → `employment`)
  - Drop firm-years with missing core variables (sales, employment, tangible assets, materials, personnel expenses, assets)
  - Drop all firm-years before the first year with complete core data for each firm
  - Encode remaining missing values as 0 for financial variables
  - Adjust employment: add 1 and convert to integer
  - Compute EBITDA (`sales - personnel_expenses - materials`)
  - Compute capital stock: use lagged assets if available, otherwise `assets - EBITDA`
  - Save to `temp/balance.dta`

---

## 4. CEO Panel Construction (`temp/ceo-panel.dta`)

- **Input**: Cleaned intervals (`temp/intervals.dta`) + manager facts
- **Script**: `lib/create/ceo-panel.do`
- **Data Wrangling Steps**:
  - Expand intervals to firm-person-year panel (one row per year in each CEO spell)
  - Merge manager-firm facts and manager-level facts
  - Create CEO transition indicators: `someone_enters` (year == start_year), `someone_exits` (year == end_year)
  - Create derived flags: `foreign_name`, `founder` (manager_category == 1)
  - Collapse to firm-year level:
    - Count CEOs per firm-year (`n_ceo`)
    - Max flags: expat CEO, founder CEO, entry/exit indicators
    - Sum male CEO count
  - Compute lagged exit indicator and cumulative CEO spell counter
  - Keep firm-year panel with CEO spell, counts, and transition flags
  - Save to `temp/ceo-panel.dta`

---

## 5. Unfiltered Dataset (`temp/unfiltered.dta`)

- **Input**: Balance sheet (`temp/balance.dta`) + CEO panel (`temp/ceo-panel.dta`)
- **Script**: `lib/create/unfiltered.do` (+ `lib/util/industry.do`, `lib/util/variables.do`)
- **Data Wrangling Steps**:
  - Merge balance sheet and CEO panel (1:1 on firm-year), keeping only matched observations
  - Apply industry classification (`industry.do`):
    - Map TEAOR08 1-digit codes to 7 sector categories (Agriculture, Mining, Manufacturing, Wholesale/Retail/Transport, Telecom/Business Services, Construction, Nontradable Services, Finance)
    - Fill missing industry codes with firm-mode industry
  - Create derived variables (`variables.do`):
    - Log transformations: lnK, lnA, lnR, lnEBITDA, lnL, lnM, lnWL, lnKL, lnRL, lnMR, lnYL
    - Ratios: export share, intangible share, EBITDA share, ROA (winsorized at p1/p99)
    - Binary flags: exporter, has_intangible, exit
    - Firm-level aggregates: max employment, max CEO spell, early exporter, early size, max size
    - Firm age (capped at 20), cohort (3-year bins starting from 1989)
    - Quadratic terms (firm_age_sq)
  - Drop firms that never report a CEO (max_ceo_spell == 0)
  - Save to `temp/unfiltered.dta`

---

## 6. Analysis Sample (`temp/analysis-sample.dta`)

- **Input**: Unfiltered dataset (`temp/unfiltered.dta`)
- **Script**: `lib/create/analysis-sample.do` (+ `lib/util/filter.do`)
- **Data Wrangling Steps**:
  - Drop firm-years without a CEO (ceo_spell == 0)
  - Drop firms that ever have > 2 CEOs in a single year
  - Drop firms with > 12 CEO spells total
  - Drop firm-age 0 observations (incomplete first year)
  - Drop finance sector (sector == 9)
  - Drop firms that never reach ≥ 3 employees (min_employment threshold)
  - Clean up temporary aggregation variables
  - Save to `temp/analysis-sample.dta`

---

## 7. Firm-Manager Edgelist (`temp/edgelist.csv`)

- **Input**: Analysis sample (`temp/analysis-sample.dta`) + intervals (`temp/intervals.dta`)
- **Script**: `lib/create/edgelist.do`
- **Data Wrangling Steps**:
  - Extract unique firm IDs from analysis sample
  - Extract unique firm-person pairs from intervals
  - Merge to restrict edgelist to firms in the analysis sample
  - Export delimited CSV with `frame_id_numeric` and `person_id` columns
  - Save to `temp/edgelist.csv`

---

## 8. Connected Component Analysis (`temp/large_component_managers.csv`)

- **Input**: Edgelist (`temp/edgelist.csv`)
- **Script**: `lib/create/connected_component.jl`
- **Data Wrangling Steps**:
  - Read bipartite firm-manager edgelist (drop rows with missing person_id)
  - Project bipartite graph to manager-manager network via shared firms:
    - Build sparse bipartite incidence matrix B (firms × managers)
    - Compute projection P = B'B (manager co-employment matrix)
    - Remove self-loops (diagonal)
  - Find connected components in projected graph
  - Filter components with ≥ 30 managers (`COMPONENT_SIZE_CUTOFF`)
  - Sort components by size (descending)
  - Map component indices back to original person IDs
  - Write CSV with person_id, component_id, component_size
  - Save to `temp/large_component_managers.csv`

---

## 9. Manager Value Estimation (`temp/manager_value.dta`, `temp/manager_value_spell.dta`)

- **Input**: Analysis sample (`temp/analysis-sample.dta`) + intervals + connected components
- **Script**: `lib/estimate/manager_value.do` (+ `lib/create/network-sample.do`)
- **Data Wrangling Steps**:
  - Expand intervals to firm-person-year panel; merge with analysis sample via `joinby`
  - Create connected component indicator (giant component flag, component ID, component size)
  - Compute within-firm manager skill:
    - Mean ROA by firm-person; subtract first CEO's within-firm skill
    - Winsorize within-firm skill to [-1, 1] range
  - Estimate two-way fixed effects model:
    - `reghdfe ROA, absorb(frame_id_numeric person_id)`
    - Extract firm fixed effects and manager skill coefficients
  - Normalize manager skill to giant component mean = 0
  - Generate skill distribution histograms (within-firm and connected component)
  - Collapse to spell-level: manager skill by firm-spell → `temp/manager_value_spell.dta`
  - Collapse to firm-person level: firm FE, manager skill, component info → `temp/manager_value.dta`

---

## 10. Placebo Event Study Samples (`temp/placebo_full.dta`, `temp/placebo_one2one.dta`, `temp/placebo_twos.dta`)

- **Input**: Analysis sample + intervals + manager value estimates
- **Script**: `lib/create/event_study_sample.do`
- **Data Wrangling Steps** (per sample specification):
  - Merge manager skill estimates onto firm-person-year panel
  - Restrict to firms with ≤ 2 CEOs; keep clean CEO changes only
  - Collapse to spell-level: mean manager skill, observation count, change year, window bounds
  - Drop spells with missing skill or insufficient observations
  - Keep only firms with consecutive spells (exclude single-spell firms)
  - Duplicate intermediate spells (before + after perspectives)
  - Reshape to wide format: spell 1 and spell 2 side-by-side
  - Apply sample filter (full, one2one, twos, fnd2non, non2non, etc.)
  - Assign unique fake IDs to treated firms
  - Build control pool:
    - Collapse treated firms by matching strata (cohort, sector, max_size, window bounds, t0)
    - Reshape to wide: count of treated firms by t0 position
    - Compute sampling probability to achieve 10:1 control-to-treated ratio
  - Generate placebo transitions:
    - Loop over cohorts; joinby matching strata to candidate control firms
    - Restrict to controls with windows weakly larger than event window
    - Sample controls with probability proportional to target ratio
    - Assign placebo change year by sampling t0 distribution from treated firms
    - Compute sampling weights (N_treated / n_control)
  - Append placebo firms to treated firms
  - Verify balance: tabulate placebo counts (weighted and unweighted)
  - Compute pre/post window lengths (T1, T2)
  - Keep core variables: fake_id, placebo, frame_id_numeric, window bounds, change year, CEO spell, weight
  - Save to `temp/placebo_{sample}.dta`

---

## Dependency Graph

```
Raw Balance Sheet ──────────────────────────────────────────────┐
                                                                ↓
Raw CEO Panel ──→ intervals.dta ──→ ceo-panel.dta ──→ unfiltered.dta ──→ analysis-sample.dta ──┬──→ edgelist.csv ──→ large_component_managers.csv
                                                                                               │
                                                                                               ├──→ manager_value.dta / manager_value_spell.dta
                                                                                               │
                                                                                               └──→ placebo_{sample}.dta (full, one2one, twos)
```

---

## Key Intermediate Files

| File | Description | Generated By |
|------|-------------|--------------|
| `temp/intervals.dta` | Cleaned CEO tenure intervals with gap-filling | `intervals.do` |
| `temp/balance.dta` | Processed balance sheet + tax data | `balance.do` |
| `temp/ceo-panel.dta` | Firm-year CEO panel with spell counts | `ceo-panel.do` |
| `temp/unfiltered.dta` | Merged dataset with all variables, no sample restrictions | `unfiltered.do` |
| `temp/analysis-sample.dta` | Final analytical dataset with sample filters applied | `analysis-sample.do` |
| `temp/edgelist.csv` | Firm-manager bipartite graph edge list | `edgelist.do` |
| `temp/large_component_managers.csv` | Managers in connected components (≥30 nodes) | `connected_component.jl` |
| `temp/manager_value.dta` | Manager skill estimates (two-way FE) | `manager_value.do` |
| `temp/manager_value_spell.dta` | Spell-level manager skill | `manager_value.do` |
| `temp/placebo_{sample}.dta` | Placebo-controlled event study samples | `event_study_sample.do` |
