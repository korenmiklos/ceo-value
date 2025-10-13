args sample outcome montecarlo fixed_effects

* you can compute fixed effects on variables other than the outcome variable
if ("`fixed_effects'" == "") {
    local fixed_effects `outcome'
}

confirm file "data/placebo_`sample'.dta"
confirm existence `outcome'

do "../../lib/estimate/setup_event_study.do" `sample' `fixed_effects' `montecarlo'
confirm numeric variable `outcome'
confirm numeric variable `fixed_effects'

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

* TFP treatment treated_group d  frame_id_numeric
generate byte treatment = event_time >= 0
generate byte treated_group = !placebo
generate manager_diff = MS2 - MS1
do "../../lib/estimate/xt2var.do" `outcome' treatment treated_group manager_diff $cluster `fixed_effects'

frame dCov: export delimited "data/`sample'_`outcome'.csv", replace
