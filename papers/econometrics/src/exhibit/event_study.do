args panel title ytitle

local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -1            // Baseline year for event study

graph twoway ///
    (rarea lower_beta1 upper_beta1 t, fcolor(gray%5) lcolor(gray%10)) (connected coef_beta1 t, lcolor(red) mcolor(red)) ///
    (rarea lower_dbeta upper_dbeta t, fcolor(gray%5) lcolor(gray%10)) (connected coef_dbeta t, lcolor(blue) mcolor(blue)) ///
    ,  title("Panel `panel': `title'", size(medium)) ///
    legend(order(2 "Naive" 4 "Debiased") rows(1) position(6)) ///
    graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("`ytitle'") ///
    `yline' ylabel(, angle(0) format(%9.2f)) ///
    aspectratio(1) xsize(5) ysize(5) ///
    name(panel`panel', replace)
