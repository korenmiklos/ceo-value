local sampleA baseline
local sampleB longpanel
local sampleC persistent
local sampleD unbalanced
local sampleE excessvariance
local sampleF all

local titleA "Baseline"
local titleB "Long Panel"
local titleC "Persistent Errors"
local titleD "Unbalanced Panel"
local titleE "Excess Variance"
local titleF "All Complications"

foreach panel in A B C D E F {
    local sample  `sample`panel''
    local title  `title`panel''

    import delimited "data/`sample'_TFP.csv", clear
    * drop ATET estimates
    drop if xvar == "ATET"

    * clip error bands for better visualization
    foreach var in beta0 beta1 dbeta {
        replace lower_`var' = max(lower_`var', -0.75)
        replace upper_`var' = min(upper_`var', 1.75)
    }

    do "src/exhibit/event_study.do" `panel' "`title'" "`ytitle'" beta
}

graph combine panelA panelB panelC panelD panelE panelF, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5) ycommon

graph export "figure/figuremc.pdf", replace
