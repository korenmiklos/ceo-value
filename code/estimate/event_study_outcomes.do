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

* Create owner-controlled figure
local graph_command ""
local legend_order ""
local i = 0
foreach Y in `owner_controlled' {
    local lbl : variable label `Y'
    xt2treatments `Y' if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal)
    capture frame drop figure_`Y'
    e2frame, generate(figure_`Y')
    frame figure_`Y': {
        rename coef coef_`Y'
        rename lower lower_`Y'
        rename upper upper_`Y'
        tempfile `Y'_data
        save ``Y'_data'
    }
    local ++i
    if `i' == 1 {
        local merge_base "``Y'_data'"
    }
    else {
        local graph_command "`graph_command' (connected coef_`Y' xvar, lcolor("`=cond(`i'==1, "blue", cond(`i'==2, "red", "green"))'") mcolor("`=cond(`i'==1, "blue", cond(`i'==2, "red", "green"))'"))"
        local legend_order "`legend_order' `i' "`lbl'""
    }
}

* Merge all owner-controlled data
frame create owner_figure
frame owner_figure: {
    use `merge_base', clear
    local i = 0
    foreach Y in `owner_controlled' {
        local ++i
        if `i' > 1 {
            merge 1:1 xvar using ``Y'_data', nogen
        }
    }
    
    * Plot combined owner-controlled figure
    graph twoway ///
        (connected coef_lnK xvar, lcolor(blue) mcolor(blue)) ///
        (connected coef_has_intangible xvar, lcolor(red) mcolor(red)) ///
        (connected coef_foreign_owned xvar, lcolor(green) mcolor(green)) ///
        , graphregion(color(white)) xlabel(-4(1)3) ///
        xline(-0.5) xscale(range (-4 3)) ///
        xtitle("Time since CEO change (year)") yline(0) ///
        ytitle("Effect relative to year -1") ///
        ylabel(, angle(0)) ///
        legend(order(1 "Log capital" 2 "Has intangibles" 3 "Foreign owned") rows(1) position(6))
}
graph export "output/figure/event_study_owner_controlled.pdf", replace

* Create manager-controlled figure
local graph_command ""
local legend_order ""
local i = 0
foreach Y in `manager_controlled' {
    local lbl : variable label `Y'
    xt2treatments `Y' if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal)
    capture frame drop figure_`Y'
    e2frame, generate(figure_`Y')
    frame figure_`Y': {
        rename coef coef_`Y'
        rename lower lower_`Y'
        rename upper upper_`Y'
        tempfile `Y'_data
        save ``Y'_data'
    }
    local ++i
    if `i' == 1 {
        local merge_base "``Y'_data'"
    }
    else {
        local graph_command "`graph_command' (connected coef_`Y' xvar, lcolor("`=cond(`i'==1, "blue", cond(`i'==2, "red", "green"))'") mcolor("`=cond(`i'==1, "blue", cond(`i'==2, "red", "green"))'"))"
        local legend_order "`legend_order' `i' "`lbl'""
    }
}

* Merge all manager-controlled data
frame create manager_figure
frame manager_figure: {
    use `merge_base', clear
    local i = 0
    foreach Y in `manager_controlled' {
        local ++i
        if `i' > 1 {
            merge 1:1 xvar using ``Y'_data', nogen
        }
    }
    
    * Plot combined manager-controlled figure
    graph twoway ///
        (connected coef_lnR xvar, lcolor(blue) mcolor(blue)) ///
        (connected coef_lnWL xvar, lcolor(red) mcolor(red)) ///
        (connected coef_lnM xvar, lcolor(green) mcolor(green)) ///
        , graphregion(color(white)) xlabel(-4(1)3) ///
        xline(-0.5) xscale(range (-4 3)) ///
        xtitle("Time since CEO change (year)") yline(0) ///
        ytitle("Effect relative to year -1") ///
        ylabel(, angle(0)) ///
        legend(order(1 "Log revenue" 2 "Log labor cost" 3 "Log materials") rows(1) position(6))
}
graph export "output/figure/event_study_manager_controlled.pdf", replace
