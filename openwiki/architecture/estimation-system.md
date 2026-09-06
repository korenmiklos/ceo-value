---
type: architecture
title: Estimation System
description: Documents all econometric estimation methods including manager FE estimation, revenue function estimation, xt2denoise placebo-controlled event study, ATET variant, variance decomposition, Monte Carlo simulation, and external KSS leave-out MATLAB routines.
tags: [estimation, econometrics, event-study, placebo, manager-FE, revenue-function, variance-decomposition, monte-carlo, KSS-correction]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-2a84a273bb200e9b22c6ecfa
    resource: repo://lib/create/montecarlo.do
  - id: openwiki-source-f0ae5c512fbda36029c85f72
    resource: repo://lib/create/network-sample.do
  - id: openwiki-source-48d46b9352692a1c5ba81912
    resource: repo://lib/estimate/bloom_autonomy_analysis.do
  - id: openwiki-source-d14dd673ea608af03e9d9544
    resource: repo://lib/estimate/event_study_atet.do
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
  - id: openwiki-source-063a17dbfdd0b7095e6bed88
    resource: repo://lib/KSS/leave_out_COMPLETE.m
  - id: openwiki-source-66c48298d2bb89eaacbf17c3
    resource: repo://lib/KSS/leave_out_KSS.m
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Estimation System

