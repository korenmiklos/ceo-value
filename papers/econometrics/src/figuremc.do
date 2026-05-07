* figuremc.do
* Replacement for figuremc.do using xt2denoise via event_study.do
* Same interface and output as original

local sampleA baseline
local sampleB persistent
local sampleC excessvariance
local sampleD excessvariance_corr
local sampleE all
local sampleF trend


local titleA "Baseline"
local titleB "Persistence"
local titleC "Excess Variance"
local titleD "E.V. Correction"
local titleE "All"
local titleF "Pretrend"


foreach panel in A B C D E F {
    local sample  `sample`panel''
    local title `title`panel''
    * run estimation — builds dCov frame in memory
    import delimited "data/`sample'_lnR-lnR.csv",clear case(preserve)

    * dispatch to appropriate exhibit script
    if "`sample'" == "all" {
        do "src/exhibit/event_study3.do" `panel' "`title'" "`title'" beta
    }
    else {
        do "src/exhibit/event_study2.do" `panel' "`title'" "`title'" beta
    }
}

graph combine panelA panelB panelC panelD panelE panelF, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5) ycommon

graph export "figure/figuremc.pdf", replace
