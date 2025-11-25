clear all

local A lnKL
local B lnRL
local C lnMR
local D exporter
local E has_intangibles
local F EBITDTA_share

foreach outcome in A B C D E F {
    import delimited "data/full_``outcome''.csv", clear case(preserve)
    * drop ATET estimates
    drop if xvar == "ATET"

    do "src/exhibit/event_study.do" `outcome' "``outcome''" "``outcome''" beta
}

graph combine panelA panelB panelC panelD panelE panelF, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

graph export "figure/outcomes.pdf", replace
