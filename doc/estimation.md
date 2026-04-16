# Estimation Method: xt2denoise

- **Purpose**: Corrects small-sample bias in fixed-effect estimates of second moments (variances, covariances) in panel event studies
- **Core idea**: Uses a placebo control group to difference out the noise component from treatment group moments
- **Key identification**: True variance = Var(treated) - Var(control)
- **Debiased coefficient**: β = (Cov(dy, dz | treated) - Cov(dy, dz | control)) / (Var(dz | treated) - Var(dz | control))

## Estimation Steps

### Step 1: Compute quality change (dz) for each group

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
- Extract interaction coefficients → cov_diff = Cov1 - Cov0
- Similarly for dz² → var_z_diff = Var_z1 - Var_z0 = true_var_z

### Step 8: Compute debiased beta and standard errors

- Beta: β[t] = cov_diff[t] / true_var_z[t] for each event time t
- Full variance-covariance matrix: V_beta[i,j] = V_cov_diff[i,j] / (true_var_z[i] × true_var_z[j])
- Standard errors: se_beta[t] = sqrt(V_beta[t,t])

**Naive beta:**
- β_naive[t] = cov1[t] / var_z1[t]
- se_beta_naive[t] = se_cov1[t] / |var_z1[t]|

### Step 9: ATET computation (if baseline == "atet")

- Collapses event times into pre (eventtime < 0) and post (eventtime >= 0)
- ATET = β_post - β_pre
- SE(ATET) = sqrt(Var(β_post) + Var(β_pre) - 2 × Cov(β_pre, β_post))
- Same computation for naive estimator using V_cov1

### Step 10: Post results

- Store e(b) = beta, e(V) = variance-covariance matrix
- Store additional matrices: cov1, var_z1, cov_diff, var_z_diff, true_var_z, n1, n0, b_naive, V_naive, cov_debiased, V_cov_debiased, V_cov_naive
- Display regression table using Stata's _coef_table

## Options

- **Excess variance correction**: Scales control group moments when noise variance differs between treatment and control groups (c_z, c_y ratios from pre-treatment periods)
- **Baseline**: Can use specific pre-period (-k), average of pre-periods, or ATET (post - pre average)
- **Naive estimator**: Also computed for comparison (uses only treated group, no differencing)

## Output

- Returns coefficients and standard errors in e(b) and e(V)
- Stores naive, debiased, and covariance matrices for post-estimation
