* =============================================================================
* PLACEBO EVENT STUDY PARAMETERS  
* =============================================================================
local max_spell_analysis 2        // Maximum CEO spell for analysis
local skill_cutoff_lower -0.05    // Lower skill change cutoff
local skill_cutoff_upper 0.05     // Upper skill change cutoff  
local event_window_start -10      // Event study window start
local event_window_end 10         // Event study window end
local baseline_year -2            // Baseline year for event study
local min_obs_threshold 1         // Minimum observations before/after

use "temp/manager_value.dta", clear
* to limit sample to giant component
keep frame_id_numeric
duplicates drop
tempfile giant_component
save `giant_component', replace

use "temp/surplus.dta", clear
* to limit sample to giant component
merge m:1 frame_id_numeric using `giant_component', keep(match) nogen
merge m:1 frame_id_numeric year using "temp/placebo.dta", keep(match) nogen
rename ceo_spell actual_spell

* pretend these spells are the real ones
rename placebo_spell ceo_spell

* limit sample to clean changes between first and second CEO 
egen max_ceo_spell = max(ceo_spell), by(frame_id_numeric)
keep if max_ceo_spell >= `max_spell_analysis'
keep if ceo_spell <= `max_spell_analysis'
keep if !missing(lnStilde)

egen change_year = min(cond(ceo_spell == 2, year, .)), by(frame_id_numeric)
generate event_time = year - change_year
drop change_year

* there is no separate measure of CEO skill, so we use lnStilde
egen MS1 = min(cond(ceo_spell == 1, lnStilde, .)), by(frame_id_numeric)
egen MS2 = min(cond(ceo_spell == 2, lnStilde, .)), by(frame_id_numeric)
drop if missing(MS1, MS2)
egen firm_tag = tag(frame_id_numeric)

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

egen n_before = sum(event_time < 0 & !missing(lnStilde)), by(frame_id_numeric)
egen n_after = sum(event_time >= 0 & !missing(lnStilde)), by(frame_id_numeric)

* prepare for event study estimation
keep if inrange(event_time, `event_window_start', `event_window_end') & n_before >= `min_obs_threshold' & n_after >= `min_obs_threshold'
xtset frame_id_numeric year

* save snapshot for tests
save "output/test/placebo.dta", replace

* save difference for tests
xt2treatments lnStilde if inlist(skill_change, 1, -1), treatment(better_ceo) control(worse_ceo) pre(`=-1*`event_window_start'') post(`event_window_end') baseline(`baseline_year') weighting(optimal)
e2frame, generate(difference)
foreach X in coef lower upper {
    frame difference: rename `X' `X'_placebo
}
* merge on actual results and plot on the same graph
frame difference: merge 1:1 xvar using "output/test/event_study.dta", keep(match) nogen
frame difference: graph twoway ///
    (rarea lower_placebo upper_placebo xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_placebo xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_actual upper_actual xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_actual xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
    legend(order(4 "Actual change" 2 "Placebo change")) xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ytitle("Log TFP relative to year `baseline_year'")
graph export "output/figure/placebo_vs_actual.pdf", replace