local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -3            // Baseline year for event study
local format graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("Log TFP relative to year `baseline_year'") ///
    ylabel(, angle(0) format(%9.2f)) ///
    aspectratio(1) xsize(5) ysize(5) 
* =============================================================================
* CREATE PANEL A: RAW EVENT STUDY
* =============================================================================

use "temp/event_study_panel_a.dta", clear

graph twoway ///
    (rarea lower_actual upper_actual xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_actual xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_placebo upper_placebo xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_placebo xvar, lcolor(red) mcolor(red)) ///
    ,  title("Panel A: Actual vs Placebo", size(medium)) ///
    legend(order(2 "Actual" 4 "Placebo") rows(1) position(6)) ///
    `format' ///
    saving("temp/event_study_panel_a.gph", replace)

* =============================================================================
* CREATE PANEL B: PLACEBO-CONTROLLED EVENT STUDY
* =============================================================================

use "temp/event_study_panel_b.dta", clear

graph twoway ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    ,  title("Panel B: Worse vs Better CEO", size(medium)) ///
    legend(order(2 "Worse" 4 "Better") rows(1) position(6)) ///
    `format' ///
    saving("temp/event_study_panel_b.gph", replace)

use "temp/event_study_panel_c.dta", clear

graph twoway ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    ,  title("Panel C: Sample Period: 2004-2022", size(medium)) ///
    legend(order(2 "Worse" 4 "Better") rows(1) position(6)) ///
    `format' ///
    saving("temp/event_study_panel_c.gph", replace)

use "temp/event_study_panel_d.dta", clear

graph twoway ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    ,  title("Panel D: Excluding Founders", size(medium)) ///
    legend(order(2 "Worse" 4 "Better") rows(1) position(6)) ///
    `format' ///
    saving("temp/event_study_panel_d.gph", replace)


* =============================================================================
* COMBINE PANELS WITH COMMON Y-SCALE AND BOTTOM LEGEND
* =============================================================================

graph combine "temp/event_study_panel_a.gph" "temp/event_study_panel_b.gph" "temp/event_study_panel_c.gph" "temp/event_study_panel_d.gph", ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5) 

graph export "output/figure/event_study.pdf", replace

display "Event study figure created: output/figure/event_study.pdf"