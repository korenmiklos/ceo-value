args sample outcome
confirm file "temp/placebo_`sample'.dta"
confirm existence `outcome'

do "code/estimate/setup_event_study.do" `sample'
confirm numeric variable `outcome'

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

* TFP treatment treated_group d  frame_id_numeric
generate byte treatment = event_time >= 0
generate byte treated_group = !placebo
generate manager_diff = MS2 - MS1
do "code/estimate/xt2var.do" `outcome' treatment treated_group manager_diff $cluster

frame dCov: export delimited "output/event_study/`sample'_`outcome'.csv", replace
