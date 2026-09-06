---
type: concept
title: Manager Skill Estimation
description: Documents how manager quality (skill) is estimated via AKM-style two-way fixed effects, combining within-firm skill relative to the first CEO and between-firm skill estimated on a connected component of the manager-manager co-employment network.
tags: [manager-FE, AKM, connected-components, reghdfe, two-way-fixed-effects, manager-skill, ROA]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-e6021cf24f8410c40aaf6ee1
    resource: repo://lib/create/connected_component.jl
  - id: openwiki-source-f0ae5c512fbda36029c85f72
    resource: repo://lib/create/network-sample.do
  - id: openwiki-source-6c17ee820f3a743f1061bc3c
    resource: repo://lib/estimate/manager_value.do
  - id: openwiki-source-f4654182fa577f7165a11860
    resource: repo://lib/estimate/revenue_function.do
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Manager Skill Estimation

## Overview

Manager skill (also called manager value added or manager quality) is estimated as a two-component decomposition of firm performance. The estimation proceeds in two stages:

1. **Within-firm skill**: For each firm-manager pair, the mean of the performance outcome (ROA) is computed and normalized relative to the first CEO observed at that firm. This captures the performance contribution of a manager relative to their predecessor within the same firm.
2. **Between-firm (connected component) skill**: A two-way fixed effects regression using `reghdfe` with absorbent firm (`frame_id_numeric`) and manager (`person_id`) effects recovers manager skill comparable across firms — but only within the same connected component of the manager-manager co-employment network.

