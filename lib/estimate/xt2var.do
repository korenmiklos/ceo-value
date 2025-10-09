args outcome treatment treated_group X cluster
confirm numeric variable `outcome'
confirm numeric variable `treatment'
confirm numeric variable `treated_group'
confirm numeric variable `X'

local pre 4
local post 3

assert inlist(`treatment', 0, 1)
assert inlist(`treated_group', 0, 1)

tempvar g e Yg dY E dY2 Xg dX EX dYdX dX2 t0 t1 Cov Var

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
ppmlhdfe `dY2' `treated_group' if `e' < 0, absorb(`e')
local excess_variance = exp(_b[`treated_group']) - 1
display "Excess variance for treated group: `excess_variance' x"
summarize `X', detail

* compute covariances with driver variable
egen `EX' = mean(`X'), by(`g' `t' `treated_group')
generate `dYdX' = (`dY' - `E') * (`X' - `EX')
generate `dX2' = (`X' - `EX')^2
egen `Cov' = mean(cond(!`treated_group', `dYdX', .)), by(`g' `t')
egen `Var' = mean(cond(!`treated_group', `dX2', .)), by(`g' `t')
replace `dYdX' = `dYdX' - `Cov' * `excess_variance' if `treated_group'
replace `dX2' = `dX2' - `Var' * `excess_variance' if `treated_group'

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

* save ATET estimates
generate byte TXT = `treated_group' & `treatment'
reghdfe `dYdX' TXT if `treated_group' == 1, vce(cluster `cluster') nocons
local ATET1 = _b[TXT]
local lower1 = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local upper1 = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

reghdfe `dYdX' TXT, absorb(`e') vce(cluster `cluster') nocons
local dATET = _b[TXT]
local dlower = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local dupper = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

foreach df in dCov Cov1 {
    frame `df': rename coef coef_`df'
    frame `df': rename lower lower_`df'
    frame `df': rename upper upper_`df'
}
frame dCov {
    frlink 1:1 xvar, frame(Cov1)
    frget coef_Cov1 lower_Cov1 upper_Cov1, from(Cov1)

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

    replace coef_dCov = `dATET' in -1
    replace lower_dCov = `dlower' in -1
    replace upper_dCov = `dupper' in -1
    replace coef_Cov1 = `ATET1' in -1
    replace lower_Cov1 = `lower1' in -1
    replace upper_Cov1 = `upper1' in -1

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

    list t coef_dbeta lower_dbeta upper_dbeta 
    order t i xvar coef_dbeta lower_dbeta upper_dbeta ///
        coef_beta1 lower_beta1 upper_beta1 ///
        coef_beta0 lower_beta0 upper_beta0
}