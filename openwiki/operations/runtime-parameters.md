---
type: reference catalog
title: Runtime Parameters and Configuration
description: Catalog of all key configurable parameters across data processing, filtering, estimation, and simulation scripts, organized by subsystem.
tags: [runtime-parameters, configuration, event-study, monte-carlo, filtering, makefile]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-cbbdea468bbabc80cdc25e89
    resource: repo://lib/create/balance.do
  - id: openwiki-source-e6021cf24f8410c40aaf6ee1
    resource: repo://lib/create/connected_component.jl
  - id: openwiki-source-f85faafafeb554812fa0eed3
    resource: repo://lib/create/event_study_sample.do
  - id: openwiki-source-0f02924f1a872fc0ce9e8336
    resource: repo://lib/create/leverage.jl
  - id: openwiki-source-2a84a273bb200e9b22c6ecfa
    resource: repo://lib/create/montecarlo.do
  - id: openwiki-source-6c17ee820f3a743f1061bc3c
    resource: repo://lib/estimate/manager_value.do
  - id: openwiki-source-e9e02b9d834f8e298693cb09
    resource: repo://lib/estimate/setup_event_study.do
  - id: openwiki-source-7e4320e30e1e1d1a93089417
    resource: repo://lib/util/filter.do
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Runtime Parameters and Configuration

This page catalogs every configurable parameter across the codebase. Parameters are grouped by subsystem; each table shows the parameter name, its default value, the file that defines it, and its effect. Constants that are never varied at runtime (e.g. hard-coded column names) are omitted. Variable-selection lists used as Makefile iterators are included because they control the scope of analysis.

---

## 1. Makefile Build Iterators

Defined in [`/Makefile`](../../Makefile) as top-level `:=` variables. These are not parameters in the usual sense, but they govern which combinations of sample, variation, and outcome the build loop generates.

| Variable | Value | Purpose |
|---|---|---|
| `ANALYSIS_VARIATIONS` | `full size1 size2 size3 size4 pre2000 post2000` | Firm-size and time-period subsamples that flow through the entire pipeline. |
| `SAMPLES` | `full one2one twos fnd2non non2non gender nogender gap nogap` | CEO-transition-type subsamples used in placebo generation and event-study estimation. |
| `OUTCOMES` | `lnK lnWL lnM has_intangible` | Outcome variables passed to the estimation Do file. |
| `COMMIT_MAIN` | `HEAD` | Git commit hash for reproducible file extraction from main branch. |
| `COMMIT_PLACEBO` | `placebo` | Git commit hash for placebo-branch file extraction. |
| `COMMIT_EXPERIMENT` | `experiment/preferred` | Git commit hash for experiment-branch file extraction. |

The Makefile defines `$(foreach variation, $(ANALYSIS_VARIATIONS), ...)` loops that produce `temp/<variation>-analysis-sample.dta` and, via a generated rule, `temp/<variation>_placebo_<sample>.dta` for every combination of variation and sample.

---

## 2. Balance Sheet Data Processing

Source: [`/lib/create/balance.do`](../../lib/create/balance.do)

| Parameter | Default | Effect |
|---|---|---|
| `start_year` | `1992` | Earliest year for which balance-sheet observations are kept. |
| `end_year` | `2023` | Latest year for which balance-sheet observations are kept. |

Firm-years outside `[start_year, end_year]` are dropped immediately. The script also drops firm-years before a firm's first observation with non-missing core variables (sales, employment, tangible assets, materials, personnel expenses, assets), and any firm-year with missing core variables after that clean start.

---

## 3. Sample Filtering

Source: [`/lib/util/filter.do`](../../lib/util/filter.do)

This Do file is called by `analysis-sample.do` for each variation. It imposes a uniform set of quality filters before the variation-specific subsample is applied.

| Parameter | Default | Effect |
|---|---|---|
| `max_ceos_per_year` | `2` | Firms that ever have more than this many CEOs in a single year are dropped. |
| `max_ceo_spells` | `12` | Firms whose maximum CEO-spell count exceeds this threshold are dropped. |
| `min_firm_age` | `1` | Firm-years with `firm_age < 1` (the first year of a firm) are dropped. |
| `excluded_sectors` | `"9"` | Sector codes to exclude entirely (sector 9 = finance/insurance). |
| `min_employment` | `3` | Firms whose maximum employment ever falls below this threshold are dropped. |

Observation-level completeness filters then drop any remaining observation that is missing `lnR`, `ROA`, `lnL`, `lnK`, `lnRL`, or `export`.

### Sample Definitions (Variations)

These are the logical conditions applied at the end of `filter.do` via `` keep if ``sample'' ``:

