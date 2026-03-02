use "temp/intervals.dta", clear

generate T = end_year - start_year + 1
tabulate T, missing
expand T

bysort frame_id_numeric person_id spell: generate year = start_year + _n -1

merge m:1 frame_id_numeric person_id using "temp/manager-firm-facts.dta", keep(match) nogen
merge m:1 person_id using "temp/manager-facts.dta", keep(match) nogen

generate byte someone_enters = year == start_year
generate byte someone_exits = year == end_year
generate byte foreign_name = 1 - hungarian_name
generate byte founder = manager_category == 1

collapse (count) n_ceo = person_id (max) has_expat_ceo = foreign_name has_founder = founder (max) someone_enters someone_exits (sum) n_ceo_male = male, by(frame_id_numeric year)

xtset frame_id_numeric year
generate byte someone_exited = L.someone_exits == 1

bysort frame_id_numeric (year): generate byte ceo_spell = sum(someone_enters | someone_exited)

keep frame_id_numeric year ceo_spell n_ceo has_expat_ceo has_founder n_ceo_male
save "temp/ceo-panel.dta", replace
