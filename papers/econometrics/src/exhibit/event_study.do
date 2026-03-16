args panel title ytitle outcome

local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -1            // Baseline year for event study

local yscale_opts "ylabel(, angle(0) format(%9.2f))"
gen cov_beta = coef_dCov/Var1
gen var_beta = coef_Cov1/dVar

graph twoway ///
        (rarea lower_`outcome'1 upper_`outcome'1 t, fcolor(gray%5) lcolor(gray%10)) (connected coef_`outcome'1 t, lcolor(red) mcolor(red)) ///
        (rarea lower_d`outcome' upper_d`outcome' t, fcolor(gray%5) lcolor(gray%10)) (connected coef_d`outcome' t, lcolor(blue) mcolor(blue)) ///
        (connected cov_beta  t, lcolor(black) mcolor(black)) (connected var_beta  t, lcolor(green) mcolor(green)) ///
        ,  title("Panel `panel': `title'", size(medium)) ///
        legend(order(2 "No" 4 "All" 5 "Cov" 6 "Var") rows(1) position(6)) ///
        graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
        xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
        xtitle("Time since CEO change (year)") yline(0) ///
        ytitle("`ytitle'") ///
        `yline' `yscale_opts' ///
        aspectratio(1) xsize(5) ysize(5) ///
        name(panel`panel', replace)

