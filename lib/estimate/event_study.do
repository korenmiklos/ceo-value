args sample outcome montecarlo fixed_effects weight_var

if ("`fixed_effects'" == "") {
    local fixed_effects `outcome'
}

confirm file "data/placebo_`sample'.dta"
confirm existence `outcome'

do "../../lib/estimate/setup_event_study.do" `sample' `fixed_effects' `montecarlo'
confirm numeric variable `outcome'
confirm numeric variable `fixed_effects'

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

local pre  4
local post 3

* =============================================================================
* Run 1: plain xt2denoise — gives debiased beta (dbeta) and naive beta (beta1)
*         also populates var_z1, true_var_z which we need for Var1 and dVar
* =============================================================================

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') detail

* extract scalar variance estimates
matrix mat_var = e(var_z1)
matrix mat_true_var = e(true_var_z)
* use mean across columns as the single scalar (xt2denoise stores per-period values)
local Var1 = 0
local dVar = 0
local K = colsof(mat_var)
forvalues k = 1/`K' {
    local Var1 = `Var1' + mat_var[1,`k']
    local dVar = `dVar' + mat_true_var[1,`k']
}
local Var1 = `Var1' / `K'
local dVar = `dVar' / `K'
local Var0 = `Var1' - `dVar'

* capture debiased beta path — e(b) / e(V)
capture frames drop _dbeta
e2frame, generate(_dbeta) numeric

* capture naive beta path — swap e(b_naive) into e()
tempname b_naive V_naive
matrix `b_naive' = e(b_naive)
matrix `V_naive' = e(V_naive)
scalar _N_obs    = e(N)
ereturn post `b_naive' `V_naive', obs(`=_N_obs')
capture frames drop _beta1
e2frame, generate(_beta1) numeric

* =============================================================================
* Run 2: xt2denoise with cov — gives cov_debiased (dCov) and cov1 (Cov1)
*         these are the raw covariances before dividing by variance
* =============================================================================

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') cov detail

* capture debiased covariance path — e(b) is cov_debiased when cov option used
capture frames drop _dCov
e2frame, generate(_dCov) numeric

* capture naive covariance path
matrix `b_naive' = e(b_naive)
matrix `V_naive' = e(V_naive)
ereturn post `b_naive' `V_naive', obs(`=_N_obs')
capture frames drop _Cov1
e2frame, generate(_Cov1) numeric

* =============================================================================
* Build unified dCov frame matching xt2var output structure
* series: dbeta (debiased), beta1 (naive/Cov-only), cov_beta (Cov-only corrected),
*         var_beta (Var-only corrected)
* =============================================================================

capture frames drop dCov
frame _dbeta {
    tempfile f_dbeta
    save `f_dbeta'
}
frame _beta1 {
    tempfile f_beta1
    save `f_beta1'
}
frame _dCov {
    tempfile f_dCov
    save `f_dCov'
}
frame _Cov1 {
    tempfile f_Cov1
    save `f_Cov1'
}

frame create dCov
frame dCov {
    use `f_dbeta', clear
    rename (coef lower upper) (coef_dbeta lower_dbeta upper_dbeta)
    generate se_dbeta = (upper_dbeta - lower_dbeta) / (2 * invnormal(0.975))

    merge 1:1 xvar using `f_beta1', nogen
    rename (coef lower upper) (coef_beta1 lower_beta1 upper_beta1)
    generate se_beta1 = (upper_beta1 - lower_beta1) / (2 * invnormal(0.975))

    merge 1:1 xvar using `f_dCov', nogen
    rename (coef lower upper) (coef_dCov lower_dCov upper_dCov)
    generate se_dCov = (upper_dCov - lower_dCov) / (2 * invnormal(0.975))

    merge 1:1 xvar using `f_Cov1', nogen
    rename (coef lower upper) (coef_Cov1 lower_Cov1 upper_Cov1)
    generate se_Cov1 = (upper_Cov1 - lower_Cov1) / (2 * invnormal(0.975))

    rename xvar t

    * derive Cov0 = Cov1 - dCov (control group covariance)
    generate coef_Cov0 = coef_Cov1 - coef_dCov
    generate se_Cov0   = sqrt(se_Cov1^2 + se_dCov^2)

    * scalar variances as constant columns
    generate Var1 = `Var1'
    generate Var0 = `Var0'
    generate dVar = `dVar'

    * cov_beta = dCov / Var1  — only covariance corrected, naive variance
    generate coef_cov_beta = coef_dCov / Var1
    generate se_cov_beta   = se_dCov   / Var1
    * var_beta = Cov1 / dVar  — only variance corrected, naive covariance
    generate coef_var_beta = coef_Cov1 / dVar
    generate se_var_beta   = se_Cov1   / dVar

    * confidence intervals for derived series
    foreach v in cov_beta var_beta Cov0 {
        generate lower_`v' = coef_`v' - invnormal(0.975) * se_`v'
        generate upper_`v' = coef_`v' + invnormal(0.975) * se_`v'
    }

    sort t
}

frames drop _dbeta _beta1 _dCov _Cov1
