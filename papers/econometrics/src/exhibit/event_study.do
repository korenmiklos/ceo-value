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

if ("`weight_var'" != "") {
    confirm numeric variable `weight_var'
    drop if missing(`weight_var')
}

local pre  4
local post 3

* =============================================================================
* Helper: swap e(b_naive)/e(V_naive) into e() and capture with e2frame
* =============================================================================

* Call 1: beta — plain xt2denoise, detail for naive
* e(b)       -> coef_dbeta  (denoised, all-corrected)
* e(b_naive) -> coef_beta1  (naive, no correction)
* also grab Var1, dVar, Var0 from e(var_z1) and e(true_var_z)
* =============================================================================

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') detail

capture frames drop _dbeta _beta1
e2frame, generate(_dbeta) numeric

tempname b_naive V_naive var_z1 true_var_z
matrix `b_naive'    = e(b_naive)
matrix `V_naive'    = e(V_naive)
matrix `var_z1'     = e(var_z1)
matrix `true_var_z' = e(true_var_z)
scalar _N_obs       = e(N)

ereturn post `b_naive' `V_naive', obs(`=_N_obs')
e2frame, generate(_beta1) numeric

* scalar Var1, dVar, Var0 as column means across event times
local K    = colsof(`var_z1')
local Var1 = 0
local dVar = 0
forvalues k = 1/`K' {
    local Var1 = `Var1' + `var_z1'[1,`k']
    local dVar = `dVar' + `true_var_z'[1,`k']
}
local Var1 = `Var1' / `K'
local dVar = `dVar' / `K'
local Var0 = `Var1' - `dVar'

* =============================================================================
* Call 2: Cov — xt2denoise with cov detail, z = manager_skill
* e(b) with cov option  -> coef_dCov   (debiased covariance)
* e(b_naive) with cov   -> coef_Cov1   (naive covariance, treated only)
* Cov0 = Cov1 - dCov    -> coef_Cov0   (control group covariance)
* =============================================================================

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') cov detail

capture frames drop _dCov _Cov1
e2frame, generate(_dCov) numeric

matrix `b_naive' = e(b_naive)
matrix `V_naive' = e(V_naive)
ereturn post `b_naive' `V_naive', obs(`=_N_obs')
e2frame, generate(_Cov1) numeric

* =============================================================================
* Call 3: VarY — xt2denoise with cov detail, z = outcome itself
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

capture frames drop dCov
frame create dCov

frame dCov {
    * --- beta series ---
    use `f_dbeta', clear
    rename xvar t
    rename (coef lower upper) (coef_dbeta lower_dbeta upper_dbeta)
    generate se_dbeta = (upper_dbeta - lower_dbeta) / (2 * invnormal(0.975))

    merge 1:1 t using `f_beta1', nogen
    rename (coef lower upper) (coef_beta1 lower_beta1 upper_beta1)
    generate se_beta1 = (upper_beta1 - lower_beta1) / (2 * invnormal(0.975))

    * --- Cov series ---
    merge 1:1 t using `f_dCov', nogen
    rename (coef lower upper) (coef_dCov lower_dCov upper_dCov)
    generate se_dCov = (upper_dCov - lower_dCov) / (2 * invnormal(0.975))

    merge 1:1 t using `f_Cov1', nogen
    rename (coef lower upper) (coef_Cov1 lower_Cov1 upper_Cov1)
    generate se_Cov1 = (upper_Cov1 - lower_Cov1) / (2 * invnormal(0.975))


    * --- VarY series ---
    merge 1:1 t using `f_dVarY', nogen
    rename (coef lower upper) (coef_dVarY lower_dVarY upper_dVarY)
    generate se_dVarY = (upper_dVarY - lower_dVarY) / (2 * invnormal(0.975))

    merge 1:1 t using `f_VarY1', nogen
    rename (coef lower upper) (coef_VarY1 lower_VarY1 upper_VarY1)
    generate se_VarY1 = (upper_VarY1 - lower_VarY1) / (2 * invnormal(0.975))

    * --- scalar variances ---
    generate Var1 = `Var1'
    generate dVar = `dVar'

    * --- derived beta series for outcomes exhibit ---
    * cov_beta = dCov / Var1  (only covariance corrected)
    generate coef_cov_beta = coef_dCov / Var1
    generate se_cov_beta   = se_dCov   / Var1
    generate lower_cov_beta = coef_cov_beta - invnormal(0.975) * se_cov_beta
    generate upper_cov_beta = coef_cov_beta + invnormal(0.975) * se_cov_beta

    * var_beta = Cov1 / dVar  (only variance corrected)
    generate coef_var_beta = coef_Cov1 / dVar
    generate se_var_beta   = se_Cov1   / dVar
    generate lower_var_beta = coef_var_beta - invnormal(0.975) * se_var_beta
    generate upper_var_beta = coef_var_beta + invnormal(0.975) * se_var_beta

    sort t

    export delimited "data/`sample'_`outcome'-`FE'.csv, replace
}

frames drop _dbeta _beta1 _dCov _Cov1 _dVarY _VarY1
