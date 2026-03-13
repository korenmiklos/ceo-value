args panel title ytitle outcome

local event_window_start -4      // Event study window start
local event_window_end 3         // Event study window end
local baseline_year -1            // Baseline year for event study

* Use common y-axis scale for comparability across outcomes
* exporter (dummy) and ROA have their own scales
local yscale_opts "ylabel(, angle(0) format(%9.2f))"
if "`title'" != "exporter" & "`title'" != "lnWL" & ("`title'" != "ROA" | "`outcome'" == "lnR") {
    local yscale_opts "yscale(range(-1 1.5)) ylabel(-1(0.5)1.5, angle(0) format(%9.1f))"
}

if "`outcome'" == "ROA" {
    graph twoway ///
        (connected `outcome'1 t, lcolor(red) mcolor(red)) ///
        (connected `outcome'0 t, lcolor(blue) mcolor(blue)) ///
        ,  title("Panel `panel': `title'", size(medium)) ///
        legend(order(1 "Treated" 2 "Placebo") rows(1) position(6)) ///
        graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
        xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
        xtitle("Time since CEO change (year)") yline(0) ///
        ytitle("`ytitle'") ///
        `yline' `yscale_opts' ///
        aspectratio(1) xsize(5) ysize(5) ///
        name(panel`panel', replace)
}
else {
    graph twoway ///
        (rarea lower_`outcome'1 upper_`outcome'1 t, fcolor(gray%5) lcolor(gray%10)) (connected coef_`outcome'1 t, lcolor(red) mcolor(red)) ///
        (rarea lower_`outcome'0 upper_`outcome'0 t, fcolor(gray%5) lcolor(gray%10)) (connected coef_`outcome'0 t, lcolor(blue) mcolor(blue)) ///
        ,  title("Panel `panel': `title'", size(medium)) ///
        legend(order(2 "Treated" 4 "Placebo") rows(1) position(6)) ///
        graphregion(color(white)) xlabel(`event_window_start'(1)`event_window_end') ///
        xline(-0.5) xscale(range (`event_window_start' `event_window_end')) ///
        xtitle("Time since CEO change (year)") yline(0) ///
        ytitle("`ytitle'") ///
        `yline' `yscale_opts' ///
        aspectratio(1) xsize(5) ysize(5) ///
        name(panel`panel', replace)
}

