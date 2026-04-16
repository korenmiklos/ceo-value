args sample FE
clear all

local A ROA
local B EBITDA
local C logTAN
local D tangibles_avg

foreach outcome in A B C D  {
    import delimited "data/`sample'_``outcome''-`FE'.csv", clear case(preserve)

    do "src/exhibit/event_study.do" `outcome' "``outcome''" "``outcome''" beta
}

graph combine panelA panelB panelC panelD , ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

graph export "figure/outcomes_`sample'_`FE'.pdf", replace
graph drop panel*
