args sample
local outcome TFP
confirm file "temp/placebo_`sample'.dta"
confirm existence `outcome'

do "code/estimate/setup_event_study.do" `sample'
confirm numeric variable `outcome'

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

generate byte treatment = (event_time >= 0)

capture frame drop atets
frame create atets str32 treatment_group str32 method n_obs ATET se

local all 1
local better good_ceo == 1
local worse good_ceo == 0

local naive placebo == 0
local placebo placebo == 1

foreach smp in all better worse {
    foreach method in naive placebo {
        reghdfe `outcome' treatment if ``method'' & ``smp'', absorb(fake_id year) vce(cluster ${cluster})
        frame post atets ("`smp'") ("`method'") (e(N)) (_b[treatment]) (_se[treatment])
    }
    xt2treatments `outcome' if ``smp'', treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(atet) weighting(optimal) cluster(${cluster})
    frame post atets ("`smp'") ("debiased") (e(N)) (_b[ATET]) (_se[ATET])
}

frame atets: export delimited "output/estimate/atet_`sample'.csv", replace
