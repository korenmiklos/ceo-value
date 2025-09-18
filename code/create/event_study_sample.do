* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
global first_spell 1                // First spell for event study
global second_spell 2               // Second spell for event study
global event_window_start -4      // Event study window start
global event_window_end 3         // Event study window end
global baseline_year -1            // Baseline year for event study
global min_obs_threshold 1         // Minimum observations before/after
global min_T 1                     // Minimum observations to estimate fixed effects
global random_seed 2181            // Random seed for reproducibility
global sample 25                   // Sample selection for analysis
global max_n_ceo 1                // Maximum number of CEOs per firm for analysis

use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(master match) nogen

* keep single-ceo firms
egen max_n_ceo = max(n_ceo), by(frame_id_numeric)
tabulate n_ceo max_n_ceo, missing
keep if max_n_ceo <= ${max_n_ceo}

* sample for performance when testing
set seed ${random_seed}
egen firm_tag = tag(frame_id_numeric)
generate byte in_sample = uniform() < ${sample}/100 if firm_tag
egen ever_in_sample = max(in_sample), by(frame_id_numeric)
keep if ever_in_sample == 1
drop ever_in_sample in_sample firm_tag

* limit sample to clean changes between first and second CEO 
keep if ceo_spell <= max_ceo_spell
keep if !missing(lnStilde)
keep if inlist(ceo_spell, ${first_spell}, ${second_spell})

egen MS1a = mean(cond(ceo_spell == ${first_spell}, manager_skill, .)), by(frame_id_numeric)
egen MS2a = mean(cond(ceo_spell == ${second_spell}, manager_skill, .)), by(frame_id_numeric)
drop if missing(MS1a, MS2a)

egen some_owner = max(founder | owner ), by(frame_id_numeric )
egen founder1 = max(cond(ceo_spell == ${first_spell}, founder, .)), by(frame_id_numeric)
egen founder2 = max(cond(ceo_spell == ${second_spell}, founder, .)), by(frame_id_numeric)

* keep founder to non-founder transitions only, except for placebo, where keep everyone
keep if (founder1 == 1 & founder2 == 0) 

egen change_year = min(cond(ceo_spell == ${second_spell}, year, .)), by(frame_id_numeric)
generate event_time = year - change_year
local in_window inrange(event_time, ${event_window_start}, ${event_window_end}) 

egen T1 = total((ceo_spell == ${first_spell} & `in_window') & !missing(lnStilde)), by(frame_id_numeric)
egen T2 = total((ceo_spell == ${second_spell} & `in_window') & !missing(lnStilde)), by(frame_id_numeric)

drop if T1 < ${min_T} | T2 < ${min_T}
keep if `in_window'

* demean TFP to make it comparable with manager value, which has zero mean by construction
summarize lnStilde
replace lnStilde = lnStilde - r(mean)

egen firm_tag = tag(frame_id_numeric)

tabulate ceo_spell some_owner
tabulate ceo_spell founder1

tabulate ceo_spell

generate cohort = foundyear
tabulate cohort, missing
replace cohort = 1989 if cohort < 1989
tabulate cohort, missing

collapse (min) window_start = year (max) window_end = year (firstnm) cohort change_year, by(frame_id_numeric)
compress
save "temp/treated_firms.dta", replace

generate t0 = change_year - window_start

collapse (count) n_treated = frame_id_numeric, by(cohort window_start window_end t0)
* we will create random CEO changes with the same t0 distribution
reshape wide n_treated, i(cohort window_start window_end) j(t0)
mvencode n_treated*, mv(0)
egen byte n_treated = rowtotal(n_treated?)
compress
save "temp/treatment_groups.dta", replace
