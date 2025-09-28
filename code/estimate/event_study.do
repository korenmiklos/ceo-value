args sample outcome
confirm file "temp/placebo_`sample'.dta"
confirm existence `outcome'

do "code/estimate/setup_event_study.do" `sample'
confirm numeric variable `outcome'

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

forvalues t = -4/3 {
    generate ET`=100+`t'' = (event_time == `t') & (good_ceo == 1)
}

* relative to baseline
drop ET`=100+${baseline_year}'
reghdfe `outcome' ET* if placebo==0, absorb(fake_id event_time) cluster(fake_id) nocons

forvalues t = 96/103 {
    scalar gamma_`t' =  _b[ET`t']
}

scalar list

BRK

xt2treatments `outcome', treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(ceo_mean)

xt2treatments `outcome' if good_ceo == 0, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(ceo_worse)

xt2treatments `outcome' if good_ceo == 1, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(ceo_better)

foreach X in coef lower upper {
    frame ceo_mean: rename `X' `X'_mean
    frame ceo_better: rename `X' `X'_better
    frame ceo_worse: rename `X' `X'_worse
}
if ("`sample'" == "montecarlo") {
    frame ceo_mean: generate true_effect = true_effect
}
frame ceo_mean: frlink 1:1 xvar, frame(ceo_better)
frame ceo_mean: frlink 1:1 xvar, frame(ceo_worse)
frame ceo_mean: frget coef_worse lower_worse upper_worse, from(ceo_worse)
frame ceo_mean: frget coef_better lower_better upper_better, from(ceo_better)
frame ceo_mean: order xvar coef_worse coef_mean coef_better lower_worse lower_mean lower_better upper_worse upper_mean upper_better
frame ceo_mean: export delimited "output/event_study/`sample'_`outcome'.csv", replace
