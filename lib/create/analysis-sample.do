use "temp/unfiltered.dta", clear

* Note: unfiltered.dta already contains merged balance sheet and CEO data
* with industry classification and variables applied
do "lib/util/filter.do"

compress

save "temp/analysis-sample.dta", replace
