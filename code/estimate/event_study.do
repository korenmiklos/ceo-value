* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
local max_spell_analysis 2        // Maximum CEO spell for analysis
local skill_cutoff_upper 0.01    // Upper skill change cutoff
local skill_cutoff_lower -0.01   // Lower skill change cutoff
local event_window_start -5      // Event study window start
local event_window_end 5         // Event study window end
local baseline_year -2            // Baseline year for event study
local min_obs_threshold 1         // Minimum observations before/after
local min_T 1                     // Minimum observations to estimate fixed effects
local random_seed 2181            // Random seed for reproducibility
local sample 100                   // Sample selection for analysis

use "temp/surplus.dta", clear
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(master match) nogen

* sample for performance when testing
set seed `random_seed'
egen firm_tag = tag(frame_id_numeric)
generate byte in_sample = uniform() < `sample'/100 if firm_tag
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
keep if max_ceo_spell >= `max_spell_analysis'
keep if ceo_spell <= `max_spell_analysis'
keep if n_ceo == 1
keep if !missing(lnStilde)

egen change_year = min(cond(ceo_spell == 2, year, .)), by(fake_id)
generate event_time = year - change_year

tabulate ceo_spell placebo, missing
tabulate change_year placebo, missing
tabulate event_time placebo, missing
drop change_year

egen MS1a = mean(cond(ceo_spell == 1, manager_skill, .)), by(fake_id)
egen MS2a = mean(cond(ceo_spell == 2, manager_skill, .)), by(fake_id)

egen MS1 = mean(cond(ceo_spell == 1, lnStilde, .)), by(fake_id)
egen MS2 = mean(cond(ceo_spell == 2, lnStilde, .)), by(fake_id)

replace MS1 = MS1a if !placebo
replace MS2 = MS2a if !placebo

egen T1 = total((ceo_spell == 1) & !missing(lnStilde)), by(fake_id)
egen T2 = total((ceo_spell == 2) & !missing(lnStilde)), by(fake_id)

drop if T1 < `min_T' | T2 < `min_T'
drop if missing(MS1, MS2)
egen firm_tag = tag(fake_id)

generate skill_change = (MS2 - MS1)
recode skill_change (min/`skill_cutoff_lower' = -1) (`skill_cutoff_lower'/`skill_cutoff_upper' = 0) (`skill_cutoff_upper'/max = 1)

* small change firms can be used as control
tabulate skill_change if firm_tag, missing
tabulate event_time skill_change, missing

generate byte actual_ceo = event_time >= 0 & placebo == 0
generate byte placebo_ceo = event_time >= 0 & placebo == 1
generate byte better_ceo = event_time >= 0 & skill_change == 1
generate byte worse_ceo = event_time >= 0 & skill_change == -1
generate byte same_ceo = event_time >= 0 & skill_change == 0

egen n_before = sum(event_time < 0), by(fake_id)
egen n_after = sum(event_time >= 0), by(fake_id)

* prepare for event study estimation
keep if inrange(event_time, `event_window_start', `event_window_end') & n_before >= `min_obs_threshold' & n_after >= `min_obs_threshold'

display "Worsening CEOs"
tabulate event_time placebo if skill_change == -1, missing
table event_time placebo if skill_change == -1, stat(mean lnStilde)

display "Improving CEOs"
tabulate event_time placebo if skill_change == 1, missing
table event_time placebo if skill_change == 1, stat(mean lnStilde)

xtset fake_id year

xt2treatments lnStilde if placebo == 0 & inlist(skill_change, -1, 0), treatment(worse_ceo) control(same_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(worse_ceo1)

xt2treatments lnStilde if placebo == 0 & inlist(skill_change, 1, 0), treatment(better_ceo) control(same_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(better_ceo1)

xt2treatments lnStilde if skill_change == -1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(worse_ceo2)

xt2treatments lnStilde if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(better_ceo2)

* now link the two frames, better_ceo and worse_ceo and create the event study figure with two lines
* Create Panel A: Raw event study (better vs worse, control = small change)
foreach X in coef lower upper {
    frame better_ceo1: rename `X' `X'_better
    frame worse_ceo1: rename `X' `X'_worse
}
frame worse_ceo1: frlink 1:1 xvar, frame(better_ceo1)
frame worse_ceo1: frget coef_better lower_better upper_better, from(better_ceo1)

* Create Panel B: Placebo-controlled event study (better vs worse, actual vs placebo)
foreach X in coef lower upper {
    frame better_ceo2: rename `X' `X'_better
    frame worse_ceo2: rename `X' `X'_worse
}
frame worse_ceo2: frlink 1:1 xvar, frame(better_ceo2)
frame worse_ceo2: frget coef_better lower_better upper_better, from(better_ceo2)

* Save frames for figure creation
frame worse_ceo1: save "temp/event_study_panel_a.dta", replace
frame worse_ceo2: save "temp/event_study_panel_b.dta", replace

display "Event study estimation complete. Data saved to temp/ for figure creation."

log using "output/event_study.txt", replace text

drop if skill_change == 0

display "Event study results for better CEOs:"
* compare naive control to placebo controlled event study
xt2treatments lnStilde if placebo == 0, treatment(better_ceo) control(worse_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(atet) weighting(optimal)
scalar total_atet = _b[ATET]

xt2treatments lnStilde if placebo == 1, treatment(better_ceo) control(worse_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(atet) weighting(optimal)
scalar placebo_atet = _b[ATET]

xt2treatments lnStilde if skill_change == -1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(atet) weighting(optimal)
scalar worse_atet = _b[ATET]

xt2treatments lnStilde if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(atet) weighting(optimal)
scalar better_atet = _b[ATET]

scalar proper_atet1 = better_atet - worse_atet
scalar proper_atet2 = total_atet - placebo_atet

display "Total ATET: " total_atet
display "Placebo-controlled ATET 1: " proper_atet1
display "Placebo-controlled ATET 2: " proper_atet2
log close