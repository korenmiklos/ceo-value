---
type: Reference
title: Event study output code
description: Evidence excerpt from lib/estimate/event_study.do, debiased event-study CSV production.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# Event study output code

## Source

- Path: `lib/estimate/event_study.do`
- SHA-256: `3873eb2e90e44ca748eda3ca121ac58bdc8db68af3019d46f831c358fb8585ce`
- Inspected: exact source slices below

## Excerpts

### Lines 1-18
```text
args variation sample outcome montecarlo fixed_effects excesssvariance

if ("`fixed_effects'" == "") {
    local fixed_effects `outcome'
}

if ("`sample'" == "excessvariance_corr"){
  local s "excessvariance"
}
else {
  local s `sample'
}
confirm file "data/`variation'_placebo_`s'.dta"
confirm existence `variation'
confirm existence `sample'
confirm existence `outcome'

do "../../lib/estimate/setup_event_study.do" `variation' `s' `fixed_effects' `montecarlo'
```

### Lines 56-81
```text
xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') detail `excesssvariance'

capture frames drop _dbeta _beta1 _dCov _Cov1
e2frame, generate(_dbeta) numeric

tempname b_naive V_naive Var1_mat dVar_mat Cov V_Cov Cov_naive V_Cov_naive VarY
matrix `b_naive'      = e(b_naive)
matrix `V_naive'      = e(V_naive)
matrix `Var1_mat'     = e(var_z1)
matrix `dVar_mat'     = e(var_z_diff)
matrix `Cov'          = e(cov_diff)
matrix `V_Cov'        = e(V_cov_diff)
matrix `Cov_naive'    = e(cov1)
matrix `V_Cov_naive'  = e(V_cov_naive)
matrix `VarY'         = e(var_y1)
matrix `VarY'         = `VarY''
scalar _N_obs         = e(N)

ereturn post `b_naive' `V_naive', obs(`=_N_obs')
e2frame, generate(_beta1) numeric
ereturn post `Cov' `V_Cov', obs(`=_N_obs')
e2frame, generate(_dCov) numeric
ereturn post `Cov_naive' `V_Cov_naive', obs(`=_N_obs')
e2frame, generate(_Cov1) numeric
```

### Lines 96-111
```text
if "`outcome'" != "`fixed_effects'" {
    drop manager_skill
    egen manager_skill = mean(`outcome'), by(fake_id ceo_spell)
}

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') cov detail `excesssvariance'

capture frames drop _dVarY _VarY1
e2frame, generate(_dVarY) numeric

matrix `b_naive' = e(b_naive)
matrix `V_naive' = e(V_naive)
ereturn post `b_naive' `V_naive', obs(`=_N_obs')
e2frame, generate(_VarY1) numeric
```

### Lines 192-212
```text

    * --- derived beta series for outcomes exhibit ---
    * cov_beta = dCov / Var1  (only covariance corrected)
    generate coef_cov_beta = coef_dCov / `Var1'
    generate se_cov_beta   = se_dCov   / `Var1'
    generate lower_cov_beta = coef_cov_beta - invnormal(0.975) * se_cov_beta
    generate upper_cov_beta = coef_cov_beta + invnormal(0.975) * se_cov_beta

    * var_beta = Cov1 / dVar  (only variance corrected)
    generate coef_var_beta = coef_Cov1 / `dVar'
    generate se_var_beta   = se_Cov1   / `dVar'
    generate lower_var_beta = coef_var_beta - invnormal(0.975) * se_var_beta
    generate upper_var_beta = coef_var_beta + invnormal(0.975) * se_var_beta

    *Rsquared correction
    svmat `VarY', names(VarY)
    generate Rsq = coef_Cov1^2/(VarY*`Var1')
    generate dRsq = coef_dCov^2/(VarY*`dVar')
    sort t

    export delimited "data/`variation'_`sample'_`OC'-`FE'.csv", replace
```

## Notes

- Produces event-time series CSVs via the `xt2denoise` estimator (a frame-based wrapper around `xt2var.do`}).
- Debiasing principle: placebo moments subtracted from treated moments to yield true variance/covariance.
- Observed CSV artifacts exist under `papers/econometrics/data/` (407 files)and `papers/application/data/` (31 files`.
