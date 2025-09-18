* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
global first_spell 1                // First spell for event study
global second_spell 2               // Second spell for event study
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
keep if inlist(ceo_spell, ${first_spell}, ${second_spell})

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

reshape wide MS T founder owner change_year window_end, i(frame_id_numeric) j(ceo_spell)
rename change_year2 change_year

generate window_start = max(change_year1, change_year + $event_window_start)
generate window_end = min(window_end2, change_year + $event_window_end)

* need to sort on skill
drop if missing(MS1, MS2)

* keep founder to non-founder transitions only, except for placebo, where keep everyone
keep if (founder1 == 1 & founder2 == 0) 
drop if T1 < ${min_T} | T2 < ${min_T}

collapse (min) window_start (max) window_end (firstnm) cohort change_year, by(frame_id_numeric)

* frame_id_numeric will stop being unique once we add placebo
egen fake_id = group(frame_id_numeric)
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
