args outcome treatment treated_group X
confirm numeric variable `outcome'
confirm numeric variable `treatment'
confirm numeric variable `treated_group'
confirm numeric variable `X'

local pre 4
local post 2

assert inlist(`treatment', 0, 1)
assert inlist(`treated_group', 0, 1)

tempvar g e Yg dY E V dY2 V_hat Cov EX dYdX

xtset
local i = r(panelvar)
local t = r(timevar)

egen `g' = max(cond(`treatment' == 0, `t', .)), by(`i')
egen `Yg' = mean(cond(`t' == `g', `outcome', .)), by(`i')
generate `dY' = `outcome' - `Yg'
generate `e' = `t' - `g' - 1

egen `E' = mean(`dY'), by(`g' `t' `treated_group')
generate `dY2' = (`dY' - `E')^2
egen `V' = mean(`dY2'), by(`g' `t' `treated_group')

table `e' `treated_group', statistic(mean `dY') statistic(mean `V')

* compute event-time-specific variance correction
ppmlhdfe `dY2' `treated_group' if `e' < 0, absorb(`e')
local excess_variance = exp(_b[`treated_group']) 
display "Excess variance for treated group: `excess_variance' x"

summarize `X', detail

* compute covariances with driver variable
egen `EX' = mean(`X'), by(`g' `t' `treated_group')
generate `dYdX' = (`dY' - `E') * (`X' - `EX')
egen `Cov' = mean((`dY' - `E') * (`X' - `EX')), by(`g' `t' `treated_group')

tempvar ET
generate `ET' = 100 + `e'
reghdfe `dYdX' i.`ET'##i.`treated_group', cluster(`i')

BRK

forvalues s = -`pre'/-2 {
    generate E1_m`=-`s'' = ((`e' == `s') & (`treated_group' == 1)) * `X'
    generate E0_m`=-`s'' = ((`e' == `s') & (`treated_group' == 0)) * `X'
}
forvalues s = 0/`post' {
    generate E1_p`s' = ((`e' == `s') & (`treated_group' == 1)) * `driver'
    generate E0_p`s' = ((`e' == `s') & (`treated_group' == 0)) * `driver'
}

reghdfe `dY' E1_* E0_*, cluster(`i') nocons

*reghdfe `dY2' E1_* E0_*, cluster(`i') nocons

drop E1_* E0_*