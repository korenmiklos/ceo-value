---
type: system architecture
title: Econometric Estimation Subsystem
description: Documents the estimation scripts (surplus share, revenue function, manager value, event study, variance decomposition, ANOVA) that transform samples into econometric results for the CEO value project.
tags: [estimation, event-study, placebo-design, manager-value, variance-decomposition, stata]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T19:57:00.087Z
sources:
  - id: openwiki-source-f85faafafeb554812fa0eed3
    resource: repo://lib/create/event_study_sample.do
  - id: openwiki-source-2a84a273bb200e9b22c6ecfa
    resource: repo://lib/create/montecarlo.do
  - id: openwiki-source-48d46b9352692a1c5ba81912
    resource: repo://lib/estimate/bloom_autonomy_analysis.do
  - id: openwiki-source-f626faeec630004c3392a141
    resource: repo://lib/estimate/event_study.do
  - id: openwiki-source-6c17ee820f3a743f1061bc3c
    resource: repo://lib/estimate/manager_value.do
  - id: openwiki-source-f4654182fa577f7165a11860
    resource: repo://lib/estimate/revenue_function.do
  - id: openwiki-source-e9e02b9d834f8e298693cb09
    resource: repo://lib/estimate/setup_event_study.do
  - id: openwiki-source-3ce4cfc25b9848c4c80a32e6
    resource: repo://lib/estimate/xt2var.do
  - id: openwiki-source-012f2c78e3b1446dfc35803f
    resource: repo://Makefile
  - id: openwiki-source-8b895ea3442e90ba82ba7276
    resource: repo://surplus.log
generated: { by: "openwiki/0.5.0", at: "2026-09-06T19:57:00.087Z" }
---

# Econometric Estimation Subsystem

The estimation subsystem transforms prepared samples (see [/openwiki/architecture/pipeline.md]) into econometric results: surplus shares, revenue function parameters, manager fixed effects, and placebo-controlled event-study estimates. It is the core analytical engine of the CEO value project.

## Architecture Overview

Estimations are organized as a sequential pipeline, with each stage consuming outputs from the previous stage:

```
analysis-sample.dta
    │
    ▼
surplus.do ──────────────────────► temp/surplus.dta         (surplus share χ, residualized surplus)
    │
    ▼
revenue_function.do ─────────────► temp/revenue_models.ster  (6 specifications of revenue function)
    │
    ▼
manager_value.do ───────────────► temp/manager_value.dta     (manager fixed effects, within-firm skill)
    │                             temp/manager_value_spell.dta
    │
    ▼
event_study_sample.do ──────────► temp/{variation}_placebo_{sample}.dta  (placebo CEO transitions)
    │
    ▼
setup_event_study.do ───────────► (loaded by event_study*.do)             (event-time variables, treatment indicators)
    │
    ▼
event_study.do ─────────────────► data/atet_*.csv            (ATET, covariance, variance dynamics)
event_study_atet.do ────────────► data/{variation}_{sample}_{OC}-{FE}.csv (beta, Cov, VarY series)
xt2var.do ──────────────────────► (in-memory frames → CSV)   (excess variance decomposition)
    │
    ▼
balance.do ─────────────────────► (tables of component coverage)
bloom_autonomy_analysis.do ─────► (Bloom et al. regressions, external validation)
```

All scripts reside in `lib/estimate/` and are called from the Makefile. The pipeline is parameterized by **variations** (sample filters: `full`, `size1`–`size4`, `pre2000`, `post2000`) and **samples** (CEO transition types: `full`, `one2one`, `twos`, `fnd2non`, `non2non`, `gap`, `nogap`, `gender`, `nogender`).

## Estimation Scripts

### surplus.do — Surplus Share Estimation

**Status:** Referenced in Makefile and `surplus.log`; file missing from current working tree.

**Role:** Computes the surplus share χ — the fraction of revenue accruing to fixed factors under Cobb-Douglas technology. This parameter determines how manager skill translates into firm performance through the leverage effect.

**Parameters:**
- `min_surplus_share = 0`, `max_surplus_share = 1` (bounds)
- Controls: `lnK`, `has_intangible`
- Fixed effects: `frame_id_numeric##ceo_spell`, `teaor08_2d##year`