| Variation | Filter condition |
|---|---|
| `full` | (no additional restriction: all observations passing the filters above) |
| `size1` | `employment <= 5` |
| `size2` | `employment > 5 & employment <= 10` |
| `size3` | `employment > 10 & employment <= 25` |
| `size4` | `employment > 25` |
| `pre2000` | `year <= 2000` |
| `post2000` | `year > 2000` |

---

## 4. Event Study Sample (Placebo Construction)

Source: [`/lib/create/event_study_sample.do`](../../lib/create/event_study_sample.do)

This script constructs the matched placebo sample. It receives `variation` and `sample` as command-line arguments.

| Parameter | Default | Effect |
|---|---|---|
| `TARGET_N_CONTROL` | `10` | Desired ratio of control (placebo) to treated observations. |
| `SEED` | `1391` | Random-number seed for sampling control firms and assigning placebo change years. |
| `min_obs_threshold` (global) | `1` | Minimum observations required before and after the change year. |
| `min_T` (global) | `1` | Minimum observations per spell to estimate fixed effects. |
| `max_n_ceo` (global) | `2` | Maximum number of CEOs per firm in the analysis sample. |
| `exact_match_on` (global) | `cohort sector max_size` | Variables for exact matching between treated and candidate control spells. |
| `fixed_effect` (global) | `ROA` | The dependent variable used for within-firm manager skill computation. |

### Sample Definitions

These are the logical conditions applied at the ``LIMIT SAMPLE HERE`` marker:

| Sample | Condition |
|---|---|
| `full` | `1` (no restriction) |
| `one2one` | `n_ceo1 == 1 & n_ceo2 == 1` |
| `twos` | `n_ceo1 == 2 \| n_ceo2 == 2` |
| `fnd2non` | `has_founder1 == 1 & has_founder2 == 0` |
| `non2non` | `has_founder1 == 0 & has_founder2 == 0` |
| `small` | `max_size == 1` |
| `large` | `max_size == 2` |
| `gap` | `(n_ceo1 == 1 & n_ceo2 == 1) & (age_diff > 10)` |
| `nogap` | `(n_ceo1 == 1 & n_ceo2 == 1) & (age_diff <= 10)` |
| `gender` | `n_ceo_male1 != n_ceo_male2` |
| `nogender` | `n_ceo_male1 == n_ceo_male2` |

Sampling procedure: control spells are drawn with probability `p = MULTIPLE * N_treated / n_control` where `MULTIPLE = TARGET_N_CONTROL / MEAN(N_treated)`, ensuring approximately `TARGET_N_CONTROL` controls per treated group. Placebo change years are then assigned proportionally to the observed `t0` distribution of treated spells.

---

## 5. Manager Value Estimation

Source: [`/lib/estimate/manager_value.do`](../../lib/estimate/manager_value.do)

| Parameter | Default | Effect |
|---|---|---|
| `within_firm_skill_min` | `-1` | Lower bound (in log points) for within-firm manager skill; values outside `[-1, 1]` are set to missing. |
| `within_firm_skill_max` | `1` | Upper bound (in log points) for within-firm manager skill. |
| `outcomes` | `lnR lnEBITDA lnL` | Outcome variables used in subsequent estimation steps (not directly used in this file beyond listing). |
| `controls` | `lnK foreign_owned has_intangible` | Control variables listed for reference. |
| `fixed_effect` | `ROA` | The dependent variable used when computing within-firm manager skill via `reghdfe`. |

The script computes `within_firm = mean(ROA)` by `(frame_id_numeric, person_id)`, demeaned by the first CEO's value, then truncates to `[within_firm_skill_min, within_firm_skill_max]`. It then runs `reghdfe ROA, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id)` to extract the manager fixed effects, which are saved to `temp/manager_value.dta`.

---

## 6. Event Study Estimation

Source: [`/lib/estimate/setup_event_study.do`](../../lib/estimate/setup_event_study.do)

This script prepares and optionally runs the event study. It receives `variation`, `sample`, `outcome`, and `montecarlo` as command-line arguments.

| Parameter | Default | Effect |
|---|---|---|
| `event_window_start` (global) | `-4` | Earliest event time relative to `change_year` (inclusive). |
| `event_window_end` (global) | `3` | Latest event time relative to `change_year` (inclusive). |
| `baseline_year` (global) | `-1` | Reference year for event-study normalization (year before the change). |
| `random_seed` (global) | `2181` | Seed for subsampling firms for performance (10% sampling at `sample=100` means 100% retention). |
| `sample` (global) | `100` | Percentage of firms to retain for analysis (set to 100 for full sample). |
| `cluster` (global) | `frame_id_numeric` | Variable for clustered standard errors. |
| `T_min` (global) | `1` | Minimum number of non-missing outcome observations per spell required to keep a firm. |