The CEO Value Research Project implements a layered estimation system that isolates managerial value added from firm performance outcomes. The system combines AKM-style two-way fixed effects, revenue/production function models, a placebo-controlled event study design with denoising (xt2denoise), an average treatment effect on the treated (ATET) variant, variance decomposition of CEO skill, Monte Carlo simulations for validation, and external KSS leave-out MATLAB routines for bias correction. All estimation scripts reside in [`/lib/estimate/`](repo://lib/estimate/).

## 1. Manager Value Estimation (two-way FE)

**Script:** [`/lib/estimate/manager_value.do`](repo://lib/estimate/manager_value.do)

This estimator decomposes firm performance (`ROA`, the fixed_effect variable) into a firm fixed effect and a manager person effect using `reghdfe` with two high-dimensional fixed effects: `frame_id_numeric` (firm) and `person_id` (manager). Connected components are identified first via [`/lib/create/network-sample.do`](repo://lib/create/network-sample.do) because manager effects are only comparable within a connected set of firms that share managers through job switches.

### Key Steps

1. **Person-year expansion**: Person-level CEO spells from [`/lib/create/intervals.do`](repo://lib/create/intervals.do) (stored as `temp/intervals.dta`) are expanded to firm-year resolution via `expand T` where `T = end_year - start_year + 1`.
2. **Within-firm skill**: For each firm-manager pair (`frame_id_numeric` × `person_id`), the mean of `ROA` is computed. The first CEO spell per firm is subtracted so that within-firm skill variation is relative to the first observed manager, isolating the contribution of CEO changes.
3. **Between-firm skill (connected component)**: `reghdfe ROA, absorb(firm_fixed_effect=frame_id_numeric manager_skill=person_id)` estimates manager effects across firms. Only the giant connected component (`giant_component == 1`) is used for between-firm comparisons.
4. **Skill bounds**: Within-firm skill is clipped to `[within_firm_skill_min, within_firm_skill_max]` = [-1, 1] log points.
5. **Output**: Spell-level manager skill saved to `temp/manager_value_spell.dta` and person-level to `temp/manager_value.dta`.

### Parameters

| Parameter | Value |
|-----------|-------|
| Within-firm skill min | -1 |
| Within-firm skill max | 1 |
| Fixed effect outcome | `ROA` |
| Firm FE | `frame_id_numeric` |
| Manager FE | `person_id` |

### Statistical Outputs

- IQR of manager skill: displayed as `exp(r(p75) - r(p25))*100 - 100`
- Histograms of within-firm and connected-component manager skill distributions saved to `output/figure/manager_skill_within.pdf` and `output/figure/manager_skill_connected.pdf`

---

## 2. Revenue Function Estimation

**Script:** [`/lib/estimate/revenue_function.do`](repo://lib/estimate/revenue_function.do)

Six specifications of a production/revenue function are estimated using `reghdfe`. The base controls are `lnK`, `has_intangible`, `foreign_owned`, `state_owned`, `founder`, `owner`; rich controls additionally include `ceo_age`, `ceo_age_sq`, `ceo_tenure`, `ceo_tenure_sq`.

### Six Specifications

| Model | Outcome | Controls | Fixed Effects | Sample |
|-------|---------|----------|---------------|--------|
| 1 | `lnR` (log revenue) | base | `frame_id_numeric` + `firm_age` + `teaor08_2d#year` | Full |
| 2 | `lnEBITDA` | base | Same as Model 1 | Full |
| 3 | `lnWL` (log wage bill) | base | Same as Model 1 | Full |
| 4 | `lnM` (log materials) | base | Same as Model 1 | Full |
| 5 | `lnR` | rich | `frame_id_numeric#ceo_spell` + `firm_age` + `teaor08_2d#year` | Full |
| 6 | `lnR` | rich | Same as Model 5 | Connected components only |

All specifications cluster standard errors at `frame_id_numeric`. Estimates are saved to `temp/revenue_models.ster` via `estimates save`.

### Outcome Variables

| Variable | Description |
|----------|-------------|
| `lnR` | Log revenue |
| `lnEBITDA` | Log EBITDA |
| `lnWL` | Log wage bill |
| `lnM` | Log materials |

---

## 3. Placebo-Controlled Event Study (xt2denoise)

**Script:** [`/lib/estimate/event_study.do`](repo://lib/estimate/event_study.do)  
**Setup script:** [`/lib/estimate/setup_event_study.do`](repo://lib/estimate/setup_event_study.do)

This is the core causal identification strategy. It implements a **placebo-controlled event study** using the `xt2denoise` Stata command, which corrects for attenuation bias in dynamic difference-in-differences.

### Architecture

The script is called with positional arguments:

```
event_study.do <variation> <sample> <outcome> [montecarlo] [fixed_effects] [excesssvariance]
```

**Setup flow** (setup_event_study.do):
1. Loads placebo-augmented dataset from `data/<variation>_placebo_<sample>.dta`
2. Merges with `temp/manager_value_spell.dta` for manager skill estimates
3. Draws a random subsample (default 100%) for performance
4. Constructs event time relative to `change_year` with `event_window_start = -4` and `event_window_end = 3`
5. Creates treatment indicators: `actual_ceo` (treated × post), `placebo_ceo` (placebo × post), `better_ceo`, `worse_ceo`
6. Demeans outcomes by `teaor08_2d#year` cells (industry-year fixed effects)
7. Drops firms with missing outcomes in any event-time cell

### Event Window Parameters

| Parameter | Value |
|-----------|-------|
| `pre` | 4 (years before CEO change) |
| `post` | 3 (years after CEO change) |
| `event_window_start` | -4 |
| `event_window_end` | 3 |
| `baseline_year` | -1 |
| `cluster` | `frame_id_numeric` |
| `random_seed` | 2181 |
| `T_min` | 1 (min obs per spell) |

### Two xt2denoise Calls

**Call 1 (beta coefficients):**
```
xt2denoise <outcome>, z(manager_skill) treatment(actual_ceo) control(placebo_ceo) pre(4) post(3) detail [excesssvariance]
```
Returns:
- `e(b)` / `e(V)`: Denoised (bias-corrected) coefficients and covariance
- `e(b_naive)` / `e(V_naive)`: Naive (uncorrected) coefficients and covariance
- `e(cov1)` / `e(V_cov_naive)`: Naive covariance between outcome and manager skill
- `e(cov_diff)` / `e(V_cov_diff)`: Denoised covariance difference
- `e(var_z1)`, `e(true_var_z)`: Variance of manager skill (treated, and difference)
- `e(var_y1)`: Variance of outcome for treated

**Call 2 (outcome variance):**
Re-estimates with `z = manager_skill` set to the spell-level mean of the outcome itself, with `cov` option, to obtain debiased outcome variance (`dVarY`) and naive outcome variance (`VarY1`). From these, `VarY0 = VarY1 - dVarY`.

### Derived Series

The script constructs a unified `dCov` dataset with event-time series:

| Series | Formula | Interpretation |
|--------|---------|--------|
| `coef_dbeta` | `dCov / dVar` | Denoised manager beta (bias-corrected) |
| `coef_beta1` | `Cov1 / Var1` | Naive manager beta (treated only) |
| `coef_beta0` | `Cov0 / Var0` | Placebo manager beta |
| `coef_cov_beta` | `dCov / Var1` | Covariance-only corrected beta |
| `coef_var_beta` | `Cov1 / dVar` | Variance-only corrected beta |
| `Rsq`, `dRsq` | Squared correlations | Goodness of fit metrics |

Output is exported to `data/<variation>_<sample>_<outcome>-<fixed_effects>.csv`.

### Clustering and Inference

- Standard errors are cluster-robust at `frame_id_numeric`
- Naive and denoised covariance matrices are captured and used for confidence intervals
- Delta-method standard errors are computed for beta estimates: `se(beta) = se(Cov)/E(X) * sqrt(1 + beta² * Var(X)/Var(Y))`

---

## 4. ATET Event Study Variant

**Script:** [`/lib/estimate/event_study_atet.do`](repo://lib/estimate/event_study_atet.do)

This variant estimates the **Average Treatment Effect on the Treated** (ATET) directly, using a collapsed pre-/post-design rather than the full dynamic event study path. It uses `xt2denoise` with the `baseline(atet)` option.

### Differences from main event_study.do

1. **No demean step**: ATET variant skips the industry-year demeaning that `event_study.do` applies when `montecarlo` is not set.
2. **Baseline ATET**: Uses `baseline(atet)` in xt2denoise, which estimates a single ATET parameter rather than event-time path coefficients.
3. **Single frame output**: Results are exported as a CSV to `data/atet_<variation>_<sample>_<outcome>-<fixed_effects>.csv` with columns: `Var1z`, `dVarz`, `dCov`, `Cov`, `VarY`, `Rsq`, `dRsq`, `se_naive`, `dse`, `N`.
4. **Matrix-based**: Captures results as Stata matrices (`Var1z`, `dVarz`, `Cov`, `Cov_naive`, `VarY`, `se_naive`, `dse`) rather than frame series.

### Output Columns

| Column | Description |
|--------|-------------|
| `Var1z` | Variance of z (manager skill) in treated group |
| `dVarz` | Variance difference (treated - placebo) of z |
| `dCov` | Denoised covariance difference |
| `Cov` | Naive covariance (treated only) |
| `VarY` | Variance of outcome in treated group |
| `Rsq` | `Cov² / (VarY * Var1z)` |
| `dRsq` | `dCov² / (VarY * dVarz)` |
| `se_naive` | sqrt of naive variance |
| `dse` | sqrt of denoised variance |
| `N` | Number of observations |

---

## 5. Variance Decomposition (xt2var)

**Script:** [`/lib/estimate/xt2var.do`](repo://lib/estimate/xt2var.do)

This script estimates the variance and covariance components of the event study design manually, implementing the placebo-controlled excess variance methodology without calling `xt2denoise`. It serves as both a validation and a more transparent implementation.

### Arguments

```
xt2var.do <outcome> <treatment> <treated_group> <X> [cluster] [fixed_effects]
```

- `outcome`: Outcome variable (e.g., `lnROA`, `TFP`)
- `treatment`: Binary (0/1), equals 1 for post-treatment treated observations
- `treated_group`: Binary (0/1), identifies the treated group (vs placebo)
- `X`: Driver variable (manager skill)
- `cluster`: Clustering variable (defaults to panel variable)
- `fixed_effects`: Fixed effects variable (defaults to outcome)

### Methodology

1. **Deviation from baseline**: For each firm, outcomes and fixed effects are expressed as deviations from the last pre-treatment year (`g = max(t) where treatment == 0`): `dY = Y - Y_g`, `dZ = Z - Z_g`.
2. **Event time**: `e = t - g - 1`, ranging from -`pre` to +`post`.
3. **Group formation**: Firms are grouped by the pattern of pre/post observations (`T1` × `T0`).
4. **Excess variance estimation**: An iterative fixed-point algorithm (4 iterations) estimates `eVarY` and `eVarZ` — the excess variance ratios — by regressing squared deviations in the treated group on the placebo-group mean squared deviations (no constant, pre-period only).
5. **Scaling**: Placebo-group squared deviations `dY²`, `dX²`, and `dY·dX` are scaled by the excess variance ratios to match the treated-group variance level.
6. **Regression**: `reghdfe` is used to estimate event-time coefficients for variance (`dY²`), covariance (`dY·dX`), and driver variance (`dX²`), separately for treated-only (biased) and treated-minus-placebo (unbiased).
7. **ATET estimates**: A separate `reghdfe` on a single `TXT = treated_group & treatment` indicator over `e ∈ [-1, post]` estimates collapsed ATET-style coefficients for `Cov1`, `dCov`, `VarY1`, `dVarY`.

### Output Components

| Frame | Content |
|-------|---------|
| `Cov1` | Naive covariance coefficients (treated only) |
| `dCov` | Denoised covariance coefficients (difference) |
| `VarY1` | Naive outcome variance coefficients |
| `dVarY` | Denoised outcome variance coefficients |
| `dCov` (unified) | All series merged: `coef_dbeta`, `coef_beta1`, `coef_beta0`, `Rsq1`, `Rsq0`, `dRsq`, plus delta-method SEs |

**Key scalars**: `Var0`, `Var1`, `dVar` (driver variance components); `eCovYZ`, `eVarY`, `eVarZ` (excess variance ratios).

---

## 6. Monte Carlo Simulation

**Script:** [`/lib/create/montecarlo.do`](repo://lib/create/montecarlo.do)

A simulation framework that generates synthetic data with known treatment effects to validate the event study and xt2denoise methodology.

### Data-Generating Process

| Parameter | Value | Description |
|-----------|-------|-------------|
| `N_changes` | 10,000 | Number of CEO changes |
| `hazard` | 0.2 | Hazard rate of CEO change per year |
| `sigma_z` | 0.1 | Std dev of CEO ability (√0.01) |
| `true_effect` | `half_normal × sigma_z = 0.0797885` | Expected true effect |
| `sigma_epsilon0` | 0.05 | Std dev of TFP growth (untreated) |
| `sigma_epsilon1` | 0.06 | Excess variance for treated firms |
| `rho` | 0.97 | Autocorrelation of TFP |
| `control_treated_ratio` | 9 | 9 placebo firms per treated firm |
| `T_max` | 20 | Maximum spell length |

### Simulation Steps

1. **CEO timing**: Two exponential-duration spells `T1`, `T2` per firm.
2. **Placebo construction**: Each treated firm is expanded to 1 + `control_treated_ratio` copies, with `placebo` flag distinguishing actual from synthetic controls. A `fake_id` groups each treated × placebo cluster.
3. **TFP process**: AR(1) with `ρ = 0.97` and innovation `dTFP ~ N(0, σ_ε²)`. Treated firms have higher innovation variance (`σ_ε1 = 0.06` vs `σ_ε0 = 0.05`), generating excess variance.
4. **CEO ability**: `dz ~ N(0, σ_z²)` drawn once per treated firm. `z` is the cumulative ability, added to TFP in post-change years for treated firms. The true effect = `E[|z|] = σ_z × √(2/π) = 0.0798`.
5. **Measured skill**: `manager_skill = mean(TFP)` per `fake_id × ceo_spell`, demeaned across treated firms.

### Validation Output

- `temp/placebo_montecarlo.dta`: Full simulated dataset
- `reghdfe TFP treatment, absorb(fake_id year)`: Checks mean ATET
- `reghdfe TFP² treatment, absorb(fake_id year)`: Checks variance ATET

The Monte Carlo design specifically tests whether xt2denoise recovers the true ATET of ~0.08 and correctly separates variance effects from mean effects.

---

## 7. External KSS Leave-Out MATLAB Routines

**Scripts:** [`/lib/KSS/leave_out_KSS.m`](repo://lib/KSS/leave_out_KSS.m), [`/lib/KSS/leave_out_FD.m`](repo://lib/KSS/leave_out_FD.m), [`/lib/KSS/leave_out_COMPLETE.m`](repo://lib/KSS/leave_out_COMPLETE.m)

These MATLAB functions implement the **Kline, Saggio, and Sølvsten (KSS) leave-out correction** for two-way fixed effects models, which removes the mechanical Nickell-type bias in estimated person and firm effects when the number of time periods is small.

### Entry Point

`leave_out_KSS(y, id, firmid, leave_out_level, year, controls, ...)`

### Core Function: `leave_out_COMPLETE`

This is the master routine (authored by Raffaele Saggio) that:

1. **Runs AKM**: Estimates the standard Abowd-Kramarz-Margolis two-way FE model via PCG (preconditioned conjugate gradient) on the connected set, computing person effects (`ahat`), firm effects (`ghat`), and residuals.
2. **Computes (Bᵢᵢ, Pᵢᵢ)**: Diagonal elements of the projection matrix (leverage) and the permutation matrix, which are the ingredients for the leave-out bias correction.
3. **Leave-out level**: `leave_out_level` controls whether to leave out individual observations (`'obs'`), or worker-level clusters (e.g., `'worker'`), which determines the coarseness of the jackknife.
4. **Bias correction**: Applies the KSS correction to produce unbiased estimates of `σ²_ψ` (variance of person effects), `σ_ψα` (covariance of person and firm effects), and `σ²_α` (variance of firm effects).

### Algorithm Options

| Option | Description |
|--------|-------------|
| `type_of_algorithm` | `'exact'` (default) for exact leave-out; `'JLL'` for Johnson-Lindenstrauss approximation |
| `scale` | Number of simulations for JLL algorithm (default 0.005) |
| `do_SE` | Whether to compute standard errors |
| `eigen_diagno` | Whether to compute eigenvalue diagnostics for A-M confidence intervals |
| `restrict_movers` | If set to 1, restricts analysis to workers who change firms |
| `subsample_llr_fit` | Whether to use subsampled LLR fit |
| `andrews_estimates` | Whether to compute Andrews et al. (2008) estimates |
| `resid_controls` | Whether to residualize controls before leave-out computation |

### Outputs

| Output | Description |
|--------|-------------|
| `sigma2_psi` | Variance of person effects (bias-corrected) |
| `sigma_psi_alpha` | Covariance of person and firm effects |
| `sigma2_alpha` | Variance of firm effects (bias-corrected) |
| `SE_*` | Standard errors for each estimate |

The KSS routines are essential for producing unbiased estimates of the variance of manager skill (`σ²_ψ`) when the number of CEOs per firm or years per CEO is small, which is the typical case.

---

## 8. Bloom et al. Autonomy Analysis

**Script:** [`/lib/estimate/bloom_autonomy_analysis.do`](repo://lib/estimate/bloom_autonomy_analysis.do)

A standalone analysis using Bloom, Sadun & Van Reenen (2012) QJE replication data to test whether family-controlled firms grant less managerial autonomy.

### Specifications

Outcomes: `central5` (investment autonomy, dollar value), `hiring` (dummy), `marketing` (dummy), `product` (dummy). Estimated via `ppmlhdfe` (PPML) and `reghdfe` (OLS on `lnI = ln(central5)`).

### Fixed Effects Sets

| Specification | Fixed Effects |
|---------------|---------------|
| Baseline | Country FE |
| Preferred | Country + Industry (sic2) FE |
| Robust | Country + Industry + Analyst FE |

### Key Findings (as documented)

- Family-controlled firms have ~31% lower investment autonomy among private firms
- CEO onsite presence strongly reduces all autonomy dimensions (38% for investment, p<0.01)
- Results robust to country, industry, and analyst fixed effects

---

## Relationship Between Components

<!-- openwiki: mermaid parse failed and this diagram was converted to a text fence so it does not break rendering. Fix the diagram source and restore the mermaid fence. Parser error: Heuristic: an unescaped angle bracket inside a label breaks rendering; rephrase the label. -->
```text
flowchart TD
    A[Raw Data: Balance Sheet + CEO Panel] --> B[Data Pipeline<br/>lib/create/]
    B --> C[analysis-sample.dta]
    B --> D[intervals.dta]
    
    C --> E[Revenue Function<br/>lib/estimate/revenue_function.do]
    C --> F[Manager FE<br/>lib/estimate/manager_value.do]
    D --> F
    
    F --> G[manager_value_spell.dta]
    
    C --> H[Placebo Data<br/>data/variation_placebo_sample.dta]
    H --> I[Setup Event Study<br/>lib/estimate/setup_event_study.do]
    G --> I
    
    I --> J[Event Study<br/>lib/estimate/event_study.do]
    I --> K[ATET Variant<br/>lib/estimate/event_study_atet.do]
    
    J --> L[dCov CSV Output]
    K --> M[ATET CSV Output]
    
    C --> N[Variance Decomp<br/>lib/estimate/xt2var.do]
    
    O[Monte Carlo<br/>lib/create/montecarlo.do] --> P[placebo_montecarlo.dta]
    P --> J
    P --> K
    
    Q[KSS MATLAB Routines<br/>lib/KSS/] --> R[AKM Correction<br/>sigma2_psi, sigma2_alpha]
    
    S[Bloom et al. Data<br/>input/bloom-et-al-2012/] --> T[Autonomy Analysis<br/>lib/estimate/bloom_autonomy_analysis.do]
```

---

## Testing

Placebo validation tests are located in [`/lib/test/placebo.do`](repo://lib/test/placebo.do), which collapses event-time outcomes into pre/post periods by skill-change category (worse, same, better) to check balancing of the placebo groups. Network connectivity tests are in [`/lib/test/test_network.jl`](repo://lib/test/test_network.jl).

---

## Configuration and Parameters Summary

| Parameter | Default | Used By |
|-----------|---------|---------|
| `pre` | 4 | event_study.do, event_study_atet.do, xt2var.do |
| `post` | 3 | event_study.do, event_study_atet.do, xt2var.do |
| `event_window_start` | -4 | setup_event_study.do |
| `event_window_end` | 3 | setup_event_study.do |
| `baseline_year` | -1 | setup_event_study.do |
| `cluster` | `frame_id_numeric` | setup_event_study.do, revenue_function.do |
| `random_seed` | 2181 | setup_event_study.do |
| `T_min` | 1 | setup_event_study.do |
| `within_firm_skill_min` | -1 | manager_value.do |
| `within_firm_skill_max` | 1 | manager_value.do |
