* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
global first_spell 1                // First spell for event study
global second_spell 2               // Second spell for event study
global skill_cutoff_upper 0.01    // Upper skill change cutoff
global skill_cutoff_lower -0.01   // Lower skill change cutoff
global event_window_start -4      // Event study window start
global event_window_end 3         // Event study window end
global baseline_year -3            // Baseline year for event study
global min_obs_threshold 1         // Minimum observations before/after
global min_T 1                     // Minimum observations to estimate fixed effects
global random_seed 2181            // Random seed for reproducibility
global sample 100                   // Sample selection for analysis
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

* merge on placebo spells
merge m:1 frame_id_numeric year using "temp/placebo.dta", keep(master match) nogen
generate byte expand_N = cond(!missing(placebo_spell), 2, 1)
expand expand_N, generate(placebo)

tabulate placebo, missing

*********************************
* prepare actual and placebo ids
replace ceo_spell = placebo_spell if placebo
egen long fake_id = group(frame_id_numeric placebo)
*********************************
drop max_ceo_spell expand_N placebo_spell
egen max_ceo_spell = max(ceo_spell), by(fake_id)

* limit sample to clean changes between first and second CEO 
keep if ceo_spell <= max_ceo_spell
keep if !missing(lnStilde)
keep if inlist(ceo_spell, ${first_spell}, ${second_spell})


egen change_year = min(cond(ceo_spell == ${second_spell}, year, .)), by(fake_id)
generate event_time = year - change_year

tabulate ceo_spell placebo, missing
tabulate change_year placebo, missing
tabulate event_time placebo, missing
drop change_year

egen T1 = total((ceo_spell == ${first_spell}) & !missing(lnStilde)), by(fake_id)
egen T2 = total((ceo_spell == ${second_spell}) & !missing(lnStilde)), by(fake_id)

drop if T1 < ${min_T} | T2 < ${min_T}
* demean TFP to make it comparable with manager value, which has zero mean by construction
summarize lnStilde
replace lnStilde = lnStilde - r(mean)

egen MS2a = mean(cond(ceo_spell == ${second_spell}, manager_skill, .)), by(fake_id)
egen MS2 = mean(cond(ceo_spell == ${second_spell}, lnStilde, .)), by(fake_id)

replace MS2 = MS2a if !placebo

drop if missing(MS2)
egen firm_tag = tag(fake_id)

generate byte good_ceo = (MS2 > 0)

* small change firms can be used as control
tabulate good_ceo if firm_tag, missing
tabulate event_time good_ceo, missing

generate byte actual_ceo = event_time >= 0 & placebo == 0
generate byte placebo_ceo = event_time >= 0 & placebo == 1
generate byte better_ceo = event_time >= 0 & good_ceo == 1
generate byte worse_ceo = event_time >= 0 & good_ceo == 0

egen n_before = sum(event_time < 0), by(fake_id)
egen n_after = sum(event_time >= 0), by(fake_id)

* prepare for event study estimation
keep if inrange(event_time, ${event_window_start}, ${event_window_end}) & n_before >= ${min_obs_threshold} & n_after >= ${min_obs_threshold}

display "Worsening CEOs"
tabulate event_time placebo if good_ceo == 0, missing
table event_time placebo if good_ceo == 0, stat(mean lnStilde)

display "Improving CEOs"
tabulate event_time placebo if good_ceo == 1, missing
table event_time placebo if good_ceo == 1, stat(mean lnStilde)

xtset fake_id year
