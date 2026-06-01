args sample FE
clear all

local A lnK
local B lnL
local C lnR
local D exporter
local E ROA
local F lnYL

foreach outcome in A B C D E F {
    import delimited "data/`sample'_``outcome''-`FE'.csv", clear case(preserve)

    do "src/exhibit/event_study.do" `outcome' "``outcome''" "``outcome''" beta
}

graph combine panelA panelB panelC panelD panelE panelF, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

graph export "figure/outcomes_`sample'_`FE'.pdf", replace
graph drop panel*
