args panel title ytitle

local event_window_start -4
local event_window_end    3
local yscale_opts "ylabel(, angle(0) format(%9.2f))"

* merge the two frames into a tempfile for plotting
frame denoised {
    tempfile f_denoised
    save `f_denoised'
}
frame naive {
    tempfile f_naive
    save `f_naive'
}

preserve
    use `f_denoised', clear
    rename (coef lower upper) (coef_denoised lower_denoised upper_denoised)
    merge 1:1 xvar using `f_naive', nogen
    rename (coef lower upper) (coef_naive lower_naive upper_naive)
    rename xvar t

    graph twoway ///
        (rarea lower_naive upper_naive t, fcolor(gray%5) lcolor(gray%10)) ///
        (connected coef_naive t, lcolor(red) mcolor(red)) ///
        (rarea lower_denoised upper_denoised t, fcolor(gray%5) lcolor(gray%10)) ///
        (connected coef_denoised t, lcolor(blue) mcolor(blue)) ///
        , title("Panel `panel': `title'", size(medium)) ///
        legend(order(2 "Naive" 4 "Debiased") rows(1) position(6)) ///
        graphregion(color(white)) ///
        xlabel(`event_window_start'(1)`event_window_end') ///
        xline(-0.5) xscale(range(`event_window_start' `event_window_end')) ///
        xtitle("Time since CEO change (year)") ///
        yline(0) ytitle("`ytitle'") ///
        `yscale_opts' ///
        aspectratio(1) xsize(5) ysize(5) ///
        name(panel`panel', replace)
restore

frames drop denoised naive
