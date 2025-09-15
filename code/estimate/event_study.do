do "code/estimate/setup_event_study.do"

xt2treatments lnStilde if skill_change == -1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal)
e2frame, generate(worse_ceo2)

xt2treatments lnStilde if skill_change == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal)
e2frame, generate(better_ceo2)

* Create Panel B: Placebo-controlled event study (better vs worse, actual vs placebo)
foreach X in coef lower upper {
    frame better_ceo2: rename `X' `X'_better
    frame worse_ceo2: rename `X' `X'_worse
}
frame worse_ceo2: frlink 1:1 xvar, frame(better_ceo2)
frame worse_ceo2: frget coef_better lower_better upper_better, from(better_ceo2)

* Save frames for figure creation
frame worse_ceo2: save "output/event_study_panel_b.dta", replace

display "Event study estimation complete. Data saved to output/ for figure creation."
