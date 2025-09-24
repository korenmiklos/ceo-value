args sample outcome
confirm file "temp/placebo_`sample'.dta"
confirm existence `outcome'

global event_window_start -10      // Event study window start
global event_window_end 9         // Event study window end
global baseline_year -2            // Baseline year for event study

do "code/estimate/setup_anova.do" `sample'
confirm numeric variable `outcome'

egen sometimes_missing = max(missing(`outcome')), by(fake_id)
drop if sometimes_missing == 1
drop sometimes_missing

egen Y_at_2 = mean(cond(firm_age == 2, `outcome', .)), by(fake_id)
generate dY = `outcome' - Y_at_2

local lbl : variable label `outcome'
label variable dY "Change in `lbl' relative to t-1"

generate event_time = year - change_year
generate byte event_window = inrange(event_time, ${event_window_start}, ${event_window_end})

table event_time placebo if event_window, stat(mean dY)
table event_time placebo if event_window, stat(var dY)

egen control_mean = mean(cond(placebo == 1, dY, .)), by(event_time)
egen treated_mean = mean(cond(placebo == 0, dY, .)), by(event_time)
generate ATET1 = cond(placebo == 0, treated_mean - control_mean, 0)

generate dY2 = (dY - ATET1)^2

/*xt2treatments dY, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(equal) cluster(${cluster})

xt2treatments dY, treatment(actual_ceo) control(placebo_ceo) pre(`=-1*${event_window_start}') post(${event_window_end}) baseline(${baseline_year}) weighting(optimal) cluster(${cluster})
e2frame, generate(ceo_mean)*/

forvalues t = `=100+$event_window_start'/`=100+$event_window_end' {
    generate byte E0_`t' = event_time == `t' - 100
    generate byte Ed_`t' = (placebo == 0) & (event_time == `t' - 100)
}
* no firm fixed effects, we assume that, without treatment, variance of control would be the same as variance of treated
reghdfe dY2 Ed* if event_window , a(event_time firm_age) cluster(frame_id_numeric ) resid nocons 
predict ATET2a, xb

egen control_variance = mean(cond(placebo == 1, dY2, .)), by(event_time firm_age)
egen treated_variance = mean(cond(placebo == 0, dY2, .)), by(event_time firm_age)
generate ATET2b = cond(placebo == 0, treated_variance - control_variance, 0)

correlate ATET2a ATET2b if event_window & !placebo

table event_time placebo if event_window, statistic(mean dY2)
table event_time if event_window & !placebo, statistic(mean ATET2a ATET2b)

* very similar estimates, we use simple means now
* FIXME: report standard errors
table firm_age if !placebo, statistic(variance dY) statistic(mean ATET2b)
egen sd_dY1 = sd(dY) if !placebo, by(firm_age)
generate var_dY1 = sd_dY1^2
egen var_dY0 = mean(var_dY1 - ATET2b) if !placebo, by(firm_age)
generate sd_dY0 = sqrt(var_dY0)

egen fat = tag(firm_age)
line var_dY1 var_dY0 firm_age if fat & firm_age>=2, sort ///
    title("Variance of TFP by Firm Age") ///
    xtitle("Firm Age (years)") ///
    xlabel(2(2)`=$event_window_end-$event_window_start+1') ///
    yscale(range(0 .)) ///
    ytitle("Variance of TFP (log points squared)") ///
    legend(order(1 "Total" 2 "Without CEO change")) ///
    lcolor(blue red)

graph export "output/figure/variance_by_firm_age_`sample'_`outcome'.pdf", replace

drop sd_* var_*
egen sd_dY1 = sd(dY) if !placebo, by(event_time)
generate var_dY1 = sd_dY1^2
egen var_dY0 = mean(var_dY1 - ATET2b) if !placebo, by(event_time)
generate sd_dY0 = sqrt(var_dY0)

egen ett = tag(event_time)
line var_dY1 var_dY0 event_time if ett & event_window, sort ///
    title("Variance of TFP by Event Time") ///
    xtitle("Event Time (years)") ///
    xlabel($event_window_start(1)$event_window_end) ///
    xline(-0.5) xscale(range ($event_window_start $event_window_end)) ///
    ytitle("Variance of TFP (log points squared)") ///
    yscale(range(0 .)) ///
    legend(order(1 "Total" 2 "Without CEO change")) ///
    lcolor(blue red)

graph export "output/figure/variance_by_event_time_`sample'_`outcome'.pdf", replace
