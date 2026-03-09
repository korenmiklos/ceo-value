args sample outcome montecarlo fixed_effects weight_var

* Add local ado path for placebo2nd
adopath ++ "../../lib/estimate"

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

* if weight variable specified, also drop observations with missing weights
if ("`weight_var'" != "") {
    confirm numeric variable `weight_var'
    drop if missing(`weight_var')
}

generate byte treatment = event_time >= 0
generate byte treated_group = !placebo
generate manager_diff = MS2 - MS1
placebo2nd `outcome' treatment treated_group manager_diff, cluster($cluster) fixed_effects(`fixed_effects')

* append weight suffix to filename if weighted
if ("`weight_var'" != "") {
    local weight_suffix _w`weight_var'
}
frame dCov: export delimited "data/`sample'_`outcome'-`fixed_effects'`weight_suffix'.csv", replace
