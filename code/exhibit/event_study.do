args panel title ytitle

local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -3            // Baseline year for event study

graph twoway ///
    (rarea lower_beta1alt upper_beta1alt xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_beta1alt xvar, lcolor(red) mcolor(red)) ///
    (rarea lower_beta0alt upper_beta0alt xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_beta0alt xvar, lcolor(blue) mcolor(blue)) ///
    (rarea lower_dbetaalt upper_dbetaalt xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef_dbetaalt xvar, lcolor(black) mcolor(black)) ///
    ,  title("Panel `panel': `title'", size(medium)) ///
    legend(order(2 "Treated" 4 "Control" 6 "Adjusted") rows(1) position(6)) ///
    graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
    xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
    xtitle("Time since CEO change (year)") yline(0) ///
    ytitle("`ytitle'") ///
    `yline' ylabel(, angle(0) format(%9.2f)) ///
    aspectratio(1) xsize(5) ysize(5) ///
    name(panel`panel', replace)
