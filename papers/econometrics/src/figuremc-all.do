local sampleA all
local sampleB all_persistent
local sampleC all_excess
local sampleD all_both

local outcomeA Cov
local outcomeB Cov
local outcomeC Cov
local outcomeD Cov

local titleA "Cov (Baseline)"
local titleB "Cov (Diff rho)"
local titleC "Cov (1.4xe)"
local titleD "Cov (both)"

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

        do "src/exhibit/event_study3.do" `panel' "`title'" "`ytitle'" `outcome'
}

graph combine panelA panelB panelC panelD, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5) ycommon

graph export "figure/figuremc-all.pdf", replace
