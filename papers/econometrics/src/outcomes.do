clear all

local A lnR
local B lnL
local C lnM
local D lnK
local E has_intangible
local F exporter

foreach FE in lnR lnL lnROA lnRL {
    foreach outcome in A B C D E F {
        import delimited "data/full_``outcome''-`FE'.csv", clear case(preserve)
        * drop ATET estimates
        drop if xvar == "ATET"

        do "src/exhibit/event_study.do" `outcome' "``outcome''" "``outcome''" beta
    }
    graph combine panelA panelB panelC panelD panelE panelF, ///
        cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

    graph export "figure/outcomes_`FE'.pdf", replace
    graph drop panel*
}
