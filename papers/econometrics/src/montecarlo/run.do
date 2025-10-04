*! Run a single Monte Carlo scenario
*! Usage: do run.do <scenario>

args scenario

include "src/montecarlo/`scenario'.do"
include "src/montecarlo/setup.do"
save "data/placebo_`scenario'.dta", replace
