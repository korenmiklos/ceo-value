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
local t = r(timevar)
if "`cluster'" == "" {
    local cluster `i'
}

egen `g' = max(cond(`treatment' == 0, `t', .)), by(`i')
egen `Yg' = mean(cond(`t' == `g', `outcome', .)), by(`i')
egen `Zg' = mean(cond(`t' == `g', `fixed_effects', .)), by(`i')
generate `dY' = `outcome' - `Yg'
generate `dZ' = `fixed_effects' - `Zg'
generate `e' = `t' - `g' - 1

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
local eCovYZ = sqrt(`eVarZ' * `eVarY')

display "Estimated variance and covariance in treated and placebo groups:"
table `e' `treated_group', stat(mean `dY2' `dYdX' `dX2') nototals

forvalues et = `pre'(-1)2 {
    generate byte et_m_`et' = (`e' == -`et') & (`treated_group' == 1)
}
forvalues et = 0(1)`post' {
    generate byte et_p_`et' = (`e' == `et') & (`treated_group' == 1)
}

* compute difference in a regression to get standard errors
reghdfe `dX2' if !`treated_group', vce(cluster `cluster')
local Var0 = _b[_cons]
local se_Var0 = _se[_cons]
reghdfe `dX2' if `treated_group', vce(cluster `cluster')
local Var1 = _b[_cons]
local se_Var1 = _se[_cons]
reghdfe `dX2' `treated_group', vce(cluster `cluster')
local dVar = _b[`treated_group']
local se_dVar  = _se[`treated_group']

generate `t1' = `treatment' & `treated_group'
generate `t0' = `treatment' & !`treated_group'

foreach df in dCov Cov1 {
    capture frames drop `df'
}

* first compute covariance in treated group only - this is biased
reghdfe `dYdX' et_m_`pre'-et_m_2 et_p_0-et_p_`post' if `treated_group' == 1, absorb(`group') vce(cluster `cluster') nocons
e2frame, generate(Cov1)

* difference to placebo group - this is unbiased
reghdfe `dYdX' et_m_`pre'-et_m_2 et_p_0-et_p_`post', absorb(`group' `e') vce(cluster `cluster') nocons
e2frame, generate(dCov)
**** Do the same for variance

* first compute variance in treated group only - this is biased
reghdfe `dY2' et_m_`pre'-et_m_2 et_p_0-et_p_`post' if `treated_group' == 1, absorb(`group') vce(cluster `cluster') nocons
e2frame, generate(VarY1)

* difference to placebo group - this is unbiased
reghdfe `dY2' et_m_`pre'-et_m_2 et_p_0-et_p_`post', absorb(`group' `e') vce(cluster `cluster') nocons
e2frame, generate(dVarY)

* save ATET estimates
generate byte TXT = `treated_group' & `treatment'
reghdfe `dYdX' TXT if `treated_group' == 1 & inrange(`e', -1, `post'), absorb(`group') vce(cluster `cluster') 
local coef_Cov1 = _b[TXT]
local lower_Cov1 = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local upper_Cov1 = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

reghdfe `dYdX' TXT if inrange(`e', -1, `post'), absorb(`group' `e') vce(cluster `cluster') 
local coef_dCov = _b[TXT]
local lower_dCov = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local upper_dCov = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

reghdfe `dY2' TXT if `treated_group' == 1 & inrange(`e', -1, `post'), absorb(`group') vce(cluster `cluster') 
local coef_VarY1 = _b[TXT]
local lower_VarY1 = _b[TXT] - invttail(e(df_r), 0.025)*_se[TXT]
local upper_VarY1 = _b[TXT] + invttail(e(df_r), 0.025)*_se[TXT]

reghdfe `dY2' TXT if inrange(`e', -1, `post'), absorb(`group' `e') vce(cluster `cluster') 
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
        generate se_`df' = (upper_`df' - lower_`df') / invnormal(0.975)
    }
    generate se_dCov = (upper_dCov - lower_dCov) / invnormal(0.975)
    drop lower_* upper_*

    generate t = -`pre' + i - 1
    * there is an event-time missing, introduce the gap
    replace t = t + 1 if t >= -1

    count
    set obs `=r(N)+1'
    replace t = -1 in -1
    replace xvar = "T_X_et_m_1" in -1
    foreach v of varlist coef_* se_* {
        replace `v' = 0 in -1
    }

    * save ATET row as t = 99
    set obs `=r(N)+2'
    replace t = 99 in -1
    replace xvar = "ATET" in -1

    foreach df in dCov Cov1 dVarY VarY1 {
        replace coef_`df' = `coef_`df'' in -1
    }

    generate coef_Cov0 = coef_Cov1 - coef_dCov
    generate coef_VarY0 = coef_VarY1 - coef_dVarY

    generate Var0 = `Var0'
    generate Var1 = `Var1'
    generate dVar = Var1 - Var0

    * standard errors for differences
    generate se_Cov0 = sqrt(se_Cov1^2 + se_dCov^2)
    generate se_VarY0 = sqrt(se_VarY1^2 + se_dVarY^2)

    sort t

    generate coef_dbeta = coef_dCov / dVar
    generate coef_beta1 = coef_Cov1 / Var1
    generate coef_beta0 = coef_Cov0 / Var0

    * use the delta method to get standard errors for beta
    * Var(beta) = Var(Cov)/E(X)^2 [1 + beta^2 * Var(X)/Var(Y)]
    * so se(beta) = se(Cov)/E(X) sqrt[1 + beta^2 * Var(X)/Var(Y)]

    scalar Var_ratio = `se_dVar' / se_dCov
    scalar correction = 1 + Var_ratio * coef_dbeta^2
    display "Variance correction factor for se(beta): " correction
    generate se_dbeta = se_dCov / dVar * sqrt(correction)

    scalar Var_ratio = `se_Var1' / se_Cov1
    scalar correction = 1 + Var_ratio * coef_beta1^2
    generate se_beta1 = se_Cov1 / Var1 * sqrt(correction)

    scalar Var_ratio = `se_Var0' / sqrt(se_Cov1^2 + se_dCov^2)
    scalar correction = 1 + Var_ratio * coef_beta0^2
    generate se_beta0 = sqrt(se_Cov1^2 + se_dCov^2) / Var0 * sqrt(correction)

    * now we can compute error bands
    foreach v in dbeta beta1 beta0 dCov Cov1 Cov0 dVarY VarY1 VarY0 {
        generate lower_`v' = coef_`v' - se_`v' * invnormal(0.975)
        generate upper_`v' = coef_`v' + se_`v' * invnormal(0.975)
    }

    generate Rsq1 = (coef_Cov1)^2 / (coef_VarY1 * Var1)
    generate Rsq0 = (coef_Cov0)^2 / (coef_VarY1 * Var0)
    generate dRsq = (coef_dCov)^2 / (coef_VarY1 * dVar)

    foreach X in Rsq0 Rsq1 dRsq {
        replace `X' = 0 if t == -1
    }

    list t coef_dbeta lower_dbeta upper_dbeta 
    order t i xvar coef_dbeta lower_dbeta upper_dbeta ///
        coef_beta1 lower_beta1 upper_beta1 ///
        coef_beta0 lower_beta0 upper_beta0
}