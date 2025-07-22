use "input/ceo-panel/ceo-panel.dta", clear

keep if inrange(year, 1992, 2022)

local dims frame_id_numeric person_id year male birth_year manager_category owner
keep `dims'
order `dims'

egen n_ceo = count(person_id), by(frame_id_numeric year)
egen ft = tag(frame_id_numeric year)

tabulate n_ceo if ft, missing
drop ft

save "temp/ceo-panel.dta", replace