**Control Flow:**
1. Load `temp/analysis-sample.dta`
2. Compute `surplus_share = EBITDA / sales` by firm-year, winsorize to [0,1]
3. For each sector: compute sales-weighted mean surplus share as the sector-level χ
4. Run sector-level `reghdfe lnR lnK has_intangible, absorb(frame_id_numeric##ceo_spell teaor08_2d##year) resid`
5. Compute residualized surplus: `lnStilde = χ × (lnR - β_lnK×lnK - β_has_intangible×has_intangible - sector_time_effect)`
6. Save `temp/surplus.dta`

**Output:** `temp/surplus.dta` with `chi` (sector-level surplus share), `lnStilde` (residualized surplus), and regression coefficients per sector.

### revenue_function.do — Revenue Function Estimation

**Role:** Estimates the revenue function under six specifications, demonstrating robustness across outcomes (revenue, EBITDA, wage bill, materials) and control sets.

**Parameters:**
- Controls: `lnK`, `has_intangible`, `foreign_owned`, `state_owned`, `founder`, `owner`
- Rich controls: adds `ceo_age`, `ceo_age_sq`, `ceo_tenure`, `ceo_tenure_sq`
- Fixed effects (basic): `frame_id_numeric`, `firm_age`, `teaor08_2d##year`
- Fixed effects (rich): `frame_id_numeric##ceo_spell`, `firm_age`, `teaor08_2d##year`

**Six Models:**

| Model | Outcome | Controls | Fixed Effects | Sample |
|-------|---------|----------|---------------|--------|
| 1 | `lnR` | basic | basic | all |
| 2 | `lnEBITDA` | basic | basic | all |
| 3 | `lnWL` | basic | basic | all |
| 4 | `lnM` | basic | basic | all |
| 5 | `lnR` | rich | rich | all |
| 6 | `lnR` | rich | rich | connected components only |

**Control Flow:**
1. Load `temp/analysis-sample.dta`
2. Create connected component indicators via `lib/create/network-sample.do`
3. Run `reghdfe` for each model with cluster-robust SEs at `frame_id_numeric`
4. Save all models to `temp/revenue_models.ster`

**Output:** `temp/revenue_models.ster` (Stata estimation file with 6 models for exhibit scripts).

### manager_value.do — Manager Fixed Effects and Skill Estimation

**Role:** Estimates manager-specific fixed effects using an AKM-style two-way model (firm × manager), produces within-firm and connected-component skill distributions.

**Key Parameters:**
- `within_firm_skill_min = -1`, `within_firm_skill_max = 1` (bounds on within-firm skill)
- Fixed effect variable: `ROA` (return on assets)
- Outcomes: `lnR`, `lnEBITDA`, `lnL`

**Control Flow:**
1. Load `temp/analysis-sample.dta` and `temp/intervals.dta` (CEO tenure intervals)
2. Expand intervals into person-year panel, merge onto firm-year panel
3. Create connected component indicators via `lib/create/network-sample.do`
4. Compute **within-firm skill**: for each firm, demean ROA by firm-person mean, then subtract the first CEO's mean (identifying variation from CEO changes)
5. Clip within-firm skill to `[-1, 1]` and produce histogram
6. Run `reghdfe ROA, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id)` — the two-way fixed-effects decomposition
7. Across connected components, demean extracted `manager_skill` and produce histogram
8. Save two outputs:
   - `temp/manager_value_spell.dta`: spell-level manager skill (used by event studies)
   - `temp/manager_value.dta`: firm-manager-level fixed effects and component assignment

**Output:** `temp/manager_value.dta`, `temp/manager_value_spell.dta`, histograms in `output/figure/`.

### event_study_sample.do — Placebo CEO Transition Construction

**Role:** Generates synthetic placebo CEO transitions matched on observables to actual transitions. This is the core identification device: placebo transitions share the same timing and firm characteristics as real transitions but occur when no actual CEO change happened.

**Key Parameters:**
- `TARGET_N_CONTROL = 10` (target control-to-treated ratio per stratum)
- `SEED = 1391`
- `exact_match_on = cohort sector max_size`
- `max_n_ceo = 2` (firms with ≤ 2 CEOs in sample period)
- `fixed_effect = ROA`
- Sample types: `full`, `fnd2non`, `non2non`, `small`, `large`, `one2one`, `twos`, `gap`, `nogap`, `gender`, `nogender`

