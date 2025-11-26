clear all

local A lnKL
local B lnRL
local C lnMR
local D exporter
local E has_intangible
local F EBITDA_share

foreach sample in small medium large full {
    foreach outcome in A B C D E F {
        import delimited "data/`sample'_``outcome''.csv", clear case(preserve)
        * drop ATET estimates
        drop if xvar == "ATET"

        do "src/exhibit/event_study.do" `outcome' "``outcome''" "``outcome''" beta
    }
    graph combine panelA panelB panelC panelD panelE panelF, ///
        cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

    graph export "figure/outcomes_`sample'.pdf", replace
    graph drop panel*
}
