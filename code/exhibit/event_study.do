args panel title ytitle

local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -3            // Baseline year for event study

graph twoway ///
    (rarea lower_beta1 upper_beta1 xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_beta1 xvar, lcolor(black) mcolor(black)) ///
    (rarea lower_dbeta upper_dbeta xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_dbeta xvar, lcolor(blue) mcolor(blue)) ///
    ,  title("Panel `panel': `title'", size(medium)) ///
    legend(order(2 "OLS" 4 "Placebo-controlled") rows(1) position(6)) ///
    graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("`ytitle'") ///
    `yline' ylabel(, angle(0) format(%9.2f)) ///
    aspectratio(1) xsize(5) ysize(5) ///
    name(panel`panel', replace)
