args outcome FE
clear all

local outcomeA lnR
local outcomeB ROA
local outcomeC lnK
local outcomeD lnL

local feA lnR
local feB lnR
local feC ROA
local feD lnRL

foreach outcome in A B C D{
  import delimited "data/full_`outcome`outcome''-`fe`outcome''.csv", clear case(preserve)

  do "src/exhibit/event_study.do" `outcome' "`outcome`outcome''-`fe`outcome''" "`outcome`outcome''-`fe`outcome''" beta
}

graph combine panelA panelB panelC panelD, ///
  cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

graph export "figure/outcomes.pdf", replace
graph drop panel*
