*! Run all Monte Carlo scenarios

local scenarios baseline longpanel persistent unbalanced excessvariance all

foreach scenario in `scenarios' {
	display _newline(2) "Running scenario: `scenario'"
	include papers/econometrics/src/montecarlo/`scenario'.do
	include papers/econometrics/src/montecarlo/setup.do
	save "papers/econometrics/data/placebo_`scenario'.dta", replace
}
