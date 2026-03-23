args sample FE
clear all

local A lnR
local B ROA
local C lnL
local D lnK
local E exporter
local F lnWL

foreach outcome in A B C D E F {
    do "../../lib/estimate/event_study.do" `sample' ``outcome'' no `FE'

    do "src/exhibit/event_study.do" `outcome' "``outcome''" "``outcome''" beta
}

graph combine panelA panelB panelC panelD panelE panelF, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

graph export "figure/outcomes_`sample'_`FE'.pdf", replace
graph drop panel*
