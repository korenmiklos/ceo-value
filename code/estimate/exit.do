* make sure variables can be created
capture drop lnKM*
capture drop exit_hat
capture drop pr

* create polynomials of lnK and lnM
local K 3

forvalues i = 0/`K' {
    local jmax = `K' - `i'
    forvalues j = 0/`jmax' {
        generate lnKM_`i'_`j' = lnK^`i' * lnM^`j'
        label variable lnKM_`i'_`j' "lnK^`i' * lnM^`j'"
    }
}
drop lnKM_0_0

quietly generate exit_hat = .

levelsof sector, local(sectors)

foreach sector of local sectors {
    logit exit lnKM* i.year if sector == `sector'
    predict pr if sector == `sector', pr
    replace exit_hat = pr if sector == `sector'
    drop pr
}

* create Chebyshev polynomial of exit_hat
local p exit_hat
generate Chebyshev_1 = 2 * `p' - 1
generate Chebyshev_2 = 8 * `p'^2 - 8 * `p' + 1
generate Chebyshev_3 = 32 * `p'^3 - 48 * `p'^2 + 18 * `p' - 1
* generate Chebyshev_4 = 128 * `p'^4 - 256 * `p'^3 + 160 * `p'^2 - 32 * `p' + 1

summarize exit_hat, detail

label variable exit_hat "Predicted exit probability"
