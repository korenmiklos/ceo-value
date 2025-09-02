do "code/estimate/setup_event_study.do"

local owner_controlled lnK has_intangible foreign_owned
local manager_controlled lnR lnWL lnM
local estab_options star(* 0.10 ** 0.05 *** 0.01) b(3) se style(tex) replace nolegend label nonote coeflabels(ATET "Better CEO")

* limit sample to firms that never miss an outcome
foreach Y in `owner_controlled' `manager_controlled' {
    egen sometimes_missing = max(missing(`Y')), by(fake_id)
    drop if sometimes_missing
    drop sometimes_missing 
}

eststo clear
foreach Y in `owner_controlled'  {
    xt2treatments `Y' if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) 
    eststo
}
esttab using "output/table/atet_owner.tex", `estab_options'

eststo clear
foreach Y in `manager_controlled' {
    xt2treatments `Y' if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) 
    eststo
}
esttab using "output/table/atet_manager.tex", `estab_options'

foreach Y in `owner_controlled' `manager_controlled' {
    local lbl : variable label `Y'
    xt2treatments `Y' if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal)
    capture frame drop figure
    e2frame, generate(figure)
    frame figure: graph twoway ///
        (rarea lower upper xvar, fcolor(gray%5) lcolor(gray%10)) (connected coef xvar, lcolor(blue) mcolor(blue)) ///
        , graphregion(color(white)) xlabel(-4(1)3) legend(off) ///
        xline(-0.5) xscale(range (-4 3)) ///
        xtitle("Time since CEO change (year)") yline(0) ///
        ytitle("`lbl' relative to year -3") ///
        ylabel(, angle(0)) 
    graph export "output/figure/event_study_`Y'.pdf", replace
}
