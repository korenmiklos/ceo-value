use "temp/analysis-sample.dta", clear

keep frame_id_numeric person_id
duplicates drop

export delimited using "temp/edgelist.csv", replace