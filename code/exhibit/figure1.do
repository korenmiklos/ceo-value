*! Create Figure 1: Event Study Results - Raw and Placebo-Controlled
*! Reads data from event study estimation and creates combined two-panel figure

* =============================================================================
* FIGURE PARAMETERS
* =============================================================================
local event_window_start -5      // Event study window start
local event_window_end 5         // Event study window end
local baseline_year -5            // Baseline year for event study

* =============================================================================
* LOAD SAVED EVENT STUDY DATA
* =============================================================================

* Load Panel A data (raw event study)
use "temp/event_study_panel_a.dta", clear
tempfile panel_a
save `panel_a'

* Load Panel B data (placebo-controlled event study)  
use "temp/event_study_panel_b.dta", clear
tempfile panel_b
save `panel_b'

* =============================================================================
* CREATE PANEL A: RAW EVENT STUDY
* =============================================================================

use `panel_a', clear

graph twoway ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    , graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') legend(off) ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("Log TFP relative to year `baseline_year'") ///
    title("Panel A: Raw Event Study", size(medium)) ///
    ylabel(, angle(0)) ///
    saving("temp/event_study_panel_a.gph", replace)

* =============================================================================
* CREATE PANEL B: PLACEBO-CONTROLLED EVENT STUDY
* =============================================================================

use `panel_b', clear

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

* =============================================================================
* COMBINE PANELS WITH COMMON Y-SCALE AND BOTTOM LEGEND
* =============================================================================

graph combine "temp/event_study_panel_a.gph" "temp/event_study_panel_b.gph", ///
    cols(2) ycommon graphregion(color(white)) imargin(small) ///
    note("Note: {bf:Blue line} = Worse CEO; {bf:Red line} = Better CEO. Confidence intervals shown in gray.", ///
         size(small) position(6) span)

graph export "output/figure/event_study.pdf", replace

display "Event study figure created: output/figure/event_study.pdf"