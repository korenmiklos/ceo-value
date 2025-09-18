local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -3            // Baseline year for event study
local format graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("Moments of log TFP change since year `baseline_year'") ///
    ylabel(, angle(0) format(%9.2f)) ///
    aspectratio(1) xsize(5) ysize(5) 
* =============================================================================
* CREATE PANEL A: RAW EVENT STUDY
* =============================================================================

local mean Panel A: Mean
local var Panel B: Variance

local outcomes mean var
local combined

use "temp/event_study_moments.dta", clear

foreach Y in `outcomes' {
    graph twoway ///
        (rarea lower_`Y' upper_`Y' xvar, fcolor(gray%5) lcolor(gray%10)) ///
        (connected coef_`Y' xvar, lcolor(blue) mcolor(blue)) ///
        ,  title("``Y''", size(medium)) ///
        legend(off) ///
        `format' ///
        saving("temp/event_study_`Y'.gph", replace)
    
    local combined "`combined' temp/event_study_`Y'.gph"
}

graph combine `combined', ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5)

graph export "output/figure/event_study_moments.pdf", replace

