args panel title ytitle

local event_window_start -4
local event_window_end    3
local yscale_opts "ylabel(, angle(0) format(%9.2f))"

cwf dCov

    drop if t == 99   // drop ATET row if present

    graph twoway ///
        (rarea lower_beta1  upper_beta1  t, fcolor(gray%5) lcolor(gray%10)) ///
        (connected coef_beta1   t, lcolor(red)   mcolor(red))   ///
        (rarea lower_dbeta  upper_dbeta  t, fcolor(gray%5) lcolor(gray%10)) ///
        (connected coef_dbeta   t, lcolor(blue)  mcolor(blue))  ///
        (connected coef_cov_beta t, lcolor(black) mcolor(black)) ///
        (connected coef_var_beta t, lcolor(green) mcolor(green)) ///
        , title("Panel `panel': `title'", size(medium)) ///
        legend(order(2 "No" 4 "All" 5 "Cov" 6 "Var") rows(1) position(6)) ///
        graphregion(color(white)) ///
        xlabel(`event_window_start'(1)`event_window_end') ///
        xline(-0.5) xscale(range(`event_window_start' `event_window_end')) ///
        xtitle("Time since CEO change (year)") ///
        yline(0) ytitle("`ytitle'") ///
        `yscale_opts' ///
        aspectratio(1) xsize(5) ysize(5) ///
        name(panel`panel', replace)

        graph export "figure/test.pdf", replace

cwf default
frames drop dCov