**Control Flow:**
1. Load analysis sample, merge with manager value data and CEO facts
2. Keep firms with ≤ 2 CEOs, limit to clean changes
3. Collapse to spell-level: compute mean manager skill (`MS`), spell length (`T`), `change_year`, cohort/sector/size matching variables
4. Drop firms with only one spell (no CEO change)
5. Expand intermediate spells so each CEO change appears twice (once as before-change, once as after-change)
6. Reshape wide: each observation is a CEO change pair (`MS1`, `MS2`, `change_year`, etc.)
7. Filter to sample type and save treated firms
8. **Placebo matching:**
   - Compute for each treated group (defined by `cohort × sector × max_size`) the distribution of pre-change spell lengths (`t0`)
   - From the full firm-year panel, draw potential control firms with the same `cohort × sector × max_size` and with an event window that fits inside their firm's lifespan
   - Sample controls proportional to treated group size (target 10×)
   - Assign each control a random `t0` drawn from the treated group's `t0` distribution
   - Create placebo `change_year = window_start + t0`
9. Save combined treated + placebo file

**Output:** `temp/{variation}_placebo_{sample}.dta` for each variation×sample combination. Each file contains: `fake_id`, `placebo` (0=actual, 1=placebo), `frame_id_numeric`, `window_start/end`, `change_year`, `ceo_spell`, `weight`.

