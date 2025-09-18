* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
global event_window_start -4      // Event study window start
global event_window_end 3         // Event study window end
global min_obs_threshold 1         // Minimum observations before/after
global min_T 1                     // Minimum observations to estimate fixed effects
global max_n_ceo 1                // Maximum number of CEOs per firm for analysis

use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(master match) nogen

* keep single-ceo firms
egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
tabulate n_ceo max_n_ceo, missing
keep if max_n_ceo <= ${max_n_ceo}

* limit sample to clean changes  
keep if ceo_spell <= max_ceo_spell
keep if !missing(lnStilde)

tabulate ceo_spell

generate cohort = foundyear
tabulate cohort, missing
replace cohort = 1989 if cohort < 1989
tabulate cohort, missing

* for some reason, there is 1 duplicate in cohort
egen min_cohort = min(cohort), by(frame_id_numeric)
replace cohort = min_cohort if cohort != min_cohort
drop min_cohort

* refactor to collapse
collapse (mean) MS = manager_skill (count) T = lnStilde (max) founder owner (min) change_year = year (max) window_end = year (firstnm) cohort, by(frame_id_numeric ceo_spell)

drop if missing(MS)
drop if T < ${min_T}

xtset frame_id_numeric ceo_spell
* drop if spells are not consecutive. this also excludes single-spell firms
tabulate ceo_spell
drop if missing(L.ceo_spell) & missing(F.ceo_spell)
tabulate ceo_spell

* intermediate spells have to be doubled so that before and after are both saved
egen first_spell = min(ceo_spell), by(frame_id_numeric)
egen last_spell = max(ceo_spell), by(frame_id_numeric)
generate duplicate = cond(ceo_spell > first_spell & ceo_spell < last_spell, 2, 1)
expand duplicate

bysort frame_id_numeric ceo_spell: generate index = _n
sort frame_id_numeric ceo_spell index
generate byte new_spell = ceo_spell[_n-1] == ceo_spell & frame_id_numeric[_n-1] == frame_id_numeric  
bysort frame_id_numeric (ceo_spell index): generate byte spell_id = sum(new_spell)

drop first_spell last_spell duplicate index new_spell
bysort frame_id_numeric spell_id (ceo_spell): generate index = _n

reshape wide MS T founder owner change_year window_end ceo_spell, i(frame_id_numeric spell_id) j(index)
rename change_year2 change_year

generate window_start = max(change_year1, change_year + $event_window_start)
generate window_end = min(window_end2, change_year + $event_window_end)
* need to sort on skill
drop if missing(MS1, MS2)
drop if ceo_spell1 != ceo_spell2 - 1
rename ceo_spell1 ceo_spell
drop ceo_spell2

*********************
* LIMIT SAMPLE HERE *
*********************
* only non-founder transitions
keep if founder1 == 0 & founder2 == 0

collapse (min) window_start ceo_spell (max) window_end (firstnm) cohort change_year, by(frame_id_numeric spell_id)

* frame_id_numeric will stop being unique once we add placebo
egen fake_id = group(frame_id_numeric ceo_spell)
summarize fake_id
scalar N_TREATED = r(max)
generate byte placebo = 0
generate float weight = 1
compress
save "temp/treated_firms.dta", replace

generate t0 = change_year - window_start

collapse (count) n_treated = frame_id_numeric, by(cohort window_start window_end t0)
* we will create random CEO changes with the same t0 distribution
reshape wide n_treated, i(cohort window_start window_end) j(t0)
mvencode n_treated*, mv(0)
egen byte n_treated = rowtotal(n_treated?)
compress

generate N_TREATED = N_TREATED
save "temp/treatment_groups.dta", replace
