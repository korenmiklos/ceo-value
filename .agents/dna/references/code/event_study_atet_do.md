---
type: Reference
title: ATET event study code
description: Evidence excerpt from lib/estimate/event_study_atet.do, ATET CSV production.
status: draft
generated:
  by: build-replication-wiki
  at: 2026-09-07T09:44:50Z
---

# ATET event study code

## Source

- Path: `lib/estimate/event_study_atet.do`
- SHA-256: `2ac2a4bb8a3c3bab33aea7ce4ffccfab3a6b53ab7de28da4751f372d6b49089a`
- Inspected: exact source slices below

## Excerpts

### Lines 1-18
```text
args variation sample outcome montecarlo fixed_effects excessvariance

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
confirm existence `s'
confirm existence `outcome'

```

### Lines 52-68
```text
xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') detail `excessvariance' baseline(atet)

tempname Cov Cov_naive VarY Var1z dVarz se_naive dse
matrix `Var1z'        = e(var_z1)
matrix `Var1z'        = `Var1z''
matrix `dVarz'        = e(var_z_diff)
matrix `dVarz'        = `dVarz''
matrix `Cov'          = e(cov_diff)
matrix `Cov'          = `Cov''
matrix `Cov_naive'    = e(cov1)
matrix `Cov_naive'    = `Cov_naive''
matrix `VarY'         = e(var_y1)
matrix `se_naive'     = e(V_naive)
matrix `dse'          = e(V)
scalar _N_obs         = e(N)
```

### Lines 74-94
```text
* build a small dataset: one row before and after with Var1, dVar
capture frames drop atet
frame create atet

frame atet {
    svmat `Var1z', names(Var1z)
    svmat `dVarz', names(dVarz)
    svmat `Cov', names(dCov)
    svmat `Cov_naive', names(Cov)
    svmat `VarY', names(VarY)
    svmat `se_naive', names(se_naive)
    svmat `dse', names(dse)
    generate N = _N_obs
    generate Rsq = (Cov1)^2/(VarY1*Var1z1)
    generate dRsq = (dCov1)^2/(VarY1*dVarz1)
    generate i = _n
    replace se_naive = sqrt(se_naive)
    replace dse = sqrt(dse)
    order i Var1z dVarz dCov Cov VarY Rsq dRsq se_naive dse N
    export delimited "data/atet_`variation'_`sample'_`OC'-`FE'.csv", replace
}
```

## Notes

- Collapses event times into pre/post, computing ATET = beta_post - beta_pre (per doc/estimation.md steps}.
- ATET CSV artifacts (`data/atet_*.csv`, 355 files)exist under `papers/econometrics/data/`.
