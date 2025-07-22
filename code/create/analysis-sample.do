use "temp/ceo-panel.dta", clear

merge m:1 frame_id_numeric year using "temp/balance.dta"

egen firm_tag = tag(frame_id_numeric)
tabulate _merge if firm_tag, missing
egen firm_year_tag = tag(frame_id_numeric year)
tabulate n_ceo if firm_year_tag, missing
tabulate n_ceo if firm_year_tag & _merge==3, missing

keep if _merge == 3
drop _merge firm_year_tag firm_tag

do "code/util/industry.do"
do "code/util/variables.do"
do "code/util/filter.do"

compress

save "temp/analysis-sample.dta", replace
