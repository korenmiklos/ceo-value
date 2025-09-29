local sampleA full
local sampleB fnd2non
local sampleC non2non
local sampleD post2004

local titleA "All CEO changes"
local titleB "Founder to Outsider"
local titleC "Outsider to Outsider"
local titleD "Sample: 2004-2022"

foreach panel in A B C D  {
    local sample  `sample`panel''
    local title  `title`panel''
    local ytitle "Log TFP relative to year -2"

    import delimited "output/event_study/`sample'_TFP.csv", clear
    do "code/exhibit/event_study.do" `panel' "`title'" "`ytitle'" 
}

graph combine panelA panelB panelC panelD, ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5)

graph export "output/figure/figure1.pdf", replace
