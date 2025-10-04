local sample full

local outcomeA lnK
local outcomeB has_intangible
local outcomeC lnM
local outcomeD lnWL

local titleA "Capital (log)"
local titleB "Intangibles (dummy)"
local titleC "Materials (log)"
local titleD "Wagebill (log)"

foreach panel in A B C D  {
    local title  `title`panel''
    local outcome  `outcome`panel''
    local ytitle "`title' relative to year -3"

    import delimited "output/event_study/`sample'_`outcome'.csv", clear
    do "papers/application/src/exhibit/event_study.do" `panel' "`title'" "`ytitle'" 
}

graph combine panelA panelB panelC panelD, ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5)

graph export "papers/application/figure/figure3.pdf", replace
