do "code/estimate/setup_event_study.do"

local owner_controlled lnK has_intangible foreign_owned
local manager_controlled lnR lnL lnM
local estab_options star(* 0.10 ** 0.05 *** 0.01) b(3) se style(tex) replace nolegend label nonote coeflabels(ATET "Better CEO")

* limit sample to firms that never miss an outcome
foreach Y in `owner_controlled' `manager_controlled' {
    egen sometimes_missing = max(missing(`Y')), by(fake_id)
    drop if sometimes_missing
    drop sometimes_missing 
}

eststo clear
foreach Y in `owner_controlled' `manager_controlled' {
    xt2treatments `Y' if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) 
    eststo
}
esttab using "output/table/better_ceo_atet.tex", `estab_options' 

foreach Y in `owner_controlled' `manager_controlled' {
    xt2treatments `Y' if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) graph
    graph export "output/figure/event_study_`Y'.pdf", replace
}


