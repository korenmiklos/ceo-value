args sample
clear all

local A lnR
local B lnL
local C ROA
local D lnK
local E lnRL

foreach outcome in A B C D E {
    import delimited "data/`sample'_``outcome''-``outcome''.csv", clear case(preserve)
    do "src/exhibit/event_study.do" `outcome' "``outcome''"

}

graph combine panelA panelB panelC panelD panelE, ///
    cols(3) graphregion(color(white)) imargin(small) xsize(7.5) ysize(5)

graph export "figure/outcomes_`sample'.pdf", replace
graph drop panel*
