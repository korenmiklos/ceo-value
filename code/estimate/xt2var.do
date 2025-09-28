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
ppmlhdfe `dY2' `treated_group' if `e' < 0, absorb(`e')
local excess_variance = exp(_b[`treated_group']) - 1
display "Excess variance for treated group: `excess_variance' x"

summarize `X', detail

* compute covariances with driver variable
egen `EX' = mean(`X'), by(`g' `t' `treated_group')
generate `dYdX' = (`dY' - `E') * (`X' - `EX')
generate `dX2' = (`X' - `EX')^2
egen `Cov' = mean(cond(!`treated_group', (`dY' - `E') * (`X' - `EX'), .)), by(`g' `t')
egen `Var' = mean(cond(!`treated_group', (`X' - `EX')^2, .)), by(`g' `t')
replace `dYdX' = `dYdX' - `Cov' * `excess_variance' if `treated_group'
replace `dX2' = `dX2' - `Var' * `excess_variance' if `treated_group'

tempvar Cov0 Cov1 beta
summarize `dX2' if `treated_group' == 0, meanonly
local Var0 = r(mean)
summarize `dX2' if `treated_group' == 1, meanonly
local Var1 = r(mean)
egen `Cov0' = mean(cond(!`treated_group', `dYdX', .)), by(`e')
egen `Cov1' = mean(cond(`treated_group', `dYdX', .)), by(`e')

generate `beta' = (`Cov1' - `Cov0') / (`Var1' - `Var0')

table `e', stat(mean `Cov0' `Cov1')
table `e', stat(mean `beta')

generate `t1' = `treatment' & `treated_group'
generate `t0' = `treatment' & !`treated_group'

foreach df in dCov Cov1 {
    capture frames drop `df'
}
xt2treatments `dYdX', treatment(`t1') control(`t0') pre(`pre') post(`post') baseline(-1) weighting(optimal) cluster(`cluster')
e2frame, generate(dCov)

* estimate without placebo adjustment, because we need to recover levels
replace `dYdX' = 0 if !`treated_group'

xt2treatments `dYdX', treatment(`t1') control(`t0') pre(`pre') post(`post') baseline(-1) weighting(optimal) cluster(`cluster')
e2frame, generate(Cov1)

foreach df in dCov Cov1 {
    frame `df': rename coef coef_`df'
    frame `df': rename lower lower_`df'
    frame `df': rename upper upper_`df'
}
frame dCov {
    frlink 1:1 xvar, frame(Cov1)
    frget coef_Cov1 lower_Cov1 upper_Cov1, from(Cov1)
    generate coef_dbeta = coef_dCov / (`Var1' - `Var0')
    replace coef_dbeta = 0 if xvar == -1
    generate lower_dbeta = lower_dCov / (`Var1' - `Var0')
    replace lower_dbeta = 0 if xvar == -1
    generate upper_dbeta = upper_dCov / (`Var1' - `Var0')
    replace upper_dbeta = 0 if xvar == -1

    generate coef_beta1 = coef_Cov1 / `Var1'
    replace coef_beta1 = 0 if xvar == -1
    generate lower_beta1 = lower_Cov1 / `Var1'
    replace lower_beta1 = 0 if xvar == -1
    generate upper_beta1 = upper_Cov1 / `Var1'
    replace upper_beta1 = 0 if xvar == -1

    list xvar coef_dbeta lower_dbeta upper_dbeta 
}