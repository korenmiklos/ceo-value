* =============================================================================
* CEO PANEL DATA PARAMETERS
* =============================================================================
local start_year 1988             // Start year for data inclusion
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

do "lib/util/potholes.do"

local dims frame_id_numeric person_id start_year male birth_year manager_category owner //cf is excluded as it creates about 28k duplicates.
keep `dims'
order `dims'
duplicates drop `dims', force

merge 1:m frame_id_numeric person_id start_year using "temp/intervals.dta", keep(matched) nogen
gen duration = end_year - start_year + 1
expand duration
drop duration
bysort frame_id_numeric person_id spell: generate year = start_year + _n -1

egen n_ceo = count(person_id), by(frame_id_numeric year)
egen ft = tag(frame_id_numeric year)

* ceo_spell is a firm-level counter: cumulative number of CEO arrivals
egen byte has_new_ceo = max(year == start_year & !missing(start_year)), by(frame_id_numeric year)
egen byte leaving_ceo = max(year == end_year & !missing(end_year)), by(frame_id_numeric year)
bysort ft frame_id_numeric (year): generate ceo_spell = sum(has_new_ceo) if ft
egen tmp = max(ceo_spell), by(frame_id_numeric year)
replace ceo_spell = tmp if missing(ceo_spell)
drop tmp has_new_ceo spell

tabulate n_ceo if ft, missing
drop ft

save "temp/ceo-panel.dta", replace
