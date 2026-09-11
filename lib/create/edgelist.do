* get the set of firms in the analysis sample
use "temp/analysis-sample.dta", clear
keep frame_id_numeric
duplicates drop
tempfile firms
save "`firms'", replace

* person_id lives in intervals.dta, not in the firm-year panel
use "temp/intervals.dta", clear
keep frame_id_numeric person_id
duplicates drop

* restrict to firms in the analysis sample
merge m:1 frame_id_numeric using "`firms'", keep(match) nogen

export delimited using "temp/edgelist.csv", replace
