---
type: concept
title: Placebo-Controlled Event Study Design
description: Explains the identification strategy that compares actual CEO transitions to placebo (randomly assigned fake) transitions to separate true managerial effects from spurious correlations, including the xt2denoise estimation method for debiasing second moments.
tags: [event-study, placebo, xt2denoise, identification, CEO-effects, difference-in-differences, variance-decomposition, ATET]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-06T17:56:56.777Z
sources:
  - id: openwiki-source-0db263135b975b680f33a2e2
    resource: repo://doc/2025-09-18-placebo.md
  - id: openwiki-source-742e5d72adc303e660199ef2
    resource: repo://doc/estimation.md
  - id: openwiki-source-f85faafafeb554812fa0eed3
    resource: repo://lib/create/event_study_sample.do
  - id: openwiki-source-2a84a273bb200e9b22c6ecfa
    resource: repo://lib/create/montecarlo.do
  - id: openwiki-source-d14dd673ea608af03e9d9544
    resource: repo://lib/estimate/event_study_atet.do
  - id: openwiki-source-f626faeec630004c3392a141
    resource: repo://lib/estimate/event_study.do
  - id: openwiki-source-e9e02b9d834f8e298693cb09
    resource: repo://lib/estimate/setup_event_study.do
  - id: openwiki-source-3ce4cfc25b9848c4c80a32e6
    resource: repo://lib/estimate/xt2var.do
generated: { by: "openwiki/0.5.0", at: "2026-09-06T17:56:56.777Z" }
---

# Placebo-Controlled Event Study Design

## Overview

The placebo-controlled event study is the core causal identification design in the CEO Value Research Project. It separates true managerial value added from spurious correlations by comparing actual CEO transitions to **placebo transitions** — randomly assigned fake transitions constructed in firms that experience no real CEO change during a defined event window.

The key insight is not that treated firms are systematically different from non-switching firms, but that standard event studies conflate true managerial impact with small-sample measurement noise from TFP estimation. By creating "fake" CEO transitions in control firms that match the timing and cohort distribution of actual changes, the design isolates mechanical bias arising from limited mobility and noisy productivity estimates.

## Identification Strategy

### Core Logic

The identification rests on a simple differencing argument:

> **True variance** = Var(outcome | treated) − Var(outcome | placebo)
>
> **Debiased coefficient** = (Cov(dy, dz | treated) − Cov(dy, dz | placebo)) / (Var(dz | treated) − Var(dz | placebo))

If the placebo transitions capture only noise and transitory shocks (since no actual CEO change occurred), then subtracting placebo-group moments from treatment-group moments removes the noise component. What remains reflects the causal contribution of CEO quality.

### Why Standard Event Studies Fail

Naive event studies that only examine treated firms suffer from two sources of bias:

1. **Dynamic endogeneity**: Firms tend to change CEOs during periods of declining performance or coincident shocks (e.g., acquisitions, capital changes). This creates pre-trends that are unrelated to CEO quality.
2. **Measurement noise**: Manager skill is estimated from short spells (often 2-3 years), producing noisy fixed effects. Labeling a transition as "better" or "worse" based on noisy estimates creates mechanical reversion to the mean.

The placebo design addresses both threats simultaneously. Placebo transitions in non-switching firms experience the same noise structure but no actual CEO change, so differencing removes the noise-driven mechanical component.

### Second-Moment Logic

Beyond mean effects, the design exploits a variance decomposition insight. If CEO quality (ΔZ) matters for firm performance, the variance of outcomes should increase after a true CEO change — different managers produce different outcomes. Placebo transitions, where no actual change occurred, should not display such a structural break beyond noise accumulation. Comparing second moments (variances and covariances) between actual and placebo transitions therefore provides a diagnostic of genuine managerial impact.

## Three-Step Process

### Step 1: Identify Actual CEO Transitions

