local sampleA persistent_baseline
local sampleB persistent_baseline
local sampleC persistent
local sampleD persistent

local outcomeA VarY
local outcomeB Cov
local outcomeC VarY
local outcomeD Cov

local titleA "Var (rho = 0.9)"
local titleB "Cov (rho = 0.9)"
local titleC "Var (rho1 = 0.8)"
local titleD "Cov (rho1 = 0.8)"

foreach panel in A B C D {
    local sample  `sample`panel''
    local title  `title`panel''
    local outcome `outcome`panel''

    import delimited "data/`sample'_lnR-lnR.csv", clear case(preserve)
    * drop ATET estimates
    drop if xvar == "ATET"

    foreach X in `outcome'1 d`outcome' {
        capture generate upper_`X' = coef_`X' + 1.96*se_`X'
        capture generate lower_`X' = coef_`X' - 1.96*se_`X'
    }


    do "src/exhibit/event_study2.do" `panel' "`title'" "`ytitle'" `outcome'
}

graph combine panelA panelB panelC panelD, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5) ycommon

graph export "figure/figuremc-rho.pdf", replace
