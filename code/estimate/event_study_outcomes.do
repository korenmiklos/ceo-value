clear all
do "code/estimate/setup_event_study.do"

local owner_controlled lnK has_intangible
local manager_controlled lnWL lnM
local estab_options star(* 0.10 ** 0.05 *** 0.01) b(3) se style(tex) replace nolegend label nonote coeflabels(ATET "Better CEO")

* limit sample to firms that never miss an outcome
foreach Y in `owner_controlled' `manager_controlled' {
    egen sometimes_missing = max(missing(`Y')), by(fake_id)
    drop if sometimes_missing
    drop sometimes_missing 
    * remove industry-year mean
    egen industry_year_mean = mean(`Y'), by(teaor08_2d year)
    replace `Y' = `Y' - industry_year_mean
    drop industry_year_mean
}

eststo clear
foreach Y in `owner_controlled'  {
    xt2treatments `Y' if good_ceo == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) cluster(${cluster})
    eststo
}
esttab using "output/table/atet_owner.tex", `estab_options'

eststo clear
foreach Y in `manager_controlled' {
    xt2treatments `Y' if good_ceo == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) cluster(${cluster})
    eststo
}
esttab using "output/table/atet_manager.tex", `estab_options'

* Create owner-controlled figure
local graph_command ""
local legend_order ""
local i = 0
foreach Y in `owner_controlled' `manager_controlled' {
    local lbl : variable label `Y'
    xt2treatments `Y' if good_ceo == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
    capture frame drop better_ceo
    e2frame, generate(better_ceo)
    frame better_ceo: {
        rename coef coef_better
        rename lower lower_better
        rename upper upper_better
    }
    xt2treatments `Y' if good_ceo == 0, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
    capture frame drop worse_ceo
    e2frame, generate(worse_ceo)
    frame worse_ceo: {
        rename coef coef_worse
        rename lower lower_worse
        rename upper upper_worse
    }
    frame worse_ceo: frlink 1:1 xvar, frame(better_ceo)
    frame worse_ceo: frget coef_better lower_better upper_better, from(better_ceo)
    frame worse_ceo: save "temp/event_study_`Y'.dta", replace
}
