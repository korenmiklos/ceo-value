local sampleA montecarlo

local titleA "Monte Carlo Simulation"

foreach panel in A  {
    local sample  `sample`panel''
    local title  `title`panel''
    local ytitle "Coefficient of TFP on new CEO skill"

    import delimited "output/event_study/`sample'_TFP.csv", clear
    do "papers/application/src/exhibit/event_study.do" `panel' "`title'" "`ytitle'"
}

graph combine panelA, ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5)

graph export "papers/application/figure/figuremc.pdf", replace
