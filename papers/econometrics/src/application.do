local outcomeA VarY
local outcomeB Rsq
local outcomeC Cov
local outcomeD beta

local titleA "Variance"
local titleB "R-squared"
local titleC "Covariance"
local titleD "Beta"

foreach panel in A B C D {
    local outcome  `outcome`panel''
    local title  `title`panel''

    import delimited "data/full_lnR.csv", clear case(preserve)
    * drop ATET estimates
    drop if xvar == "ATET"

    do "src/exhibit/event_study.do" `panel' "`title'" "`ytitle'" `outcome'
}

graph combine panelA panelB panelC panelD, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(5) 

graph export "figure/application.pdf", replace
