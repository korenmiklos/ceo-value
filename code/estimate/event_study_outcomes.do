do "code/estimate/setup_event_study.do"

foreach Y in lnK has_intangible foreign_owned lnL lnM lnEBITDA ceo_age {
    xt2treatments `Y', treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) graph
    graph export "output/figure/event_study_`Y'.pdf", replace
}
