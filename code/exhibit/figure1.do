local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -3            // Baseline year for event study

* =============================================================================
* CREATE PANEL A: RAW EVENT STUDY
* =============================================================================

use "temp/event_study_panel_a.dta", clear

graph twoway ///
    (rarea lower_actual upper_actual xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_actual xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_placebo upper_placebo xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_placebo xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') legend(off) ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("Log TFP relative to year `baseline_year'") ///
    title("Panel A: Actual vs Placebo", size(medium)) ///
    ylabel(, angle(0)) ///
    saving("temp/event_study_panel_a.gph", replace)

* =============================================================================
* CREATE PANEL B: PLACEBO-CONTROLLED EVENT STUDY
* =============================================================================

use "temp/event_study_panel_b.dta", clear

graph twoway ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') legend(off) ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("Log TFP relative to year `baseline_year'") ///
    title("Panel B: Placebo-Controlled Event Study", size(medium)) ///
    ylabel(, angle(0)) ///
    saving("temp/event_study_panel_b.gph", replace)


use "temp/event_study_moments.dta", clear

graph twoway ///
    (rarea lower_mean upper_mean xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_mean xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_var upper_var xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_var xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') legend(order(2 "Mean" 4 "Variance")) ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("Moments of log TFP relative to year `baseline_year'") ///
    title("Panel C: First and Second Moments of TFP Around CEO Change", size(medium)) ///
    ylabel(, angle(0)) ///
    saving("temp/event_study_panel_c.gph", replace)

graph export "output/figure/event_study_panel_c.pdf", replace

* =============================================================================
* COMBINE PANELS WITH COMMON Y-SCALE AND BOTTOM LEGEND
* =============================================================================

graph combine "temp/event_study_panel_a.gph" "temp/event_study_panel_b.gph", ///
    cols(2) ycommon graphregion(color(white)) imargin(small)

graph export "output/figure/event_study.pdf", replace

display "Event study figure created: output/figure/event_study.pdf"