The complete estimation is implemented in [`lib/estimate/manager_value.do`](repo://lib/estimate/manager_value.do), which depends on the connected component infrastructure built by [`lib/create/connected_component.jl`](repo://lib/create/connected_component.jl) and integrated via [`lib/create/network-sample.do`](repo://lib/create/network-sample.do). The Makefile target is:

```makefile
temp/manager_value.dta: lib/estimate/manager_value.do \
    temp/full-analysis-sample.dta temp/intervals.dta \
    temp/large_component_managers.csv
    $(STATA) $<
```

## Inputs

| Input | Path | Source | Contents |
|-------|------|--------|----------|
| Analysis sample | `temp/analysis-sample.dta` | Stage 6 pipeline | Firm-year panel with ROA and firm attributes |
| CEO intervals | `temp/intervals.dta` | Stage 2 pipeline | Person-level CEO spells with start/end years |
| Large component managers | `temp/large_component_managers.csv` | Connected component Julia script | `person_id`, `component_id`, `component_size` for managers in components ≥ 30 |

## Person-Year Expansion

Because the analysis sample is a firm-year panel but the manager skill contribution is person-specific, the estimation first expands CEO spells to person-year resolution. The script [`lib/estimate/manager_value.do`](repo://lib/estimate/manager_value.do) performs:

```stata
use "temp/intervals.dta", clear
generate T = end_year - start_year + 1
expand T
bysort frame_id_numeric person_id spell: generate year = start_year + _n - 1
keep frame_id_numeric person_id year
duplicates drop
```

The expanded person-year file is then merged into the analysis sample via `joinby frame_id_numeric year`, creating a dataset with one observation per firm-year-manager combination. This permits computing within-firm manager averages and running the two-way FE regression at the firm-year level while maintaining the person-level identification.

## Stage 1: Within-Firm Manager Skill

### Computation

For each unique firm-manager pair (`frame_id_numeric` × `person_id`), the mean of the fixed effect outcome (`ROA`) is computed:

```stata
egen within_firm = mean(`fixed_effect'), by(frame_id_numeric person_id)
```

This captures the average firm performance during a given manager's tenure. However, performance levels differ across firms for reasons unrelated to the manager (e.g., industry, size, market position). To isolate the manager's contribution, the within-firm skill is normalized relative to the firm's first observed CEO:

```stata
egen first_ceo = mean(cond(ceo_spell == 1, within_firm, .)), by(frame_id_numeric)
replace within_firm = within_firm - first_ceo
```

After this normalization, `within_firm` measures the performance difference between a given manager and the first CEO of that firm. A positive value means the manager outperformed the first observed CEO; a negative value means underperformance.

### Winsorization Bounds

To limit the influence of extreme outliers, within-firm manager skill is winsorized to the interval `[-1, 1]` log points (parameters `within_firm_skill_min` and `within_firm_skill_max`):

```stata
local within_firm_skill_min -1
local within_firm_skill_max 1
...
replace within_firm = . if !inrange(within_firm, `within_firm_skill_min', `within_firm_skill_max')
```

Observations with `ceo_spell == 1` (the first CEO spell) are excluded from the within-firm analysis because their skill has no predecessor to compare against within the same firm.

### IQR Interpretation

The interquartile range (IQR) of within-firm manager skill is reported on the revenue/surplus contribution scale:

```stata
summarize within_firm if ceo_spell > 1, detail
display "IQR of within-firm variation in manager skill: " exp(r(p75) - r(p25))*100 - 100
```

The transformation `exp(IQR) * 100 - 100` converts log-point differences to percentage differences. In the actual run log ([`manager_value.log`](repo://manager_value.log#L308-L310)), the within-firm IQR is approximately 297%, indicating substantial dispersion in manager quality even within the same firm.

## Stage 2: Between-Firm (Connected Component) Manager Skill

### Two-Way Fixed Effects via reghdfe

The between-firm component is estimated using the high-dimensional fixed effects estimator `reghdfe`:

```stata
reghdfe `fixed_effect', absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id) keepsingletons
```

This decomposes ROA into a firm fixed effect (`firm_fixed_effect`) and a manager person effect (`manager_skill`). The `keepsingletons` option retains singleton observations (managers observed at only one firm, or firms with only one manager), which contribute to the within-firm identification but do not help link components.

The absorbed degrees of freedom output (from the log) shows:

| Absorbed FE | Categories | Redundant | Num. Coefs |
|-------------|-----------|-----------|------------|
| `frame_id_numeric` | 458,925 | 0 | 458,925 |
| `person_id` | 600,724 | 305,843 | 294,881 |

### Connected Component Normalization

Manager fixed effects from `reghdfe` are only identified up to a constant *within* each connected component. Across components, the level is arbitrary — managers in different components cannot be compared on the same scale. The estimation therefore normalizes manager skill to have mean zero **within the giant component** (the largest connected component, `component_id == 1`):

```stata
summarize manager_skill if giant_component == 1, detail
replace manager_skill = manager_skill - r(mean)
```

This sets the average manager skill in the giant component to zero, making all estimates interpretable as deviations from the giant component mean.

### Connected Component Restriction

The project defines two indicator variables that control which observations are used for between-manager comparisons:

| Variable | Definition | Meaning |
|----------|-----------|---------|
| `giant_component` | `component_id == 1` | Belongs to the largest connected component |
| `connected_components` | `component_size >= 30` | Belongs to any component of at least 30 managers |

These are defined in [`lib/create/network-sample.do`](repo://lib/create/network-sample.do) (lines 14-15):

```stata
generate byte giant_component = (component_id == 1)
generate byte connected_components = (component_size >= 30)
```

Managers with `component_id == 0` (those not in any component meeting the size threshold) receive `giant_component = 0` and `connected_components = 0`. The threshold of 30 (`COMPONENT_SIZE_CUTOFF` in the Julia script) filters out tiny components that would not support reliable between-manager comparisons.

From the tabulation in the log, component 1 (the giant component) contains 1,583,323 manager-year observations (25.23% of the sample). An additional 134 smaller components (IDs 2–135) each contain under 1,000 observations, confirming that the giant component dominates the connected estimation sample.

## Outputs

Two output files are produced:

### Spell-Level Output: `temp/manager_value_spell.dta`

```stata
collapse (firstnm) manager_skill, by(frame_id_numeric ceo_spell)
```

This collapses the manager skill estimate to the spell level (one observation per firm-CEO-spell combination). It is the primary input for the placebo-controlled event study, which merges these spell-level skill estimates into the event study sample. Person identifiers are dropped to avoid identification of individual managers in downstream analyses.

### Firm-Person-Level Output: `temp/manager_value.dta`

```stata
collapse (firstnm) firm_fixed_effect manager_skill component_id component_size, by(frame_id_numeric person_id)
```

This preserves the firm fixed effect, manager skill estimate, and component identifiers at the firm-person level. It is used for across-firm manager comparisons, skill distribution analysis, and any analysis requiring person-level identifiers.

## Statistical Outputs and Interpretation

### Within-Firm Skill Distribution

A histogram is saved to `output/figure/manager_skill_within.pdf` (Panel A), showing the distribution of `within_firm` for non-first CEO spells (`ceo_spell > 1`), after winsorization to `[-1, 1]`. The within-firm IQR of ~297% indicates large performance heterogeneity across managers even after controlling for firm fixed effects.

### Connected Component Skill Distribution

A histogram is saved to `output/figure/manager_skill_connected.pdf` (Panel B), showing the distribution of `manager_skill` from the two-way FE regression, normalized to zero mean in the giant component. The connected-component IQR (from the log: ~5,252%) is substantially larger than the within-firm IQR because it includes cross-firm variation — managers at better-performing firms receive higher skill estimates, and the firm fixed effect absorbs the permanent component of firm quality.

### Why the Two Components Differ

The two components answer different questions:

- **Within-firm skill** answers: "How does this manager perform relative to the firm's baseline (first CEO)?" It abstracts from firm-level heterogeneity but can be estimated on the full sample.
- **Between-firm (connected component) skill** answers: "How does this manager perform relative to other managers in the same network of labor market connections?" It enables cross-firm ranking but is valid only within a connected component.

The revenue function estimation in [`lib/estimate/revenue_function.do`](repo://lib/estimate/revenue_function.do) uses the same connected component infrastructure — Model 6 restricts estimation to `(giant_component == 1) | (connected_components == 1)` — ensuring that the production function estimates are consistent with the same identification domain as the manager skill estimates.

## Invariants and Failures

- **Across-component incomparability**: Manager fixed effects from different connected components cannot be compared. The normalization to giant-component mean zero only solves within-component identification. Merging or comparing estimates across components would introduce arbitrary level shifts.
- **Winsorization loss**: Extreme values of within-firm skill are set to missing. If a large fraction of observations fall outside `[-1, 1]`, the within-firm estimates may be uninformative. In the actual run, 821,548 observations were set to missing by the winsorization.
- **Singleton retention**: The `keepsingletons` option retains managers with only one spell and firms with only one manager. These observations contribute to firm fixed effects (or manager fixed effects via within-firm variation) but do not help identify the connected component structure.
- **Minimal component threshold**: The COMPONENT_SIZE_CUTOFF = 30 is a heuristic. Very small components (e.g., components 2–135, each with <1,000 manager-years) still pass the threshold but may contain too few managers for reliable cross-manager comparisons.
