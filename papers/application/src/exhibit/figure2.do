local sampleA fnd2non
local sampleB non2non
local sampleC full
local sampleD post2004

local titleA "Founder to Non-founder"
local titleB "Non-founder to Non-founder"
local titleC "All CEO changes"
local titleD "Sample: 2004-2022"

foreach panel in A B C D  {
    local sample  `sample`panel''
    local title  `title`panel''
    local ytitle "Log TFP relative to year -3"

    import delimited "output/event_study/`sample'_TFP.csv", clear
    do "code/exhibit/event_study.do" `panel' "`title'" "`ytitle'" 
}

graph combine panelA panelB panelC panelD, ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5)

graph export "output/figure/figure2.pdf", replace
