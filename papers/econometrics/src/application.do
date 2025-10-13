clear all
do "src/exhibit/age.do"

import delimited "data/full_lnR.csv", clear case(preserve)
* drop ATET estimates
drop if xvar == "ATET"

do "src/exhibit/event_study3.do" A "Variance" "" VarY
do "src/exhibit/event_study3.do" B "Covariance" "" Cov
do "src/exhibit/event_study.do" C "R-squared" "" Rsq

do "src/exhibit/event_study.do" E "Own beta" "" beta

import delimited "data/full_exporter.csv", clear case(preserve)
* drop ATET estimates
drop if xvar == "ATET"
do "src/exhibit/event_study.do" F "Exporter beta" "" beta

graph combine panelA panelB panelC panelD panelE panelF, ///
    cols(2) graphregion(color(white)) imargin(small) xsize(5) ysize(7.5)

graph export "figure/application.pdf", replace
