local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -3            // Baseline year for event study
local format graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("Log change since year `baseline_year'") ///
    ylabel(, angle(0) format(%9.2f)) ///
    aspectratio(1) xsize(5) ysize(5) 
* =============================================================================
* CREATE PANEL A: RAW EVENT STUDY
* =============================================================================

local lnK Panel A: Capital
local has_intangible Panel B: Intangible
local lnWL Panel C: Wagebill
local lnM Panel D: Materials

local outcomes lnK has_intangible lnWL lnM
local combined

foreach Y in `outcomes' {
    use "temp/event_study_`Y'.dta", clear

    graph twoway ///
        (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
        (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
        ,  title("``Y''", size(medium)) ///
        legend(order(4 "Better" 2 "Worse") rows(1) position(6)) ///
        `format' ///
        saving("temp/event_study_`Y'.gph", replace)
    
    local combined "`combined' temp/event_study_`Y'.gph"
}

graph combine `combined', ///
    cols(2) ycommon graphregion(color(white)) imargin(small) xsize(5) ysize(5)

graph export "output/figure/event_study_outcomes.pdf", replace

display "Event study figure created: output/figure/event_study.pdf"