**[Subsample Definitions](https://github.com/korenmiklos/ceo-value/blob/main/lib/create/event_study_sample.do#L7-L17):**
| Sample | Condition |
|--------|-----------|
| `full` | all CEO changes |
| `fnd2non` | founder CEO → non-founder CEO |
| `non2non` | non-founder → non-founder |
| `small` | firm has ≤ 10 employees throughout |
| `large` | firm has > 10 employees throughout |
| `one2one` | single CEO in each spell |
| `twos` | two CEOs in one of the spells |
| `gap` | CEO age difference > 10 years |
| `nogap` | CEO age difference ≤ 10 years |
| `gender` | CEO gender changes |
| `nogender` | CEO gender stays same |

### setup_event_study.do — Event Study Data Preparation

**Role:** Shared setup script loaded by `event_study.do`, `event_study_atet.do`, and Monte Carlo simulations. Merges placebo transition data with firm-year panel and creates event-time variables.

**Key Parameters:**
- `event_window_start = -4`, `event_window_end = 3`, `baseline_year = -1`
- `random_seed = 2181`, `sample = 100` (pct sampling for test performance)
- `cluster = frame_id_numeric`, `T_min = 1`

**Control Flow:**
1. Load firm-year panel and merge in spell-level manager skill
2. Sample firms (optional, controlled by `${sample}` parameter)
3. Join with placebo data on `frame_id_numeric`
4. Keep only event-window years and groups with both treated and control firms
5. Assign `ceo_spell = 1` (before change) / `2` (after change) based on year relative to `change_year`
6. Compute `fake_manager_skill` = mean outcome by `fake_id × ceo_spell`
7. Create treatment indicators:
   - `actual_ceo` = post-change ∧ placebo=0
   - `placebo_ceo` = post-change ∧ placebo=1
   - `better_ceo` = post-change ∧ MS2 > MS1
   - `worse_ceo` = post-change ∧ MS2 < MS1
8. `xtset fake_id year` for panel time series operations

**State invariants:** After setup: the panel covers event times [−4, +3] relative to `change_year`, each `fake_id` has exactly one `change_year`, data contains both treated (`placebo=0`) and matched placebo (`placebo=1`) units.

### event_study.do — Main Event Study (Denoised ATET)

**Role:** Implements the placebo-controlled event study that separates true CEO effects from noise using the `xt2denoise` estimator. Produces ATET (average treatment effect on the treated) and variance/covariance dynamics.

**Arguments:** `variation`, `sample`, `outcome`, `montecarlo`, `fixed_effects`, `excessvariance`

**Control Flow:**
1. Load placebo data, confirm existence of variation and sample
2. If not Monte Carlo: demean outcome and fixed effects by `teaor08_2d × year` (absorbing sector-year shocks)
3. Drop units where outcome is ever missing
4. Call `xt2denoise outcome, z(manager_skill) treatment(actual_ceo) control(placebo_ceo) pre(4) post(3) detail [excessvariance] baseline(atet)`
5. Capture matrices: `var_z1` (naive variance of z), `var_z_diff` (denoised variance), `cov_diff` (denoised covariance), `cov1` (naive covariance), `var_y1` (outcome variance), `V_naive` / `V` (standard errors)
6. Build ATET frame with: `Var1z`, `dVarz`, `dCov`, `Cov`, `VarY`, `Rsq`, `dRsq`, standard errors, N
7. Export to `data/atet_{variation}_{sample}_{OC}-{FE}.csv`

**Output:** CSV file with one row per event time containing naive and denoised covariance estimates, variance components, R², and standard errors.

### event_study_atet.do — Detailed Beta and Variance Decomposition

**Role:** Two-phase extension of the event study that extracts beta coefficients (regression of outcome on manager skill), covariance series, and variance series separately.

**Arguments:** Same structure as `event_study.do` plus `excesssvariance` flag.

**Control Flow:**
1. **Phase 1 (Covariance):** `xt2denoise` with z=manager_skill, capture beta coefficients (`b_naive`, `b_denoised`) and Cov matrices (`Cov1`, `dCov`, `Var1`, `dVar`) using `e2frame`
2. **Phase 2 (Variance):** Recompute `manager_skill` = mean(outcome) by spell (if outcome ≠ fixed_effects), run `xt2denoise` with cov detail to get `dVarY`, `VarY1`
3. Compute aggregate `Var1`, `dVar`, `Var0` by averaging over pre-treatment columns
4. Build unified frame `dCov` with:
   - Beta series: `coef_beta1`, `coef_dbeta` (with CI bands)
   - Cov series: `coef_Cov1`, `coef_Cov0`, `coef_dCov` (with CI)
   - VarY series: `coef_VarY1`, `coef_VarY0`, `coef_dVarY` (with CI)
   - Derived: `coef_cov_beta = dCov/Var1`, `coef_var_beta = Cov1/dVar`
   - R²: `Rsq = Cov1²/(VarY×Var1)`, `dRsq = dCov²/(VarY×dVar)`
5. Export to `data/{variation}_{sample}_{OC}-{FE}.csv`

**Output:** Comprehensive CSV with all series for exhibit figures (Figure 2, Figure 3 in the paper).

### xt2var.do — Excess Variance via xt2denoise

**Role:** An alternative, direct implementation of the covariance/variance decomposition using the `xt2var` framework. Computes variance of manager skill, covariance of outcome with skill, and beta coefficients = Cov/Var with delta-method standard errors.

**Arguments:** `outcome`, `treatment`, `treated_group`, `X`, `cluster`, `fixed_effects`

**Control Flow:**
1. Compute group-level means, demeaned variables (`dY`, `dZ`), event time `e`
2. Form groups based on treatment pattern, compute covariances with driver variable
3. **Iterative reweighting** (4 iterations): estimate excess variance ratio `eVarZ`, `eVarY` via OLS in pre-treatment period, reweight control group variances to match treated group
4. Run `reghdfe` on demeaned variance/covariance terms to get event-time coefficients:
   - `Cov1`: variance of manager skill on treated (biased)
   - `dCov`: difference between treated and placebo (unbiased)
   - `VarY1`, `dVarY`: outcome variance analogues
5. Compute ATET as a single row (`reghdfe dYdX TXT` for event times ≥ -1)
6. Build unified frame with:
   - `coef_dbeta = dCov/dVar`, `coef_beta1 = Cov1/Var1`
   - Delta-method standard errors for beta using variance ratio correction
   - `Cov0_excess`, `VarY0_excess` for control group
   - R² measures: `Rsq1`, `Rsq0`, `dRsq`
7. Standardize by `eCovYZ` / `eVarY` factors for comparability

**Invariant:** Pre-treatment period (`e < 0`) drives identification of excess variance ratios. The iterative reweighting converges to an unbiased variance estimate in the treated group by borrowing information from controls.

### balance.do — Balance Check

**Role:** Simple diagnostic that loads the analysis sample, creates connected component indicators via `network-sample.do`, and tabulates the number of firms in the giant component and in large connected components (size ≥ 30) by year.

**Parameters:** None. Uses `temp/analysis-sample.dta` directly.

**Output:** Log output with balance tables, no persistent data files.

### bloom_autonomy_analysis.do — Bloom et al. (2012) Validation

**Role:** Tests whether family-controlled firms exhibit lower managerial autonomy using the Bloom, Sadun & Van Reenen (2012) cross-country replication data. Provides external validity evidence for the project's theoretical framework.

**Data:** `input/bloom-et-al-2012/replication.dta`

**Specifications:**
- Six PPML specifications per autonomy dimension (country FE, + industry FE, + analyst FE, private-only, with CEO onsite control, full sample)
- Four OLS specifications on log investment autonomy
- Autonomy dimensions: investment (dollar value), hiring (dummy), marketing (dummy), product introduction (dummy)

**Key Findings (documented in script):**
- Family firms have ~31% less investment autonomy among private firms
- CEO onsite presence strongly reduces all autonomy dimensions (22–38%)
- Effects robust to country, industry, and analyst fixed effects

**Output:** Display output only; no persistent data files.

### ANOVA (lib/estimate/anova.do) — ATET Tables

**Status:** Referenced in Makefile for creating `table/atet_owner.tex` and `table/atet_manager.tex`; file missing from current working tree.

**Role:** Produces LaTeX tables showing ATET (average treatment effect on the treated) for owner-CEO vs non-owner-CEO transitions, likely splitting the sample by ownership type.

### Monte Carlo Support

The `lib/create/montecarlo.do` script generates synthetic data for testing estimator properties. It creates 10,000 simulated CEO changes with known true effect size `σ_z × √(2/π)` and tests whether the event study estimator recovers the true parameters. The event study scripts (`event_study.do`, `event_study_atet.do`) accept a `montecarlo` flag that bypasses the real-data merging and uses synthetic data paths.

## Relationships and Data Flow

```
                                ┌─────────────────────────────────────────────┐
                                │           analysis-sample.dta               │
                                │ (firm-years with CEO spells, outcomes,      │
                                │  controls, network component IDs)           │
                                └──────┬──────────────────────┬───────────────┘
                                       │                      │
                        ┌──────────────▼──────────────┐      │
                        │      surplus.do              │      │
                        │  ↓ temp/surplus.dta (χ)      │      │
                        └──────────────────────────────┘      │
                                                              │
                        ┌──────────────▼──────────────┐      │
                        │   revenue_function.do        │      │
                        │  ↓ revenue_models.ster       │      │
                        └──────────────────────────────┘      │
                                                              │
                        ┌──────────────▼──────────────┐      │
                        │   manager_value.do           │◄─────┤
                        │  ↓ manager_value.dta         │      │
                        │  ↓ manager_value_spell.dta   │      │
                        └──────────────────────────────┘      │
                                                              │
                        ┌──────────────▼──────────────┐      │
                        │ event_study_sample.do        │◄─────┤
                        │ (placebo transition design)  │      │
                        │  ↓ {variation}_placebo.dta   │      │
                        └──────────────────────────────┘      │
                                                              │
        ┌──────────────────────────────┬──────────────────────┘
        │                              │
┌───────▼──────────┐     ┌────────────▼───────────┐
│  event_study.do   │     │  event_study_atet.do   │
│  ↓ atet_*.csv     │     │  ↓ {v}_{s}_{OC}-FE.csv│
└───────────────────┘     └────────────────────────┘
```

## Configuration and Parametrization

The subsystem is parameterized along two orthogonal dimensions:

1. **Analysis variations** (sample filters applied to firm-year panel): `full`, `size1`–`size4`, `pre2000`, `post2000`. Defined in `lib/util/filter.do`.
2. **Event study samples** (CEO transition types): 11 types defined in `event_study_sample.do`.

The Makefile enumerates all `variation × sample` combinations for placebo generation:
```makefile
$(foreach variation,$(ANALYSIS_VARIATIONS), $(foreach sample,$(SAMPLES), temp/$(variation)_placebo_$(sample).dta))
```

Event study outcome variables: `lnK`, `lnWL`, `lnM`, `has_intangible` (defined as `OUTCOMES` in Makefile).

## Key Dependencies on External Packages

- **`xt2treatments`** (Stata package, ≥0.9.0): Provides `xt2denoise` command for placebo-controlled difference-in-differences estimation. Required for all event study scripts.
- **`reghdfe`** (Stata package, ≥6.12.3): High-dimensional fixed-effects OLS. Used in `surplus.do`, `revenue_function.do`, `manager_value.do`, `xt2var.do`, `bloom_autonomy_analysis.do`.
- **`estout`** (Stata package): Estimation output formatting for tables.
- **`e2frame`** (Stata package): Converts estimation results to Stata frames.

## Testing

The `lib/test/` directory contains:
- `placebo.do`: Tests placebo balance by comparing treated vs control periods for different skill change directions.
- `test_network.jl`: Tests the Julia-based connected component algorithm (not estimation per se, but required for manager value estimation).

Monte Carlo tests are implemented in `lib/create/montecarlo.do` and invoked by event study scripts with the `montecarlo` argument. The Monte Carlo generates data with known true effect size (`true_effect = 0.797885 × σ_z ≈ 0.08`) and checks that ATET estimates recover this value.
