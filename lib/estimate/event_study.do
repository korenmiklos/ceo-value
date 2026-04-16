args sample outcome montecarlo fixed_effects

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
* Helper: swap e(b_naive)/e(V_naive) into e() and capture with e2frame
* =============================================================================

* Call 1: beta — plain xt2denoise, detail for naive
* e(b)       -> coef_dbeta  (denoised, all-corrected)
* e(b_naive) -> coef_beta1  (naive, no correction)
* e(cov1)    -> coef_Cov1   (naive covariance)
* e(cov_diff) -> coef_dCov  (denoised covariance)
* also grab Var1, dVar, Var0 from e(var_z1) and e(true_var_z)
* =============================================================================

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') detail

capture frames drop _dbeta _beta1 _dCov _Cov1
e2frame, generate(_dbeta) numeric

tempname b_naive V_naive Var1_mat dVar_mat Cov V_Cov Cov_naive V_Cov_naive
matrix `b_naive'      = e(b_naive)
matrix `V_naive'      = e(V_naive)
matrix `Var1_mat'     = e(var_z1)
matrix `dVar_mat'     = e(true_var_z)
matrix `Cov'          = e(cov_diff)
matrix `V_Cov'        = e(V_cov_diff)
matrix `Cov_naive'    = e(cov1)
matrix `V_Cov_naive'  = e(V_cov_naive)
scalar _N_obs         = e(N)

ereturn post `b_naive' `V_naive', obs(`=_N_obs')
e2frame, generate(_beta1) numeric
ereturn post `Cov' `V_Cov', obs(`=_N_obs')
e2frame, generate(_dCov) numeric
ereturn post `Cov_naive' `V_Cov_naive', obs(`=_N_obs')
e2frame, generate(_Cov1) numeric


* =============================================================================
* Call 2: VarY — xt2denoise with cov detail, z = outcome itself
* Cov(dY, dY) = Var(dY), so:
* e(b) with cov   -> coef_dVarY  (debiased outcome variance)
* e(b_naive)      -> coef_VarY1  (naive outcome variance, treated only)
* VarY0 = VarY1 - dVarY
* setup_event_study already set fake_manager_skill = mean(outcome) by spell,
* so we need to rebuild it here using outcome as z directly
* =============================================================================

* replace manager_skill with mean(outcome) relative to baseline, spell-level
* (setup already did this for fixed_effects; if outcome == fixed_effects it's done;
*  if they differ we need to redo for outcome)
if "`outcome'" != "`fixed_effects'" {
    drop manager_skill
    egen manager_skill = mean(`outcome'), by(fake_id ceo_spell)
}

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') cov detail

capture frames drop _dVarY _VarY1
e2frame, generate(_dVarY) numeric

matrix `b_naive' = e(b_naive)
matrix `V_naive' = e(V_naive)
ereturn post `b_naive' `V_naive', obs(`=_N_obs')
e2frame, generate(_VarY1) numeric

* =============================================================================
* Compute scalar Var1, dVar, Var0 from pre-treatment columns only
* dz = z_after - z_before is spell-level, so its variance is a single number.
* We average over pre-treatment event times (cols 1..pre) to match xt2var,
* which estimated Var0/Var1 from pre-period data only.
* Pre-treatment columns are 1..pre in the matrix (event times -pre..-1,
* skipping the baseline col which is stored as 0 anyway).
* =============================================================================

local Var1 = 0
local dVar = 0
forvalues k = 1/`pre' {
    local Var1 = `Var1' + `Var1_mat'[1, `k']
    local dVar = `dVar' + `dVar_mat'[1, `k']
}
local Var1 = `Var1' / `pre'
local dVar = `dVar' / `pre'
local Var0 = `Var1' - `dVar'

* =============================================================================
* Build unified dCov frame with all series for both exhibit scripts
* Columns needed by event_study2/3.do:
*   beta:  coef_beta1, coef_beta0, coef_dbeta  + CI bands
*   Cov:   coef_Cov1,  coef_Cov0,  coef_dCov   + CI bands
*   VarY:  coef_VarY1, coef_VarY0, coef_dVarY  + CI bands
* Also needed by outcomes exhibit:
*   coef_cov_beta (dCov/Var1), coef_var_beta (Cov1/dVar)
* =============================================================================

foreach f in _dbeta _beta1 _dCov _Cov1 _dVarY _VarY1 {
    frame `f' {
        tempfile f`f'
        save `f`f''
    }
}

* build a small dataset: one row per event time with Var1, dVar, Var0
capture frames drop dCov
frame create dCov

frame dCov {
    * --- beta series ---
    use `f_dbeta', clear
    rename (coef lower upper) (coef_dbeta lower_dbeta upper_dbeta)
    generate se_dbeta = (upper_dbeta - lower_dbeta) / (2 * invnormal(0.975))

    merge 1:1 xvar using `f_beta1', nogen
    rename (coef lower upper) (coef_beta1 lower_beta1 upper_beta1)
    generate se_beta1 = (upper_beta1 - lower_beta1) / (2 * invnormal(0.975))

    * --- Cov series ---
    merge 1:1 xvar using `f_dCov', nogen
    rename (coef lower upper) (coef_dCov lower_dCov upper_dCov)
    generate se_dCov = (upper_dCov - lower_dCov) / (2 * invnormal(0.975))

    merge 1:1 xvar using `f_Cov1', nogen
    rename (coef lower upper) (coef_Cov1 lower_Cov1 upper_Cov1)
    generate se_Cov1 = (upper_Cov1 - lower_Cov1) / (2 * invnormal(0.975))

    generate coef_Cov0 = coef_Cov1 - coef_dCov
    generate se_Cov0   = sqrt(se_Cov1^2 + se_dCov^2)
    generate lower_Cov0 = coef_Cov0 - invnormal(0.975) * se_Cov0
    generate upper_Cov0 = coef_Cov0 + invnormal(0.975) * se_Cov0

    * --- VarY series ---
    merge 1:1 xvar using `f_dVarY', nogen
    rename (coef lower upper) (coef_dVarY lower_dVarY upper_dVarY)
    generate se_dVarY = (upper_dVarY - lower_dVarY) / (2 * invnormal(0.975))

    merge 1:1 xvar using `f_VarY1', nogen
    rename (coef lower upper) (coef_VarY1 lower_VarY1 upper_VarY1)
    generate se_VarY1 = (upper_VarY1 - lower_VarY1) / (2 * invnormal(0.975))

    generate coef_VarY0 = coef_VarY1 - coef_dVarY
    generate se_VarY0   = sqrt(se_VarY1^2 + se_dVarY^2)
    generate lower_VarY0 = coef_VarY0 - invnormal(0.975) * se_VarY0
    generate upper_VarY0 = coef_VarY0 + invnormal(0.975) * se_VarY0

    rename xvar t

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

    generate Rsq1 = (coef_Cov1)^2 / (coef_VarY1 * `Var1')
    generate dRsq = (coef_dCov)^2 / (coef_dVarY * `dVar')

    sort t

    export delimited "data/`sample'_`outcome'-`fixed_effects'.csv", replace
}

frames drop _dbeta _beta1 _dCov _Cov1 _dVarY _VarY1
