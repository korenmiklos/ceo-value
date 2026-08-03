args panel title

local event_window_start -4
local event_window_end    3
local yscale_opts "ylabel(, angle(0) format(%9.2f))"

    graph twoway ///
        (connected Rsq   t, lcolor(red)   mcolor(red))   ///
        (connected dRsq   t, lcolor(blue)  mcolor(blue))  ///
        , title("Panel `panel': `title'", size(medium)) ///
        legend(order(1 "OLS" 2 "Debiased") rows(1) position(6)) ///
        graphregion(color(white)) ///
        xlabel(`event_window_start'(1)`event_window_end') ///
        xline(-0.5) xscale(range(`event_window_start' `event_window_end')) ///
        xtitle("Time since CEO change (year)") ///
        yline(0) ytitle("R2") ///
        `yscale_opts' ///
        aspectratio(1) xsize(5) ysize(5) ///
        name(panel`panel', replace)
