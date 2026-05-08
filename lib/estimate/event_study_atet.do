args sample outcome montecarlo fixed_effects excessvariance

if ("`fixed_effects'" == "") {
    local fixed_effects `outcome'
}

confirm file "data/placebo_`sample'.dta"
confirm existence `outcome'

do "../../lib/estimate/setup_event_study.do" `sample' `fixed_effects' `montecarlo'
if !("`montecarlo'" == "montecarlo") {
  foreach var in outcome fixed_effects {
    tempvar mean_`var' demean_`var'
    egen double `mean_`var'' = mean(``var''), by(teaor08_2d year)
    generate `demean_`var'' = ``var'' - `mean_`var''
    drop `mean_`var''
  }
  confirm numeric variable `demean_outcome'
  confirm numeric variable `demean_fixed_effects'
  local OC `outcome'
  local FE `fixed_effects'
  local outcome `demean_outcome'
  local fixed_effects `demean_fixed_effects'
}

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

local pre  4
local post 3

* Call 1: beta — plain xt2denoise, detail for naive
* e(cov1)    -> coef_Cov1   (naive covariance)
* e(cov_diff) -> coef_dCov  (denoised covariance)
* also grab Var1, dVar from e(var_z1) and e(true_var_z)
* =============================================================================

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') detail `excessvariance' baseline(atet)

tempname Cov Cov_naive VarY Var1z dVarz
matrix `Var1z'        = e(var_z1)
matrix `Var1z'        = `Var1z''
matrix `dVarz'        = e(var_z_diff)
matrix `dVarz'        = `dVarz''
matrix `Cov'          = e(cov_diff)
matrix `Cov'          = `Cov''
matrix `Cov_naive'    = e(cov1)
matrix `Cov_naive'    = `Cov_naive''
scalar _N_obs         = e(N)

su `outcome' if actual_ceo, det
matrix `VarY'         = r(Var)
* =============================================================================
* Build unified dCov frame with all series for both exhibit scripts
* turn matrices and scalars into csv.
* =============================================================================

* build a small dataset: one row before and after with Var1, dVar
capture frames drop atet
frame create atet

frame atet {
    svmat `Var1z', names(Var1z)
    svmat `dVarz', names(dVarz)
    svmat `Cov', names(dCov)
    svmat `Cov_naive', names(Cov)
    svmat `VarY', names(VarY)
    generate N = _N_obs
    generate Rsq = (Cov[2]-Cov[1])^2/(VarY[1]*(Var1z[1]+Var1z[2])/2)
    generate dRsq = (dCov[2]-Cov[1])^2/(VarY[1]*(dVarz[1]+dVarz[2])/2)
    generate i = _n
    generate t = "pre"
    replace t = "post" if i == 2
    order i t Var1z dVarz dCov Cov VarY Rsq dRsq N
    export delimited "data/atet_`sample'_`OC'-`FE'.csv", replace
}

