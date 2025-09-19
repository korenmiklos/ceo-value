do "code/estimate/setup_event_study.do"

xt2treatments lnStilde, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(ceo_mean)

* now that we have mean effects, we can compute variance effects
frlink m:1 event_time, frame(ceo_mean xvar)
frget coef, from(ceo_mean)

egen lnS_at_baseline = mean(cond(event_time == ${baseline_year}, lnStilde, .)), by(fake_id)
generate lnStilde_var = (lnStilde - lnS_at_baseline - coef)^2

xt2treatments lnStilde_var, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(ceo_var)

xt2treatments lnStilde if placebo == 0, treatment(better_ceo) control(worse_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(actual_ceo)

xt2treatments lnStilde if placebo == 1, treatment(better_ceo) control(worse_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(placebo_ceo)

xt2treatments lnStilde if good_ceo == 0, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(worse_ceo2)

xt2treatments lnStilde if good_ceo == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(better_ceo2)

* now link the two frames, better_ceo and worse_ceo and create the event study figure with two lines
* Create Panel A: Raw event study (better vs worse, control = small change)
foreach X in coef lower upper {
    frame actual_ceo: rename `X' `X'_actual
    frame placebo_ceo: rename `X' `X'_placebo
    frame ceo_mean: rename `X' `X'_mean
    frame ceo_var: rename `X' `X'_var
}
frame actual_ceo: frlink 1:1 xvar, frame(placebo_ceo)
frame actual_ceo: frget coef_placebo lower_placebo upper_placebo, from(placebo_ceo)
frame actual_ceo: save "temp/event_study_panel_a.dta", replace

frame ceo_var: frlink 1:1 xvar, frame(ceo_mean)
frame ceo_var: frget coef_mean lower_mean upper_mean, from(ceo_mean)
frame ceo_var: save "temp/event_study_moments.dta", replace

* Create Panel B: Placebo-controlled event study (better vs worse, actual vs placebo)
foreach X in coef lower upper {
    frame better_ceo2: rename `X' `X'_better
    frame worse_ceo2: rename `X' `X'_worse
}
frame worse_ceo2: frlink 1:1 xvar, frame(better_ceo2)
frame worse_ceo2: frget coef_better lower_better upper_better, from(better_ceo2)
frame worse_ceo2: save "temp/event_study_panel_b.dta", replace

display "Event study estimation complete. Data saved to temp/ for figure creation."

log using "output/event_study.txt", replace text

display "Event study results for better CEOs:"
* compare naive control to placebo controlled event study
xt2treatments lnStilde if placebo == 0, treatment(better_ceo) control(worse_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) cluster(${cluster})
scalar total_atet = _b[ATET]

xt2treatments lnStilde if placebo == 1, treatment(better_ceo) control(worse_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) cluster(${cluster})
scalar placebo_atet = _b[ATET]

xt2treatments lnStilde if good_ceo == 0, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) cluster(${cluster})
scalar worse_atet = _b[ATET]

xt2treatments lnStilde if good_ceo == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) cluster(${cluster})
scalar better_atet = _b[ATET]

scalar proper_atet1 = better_atet - worse_atet
scalar proper_atet2 = total_atet - placebo_atet

display "Total ATET: " total_atet
display "Placebo-controlled ATET 1: " proper_atet1
display "Placebo-controlled ATET 2: " proper_atet2
log close