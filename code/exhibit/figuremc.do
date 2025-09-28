local sampleA montecarlo

local titleA "Monte Carlo Simulation"

foreach panel in A  {
    local sample  `sample`panel''
    local title  `title`panel''
    local ytitle "Log TFP relative to year -1"

    import delimited "output/event_study/`sample'_TFP.csv", clear
    summarize true_effect, meanonly
    local true_effect = r(mean)
    do "code/exhibit/event_study.do" `panel' "`title'" "`ytitle'" `true_effect'
}

graph combine panelA, ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5)

graph export "output/figure/figuremc.pdf", replace