The script sub-samples firms when `sample < 100` using `random_seed`, joins the placebo data, restricts the panel to `[change_year + event_window_start, change_year + event_window_end]`, and drops firms that do not meet `T_min` in both CEO spells. When called with `montecarlo`, the analysis-sample join is skipped entirely.

---

## 7. Monte Carlo Simulation

Source: [`/lib/create/montecarlo.do`](../../lib/create/montecarlo.do)

A synthetic-data generator used to validate the placebo design under known parameters.

| Parameter | Default | Effect |
|---|---|---|
| `N_changes` | `10000` | Number of CEO-change events to simulate. |
| `hazard` | `0.2` | Hazard rate of CEO change; used as the rate parameter for the exponential distribution determining spell length. |
| `sigma_z` | `0.1` | Standard deviation of CEO ability (the true manager effect). |
| `half_normal` | `0.797885` | Mean of the half-normal distribution; `true_effect = half_normal * sigma_z`. |
| `true_effect` | `sigma_z * half_normal` | The true average treatment effect on the treated (ATET) implied by the model. |
| `sigma_epsilon0` | `0.05` | Standard deviation of TFP growth innovations for control firms (placebo=1). |
| `sigma_epsilon1` | `0.06` | Standard deviation of TFP growth innovations for treated firms (placebo=0). |
| `rho` | `0.97` | Autocorrelation coefficient for the TFP process. |
| `control_treated_ratio` | `9` | Number of placebo (control) synthetic firms generated per treated firm. |
| `T_max` | `20` | Maximum CEO spell length; spells exceeding this are discarded. |
| seed (hard-coded) | `2191` | Random-number seed (set separately from `SEED=1391` used in the placebo construction). |

Data-generating process: `TFP` follows an AR(1) with autocorrelation `rho` and innovation variance `sigma_epsilon0` (`sigma_epsilon1` for treated). The true manager effect `z` is drawn once per treated firm from `N(0, sigma_z^2)` and added to TFP for all years after the CEO change. The simulation verifies that the placebo estimator recovers zero mean ATET with variance approximately `sigma_z^2`.

---

## 8. Connected Component Analysis (Julia)

Source: [`/lib/create/connected_component.jl`](../../lib/create/connected_component.jl)

| Parameter | Default | Effect |
|---|---|---|
| `COMPONENT_SIZE_CUTOFF` | `30` | Minimum number of managers in a connected component for it to be included in the output. Components with fewer than this many manager nodes are discarded. |

The script reads the firm–manager edgelist, projects it onto a manager–manager graph, calls `connected_components`, and keeps only components whose node count is at least `COMPONENT_SIZE_CUTOFF`. The results (`person_id`, `component_id`, `component_size`) are written to `temp/large_component_managers.csv`.

---

## 9. Component Leverage Computation (Julia)

Source: [`/lib/create/leverage.jl`](../../lib/create/leverage.jl)

| Parameter | Default | Effect |
|---|---|---|
| `COMPONENT_RANK` (env var) | `"1"` | Rank of the connected component to analyse (1 = giant component, 2 = second largest, etc.). Passed via the `COMPONENT_RANK` environment variable. |

The script orders connected components by descending size, selects the component at rank `COMPONENT_RANK`, builds its subgraph, and computes edge leverages via `LeaveOut.jl`. Results are saved to `temp/edgelist_leverage.csv`.

---

## Summary of Parameter Interactions

1. **Makefile iterators** (`ANALYSIS_VARIATIONS`, `SAMPLES`, `OUTCOMES`) determine which combinations of subsample, transition type, and outcome are built.
2. **`balance.do`** (`start_year`, `end_year`) defines the raw-data window and produces `temp/balance.dta`.
3. **`filter.do`** (`max_ceos_per_year`, `max_ceo_spells`, `min_firm_age`, `min_employment`, `excluded_sectors`) + the variation-specific subsample condition produce `temp/<variation>-analysis-sample.dta`.
4. **`manager_value.do`** (`within_firm_skill_min`, `within_firm_skill_max`) produces manager fixed effects on the full sample.
5. **`event_study_sample.do`** (`TARGET_N_CONTROL`, `SEED`, `exact_match_on`, sample condition) constructs placebo data for every `(variation, sample)` pair.
6. **`setup_event_study.do`** (`event_window_start`, `event_window_end`, `baseline_year`, `random_seed`, `sample`, `T_min`) runs the final event-study regressions.
7. The Julia scripts (`connected_component.jl`, `leverage.jl`) influence the network structure used for manager-skill comparisons via `COMPONENT_SIZE_CUTOFF` and `COMPONENT_RANK`.
