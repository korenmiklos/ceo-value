* =============================================================================
* CEO PANEL DATA PARAMETERS
* =============================================================================
local start_year 1992             // Start year for data inclusion
local end_year 2022               // End year for data inclusion

use "input/manager-db-ceo-panel/ceo-panel.dta", clear

* birth year is better then entry
replace first_year_as_ceo = birth_year + 18 if first_year_as_ceo < birth_year + 18 & !missing(birth_year)
* except for very old people
replace birth_year = 1911 if birth_year < 1911
* for missing birth year, extrapolate from entry
egen pt = tag(person_id)
generate age_at_entry = first_year_as_ceo - birth_year if !missing(birth_year) & !missing(first_year_as_ceo)
summarize age_at_entry if pt & !missing(age_at_entry), detail
scalar median_age_at_entry = r(p50)

generate byte imputed_age = missing(birth_year) & !missing(first_year_as_ceo)

replace birth_year = first_year_as_ceo - median_age_at_entry if missing(birth_year) & !missing(first_year_as_ceo)
tabulate birth_year imputed_age if pt, missing

keep if inrange(year, `start_year', `end_year')

egen fp = group(frame_id_numeric person_id)
xtset fp year, yearly

generate byte entering_ceo = missing(L.year)
generate byte leaving_ceo = missing(F.year)

* the same person may have multiple spells at the firm
bysort frame_id_numeric person_id (year): generate spell = sum(entering_ceo)
egen start_year = min(year), by(frame_id_numeric person_id spell)

local dims frame_id_numeric person_id start_year male birth_year manager_category owner //cf is excluded as it creates about 28k duplicates.
keep `dims'
order `dims'
duplicates drop `dims', force

merge 1:m frame_id_numeric person_id start_year using "temp/intervals.dta", keep(matched) nogen
gen duration = end_year - start_year + 1
expand duration
drop duration
bysort frame_id_numeric person_id spell: generate year = start_year + _n -1
ren spell ceo_spell


egen n_ceo = count(person_id), by(frame_id_numeric year)
egen ft = tag(frame_id_numeric year)

tabulate n_ceo if ft, missing
drop ft

save "temp/ceo-panel.dta", replace
