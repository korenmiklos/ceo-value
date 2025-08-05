* =============================================================================
* EVENT STUDY PARAMETERS
* =============================================================================
local max_spell_analysis 2        // Maximum CEO spell for analysis
local skill_cutoff 0.0            // Lower skill change cutoff
local event_window_start -5      // Event study window start
local event_window_end 5         // Event study window end
local baseline_year -5            // Baseline year for event study
local min_obs_threshold 1         // Minimum observations before/after
local scatter_sample_prob 0.1     // Sampling probability for scatter plot
local random_seed 2181            // Random seed for reproducibility

use "temp/surplus.dta", clear
* to limit sample to giant component
merge m:1 frame_id_numeric person_id using "temp/manager_value.dta", keep(match) nogen
merge 1:1 frame_id_numeric person_id year using "temp/analysis-sample.dta", keep(match) nogen

* merge on placebo spells
merge m:1 frame_id_numeric year using "temp/placebo.dta", keep(master match) nogen
generate byte expand_N = cond(!missing(placebo_spell), 2, 1)
expand expand_N, generate(placebo)

tabulate placebo, missing

*********************************
* prepare actual and placebo ids
replace ceo_spell = placebo_spell if placebo
egen long fake_id = group(frame_id_numeric placebo)
egen MS = mean(lnStilde), by(fake_id ceo_spell)
replace manager_skill = MS if placebo
drop MS
*********************************
drop max_ceo_spell expand_N placebo_spell
egen max_ceo_spell = max(ceo_spell), by(fake_id)

* limit sample to clean changes between first and second CEO 
keep if max_ceo_spell >= `max_spell_analysis'
keep if ceo_spell <= `max_spell_analysis'
keep if n_ceo == 1
keep if !missing(lnStilde, manager_skill)

egen change_year = min(cond(ceo_spell == 2, year, .)), by(fake_id)
generate event_time = year - change_year

tabulate ceo_spell placebo, missing
tabulate change_year placebo, missing
tabulate event_time placebo, missing
drop change_year

egen MS1 = min(cond(ceo_spell == 1, manager_skill, .)), by(fake_id)
egen MS2 = min(cond(ceo_spell == 2, manager_skill, .)), by(fake_id)

drop if missing(MS1, MS2)
egen firm_tag = tag(fake_id)

generate byte skill_change = (MS2 - MS1) > `skill_cutoff'

tabulate skill_change if firm_tag, missing
tabulate event_time skill_change, missing

generate byte actual_ceo = event_time >= 0 & placebo == 0
generate byte placebo_ceo = event_time >= 0 & placebo == 1
generate byte better_ceo = event_time >= 0 & skill_change == 1
generate byte worse_ceo = event_time >= 0 & skill_change == 0

egen n_before = sum(event_time < 0), by(fake_id)
egen n_after = sum(event_time >= 0), by(fake_id)

* prepare for event study estimation
keep if inrange(event_time, `event_window_start', `event_window_end') & n_before >= `min_obs_threshold' & n_after >= `min_obs_threshold'

display "Worsening CEOs"
tabulate event_time placebo if skill_change == 0, missing
table event_time placebo if skill_change == 0, stat(mean lnStilde)

display "Improving CEOs"
tabulate event_time placebo if skill_change == 1, missing
table event_time placebo if skill_change == 1, stat(mean lnStilde)

xtset fake_id year

xt2treatments lnStilde if placebo == 0, treatment(better_ceo) control(worse_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)

xt2treatments lnStilde if placebo == 1, treatment(better_ceo) control(worse_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
BRK

xt2treatments lnStilde if skill_change == 0, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(worse_ceo)

xt2treatments lnStilde if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
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
BRK
* save difference for tests
xt2treatments lnStilde if inlist(skill_change, 1, -1), treatment(better_ceo) control(worse_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(difference)
foreach X in coef lower upper {
    frame difference: rename `X' `X'_actual
}
frame difference: save "output/test/event_study.dta", replace