The script [`/lib/create/event_study_sample.do`](repo://lib/create/event_study_sample.do) identifies firms with clean CEO transitions from the analysis sample (`temp/analysis-sample.dta`):

- Selects firms with ≤2 CEOs (single-CEO or two-CEO spells)
- Focuses on consecutive, non-overlapping CEO spells
- Requires spells to have at least 1 observation before and after the transition
- Defines an event window of -4 to +3 years around the change year
- Applies sample filters: `full`, `fnd2non` (founder-to-non-founder), `non2non`, `one2one`, `twos`, `small`, `large`, `gap`, `nogap`, `gender`, `nogender`

From approximately 3.5 million firm-year observations, roughly 18,000+ treated firms with clean CEO changes are identified.

### Step 2: Generate Placebo Transitions

Placebo transitions are constructed in [`/lib/create/event_study_sample.do`](repo://lib/create/event_study_sample.do) using a stratified matching design:

1. **Matching on strata**: Control firms must match treated firms on cohort (founding year), sector, and max size.
2. **Window compatibility**: Control firms must have no actual CEO change within an event window weakly larger than the treatment window.
3. **Timing distribution**: Placebo change years are randomly assigned to match the empirical `t0` distribution (year of change within the window) of actual transitions within each stratum.
4. **Sampling probability**: The target is `TARGET_N_CONTROL = 10` control firms per treated firm. Sampling weights are computed as `MULTIPLE × N_treated / n_control` where `MULTIPLE = 10 / mean(N_treated)`.
5. **Weighting**: Each placebo observation carries a weight `weight = N_treated / n_control` to ensure balanced representation.

The resulting dataset (`temp/<variation>_placebo_<sample>.dta`) contains both actual and placebo transitions with a shared `fake_id`, a `placebo` indicator (0 = actual, 1 = placebo), `change_year`, event window bounds, and sampling weights.

### Step 3: Estimate Treatment Effects

The estimation pipeline proceeds in two sub-steps:

#### Setup: [`/lib/estimate/setup_event_study.do`](repo://lib/estimate/setup_event_study.do)

This helper merges the placebo-augmented dataset with manager skill estimates from `temp/manager_value_spell.dta`, creates event-time variables relative to `change_year`, and constructs treatment indicators:

| Indicator | Definition |
|-----------|------------|
| `actual_ceo` | `event_time >= 0 & placebo == 0` |
| `placebo_ceo` | `event_time >= 0 & placebo == 1` |
| `better_ceo` | `event_time >= 0 & good_ceo == 1` (where `good_ceo` means `MS2 > MS1`) |
| `worse_ceo` | `event_time >= 0 & good_ceo == 0` |

It also:
- Demeans outcomes by industry-year (`teaor08_2d#year`) cells to absorb industry-specific time trends
- Drops firms with missing outcomes in any event-time cell
- Ensures every fake_id has at least `T_min` observations in both CEO spells
- Normalizes `manager_skill` to the spell-level mean of the outcome, ensuring consistency

**Key parameters**:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `event_window_start` | -4 | First pre-treatment event time |
| `event_window_end` | 3 | Last post-treatment event time |
| `baseline_year` | -1 | Reference year for deviations |
| `pre` | 4 | Number of pre-treatment periods |
| `post` | 3 | Number of post-treatment periods |
| `cluster` | `frame_id_numeric` | Clustering variable for standard errors |
| `random_seed` | 2181 | Seed for reproducible subsampling |
| `T_min` | 1 | Minimum observations per spell |

#### Main estimation: [`/lib/estimate/event_study.do`](repo://lib/estimate/event_study.do)

Two calls to `xt2denoise` implement the core estimation:

**Call 1 (beta coefficients):**
```
xt2denoise <outcome>, z(manager_skill) treatment(actual_ceo) control(placebo_ceo) pre(4) post(3) detail [excesssvariance]
```

**Call 2 (outcome variance):** Re-estimates with `z = manager_skill` set to the spell-level mean of the outcome itself, producing debiased outcome variance estimates.

## xt2denoise Methodology

The `xt2denoise` Stata command (part of the `xt2treatments` package) implements the placebo-controlled denoising estimator. The algorithm proceeds through the following steps:

### Step 1: Compute quality change (dz) per group

For each group `g` (defined by matched strata), compute the pre-treatment mean of `z` (manager skill), the post-treatment mean, and their difference:

```
z_before_g = mean(z | event_time < 0)
z_after_g = mean(z | event_time >= 0)
dz_g = z_after_g - z_before_g
```

### Step 2: Remove group fixed effects from outcome `y`

```
y_g = mean(y | event_time == -1)    // baseline at event time -1
dy_it = y_it - y_g                  // demeaned outcome
```

### Step 3: Remove event-time × treatment-group means

```
dy_mean_et = mean(dy | event_time, treated/control)  // group-specific event-time means
dy_demean_it = dy_it - dy_mean_et                     // fully demeaned
```

### Step 4: Construct naive dz

For treated groups: `dz_naive = dz_g`. For control groups: `dz_naive = 0`. Demeaned by event time across the full sample.

### Step 5: Compute second moments

- `dy² = dy_demean²`
- `dz² = (dz_g - dz_mean_et_group)²` (demeaned by event-time × treatment-group)
- `dydz = dy_demean × dz_demean`

### Step 6: Excess variance correction (optional)

If `excessvariance` is specified, estimate variance ratios from pre-treatment periods:
```
c_z = Var(dz | treated, pre) / Var(dz | control, pre)
c_y = Var(dy | treated, pre) / Var(dy | control, pre)
```
Scale control-group variables by √c_z and √c_y respectively.

### Step 7: Estimate covariances and variances by event time

**Naive estimator** (treated group only):
- `regress dydz_naive ibn.eventtime100, nocons cluster(cluster)` → `cov1` (Cov(dy, dz | treated))
- `regress dz²_naive ibn.eventtime100, nocons cluster(cluster)` → `var_z1` (Var(dz | treated))

**Debiased estimator** (treated − control difference):
- `areg dydz c.evert#ibn.eventtime100, absorb(eventtime100) cluster(cluster)` → `cov_diff = Cov1 - Cov0`
- Similarly for `dz²` → `var_z_diff = Var_z1 - Var_z0` = true variance of `z`

### Step 8: Compute debiased beta and standard errors

```
β[t] = cov_diff[t] / true_var_z[t]          // debiased beta by event time
V_beta[i,j] = V_cov_diff[i,j] / (true_var_z[i] × true_var_z[j])
se_beta[t] = sqrt(V_beta[t,t])
```

The naive beta is `β_naive[t] = cov1[t] / var_z1[t]` with `se_beta_naive[t] = se_cov1[t] / |var_z1[t]|`.

### Step 9: ATET computation

If `baseline(atet)` is specified (in [`/lib/estimate/event_study_atet.do`](repo://lib/estimate/event_study_atet.do)), event times are collapsed into pre (event_time < 0) and post (event_time >= 0):

```
ATET = β_post - β_pre
SE(ATET) = sqrt(Var(β_post) + Var(β_pre) - 2 × Cov(β_pre, β_post))
```

### Step 10: Output

Returns are stored in `e(b)` and `e(V)` for the denoised estimates, and `e(b_naive)` and `e(V_naive)` for the naive comparison. Additional matrices capture `cov1`, `var_z1`, `cov_diff`, `var_z_diff`, `true_var_z`, `n1`, `n0`.

## Output Series

The main event study script produces a unified dataset (exported as CSV) with the following series by event time `t`:

| Series | Formula | Interpretation |
|--------|---------|----------------|
| `coef_dbeta` | `dCov / dVar` | Denoised manager beta (bias-corrected via placebo) |
| `coef_beta1` | `Cov1 / Var1` | Naive manager beta (treated only, no correction) |
| `coef_beta0` | `Cov0 / Var0` | Placebo manager beta (noise-only benchmark) |
| `coef_dCov` | `Cov1 − Cov0` | Denoised covariance difference |
| `coef_Cov1` | — | Naive covariance (treated only) |
| `coef_Cov0` | `Cov1 − dCov` | Placebo covariance (noise component) |
| `coef_dVarY` | `VarY1 − VarY0` | Denoised outcome variance difference |
| `coef_VarY1` | — | Naive outcome variance (treated) |
| `coef_VarY0` | `VarY1 − dVarY` | Placebo outcome variance |
| `coef_cov_beta` | `dCov / Var1` | Covariance-only corrected beta |
| `coef_var_beta` | `Cov1 / dVar` | Variance-only corrected beta |
| `Rsq` | `Cov1² / (VarY × Var1)` | Naive goodness of fit |
| `dRsq` | `dCov² / (VarY × dVar)` | Debiased goodness of fit |

Each series has companion `lower_*` and `upper_*` columns for 95% confidence intervals (constructed using normal approximation: `coef ± 1.96 × se`).

Standard errors for beta estimates use a delta-method correction:

```
se(β) = se(Cov)/E(X) × sqrt(1 + β² × Var(X)/Var(Y))
```

where `Var_ratio = (se_Var / se_Cov)²`.

## ATET Variant

[`/lib/estimate/event_study_atet.do`](repo://lib/estimate/event_study_atet.do) estimates a single ATET parameter rather than the full dynamic event-time path. It uses `xt2denoise` with the `baseline(atet)` option and produces a CSV with columns for pre- and post-treatment variance and covariance components.

Key differences from the main event study:
- **No industry-year demeaning** step
- **Single ATET parameter** (pre vs. post collapse) instead of event-time coefficients
- **Matrix-based output** captured as Stata matrices rather than frame series

## Variance Decomposition (xt2var)

[`/lib/estimate/xt2var.do`](repo://lib/estimate/xt2var.do) implements the placebo-controlled excess variance methodology manually, without calling `xt2denoise`. It serves as both a transparent implementation and a validation of the automated routine.

### Methodology

1. **Deviation from baseline**: For each firm, outcomes and fixed effects are expressed as deviations from the last pre-treatment year (`g`).
2. **Event time**: `e = t − g − 1`, ranging from -pre to +post.
3. **Group formation**: Firms are grouped by pre/post observation pattern.
4. **Excess variance estimation**: An iterative fixed-point algorithm (4 iterations) estimates `eVarY` and `eVarZ` — the excess variance ratios — by regressing squared deviations in the treated group on the placebo-group mean squared deviations.
5. **Scaling**: Placebo-group squared moments are scaled by excess variance ratios to match treated-group noise levels.
6. **Regression**: `reghdfe` estimates event-time coefficients for variance (`dY²`), covariance (`dY·dX`), and driver variance (`dX²`), separately for treated-only (biased) and treated-minus-placebo (unbiased).

## Monte Carlo Validation

[`/lib/create/montecarlo.do`](repo://lib/create/montecarlo.do) generates synthetic data with known treatment effects to validate the estimation methodology. The data-generating process:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `N_changes` | 10,000 | Number of simulated CEO changes |
| `hazard` | 0.2 | Annual hazard of CEO change |
| `sigma_z` | 0.1 | Std dev of CEO ability |
| `true_effect` | 0.0798 | Expected true effect (`E[|z|]`) |
| `sigma_epsilon0` | 0.05 | TFP growth noise (untreated) |
| `sigma_epsilon1` | 0.06 | Excess TFP noise (treated firms) |
| `rho` | 0.97 | TFP autocorrelation |
| `control_treated_ratio` | 9 | Placebo firms per treated firm |

The simulation tests whether `xt2denoise` recovers the true ATET of ~0.08 and correctly separates variance effects from mean effects.

## Sample Variations

The design supports multiple sample specifications defined in [`/lib/create/event_study_sample.do`](repo://lib/create/event_study_sample.do):

| Sample | Definition |
|--------|------------|
| `full` | All clean transitions |
| `fnd2non` | Founder CEO replaced by non-founder |
| `non2non` | Non-founder replaced by non-founder |
| `one2one` | Both spells have exactly 1 CEO per year |
| `twos` | At least one spell has 2 CEOs |
| `small` | Firms with `max_size == 1` (small) |
| `large` | Firms with `max_size == 2` (large) |
| `gap` | Successive CEOs differ in age by >10 years |
| `nogap` | Successive CEOs differ in age by ≤10 years |
| `gender` | CEO gender changes between spells |
| `nogender` | CEO gender unchanged |

## Invariants and Failure Modes

- **Across-component incomparability**: Manager skill estimates from different connected components of the manager-manager co-employment network are not directly comparable. The event study uses within-firm mean comparisons (`manager_skill` = mean of outcome by spell), avoiding this issue.
- **Excess variance scaling**: If the `excessvariance` option is used and pre-treatment variances differ substantially between treated and placebo groups, the scaling factors (`c_z`, `c_y`) may be imprecisely estimated. The script uses 4 fixed-point iterations to estimate these ratios.
- **Sample size requirements**: The design requires both treated and placebo observations within each matched group (`N_treated > 0 & N_control > 0`). Groups without both are dropped.
- **Placebo contamination**: If a firm selected as a placebo has an actual CEO change within its event window due to data errors or alternative definitions, it would bias the placebo toward the treated pattern, reducing the estimated effect.
- **Spell-length distribution**: The Monte Carlo simulation reveals that the design's performance depends on correctly matching the empirical distribution of spell lengths between treated and placebo groups.

## Relationship to Other Components

<!-- openwiki: mermaid parse failed and this diagram was converted to a text fence so it does not break rendering. Fix the diagram source and restore the mermaid fence. Parser error: Heuristic: an unescaped angle bracket inside a label breaks rendering; rephrase the label. -->
```text
flowchart LR
    A[Manager Skill Estimation<br/>manager_value.do] --> B[manager_value_spell.dta]
    C[Event Study Sample<br/>event_study_sample.do] --> D[Placebo Data<br/>placebo_sample.dta]
    B --> E[Setup Event Study<br/>setup_event_study.do]
    D --> E
    E --> F[Main Event Study<br/>event_study.do]
    E --> G[ATET Variant<br/>event_study_atet.do]
    E --> H[Variance Decomp<br/>xt2var.do]
    I[Monte Carlo<br/>montecarlo.do] --> F
    I --> G
    F --> J[dCov CSV Output]
    G --> K[ATET CSV Output]
```

## References

- Detailed estimation steps: [`/doc/estimation.md`](repo://doc/estimation.md)
- Technical methodology discussion: [`/doc/2025-09-18-placebo.md`](repo://doc/2025-09-18-placebo.md)
- Full estimation system architecture: [`/openwiki/architecture/estimation-system.md`](repo://openwiki/architecture/estimation-system.md)
- Manager skill estimation procedure: [`/openwiki/concepts/manager-skill-estimation.md`](repo://openwiki/concepts/manager-skill-estimation.md)
