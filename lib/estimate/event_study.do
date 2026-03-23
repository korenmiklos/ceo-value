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

* run xt2denoise with detail to get both denoised and naive estimates
local pre  4
local post 3

xt2denoise `outcome', ///
    z(manager_skill) treatment(actual_ceo) control(placebo_ceo) ///
    pre(`pre') post(`post') detail

* capture denoised result from e(b) / e(V)
capture frames drop denoised
e2frame, generate(denoised) numeric

* swap naive matrices into e() so e2frame can capture them
tempname b_naive V_naive
matrix `b_naive' = e(b_naive)
matrix `V_naive' = e(V_naive)
scalar N_obs     = e(N)
ereturn post `b_naive' `V_naive', obs(`=N_obs')
capture frames drop naive
e2frame, generate(naive) numeric
