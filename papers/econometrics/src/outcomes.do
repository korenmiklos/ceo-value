args FE
clear all

local A lnR
local B ROA
local C lnL
local D lnK
local E exporter
local F lnWL
local G ROA_operating

foreach outcome in A B C D E F G {
  import delimited "data/full_``outcome''-`FE'.csv", clear case(preserve)
  * drop ATET estimates
    drop if xvar == "ATET"

    do "src/exhibit/event_study.do" `outcome' "``outcome''" "``outcome''" beta
}
graph combine panelG panelB panelA panelC panelD panelE panelF, ///
        cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

graph export "figure/outcomes_`FE'.pdf", replace
graph drop panel*
