* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
local max_spell_analysis 2        // Maximum CEO spell for analysis
local skill_cutoff_lower -0.05    // Lower skill change cutoff
local skill_cutoff_upper 0.05     // Upper skill change cutoff  
local event_window_start -10      // Event study window start
local event_window_end 10         // Event study window end
local baseline_year -2            // Baseline year for event study
local min_obs_threshold 1         // Minimum observations before/after
local scatter_sample_prob 0.1     // Sampling probability for scatter plot
local random_seed 2181            // Random seed for reproducibility

use "temp/surplus.dta", clear
* to limit sample to giant component
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(match) nogen
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen

* limit sample to clean changes between first and second CEO 
keep if max_ceo_spell >= `max_spell_analysis'
keep if ceo_spell <= `max_spell_analysis'
keep if n_ceo == 1
keep if !missing(lnStilde)

egen change_year = min(cond(ceo_spell == 2, year, .)), by(frame_id_numeric)
generate event_time = year - change_year
drop change_year

egen MS1 = min(cond(ceo_spell == 1, manager_skill, .)), by(frame_id_numeric)
egen MS2 = min(cond(ceo_spell == 2, manager_skill, .)), by(frame_id_numeric)
drop if missing(MS1, MS2)
egen firm_tag = tag(frame_id_numeric)

set seed `random_seed'
scatter MS2 MS1 if firm_tag & uniform() < `scatter_sample_prob', ///
    title("Manager Skills of First and Second CEO") ///
    xtitle("Skill of First CEO (log points)") ///
    ytitle("Skill of Second CEO (log points)") ///
    msize(tiny) mcolor(blue%25)
graph export "output/figure/manager_skill_correlation.pdf", replace

generate skill_change = MS2 - MS1

count if inrange(skill_change, -100, 100) & event_time == 0
count if inrange(skill_change, -0.1, 0.1) & event_time == 0
count if inrange(skill_change, `skill_cutoff_lower', `skill_cutoff_upper') & event_time == 0

recode skill_change (min/`skill_cutoff_lower' = -1) (`skill_cutoff_lower'/`skill_cutoff_upper' = 0) (`skill_cutoff_upper'/max = 1)

tabulate skill_change if firm_tag, missing
tabulate event_time skill_change, missing

generate same_ceo = event_time >= 0 & skill_change == 0
generate better_ceo = event_time >= 0 & skill_change == 1
generate worse_ceo = event_time >= 0 & skill_change == -1

egen n_before = sum(event_time < 0), by(frame_id_numeric)
egen n_after = sum(event_time >= 0), by(frame_id_numeric)

* prepare for event study estimation
keep if inrange(event_time, `event_window_start', `event_window_end') & n_before >= `min_obs_threshold' & n_after >= `min_obs_threshold'
xtset frame_id_numeric year

xt2treatments lnStilde if inlist(skill_change, -1, 0), treatment(worse_ceo) control(same_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(worse_ceo)

xt2treatments lnStilde if inlist(skill_change, 1, 0), treatment(better_ceo) control(same_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(better_ceo)

* now link the two frames, better_ceo and worse_ceo and create the event study figure with two lines
foreach X in coef lower upper {
    frame better_ceo: rename `X' `X'_better
    frame worse_ceo: rename `X' `X'_worse
}
frame worse_ceo: frlink 1:1 xvar, frame(better_ceo)
frame worse_ceo: frget coef_better lower_better upper_better, from(better_ceo)

frame worse_ceo: graph twoway ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') legend(order(4 "Better CEO" 2 "Worse CEO")) xline(-0.5) xscale(range (`event_window_start' `event_window_end')) xtitle("Time since CEO change (year)") yline(0) ytitle("Log TFP relative to year `baseline_year'") 
graph export "output/figure/event_study.pdf", replace

* save difference for tests
xt2treatments lnStilde if inlist(skill_change, 1, -1), treatment(better_ceo) control(worse_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(difference)
foreach X in coef lower upper {
    frame difference: rename `X' `X'_actual
}
frame difference: save "output/test/event_study.dta", replace
