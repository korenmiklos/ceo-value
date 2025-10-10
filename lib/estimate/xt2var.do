args outcome treatment treated_group X cluster
confirm numeric variable `outcome'
confirm numeric variable `treatment'
confirm numeric variable `treated_group'
confirm numeric variable `X'

local pre 4
local post 3

assert inlist(`treatment', 0, 1)
assert inlist(`treated_group', 0, 1)

tempvar g e Yg dY E dY2 Xg dX EX dYdX dX2 t0 t1 CovXY VarX VarY

xtset
local i = r(panelvar)
local t = r(timevar)
if "`cluster'" == "" {
    local cluster `i'
}

egen `g' = max(cond(`treatment' == 0, `t', .)), by(`i')
egen `Yg' = mean(cond(`t' == `g', `outcome', .)), by(`i')
generate `dY' = `outcome' - `Yg'
generate `e' = `t' - `g' - 1

egen `E' = mean(`dY'), by(`g' `t' `treated_group')
generate `dY2' = (`dY' - `E')^2


* compute event-time-specific variance correction
* treated group may have difference variance of epsilon
ppmlhdfe `dY2' `treated_group' if `e' < 0, absorb(`g' `t')
local excess_variance = exp(_b[`treated_group']) - 1
display "Excess variance for treated group: `excess_variance' x"
summarize `X', detail

* compute covariances with driver variable
egen `EX' = mean(`X'), by(`g' `t' `treated_group')
generate `dYdX' = (`dY' - `E') * (`X' - `EX')
generate `dX2' = (`X' - `EX')^2
egen `CovXY' = mean(cond(!`treated_group', `dYdX', .)), by(`g' `t')
egen `VarX' = mean(cond(!`treated_group', `dX2', .)), by(`g' `t')
egen `VarY' = mean(cond(!`treated_group', `dY2', .)), by(`g' `t')
replace `dYdX' = `dYdX' - `CovXY' * `excess_variance' if `treated_group'
replace `dX2' = `dX2' - `VarX' * `excess_variance' if `treated_group'
replace `dY2' = `dY2' - `VarY' * `excess_variance' if `treated_group'

summarize `dX2' if `treated_group' == 0, meanonly
local Var0 = r(mean)
summarize `dX2' if `treated_group' == 1, meanonly
local Var1 = r(mean)

generate `t1' = `treatment' & `treated_group'
generate `t0' = `treatment' & !`treated_group'

foreach df in dCov Cov1 {
    capture frames drop `df'
}

forvalues et = `pre'(-1)2 {
    generate byte et_m_`et' = `e' == -`et'
}
forvalues et = 0(1)`post' {
    generate byte et_p_`et' = `e' == `et'
}
forvalues et = `pre'(-1)2 {
    generate byte T_X_et_m_`et' = (`e' == -`et') & (`treated_group' == 1)
}
forvalues et = 0(1)`post' {
    generate byte T_X_et_p_`et' = (`e' == `et') & (`treated_group' == 1)
}

* first compute covariance in treated group only - this is biased
reghdfe `dYdX' T_X_et_m_`pre'-T_X_et_m_2 T_X_et_p_0-T_X_et_p_`post' if `treated_group' == 1, vce(cluster `cluster') nocons
e2frame, generate(Cov1)

* difference to placebo group - this is unbiased
reghdfe `dYdX' T_X_et_m_`pre'-T_X_et_m_2 T_X_et_p_0-T_X_et_p_`post', absorb(`e') vce(cluster `cluster') nocons
e2frame, generate(dCov)

**** Do the same for variance

* first compute variance in treated group only - this is biased
reghdfe `dY2' T_X_et_m_`pre'-T_X_et_m_2 T_X_et_p_0-T_X_et_p_`post' if `treated_group' == 1, vce(cluster `cluster') nocons
e2frame, generate(VarY1)

* difference to placebo group - this is unbiased
reghdfe `dY2' T_X_et_m_`pre'-T_X_et_m_2 T_X_et_p_0-T_X_et_p_`post', absorb(`e') vce(cluster `cluster') nocons
e2frame, generate(dVarY)

* save ATET estimates
generate byte TXT = `treated_group' & `treatment'
reghdfe `dYdX' TXT if `treated_group' == 1 & inrange(`e', -1, `post'), vce(cluster `cluster') 
local coef_Cov1 = _b[TXT]
local lower_Cov1 = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local upper_Cov1 = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

reghdfe `dYdX' TXT if inrange(`e', -1, `post'), absorb(`e') vce(cluster `cluster') 
local coef_dCov = _b[TXT]
local lower_dCov = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local upper_dCov = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

reghdfe `dY2' TXT if `treated_group' == 1 & inrange(`e', -1, `post'), vce(cluster `cluster') 
local coef_VarY1 = _b[TXT]
local lower_VarY1 = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local upper_VarY1 = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

reghdfe `dY2' TXT if inrange(`e', -1, `post'), absorb(`e') vce(cluster `cluster') 
local coef_dVarY = _b[TXT]
local lower_dVarY = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local upper_dVarY = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

foreach df in dCov Cov1 dVarY VarY1 {
    frame `df': rename coef coef_`df'
    frame `df': rename lower lower_`df'
    frame `df': rename upper upper_`df'
}
frame dCov {
    foreach df in Cov1 dVarY VarY1 {
        frlink 1:1 xvar, frame(`df')
        frget coef_`df' lower_`df' upper_`df', from(`df')
    }

    generate t = -`pre' + i - 1
    * there is an event-time missing, introduce the gap
    replace t = t + 1 if t >= -1

    count
    set obs `=r(N)+1'
    replace t = -1 in -1
    replace xvar = "T_X_et_m_1" in -1
    foreach v of varlist coef_* lower_* upper_* {
        replace `v' = 0 in -1
    }

    * save ATET row as t = 99
    set obs `=r(N)+2'
    replace t = 99 in -1
    replace xvar = "ATET" in -1

    foreach df in dCov Cov1 dVarY VarY1 {
        replace coef_`df' = `coef_`df'' in -1
        replace lower_`df' = `lower_`df'' in -1
        replace upper_`df' = `upper_`df'' in -1
    }

    generate Var0 = `Var0'
    generate Var1 = `Var1'
    generate dVar = Var1 - Var0

    sort t

    generate coef_dbeta = coef_dCov / dVar
    generate lower_dbeta = lower_dCov / dVar
    generate upper_dbeta = upper_dCov / dVar

    generate coef_beta1 = coef_Cov1 / Var1
    generate lower_beta1 = lower_Cov1 / Var1
    generate upper_beta1 = upper_Cov1 / Var1

    * FIXME: we need proper standard errors here
    generate coef_beta0 = (coef_Cov1 - coef_dCov) / Var0
    generate lower_beta0 = (lower_Cov1 - lower_dCov) / Var0
    generate upper_beta0 = (upper_Cov1 - upper_dCov) / Var0

    generate Rsq1 = (coef_Cov1)^2 / (coef_VarY1 * Var1)
    generate Rsq0 = (coef_Cov1 - coef_dCov)^2 / (coef_VarY1 * Var0)
    generate dRsq = (coef_dCov)^2 / (coef_VarY1 * dVar)

    list t coef_dbeta lower_dbeta upper_dbeta 
    order t i xvar coef_dbeta lower_dbeta upper_dbeta ///
        coef_beta1 lower_beta1 upper_beta1 ///
        coef_beta0 lower_beta0 upper_beta0
}