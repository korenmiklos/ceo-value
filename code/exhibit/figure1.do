local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -3            // Baseline year for event study

* =============================================================================
* CREATE PANEL A: RAW EVENT STUDY
* =============================================================================

use "output/event_study_panel_b.dta", clear

graph twoway ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') legend(off) ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("Log TFP relative to year `baseline_year'") ///
    title("Panel C: Sample Period: 2004-2022", size(medium)) ///
    ylabel(, angle(0)) ///
    saving("output/event_study_panel_c.gph", replace)


