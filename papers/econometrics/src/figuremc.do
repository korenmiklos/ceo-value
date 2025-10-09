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
    local ytitle "Coefficient of TFP on new CEO skill"

    import delimited "data/`sample'_TFP.csv", clear

    * clip error bands for better visualization
    foreach var in beta0 beta1 dbeta {
        replace lower_`var' = max(lower_`var', -0.5)
        replace upper_`var' = min(upper_`var', 1.5)
    }

    do "src/exhibit/event_study.do" `panel' "`title'" "`ytitle'"
}

graph combine panelA panelB panelC panelD panelE panelF, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5) ycommon

graph export "figure/figuremc.pdf", replace
