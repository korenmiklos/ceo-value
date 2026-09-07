---
type: Reference
title: Estimation methodology doc
description: Evidence excerpts from doc/estimation.md, xt2denoise estimator steps.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Estimation methodology doc

## Source

- Path: `doc/estimation.md`
- SHA-256: `c9100ef0b25489586b1189d5fda7b369e8ec636c7d818330e93f75bfcfbf29c3`
- Inspected: exact source slices below

## Excerpts

### Lines 1-9
```text
# Estimation Method: xt2denoise

- **Purpose**: Corrects small-sample bias in fixed-effect estimates of second moments (variances, covariances) in panel event studies
- **Core idea**: Uses a placebo control group to difference out the noise component from treatment group moments
- **Key identification**: True variance = Var(treated) - Var(control)
- **Debiased coefficient**: β = (Cov(dy, dz | treated) - Cov(dy, dz | control)) / (Var(dz | treated) - Var(dz | control))

## Estimation Steps

```

### Lines 11-29
```text

- For each panel group g, compute mean z before treatment: z_before_g = mean(z | eventtime < 0)
- Compute mean z after treatment: z_after_g = mean(z | eventtime >= 0)
- Quality change: dz_g = z_after_g - z_before_g
- This is a group-level scalar, constant across all time periods for that group

### Step 2: Remove group fixed effects from y

- Compute baseline y at eventtime = -1: yg = mean(y | eventtime == -1) for each group
- Demeaned outcome: dy_it = y_it - yg
- This removes time-invariant group fixed effects from the outcome

### Step 3: Remove event-time × treatment-group means from dy

- Compute group-specific means by event time: dy_mean_et = mean(dy | eventtime, treated/control)
- Fully demeaned outcome: dy_demean_it = dy_it - dy_mean_et
- This removes any systematic event-time patterns specific to each treatment group

### Step 4: Construct naive dz (for comparison estimator)
```

### Lines 31-59
```text
- For treated groups: dz_naive = dz_g; for control groups: dz_naive = 0
- Demean dz_naive by event time only (across full sample): dz_naive_mean_et = mean(dz_naive | eventtime)
- dz_naive_demean = dz_naive - dz_naive_mean_et

### Step 5: Compute second moments

- dy² = dy_demean²
- dz² = (dz_g - dz_mean_et_group)² where dz is demeaned by eventtime × treatment-group
- dydz = dy_demean × dz_demean
- dz²_naive = dz_naive_demean²
- dydz_naive = dy_demean × dz_naive_demean

### Step 6: (Optional) Excess variance correction

- If `excessvariance` is specified, estimate variance ratios from pre-treatment periods:
  - c_z = Var(dz | treated, pre) / Var(dz | control, pre)
  - c_y = Var(dy | treated, pre) / Var(dy | control, pre)
- Scale control group variables: dy_control *= sqrt(c_y), dz_control *= sqrt(c_z)
- Recompute dydz and dz² with scaled variables

### Step 7: Estimate covariances and variances by event time

**Naive estimator (treated group only):**
- Regress dydz_naive on event-time indicators: `regress dydz_naive ibn.eventtime100, nocons cluster(cluster)`
- Extract coefficients → cov1 (Cov(dy, dz | treated) by event time)
- Regress dz²_naive on event-time indicators → var_z1 (Var(dz | treated) by event time)

**Debiased estimator (difference treated - control):**
- Use `areg dydz c.evert#ibn.eventtime100, absorb(eventtime100) cluster(cluster)` to estimate treated - control difference
```

## Notes

- Matches the implementation in `lib/estimate/xt2var.do` (naive cov1/dCov difference, Var0/Var1/dVar difference).
- The doc is a methods exposition, not code; no hash anchor beyond this file.
