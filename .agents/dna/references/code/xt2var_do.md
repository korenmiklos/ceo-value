---
type: Reference
title: xt2denoise variance estimator code
description: Evidence excerpts from lib/estimate/xt2var.do, the placebo debiasing estimator core.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# xt2denoise variance estimator code

## Source

- Path: `lib/estimate/xt2var.do`
- SHA-256: `b15c733a21a3794d2976249b7f5c65c9bc727c008c3f99e1e0be704b489cacd4`
- Inspected: exact source slices below

## Excerpts

### Lines 1-23
```text
args outcome treatment treated_group X cluster fixed_effects
confirm numeric variable `outcome'
confirm numeric variable `treatment'
confirm numeric variable `treated_group'
confirm numeric variable `X'

* you can compute fixed effects on variables other than the outcome variable
if ("`fixed_effects'" == "") {
    local fixed_effects `outcome'
}
confirm numeric variable `fixed_effects'

local pre 4
local post 3

assert inlist(`treatment', 0, 1)
assert inlist(`treated_group', 0, 1)

tempvar group T1 T0
tempvar g e Yg dY E dY2 Xg dX EX dYdX dX2 t0 t1 VarX VarY Z EZ Zg dZ dZ2 VarZ

xtset
local i = r(panelvar)
```

### Lines 36-62
```text
* form groups based on the shape of the design matrix
egen `T1' = total(`treatment'), by(`i')
egen `T0' = total(!`treatment'), by(`i')
egen `group' = group(`T1' `T0')
table `group', stat(min `T0' `T1')

* compute covariances with driver variable
egen `E' = mean(`dY'), by(`g' `t' `treated_group')
egen `EX' = mean(`X'), by(`g' `t' `treated_group')
egen `EZ' = mean(`dZ'), by(`g' `t' `treated_group')
generate `dY2' = (`dY' - `E')^2
generate `dZ2' = (`dZ' - `EZ')^2
generate `dYdX' = (`dY' - `E') * (`X' - `EX')
generate `dX2' = (`X' - `EX')^2

* the least-square estimate of excess variance is a nocons OLS
egen `VarZ' = mean(cond(!`treated_group', `dZ2', .)), by(`e' `group')
egen `VarY' = mean(cond(!`treated_group', `dY2', .)), by(`e' `group')
forvalues k = 1/4 {
    regress `dZ2' `VarZ' if `treated_group' == 1 & `e' < 0, noconstant
    local eVarZ = _b[`VarZ']
    regress `dY2' `VarY' if `treated_group' == 1 & `e' < 0, noconstant
    local eVarY = _b[`VarY']
    drop `VarZ' `VarY'
    egen `VarZ' = mean(cond(!`treated_group', `dZ2', `dZ2' / `eVarZ')), by(`e' `group')
    egen `VarY' = mean(cond(!`treated_group', `dY2', `dY2' / `eVarY')), by(`e' `group')
}
```

### Lines 99-114
```text
* first compute covariance in treated group only - this is biased
reghdfe `dYdX' et_m_`pre'-et_m_2 et_p_0-et_p_`post'  if `treated_group' == 1, absorb(`group') vce(cluster `cluster') nocons
e2frame, generate(Cov1)

* difference to placebo group - this is unbiased
reghdfe `dYdX' et_m_`pre'-et_m_2 et_p_0-et_p_`post' , absorb(`group' `e') vce(cluster `cluster') nocons
e2frame, generate(dCov)
**** Do the same for variance

* first compute variance in treated group only - this is biased
reghdfe `dY2' et_m_`pre'-et_m_2 et_p_0-et_p_`post'  if `treated_group' == 1, absorb(`group') vce(cluster `cluster') nocons
e2frame, generate(VarY1)

* difference to placebo group - this is unbiased
reghdfe `dY2' et_m_`pre'-et_m_2 et_p_0-et_p_`post' , absorb(`group' `e') vce(cluster `cluster') nocons
e2frame, generate(dVarY)
```

### Lines 190-214
```text
    sort t

    * report coefficients (previously standardized)
    generate coef_dbeta = coef_dCov / dVar
    generate coef_beta1 = coef_Cov1 / Var1
    generate coef_beta0 = coef_Cov0 / Var0
    generate coef_beta0_excess = coef_Cov0_excess / Var0_excess
    * FIXME: correct standard errors for beta estimates

    * use the delta method to get standard errors for beta
    * Var(beta) = Var(Cov)/E(X)^2 [1 + beta^2 * Var(X)/Var(Y)]
    * so se(beta) = se(Cov)/E(X) sqrt[1 + beta^2 * Var(X)/Var(Y)]

    scalar Var_ratio = (`se_dVar' / se_dCov)^2
    scalar correction = sqrt(1 + Var_ratio * coef_dbeta^2)
    display "Variance correction factor for se(beta): " correction
    generate se_dbeta = se_dCov / dVar * correction

    scalar Var_ratio = (`se_Var1' / se_Cov1)^2
    scalar correction = sqrt(1 + Var_ratio * coef_beta1^2)
    generate se_beta1 = se_Cov1 / Var1 * correction

    scalar Var_ratio = (`se_Var0' / sqrt(se_Cov1^2 + se_dCov^2))^2
    scalar correction = sqrt(1 + Var_ratio * coef_beta0^2)
    generate se_beta0 = se_Cov0 / Var0 * correction
```

## Notes

- `treated_group` flags treated (1 vs placebo 0}; `treatment` flags post-transition period.
- The placebo sample provides `Var0`/`Cov0`; the treated-only sample provides `Var1`/`Cov1`; the difference `dVar`/`dCov` is the debiased quantity.
- Excess variance correction (`excessvariance` option) scales the control-group moments by variance ratios estimated from pre-treatment periods (lines  55-71}.
- ATET rows are appended as t=99 (lines  164-171}.
