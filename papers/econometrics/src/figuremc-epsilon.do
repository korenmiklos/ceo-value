local sampleA excessvariance_baseline
local sampleB excessvariance_baseline
local sampleC excessvariance
local sampleD excessvariance

local outcomeA VarY
local outcomeB Cov
local outcomeC VarY
local outcomeD Cov

local titleA "Var (e1 = 1; e0 = 0)"
local titleB "Cov (e1 = 1; e0 = 0)"
local titleC "Var (e1 = .7; e0 = .5)"
local titleD "Cov (e1 = .7; e0 = .5)"

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
graph export "figure/figuremc-epsilon.pdf", replace
