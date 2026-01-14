local sampleA baseline
local sampleB baseline
local sampleC persistent_baseline
local sampleD persistent_baseline
local sampleE all
local sampleF all

local outcomeA VarY
local outcomeB Cov
local outcomeC VarY
local outcomeD Cov
local outcomeE VarY
local outcomeF Cov

local titleA "Variance (Baseline)"
local titleB "Covariance (Baseline)"
local titleC "Variance (Persistent)"
local titleD "Covariance (Persistent)"
local titleE "Variance (All)"
local titleF "Covariance (All)"

foreach panel in A B C D E F {
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

    if "`sample'" == "all" {
        do "src/exhibit/event_study3.do" `panel' "`title'" "`ytitle'" `outcome'
    }
    else {
        do "src/exhibit/event_study2.do" `panel' "`title'" "`ytitle'" `outcome'
    }
}

graph combine panelA panelB panelC panelD panelE panelF, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5) ycommon

graph export "figure/figuremc.pdf", replace
