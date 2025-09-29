args panel title ytitle

local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -2            // Baseline year for event study

graph twoway ///
    (rarea lower_mean upper_mean xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_mean xvar, lcolor(black) mcolor(black)) ///
    (rarea lower_worse upper_worse xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_worse xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_better upper_better xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_better xvar, lcolor(red) mcolor(red)) ///
    ,  title("Panel `panel': `title'", size(medium)) ///
    legend(order(6 "Better" 2 "Mean" 4 "Worse") rows(1) position(6)) ///
    graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("`ytitle'") ///
    ylabel(, angle(0) format(%9.2f)) ///
    aspectratio(1) xsize(5) ysize(5) ///
    name(panel`panel', replace)
