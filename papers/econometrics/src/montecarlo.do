*! Run all Monte Carlo scenarios

local scenarios baseline longpanel persistent unbalanced excessvariance all

foreach scenario in `scenarios' {
	display _newline(2) "Running scenario: `scenario'"
	include "src/montecarlo/`scenario'.do"
	include "src/montecarlo/setup.do"
	save "data/placebo_`scenario'.dta", replace
}
